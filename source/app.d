import std;
import docopt : docopt;

import corpus;
import layout;
import analysis;
import parsing;

immutable string doc = "
krillyzer

Usage:
  krillyzer   list    (layouts | corpora)   [--contains=<string>]
  krillyzer   load    <corpus>              [--file]
  krillyzer   stats   <layout>              [--board=<board>]
  krillyzer   sfb     <layout>              [--dist] [--amount=<int>]
  krillyzer   roll    <layout>              [--relative]
  krillyzer   use     <layout>
  krillyzer   rank
  krillyzer   gen
  krillyzer   freq    <bigram>              [--ignoreCase]
  krillyzer   debug   <layout> <bigram>     [--board=<board>]
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
	"L %-11s".writef("%5.2f%%".format(raw.get(3, 0) / total * 100));
	"L %-11s".writef("%5.2f%%".format(raw.get(2, 0) / total * 100));
	"L %-11s".writef("%5.2f%%".format(raw.get(1, 0) / total * 100));
	"L %-11s".writef("%5.2f%%".format(raw.get(0, 0) / total * 100));

	writef("\n  ");

	"R %-11s".writef("%5.2f%%".format(raw.get(6, 0) / total * 100));
	"R %-11s".writef("%5.2f%%".format(raw.get(8, 0) / total * 100));
	"R %-11s".writef("%5.2f%%".format(raw.get(7, 0) / total * 100));
	"R %-11s".writef("%5.2f%%".format(raw.get(9, 0) / total * 100));

	writeln("\n\nHand Balance");
	"  Left   %6.3f%%".writefln((raw.get(0, 0) + raw.get(1, 0) + raw.get(2, 0) + raw.get(3, 0)) / total * 100);
	"  Right  %6.3f%%".writefln((raw.get(6, 0) + raw.get(7, 0) + raw.get(8, 0) + raw.get(9, 0)) / total * 100);

	if (4 in raw || 5 in raw) {
		"  Thumb  %6.3f%%".writefln((raw.get(4, 0) + raw.get(5, 0)) / total * 100);
	}
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
	"  Pinky  %.3f%%".writefln((raw.get(0, 0) + raw.get(6, 0)) / total * 100);
	"  Ring   %.3f%%".writefln((raw.get(1, 0) + raw.get(7, 0)) / total * 100);
	"  Middle %.3f%%".writefln((raw.get(2, 0) + raw.get(8, 0)) / total * 100);
	"  Index  %.3f%%".writefln((raw.get(3, 0) + raw.get(9, 0)) / total * 100);

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
	auto pos = gram.map!(x => layout.keys[x]).array;

	"%s (%s)".writefln(layout.name, layout.format);
	layout.main.map!(
		x => ['\n', ' ', gram[0], gram[1]].canFind(x) ? x : ' '
	).to!string.splitter("\n").each!(x => "  %s".writefln(x));

	writeln();

	"%s %s".writefln(gram[0], pos[0]);
	"%s %s".writefln(gram[1], pos[1]);

	writeln("\nflags");
	"  repeat        %2d".writefln(pos.isRepeat);
	"  sameFinger    %2d".writefln(pos.sameFinger);
	"  sameHand      %2d".writefln(pos.sameHand);
	"  isAdjacent    %2d".writefln(pos.isAdjacent);

	writeln("\nvalues");
	"  direction     %2d".writefln(pos.direction);
	"  horizontal  %2.2f".writefln(pos.distHorizontal);
	"  vertical    %2.2f".writefln(pos.distVertical);
	"  distance    %2.2f".writefln(pos.distance);

	writeln("\nstats");
	"  sfb           %2d".writefln(pos.isSFB);
	"  lsb           %2d".writefln(pos.isLSB);
}

void debugTrigram(Layout layout, string gram) {
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
	"  adjacent  %2d".writefln(pos.isAdjacentRoll);
	"  inroll    %2d".writefln(pos.isInroll);
	"  outroll   %2d".writefln(pos.isOutroll);
	"  redirect  %2d".writefln(pos.isRedirect);	
	"  onehand   %2d".writefln(pos.isOnehand);
}

void main(string[] args) {
    auto cmds = doc.docopt(args[1..$]);

	auto config = parseFile("config.txt".File);
	
	string board = config["board"];
	if (cmds["--board"].isString) {
		board = cmds["--board"].toString;
	}

	Layout layout;
	if (cmds["<layout>"].isString) {
		try {
			layout = getLayout(cmds["<layout>"].toString, board);
		} catch (ParserException e) {
			"Error in layout file: %s".writefln(e.msg);
			return;
		}
	}

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
		auto data = "data.json".readText.parseJSON;

		writeln(layout.name);
		layout.main.splitter("\n").each!(x => "  %s".writefln(x));

		double mtotal = 0;
		double btotal = 0;
		double stotal = 0;
		double ttotal = 0;
		double ptotal = 0;

		double[string] raw;

		foreach (e; data["monograms"].object.byKeyValue) {
			dchar k = e.key.to!dchar;
			double v = e.value.get!double;

			mtotal += v;

			if (!(k in layout.keys)) {
				continue;
			}

			auto pos = layout.keys[k];

			if ([4, 5].canFind(pos.col)) {
				raw["center"] += v;
				continue;
			}

			if (pos.row == 0) {
				raw["top"] += v;
			}

			if (pos.row == 1) {
				raw["home"] += v;
			}

			if (pos.row == 2) {
				raw["bottom"] += v;
			}
		}

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

			if (pos.isRoll) {
				raw["rolls"] += v; 
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
		"Freq %-12s".writef("%6.3f%%".format(raw.get("sfb", 0) / btotal * 100));
		"Freq %-12s".writef("%6.3f%%".format(raw.get("sfs", 0) / stotal * 100));
		"Freq %-12s".writef("%6.3f%%".format(raw.get("lsb", 0) / btotal * 100));

		writef("\n  ");

		"Dist %-12s".writef("%6.3f".format(raw["sfb-dist"] / raw["sfb"]));
		"Dist %-12s".writef("%6.3f".format(raw["sfs-dist"] / raw["sfs"]));
		"Dist %-12s".writef("%6.3f".format(raw["lsb-dist"] / raw["lsb"]));

		// writeln("\n\nFspeed");
		// "  Pinky  %.3f".writefln((raw["LP"] + raw["RP"]) / ptotal * 100);
		// "  Ring   %.3f".writefln((raw["LR"] + raw["RR"]) / ptotal * 100);
		// "  Middle %.3f".writefln((raw["LM"] + raw["RM"]) / ptotal * 100);
		// "  Index  %.3f".writefln((raw["LI"] + raw["RI"]) / ptotal * 100);

		"\n\nRolls %.3f%%".writefln(raw.get("rolls", 0) / ttotal * 100);
		"  Inroll   %.3f%%".writefln(raw.get("inroll", 0) /  ttotal * 100);
		"  Outroll  %.3f%%".writefln(raw.get("outroll", 0) / ttotal * 100);

		writeln("\nTrigrams");
		"  Alternates %6.3f%%".writefln(raw.get("alt", 0) / ttotal * 100);
		"  Redirects  %6.3f%%".writefln(raw.get("red", 0) / ttotal * 100);
		"  Onehands   %6.3f%%".writefln(raw.get("one", 0) / ttotal * 100);

		writeln("\nRows");
		"  Top    %6.3f%%".writefln(raw.get("top", 0) / mtotal * 100);
		"  Home   %6.3f%%".writefln(raw.get("home", 0) / mtotal * 100);
		"  Bottom %6.3f%%".writefln(raw.get("bottom", 0) / mtotal * 100);
		"  Center %6.3f%%".writefln(raw.get("center", 0) / mtotal * 100);

		writeln();
		showUse(layout, data);
	}

	if (cmds["roll"].isTrue) {
		auto data = "data.json".readText.parseJSON;

		double total = 0;
		double[string] raw;

		foreach (e; data["trigrams"].object.byKeyValue) {
			string k = e.key;
			double v = e.value.get!double;

			total += v;

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

			if (pos.isAdjacentRoll) {
				raw["adroll"] += v;
			}

			if (pos.isRoll) {
				raw["rolls"] += v; 
			}

			if (pos.isRowRoll) {
				raw["rowroll"] += v;
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

		double rtotal = total;
		if (cmds["--relative"].isTrue) {
			rtotal = raw["rolls"];
		}

		writeln(layout.name);
		layout.main.splitter("\n").each!(x => "  %s".writefln(x));

		"\nRolls %.3f%%".writefln(raw.get("rolls", 0) / total * 100);
		"  Inroll   %.3f%%".writefln(raw.get("inroll", 0) /  rtotal * 100);
		"  Outroll  %.3f%%".writefln(raw.get("outroll", 0) / rtotal * 100);
		"  Adjacent %.3f%%".writefln(raw.get("adroll", 0) /  rtotal * 100);
		"  Same Row %.3f%%".writefln(raw.get("rowroll", 0) / rtotal * 100);
	}

	if (cmds["use"].isTrue) {
		auto data = "data.json".readText.parseJSON;

		writeln(layout.name);
		layout.main.splitter("\n").each!(x => "  %s".writefln(x));
		writeln();

		showUse(layout, data);
	}

	if (cmds["sfb"].isTrue) {
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
			layout = getLayout(e, "rowstag");
			scores[layout.name] = scoreLayout(layout, json);
		}

		foreach (k, v; scores.byPair.array.sort!"a[1] > b[1]") {
			"%-25s %6.3f".writefln(k, v);
		}
	}

	if (cmds["debug"].isTrue) {
		string gram = cmds["<bigram>"].toString;

		if (gram.length == 2) {
			debugBigram(layout, gram);
		}

		if (gram.length == 3) {
			debugTrigram(layout, gram);
		}
	}
}