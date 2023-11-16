module corpus.parser;

import std;

string[] getCorpora() {
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

    dchar[] text = path.readText.array;

    double[string] monograms;
    double[string] bigrams;
    double[string] trigrams;
    double[string] skipgrams;
    double[string] speedgrams;

    foreach (i; 0 .. text.length) {
        monograms[text[i].to!string]++;

        foreach (j; 0 .. 4) {
            if (i + j + 2 > text.length) {
                break;
            }

            string gram = [text[i], text[i + j + 1]].to!string;

            if (gram.canFind(' ')) {
                continue;
            }

            if (j == 0) {
                bigrams[gram]++;
            }

            if (j == 1) {
                skipgrams[gram]++;
            }

            if (j == 1 && text[i + j] != ' ') {
                trigrams[text[i .. i + 3].to!string]++;
            }

            speedgrams[gram] += 1.0 / (j + 1).pow(2);
        }
    }

    monograms[" "] = 0;

    [
        "monograms":  monograms,
        "bigrams":    bigrams,
        "trigrams":   trigrams,
        "skipgrams":  skipgrams,
        "speedgrams": speedgrams,
    ].JSONValue.toPrettyString.toFile("data.json");

    writeln("Done.");
}

double[string] getBigrams(bool ignoreCase = false, bool pairs = false) {
    auto json = "data.json".readText.parseJSON;

    double[string] bigrams;
    foreach (string k, v; json["bigrams"]) {
        string gram = ignoreCase ? k.toLower : k;
        gram = pairs ? gram.array.sort.to!string : gram;
        bigrams[gram] += v.get!double;
    }

    return bigrams;
}

double[string] getSkipgrams(bool ignoreCase = false) {
    auto json = "data.json".readText.parseJSON;

    double[string] skipgrams;
    foreach (string k, v; json["skipgrams"]) {
        if (ignoreCase) {
            skipgrams[k.toLower] += v.get!double;
        } else {
            skipgrams[k] += v.get!double;
        }
    }

    return skipgrams;
}