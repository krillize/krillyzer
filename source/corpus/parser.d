module corpus.parser;

import std;

int[string] ngrams(string text, int n) {
    int[string] counts;

    text.slide(n)
        .map!(x => x.to!string)
        .filter!(x => !x.canFind(" "))
        .each!(x => counts[x]++);

    return counts;
}

int[string] skipgrams(string text, int n) {
    int[string] counts;

    text.slide(2 + n)
        .map!(x => x.to!string)
        .map!(x => x[0 .. 1] ~ x[$ - 1 .. $])
        .filter!(x => !x.canFind(" "))
        .each!(x => counts[x]++);

    return counts;
}

auto getCorpora() {
    return "corpora".dirEntries("*.txt", SpanMode.depth)
        .map!(x => x[8 .. $-4]);
}

void setCorpus(string corpus, bool file = true) {
    string path = file ? corpus : "corpora/%s.txt".format(corpus);

    if (!path.exists) {
        "corpus \"%s\" not found".writefln(corpus);
        return;
    } 

    writeln("Processing data...");

    string text = path.readText;

    [
        "bigrams":   text.ngrams(2),
        "skipgrams": text.skipgrams(1),
    ].JSONValue.to!string.toFile("data.json");

    writeln("Done.");
}