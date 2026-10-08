// To-scale lineups, closed and standing up.
//   part = "all" : v0.1, Concept A Grip, Concept B Stone
//   part = "b2"  : v0.1, Concept B Stone, Concept B2 Stone (layered)
use <../cad/shot_tracker_case.scad>
use <concept_a_grip.scad>
use <concept_b_stone.scad>
use <concept_b2_stone.scad>

part = "all";
gap = 30;

module v01() rotate([90, 0, 0]) translate([-37.2, -39, 0]) {
    color("#4a6b5a") shell(); color("#e8e8e8") lid(); color("orange") plunger();
    translate([2.2 + 35, 2.2 + 13.7, 31.6 + 2]) color("white") knob();
}

v01();
if (part == "b2") {
    translate([37.2 + gap + 39.7, 0, 0]) stone_posed();
    translate([37.2 + gap + 79.4 + gap + 31.5, 0, 0]) stone2_posed();
} else {
    translate([37.2 + gap + 39.3, 0, 0]) grip_posed();
    translate([37.2 + gap + 78.6 + gap + 39.7, 0, 0]) stone_posed();
}
