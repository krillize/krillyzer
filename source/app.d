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
  krillyzer sfb <layout> [--dist] [--ignoreCase] [--amount=<int>]
  krillyzer freq <bigram> [--ignoreCase]
  krillyzer debug <layout> <bigram>
  krillyzer -h | --help
";

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

	if (cmds["sfb"].isTrue) {
		auto layout = getLayout(cmds["<layout>"].toString);
		auto bigrams = getBigrams(cmds["--ignoreCase"].isTrue);

		int total;
		double[int] raw;

		string[] sfbs; 
		foreach (k, v; bigrams) {
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

				if (cmds["--dist"].isTrue) {
					count *= pos.distance;
				}

				raw[i] += count;
			}

			sfbs ~= k;
		}

		sfbs.sort!((a, b) => bigrams[a] > bigrams[b]).take(3);

		writeln(layout.name);
		layout.main.splitter("\n").each!(x => "  %s".writefln(x));
		
		"\nSFB %.3f%%".writefln(raw.values.sum / total * 100);
		"  Pinky  %.3f%%".writefln((raw[0] + raw[6]) / total * 100);
		"  Ring   %.3f%%".writefln((raw[1] + raw[7]) / total * 100);
		"  Middle %.3f%%".writefln((raw[2] + raw[8]) / total * 100);
		"  Index  %.3f%%".writefln((raw[3] + raw[9]) / total * 100);

		int amount = 16;
		
		if (cmds["--amount"].isString) {
			string str = cmds["--amount"].toString;
			amount = str.parse!int;
		}

		writeln("\nWorst");
		foreach (row; sfbs.take(amount).chunks(4)) {
			foreach (gram; row) {
				auto pos = gram.map!(x => layout.keys[x]).array;
				double count = bigrams[gram].to!float / total * 100;

				if (cmds["--dist"].isTrue) {
					count *= pos.distance;
				}

				"  %s %-7s".writef(gram, "%.3f%%".format(count));
			}
			writeln;
		}
	}

	if (cmds["debug"].isTrue) {
		try {
			auto layout = getLayout(cmds["<layout>"].toString);

			string gram = cmds["<bigram>"].toString;
			auto pos = gram.map!(x => layout.keys[x]).array;

			"%s (%s)".writefln(layout.name, layout.format);
			layout.main.map!(
				x => ['\n', ' ', gram[0], gram[1]].canFind(x) ? x : ' '
			).to!string.splitter("\n").each!(x => "  %s".writefln(x));

			writeln();

			"%s %s".writefln(gram[0], pos[0]);
			"%s %s".writefln(gram[1], pos[1]);

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

		} catch (ParserException e) {
			"Error in layout file: %s".writefln(e.msg);
		}
	}
	
    // writeln(cmds);
}