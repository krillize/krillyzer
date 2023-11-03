module layout.keyboard;

import std;

enum {LP, LR, LM, LI, LT, RT, RI, RM, RR, RP}
enum {Left, Right}

struct Position {
    int row;
    int col;
    int finger;
    int hand;
}

struct Layout {
    string name;
    string date;
    string format;

    string[] authors;
    string source;

    string desc;
    
    Position[char] keys;
}