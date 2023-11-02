import std;
import docopt : docopt;

import corpus;
import layout;

immutable string doc = "
krillyzer

Usage:
  krillyzer load <corpus> [--file]
  krillyzer list
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
		writeln("List of Corpora:");
		getCorpora.each!(x => "  %s".writefln(x));
	}

	if (cmds["freq"].isTrue) {
		showFreq(
			cmds["<bigram>"].toString,
			cmds["--ignoreCase"].isTrue,
		);
	}

	if (cmds["view"].isTrue) {
		getLayout(cmds["<layout>"].toString);
	}
	
    // writeln(cmds);
}