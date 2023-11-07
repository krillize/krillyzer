module analysis.generate;

import std;

import layout;
import analysis;

double scoreLayout(Layout layout, JSONValue json) {
	double total = 0;
	double count = 0;

	foreach(e; json["speedgrams"].object.byKeyValue) {
		string k = e.key;
		double v = e.value.get!double;

		total += v;

		if (
			!(k[0] in layout.keys) ||
			!(k[1] in layout.keys)
		) {
			continue;
		}

		auto pos = k.map!(x => layout.keys[x]).array;

		if (pos.sameFinger) {
			count += v * (pos.distance + 0.1);
		}
	}

	return count / total * 100;
}

void generate() {
    auto layout = getLayout("qwerty");
	auto json = "data.json".readText.parseJSON;
	auto letters = layout.main.splitter.join;

    double best = scoreLayout(layout, json);

	string[] combos;
	foreach (i; 0 .. letters.length) {
			foreach (j; i + 1 .. letters.length) {
				combos ~= [letters[i], letters[j]];
			}
	}

	bool searching = true;
	while (searching) {
		searching = false;
		combos.randomShuffle;

		foreach (combo; combos) {
			dchar a = combo[0];
			dchar b = combo[1];
			
			layout.swap(a, b);
			auto score = scoreLayout(layout, json);

			if (score < best) {
				searching = true;
				best = score;
				break;
			}

			layout.swap(a, b);			
		}
	}

	layout.main.writeln;
	"\n%s".writefln(best);
}