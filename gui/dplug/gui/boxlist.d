/**
Internal. Operations on list of 2D boxes.

Copyright: Guillaume Piolat 2015.
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
* Authors:   Guillaume Piolat
*/
module dplug.gui.boxlist;

import dplug.core.vec;
import gfm.math.box;

/// Returns: Bounding boxes of all bounding boxes.
box2i boundingBox(box2i[] boxes) pure nothrow @nogc
{
    if (boxes.length == 0)
        return box2i(0, 0, 0, 0);
    else
    {
        // Computes union of all boxes
        box2i unionBox = boxes[0];
        for(int i = 1; i < cast(int)boxes.length; ++i)
            unionBox = unionBox.expand(boxes[i]);
        return unionBox;
    }
}


/// Make 4 boxes that are A without C (C is contained in A)
/// Some may be empty though since C touch at least one edge of A

/// General case
/// +---------+               +---------+
/// |    A    |               |    D    |
/// |  +---+  |   After split +--+---+--+
/// |  | C |  |        =>     | E|   |F |   At least one of D, E, F or G is empty
/// |  +---+  |               +--+---+--+
/// |         |               |    G    |
/// +---------+               +---------+
void boxSubtraction(in box2i A, in box2i C, out box2i D, out box2i E, out box2i F, out box2i G) pure nothrow @nogc
{
    D = box2i(A.min.x, A.min.y, A.max.x, C.min.y);
    E = box2i(A.min.x, C.min.y, C.min.x, C.max.y);
    F = box2i(C.max.x, C.min.y, A.max.x, C.max.y);
    G = box2i(A.min.x, C.max.y, A.max.x, A.max.y);
}

// Change the list of boxes so that the coverage is the same but none overlaps
// Every box pushed in filtered are non-intersecting.
// This may modify boxes in input.
// FUTURE: something better than O(n^2)
void removeOverlappingAreas(ref Vec!box2i boxes, ref Vec!box2i filtered) nothrow @nogc
{
    for(int i = 0; i < cast(int)(boxes.length); ++i)
    {
        box2i A = boxes[i];

        assert(A.isSorted());

        // empty boxes aren't kept
        if (A.volume() <= 0)
            continue;

        bool foundIntersection = false;

        // test A against all other rectangles, if it pass, it is pushed
        for(int j = i + 1; j < cast(int)(boxes.length); ++j)
        {
            box2i B = boxes[j];

            box2i C = A.intersection(B);
            bool doesIntersect =  C.isSorted() && (!C.empty());

            if (doesIntersect)
            {
                // case 1: A contains B, B is removed from the array, and no intersection considered
                if (A.contains(B))
                {
                    // Remove that box since it has been dealt with
                    boxes.removeAndReplaceByLastElement(j);
                    j = j - 1;
                    continue;
                }

                foundIntersection = true; // A will not be pushed as is

                if (B.contains(A))
                {
                    break; // nothing from A is kept
                }
                else
                {
                    // computes A without C
                    box2i D, E, F, G;
                    boxSubtraction(A, C, D, E, F, G);

                    if (!D.empty)
                        boxes.pushBack(D);
                    if (!E.empty)
                        boxes.pushBack(E);
                    if (!F.empty)
                        boxes.pushBack(F);
                    if (!G.empty)
                        boxes.pushBack(G);

                    // no need to search for other intersection in A, since its parts have
                    // been pushed
                    break;
                }
            }
        }

        if (!foundIntersection)
            filtered.pushBack(A);
    }
}

unittest
{
    auto bl = makeVec!box2i();
    bl.pushBack( box2i(0, 0, 4, 4) );
    bl.pushBack( box2i(2, 2, 6, 6) );
    bl.pushBack( box2i(1, 1, 2, 2) );

    import dplug.core.vec;

    auto ab = makeVec!box2i();

    removeOverlappingAreas(bl, ab);
    assert(ab[] == [ box2i(2, 2, 6, 6), box2i(0, 0, 4, 2), box2i(0, 2, 2, 4) ] );

    assert(bl[].boundingBox() == box2i(0, 0, 6, 6));
}


// Split each boxes in smaller boxes.
void tileAreas(in box2i[] areas, int maxWidth, int maxHeight, ref Vec!box2i splitted) nothrow @nogc
{
    foreach(area; areas)
    {
        assert(!area.empty);
        int nWidth = (area.width + maxWidth - 1) / maxWidth;
        int nHeight = (area.height + maxHeight - 1) / maxHeight;

        foreach (int j; 0..nHeight)
        {
            int y0 = maxHeight * j;
            int y1 = y0 + maxHeight;
            if (y1 > area.height)
                y1 = area.height;

            foreach (int i; 0..nWidth)
            {
                int x0 = maxWidth * i;
                int x1 = x0 + maxWidth;
                if (x1 > area.width)
                    x1 = area.width;

                box2i b = box2i(x0, y0, x1, y1).translate(area.min);
                assert(area.contains(b));
                splitted.pushBack(b);
            }
        }
    }
}

/// For debug purpose.
/// Returns: true if none of the boxes overlap.
bool haveNoOverlap(in box2i[] areas) nothrow @nogc
{
    int N = cast(int)areas.length;

    // check every pair of boxes for overlap, inneficient
    for (int i = 0; i < N; ++i)
    {
        assert(areas[i].isSorted());
        for (int j = i + 1; j < N; ++j)
        {
            if (areas[i].intersects(areas[j]))
                return false;
        }
    }
    return true;
}

unittest
{
    assert(haveNoOverlap([ box2i( 0, 0, 1, 1), box2i(1, 1, 2, 2) ]));
    assert(!haveNoOverlap([ box2i( 0, 0, 1, 1), box2i(0, 0, 2, 1) ]));
}
