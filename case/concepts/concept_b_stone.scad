// =====================================================================
//  Concept B - "STONE"   (concept-level massing model, not print-ready)
//
//  A compact, soft palm-stone that keeps v0.1's proven stack (battery on the floor,
//  chassis plate above it, boards on the plate, OLED under the lid) but rearranges
//  the front so it gets thinner and easier on the thumb:
//    * The Twist moves off the boards into the free plate corner beside the GPS
//      (bottom-right), on short plate standoffs. It no longer stacks on top of the
//      Thing Plus, so the case loses ~2 mm of depth even after adding the mount socket,
//      and the dial sits where a right thumb naturally rests.
//    * The knob sits in a dial cup (recessed well), so it's lower and protected.
//    * Big front radius, 45-degree printable lead-in on both faces.
//  The TwistLock socket is flush in the centre of the back.
//
//  Frame: x = width, y = bottom (USB end) -> top (antenna end), z = back -> front.
//  z = 0 is the inner floor. Ghost components are at their real SparkFun sizes.
//
//  part = "assembly" | "exploded" | "cutaway" | "cart" | "strap" | "chk" | "chk_out" | "chk_cart"
// =====================================================================
include <lib/components.scad>
include <lib/shape.scad>
include <lib/mount.scad>

part = "assembly";
pose = true;
$fn = 40;

wall = 2.2;
rb = 6;   rf = 10;   crown = 0;    // a crowned face would not sit flat for the face-down lid print

// ---------- layout (inner coordinates) ----------
W_in = 75;  H_in = 76;
tp_x0 = 2 + tp_keepout;                  // TP not rotated: USB at the bottom, plug side faces the left wall
tp_y0 = 1.0 + tp_usb_overhang;           // USB-end board edge
gps_x0 = tp_x0 + tp_w + 1.5;
gps_y0 = H_in - 2.2 - gps_l;             // SMA edge 2.2 off the top wall (lets the top-right corner be round)
batt_x0 = W_in/2 - batt[0]/2;
batt_y0 = H_in/2 - batt[1]/2;

zb = -wall;
z_batt  = zb + qt_depth + qt_floor + 0.2;            // pouch rests on the socket boss / ribs
plate_t = 1.6;
z_plate = z_batt + batt[2] + batt_swell;             // plate bottom
z_board = z_plate + plate_t + tp_standoff;           // TP + GPS bottom
z_comp  = z_board + 1.6 + tp_parts_h;
z_oled  = z_comp + oled_rear + 0.4;                  // OLED PCB bottom
Z_in    = z_oled + 1.6 + oled_glass[2];              // lid inner (glass against it)
zf      = Z_in + wall;
z_split = zf - rf;
well_d  = 3.0;                                       // dial cup depth
z_well  = zf - well_d;                               // cup floor (top face)
z_tw    = z_well - 1.6 - 0.2 - twist_top;            // Twist PCB bottom: encoder just under the cup floor

tw_c   = [(tp_x0 + tp_w + W_in)/2, 4 + tw_h/2];
oled_c = [34, 53];
rst_p  = [tp_x0 + tp_rst[0], tp_y0 + tp_rst[1]];
usb_x  = tp_x0 + tp_usb_x;
sd_x   = tp_x0 + tp_sd_x;
sma_x  = gps_x0 + gps_sma_x;
sma_z  = z_board + gps_sma_z;
sw_y   = 50;  sw_z = z_board + 1.8;                  // right wall, beside the GPS
qt_c   = [W_in/2, H_in/2];

Rc = 11 + wall;
corners = [[11, 11, Rc], [W_in - 11, 11, Rc], [11, H_in - 11, Rc], [W_in - 11, H_in - 11, Rc]];

Wo = W_in + 2*wall; Ho = H_in + 2*wall; Do = zf + crown - zb;
echo(str("CONCEPT B STONE outer: ", Wo, " x ", Ho, " x ", Do, " mm"));
echo(str("z: batt ", z_batt, "  plate ", z_plate, "  boards ", z_board, "  twist ", z_tw, "  oled ", z_oled, "  lid ", Z_in));

module body(t) hull() {
    pebble(t, corners, zb, zf, rb, rf);
    if (crown > 0) translate([W_in/2, H_in/2 + 3, zf + crown - t - 0.01]) cylinder(r = 24, h = 0.01, $fn = 64);   // optional crowned face (needs supports face-down)
}

// ---------- shell ----------
module apertures() {
    translate([oled_c[0], oled_c[1], Z_in]) window_cut(oled_window, wall + crown + 0.5);
    // dial cup + encoder hole
    translate([tw_c[0], tw_c[1], z_well]) cylinder(d1 = 22, d2 = 22 + 2*(zf + 1 - z_well), h = zf + 1 - z_well, $fn = 64);   // 45-degree wall, prints face-down
    translate([tw_c[0], tw_c[1], z_well - 3]) cylinder(d = enc_hole_d, h = 10);
    translate([rst_p[0], rst_p[1], z_board + 4.2]) cylinder(d = 2.5, h = 30, $fn = 16);
    // bottom end: USB-C + microSD
    translate([usb_x, 1, z_board + 1.6 + 1.6]) rotate([90, 0, 0]) linear_extrude(wall + 6) rrect2(12.6, 7.0, 2.2);
    translate([sd_x, 1, z_board - 0.7]) rotate([90, 0, 0]) linear_extrude(wall + 6) rrect2(12.4, 2.6, 0.6);
    // top end: SMA
    translate([sma_x, H_in - 1, sma_z]) rotate([-90, 0, 0]) cylinder(d = 11, h = wall + 6);
    // right side: EN switch
    translate([W_in - 1, sw_y - sw_slot[0]/2, sw_z - sw_slot[1]/2]) cube([wall + 4, sw_slot[0], sw_slot[1]]);
    // back: TwistLock socket
    translate([qt_c[0], qt_c[1], zb]) qt_socket_cut();
    // left side: wrist-strap passage
    translate([-wall, 62, 4.5]) rotate([0, 0, -90]) lanyard_cut();
}
plate_pillars = [[4.5, 26], [4.5, 58], [70.5, 22], [70.5, 62]];
module inner_features() {
    translate([qt_c[0], qt_c[1], zb]) qt_socket_boss();
    translate([-1, 56, -1]) cube([9, 12, 10]);                                     // lanyard block
    for (p = plate_pillars) translate([p[0], p[1], -1]) cylinder(d = 5.4, h = z_plate + 1);
    for (sx = [0, 1], sy = [0, 1]) translate([batt_x0 - 1.2 + sx*(batt[0] + 1.4), batt_y0 - 1.2 + sy*(batt[1] + 1.4), -1]) cube([1.0, 1.0, z_batt + 4]);
    for (x = [batt_x0 + 8, batt_x0 + batt[0] - 8]) translate([x - 0.6, batt_y0 + 4, -1]) cube([1.2, batt[1] - 8, z_batt + 1]);   // pouch support ribs
}
module lid_features() {
    // dial cup wall
    translate([tw_c[0], tw_c[1], z_well - 1.6]) cylinder(d = 34, h = Z_in - z_well + 1.6 + 1, $fn = 64);
    for (sx = [-1, 1], sy = [-1, 1])
        translate([oled_c[0] + sx*oled_holes[0]/2, oled_c[1] + sy*oled_holes[1]/2, z_oled + 1.6]) cylinder(d = 4.8, h = oled_glass[2] + 1);
    translate([rst_p[0], rst_p[1], z_board + 1.6 + 2.5 + 2.6]) cylinder(d = rst_tube_od, h = 20, $fn = 20);
}
module half(front) intersection() { difference() { body(0); body(wall); } translate([-50, -50, front ? z_split : zb - 10]) cube([200, 200, front ? 50 : z_split - zb + 10]); }
module back_shell() difference() { union() { half(false); intersection() { body(0.01); inner_features(); } } apertures(); }
module lid_shell()  difference() { union() { half(true);  intersection() { body(0.01); lid_features(); } } apertures(); }
module shell_solid() { back_shell(); lid_shell(); }

// internal chassis plate (separate print), with the TP/GPS/Twist standoffs
module chassis() difference() {
    union() {
        intersection() { body(wall + 0.4); translate([-5, -5, z_plate]) cube([100, 100, plate_t]); }
        for (h = [[2.54, 2.54], [20.32, 2.54]]) translate([tp_x0 + h[0], tp_y0 + h[1], z_plate]) cylinder(d = 5, h = z_board - z_plate);
        translate([tp_x0 + tp_w/2 - 5, tp_y0 + tp_l - 4, z_plate]) cube([10, 3, z_board - z_plate]);
        for (h = gps_holes) translate([gps_x0 + h[0], gps_y0 + h[1], z_plate]) cylinder(d = 5, h = z_board - z_plate);
        for (sx = [-1, 1], sy = [-1, 1]) translate([tw_c[0] + sx*tw_holes[0]/2, tw_c[1] + sy*tw_holes[1]/2, z_plate]) cylinder(d = 5, h = z_tw - z_plate);
    }
    translate([-2, 55, z_plate - 1]) cube([11, 14, 5]);                                // lanyard block
    translate([-2, 32, z_plate - 1]) cube([6, 14, 5]);                                 // battery lead pass-through
    translate([W_in - 5, sw_y - 6, z_plate - 1]) cube([7, 12, 5]);                     // switch body
}

// ---------- components ----------
module place_tp()   translate([tp_x0, tp_y0, z_board]) children();
module place_gps()  translate([gps_x0, gps_y0, z_board]) children();
module place_oled() translate([oled_c[0], oled_c[1], z_oled]) children();
module place_tw()   translate([tw_c[0], tw_c[1], z_tw]) children();
module place_batt() translate([batt_x0, batt_y0, z_batt]) children();
module place_sw()   translate([W_in, sw_y, sw_z]) rotate([0, 0, 180]) children();

module comps_base() {
    place_tp() ghost_tp();
    place_gps() { ghost_gps(); ghost_sma_plug(); }
    place_batt() ghost_batt();
    place_sw() ghost_switch();
    place_tw() ghost_twist();
}
module comps_lid() {
    place_oled() ghost_oled();
    color("orange") translate([rst_p[0], rst_p[1], z_board + 1.6 + 2.5 + 0.1]) cylinder(d = rst_pin_d, h = zf + crown + 0.6 - (z_board + 4.2), $fn = 16);
}
module dial_knob() translate([tw_c[0], tw_c[1], z_well + 0.2]) ghost_knob();
module keep_all() {
    place_tp() keep_tp();
    place_gps() keep_gps();
    place_oled() keep_oled();
    place_tw() keep_twist();
    place_batt() keep_batt();
    place_sw() translate([0, -sw_body[1]/2, -sw_body[2]/2]) cube(sw_body);
}

// ---------- views ----------
c_back = "#3b4046"; c_front = "#dcd4c3"; c_panel = "#262a2e"; c_plate = "#c9b458";
module panel_prism() translate([oled_c[0], oled_c[1], zf - 0.6]) linear_extrude(5) rrect2(44, 32, 6);
module ring_prism() translate([tw_c[0], tw_c[1], zf - 0.6]) linear_extrude(5) difference() { circle(d = 34, $fn = 64); circle(d = 28.5, $fn = 64); }
module lid_two_tone() {
    color(c_front) difference() { lid_shell(); panel_prism(); ring_prism(); }
    color(c_panel) intersection() { lid_shell(); union() { panel_prism(); ring_prism(); } }
}
module two_tone() { color(c_back) back_shell(); lid_two_tone(); }
module device() { two_tone(); color(c_plate) chassis(); comps_base(); comps_lid(); dial_knob(); }

// for lineup.scad (use <>): the posed, closed device
module stone_posed() stand() device();

module stand() if (pose) rotate([90, 0, 0]) translate([-W_in/2, -Ho/2, 0]) children(); else children();

if (part == "assembly") stand() device();
else if (part == "exploded") stand() {
    color(c_back) back_shell();
    place_batt() ghost_batt();
    translate([0, 0, 22]) { color(c_plate) chassis(); place_tp() ghost_tp(); place_gps() { ghost_gps(); ghost_sma_plug(); } place_tw() ghost_twist(); place_sw() ghost_switch(); }
    translate([0, 0, 58]) { lid_two_tone(); comps_lid(); dial_knob(); }
}
else if (part == "cutaway") stand() {
    // section on the plane x = dial centre (cuts the Twist, GPS, plate and pouch); +x part removed
    x_cut = tw_c[0];
    intersection() {
        union() { two_tone(); color(c_plate) chassis(); comps_base(); comps_lid(); dial_knob(); }
        translate([x_cut - 300, -100, -50]) cube([300, 400, 200]);
    }
}
else if (part == "cart") cart_mount(tilt = 55, tube_d = 25.4) translate([-qt_c[0], -qt_c[1], -zb]) device();
else if (part == "strap") rotate([90, 0, 0]) {
    strap_clip(); strap_ghost(220);
    translate([0, clip_puck_y, puck_t]) translate([-qt_c[0], -qt_c[1], -zb]) device();
}
else if (part == "chk") intersection() { union() { shell_solid(); chassis(); } keep_all(); }
else if (part == "chk_plate") intersection() { chassis(); shell_solid(); }
else if (part == "chk_out") difference() { keep_all(); body(0); }
else if (part == "chk_cart") intersection() {
    translate([0, 0, knk_z]) rotate([55, 0, 0]) translate([0, 0, tilt_puck_z]) translate([-qt_c[0], -qt_c[1], -zb]) shell_solid();
    union() { rotate([0, 90, 0]) cylinder(d = 25.4, h = 120, center = true); clamp_half(true); clamp_half(false);
              translate([0, 0, knk_z]) rotate([55, 0, 0]) tilt_head_body(); }
}
