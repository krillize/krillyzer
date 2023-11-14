module parsing;

import std;

class ParserException : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

string[string] parseFile(File file) {
    string[string] data;

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

    return data;
}