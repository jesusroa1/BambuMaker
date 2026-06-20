// BambuMaker: Mug
// A parametric coffee mug for the Bambu A1 Mini
//
// @param height 100
// @param outer_diameter 80
// @param wall_thickness 3
// @param base_thickness 4
// @param handle_extend 35

height          = 100;
outer_diameter  = 80;
wall_thickness  = 3;
base_thickness  = 4;
handle_extend   = 35;

$fn = 64;
r = outer_diameter / 2;

// ── Cup body ─────────────────────────────────────────────
difference() {
    cylinder(h=height, r=r);
    translate([0, 0, base_thickness])
        cylinder(h=height, r=r - wall_thickness);
}

// ── Handle ───────────────────────────────────────────────
// D-shaped solid handle, hulled from two tapered columns
handle_w  = wall_thickness * 2.2;
z_low     = height * 0.18;
z_high    = height * 0.80;
z_span    = z_high - z_low;

hull() {
    // Attachment column at mug surface
    translate([r - 0.5, -handle_w/2, z_low])
        cube([0.5, handle_w, z_span]);

    // Outer column, shorter so the shape tapers at top/bottom
    translate([r + handle_extend, -handle_w/2, z_low + z_span*0.22])
        cube([wall_thickness, handle_w, z_span * 0.56]);
}
