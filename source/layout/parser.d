module layout.parser;

import std;

import layout.keyboard;
import parsing;

string getBasename(string path) {
    return path.baseName[0 .. $ - 4];
}

auto getLayouts() {
    return "layouts".dirEntries("*.txt", SpanMode.depth).map!(x => x.to!string).array;
}

Layout findLayout(string name, string boardname) {
    auto layouts = "layouts".dirEntries("*.txt", SpanMode.depth).array;
    auto path = layouts.minElement!(x => 
        levenshteinDistance(name, x.getBasename)
    );

    enforce!ParserException(
        levenshteinDistance(name, path.getBasename) == 0,
        "layout \"%s\" not found, did you mean %s?".format(name, path.getBasename)
    );

    return getLayout(path, boardname);
}

Layout getLayout(string path, string boardname) {
    auto boards = "boards".dirEntries("*%s.txt".format(boardname), SpanMode.depth).array;

    string[string] data = parseFile(path.File);
    string[string] board = parseFile(boards[0].File);

    auto missing = ["main", "format", "name"].filter!(x => !(x in data));
    enforce!ParserException(missing.empty, 
        "missing keys %s".format(missing.join(", "))
    );

    enforce!ParserException(["standard", "angle", "custom"].canFind(data["format"]), 
        "format value \"%s\" not recognized".format(data["format"])
    );

    auto rows = data["main"].splitter("\n").map!(x => x.splitter.walkLength).array;

    enforce!ParserException(rows.length == 3 || data["format"] == "custom",
        "format %s expects 3 rows (found %s)".format(data["format"], rows.length)
    );

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

    Layout layout;

    layout.date    = data.get("date", "0001-01-01");
    layout.authors = data.get("author", "??").splitter("\n").array;
    layout.source  = data.get("source", "??");
    layout.desc    = data.get("desc", "??");

    layout.name = data["name"];
    layout.format = data["format"];
    layout.main = data["main"];

    int row;
    int col;

    double[] roff = [0];
    double[] coff = [0];

    if (board["offset"] == "row") {
        roff = board["stagger"].splitter("\n").map!(x => x.parse!double).array;
    }
    
    if (board["offset"] == "col") {
        coff = board["stagger"].splitter("\n").map!(x => x.parse!double).array;
    }

    Position[dchar] keys;
    foreach (ch, sh, finger; zip(data["main"], data["shift"], data["fingers"])) {
        if (ch == '\n') {
            row++;
            col = 0;
            continue;
        }

        if (ch == ' ') {
            col++;
            continue;
        }

        if (ch == '~') {
            continue;
        }

        Position pos = Position(
            row,
            col,
            row + coff[min(row, coff.length.to!int - 1)],
            col + roff[min(row, roff.length.to!int - 1)],
            (finger - '0').to!Finger,
            ((finger - '0') > 4).to!Hand
        );

        keys[ch] = pos;
        keys[sh] = pos;

        if (pos.finger == 4 || pos.finger == 5) {
            layout.hasThumb = true;
        }
    }

    layout.keys = keys;
    return layout;
}