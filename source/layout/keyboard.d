module layout.keyboard;

import std;

enum Finger {LP, LR, LM, LI, LT, RT, RI, RM, RR, RP}
enum Hand   {Left, Right}
enum Row    {top, home, bottom}

struct Position {
    int row;
    int col;
    Finger finger;
    Hand hand;
}

struct Layout {
    string name;
    string date;
    string format;

    string[] authors;
    string source;

    string desc;
    
    Position[dchar] keys;
}