// =====================================================================
//  TwistLock mount kit (shared by every concept), concept-level model.
//  part = "kit"     : cart-bar clamp with tilt head, bag-strap clip, spare puck, 22 mm shim
//       = "socket"  : how the device socket and the puck engage (half-section coupon)
// =====================================================================
include <lib/mount.scad>
include <lib/shape.scad>

part = "kit";
$fn = 40;

// coupon of device back skin (2.2 mm) with the socket, cut in half to show the lip/chamber
module socket_coupon() color("#3d5c4b") intersection() {
    difference() {
        union() {
            translate([-24, -24, 0]) cube([48, 48, 2.2]);
            qt_socket_boss();
        }
        qt_socket_cut();
    }
    translate([-50, 0, -10]) cube([100, 50, 30]);
}

if (part == "kit") mount_kit();
else if (part == "socket") {
    socket_coupon();
    translate([0, 0, -9]) qt_puck(lock = false);   // puck lined up with the notches, ready to push in
    translate([60, 0, 0]) { socket_coupon(); qt_puck(lock = true); }  // seated and turned 90 degrees
}
