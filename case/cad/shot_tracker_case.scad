// =====================================================================
//  Golf Shot Tracker - handheld enclosure (parametric, OpenSCAD)
//  Parts: shell (back), lid (front), plate (internal chassis), knob, reset plunger
//
//  Export a part:   openscad -D 'part="shell"' -o shell.stl shot_tracker_case.scad
//  part = "assembly" | "exploded" | "shell" | "lid" | "plate" | "knob" | "plunger"
//
//  Frame: X = width (left->right, viewed from front), Y = height
//  (bottom end with USB -> top end with the SMA antenna port), Z = depth (back=0, front=D).
//  All board positions below are in INNER-cavity coordinates (origin at the
//  inside back-left-bottom corner).
// =====================================================================

part = "assembly";
show_components = true;     // ghost boards in assembly/exploded views
$fn = 48;

// ---------- print / fit tolerances (PETG, 0.4 nozzle) ----------
clr        = 0.25;   // general part-to-part clearance
lip_clr    = 0.20;   // lid lip to shell wall
insert_d   = 4.0;    // M3 heat-set insert hole (CNC Kitchen style M3x5.7 -> 4.0)
insert_l   = 5.8;
m3_clear   = 3.4;
m3_head_d  = 6.2;    // counterbore for M3 socket head
m3_head_h  = 3.2;
m25_pilot  = 2.1;    // M2.5 self-tapping pilot into PETG

// ---------- shell ----------
wall     = 2.2;
floor_t  = 2.0;
lid_t    = 2.0;
r_out    = 4.5;      // outer corner radius (plan view); GPS board corner sits tight in the top-right
lip_t    = 1.2;
lip_h    = 3.0;

// ---------- components (from SparkFun Eagle/KiCad source files) ----------
// Thing Plus ESP32-S3 (KiCad): 22.86 x 58.42, 2 holes at USB end
tp_w = 22.86;  tp_l = 58.42;
tp_holes = [[2.54, 2.54], [20.32, 2.54]];    // (across, from USB end)
tp_usb_x = 11.43;                            // USB-C centre across board
tp_usb_overhang = 1.5;                       // USB-C shell past board edge
tp_sd_x  = 11.6;                             // microSD card centre (bottom side)

// NEO-M9N SMA breakout (Eagle): 40.64 x 36.80, 4 holes, SMA on +X edge @ y=25.65
gps_l = 40.64; gps_w = 36.80;
gps_holes = [[2.54,2.54],[38.10,2.54],[2.54,34.26],[38.10,34.26]];
gps_sma_y = 25.65;

// Qwiic OLED 1.3" (Eagle): body 35.56 x 25.40 + corner ears, holes 30.48 x 31.75
oled_w = 35.56; oled_body_h = 25.40; oled_ear = 5.715;
oled_holes_dx = 30.48; oled_holes_dy = 31.75;
oled_glass = [34.5, 23.0];
oled_glass_t = 1.6;  // glass + tape; sets boss length (verify with calipers)
oled_window = [32.0, 20.0];

// Qwiic Twist (Eagle): 30.48 x 25.40, holes 25.40 x 20.32; encoder body 13.2x12.4x7.8
tw_w = 30.48; tw_h = 25.40;
tw_holes_dx = 25.40; tw_holes_dy = 20.32;
enc_body = [12.4, 13.4, 7.8];
enc_hole_d = 9.8;    // clears M9 bushing; plain 6 mm shaft passes too
tw_pin_protrusion = 1.6;

// Battery PRT-13855. SparkFun/DigiKey list 61 x 53.3 x 6.4; some resellers list 68.8 x 49.2 x 5.6.
batt = [55, 64, 6.4];      // [x, y, z]  <-- MEASURE YOURS
batt_clear = 0.6;

// Edge SMA jack on the GPS board (Eagle footprint, from the board edge outward):
// flange 0-1.7 mm, thread 1.7-5.3 mm, tip at 6.0 mm. External antenna plugs in here.
sma_edge_gap   = 0.6;   // GPS board edge to inside of top wall
sma_port_d     = 11.0;  // wall opening: lets the plug's 8 mm coupling nut reach the thread

// ---------- layout ----------
W_in = 70;
plate_region_h = 70;
H_in = plate_region_h;
Wo = W_in + 2*wall;
Ho = H_in + 2*wall;

// z stack
z_plate_bot  = floor_t + batt[2] + batt_clear;     // plate sits just above battery
plate_t      = 1.6;
z_plate_top  = z_plate_bot + plate_t;
standoff_h   = 2.4;                                 // clears microSD socket under Thing Plus
z_board_bot  = z_plate_top + standoff_h;
z_comp_top   = z_board_bot + 1.6 + 3.4;             // tallest plate-level part (USB-C / RA Qwiic)
z_tw_bot     = z_comp_top + tw_pin_protrusion + 0.6;
z_tw_top     = z_tw_bot + 1.6;
z_lid_in     = z_tw_top + enc_body[2];              // encoder body touches lid inside
D            = z_lid_in + lid_t;
Ds           = z_lid_in;                            // shell wall height

// plate-level boards (inner coords)
tp_x0 = 8;                        // left gap for side-entry JST battery + Qwiic plugs
tp_y0 = tp_usb_overhang + 1.0;    // USB end toward bottom wall
gps_x0 = W_in - 1.0 - gps_w;      // GPS rotated 90 deg so SMA points +Y out the top wall
gps_y0 = H_in - sma_edge_gap - gps_l;   // SMA edge sits against the top wall
sma_x = gps_x0 + (gps_w - gps_sma_y);
sma_y = gps_y0 + gps_l;

// front boards
tw_cx = W_in/2;  tw_cy = 1 + tw_h/2;
oled_cx = W_in/2;
oled_body_y0 = tw_cy + tw_h/2 + 9.6;         // clears Twist bosses + the RESET plunger under the lower-left ear
oled_cy = oled_body_y0 + oled_body_h/2;

// lid retention: 2 tongues hook under the top wall, 2 screws at the bottom corners
post_d = 7.0;
post_in = 4.2;
posts = [[post_in, post_in], [W_in-post_in, post_in]];
tongue_w = 12; tongue_t = 1.6; tongue_out = 1.0; groove_clr = 0.2;
tongue_xs = [W_in*0.22, W_in*0.78];
z_tongue = z_lid_in - lip_h;
lid_boss_l = 6.0;

// plate screws / support pillars (outside battery footprint)
batt_x0 = (W_in - batt[0])/2;
batt_y0 = plate_region_h - batt[1] - 0.2;   // pushed up to clear the bottom screw posts
plate_screws = [[3.6, 34], [3.6, 60], [W_in-3.6, 58]];


echo(str("OUTER SIZE (mm): ", Wo, " x ", Ho, " x ", D));
echo(str("lid inner z=", z_lid_in, "  plate top z=", z_plate_top, "  board bottom z=", z_board_bot));
echo(str("Lid screw span (head seat to insert end): ", z_lid_in - lid_boss_l + insert_l - m3_head_h, " mm -> M3x25"));

// ---------- RESET plunger (Thing Plus SW2 = ESP32 RST, KiCad 114.935,126.6825) ----------
rst_x = tp_x0 + (114.935 - 101.6);
rst_y = tp_y0 + (152.4 - 126.6825);
btn_top     = z_board_bot + 1.6 + 2.5;     // 4.6x2.8 mm SMD tact, 2.5 mm tall
rst_tube_od = 3.8;
rst_tube_id = 2.5;
rst_pin_d   = 2.1;
rst_tube_bot = btn_top + 2.6;              // collar sits below the tube, under the Twist board height
rst_recess  = -1.0;                         // negative = plunger top stands proud of the lid face

// ---------- EN power switch (SS12D00G3-style mini SPDT slide switch) ----------
sw_body = [3.6, 8.7, 3.6];     // [depth from wall, length, height]  <-- measure yours
sw_slot = [4.8, 2.2];          // actuator opening [along travel (Y), height (Z)]
sw_y = 46;                     // centre, inner coords
sw_z = z_plate_top + 6.5;

// =====================================================================
// helpers
// =====================================================================
module rbox(size, r) {  // rounded in XY
    hull() for (x=[r, size[0]-r], y=[r, size[1]-r])
        translate([x, y, 0]) cylinder(r=r, h=size[2]);
}
module rrect2(w, h, r) { offset(r) square([w-2*r, h-2*r], center=true); }
module inner(p) { translate([wall, wall, 0]) children(); }
// lid screw post hulled into its corner (inner coords); grow = clearance, ext = overshoot past the walls
module post_fill(p, grow, h, ext=0) {
    left = p[0] < W_in/2;
    hull() {
        translate([p[0], p[1], 0]) cylinder(d=post_d + 2*grow, h=h);
        translate([left ? -ext : p[0] - grow, -ext, 0])
            cube([(left ? p[0] : W_in - p[0]) + ext + grow, p[1] + ext + grow, h]);
    }
}

// =====================================================================
// SHELL (back half)
// =====================================================================
module shell() {
    difference() {
        union() {
            difference() {
                rbox([Wo, Ho, Ds], r_out);
                translate([wall, wall, floor_t]) rbox([W_in, H_in, Ds], r_out - wall);
            }
            inner() {
                // lid screw posts, filled out into the corner so they fuse to both walls
                // (the back counterbore leaves only a thin ring of floor under a round post)
                for (p = posts) post_fill(p, 0, z_lid_in - lid_boss_l - 0.2);
                // battery locating ribs (corners)
                for (sx=[0,1], sy=[0,1]) translate([batt_x0 - 1.2 + sx*(batt[0]+1.2+clr),
                                                   batt_y0 - 1.2 + sy*(batt[1]+1.2+clr), 0])
                    cube([1.2, 1.2, floor_t + 3]);
                // plate support pillars
                for (p = plate_screws) translate([p[0], p[1], 0]) cylinder(d=5.4, h=z_plate_bot);
                // plate perimeter ledges on side walls
                for (x=[0, W_in-1.6]) translate([x, 10, 0]) cube([1.6, plate_region_h-14, z_plate_bot]);
            }
            // (no switch cradle: the switch is glued into its wall slot so the plate drops in cleanly)
            // lanyard lug, top-left outer corner
            translate([r_out + 2, Ho - 0.5, Ds - 9]) lanyard_lug();
            // zip-tie anchor beside the SMA port (strain relief for the antenna cable)
            translate([wall + sma_x + sma_port_d/2 + 3, Ho - 0.5, z_board_bot + 0.8 - 4]) lanyard_lug();
        }
        inner() {
            // lid screw holes + back counterbores
            for (p = posts) translate([p[0], p[1], -floor_t - 1]) {
                cylinder(d=m3_clear, h=100);
                cylinder(d=m3_head_d, h=floor_t + 1 + m3_head_h);
            }
            // plate pilot holes
            for (p = plate_screws) translate([p[0], p[1], floor_t]) cylinder(d=m25_pilot, h=50);
            // grooves in the top wall for the lid tongues
            for (x = tongue_xs) translate([x - tongue_w/2 - 0.4, H_in - 0.01, z_tongue - groove_clr])
                cube([tongue_w + 0.8, tongue_out + 0.2 + 0.01, tongue_t + 2*groove_clr]);
            // battery lead pass-through notch in left ledge
            translate([-1, 14, floor_t]) cube([4, 16, z_plate_bot]);
        }
        // left wall: slide-switch actuator slot
        translate([-1, wall + sw_y - sw_slot[0]/2, sw_z - sw_slot[1]/2]) cube([wall + 2, sw_slot[0], sw_slot[1]]);
        // top wall: SMA antenna port
        translate([wall + sma_x, Ho - wall - 1, z_board_bot + 0.8]) rotate([-90,0,0])
            cylinder(d=sma_port_d, h=wall + 2);
        // bottom wall: USB-C + microSD access
        usb_z = z_board_bot + 1.6 + 1.6;
        translate([wall + tp_x0 + tp_usb_x, -1, usb_z]) rotate([-90,0,0])
            linear_extrude(wall + 2) rrect2(12.6, 7.0, 2.2);
        translate([wall + tp_x0 + tp_sd_x, -1, z_board_bot - 0.8]) rotate([-90,0,0])
            linear_extrude(wall + 2) rrect2(12.4, 2.6, 0.6);
        // finger scallop under the SD slot
        translate([wall + tp_x0 + tp_sd_x, -0.01, z_board_bot - 1.6]) scale([1, 0.35, 0.5])
            sphere(d=12);
    }
}

module lanyard_lug() {
    difference() {
        hull() { cube([10, 0.1, 8]); translate([0, 4, 1.5]) cube([10, 0.1, 5]); }
        translate([-1, 2.0, 4]) rotate([0,90,0]) cylinder(d=3.2, h=12);
    }
}

// =====================================================================
// LID (front) - modelled in assembly position
// =====================================================================
module lid() {
    difference() {
        union() {
            translate([0,0,z_lid_in]) rbox([Wo, Ho, lid_t], r_out);
            // locating lip
            translate([0,0,z_lid_in - lip_h]) difference() {
                translate([wall+lip_clr, wall+lip_clr, 0])
                    rbox([W_in-2*lip_clr, H_in-2*lip_clr, lip_h], r_out-wall);
                translate([wall+lip_clr+lip_t, wall+lip_clr+lip_t, -1])
                    rbox([W_in-2*lip_clr-2*lip_t, H_in-2*lip_clr-2*lip_t, lip_h+2], r_out-wall-lip_t);
            }
            inner() {
                // tongues that hook under the top wall
                for (x = tongue_xs) translate([x - tongue_w/2, H_in - lip_clr - lip_t, z_tongue])
                    cube([tongue_w, lip_t + lip_clr + tongue_out, tongue_t]);
                // corner bosses for heat-set inserts
                for (p = posts) translate([p[0], p[1], z_lid_in - lid_boss_l]) cylinder(d=post_d, h=lid_boss_l);
                // Twist bosses (board screws on from behind)
                for (sx=[-1,1], sy=[-1,1])
                    translate([tw_cx + sx*tw_holes_dx/2, tw_cy + sy*tw_holes_dy/2, z_tw_top])
                        cylinder(d=5.0, h=z_lid_in - z_tw_top);
                // OLED bosses at the ear holes (glass presses on the lid)
                for (sx=[-1,1], sy=[-1,1])
                    translate([oled_cx + sx*oled_holes_dx/2, oled_cy + sy*oled_holes_dy/2, z_lid_in - oled_glass_t])
                        cylinder(d=4.8, h=oled_glass_t);
                // RESET plunger guide tube
                translate([rst_x, rst_y, rst_tube_bot]) intersection() {        // flattened where it passes the Twist edge
                    cylinder(d=rst_tube_od, h=z_lid_in - rst_tube_bot + 0.01);
                    translate([-5, (tw_cy + tw_h/2 + 0.25) - rst_y, 0]) cube([10, 10, 50]);
                }
                // OLED glass locating frame
                translate([oled_cx, oled_cy, z_lid_in - 1.0]) linear_extrude(1.0) difference() {
                    square([oled_glass[0] + 2*clr + 2.4, oled_glass[1] + 2*clr + 2.4], center=true);
                    square([oled_glass[0] + 2*clr, oled_glass[1] + 2*clr], center=true);
                    // gaps for the flex tail + ears
                    square([oled_glass[0] + 10, 12], center=true);
                }
            }
        }
        inner() {
            for (p = posts) translate([p[0], p[1], z_lid_in - lid_boss_l - 1]) cylinder(d=insert_d, h=insert_l + 1);
            for (sx=[-1,1], sy=[-1,1]) {
                translate([tw_cx + sx*tw_holes_dx/2, tw_cy + sy*tw_holes_dy/2, z_tw_top - 1])
                    cylinder(d=m25_pilot, h=z_lid_in - z_tw_top + 1 + lid_t - 0.6);
                translate([oled_cx + sx*oled_holes_dx/2, oled_cy + sy*oled_holes_dy/2, z_lid_in - oled_glass_t - 1])
                    cylinder(d=m25_pilot, h=oled_glass_t + 1 + lid_t - 0.6);
            }
            // OLED window with chamfer on the outside
            translate([oled_cx, oled_cy, z_lid_in - 0.01]) hull() {
                linear_extrude(0.01) square(oled_window, center=true);
                translate([0,0,lid_t + 0.02]) linear_extrude(0.01)
                    square([oled_window[0] + 2*lid_t, oled_window[1] + 2*lid_t], center=true);
            }
            // lip notches where the OLED's top ears reach the wall
            for (sx=[-1,1]) translate([oled_cx + sx*oled_holes_dx/2 - 3.5, oled_cy + oled_holes_dy/2, z_lid_in - lip_h - 1])
                cube([7, 10, lip_h + 0.99]);
            // RESET plunger bore (+ small outer chamfer)
            translate([rst_x, rst_y, rst_tube_bot - 1]) cylinder(d=rst_tube_id, h=50);
            translate([rst_x, rst_y, z_lid_in + lid_t - 0.6]) cylinder(d1=rst_tube_id, d2=rst_tube_id + 1.4, h=0.61);
            // encoder shaft / bushing
            translate([tw_cx, tw_cy, z_lid_in - 1]) cylinder(d=enc_hole_d, h=lid_t + 2);
            // clearance for the encoder body so it can seat flush against the lid
            translate([tw_cx, tw_cy, z_lid_in - lip_h - 0.01]) linear_extrude(lip_h)
                square([enc_body[0] + 1, enc_body[1] + 1], center=true);
        }
    }
}

// =====================================================================
// PLATE (internal chassis over the battery)
// =====================================================================
module plate() {
    ph = plate_region_h - 0.4;
    difference() {
        union() {
            translate([clr, clr, z_plate_bot]) rbox([W_in - 2*clr, ph - clr, plate_t], r_out - wall - clr);
            inner0() {
                // Thing Plus standoffs (USB end) + far-end rest
                for (h = tp_holes) translate([tp_x0 + h[0], tp_y0 + h[1], z_plate_top]) cylinder(d=5, h=standoff_h);
                translate([tp_x0 + tp_w/2 - 5, tp_y0 + tp_l - 4, z_plate_top]) cube([10, 3, standoff_h]);
                // GPS standoffs (board rotated 90 deg)
                for (h = gps_holes) translate([gps_x0 + (gps_w - h[1]), gps_y0 + h[0], z_plate_top])
                    cylinder(d=5, h=standoff_h);
            }
        }
        inner0() {
            for (h = tp_holes) translate([tp_x0 + h[0], tp_y0 + h[1], z_plate_bot - 1]) cylinder(d=m25_pilot, h=10);
            for (h = gps_holes) translate([gps_x0 + (gps_w - h[1]), gps_y0 + h[0], z_plate_bot - 1])
                cylinder(d=m25_pilot, h=10);
            // screw holes into support pillars (countersunk from top)
            for (p = plate_screws) translate([p[0], p[1], z_plate_bot - 1]) {
                cylinder(d=2.8, h=10);
                translate([0,0,1 + plate_t - 1.4]) cylinder(d1=2.8, d2=5.4, h=1.41);
            }
            // relief under the SMA jack + mated plug
            translate([sma_x - 5, sma_y - 3, z_plate_bot - 1]) cube([10, 30, 10]);
            // clearance around the corner-filled lid screw posts (notch runs out to the edges, no thin slivers)
            for (p = posts) translate([0, 0, z_plate_bot - 1]) post_fill(p, clr, 10, 1);
            // notch so the plate drops past the slide switch body on the left wall
            translate([-1, sw_y - sw_body[1]/2 - 1, z_plate_bot - 1]) cube([1 + sw_body[0] + 1, sw_body[1] + 2, 10]);
            // battery lead + Qwiic pass-through (left edge)
            translate([-1, 14, z_plate_bot - 1]) cube([6, 16, 10]);
            // lightening/ventilation slots under the boards (also saves print time)
            for (i=[0:3]) translate([tp_x0 + 5, tp_y0 + 12 + i*10, z_plate_bot - 1]) cube([tp_w - 10, 5, 10]);
            for (i=[0:2]) translate([gps_x0 + 7, gps_y0 + 7 + i*10, z_plate_bot - 1]) cube([gps_w - 14, 5, 10]);
        }
    }
}
module inner0() { translate([0,0,0]) children(); }   // plate is modelled in inner coords

// =====================================================================
// KNOB (optional) - print in clear/translucent PETG so the RGB shaft shows through
// =====================================================================
knob_d = 18; knob_h = 12; shaft_d = 6.0; bore_depth = 10;
module knob() {
    difference() {
        union() {
            cylinder(d=knob_d, h=knob_h - 1);
            translate([0,0,knob_h-1]) cylinder(d1=knob_d, d2=knob_d-2, h=1);
            for (a=[0:15:359]) rotate(a) translate([knob_d/2, 0, 0]) cylinder(d=1.2, h=knob_h - 1, $fn=12);
        }
        translate([0,0,-0.01]) cylinder(d=shaft_d + 0.15, h=bore_depth);
        translate([0,0,-0.01]) cylinder(d1=shaft_d + 1, d2=shaft_d + 0.15, h=0.6);
        translate([0,0,bore_depth - 0.1]) cylinder(d=3, h=knob_h);        // light pipe to the top
    }
    // crush ribs
    for (a=[0:120:359]) rotate(a) translate([shaft_d/2 + 0.08, 0, 0]) cylinder(d=0.6, h=bore_depth - 1, $fn=8);
}

// =====================================================================
// RESET PLUNGER - modelled in assembly position; cone tip presses the tact switch
// =====================================================================
module plunger() {
    inner() translate([rst_x, rst_y, 0]) {
        translate([0,0,btn_top + 0.1]) cylinder(d1=1.2, d2=3.4, h=0.8);                  // tip
        translate([0,0,btn_top + 0.9]) cylinder(d=3.4, h=rst_tube_bot - btn_top - 1.2);   // retaining collar
        translate([0,0,btn_top + 0.9]) cylinder(d=rst_pin_d, h=z_lid_in + lid_t - rst_recess - btn_top - 0.9);
    }
}

// =====================================================================
// ghost components for fit checks
// =====================================================================
module components() { comp_base(); comp_plate(); comp_lid(); }

module comp_base() inner() {
    color("steelblue") translate([0, sw_y - sw_body[1]/2, sw_z - sw_body[2]/2]) cube(sw_body);
    color("steelblue") translate([-2, sw_y - 0.75, sw_z - 0.75]) cube([2, 1.5, 1.5]);            // actuator
    color("silver", 0.8) translate([batt_x0, batt_y0, floor_t]) cube(batt);
}

module comp_plate() inner() {
    color("orange") translate([tp_x0 + (114.935-101.6) - 2.3, tp_y0 + (152.4-126.6825) - 1.4, z_board_bot + 1.6]) cube([4.6, 2.8, 2.5]);
    color("orange") translate([tp_x0 + (114.935-101.6) - 2.3, tp_y0 + (152.4-131.7625) - 1.4, z_board_bot + 1.6]) cube([4.6, 2.8, 2.5]);
    color("red", 0.9) translate([tp_x0, tp_y0, z_board_bot]) {
        cube([tp_w, tp_l, 1.6]);
        translate([tp_w/2 - 7.7, tp_l - 20.4, 1.6]) cube([15.4, 20.4, 2.4]);           // ESP32 module
        translate([tp_usb_x - 4.5, -tp_usb_overhang, 1.6]) cube([9, 7.5, 3.2]);       // USB-C
        translate([tp_sd_x - 5.5, -4.2, -1.4]) cube([11, 15, 1.4]);                   // microSD card
    }
    color("red", 0.9) translate([gps_x0, gps_y0, z_board_bot]) {
        cube([gps_w, gps_l, 1.6]);
        translate([gps_w/2 - 6, gps_l/2 - 8, 1.6]) cube([12, 16, 2.4]);               // NEO-M9N
    }
    color("gold") translate([sma_x, sma_y, z_board_bot + 0.8]) rotate([-90,0,0]) cylinder(d=6.35, h=6.0);   // jack
    color("dimgray") translate([sma_x, sma_y + 1.8, z_board_bot + 0.8]) rotate([-90,0,0]) cylinder(d=9.2, h=9, $fn=6); // plug nut
    color("black") translate([sma_x, sma_y + 10.8, z_board_bot + 0.8]) rotate([-90,0,0]) cylinder(d=5, h=12);   // cable boot
}

module comp_lid() inner() {
    color("red", 0.9) translate([tw_cx - tw_w/2, tw_cy - tw_h/2, z_tw_bot]) cube([tw_w, tw_h, 1.6]);
    color("dimgray") translate([tw_cx - enc_body[0]/2, tw_cy - enc_body[1]/2, z_tw_top]) cube(enc_body);
    color("white", 0.6) translate([tw_cx, tw_cy, z_tw_top]) cylinder(d=6, h=enc_body[2] + 10);
    color("red", 0.9) translate([oled_cx - oled_w/2, oled_cy - oled_body_h/2, z_lid_in - oled_glass_t - 1.6])
        cube([oled_w, oled_body_h, 1.6]);
    color("red", 0.9) for (sx=[-1,1], sy=[-1,1])      // ears
        translate([oled_cx + sx*oled_holes_dx/2, oled_cy + sy*oled_holes_dy/2, z_lid_in - oled_glass_t - 1.6])
            cylinder(d=5.08, h=1.6);
    color("black") translate([oled_cx - oled_glass[0]/2, oled_cy - oled_glass[1]/2, z_lid_in - oled_glass_t])
        cube([oled_glass[0], oled_glass[1], oled_glass_t]);
}

// =====================================================================
// part selection
// =====================================================================
if (part == "shell") shell();
else if (part == "lid") translate([0, Ho, D]) rotate([180, 0, 0]) lid();     // face-down for printing
else if (part == "plate") translate([0, 0, -z_plate_bot]) plate();
else if (part == "knob") knob();
else if (part == "plunger") translate([-(wall + rst_x), -(wall + rst_y), -(btn_top + 0.1)]) plunger();
else if (part == "chk_plunger") intersection() { plunger(); union() { shell(); translate([wall,wall,0]) plate(); components(); } }
else if (part == "chk_plunger_lid") intersection() { plunger(); lid(); }
else if (part == "chk_shell") intersection() { shell(); components(); }
else if (part == "chk_lid") intersection() { lid(); components(); }
else if (part == "chk_plate") intersection() { translate([wall, wall, 0]) plate(); components(); }
else if (part == "chk_shell_lid") intersection() { shell(); lid(); }
else if (part == "chk_shell_plate") intersection() { shell(); translate([wall, wall, 0]) plate(); }
else if (part == "chk_lid_plate") intersection() { lid(); translate([wall, wall, 0]) plate(); }
else if (part == "exploded") {
    color("#4a6b5a") shell();
    if (show_components) comp_base();
    translate([0, 0, 30]) { translate([wall, wall, 0]) color("#c9b458") plate(); if (show_components) comp_plate(); }
    translate([0, 0, 70]) { color("#e8e8e8", 0.9) lid(); if (show_components) comp_lid(); }
    translate([wall + tw_cx, wall + tw_cy, D + 85]) color("white", 0.8) knob();
    translate([0, 0, 70]) color("orange") plunger();
} else {
    color("#4a6b5a") shell();
    translate([wall, wall, 0]) color("#c9b458") plate();
    color("#e8e8e8") lid();
    if (show_components) components();
    translate([wall + tw_cx, wall + tw_cy, D + 2]) color("white", 0.8) knob();
    color("orange") plunger();
}
