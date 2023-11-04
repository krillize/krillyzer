module analysis.util;

import std;

import layout.keyboard;

bool isRepeat(Position[] pos) {
    return pos[0] == pos[1];
}

bool sameFinger(Position[] pos) {
    return pos[0].finger == pos[1].finger;
}

bool sameHand(Position[] pos) {
    return pos[0].hand == pos[1].hand;
}

bool isAdjacent(Position[] pos) {
    return (
        pos.sameHand &&
        ![4, 5].canFind(pos[0].finger) &&
        ![4, 5].canFind(pos[1].finger) &&
        abs(pos[0].finger - pos[1].finger) == 1
    );
}

int direction(Position[] pos) {
    if (!pos.sameHand || pos.sameFinger) {
        return 0;
    }

    int diff;
    if (pos[0].hand) {
        diff = pos[0].finger - pos[1].finger;
    } else {
        diff = pos[1].finger - pos[0].finger;
    }

    return diff / abs(pos[0].finger - pos[1].finger);
}

int distHorizontal(Position[] pos) {
    return abs(pos[0].col - pos[1].col);
}

int distVertical(Position[] pos) {
    return abs(pos[0].row - pos[1].row);
}

float distance(Position[] pos) {
    return (
        cast(float) pos.distHorizontal.pow(2) +
        pos.distVertical.pow(2)
    ).sqrt;
}