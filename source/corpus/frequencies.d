module corpus.frequencies;

import std;

double freq(string ngram, int[string] bigrams) {
    return cast(float) bigrams.get(ngram, 0) / bigrams.values.sum;
}

void showFreq(string ngram, bool ignoreCase = false) {
    if (ngram.length != 2) {
        writeln("Error: ngram must be of length 2");
        return;
    }

    string margn = ngram.dup.reverse;
    auto json = "data.json".readText.parseJSON;

    int[string] bigrams;
    foreach (string k, v; json["bigrams"]) {
        if (ignoreCase) {
            bigrams[k.toLower] += v.get!int;
        } else {
            bigrams[k] += v.get!int;
        }
    }

    int[string] skipgrams;
    foreach (string k, v; json["skipgrams"]) {
        if (ignoreCase) {
            skipgrams[k.toLower] += v.get!int;
        } else {
            skipgrams[k] += v.get!int;
        }
    }

    double freqNorm = freq(ngram, bigrams);
    double freqRevr = freq(margn, bigrams);

    writeln("Bigram %:");
    "  pair %.3f%%".writefln((freqNorm + freqRevr) * 100);
    "    %s %.3f%%".writefln(ngram, freqNorm * 100);
    "    %s %.3f%%".writefln(margn, freqRevr * 100);

    freqNorm = freq(ngram, skipgrams);
    freqRevr = freq(margn, skipgrams);

    writeln("\nSkipgram %:");
    "  pair %.3f%%".writefln((freqNorm + freqRevr) * 100);
    "    %s %.3f%%".writefln(ngram, freqNorm * 100);
    "    %s %.3f%%".writefln(margn, freqRevr * 100);
}