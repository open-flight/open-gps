// =====================================================================
//  Concept A - "GRIP"   (concept-level massing model, not print-ready)
//
//  A slim two-zone handheld, the size of a SkyCaddie-style golf GPS.
//    * Handle (bottom): the 2 Ah pouch lies flat; the Twist sits directly on top of it,
//      so the dial lands under the thumb of the holding hand, in a shallow thumb pocket.
//    * Head (top): Thing Plus and GPS side by side (not stacked) under the OLED.
//      USB-C, microSD and the SMA port all on the top end.
//  The back is flat and prints flat; a separate TPU palm pad fills the palm, and the
//  TwistLock socket sits flush in the back of the head.
//
//  Frame: x = width, y = bottom (handle) -> top (antenna end), z = back -> front.
//  z = 0 is the inner floor. Ghost components are at their real SparkFun sizes.
//
//  part = "assembly" | "exploded" | "cutaway" | "cart" | "strap" | "chk" | "outer"
// =====================================================================
include <lib/components.scad>
include <lib/shape.scad>
include <lib/mount.scad>

part = "assembly";
pose = true;          // stand the model up for product-style renders
$fn = 40;

wall = 2.2;
rb = 4;   // back edge radius (with 45-degree printable lead-in)
rf = 8;   // front edge radius

// ---------- layout (inner coordinates) ----------
gps_x0  = 6.0;                                     // GPS kept 6 mm off the left wall so the head corner can be round
W_in    = gps_x0 + gps_w + 1.5 + tp_w + tp_keepout;  // 74.16; TP is rotated, so its plug side faces the right wall
xc      = W_in/2;
batt_x0 = xc - batt[0]/2;
batt_y0 = 5.5;                                     // leaves room for the rounded bottom corners
gap_cable = 3.5;                                   // battery lead + Qwiic run between the zones
tp_y_far  = batt_y0 + batt[1] + gap_cable;         // Thing Plus is rotated 180: USB end at the top
tp_y_usb  = tp_y_far + tp_l;
H_in    = tp_y_usb + tp_usb_overhang + 1.0;
tp_x0   = gps_x0 + gps_w + 1.5;
gps_y0  = H_in - 0.6 - gps_l;                      // SMA edge 0.6 from the top wall (as v0.1)

z_board = 5.5;                                     // TP + GPS bottom face (on floor bosses)
z_tw    = batt[2] + batt_swell + tw_pins + 0.4;    // Twist PCB bottom, pins clear the pouch
Z_in    = z_tw + twist_top;                        // encoder body touches the lid (18.4)
z_oled  = Z_in - oled_glass[2] - 1.6;              // OLED PCB bottom (glass against the lid)
zb = -wall;  zf = Z_in + wall;
z_split = zf - rf;                                 // shell / lid parting line

tw_c   = [xc, batt_y0 + batt[1] - 1 - tw_h/2];
oled_c = [33.0, 104];                              // nudged left so the RESET plunger clears the OLED
rst_p  = [tp_x0 + tp_w - tp_rst[0], tp_y_usb - tp_rst[1]];
usb_x  = tp_x0 + tp_w - tp_usb_x;
sd_x   = tp_x0 + tp_w - tp_sd_x;
sma_x  = gps_x0 + gps_sma_x;
sma_z  = z_board + gps_sma_z;
sw_y   = 84;  sw_z = z_board + 3.5;                // left wall, below the GPS
qt_c   = [xc, 104];
dish_d = 32; dish_h = 1.0;                         // thumb pocket: flat floor (bridged), 45-degree rim

// plan corners [x, y, outer plan radius]
Rh = 9 + wall;  Rb = 8 + wall;
hx0 = xc - (batt[0]/2 + 1.6);
corners = [
    [9, H_in - 9, Rh], [W_in - 9, H_in - 9, Rh],          // head top
    [9, 76, Rh],       [W_in - 9, 76, Rh],                // head shoulders
    [hx0 + 8, 8, Rb],  [W_in - hx0 - 8, 8, Rb]            // handle bottom
];

Wo = W_in + 2*wall; Ho = H_in + 2*wall; Do = zf - zb;
echo(str("CONCEPT A GRIP outer: ", Wo, " x ", Ho, " x ", Do, " mm (head width; handle ",
         W_in - 2*hx0 + 2*wall, " wide at the bottom; palm pad +", 3.5, ")"));

module body(t) pebble(t, corners, zb, zf, rb, rf);

// ---------- shell (back + lid in one piece for massing; split shown by colour) ----------
module apertures() {
    translate([oled_c[0], oled_c[1], Z_in]) window_cut(oled_window, wall);
    translate([tw_c[0], tw_c[1], zf - dish_h]) cylinder(d1 = dish_d - 2*dish_h, d2 = dish_d + 0.02, h = dish_h + 0.01, $fn = 96);
    translate([tw_c[0], tw_c[1], Z_in - 1]) cylinder(d = enc_hole_d, h = 10);
    translate([rst_p[0], rst_p[1], z_board + 4.2]) cylinder(d = 2.5, h = 30, $fn = 16);
    translate([rst_p[0], rst_p[1], zf - 0.6]) cylinder(d1 = 2.5, d2 = 4, h = 0.61, $fn = 16);
    // top end: USB-C, microSD, SMA
    translate([usb_x, H_in - 1, z_board + 1.6 + 1.6]) rotate([-90, 0, 0]) linear_extrude(wall + 6) rrect2(12.6, 7.0, 2.2);
    translate([sd_x, H_in - 1, z_board - 0.7]) rotate([-90, 0, 0]) linear_extrude(wall + 6) rrect2(12.4, 2.6, 0.6);
    translate([sma_x, H_in - 1, sma_z]) rotate([-90, 0, 0]) cylinder(d = 11, h = wall + 6);
    // left side: EN slide switch
    translate([-wall - 3, sw_y - sw_slot[0]/2, sw_z - sw_slot[1]/2]) cube([wall + 4, sw_slot[0], sw_slot[1]]);
    // back: TwistLock socket
    translate([qt_c[0], qt_c[1], zb]) qt_socket_cut();
    // bottom end: wrist-strap passage
    translate([xc, -wall, 4]) lanyard_cut();
}
module inner_features() {
    // TwistLock socket boss, lanyard block
    translate([qt_c[0], qt_c[1], zb]) qt_socket_boss();
    translate([xc - 8, -1, 0]) cube([16, batt_y0 - 0.5 + 1, 8]);
    // TP standoffs (2 holes at the USB end) + far-end rest, GPS standoffs
    for (h = [[2.54, 2.54], [20.32, 2.54]]) translate([tp_x0 + tp_w - h[0], tp_y_usb - h[1], -1]) cylinder(d = 5, h = z_board + 1);
    translate([tp_x0 + tp_w/2 - 5, tp_y_far + 1, -1]) cube([10, 3, z_board + 1]);
    for (h = gps_holes) translate([gps_x0 + h[0], gps_y0 + h[1], -1]) cylinder(d = 5, h = z_board + 1);
    // battery corner ribs
    for (sx = [0, 1], sy = [0, 1]) translate([batt_x0 - 1.2 + sx*(batt[0] + 1.4), batt_y0 - 1.2 + sy*(batt[1] + 1.4), -1]) cube([1.0, 1.0, 4]);
}
module lid_features() {
    // Twist hangs from lid bosses; OLED ears on short bosses
    for (sx = [-1, 1], sy = [-1, 1]) {
        translate([tw_c[0] + sx*tw_holes[0]/2, tw_c[1] + sy*tw_holes[1]/2, z_tw + 1.6]) cylinder(d = 5, h = Z_in - z_tw - 1.6 + 1);
        translate([oled_c[0] + sx*oled_holes[0]/2, oled_c[1] + sy*oled_holes[1]/2, z_oled + 1.6]) cylinder(d = 4.8, h = oled_glass[2] + 1);
    }
    // RESET guide tube
    translate([rst_p[0], rst_p[1], z_board + 1.6 + 2.5 + 2.6]) cylinder(d = rst_tube_od, h = 20, $fn = 20);
}
// back shell (z < z_split) and lid (z >= z_split, plus the bosses that hang below it)
module half(front) intersection() { difference() { body(0); body(wall); } translate([-50, -50, front ? z_split : zb - 10]) cube([200, 300, front ? 50 : z_split - zb + 10]); }
module back_shell() difference() { union() { half(false); intersection() { body(0.01); inner_features(); } } apertures(); }
module lid_shell()  difference() { union() { half(true);  intersection() { body(0.01); lid_features(); } } apertures(); }
module shell_solid() { back_shell(); lid_shell(); }

// palm pad: separate TPU part on the back of the handle (prints flat side down)
module palm_pad() color("#4a4a4a") translate([xc, 34, zb + 0.01]) intersection() {
    scale([24, 28, 3.5]) sphere(r = 1, $fn = 64);
    translate([-40, -40, -10]) cube([80, 80, 10]);
}

// ---------- components ----------
module place_tp()   translate([tp_x0 + tp_w, tp_y_usb, z_board]) rotate([0, 0, 180]) children();
module place_gps()  translate([gps_x0, gps_y0, z_board]) children();
module place_oled() translate([oled_c[0], oled_c[1], z_oled]) children();
module place_tw()   translate([tw_c[0], tw_c[1], z_tw]) children();
module place_batt() translate([batt_x0, batt_y0, 0]) children();
module place_sw()   translate([0, sw_y, sw_z]) children();

module comps_base() {
    place_tp() ghost_tp();
    place_gps() { ghost_gps(); ghost_sma_plug(); }
    place_batt() ghost_batt();
    place_sw() ghost_switch();
}
module comps_lid() {
    place_oled() ghost_oled();
    place_tw() ghost_twist();
    color("orange") translate([rst_p[0], rst_p[1], z_board + 1.6 + 2.5 + 0.1]) cylinder(d = rst_pin_d, h = zf + 1 - (z_board + 4.2), $fn = 16);
}
module dial_knob() translate([tw_c[0], tw_c[1], zf - dish_h + 0.6]) ghost_knob();
module keep_all() {
    place_tp() keep_tp();
    place_gps() keep_gps();
    place_oled() keep_oled();
    place_tw() keep_twist();
    place_batt() keep_batt();
    place_sw() translate([0, -sw_body[1]/2, -sw_body[2]/2]) cube(sw_body);
}

// ---------- views ----------
c_back = "#3d5c4b"; c_front = "#ecebe6"; c_panel = "#23292e";
// face panel printed in the second colour (X2D dual nozzle): the top 0.6 mm of the lid
// around the screen and RESET, so the bezel reads as one dark "glass" area
panel_c = [oled_c[0] + 3.2, oled_c[1]];  panel_sz = [50, 34];
module panel_prism() translate([panel_c[0], panel_c[1], zf - 0.6]) linear_extrude(1) rrect2(panel_sz[0], panel_sz[1], 5);
module lid_two_tone() {
    color(c_front) difference() { lid_shell(); panel_prism(); }
    color(c_panel) intersection() { lid_shell(); panel_prism(); }
}
module two_tone() { color(c_back) back_shell(); lid_two_tone(); }
module device() { two_tone(); comps_base(); comps_lid(); dial_knob(); palm_pad(); }

// for lineup.scad (use <>): the posed, closed device
module grip_posed() stand() device();

module stand() if (pose) rotate([90, 0, 0]) translate([-xc, -Ho/2, 0]) children(); else children();

if (part == "assembly") stand() device();
else if (part == "outer") stand() { two_tone(); dial_knob(); palm_pad(); }
else if (part == "exploded") stand() {
    color(c_back) back_shell();
    comps_base(); palm_pad();
    translate([0, 0, 60]) {
        lid_two_tone();
        comps_lid(); dial_knob();
    }
}
else if (part == "cutaway") stand() {
    // shell sectioned on the plane x = x_cut (the +x part removed); components left whole
    x_cut = tw_c[0] + 3;
    color(c_back) intersection() { back_shell(); translate([x_cut - 300, -50, -50]) cube([300, 300, 200]); }
    color(c_front) intersection() { lid_shell(); translate([x_cut - 300, -50, -50]) cube([300, 300, 200]); }
    intersection() { union() { comps_base(); comps_lid(); dial_knob(); palm_pad(); } translate([x_cut - 300, -100, -50]) cube([300, 400, 200]); }
}
else if (part == "cart") {
    // push-cart handle (25.4 mm tube along x), screen tipped 55 degrees toward the golfer
    cart_mount(tilt = 55, tube_d = 25.4) rotate([0, 0, 0]) translate([-qt_c[0], -qt_c[1], -zb]) device();
}
else if (part == "strap") {
    rotate([90, 0, 0]) {
        strap_clip(); strap_ghost(260);
        translate([0, clip_puck_y, puck_t]) translate([-qt_c[0], -qt_c[1], -zb]) device();
    }
}
else if (part == "chk") intersection() { shell_solid(); keep_all(); }
else if (part == "chk_pad") intersection() { palm_pad(); union() { shell_solid(); keep_all(); } }
else if (part == "chk_out") difference() { keep_all(); body(0); }
// device vs. cart clamp/bar (the puck itself is meant to sit in the socket, so it's excluded)
else if (part == "chk_cart") intersection() {
    translate([0, 0, knk_z]) rotate([55, 0, 0]) translate([0, 0, tilt_puck_z]) translate([-qt_c[0], -qt_c[1], -zb]) { shell_solid(); palm_pad(); }
    union() { color("#9aa3ab") rotate([0, 90, 0]) cylinder(d = 25.4, h = 120, center = true); clamp_half(true); clamp_half(false);
              translate([0, 0, knk_z]) rotate([55, 0, 0]) tilt_head_body(); }
}
