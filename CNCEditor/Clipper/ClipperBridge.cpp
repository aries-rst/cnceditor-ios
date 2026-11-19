#include "ClipperBridge.h"
#include "clipper.hpp"
#include <cstdlib>
using namespace ClipperLib;

static const int64_t* readPaths(const int64_t* p, Paths& out) {
    int64_t n = *p++;
    for (int64_t i = 0; i < n; i++) {
        int64_t m = *p++; Path pa; pa.reserve((size_t)m);
        for (int64_t j = 0; j < m; j++) { cInt x = (cInt)*p++; cInt y = (cInt)*p++; pa.push_back(IntPoint(x, y)); }
        out.push_back(pa);
    }
    return p;
}
static int64_t* writePaths(const Paths& ps, int64_t* outLen) {
    int64_t len = 1; for (const Path& pa : ps) len += 1 + 2 * (int64_t)pa.size();
    int64_t* r = (int64_t*)malloc(sizeof(int64_t) * (size_t)len); int64_t* q = r;
    *q++ = (int64_t)ps.size();
    for (const Path& pa : ps) { *q++ = (int64_t)pa.size(); for (const IntPoint& pt : pa) { *q++ = pt.X; *q++ = pt.Y; } }
    *outLen = len; return r;
}
int64_t* cb_boolean(int clipType, int subjFill, int clipFill, int strictlySimple, const int64_t* subj, const int64_t* clip, int64_t* outLen) {
    Paths s, c, sol;
    if (subj) readPaths(subj, s);
    if (clip) readPaths(clip, c);
    Clipper cl; cl.StrictlySimple(strictlySimple != 0);
    try {
        cl.AddPaths(s, ptSubject, true);
        if (!c.empty()) cl.AddPaths(c, ptClip, true);
        cl.Execute((ClipType)clipType, sol, (PolyFillType)subjFill, (PolyFillType)clipFill);
    } catch (...) { sol.clear(); }
    return writePaths(sol, outLen);
}
int64_t* cb_offset(double miterLimit, double arcTolerance, const int64_t* groups, double delta, int64_t* outLen) {
    ClipperOffset co(miterLimit, arcTolerance); Paths sol;
    const int64_t* p = groups; int64_t ng = *p++;
    for (int64_t g = 0; g < ng; g++) {
        int jt = (int)*p++; int et = (int)*p++; Paths ps; p = readPaths(p, ps);
        co.AddPaths(ps, (JoinType)jt, (EndType)et);
    }
    try { co.Execute(sol, delta); } catch (...) { sol.clear(); }
    return writePaths(sol, outLen);
}
void cb_free(int64_t* p) { free(p); }
