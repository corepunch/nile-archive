/* Dijkstra on a small geometric graph, with live circular segment blockers.
 * Routes include the actor and final approach; failures clear the old result. */
#include "engine.h"
#include <math.h>
#include <float.h>

static float segment_distance(vec2 p, vec2 a, vec2 b)
{
    vec2 d = vec2_sub(b, a);
    float len = vec2_dot(d, d);
    float t = len > 0 ? saturate(vec2_dot(vec2_sub(p, a), d) / len) : 0;
    return vec2_dist(p, vec2_add(a, vec2_scale(d, t)));
}
static bool blocked(const nav *g, vec2 a, vec2 b, int ignore)
{
    for (int i = 0; i < g->blocker_count; i++)
        if (i != ignore && g->blockers[i].radius > 0 &&
            segment_distance(g->blockers[i].pos, a, b) < g->blockers[i].radius) return true;
    return false;
}
static int nearest(const nav *g, vec2 p)
{
    int best = -1; float cost = FLT_MAX;
    for (int i = 0; i < g->node_count; i++) {
        float d = vec2_dist(g->nodes[i], p);
        if (d < cost) best = i, cost = d;
    }
    return best;
}
static void trim(nav *g, vec2 centre, vec2 axes)
{
    if (axes.x <= 0 || axes.y <= 0) return;
    for (int i = 0; i + 1 < g->path_count; i++) {
        vec2 a = g->path[i], b = g->path[i + 1];
        vec2 o = vec2_div(vec2_sub(a, centre), axes);
        if (vec2_dot(o, o) <= 1) { g->path_count = i + 1; return; }
        vec2 end = vec2_div(vec2_sub(b, centre), axes);
        if (vec2_dot(end, end) > 1) continue;
        vec2 d = vec2_div(vec2_sub(b, a), axes);
        float qa = vec2_dot(d, d), qb = 2 * vec2_dot(o, d), qc = vec2_dot(o, o) - 1;
        float disc = qb * qb - 4 * qa * qc;
        float t = qa > 0 && disc >= 0 ? saturate((-qb - sqrtf(disc)) / (2 * qa)) : 1;
        g->path[i + 1] = vec2_lerp(a, b, t); g->path_count = i + 2; return;
    }
}
bool nav_find(nav *g, vec2 start, vec2 finish, int ignore, vec2 footprint)
{
    g->path_count = 0; g->length = 0;
    if (g->node_count <= 0 || g->node_count > NAV_NODES || g->blocker_count < 0 || g->blocker_count > NAV_BLOCKERS) return false;
    int from = nearest(g, start), to = nearest(g, finish), parents[NAV_NODES];
    float costs[NAV_NODES]; bool seen[NAV_NODES] = {0};
    for (int i = 0; i < g->node_count; i++) costs[i] = FLT_MAX, parents[i] = -1;
    costs[from] = 0;
    float link = g->link_distance > 0 ? g->link_distance : 50;
    for (;;) {
        int cur = -1; float cost = FLT_MAX;
        for (int i = 0; i < g->node_count; i++) if (!seen[i] && costs[i] < cost) cur = i, cost = costs[i];
        if (cur < 0) return false;
        if (cur == to) break;
        seen[cur] = true;
        for (int i = 0; i < g->node_count; i++) {
            if (seen[i]) continue;
            float d = vec2_dist(g->nodes[cur], g->nodes[i]);
            if (d < link && cost + d < costs[i] && !blocked(g, g->nodes[cur], g->nodes[i], ignore))
                costs[i] = cost + d, parents[i] = cur;
        }
    }
    int count = 0;
    for (int i = to; i >= 0; i = parents[i]) count++;
    g->path[0] = start; g->path_count = count + 1;
    for (int i = to, k = count; i >= 0; i = parents[i], k--) g->path[k] = g->nodes[i];
    if (vec2_dist(g->path[g->path_count - 1], finish) > .01f) g->path[g->path_count++] = finish;
    trim(g, finish, footprint);
    for (int i = 1; i < g->path_count; i++) {
        if (blocked(g, g->path[i - 1], g->path[i], ignore)) { g->path_count = 0; g->length = 0; return false; }
        g->length += vec2_dist(g->path[i - 1], g->path[i]);
    }
    return true;
}
