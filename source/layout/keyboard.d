module layout.keyboard;

import std;

enum Finger {LP, LR, LM, LI, LT, RT, RI, RM, RR, RP}
enum Hand   {Left, Right}
enum Row    {top, home, bottom}

struct Position {
    int row;
    int col;

    double x;
    double y;

    Finger finger;
    Hand hand;

    string toString() const @safe pure {
        if (row == x && col == y) {
            return "F=%s, (%s, %s)".format(
                finger, row, col
            );
        } else {
            return "F=%s, (%s, %s) => (%s, %s)".format(
                finger, row, col, x, y
            );
        }
    }
}

struct Layout {
    string name;
    string date;
    string format;
    string[] authors;
    string source;
    string desc;
    string main;
    bool hasThumb;
    
    Position[dchar] keys;

    void swap(dchar a, dchar b) {
        auto temp = this.keys[a];
        this.keys[a] = this.keys[b];
        this.keys[b] = temp;

        this.main = this.main.map!(x => [a: b, b: a].get(x, x)).to!string;
    }
}