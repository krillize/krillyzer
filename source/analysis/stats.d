module analysis.stats;

import std;

import layout.keyboard;
import analysis.util;

bool isSFB(Position[] pos) {
	return (
        !pos.isRepeat &&
        pos.sameFinger
    );
}

bool isLSB(Position[] pos) {
    return (
        pos.isAdjacent &&
        pos.distHorizontal >= 2
    );
}

double distSFB(Position[] pos) {
    return pos.isSFB * pos.distance;
}

double distLSB(Position[] pos) {
    return pos.isLSB * pos.distance;
}