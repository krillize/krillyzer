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

    string text = path.readText;

    double[string] monograms;
    double[string] bigrams;
    double[string] trigrams;
    double[string] skipgrams;
    double[string] speedgrams;

    int back;
    int front;

    foreach (_; 0 .. 5) {
        front += std.utf.stride(text, front);
    }

    while (front < text.length) {
        string window = text[back .. front];

        back += std.utf.stride(text, back);
        front += std.utf.stride(text, front);

        foreach (i; 0 .. 3) {
            if (window[window.toUTFindex(i) .. window.toUTFindex(i+1)] == " ") {
                break;
            }

            string gram = window[0 .. window.toUTFindex(i + 1)];

            if (i == 0) {
                monograms[gram]++;
            }

            if (i == 1) {
                bigrams[gram]++;
            }

            if (i == 2) {
                trigrams[gram]++;
            }
        }   

        if (window[0 .. window.toUTFindex(1)] == " ") {
            continue;
        }

        foreach (i; 1 .. 5) {
            if (window[window.toUTFindex(i) .. window.toUTFindex(i+1)] == " ") {
                continue;
            }

            string skip  = window[0 .. window.toUTFindex(1)];
                   skip ~= window[window.toUTFindex(i) .. window.toUTFindex(i+1)];
           
            if (i == 2) {
                skipgrams[skip]++;
            }  

            speedgrams[skip] += 1.0 / (i).pow(2);
        }
    }

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