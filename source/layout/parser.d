module layout.parser;

import std;

import layout.keyboard;

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
            if (tokens[0] == ")" && tokens.length == 1) {
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

            if (tokens.length < 2) {
                "Error, missing value after token \"%s\" in %s".writefln(tokens[0], name);
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
        "Error, list in %s definition was never closed".writefln(name);
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

    switch (data["format"]) {
        case "standard":
            data["fingers"] = (
                "0 1 2 3 3 6 6 7 8 9\n" ~
                "0 1 2 3 3 6 6 7 8 9\n" ~
                "0 1 2 3 3 6 6 7 8 9"
            );
            break;
        case "angle":
            data["fingers"] = (
                "0 1 2 3 3 6 6 7 8 9\n" ~
                "0 1 2 3 3 6 6 7 8 9\n" ~
                "1 2 3 3 3 6 6 7 8 9"
            );
            break;
        case "custom":
            break;
        default:
            "Error, format \"%s\" not valid in %s".writefln(data["format"], name);
            return;
    }

    if (!("fingers" in data)) {
        "Error, no finger definition in %s".writefln(name);
        return;
    }

    if (!("shift" in data)) {
        auto shifter = zip(
            "abcdefghijklmnopqrstuvwxyz-=[],.;/'",
            "ABCDEFGHIJKLMNOPQRSTUVWXYZ_+{}<>:?\"",
        ).assocArray;

        data["shift"] = data["main"].map!(x => shifter.get(x, x)).to!string;
    }

    // data["name"].writeln;
    // data["main"].splitter("\n").each!(x => "  %s".writefln(x));

    // data.JSONValue.to!string.writeln;

    foreach (k, v; data) {
        "%s\n%s\n".writefln(k, v);
    }
}

