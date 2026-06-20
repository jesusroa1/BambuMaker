// BambuMaker: Bowl
// @param diameter 120
// @param height 50
// @param wall_thickness 3

diameter       = 120;
height         = 50;
wall_thickness = 3;

$fn = 64;
r = diameter / 2;

difference() {
    sphere(r = r);
    sphere(r = r - wall_thickness);
    translate([0, 0, -r])
        cube([r * 2, r * 2, r * 2], center = true);
    translate([0, 0, height - r])
        cube([r * 2, r * 2, r * 2], center = true);
}
