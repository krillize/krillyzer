import std;
import docopt : docopt;

import corpus;
import layout;
import analysis;

immutable string doc = "
krillyzer

Usage:
  krillyzer list (layouts | corpora) [--contains=<string>]
  krillyzer load <corpus> [--file]
  krillyzer stats <layout>
  krillyzer sfb <layout> [--dist] [--amount=<int>]
  krillyzer use <layout>
  krillyzer freq <bigram> [--ignoreCase]
  krillyzer rank
  krillyzer gen
  krillyzer debug <layout> <bigram>
  krillyzer -h | --help
";

void showUse(Layout layout, JSONValue data) {
	auto monograms = data["monograms"];

	double total = 0;
	double[int] raw;

	foreach (e; monograms.object.byKeyValue) {
		dchar k = e.key.to!dchar;
		double v = e.value.get!double;

		total += v;

		if (!(k in layout.keys)) {
			continue;
		}

		raw[layout.keys[k].finger] += v;
	}
	
	"%-12s %-12s %-12s %-12s\n  ".writef("Index", "Middle", "Ring", "Pinky");
	"L %-11s".writef("%5.2f%%".format(raw[3] / total * 100));
	"L %-11s".writef("%5.2f%%".format(raw[1] / total * 100));
	"L %-11s".writef("%5.2f%%".format(raw[2] / total * 100));
	"L %-11s".writef("%5.2f%%".format(raw[0] / total * 100));

	writef("\n  ");

	"R %-11s".writef("%5.2f%%".format(raw[6] / total * 100));
	"R %-11s".writef("%5.2f%%".format(raw[8] / total * 100));
	"R %-11s".writef("%5.2f%%".format(raw[7] / total * 100));
	"R %-11s".writef("%5.2f%%".format(raw[9] / total * 100));

	writeln();
}

void showSFB(Layout layout, JSONValue data, int amount = 16, bool dist = false, bool worst = false) {
	auto bigrams = data["bigrams"];
	
	double total = 0;
	double[int] raw;

	string[] sfbs; 
	foreach (e; bigrams.object.byKeyValue) {
		string k = e.key;
		double v = e.value.get!double;
		
		total += v;

		if (
			!(k[0] in layout.keys) ||
			!(k[1] in layout.keys)
		) {
			continue;
		}

		auto pos = k.map!(x => layout.keys[x]).array;

		if (!pos.isSFB) {
			continue;
		}

		foreach (i; 0 .. 10) {
			double count = v * (pos[0].finger == i);

			if (dist) {
				count *= pos.distance;
			}

			raw[i] += count;
		}

		sfbs ~= k;
	}
	
	"SFB %.3f%%".writefln(raw.values.sum / total * 100);
	"  Pinky  %.3f%%".writefln((raw[0] + raw[6]) / total * 100);
	"  Ring   %.3f%%".writefln((raw[1] + raw[7]) / total * 100);
	"  Middle %.3f%%".writefln((raw[2] + raw[8]) / total * 100);
	"  Index  %.3f%%".writefln((raw[3] + raw[9]) / total * 100);

	if (worst) {
		sfbs.sort!((a, b) => bigrams[a].get!double > bigrams[b].get!double).take(3);

		writeln("\nWorst");
		foreach (row; sfbs.take(amount).chunks(4)) {
			foreach (gram; row) {
				auto pos = gram.map!(x => layout.keys[x]).array;
				double count = bigrams[gram].get!double / total * 100;

				if (dist) {
					count *= pos.distance;
				}

				"  %s %-7s".writef(gram, "%.3f%%".format(count));
			}
			writeln;
		}
	}

}

void debugBigram(Layout layout, string gram) {
	auto json = "data.json".readText.parseJSON;
	auto pos = gram.map!(x => layout.keys[x]).array;

	double bigram = (
		(
			json["bigrams"][gram].get!double +
			json["bigrams"][gram.dup.reverse].get!double
		)/ 
		json["bigrams"].object.byValue.map!(x => x.get!double).sum *
		100
	);

	double skipgram = (
		(
			json["skipgrams"][gram].get!double +
			json["skipgrams"][gram.dup.reverse].get!double
		)/ 
		json["bigrams"].object.byValue.map!(x => x.get!double).sum *
		100
	);

	double speedgram = (
		(
			json["speedgrams"][gram].get!double +
			json["speedgrams"][gram.dup.reverse].get!double
		)/ 
		json["bigrams"].object.byValue.map!(x => x.get!double).sum *
		100
	);

	"%s (%s)".writefln(layout.name, layout.format);
	layout.main.map!(
		x => ['\n', ' ', gram[0], gram[1]].canFind(x) ? x : ' '
	).to!string.splitter("\n").each!(x => "  %s".writefln(x));

	writeln();

	"%s %s".writefln(gram[0], pos[0]);
	"%s %s".writefln(gram[1], pos[1]);

	writeln("\ncorpus");
	"  bigram     %.3f%%".writefln(bigram);
	"  skipgram   %.3f%%".writefln(skipgram);
	"  speedgram  %.3f%%".writefln(speedgram);

	writeln("\nflags");
	"  repeat      %2d".writefln(pos.isRepeat);
	"  sameFinger  %2d".writefln(pos.sameFinger);
	"  sameHand    %2d".writefln(pos.sameHand);
	"  isAdjacent  %2d".writefln(pos.isAdjacent);

	writeln("\nvalues");
	"  direction   %2d".writefln(pos.direction);
	"  horizontal  %2d".writefln(pos.distHorizontal);
	"  vertical    %2d".writefln(pos.distVertical);
	"  distance  %2.2f".writefln(pos.distance);
}

void debugTrigram(Layout layout, string gram) {
	auto json = "data.json".readText.parseJSON;
	auto pos = gram.map!(x => layout.keys[x]).array;

	"%s (%s)".writefln(layout.name, layout.format);
	layout.main.map!(
		x => ['\n', ' ', gram[0], gram[1], gram[2]].canFind(x) ? x : ' '
	).to!string.splitter("\n").each!(x => "  %s".writefln(x));

	writeln();

	"%s %s".writefln(gram[0], pos[0]);
	"%s %s".writefln(gram[1], pos[1]);
	"%s %s".writefln(gram[2], pos[2]);

	writeln("\nflags");
	"  alternate %2d".writefln(pos.isAlternate);
	"  inroll    %2d".writefln(pos.isInroll);
	"  outroll   %2d".writefln(pos.isOutroll);
	"  redirect  %2d".writefln(pos.isRedirect);	
	"  onehand   %2d".writefln(pos.isOnehand);
}

void main(string[] args) {
    auto cmds = doc.docopt(args[1..$]);

	if (cmds["load"].isTrue) {
		setCorpus(
			cmds["<corpus>"].toString,
			cmds["--file"].isTrue,
		);
	}

	if (cmds["list"].isTrue) {
		string msg;
		string[] items;

		if (cmds["corpora"].isTrue) {
			items = getCorpora;
			msg = "List of Corpora:";
		}

		if (cmds["layouts"].isTrue) {
			items = getLayouts;
			msg = "List of Layouts:";
		}

		if (cmds["--contains"].isString) {
			string str = cmds["--contains"].toString;
			items = items.filter!(x => x.canFind(str)).array;
		}

		writeln(msg);
		items.sort;
		items.each!(x => "  %s".writefln(x));
	}

	if (cmds["freq"].isTrue) {
		showFreq(
			cmds["<bigram>"].toString,
			cmds["--ignoreCase"].isTrue,
		);
	}

	if (cmds["gen"].isTrue) {
		generate();
	}

	if (cmds["stats"].isTrue) {
		Layout layout;
		
		try {
			layout = getLayout(cmds["<layout>"].toString);
		} catch (ParserException e) {
			"Error in layout file: %s".writefln(e.msg);
			return;
		}

		auto data = "data.json".readText.parseJSON;

		writeln(layout.name);
		layout.main.splitter("\n").each!(x => "  %s".writefln(x));

		double btotal = 0;
		double stotal = 0;
		double ttotal = 0;
		double ptotal = 0;

		double[string] raw;

		foreach (e; data["bigrams"].object.byKeyValue) {
			string k = e.key;
			double v = e.value.get!double;

			btotal += v;

			if (
				!(k[0] in layout.keys) ||
				!(k[1] in layout.keys)
			) {
				continue;
			}

			auto pos = k.map!(x => layout.keys[x]).array;

			if (pos.isSFB) {
				raw["sfb"] += v;
				raw["sfb-dist"] += v * pos.distance;
			}

			if (pos.isLSB) {
				raw["lsb"] += v;
				raw["lsb-dist"] += v * pos.distance;
			}
		}

		foreach (e; data["skipgrams"].object.byKeyValue) {
			string k = e.key;
			double v = e.value.get!double;

			stotal += v;

			if (
				!(k[0] in layout.keys) ||
				!(k[1] in layout.keys)
			) {
				continue;
			}

			auto pos = k.map!(x => layout.keys[x]).array;

			if (pos.isSFB) {
				raw["sfs"] += v;
				raw["sfs-dist"] += v * pos.distance;
			}
		}

		foreach (e; data["trigrams"].object.byKeyValue) {
			string k = e.key;
			double v = e.value.get!double;

			ttotal += v;

			if (
				!(k[0] in layout.keys) ||
				!(k[1] in layout.keys) ||
				!(k[2] in layout.keys)
			) {
				continue;
			}

			auto pos = k.map!(x => layout.keys[x]).array;

			if (pos.isAlternate) {
				raw["alt"] += v;
			}

			if (pos.isInroll) {
				raw["inroll"] += v;
			}

			if (pos.isOutroll) {
				raw["outroll"] += v;
			}

			if (pos.isRedirect) {
				raw["red"] += v;
			}

			if (pos.isOnehand) {
				raw["one"] += v;
			}
		}

		foreach (e; data["speedgrams"].object.byKeyValue) {
			string k = e.key;
			double v = e.value.get!double;

			ptotal += v;

			if (
				!(k[0] in layout.keys) ||
				!(k[1] in layout.keys)
			) {
				continue;
			}

			auto pos = k.map!(x => layout.keys[x]).array;

			if (pos.isSFB) {
				auto finger = pos[0].finger;
				
				raw[finger.to!string] += (
					v * pos.distance.pow(0.65) * 
					(1 / [1.5, 3.6, 4.8, 5.5, 0, 0, 5.5, 4.8, 3.6, 1.5][finger])
				);
			}
		}

		"\n%-16s %-16s %-16s\n  ".writef("SFB", "SFS", "LSB");
		"Freq %-12s".writef("%6.3f%%".format(raw["sfb"] / btotal * 100));
		"Freq %-12s".writef("%6.3f%%".format(raw["sfs"] / stotal * 100));
		"Freq %-12s".writef("%6.3f%%".format(raw["lsb"] / btotal * 100));

		writef("\n  ");

		"Dist %-12s".writef("%6.3f".format(raw["sfb-dist"] / raw["sfb"]));
		"Dist %-12s".writef("%6.3f".format(raw["sfs-dist"] / raw["sfs"]));
		"Dist %-12s".writef("%6.3f".format(raw["lsb-dist"] / raw["lsb"]));

		writeln("\n\nFspeed");
		"  Pinky  %.3f".writefln((raw["LP"] + raw["RP"]) / ptotal * 100);
		"  Ring   %.3f".writefln((raw["LR"] + raw["RR"]) / ptotal * 100);
		"  Middle %.3f".writefln((raw["LM"] + raw["RM"]) / ptotal * 100);
		"  Index  %.3f".writefln((raw["LI"] + raw["RI"]) / ptotal * 100);

		writeln("\nRolls");
		"  Total   %.3f%%".writefln((raw["inroll"] + raw["outroll"]) / ttotal * 100);
		"  Inroll  %.3f%%".writefln(raw["inroll"] / ttotal * 100);
		"  Outroll %.3f%%".writefln(raw["outroll"] / ttotal * 100);

		writeln("\nTrigrams");
		"  Alternates %.3f%%".writefln(raw["alt"] / ttotal * 100);
		"  Redirects  %.3f%%".writefln(raw["red"] / ttotal * 100);
		"  Onehands   %.3f%%".writefln(raw["one"] / ttotal * 100);

		writeln();
		showUse(layout, data);
	}

	if (cmds["use"].isTrue) {
		Layout layout;
		
		try {
			layout = getLayout(cmds["<layout>"].toString);
		} catch (ParserException e) {
			"Error in layout file: %s".writefln(e.msg);
			return;
		}

		auto data = "data.json".readText.parseJSON;

		writeln(layout.name);
		layout.main.splitter("\n").each!(x => "  %s".writefln(x));
		writeln();

		showUse(layout, data);
	}

	if (cmds["sfb"].isTrue) {
		Layout layout;
		
		try {
			layout = getLayout(cmds["<layout>"].toString);
		} catch (ParserException e) {
			"Error in layout file: %s".writefln(e.msg);
			return;
		}

		auto data = "data.json".readText.parseJSON;

		int amount = 16;
		if (cmds["--amount"].isString) {
			string str = cmds["--amount"].toString;
			amount = str.parse!int;
		}

		writeln(layout.name);
		layout.main.splitter("\n").each!(x => "  %s".writefln(x));
		writeln();

		showSFB(layout, data, amount, cmds["--dist"].isTrue, true);
	}

	if (cmds["rank"].isTrue) {
		auto layouts = getLayouts();
		auto json = "data.json".readText.parseJSON;

		double[string] scores;

		foreach (e; layouts) {
			auto layout = getLayout(e);
			scores[layout.name] = scoreLayout(layout, json);
		}

		foreach (k, v; scores.byPair.array.sort!"a[1] > b[1]") {
			"%-14s %.3f".writefln(k, v);
		}
	}

	if (cmds["debug"].isTrue) {
		Layout layout;
		
		try {
			layout = getLayout(cmds["<layout>"].toString);
		} catch (ParserException e) {
			"Error in layout file: %s".writefln(e.msg);
			return;
		}

		string gram = cmds["<bigram>"].toString;

		if (gram.length == 2) {
			debugBigram(layout, gram);
		}

		if (gram.length == 3) {
			debugTrigram(layout, gram);
		}
	}
}