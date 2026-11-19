// C-мост к Clipper 6.4.2 (C++) для Swift.
// Кодировка контуров: [npaths, n0, x0,y0, x1,y1, ..., n1, ...] (int64).
#ifndef ClipperBridge_h
#define ClipperBridge_h
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
/// clipType: 0 Intersection, 1 Union, 2 Difference, 3 Xor; fill: 0 EvenOdd, 1 NonZero, 2 Positive, 3 Negative
int64_t* cb_boolean(int clipType, int subjFill, int clipFill, int strictlySimple, const int64_t* subj, const int64_t* clip, int64_t* outLen);
/// groups: [ngroups, (jt, et, <пути>)...]; jt: 0 Square, 1 Round, 2 Miter; et: 0 ClosedPolygon, 1 ClosedLine, 2 OpenButt, 3 OpenSquare, 4 OpenRound
int64_t* cb_offset(double miterLimit, double arcTolerance, const int64_t* groups, double delta, int64_t* outLen);
void cb_free(int64_t* p);
#ifdef __cplusplus
}
#endif
#endif
