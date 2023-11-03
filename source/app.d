import std;
import docopt : docopt;

import corpus;
import layout;

immutable string doc = "
krillyzer

Usage:
  krillyzer load <corpus> [--file]
  krillyzer list (layouts | corpora)
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

	if (cmds["list"].isTrue && cmds["corpora"].isTrue) {
		writeln("List of Corpora:");
		getCorpora.each!(x => "  %s".writefln(x));
	}

	if (cmds["list"].isTrue && cmds["layouts"].isTrue) {
		writeln("List of Layouts:");
		auto layouts = getLayouts.array;
		layouts.sort;
		layouts.each!(x => "  %s".writefln(x));
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