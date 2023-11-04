module corpus.parser;

import std;

int[string] ngrams(string text, int n) {
    int[string] counts;

    foreach (item; text.slide(n)) {
        if (item.canFind(" ")) {
            continue;
        }

        counts[item.to!string]++;
    }

    return counts;
}

int[string] skipgrams(string text, int n) {
    int[string] counts;

    foreach (item; text.slide(2 + n)) {
        auto gram = item.array;
        
        if (gram[0] == ' ' || gram[$ - 1] == ' ') {
            continue;
        }

        counts[[gram[0], gram[$ - 1]].to!string]++;
    }

    return counts;
}

auto getCorpora() {
    return "corpora".dirEntries("*.txt", SpanMode.depth)
        .map!(x => x[8 .. $-4]).array;
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
    ].JSONValue.toPrettyString.toFile("data.json");

    writeln("Done.");
}

int[string] getBigrams(bool ignoreCase = false) {
    auto json = "data.json".readText.parseJSON;

    int[string] bigrams;
    foreach (string k, v; json["bigrams"]) {
        if (ignoreCase) {
            bigrams[k.toLower] += v.get!int;
        } else {
            bigrams[k] += v.get!int;
        }
    }

    return bigrams;
}

int[string] getSkipgrams(bool ignoreCase = false) {
    auto json = "data.json".readText.parseJSON;

    int[string] skipgrams;
    foreach (string k, v; json["skipgrams"]) {
        if (ignoreCase) {
            skipgrams[k.toLower] += v.get!int;
        } else {
            skipgrams[k] += v.get!int;
        }
    }

    return skipgrams;
}
