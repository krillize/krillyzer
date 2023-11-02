module layout.parser;

import std;

immutable defs = [
    "name", "date", "format", "author", "fingers", 
    "source", "desc", "main", "shift"
];

void getLayout(string name) {
    auto layouts = "layouts".dirEntries("*%s.txt".format(name), SpanMode.depth).array;

    if (layouts.empty) {
        "layout \"%s\" not found...".writefln(name);
        return;
    }

    auto file = layouts[0].File;

    string[string] data = [
        "date":   "0000 01 01",
        "author": "",
        "source": "",
        "desc":   "",
    ];

    bool inList = false;
    string curr = "";

    foreach (string line; file.lines) {
        if (line.strip.length == 0) {
            continue;
        }

        auto tokens = line.strip.splitter.array;

        if (tokens[0] == "#") {
            continue;
        }

        if (inList) {
            if (tokens[0] == ")") {
                inList = false;
                data[curr] = data[curr].strip;
            } else {
                data[curr] ~= tokens.join(" ") ~ "\n";
            }
        } else {
            if (!defs.canFind(tokens[0])) {
                "Error, unexpected token \"%s\" for %s".writefln(tokens[0], name);
                return;
            }   

            if (tokens[1] == "(") {
                inList = true;
                curr = tokens[0];
            } else {
                data[tokens[0]] = tokens[1 .. $].join(" ");
            }
        }
    }

    if (inList) {
        "Error, list for %s definition was never closed".writefln(name);
        return;
    }

    auto missing = ["main", "format", "name"].filter!(x => !(x in data));
    if (!missing.empty) {
        "Error, missing definition(s) for %s: %s".writefln(
            name, 
            missing.join(", ")
        );

        return;
    }

    data["name"].writeln;
    data["main"].splitter("\n").each!(x => "  %s".writefln(x));
}