module analysis.analysis;

import std;

import layout;
import analysis.stats;
import analysis.util;

struct Stat {
    double count = 0;
    double distance = 0;
    double total = 0;
    double[string] ngram;

    double freq(string gram = null) {
        if (gram) {
            return ngram.get(gram, 0) / total * 100;
        } else {
            return count / total * 100;
        }
    }

    double avgdist() {
        return distance / count;
    }

    double dist() {
        return distance / total * 100;
    }

    auto top(int n) {
        return ngram.keys.sort!((a, b) => ngram[a] > ngram[b]).take(n);
    }

    double exists() {
        return count != 0;
    }
}

Stat[string] countStats(Layout layout, JSONValue json, bool function(Position[])[string] stats, bool dist = false) {
    Stat[string] res;
    foreach(k; stats.byKey) {
        res[k] = Stat();
    }

    double total = 0;
    foreach(e; json.object.byKeyValue) {
        string k = e.key;
        double v = e.value.get!double;

        if (!k.all!(x => x in layout.keys)) {
            total += v;
            continue;
        }
        
        total += v;

        Position[] pos = k.map!(x => layout.keys[x]).array;
        foreach(stat, fn; stats) {
            if (!fn(pos)) {
                continue;
            }

            double dmult = dist ? pos.distance : 1;

            res[stat].ngram[k] = v * dmult;
            res[stat].distance += v * dmult;
            res[stat].count += v;
        }
    }

    foreach(ref v; res.byValue) {
        v.total = total;
    }

    return res;
}

Stat[string] getStats(Layout layout, JSONValue json = "data.json".readText.parseJSON, bool dist = false) {
    Stat[string] res;
    
    foreach (k, v; layout.getMono(json)) {
        res[k] = v;
    }

    foreach (k, v; layout.getBi(json, dist)) {
        res[k] = v;
    }

    foreach (k, v; layout.getSkip(json, dist)) {
        res[k] = v;
    }

    foreach (k, v; layout.getTri(json)) {
        res[k] = v;
    }

    return res;
}

Stat[string] getMono(Layout layout, JSONValue json = "data.json".readText.parseJSON) {
    return layout.countStats(json["monograms"], [
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
    ]);
}

Stat[string] getBi(Layout layout, JSONValue json = "data.json".readText.parseJSON, bool dist = false) {
    return layout.countStats(json["bigrams"], [
        "sfb":        &isSFB,
        "lsb":        &isLSB,

        "pinky-sfb":  &isPinkySFB,  
        "ring-sfb":   &isRingSFB, 
        "middle-sfb": &isMiddleSFB, 
        "index-sfb":  &isIndexSFB, 
        "thumb-sfb":  &isThumbSFB,   
    ], dist);
}

Stat[string] getSkip(Layout layout, JSONValue json = "data.json".readText.parseJSON, bool dist = false) {
    return layout.countStats(json["skipgrams"], [
        "sfs":        &isSFB,
    ], dist);
}

Stat[string] getTri(Layout layout, JSONValue json = "data.json".readText.parseJSON) {
    return layout.countStats(json["trigrams"], [
        "roll":    &isRoll,
        "adroll":  &isAdjacentRoll,
        "rowroll": &isRowRoll,
        "inroll":  &isInroll,
        "outroll": &isOutroll,
        
        "alt":     &isAlternate,
        "red":     &isRedirect,
        "one":     &isOnehand,
    ]);
}