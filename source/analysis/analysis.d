module analysis.analysis;

import std;

import layout;
import analysis.stats;
import analysis.util;

struct Stat {
    double count = 0;
    double total = 0;
    string[] ngram;

    double freq() {
        return count / total * 100;
    }

    double exists() {
        return count != 0;
    }
}

Stat[string] getMono(Layout layout, JSONValue json = "data.json".readText.parseJSON) {
    auto stats = [
        "top":    &isTop,
        "home":   &isHome,
        "bottom": &isBottom,
        "center": &isCenter,

        "pinky":  &isPinky,
        "ring":   &isRing,
        "middle": &isMiddle,
        "index":  &isIndex,
        "thumb":  &isThumb,

        "LH":     &isLH,
        "RH":     &isRH,

        "LP":     &isLP,
        "LR":     &isLR,
        "LM":     &isLM,
        "LI":     &isLI,
        "LT":     &isLT,
        "RT":     &isRT,
        "RI":     &isRI,
        "RM":     &isRM,
        "RR":     &isRR,
        "RP":     &isRP,
    ];
    
    Stat[string] res;
    foreach(k; stats.byKey) {
        res[k] = Stat();
    }

    double total = 0;
    foreach(e; json["monograms"].object.byKeyValue) {
        dchar k = e.key.to!dchar;
        double v = e.value.get!double;

        total += v;

        if (!(k in layout.keys)) {
            continue;
        }

        Position pos = layout.keys[k];
        foreach(stat, fn; stats) {
            if (!fn(pos)) {
                continue;
            }

            res[stat].ngram ~= k.to!string;
            res[stat].count += v;
        }
    }

    foreach(ref v; res.byValue) {
        v.total = total;
    }

    return res;
}