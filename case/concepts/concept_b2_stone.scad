// =====================================================================
//  Concept B2 - "STONE, LAYERED"   (print-ready: back shell, lid, plate, knob, plunger)
//
//  B's palm stone with a smaller footprint, bought with depth. Four layers, back -> front:
//    1. the 2 Ah pouch (on the floor, or on the TwistLock socket boss if mount_socket)
//    2. chassis plate + Thing Plus on the left (USB-C at the bottom end, plug keep-out
//       against the left wall)
//    3. split by zone, sharing the same depth instead of stacking:
//         top    : GPS (SMA edge 0.6 mm off the top wall) on three plate posts, OLED in front
//         bottom : the Twist on its own, dial lower right, hung from lid bosses (as v0.1)
//    4. lid
//  The Thing Plus RESET (28.2 mm from the USB end) gets a straight plunger path between
//  the Twist (to its right) and the GPS (above it).
//
//  Lens section: straight sides from the back up to a shoulder just above the boards, then
//  the sides lean 6 mm inward (40.6 deg) to a smaller face (left, right, bottom; not the top,
//  where the SMA sits). Plan corners limited by the pouch corners (8.5 mm inside radius).
//
//  Retention (differs from v0.1, see README "Printing B2"): the pouch fills the floor to
//  within 1.8 mm of the side walls, so v0.1's back-to-lid screw posts have nowhere to stand
//  and top tongues would hit the GPS. Instead four lid tabs drop inside the back shell; three
//  M2 x 8 countersunk screws go through the side walls into M2 pilots in the tabs (no inserts).
//  The same tabs clamp the plate down onto ledges; two M2 pan screws locate the plate.
//
//  Frame: x = width, y = bottom (USB end) -> top (antenna end), z = back -> front.
//  z = 0 is the inner floor. Ghost components are at their real SparkFun sizes.
//
//  part = views : "assembly" | "exploded" | "cutaway" | "side" | "cart" | "strap"
//         print : "back_shell" | "lid" | "plate" | "knob" | "plunger"   (print orientation)
//         checks: "chk" | "chk_out" | "chk_comp" | "chk_plate" | "chk_pilot" | "chk_cart" | "chk_batt" | "chk_batt_old" (should be non-empty)
// =====================================================================
include <lib/components.scad>
include <lib/shape.scad>
include <lib/mount.scad>
use <../cad/shot_tracker_case.scad>      // v0.1's knob() for the printed knob

// ---------- B2-only overrides of lib/components.scad (A and B keep the library values) ----------
batt        = [51, 71.5, 6.4]; // pouch pocket. The user's cell measures 49.2 x 68.8 mm plus a ~1.5 mm seal flap at the
                              // top end (the reseller size in the v0.1 README): 49.2 x 70.3 + 0.6 mm all round, rounded up.
                              // Long side vertical, leads at the BOTTOM (USB) end. Thickness unmeasured: 6.4 nominal.
real_pouch  = [49.2, 70.3, 6.4];   // measured body + flap, for chk_batt / chk_batt_old
batt_lead   = 4.0;            // free space below the pocket for the leads to bend (leads exit the bottom short edge)
batt_top    = 2.4;            // pocket to top wall: what the 8.5 mm plan corners need with 3.5 mm side margins
W_front     = 58.0;           // narrowest inside width the front stack allows (RESET + Twist row, Twist in the corner)
batt_swell  = 1.0;            // +0.4 over the library value: cells swell
tp_standoff = 3.2;            // +0.8 so the Thing Plus M2 screws get >= 4 mm of thread in standoff + plate

part = "assembly";
pose = true;
mount_socket = false;   // TwistLock socket in the back. Off for the first print: thinner case.
batt_lift = 0.4;        // pouch height above the inner floor when there's no socket boss (clears the back edge radius)
show_hw = true;         // draw screws in the views
$fn = 40;

wall = 2.2;
rb   = mount_socket ? 6 : 3;  // back edge radius; tighter without the socket so the low pouch's corners clear it
Rc_in  = 8.5;                 // plan corner radius (inside), limited by the pouch corners

// ---------- print / fit tolerances and hardware (v0.1 values) ----------
lip_clr  = 0.2;  lip_t = 1.2;  lip_h = 3.0;
// All screws are M2 self-tapping into PETG (no heat-set inserts).
m2_pilot = 1.6;  m2_clear = 2.4;                      // pilot / clearance holes
m2_pan   = [3.8, 1.6];                                // pan head (dk, k)
m2_csk_d = 4.4;                                       // 90-degree countersink for an M2 flat head (dk 3.8)
skin_min = 0.6;                                       // pilot holes stop this far from any outer face

// ---------- z stack (inner floor = 0) ----------
zb      = -wall;
z_batt  = mount_socket ? zb + qt_depth + qt_floor + 0.2 : batt_lift;   // layer 1: pouch on the socket boss, or the floor
plate_t = 1.6;
z_plate = z_batt + batt[2] + batt_swell;            // layer 2: plate
z_ptop  = z_plate + plate_t;
z_board = z_ptop + tp_standoff;                     //          Thing Plus bottom
z_comp  = z_board + 1.6 + tp_parts_h;               //          Thing Plus tallest part
z_gps   = z_comp + 0.6;                             // layer 3 top: GPS bottom
z_gps_top = z_gps + 1.6 + 3.0;                      //          (J4 is the tallest part)
z_oled  = z_gps_top + oled_rear + 0.4;              //          OLED PCB bottom
Z_in    = z_oled + 1.6 + oled_glass[2];             // lid inner
zf      = Z_in + wall;
z_tw    = Z_in - twist_top;                         // layer 3 bottom: encoder body touches the lid (as v0.1)
btn_top = z_board + 1.6 + 2.5;                      // RESET tact switch top

// ---------- plan layout ----------
W_in    = max(batt[0] + 2*1.8, W_front);            // pouch + corner margin, or the front stack (it is the front stack now)
tp_x0   = 1.5 + tp_keepout;                         // plug keep-out against the left wall
tp_y0   = 1.0 + tp_usb_overhang;
rst_p   = [tp_x0 + tp_rst[0], tp_y0 + tp_rst[1]];
tw_c    = [rst_p[0] + 2.4 + tw_w/2, 2.0 + tw_h/2];  // Twist just right of the plunger, lid bosses clear of its tube
gps_y0_min = rst_p[1] + rst_pin_d/2 + 0.6;          // GPS can't start lower than just above the plunger
H_in    = max(gps_y0_min + gps_l + 0.6, batt_lead + batt[1] + batt_top);   // RESET + GPS column, or lead zone + pouch
gps_y0  = H_in - 0.6 - gps_l;                       // SMA edge 0.6 off the top wall (v0.1 value)
gps_x0  = W_in/2 - gps_w/2;
oled_c  = [W_in/2, gps_y0 + gps_l/2 + 0.3];
batt_x0 = W_in/2 - batt[0]/2;
batt_y0 = batt_lead;                                // pocket starts above the lead-bend zone
usb_x   = tp_x0 + tp_usb_x;
sd_x    = tp_x0 + tp_sd_x;
usb_z   = z_board + 1.6 + 1.6;
sma_x   = gps_x0 + gps_sma_x;
sma_z   = z_gps + gps_sma_z;
sw_y    = 45;  sw_z = z_board + 1.8;                // right wall, layer 2
qt_c    = [W_in/2, H_in/2];
z_tube  = z_gps_top + 0.4;                          // RESET guide tube starts above the GPS parts

// Lens section: full plan from the back up to a shoulder just above the layer-3 boards,
// then the sides lean in toward a smaller face (<= 45 deg, so the face-down lid prints
// without supports). No lean at the top: the SMA, J4 and the OLED's top ears sit there.
Rp     = Rc_in + wall;
z_sh   = z_comp + 3.0;      // shoulder (ring equator)
r_sh   = 4;                 // = rf, so the lean is one straight flank
rf     = 4;                 // face edge radius
lean   = [4.9, 4.9, 4.9, 0]; // face inset per side: left, right, bottom, top. 4.9 over a 7 mm rise = 35 deg on the sides
                            // and 44.7 deg on the diagonal at the bottom corners (6 would be 50.5 there: unprintable face-down)
// [x, y, plan radius, face-centre shift x, y]
corners = [[Rc_in, Rc_in, Rp,  lean[0],  lean[2]], [W_in - Rc_in, Rc_in, Rp, -lean[1],  lean[2]],
           [Rc_in, H_in - Rc_in, Rp, lean[0], -lean[3]], [W_in - Rc_in, H_in - Rc_in, Rp, -lean[1], -lean[3]]];
zs = z_sh;                  // shell / lid parting plane (the widest section)

// ---------- fastener positions ----------
// lid tabs: [x side (0 = left, 1 = right), y centre, y half-length, screwed]; M2 pilots horizontal along x.
// The lower-left tab has no screw: a head there would sit on the bottom-left corner curve
// (up to 1 mm proud), and the Thing Plus plug keep-out blocks the straight wall above it.
// It still clamps the plate and locates the lid.
tab_z0   = z_ptop;                                  // tabs bear on the plate (clamp it to the ledges)
ins_z    = z_board + 1.6;                           // side-screw axis height
tab_w    = 6.8;                                     // tab depth from the wall
tabs     = [[0, 6, 4, false], [1, 12, 3.5, true], [0, 58, 4, true], [1, 58, 4, true]];   // screw heads on the straight part of the walls
screwed  = [for (t = tabs) if (t[3]) t];
tp_holes_w   = [for (h = [[2.54, 2.54], [20.32, 2.54]]) [tp_x0 + h[0], tp_y0 + h[1]]];
gps_holes_w  = [for (h = gps_holes) let (p = [gps_x0 + h[0], gps_y0 + h[1]])
                if (!(p[0] < tp_x0 + tp_w + 3 && p[1] < tp_y0 + tp_l + 3)) p];   // 3 posts; the 4th hole sits over the TP
tw_holes_w   = [for (sx = [-1, 1], sy = [-1, 1]) [tw_c[0] + sx*tw_holes[0]/2, tw_c[1] + sy*tw_holes[1]/2]];
oled_holes_w = [for (sx = [-1, 1], sy = [-1, 1]) [oled_c[0] + sx*oled_holes[0]/2, oled_c[1] + sy*oled_holes[1]/2]];
plate_scr    = [[1.9, 40], [W_in - 1.9, 30]];        // plate -> left / right side ledges (the pouch leaves 3.5 mm margins)
lan_x        = 45;                                   // wrist-strap passage, bottom end
ledge_d      = batt_top - 0.35;                       // top ledge depth (no bottom ledge: the lead-bend zone is there)
lead_x       = [8.5, 38];                            // lead-bend zone along the bottom end (left of the wrist-strap block)

// screw lengths (mm, under-head)
L_tp = 6; L_gps = 6; L_tw = 6; L_oled = 4; L_plate = 6; L_side = 8;   // L_oled: only glass + skin above the ears (2.4 mm of thread)

Wo = W_in + 2*wall; Ho = H_in + 2*wall; Do = zf - zb;
echo(str("CONCEPT B2 outer: ", Wo, " x ", Ho, " x ", Do, " mm (mount_socket = ", mount_socket, ")"));
echo(str("z: batt ", z_batt, "  plate ", z_plate, "  TP ", z_board, "  GPS ", z_gps, "  Twist ", z_tw,
         "  OLED ", z_oled, "  lid ", Z_in, "  face ", zf, "  split ", zs));

module body(t) hull() for (p = corners) translate([p[0], p[1], 0]) {
    translate([0, 0, zb + rb]) corner_ring(p[2], rb, t);
    translate([0, 0, zb + t]) cylinder(r = p[2] - rb + 0.414*(rb - t), h = 0.01, $fn = 48);   // 45-degree back lead-in
    translate([0, 0, z_sh]) corner_ring(p[2], r_sh, t);
    translate([p[3], p[4], 0]) {
        translate([0, 0, zf - rf]) corner_ring(p[2], rf, t);
        translate([0, 0, zf - t - 0.01]) cylinder(r = p[2] - rf + 0.414*(rf - t), h = 0.01, $fn = 48);
    }
}
module below(z) translate([-50, -50, -50]) cube([200, 200, z + 50]);
module above(z) translate([-50, -50, z]) cube([200, 200, 100]);

// =====================================================================
// cuts
// =====================================================================
// openings shared by shell and lid
module apertures() {
    translate([oled_c[0], oled_c[1], Z_in]) window_cut(oled_window, wall + 0.5);
    translate([tw_c[0], tw_c[1], Z_in - 1]) cylinder(d = enc_hole_d, h = 10);
    translate([rst_p[0], rst_p[1], btn_top + 0.5]) cylinder(d = 2.5, h = 40, $fn = 16);
    translate([rst_p[0], rst_p[1], zf - 0.6]) cylinder(d1 = 2.5, d2 = 3.9, h = 0.61, $fn = 16);
    // bottom end: USB-C + microSD "port bay": opened up through the rim so the back shell has no
    // 12.6 mm bridge over it; a tooth on the lid fills the top of the slot
    hull() {
        translate([usb_x, 1.5, usb_z]) rotate([90, 0, 0]) linear_extrude(wall + 6) rrect2(12.6, 7.0, 2.2);
        translate([sd_x, 1.5, z_board - 0.7]) rotate([90, 0, 0]) linear_extrude(wall + 6) rrect2(12.4, 2.6, 0.6);
        translate([usb_x - 6.3, -wall - 4.5, zs - 0.01]) cube([12.6, wall + 6, 0.02]);
    }
    // top end: SMA (straddles the parting plane: a half-round notch in each part, no bridge)
    translate([sma_x, H_in - 1, sma_z]) rotate([-90, 0, 0]) cylinder(d = 11, h = wall + 6);
    // right side: EN switch (4.8 mm bridge)
    translate([W_in - 1, sw_y - sw_slot[0]/2, sw_z - sw_slot[1]/2]) cube([wall + 4, sw_slot[0], sw_slot[1]]);
    if (mount_socket) translate([qt_c[0], qt_c[1], zb]) qt_socket_cut();
    // bottom end: wrist-strap passage
    translate([lan_x, -wall, ins_z]) lanyard_td();
    // side screws: clearance + countersink in the shell wall, M2 pilot in the lid tab
    for (t = screwed) side_frame(t) {
        translate([0, 0, -wall - 1]) cylinder(d = m2_clear, h = wall + 1.2, $fn = 20);
        translate([0, 0, -wall - 0.01]) cylinder(d1 = m2_csk_d, d2 = 0, h = m2_csk_d/2, $fn = 32);
        translate([0, 0, lip_clr - 0.01]) cylinder(d = m2_pilot, h = L_side - wall - lip_clr + 0.6, $fn = 16);
    }
}
// wrist-strap passage with teardrop (45-degree pointed) tops, so it prints without support
module td(d, h) linear_extrude(h) hull() { circle(d = d, $fn = 20); translate([0, d/2*sqrt(2)]) circle(d = 0.01); }
module lanyard_td(spacing = 7, d = 3.2, depth = 5) {
    for (s = [-1, 1]) translate([s*spacing/2, -2, 0]) rotate([-90, 0, 0]) rotate([0, 0, 180]) td(d, depth + 2);
    translate([-spacing/2, depth, 0]) rotate([90, 0, 90]) td(d, spacing);
    for (s = [-1, 1]) translate([s*spacing/2, depth, 0]) sphere(d = d, $fn = 16);
}
// local frame for a side screw: origin on the inner wall at the screw axis, +z pointing into the case
module side_frame(t) translate([t[0] == 0 ? 0 : W_in, t[1], ins_z]) rotate([0, t[0] == 0 ? 90 : -90, 0]) children();

// pilot holes (all blind; depths chosen so the listed screw can't reach a skin)
module pilots() {
    for (p = tp_holes_w)   translate([p[0], p[1], z_board - (L_tp - 1.6) - 0.2]) cylinder(d = m2_pilot, h = (L_tp - 1.6) + 0.2 + 0.01, $fn = 16);
    for (p = gps_holes_w)  translate([p[0], p[1], z_gps - (L_gps - 1.6) - 0.6]) cylinder(d = m2_pilot, h = (L_gps - 1.6) + 0.6 + 0.01, $fn = 16);
    for (p = tw_holes_w)   translate([p[0], p[1], z_tw + 1.6 - 0.01]) cylinder(d = m2_pilot, h = (L_tw - 1.6) + skin_min + 0.01, $fn = 16);
    for (p = oled_holes_w) translate([p[0], p[1], z_oled + 1.6 - 0.01]) cylinder(d = m2_pilot, h = zf - skin_min - (z_oled + 1.6), $fn = 16);
    for (p = plate_scr)    translate([p[0], p[1], z_plate - (L_plate - plate_t) - 0.6]) cylinder(d = m2_pilot, h = L_plate - plate_t + 0.6 + 0.01, $fn = 16);
}

// =====================================================================
// back shell
// =====================================================================
module inner_features() {
    if (mount_socket) translate([qt_c[0], qt_c[1], zb]) qt_socket_boss();
    // pouch corner ribs + floor ribs
    for (sx = [0, 1], sy = [0, 1]) translate([batt_x0 - 1.2 + sx*(batt[0] + 1.4), batt_y0 - 1.2 + sy*(batt[1] + 1.4), -1]) cube([1.0, 1.0, z_batt + 4]);
    if (mount_socket) for (x = [batt_x0 + 8, batt_x0 + batt[0] - 8]) translate([x - 0.6, batt_y0 + 4, -1]) cube([1.2, batt[1] - 8, z_batt + 1]);
    // plate ledges, up to the plate: right side, left side above the lead channel, top end.
    // No bottom ledge (lead-bend zone) and no left ledge below y 28 (the leads run up there to the notch).
    m = batt_x0 - 0.4;                                    // side ledge depth: 0.4 short of the pocket
    translate([W_in - m, 10, -1]) cube([m + 1, H_in - 20, z_plate + 1]);
    translate([-1, 28, -1]) cube([m + 1, H_in - 38, z_plate + 1]);
    translate([10, H_in - ledge_d, -1]) cube([W_in - 20, ledge_d + 1, z_plate + 1]);
    // wrist-strap block: hangs off the bottom wall, 45-degree underside for the back-down print
    translate([lan_x - 6, 0, 0]) hull() {
        translate([0, -1, ins_z - 4.0]) cube([12, 6, 0.01]);
        translate([0, -1, zs - lip_h - 0.25]) cube([12, 6, 0.01]);
        translate([0, -1, ins_z - 4.0 - 6]) cube([12, 0.01, 0.01]);
    }
}
module back_shell() difference() {
    union() {
        intersection() { difference() { body(0); body(wall); } below(zs); }
        intersection() { body(0.01); below(zs); inner_features(); }
    }
    apertures();
    pilots();
}

// =====================================================================
// lid
// =====================================================================
// lip + tabs live inside the back shell (below zs): keep them clear of its wall by lip_clr
module in_lid()   intersection() { body(0.01); above(zs); }
// Lid built by subtraction with one cavity cutter. Inside the lip the cavity is the lip's inner
// outline (body offset wall + lip_clr + lip_t, vertical below zs). Above the rim it is a convex
// hull from that outline at zs up to the lid's own inner wall lip_band higher, so the lid wall is
// thickened just above the rim and the lip and tabs fuse into it (the wall leans inward above zs,
// so a plain lip would hang on a knife edge). The hull face is ~7 deg off vertical on the leaning
// sides and 30 deg on the top side: nothing faces down beyond 45 deg in the face-down print.
lip_ov   = 0.3;   // lip, tabs and tooth overlap into the lid by this much (no edge-to-edge contacts)
lip_band = 2.4;
module lid_cavity() {
    li = wall + lip_clr + lip_t;
    intersection() { body(li); below(zs + lip_ov); }
    hull() {
        intersection() { body(li); translate([-50, -50, zs]) cube([200, 200, 0.01]); }
        intersection() { body(wall); above(zs + lip_band); }
    }
    // lip/band notches (only inside the wall line, never through the lid wall)
    intersection() {
        union() { body(wall); below(zs); }
        union() {
            translate([gps_x0 - 1.5, H_in - 6, zs - lip_h - 1]) cube([gps_w + 3, 10, lip_h + lip_band + 3]);   // GPS edge, J4, SMA
            translate([tw_c[0] - tw_w/2 - 0.5, tw_c[1] - tw_h/2 - 0.5, z_tw - 0.5]) cube([tw_w + 1, tw_h + 1, 10]);   // Twist corner
        }
    }
}
module tab(t) {
    x0 = t[0] == 0 ? lip_clr : W_in - tab_w;
    x1 = t[0] == 0 ? tab_w : W_in - lip_clr;
    y0 = t[1] - t[2]; y1 = t[1] + t[2];
    // right-lower tab sits under the Twist corner: keep x < tw_r below z_tw - 0.4, 45-degree top
    tw_r = tw_c[0] + tw_w/2 + 0.3;
    low = (t[0] == 1 && t[1] < 30);
    // above the rim the tab reaches into the lid wall so it fuses with it
    xo0 = t[0] == 0 ? -wall - 1 : (low ? tw_r : x0);  xo1 = t[0] == 0 ? x1 : W_in + wall + 1;
    intersection() { in_lid(); translate([xo0, y0, zs - 0.01]) cube([xo1 - xo0, y1 - y0, Z_in - zs + 1]); }
    intersection() {
        intersection() { body(wall + lip_clr); below(zs + lip_ov); }   // overlaps the lid by lip_ov
        if (!low) translate([x0, y0, tab_z0]) cube([x1 - x0, y1 - y0, Z_in - tab_z0 + 1]);
        else union() {
            translate([tw_r, y0, tab_z0]) cube([x1 - tw_r, y1 - y0, Z_in - tab_z0 + 1]);
            hull() {
                translate([x0, y0, tab_z0]) cube([tw_r - x0 + 0.01, y1 - y0, (z_tw - 0.4 - (tw_r - x0)) - tab_z0]);
                translate([tw_r - 0.01, y0, tab_z0]) cube([0.01, y1 - y0, z_tw - 0.4 - tab_z0]);
            }
        }
    }
}
// tooth that fills the top of the port-bay slot (stands up off the rim in the face-down print)
module tooth() translate([usb_x - 6.1, -wall + 0.25, usb_z + 3.5 + 0.2]) cube([12.2, wall - 0.25 + lip_clr + 0.6, zs - (usb_z + 3.5 + 0.2) + lip_ov]);   // ends 0.6 short of the lip face
module lid_features() {
    for (p = tw_holes_w)   translate([p[0], p[1], z_tw + 1.6]) cylinder(d = 5, h = Z_in - z_tw - 1.6 + 1);
    for (p = oled_holes_w) translate([p[0], p[1], z_oled + 1.6]) cylinder(d = 4.8, h = oled_glass[2] + 1);
    translate([rst_p[0], rst_p[1], z_tube]) cylinder(d = rst_tube_od, h = Z_in - z_tube + 1, $fn = 20);
}
module lid_shell() union() {
    difference() {
        union() {
            difference() {
                union() {
                    intersection() { body(0); above(zs); }
                    intersection() { body(wall + lip_clr); translate([-50, -50, zs - lip_h]) cube([200, 200, lip_h + lip_ov]); }
                }
                lid_cavity();
            }
            intersection() { body(0.01); lid_features(); }
            for (t = tabs) tab(t);
        }
        apertures();
        pilots();
    }
    intersection() { body(0); tooth(); }
}
module shell_solid() { back_shell(); lid_shell(); }

// =====================================================================
// plate (internal chassis, prints flat)
// =====================================================================
module chassis() difference() {
    union() {
        intersection() { body(wall + 0.4); translate([-5, -5, z_plate]) cube([100, 100, plate_t]); }
        for (p = tp_holes_w) translate([p[0], p[1], z_plate]) cylinder(d = 5, h = z_board - z_plate);
        translate([tp_x0 + tp_w/2 - 5, tp_y0 + tp_l - 4, z_plate]) cube([10, 3, z_board - z_plate]);   // far-end rest (no hole on the TP)
        for (p = gps_holes_w) translate([p[0], p[1], z_plate]) cylinder(d = 5.4, h = z_gps - z_plate);
        translate([W_in - 0.4 - sw_body[0] - 0.6, sw_y - 6, z_plate]) cube([sw_body[0] + 0.6, 12, sw_z - sw_body[2]/2 - z_plate]);   // switch shelf (glue)
    }
    translate([-2, 12, z_plate - 1]) cube([batt_x0 + 2 - 0.1, 14, 5]);                // battery lead pass-through, up to the TP JST
    translate([lan_x - 6.4, -2, z_plate - 1]) cube([12.8, 7.6, 5]);                     // wrist-strap block
    for (p = plate_scr) translate([p[0], p[1], z_plate - 1]) cylinder(d = m2_clear, h = 5, $fn = 16);
    pilots();
}

// =====================================================================
// RESET plunger (v0.1 style: cone tip, retaining collar under the guide tube, 1 mm proud)
// =====================================================================
col_top = z_tube - 0.4;  col_h = 0.6;  col_ch = (3.4 - rst_pin_d)/2;
module plunger() translate([rst_p[0], rst_p[1], 0]) {
    translate([0, 0, btn_top + 0.1]) cylinder(d1 = 1.2, d2 = rst_pin_d, h = (rst_pin_d - 1.2)/2 + 0.01, $fn = 16);   // 45-degree tip
    translate([0, 0, btn_top + 0.1 + (rst_pin_d - 1.2)/2]) cylinder(d = rst_pin_d, h = zf + 1.0 - (btn_top + 0.1 + (rst_pin_d - 1.2)/2), $fn = 16);
    translate([0, 0, col_top - col_h - col_ch]) cylinder(d1 = rst_pin_d, d2 = 3.4, h = col_ch + 0.01, $fn = 20);   // 45-degree underside
    translate([0, 0, col_top - col_h]) cylinder(d = 3.4, h = col_h, $fn = 20);
}

// =====================================================================
// hardware (drawn, and used as keep-out solids in the checks)
// =====================================================================
module pan(L, up = true) {                      // head on z = 0; shank to -L (up = head above)
    mirror([0, 0, up ? 0 : 1]) {
        cylinder(d = m2_pan[0], h = m2_pan[1], $fn = 20);
        translate([0, 0, -L]) cylinder(d = 2.0, h = L, $fn = 12);
    }
}
module hw_group(g) {
    if (g == 0) for (p = tp_holes_w)   translate([p[0], p[1], z_board + 1.6]) pan(L_tp);
    if (g == 1) for (p = gps_holes_w)  translate([p[0], p[1], z_gps + 1.6]) pan(L_gps);
    if (g == 2) for (p = tw_holes_w)   translate([p[0], p[1], z_tw]) pan(L_tw, false);
    if (g == 3) for (p = oled_holes_w) translate([p[0], p[1], z_oled]) pan(L_oled, false);
    if (g == 4) for (p = plate_scr)    translate([p[0], p[1], z_ptop]) pan(L_plate);
    if (g == 5) for (t = screwed) side_frame(t) {
        translate([0, 0, -wall]) cylinder(d1 = 3.8, d2 = 0, h = 1.9, $fn = 24);               // M2 flat head (cone)
        translate([0, 0, -wall]) cylinder(d = 2, h = L_side, $fn = 12);
    }
}
module hw_all() for (g = [0 : 5]) hw_group(g);
module hw_ghost() color("#9a9a9a") for (g = [0 : 5]) hw_group(g);

// =====================================================================
// components
// =====================================================================
module place_tp()   translate([tp_x0, tp_y0, z_board]) children();
module place_gps()  translate([gps_x0, gps_y0, z_gps]) children();
module place_oled() translate([oled_c[0], oled_c[1], z_oled]) children();
module place_tw()   translate([tw_c[0], tw_c[1], z_tw]) children();
module place_batt() translate([batt_x0, batt_y0, z_batt]) children();
module place_sw()   translate([W_in, sw_y, sw_z]) rotate([0, 0, 180]) children();

module comps_base() {
    place_tp() ghost_tp();
    place_batt() ghost_batt();
    place_sw() ghost_switch();
}
module comps_mid() { place_gps() { ghost_gps(); ghost_sma_plug(); } }
module comps_lid() {
    place_oled() ghost_oled();
    place_tw() ghost_twist();
    color("orange") plunger();
}
knob_z = zf + 2;                                    // knob clears the face by 2 mm (as v0.1)
module dial_knob() translate([tw_c[0], tw_c[1], knob_z]) color("#f4f4f4") knob();
module keep_plunger() intersection() { plunger(); below(zf); }
// pouch leads: bend zone below the pocket, then up the left margin to the plate notch
module keep_leads() {
    translate([lead_x[0], 0.4, z_batt]) cube([lead_x[1] - lead_x[0], batt_lead - 0.4, batt[2] + batt_swell]);
    translate([0.4, 8.5, z_batt]) cube([batt_x0 - 0.8, 26 - 8.5, batt[2] + batt_swell]);
}
module real_pouch_at(grow = 0) translate([W_in/2 - real_pouch[0]/2 - grow, batt_y0 + (batt[1] - real_pouch[1])/2 - grow, z_batt - (grow > 0 ? 0 : 0)])
    cube([real_pouch[0] + 2*grow, real_pouch[1] + 2*grow, real_pouch[2] + batt_swell]);
module keep_all() {
    place_tp() keep_tp();
    place_gps() keep_gps();
    place_oled() keep_oled();
    place_tw() keep_twist();
    place_batt() keep_batt();
    keep_leads();
    place_sw() translate([0, -sw_body[1]/2, -sw_body[2]/2]) cube(sw_body);
    keep_plunger();
}

// each kept volume on its own, for the pairwise check
module keep_i(i) {
    if (i == 0) place_tp() keep_tp();
    if (i == 1) place_gps() keep_gps();
    if (i == 2) place_oled() keep_oled();
    if (i == 3) place_tw() keep_twist();
    if (i == 4) { place_batt() keep_batt(); keep_leads(); }
    if (i == 5) place_sw() translate([0, -sw_body[1]/2, -sw_body[2]/2]) cube(sw_body);
    if (i == 6) keep_plunger();
    if (i == 7) chassis();
    if (i == 8) lid_shell();
    if (i == 9) intersection() { body(0.01); below(zs); inner_features(); }
    if (i >= 10 && i <= 15) hw_group(i - 10);
}
n_keep = 16;
// intended contacts / engagements (screw in its pilot, plunger in its tube, ...)
exempt = [[0, 6],                        // plunger tip on the RESET button (inside the TP part-height block)
          [6, 8],                        // plunger in its guide tube
          [0, 10], [7, 10],              // TP screws: through the TP, into the plate standoffs
          [1, 11], [7, 11],              // GPS screws: through the GPS, into the posts
          [3, 12], [8, 12],              // Twist screws: through the Twist, into the lid bosses
          [2, 13], [8, 13],              // OLED screws: through the OLED ears, into the lid bosses
          [7, 14], [9, 14],              // plate screws: through the plate, into the ledges
          [8, 15]];                      // side screws into the lid tabs
function is_exempt(i, j) = len([for (e = exempt) if (e[0] == i && e[1] == j) 1]) > 0;

// =====================================================================
// views
// =====================================================================
c_back = "#3b4046"; c_front = "#dcd4c3"; c_panel = "#262a2e"; c_plate = "#c9b458";
module panel_prism() translate([oled_c[0], oled_c[1], zf - 0.6]) linear_extrude(5) rrect2(44, 31, 6);
module ring_prism() translate([tw_c[0], tw_c[1], zf - 0.6]) linear_extrude(5) difference() { circle(d = 27, $fn = 64); circle(d = 21.5, $fn = 64); }
module lid_two_tone() {
    color(c_front) difference() { lid_shell(); panel_prism(); ring_prism(); }
    color(c_panel) intersection() { lid_shell(); union() { panel_prism(); ring_prism(); } }
}
module two_tone() { color(c_back) back_shell(); lid_two_tone(); }
module device() { two_tone(); color(c_plate) chassis(); comps_base(); comps_mid(); comps_lid(); dial_knob(); if (show_hw) hw_ghost(); }

// for lineup.scad (use <>): the posed, closed device
module stone2_posed() stand() device();
module stand() if (pose) rotate([90, 0, 0]) translate([-W_in/2, -Ho/2, 0]) children(); else children();

if (part == "assembly") stand() device();
else if (part == "exploded") stand() {
    color(c_back) back_shell();
    place_batt() ghost_batt();
    if (show_hw) color("#9a9a9a") for (t = screwed) translate([t[0] == 0 ? -14 : 14, 0, 0]) side_frame(t) {
        translate([0, 0, -wall]) cylinder(d1 = 6.0, d2 = 0, h = 3.0, $fn = 24); translate([0, 0, -wall]) cylinder(d = 3, h = L_side, $fn = 12); }
    translate([0, 0, 22]) { color(c_plate) chassis(); place_tp() ghost_tp(); place_sw() ghost_switch();
        if (show_hw) color("#9a9a9a") { hw_group(0); hw_group(4); } }
    translate([0, 0, 40]) { comps_mid(); if (show_hw) color("#9a9a9a") hw_group(1); }
    translate([0, 0, 66]) { lid_two_tone(); comps_lid(); dial_knob();
        if (show_hw) color("#9a9a9a") { hw_group(2); hw_group(3); } }
}
else if (part == "cutaway") stand() {
    // section on x = plunger axis + 0.5: cuts the pouch, plate, Thing Plus, GPS/OLED zone and the plunger
    x_cut = rst_p[0] + 0.5;
    intersection() {
        union() { two_tone(); color(c_plate) chassis(); comps_base(); comps_mid(); comps_lid(); dial_knob(); if (show_hw) hw_ghost(); }
        translate([x_cut - 300, -100, -50]) cube([300, 400, 200]);
    }
}
else if (part == "side") stand() device();   // rendered from the side to show the lean
else if (part == "cart") cart_mount(tilt = 55, tube_d = 25.4) translate([-qt_c[0], -qt_c[1], -zb]) device();
else if (part == "strap") rotate([90, 0, 0]) {
    strap_clip(); strap_ghost(220);
    translate([0, clip_puck_y, puck_t]) translate([-qt_c[0], -qt_c[1], -zb]) device();
}
// ---------- print parts, in print orientation on z = 0 ----------
else if (part == "back_shell") translate([0, 0, -zb]) back_shell();                        // back down
else if (part == "lid")   translate([0, 0, zf]) rotate([180, 0, 0]) lid_shell();            // face down
else if (part == "plate") translate([0, 0, -z_plate]) chassis();                            // flat
else if (part == "knob")  knob();                                                            // upright (v0.1 part)
else if (part == "plunger") translate([-rst_p[0], -rst_p[1], -(btn_top + 0.1)]) plunger();  // tip down
// ---------- checks (all should export empty or zero-volume) ----------
else if (part == "chk") intersection() { union() { shell_solid(); chassis(); } keep_all(); }
else if (part == "chk_comp") {   // braces matter: without them the next "else" binds to the inner if
    for (i = [0 : n_keep - 2], j = [i + 1 : n_keep - 1]) if (!is_exempt(i, j)) intersection() { keep_i(i); keep_i(j); }
}
// the measured pouch (49.2 x 70.3) grown by 0.6 all round must clear the shell, plate and ribs
else if (part == "chk_batt") intersection() { real_pouch_at(0.6); union() { shell_solid(); chassis(); } }
// ...and must NOT fit the first print's 55 x 64 pocket (this should be non-empty)
else if (part == "chk_batt_old") difference() { real_pouch_at(0); translate([W_in/2 - 55/2, batt_y0 + (batt[1] - 64)/2, z_batt - 1]) cube([55, 64, 20]); }
else if (part == "chk_plate") intersection() { chassis(); shell_solid(); }
else if (part == "chk_out") difference() { union() { keep_all(); hw_all(); } body(0); }
else if (part == "chk_pilot") intersection() {                                               // pilots vs outer skin, pouch
    pilots();
    union() { difference() { body(0); body(0.4); } place_batt() keep_batt(); }
}
else if (part == "chk_cart") intersection() {
    translate([0, 0, knk_z]) rotate([55, 0, 0]) translate([0, 0, tilt_puck_z]) translate([-qt_c[0], -qt_c[1], -zb]) shell_solid();
    union() { rotate([0, 90, 0]) cylinder(d = 25.4, h = 120, center = true); clamp_half(true); clamp_half(false);
              translate([0, 0, knk_z]) rotate([55, 0, 0]) tilt_head_body(); }
}
