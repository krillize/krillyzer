module analysis.stats;

import std;

import layout.keyboard;
import analysis.util;

// monogram row stats
bool isCenter(Position[] pos) {
    return [4, 5].canFind(pos[0].col);
}

bool isTop(Position[] pos) {
    return !pos.isCenter && pos[0].row == 0;
}

bool isHome(Position[] pos) {
    return !pos.isCenter && pos[0].row == 1;
}

bool isBottom(Position[] pos) {
    return !pos.isCenter && pos[0].row == 2;
}

// monogram finger stats
bool isLP(Position[] pos) {
    return pos[0].finger == 0;
}

bool isLR(Position[] pos) {
    return pos[0].finger == 1;
}

bool isLM(Position[] pos) {
    return pos[0].finger == 2;
}

bool isLI(Position[] pos) {
    return pos[0].finger == 3;
}

bool isLT(Position[] pos) {
    return pos[0].finger == 4;
}

bool isRT(Position[] pos) {
    return pos[0].finger == 5;
}

bool isRI(Position[] pos) {
    return pos[0].finger == 6;
}

bool isRM(Position[] pos) {
    return pos[0].finger == 7;
}

bool isRR(Position[] pos) {
    return pos[0].finger == 8;
}

bool isRP(Position[] pos) {
    return pos[0].finger == 9;
}

bool isPinky(Position[] pos) {
    return pos.isLP || pos.isRP;
}

bool isRing(Position[] pos) {
    return pos.isLR || pos.isRR;
}

bool isMiddle(Position[] pos) {
    return pos.isLM || pos.isRM;
}

bool isIndex(Position[] pos) {
    return pos.isLI || pos.isRI;
}

bool isThumb(Position[] pos) {
    return pos.isLT || pos.isRT;
}

bool isLH(Position[] pos) {
    return (
        pos.isLP ||
        pos.isLR ||
        pos.isLM ||
        pos.isLI
    );
}

bool isRH(Position[] pos) {
    return (
        pos.isRP ||
        pos.isRR ||
        pos.isRM ||
        pos.isRI
    );
}

// sfb bigram stats
bool isSFB(Position[] pos) {
	return !pos.isRepeat && pos.sameFinger;
}

bool isPinkySFB(Position[] pos) {
    return pos.isSFB && pos.isPinky;
}

bool isRingSFB(Position[] pos) {
    return pos.isSFB && pos.isRing;
}

bool isMiddleSFB(Position[] pos) {
    return pos.isSFB && pos.isMiddle;
}

bool isIndexSFB(Position[] pos) {
    return pos.isSFB && pos.isIndex;
}

bool isThumbSFB(Position[] pos) {
    return pos.isSFB && pos.isThumb;
}

// other bigram stats
bool isLSB(Position[] pos) {
    return pos.isAdjacent && pos.distHorizontal >= 2;
}

double distSFB(Position[] pos) {
    return pos.isSFB * pos.distance;
}

double distLSB(Position[] pos) {
    return pos.isLSB * pos.distance;
}

// trigram stats
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
            (
                pos[0 .. 2].sameRow &&
                pos[0 .. 2].sameHand
            ) ||
            (
                pos[1 .. 3].sameRow &&
                pos[1 .. 3].sameHand
            )
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