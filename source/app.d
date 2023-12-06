import std;
import docopt : docopt;

import corpus;
import layout;
import analysis;
import parsing;

immutable string doc = "
krillyzer

Usage:
  krillyzer   list    (layouts | stats | corpora)   [--contains=<string>]             
  krillyzer   load    <corpus>                      [--file]
  krillyzer   view    <layout>                      [--board=<board>]
  krillyzer   sfb     <layout>                      [--dist] [--amount=<int>]
  krillyzer   stat    <layout> <stat>               [--dist] [--amount=<int>]
  krillyzer   roll    <layout>                      [--relative]
  krillyzer   use     <layout>
  krillyzer   find    <filters>...
  krillyzer   sort    <stat>                        [--asc]
  krillyzer   rank
  krillyzer   gen
  krillyzer   freq    <bigram>                      [--ignoreCase]
  krillyzer   debug   <layout> <bigram>             [--board=<board>]
";

void showUse(Layout layout, JSONValue data) {
	auto raw = layout.getMono(data);
	
	"%-12s %-12s %-12s %-12s\n  ".writef("Index", "Middle", "Ring", "Pinky");
	"L %-11s".writef("%5.2f%%".format(raw["LI"].freq));
	"L %-11s".writef("%5.2f%%".format(raw["LM"].freq));
	"L %-11s".writef("%5.2f%%".format(raw["LR"].freq));
	"L %-11s".writef("%5.2f%%".format(raw["LP"].freq));

	writef("\n  ");

	"R %-11s".writef("%5.2f%%".format(raw["RI"].freq));
	"R %-11s".writef("%5.2f%%".format(raw["RM"].freq));
	"R %-11s".writef("%5.2f%%".format(raw["RR"].freq));
	"R %-11s".writef("%5.2f%%".format(raw["RP"].freq));

	writeln("\n\nHand Balance");
	"  Left   %6.3f%%".writefln(raw["LH"].freq);
	"  Right  %6.3f%%".writefln(raw["RH"].freq);

	if (raw["thumb"].exists) {
		"  Thumb  %6.3f%%".writefln(raw["thumb"].freq);
	}
}

void showSFB(Layout layout, JSONValue data, int amount = 16, bool dist = false, bool worst = false) {
	auto raw = layout.getBi(data, dist);
	
	"SFB %.3f%%".writefln(raw["sfb"].dist);
	"  Pinky  %.3f%%".writefln(raw["pinky-sfb"].dist);
	"  Ring   %.3f%%".writefln(raw["ring-sfb"].dist);
	"  Middle %.3f%%".writefln(raw["middle-sfb"].dist);
	"  Index  %.3f%%".writefln(raw["index-sfb"].dist);

	if(raw["thumb-sfb"].exists) {
		"  Thumb  %.3f%%".writefln(raw["thumb-sfb"].dist);
	}

	if (worst) {
		writeln("\nWorst");
		foreach (row; raw["sfb"].top(amount).chunks(4)) {
			foreach (gram; row) {
				"  %s %-7s".writef(
					gram, "%.3f%%".format(raw["sfb"].freq(gram))
				);
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

	string[] folders = config["folders"].splitter("\n").array;

	Layout layout;
	if (cmds["<layout>"].isString) {
		try {
			layout = findLayout(cmds["<layout>"].toString, board);
		} catch (ParserException e) {
			"Error: %s".writefln(e.msg);
			return;
		}
	}

	JSONValue data = "data.json".readText.parseJSON;

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
			items = getLayouts(folders).map!(x => x.getBasename).array;
			msg = "List of Layouts:";
		}

		if (cmds["stats"].isTrue) {
			layout = findLayout("qwerty", board);
			items = layout.getStats(data, true).byKey.array;
			msg = "List of Stats:";
		}

		if (cmds["--contains"].isString) {
			string str = cmds["--contains"].toString;
			items = items.filter!(x => x.canFind(str)).array;
		}

		items.sort;

		writeln(msg);
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

	if (cmds["view"].isTrue) {
		auto raw = layout.getStats(data, true);

		writeln(layout.name);
		layout.main.splitter("\n").each!(x => "  %s".writefln(x));

		"\n%-16s %-16s %-16s\n  ".writef("SFB", "SFS", "LSB");
		"Freq %-12s".writef("%6.3f%%".format(raw["sfb"].freq));
		"Freq %-12s".writef("%6.3f%%".format(raw["sfs"].freq));
		"Freq %-12s".writef("%6.3f%%".format(raw["lsb"].freq));

		writef("\n  ");

		"Dist %-12s".writef("%6.3f".format(raw["sfb"].avgdist));
		"Dist %-12s".writef("%6.3f".format(raw["sfs"].avgdist));
		"Dist %-12s".writef("%6.3f".format(raw["lsb"].avgdist));

		"\n\nRolls %.3f%%".writefln(raw["roll"].freq);
		"  Inroll   %.3f%%".writefln(raw["inroll"].freq);
		"  Outroll  %.3f%%".writefln(raw["outroll"].freq);

		writeln("\nTrigrams");
		"  Alternates %6.3f%%".writefln(raw["alt"].freq);
		"  Redirects  %6.3f%%".writefln(raw["red"].freq);
		"  Onehands   %6.3f%%".writefln(raw["one"].freq);

		writeln("\nRows");
		"  Top    %6.3f%%".writefln(raw["top"].freq);
		"  Home   %6.3f%%".writefln(raw["home"].freq);
		"  Bottom %6.3f%%".writefln(raw["bottom"].freq);
		"  Center %6.3f%%".writefln(raw["center"].freq);

		writeln();
		showUse(layout, data);
	}

	if (cmds["stat"].isTrue) {
		auto raw = layout.getStats(data, cmds["--dist"].isTrue);
		string stat = cmds["<stat>"].toString;

		int amount = 16;
		if (cmds["--amount"].isString) {
			string str = cmds["--amount"].toString;
			amount = str.parse!int;
		}

		if (!(stat in raw)) {
			"Error: stat %s does not exist".writefln(stat);
			return;
		}

		writeln(layout.name);
		layout.main.splitter("\n").each!(x => "  %s".writefln(x));

		"\n%s".writefln(stat.toUpper);
		"  Freq  %6.3f%%".writefln(raw[stat].freq);

		if (raw[stat].avgdist > 1) {
			"  Dist  %6.3f%%".writefln(raw[stat].avgdist);
			"  Total %6.3f%%".writefln(raw[stat].dist);
		}
		
		"\nTop %s".writefln(amount);

		foreach (row; raw[stat].top(amount).chunks(4)) {
			foreach (gram; row) {
				"  %s %-7s".writef(
					gram, "%.3f%%".format(raw[stat].freq(gram))
				);
			}
			writeln;
		}
	}

	if (cmds["roll"].isTrue) {
		auto raw = layout.getTri(data);

		writeln(layout.name);
		layout.main.splitter("\n").each!(x => "  %s".writefln(x));

		double total = cmds["--relative"].isTrue ? raw["roll"].count : raw["roll"].total;

		"\nRolls %.3f%%".writefln(raw["roll"].freq);
		"  Inroll   %.3f%%".writefln(raw["inroll"].count / total * 100);
		"  Outroll  %.3f%%".writefln(raw["outroll"].count / total * 100);
		"  Adjacent %.3f%%".writefln(raw["adroll"].count / total * 100);
		"  Same Row %.3f%%".writefln(raw["rowroll"].count / total * 100);
	}

	if (cmds["use"].isTrue) {
		writeln(layout.name);
		layout.main.splitter("\n").each!(x => "  %s".writefln(x));
		writeln();

		showUse(layout, data);
	}

	if (cmds["sfb"].isTrue) {
		int amount = 16;
		if (cmds["--amount"].isString) {
			string str = cmds["--amount"].toString;
			amount = str.parse!int;
		}

		// writeln(layout.name);
		// layout.main.splitter("\n").each!(x => "  %s".writefln(x));
		// writeln();

		layout.writeln;
		writeln();

		showSFB(layout, data, amount, cmds["--dist"].isTrue, true);
	}

	if (cmds["rank"].isTrue) {
		auto layouts = getLayouts(folders);

		double[string] scores;

		foreach (e; layouts) {
			layout = getLayout(e, "rowstag");
			scores[layout.name] = scoreLayout(layout, data);
		}

		foreach (k, v; scores.byPair.array.sort!"a[1] > b[1]") {
			"%-25s %6.3f".writefln(k, v);
		}
	}

	if (cmds["sort"].isTrue) {
		auto layouts = getLayouts(folders);

		string stat = cmds["<stat>"].toString;

		double[string] scores;

		foreach (e; layouts) {
			layout = getLayout(e, "rowstag");
			Stat[string] stats = layout.getStats(data);

			if (!(stat in stats)) {
				"Error: stat %s does not exist".writefln(stat);
				return;
			}

			scores[layout.name] = stats[stat].freq;
		}

		if (cmds["--asc"].isTrue) {
			foreach (k, v; scores.byPair.array.sort!"a[1] < b[1]") {
				"%-25s %6.3f%%".writefln(k, v);
			}
		} else {
			foreach (k, v; scores.byPair.array.sort!"a[1] > b[1]") {
				"%-25s %6.3f%%".writefln(k, v);
			}
		}
	}

	if (cmds["find"].isTrue) {
		auto filters = cmds["<filters>"].asList;

		Stat[string] statlist = findLayout("qwerty", board).getStats(data);
		foreach(f; filters) {
			string[] tokens = f.splitter(":").array;
			string stat = tokens[0];

			if (!(stat in statlist)) {
				"Error: stat %s does not exist".writefln(stat);
				return;
			}

			if (tokens.length == 1) {
				continue;
			}

			if (tokens[1].length == 0) {
				"Error: no value to the right specified".writeln;
				return;	
			}

			char comp = tokens[1][0];

			if (!"lge".canFind(comp)) {
				"Error: unrecognized comparison op \"%s\"".writefln(comp);
				return;
			}

			try {
				tokens[1][1 .. $].to!double;
			} catch (ConvException e) {
				"Error: unable to parse value for filter %s".writefln(stat);
				return;
			}
		}

		"%-25s".writef("Layouts");

		foreach(f; filters) {
			string[] tokens = f.splitter(":").array;
			string stat = tokens[0];

			if (tokens.length > 1) {
				char comp = tokens[1][0];

				if (comp == 'e') {
					continue;
				}
			}

			"%12s".writef(stat.toUpper);
		}

		writeln;

		foreach (e; getLayouts(folders)) {
			layout = e.getLayout(board);
			Stat[string] stats = layout.getStats(data);

			bool passes = true;
			double[] res;

			foreach(f; filters) {
				string[] tokens = f.splitter(":").array;

				string stat = tokens[0];

				if (tokens.length == 1) {
					res ~= stats[stat].freq;
					continue;
				} 

				char comp = tokens[1][0];
				double value = tokens[1][1 .. $].to!double;

				if (
					(comp == 'l' && stats[stat].freq >= value) ||
					(comp == 'g' && stats[stat].freq <= value) ||
					(comp == 'e' && stats[stat].freq != value)
				) {
					passes = false;
					break;
				}

				if (comp != 'e') {
					res ~= stats[stat].freq;
				}
			}

			if (passes) {
				"%-25s ".writef(layout.name);

				foreach(val; res) {
					"%10.2f%% ".writef(val);
				}

				writeln;
			}
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