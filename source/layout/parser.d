module layout.parser;

import std;

import layout.keyboard;

immutable defs = [
    "name", "date", "format", "author", "fingers", 
    "source", "desc", "main", "shift"
];

class ParserException : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

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
            enforce!ParserException(defs.canFind(tokens[0]),
                "unexpected key \"%s\"".format(tokens[0]) 
            );

            enforce!ParserException(tokens.length > 1,
                "missing value for key \"%s\"".format(tokens[0])
            );

            if (tokens[1] == "(") {
                inList = true;
                curr = tokens[0];
            } else {
                data[tokens[0]] = tokens[1 .. $].join(" ");
            }
        }
    }

    enforce!ParserException(!inList, "list was never closed");

    auto missing = ["main", "format", "name"].filter!(x => !(x in data));
    enforce!ParserException(missing.empty, 
        "missing keys %s".format(missing.join(", "))
    );

    enforce!ParserException(["standard", "angle", "custom"].canFind(data["format"]), 
        "format value \"%s\" not recognized".format(data["format"])
    );

    auto rows = data["main"].splitter("\n").map!(x => x.splitter.walkLength).array;

    enforce!ParserException(all!"a >= 10"(rows) || data["format"] == "custom",
        "format %s doesnt support row lengths less than 10".format(data["format"])
    );

    if (data["format"] == "standard") {
        data["fingers"] = (
            "0 1 2 3 3 6 6 7 8 9" ~ " 9".repeat(rows[0] - 10).join ~ "\n" ~
            "0 1 2 3 3 6 6 7 8 9" ~ " 9".repeat(rows[1] - 10).join ~ "\n" ~
            "0 1 2 3 3 6 6 7 8 9" ~ " 9".repeat(rows[2] - 10).join
        );
    }
    
    if (data["format"] == "angle") {
        data["fingers"] = (
            "0 1 2 3 3 6 6 7 8 9" ~ " 9".repeat(rows[0] - 10).join ~ "\n" ~ 
            "0 1 2 3 3 6 6 7 8 9" ~ " 9".repeat(rows[1] - 10).join ~ "\n" ~ 
            "1 2 3 3 3 6 6 7 8 9" ~ " 9".repeat(rows[2] - 10).join
        );
    }

    enforce!ParserException("fingers" in data, "key \"fingers\" not found");
    enforce!ParserException(data["main"].length == data["fingers"].length,
        "mismatch in tokens between main and fingers keys"
    );

    if (!("shift" in data)) {
        auto shifter = zip(
            "abcdefghijklmnopqrstuvwxyz-=[],.;/'",
            "ABCDEFGHIJKLMNOPQRSTUVWXYZ_+{}<>:?\"",
        ).assocArray;

        data["shift"] = data["main"].map!(x => shifter.get(x, x)).to!string;
    }

    enforce!ParserException(data["main"].length == data["shift"].length,
        "mismatch in tokens between main and shift keys"
    );

    // data["name"].writeln;
    // data["main"].splitter("\n").each!(x => "  %s".writefln(x));

    // data.JSONValue.to!string.writeln;

    foreach (k, v; data) {
        "%s\n%s\n".writefln(k, v);
    }
}

