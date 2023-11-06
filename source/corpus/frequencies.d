module corpus.frequencies;

import std;

import corpus.parser;

double freq(string ngram, double[string] bigrams) {
    return cast(float) bigrams.get(ngram, 0) / bigrams.values.sum;
}

void showFreq(string ngram, bool ignoreCase = false) {
    if (ngram.length != 2) {
        writeln("Error: ngram must be of length 2");
        return;
    }

    string margn = ngram.dup.reverse;

    auto bigrams = getBigrams(ignoreCase);
    auto skipgrams = getSkipgrams(ignoreCase);

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