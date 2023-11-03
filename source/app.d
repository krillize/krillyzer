import std;
import docopt : docopt;

import corpus;
import layout;

immutable string doc = "
krillyzer

Usage:
  krillyzer list (layouts | corpora) [--contains=<string>]
  krillyzer load <corpus> [--file]
  krillyzer freq <bigram> [--ignoreCase]
  krillyzer view <layout>
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

	if (cmds["view"].isTrue) {
		try {
			auto layout = getLayout(cmds["<layout>"].toString);
			layout.writeln;
		} catch (ParserException e) {
			"Error in layout file: %s".writefln(e.msg);
		}
	}
	
    // writeln(cmds);
}