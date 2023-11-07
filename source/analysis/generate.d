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

		if (pos.isSFB) {
			count += v * pos.distance;
		}
	}

	return count / total * 100;
}

void generate() {
    auto layout = getLayout("qwerty");
	auto json = "data.json".readText.parseJSON;

    double score = scoreLayout(layout, json);

    layout.name.writeln;
	layout.main.splitter("\n").each!(x => "  %s".writefln(x));
}