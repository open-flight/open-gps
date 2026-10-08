// =====================================================================
//  Ghost components for the enclosure concepts.
//  Dimensions are copied from ../cad/shot_tracker_case.scad (v0.1), which took them
//  from SparkFun's Eagle/KiCad sources. Keep them in sync if v0.1 is re-measured.
//
//  Every ghost is modelled in its own LOCAL frame:
//    board bottom face at z = 0, component side facing +z.
//  The concepts place them with translate/rotate.
//  ghost_*()      = what is drawn (colours, plugs, cables)
//  keep_*()       = solid used for collision checks (the part plus the space it needs)
// =====================================================================

// ---------- Thing Plus ESP32-S3 (KiCad) ----------
tp_w = 22.86;  tp_l = 58.42;          // local x = across, y = along (USB end at y = 0)
tp_usb_x = 11.43;  tp_usb_overhang = 1.5;
tp_sd_x  = 11.6;                       // microSD (bottom side), card sticks out 4.2 past the USB end
tp_rst   = [13.335, 25.7175];          // SW2 RESET centre (across, from USB end)
tp_boot  = [13.335, 20.6375];
tp_parts_h = 3.4;                      // tallest top-side part (USB-C / right-angle Qwiic)
tp_standoff = 2.4;                     // clears the microSD socket under the board
tp_keepout = 7.0;                      // side-entry JST battery + Qwiic plugs on the local -x edge (v0.1 kept 8)

// ---------- NEO-M9N SMA breakout (Eagle) ----------
// Local frame = v0.1's rotated frame: x across 36.80, y along 40.64, SMA edge at y = gps_l (+y).
gps_w = 36.80; gps_l = 40.64;
gps_sma_x   = gps_w - 25.65;           // 11.15 from the local left edge
gps_j4_x    = gps_w - 15.60;           // top-edge Qwiic J4 (left unused in the concepts)
gps_sma_z   = 0.8;                     // jack axis above board bottom
gps_holes   = [[2.54,2.54],[34.26,2.54],[2.54,38.10],[34.26,38.10]];

// ---------- Qwiic OLED 1.3" (Eagle) ----------
oled_w = 35.56; oled_body_h = 25.40;
oled_holes = [30.48, 31.75]; oled_ear_d = 5.08;
oled_glass = [34.5, 23.0, 1.6];        // glass + tape (verify)
oled_window = [32.0, 20.0];
oled_rear = 3.0;                       // keep-out behind the PCB for its Qwiic connectors + passives (estimate)
oled_span_y = oled_holes[1] + oled_ear_d;   // 36.83 incl. ears

// ---------- Qwiic Twist (Eagle) ----------
tw_w = 30.48; tw_h = 25.40;
tw_holes = [25.40, 20.32];
enc_body = [12.4, 13.4, 7.8];
tw_pins = 1.6;                         // encoder pins through the PCB
enc_hole_d = 9.8;
shaft_d = 6.0; shaft_above = 10.0;     // shaft above the encoder body (as modelled in v0.1)

// ---------- LiPo 2 Ah (PRT-13855) ----------
batt = [55, 64, 6.4];                  // v0.1 pocket; listed 61 x 53.3 x 6.4 (some resellers: 68.8 x 49.2 x 5.6)
batt_swell = 0.6;                      // free space above the pouch

// ---------- EN slide switch (SS12D00G3-style) ----------
sw_body = [3.6, 8.7, 3.6];             // [into the case, along the wall, height]
sw_slot = [4.8, 2.2];

// ---------- knob (v0.1 part) ----------
knob_d = 18; knob_h = 12;

// RESET plunger (v0.1 part): guide tube OD, pin
rst_tube_od = 3.8; rst_pin_d = 2.1;

// =====================================================================
module ghost_tp() {
    color("#d33") cube([tp_w, tp_l, 1.6]);
    color("#bbb") translate([tp_w/2 - 7.7, tp_l - 20.4, 1.6]) cube([15.4, 20.4, 2.4]);        // ESP32-S3 module
    color("#999") translate([tp_usb_x - 4.5, -tp_usb_overhang, 1.6]) cube([9, 7.5, 3.2]);     // USB-C
    color("#222") translate([tp_sd_x - 5.5, -4.2, -1.4]) cube([11, 15, 1.4]);                 // microSD card
    for (p = [tp_rst, tp_boot]) color("orange") translate([p[0] - 2.3, p[1] - 1.4, 1.6]) cube([4.6, 2.8, 2.5]);
    color("#fff", 0.35) keep_tp_plugs();
}
module keep_tp_plugs() translate([-tp_keepout, 8, 0]) cube([tp_keepout, 42, 1.6 + 4.4]);   // local y 8..50 (JST near the USB end per v0.1's lead notch)
module keep_tp() {
    cube([tp_w, tp_l, 1.6 + tp_parts_h]);
    translate([tp_usb_x - 4.5, -tp_usb_overhang, 1.6]) cube([9, 7.5, 3.2]);
    translate([tp_sd_x - 5.5, -4.2, -1.4]) cube([11, 15, 1.4]);
    keep_tp_plugs();
}

module ghost_gps() {
    color("#d33") cube([gps_w, gps_l, 1.6]);
    color("#bbb") translate([gps_w/2 - 6, gps_l/2 - 8, 1.6]) cube([12, 16, 2.4]);             // NEO-M9N
    color("gold") translate([gps_sma_x, gps_l, gps_sma_z]) rotate([-90,0,0]) cylinder(d=6.35, h=6.0, $fn=24);
    color("#eee") translate([gps_j4_x - 3, gps_l - 4.2, 1.6]) cube([6, 4.2, 3.0]);           // J4 (unused)
}
module keep_gps() {
    cube([gps_w, gps_l, 1.6 + 2.4]);
    translate([gps_j4_x - 3, gps_l - 4.2, 1.6]) cube([6, 4.2, 3.0]);
    translate([gps_sma_x, gps_l, gps_sma_z]) rotate([-90,0,0]) cylinder(d=6.35, h=1.7, $fn=24); // flange part only
}
// mated antenna plug + cable boot (outside the case, drawn only)
module ghost_sma_plug() {
    color("#555") translate([gps_sma_x, gps_l + 1.8, gps_sma_z]) rotate([-90,0,0]) cylinder(d=9.2, h=9, $fn=6);
    color("#111") translate([gps_sma_x, gps_l + 10.8, gps_sma_z]) rotate([-90,0,0]) cylinder(d=5, h=14, $fn=16);
}

module ghost_oled() {      // centred on the body centre
    color("#d33") translate([-oled_w/2, -oled_body_h/2, 0]) cube([oled_w, oled_body_h, 1.6]);
    color("#d33") for (sx=[-1,1], sy=[-1,1]) translate([sx*oled_holes[0]/2, sy*oled_holes[1]/2, 0]) cylinder(d=oled_ear_d, h=1.6, $fn=20);
    color("#0a0a0a") translate([-oled_glass[0]/2, -oled_glass[1]/2, 1.6]) cube(oled_glass);
    color("#3af") translate([-oled_window[0]/2 + 1, -oled_window[1]/2 + 1, 1.6 + oled_glass[2]]) cube([oled_window[0] - 2, oled_window[1] - 2, 0.05]);
    color("#fff", 0.3) keep_oled_rear();
}
module keep_oled_rear() translate([-oled_w/2, -oled_body_h/2, -oled_rear]) cube([oled_w, oled_body_h, oled_rear]);
module keep_oled() {
    translate([-oled_w/2, -oled_body_h/2, 0]) cube([oled_w, oled_body_h, 1.6]);
    for (sx=[-1,1], sy=[-1,1]) translate([sx*oled_holes[0]/2, sy*oled_holes[1]/2, 0]) cylinder(d=oled_ear_d, h=1.6, $fn=20);
    translate([-oled_glass[0]/2, -oled_glass[1]/2, 1.6]) cube(oled_glass);
    keep_oled_rear();
}

module ghost_twist() {     // centred on the encoder shaft
    color("#d33") translate([-tw_w/2, -tw_h/2, 0]) cube([tw_w, tw_h, 1.6]);
    color("#555") translate([-enc_body[0]/2, -enc_body[1]/2, 1.6]) cube(enc_body);
    color("#888") translate([-6, -6, -tw_pins]) cube([12, 12, tw_pins]);
    color("#fff", 0.7) translate([0, 0, 1.6 + enc_body[2]]) cylinder(d=shaft_d, h=shaft_above, $fn=24);
}
module keep_twist() {
    translate([-tw_w/2, -tw_h/2, 0]) cube([tw_w, tw_h, 1.6]);
    translate([-enc_body[0]/2, -enc_body[1]/2, 1.6]) cube(enc_body);
    translate([-6, -6, -tw_pins]) cube([12, 12, tw_pins]);
}
twist_top = 1.6 + enc_body[2];          // encoder top above Twist PCB bottom

module ghost_batt() { color("#c8c8c8") cube(batt); }
module keep_batt()  { cube([batt[0], batt[1], batt[2] + batt_swell]); }

// switch body against a wall at x = 0, body extends +x; actuator pokes out to -x
module ghost_switch() {
    color("steelblue") translate([0, -sw_body[1]/2, -sw_body[2]/2]) cube(sw_body);
    color("#36c") translate([-2.4, -0.75, -0.75]) cube([2.4, 1.5, 1.5]);
}

module ghost_knob() {
    color("#f4f4f4") difference() {
        union() {
            cylinder(d=knob_d, h=knob_h - 1, $fn=48);
            translate([0,0,knob_h-1]) cylinder(d1=knob_d, d2=knob_d-2, h=1, $fn=48);
            for (a=[0:15:359]) rotate(a) translate([knob_d/2, 0, 0]) cylinder(d=1.2, h=knob_h - 1, $fn=8);
        }
        translate([0,0,knob_h - 2]) cylinder(d=3, h=5, $fn=16);
    }
}
