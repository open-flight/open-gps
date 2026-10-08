// =====================================================================
//  Shape helpers shared by the concepts.
//
//  pebble(t, pts, zb, zf, rb, rf) is a convex hull of "corner rings":
//    pts = [[x, y, Rp], ...] are plan-corner centres with the OUTER plan radius Rp,
//    rb / rf are the back / front edge radii, zb / zf the back / front faces.
//  pebble(0, ...) is the outer skin; pebble(wall, ...) is the cavity. Because every
//  ring and land shrinks by exactly t, the wall is >= t everywhere (exact offset of a
//  hull of balls), so the cavity can be trusted for fit checks.
//
//  With tear = true the back and front lands are widened so the edge starts with a
//  45-degree chamfer that blends into the radius ("printable fillet"): the shell prints
//  back-down and the lid face-down on the Bambu plate without supports or a drooping
//  first-layer edge.
// =====================================================================

module corner_ring(Rp, r, t) {
    R  = max(Rp - r, 0);
    rr = r - t;
    rotate_extrude($fn = 48) intersection() {
        translate([R, 0]) circle(r = rr, $fn = 28);
        translate([0, -rr - 1]) square([R + rr + 1, 2*rr + 2]);
    }
}

module pebble(t, pts, zb, zf, rb, rf, tear = true) {
    hull() for (p = pts) translate([p[0], p[1], 0]) {
        translate([0, 0, zb + rb]) corner_ring(p[2], rb, t);
        translate([0, 0, zf - rf]) corner_ring(p[2], rf, t);
        if (tear) {
            translate([0, 0, zb + t]) cylinder(r = max(p[2] - rb, 0) + 0.414*(rb - t), h = 0.01, $fn = 48);
            translate([0, 0, zf - t - 0.01]) cylinder(r = max(p[2] - rf, 0) + 0.414*(rf - t), h = 0.01, $fn = 48);
        }
    }
}

module rrect2(w, h, r) { offset(r) square([w - 2*r, h - 2*r], center = true); }

// chamfered window through a skin `h` thick: inner opening `win`, flaring by `flare` per side
module window_cut(win, h, flare = 1.2) hull() {
    translate([0, 0, -0.01]) linear_extrude(0.01) square(win, center = true);
    translate([0, 0, h + 0.02]) linear_extrude(0.01) square([win[0] + 2*flare, win[1] + 2*flare], center = true);
}

// U-shaped lanyard / wrist-strap passage: two holes from an end face (origin, +y inward)
// that meet in a cross-bore `depth` inside. Needs solid material around it.
module lanyard_cut(spacing = 7, d = 3.2, depth = 5) {
    for (s = [-1, 1]) translate([s*spacing/2, -2, 0]) rotate([-90, 0, 0]) cylinder(d = d, h = depth + 2, $fn = 16);
    translate([-spacing/2, depth, 0]) rotate([0, 90, 0]) cylinder(d = d, h = spacing, $fn = 16);
    for (s = [-1, 1]) translate([s*spacing/2, depth, 0]) sphere(d = d, $fn = 16);
}

