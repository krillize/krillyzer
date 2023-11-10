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

bool isAlternate(Position[] pos) {
    return (
        (!pos[0 .. 2].sameHand) &&
        (!pos[1 .. 3].sameHand)
    );
}

bool isRoll(Position[] pos) {
    return !(
        ([pos[0], pos[2]].sameHand) ||
        (pos[0 .. 2].sameFinger) ||
        (pos[1 .. 3].sameFinger)
    );
}

bool isAdjacentRoll(Position[] pos) {
    return (
        pos.isRoll && (
            pos[0 .. 2].isAdjacent ||
            pos[1 .. 3].isAdjacent
        )
    );
}

bool isRowRoll(Position[] pos) {
    return (
        pos.isRoll && (
            pos[0 .. 2].sameRow ||
            pos[1 .. 3].sameRow
        )
    );
}

bool isInroll(Position[] pos) {
    return (
        pos.isRoll &&
        max(pos[0 .. 2].direction, pos[1 .. 3].direction) == 1
    );
}

bool isOutroll(Position[] pos) {
    return (
        pos.isRoll &&
        min(pos[0 .. 2].direction, pos[1 .. 3].direction) == -1
    );
}

bool isRedirect(Position[] pos) {
    return (
        (pos[0 .. 2].sameHand) &&
        (pos[1 .. 3].sameHand) &&
        (!pos[0 .. 2].sameFinger) &&
        (!pos[1 .. 3].sameFinger) &&
        (pos[0 .. 2].direction != pos[1 .. 3].direction)
    );
}

bool isOnehand(Position[] pos) {
    return (
        (pos[0 .. 2].sameHand) &&
        (pos[1 .. 3].sameHand) &&
        (!pos[0 .. 2].sameFinger) &&
        (!pos[1 .. 3].sameFinger) &&
        (pos[0 .. 2].direction == pos[1 .. 3].direction)
    );
}