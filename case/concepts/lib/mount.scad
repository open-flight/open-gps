// =====================================================================
//  "TwistLock" mount system shared by every concept.
//
//  Device side : a recessed quarter-turn SOCKET moulded into the back (flush back, nothing
//                to dig into the palm). Opening = a 20.6 mm neck hole with two lug notches;
//                behind the 1.6 mm lip is a 25.6 mm chamber with rotation stops.
//  Mount side  : one shared male PUCK (two 60-degree lugs) that screws onto
//                  - the cart-bar clamp (22-32 mm round tubes, TPU shims) via a tilt knuckle
//                  - the bag-strap clip
//  Fit: push the device onto the puck with the screen turned 90 degrees, twist 90 degrees
//  until it hits the stop (screen upright). A bump on each lug clicks into a dimple in the
//  chamber ceiling (detent, not modelled).
//
//  Same convention as Garmin bike-computer mounts (device female, mount male). The sizes
//  here are NOT verified against a Garmin mount; see the concepts README.
// =====================================================================

qt_r_neck = 10.0;    // puck neck radius
qt_r_lug  = 12.5;    // lug tip radius
qt_lug_a  = 60;      // lug angular width
qt_clr    = 0.3;
qt_lip    = 1.6;     // socket lip (device back skin around the opening)
qt_chamber= 2.0;     // lug chamber height
qt_floor  = 1.0;     // skin between the chamber and the device interior
qt_depth  = qt_lip + qt_chamber;               // 3.6 below the back surface
qt_boss_r = qt_r_lug + qt_clr + 2.4;           // material ring around the chamber
qt_neck_h = qt_lip + 0.3;
qt_lug_t  = 1.6;
qt_lugs   = [0, 180];
qt_entry  = 90;      // socket notch angle (device frame); locked = notch - 90 -> lugs along device x

module sector2d(r, a0, a1, step = 5) polygon(concat([[0, 0]], [for (a = [a0 : (a1 - a0)/ceil((a1 - a0)/step) : a1]) [r*cos(a), r*sin(a)]]));

// cutter, origin at the back-surface centre, +z into the device
module qt_socket_cut() {
    translate([0, 0, -1]) linear_extrude(qt_lip + 1.01) {
        circle(r = qt_r_neck + qt_clr, $fn = 64);
        for (a = qt_lugs) sector2d(qt_r_lug + qt_clr, qt_entry + a - qt_lug_a/2 - 3, qt_entry + a + qt_lug_a/2 + 3);
    }
    // chamber: neck circle + the 90-degree travel of each lug; the rest stays solid as the stops
    translate([0, 0, qt_lip]) linear_extrude(qt_chamber) {
        circle(r = qt_r_neck + qt_clr, $fn = 64);
        for (a = qt_lugs) sector2d(qt_r_lug + qt_clr, qt_entry + a - 90 - qt_lug_a/2 - 1, qt_entry + a + qt_lug_a/2 + 3);
    }
}
module qt_socket_boss() cylinder(r = qt_boss_r, h = qt_depth + qt_floor, $fn = 64);

// male puck; origin on the mating plane (= device back surface), +z toward the device.
// Printed lugs-down; the flange gets a 45-degree underside so it needs no support.
puck_r = 17.5; puck_t = 3.0;
module qt_puck(lock = true) {
    rot = lock ? qt_entry - 90 : qt_entry;
    color("#2b2b2b") difference() {
        union() {
            translate([0, 0, -puck_t]) cylinder(r = puck_r, h = puck_t, $fn = 64);
            cylinder(r = qt_r_neck, h = qt_neck_h + qt_lug_t, $fn = 64);
            translate([0, 0, qt_neck_h]) linear_extrude(qt_lug_t) rotate(rot) for (a = qt_lugs) sector2d(qt_r_lug, a - qt_lug_a/2, a + qt_lug_a/2);
        }
        // 2x M3 countersunk, between the lugs
        rotate(rot) for (a = [90, 270]) rotate(a) translate([14.2, 0, -puck_t - 1]) {
            cylinder(d = 3.4, h = 10, $fn = 16);
            translate([0, 0, puck_t + 1 - 1.7]) cylinder(d1 = 3.4, d2 = 6.6, h = 1.71, $fn = 16);
        }
    }
}

// ---------------------------------------------------------------------
// Cart-bar clamp. Frame: tube axis = X through the origin. Bore fits a 32 mm tube; the
// printed TPU shims step it down to 25.4 mm (1") and 22.2 mm (7/8"). Two M4 x 25 + nuts.
// Upper half carries a GoPro-style 2-prong knuckle (axis // tube) for screen tilt.
// ---------------------------------------------------------------------
bar_bore  = 32.5;
clamp_w   = 18;
clamp_ro  = bar_bore/2 + 4.5;
clamp_ear = clamp_ro + 5.5;            // bolt axis offset
knk_r     = 7.5;
knk_z     = clamp_ro + knk_r + 1.5;    // knuckle axis height above the tube axis
knk_t     = 3.0;
module knuckle_prong(x) translate([x - knk_t/2, 0, 0]) rotate([0, 90, 0]) cylinder(r = knk_r, h = knk_t, $fn = 40);

module clamp_half(upper = true) {
    color(upper ? "#3a3f45" : "#4a5058") difference() {
        intersection() {
            union() {
                rotate([0, 90, 0]) cylinder(r = clamp_ro, h = clamp_w, center = true, $fn = 64);
                hull() for (s = [-1, 1]) translate([0, s*clamp_ear, 0]) cylinder(r = 5.5, h = 14, center = true, $fn = 32);
                if (upper) hull() {
                    for (x = [-4.5, 4.5]) translate([x, 0, knk_z]) rotate([0, 90, 0]) cylinder(r = knk_r, h = 0.01, center = true, $fn = 40);
                    translate([-4.5, -9, clamp_ro - 3]) cube([9, 18, 1]);
                }
            }
            translate([-50, -50, upper ? 0.4 : -100.4]) cube([100, 100, 100]);
        }
        rotate([0, 90, 0]) cylinder(d = bar_bore, h = clamp_w + 2, center = true, $fn = 64);
        for (s = [-1, 1]) translate([0, s*clamp_ear, -20]) cylinder(d = 4.4, h = 40, $fn = 16);
        if (upper) {   // slot between the two prongs + knuckle bore
            translate([-1.65, -20, clamp_ro - 1]) cube([3.3, 40, 30]);
            translate([-20, 0, knk_z]) rotate([0, 90, 0]) cylinder(d = 5.3, h = 40, $fn = 20);
            for (x = [-20, 4.5]) translate([x, -20, clamp_ro - 1]) cube([15.5, 40, 30]);
        }
    }
}
module clamp_shim(d_tube) color("#e0a030", 0.9) difference() {
    rotate([0, 90, 0]) cylinder(d = bar_bore - 0.4, h = clamp_w - 1, center = true, $fn = 64);
    rotate([0, 90, 0]) cylinder(d = d_tube + 0.3, h = clamp_w + 2, center = true, $fn = 64);
    translate([-20, -1, -30]) cube([40, 2, 30]);   // split so it wraps the tube
}

// tilt head: 3-prong knuckle at the origin (axis X) + pad that carries the puck.
// Puck mating plane at z = tilt_puck_z (in the head frame).
tilt_pad_z  = 11;
tilt_puck_z = tilt_pad_z + 4 + puck_t;
module tilt_head() {
    color("#3a3f45") tilt_head_body();
    translate([0, 0, tilt_puck_z]) qt_puck();
    // M5 bolt + thumb knob (drawn only)
    color("#aaa") translate([-12, 0, 0]) rotate([0, 90, 0]) cylinder(d = 5, h = 24, $fn = 16);
    color("#2b2b2b") translate([10.5, 0, 0]) rotate([0, 90, 0]) cylinder(d = 16, h = 6, $fn = 8);
}
module tilt_head_body() {
    difference() {
        union() {
            for (x = [-6.3, 0, 6.3]) hull() {
                knuckle_prong(x);
                translate([x - knk_t/2, -10, tilt_pad_z - 0.01]) cube([knk_t, 20, 0.01]);
            }
            translate([0, 0, tilt_pad_z]) cylinder(r = puck_r + 1, h = 4, $fn = 64);
        }
        translate([-20, 0, 0]) rotate([0, 90, 0]) cylinder(d = 5.3, h = 40, $fn = 20);
    }
}

// complete cart mount; `tilt` = degrees the puck face is tipped from straight up toward -Y
// (the golfer). Children are placed in the PUCK frame (mating plane, +z toward the device).
module cart_mount(tilt = 55, tube_d = 25.4, bar_len = 120) {
    color("#9aa3ab") rotate([0, 90, 0]) cylinder(d = tube_d, h = bar_len, center = true, $fn = 64);
    clamp_half(true);
    clamp_half(false);
    if (tube_d < 32) clamp_shim(tube_d);
    color("#aaa") for (s = [-1, 1]) translate([0, s*clamp_ear, -10]) cylinder(d = 4, h = 21, $fn = 12);
    translate([0, 0, knk_z]) rotate([tilt, 0, 0]) {
        tilt_head();
        translate([0, 0, tilt_puck_z]) children();
    }
}

// ---------------------------------------------------------------------
// Bag-strap clip. Frame: front plate in XY (y up), its front face at z = 0, puck on the
// front. A spring tongue folds back over the top and runs down behind a strap up to
// `strap_gap` thick; side slots take a 25 mm hook-and-loop strap for thick/padded straps
// or the cart bar of a riding cart that isn't round. Printed on its side (the U profile
// is a plain extrusion), puck screwed on afterwards.
// ---------------------------------------------------------------------
clip_w = 48; clip_h = 74; clip_t = 4; strap_gap = 12;
clip_puck_y = clip_h/2 + 4;
module strap_clip() {
    color("#3a3f45") difference() {
        union() {
            translate([-clip_w/2, 0, -clip_t]) cube([clip_w, clip_h, clip_t]);                       // front plate
            translate([-clip_w/2 + 6, clip_h - 6, -clip_t - strap_gap - 3.5]) cube([clip_w - 12, 6, strap_gap + 3.5 + 0.01]);   // bend
            translate([-clip_w/2 + 6, 16, -clip_t - strap_gap - 3.5]) cube([clip_w - 12, clip_h - 16, 3.5]); // tongue
            hull() {   // flared lead-in at the tongue tip
                translate([-clip_w/2 + 6, 16, -clip_t - strap_gap - 3.5]) cube([clip_w - 12, 0.01, 3.5]);
                translate([-clip_w/2 + 6, 8, -clip_t - strap_gap - 7]) cube([clip_w - 12, 2, 2.5]);
            }
            translate([-clip_w/2 + 6, 30, -clip_t - strap_gap]) rotate([0, 90, 0]) cylinder(d = 3, h = clip_w - 12, $fn = 16);   // retaining ridge
        }
        for (s = [-1, 1]) translate([s*(clip_w/2 - 4.5) - 2, 14, -clip_t - 1]) cube([4, 28, clip_t + 2]);   // strap slots
    }
    translate([0, clip_puck_y, puck_t]) qt_puck();
}
module strap_ghost(len = 140) color("#7a2f2f") translate([-20, clip_h/2 - len/2, -clip_t - 10.5]) cube([40, len, 10]);

// stand-alone kit layout for the mount render (everything stood up, facing -y)
module mount_kit() {
    cart_mount(tilt = 25, tube_d = 25.4, bar_len = 56);
    translate([85, 0, -20]) rotate([90, 0, 0]) translate([0, -clip_h/2, 0]) { strap_clip(); strap_ghost(120); }
    translate([-62, 0, 10]) rotate([70, 0, 0]) translate([0, 0, puck_t]) qt_puck(lock = false);
    translate([-62, 10, -30]) rotate([70, 0, 0]) clamp_shim(22.2);
}
