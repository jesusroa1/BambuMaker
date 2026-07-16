// BambuMaker: Lid Fit Tester — plate 2 (92.5 / 92.0 mm)
// Companion to lid_fit_tester (plate 1: 93.5 / 93.0 mm). Round 2 found the
// jar mouth is just barely under 94 mm, so this round steps down in 0.5 mm
// increments. Labels are the actual ring diameter in mm.
//
// Rings instead of solid discs to save filament; the crossbar carries the
// label and doubles as the grip — pinch it through the ring openings to
// pull the tester back out.
//
// NOTE: two ~93 mm circles side by side exceed the A1 Mini bed, so the two
// rings are packed diagonally; the plate spans ~163 mm in X/Y — over the
// 150 mm flag threshold, inside the 170 mm comfort zone.
//
// High $fn so polygon faceting doesn't shrink the effective diameter.
//
// @param diameter_a 92.5
// @param diameter_b 92
// @param ring_wall 8
// @param disc_thickness 2
// @param bar_width 12
// @param label_size 6
// @param label_height 0.6

diameter_a     = 92.5;  // first ring diameter (mm)
diameter_b     = 92;    // second ring diameter (mm)
ring_wall      = 8;     // radial wall of each test ring
disc_thickness = 2;     // keep testers thin to save filament
bar_width      = 12;    // crossbar = label surface + pinch grip
label_size     = 6;     // small text prints faster
label_height   = 0.6;   // raised text

$fn = 180;

lead_in = 0.6;          // bottom-edge chamfer so rings enter the jar easily

// chamfered solid blank the ring and bar are carved from
module blank(od) {
    cylinder(h = lead_in, d1 = od - 2 * lead_in, d2 = od);
    translate([0, 0, lead_in])
        cylinder(h = disc_thickness - lead_in, d = od);
}

module fit_ring(od) {
    // outer ring
    difference() {
        blank(od);
        translate([0, 0, -0.5])
            cylinder(h = disc_thickness + 1, d = od - 2 * ring_wall);
    }

    // crossbar: label surface + pinch grip
    intersection() {
        blank(od);
        translate([-od / 2, -bar_width / 2, -0.5])
            cube([od, bar_width, disc_thickness + 1]);
    }

    // diameter label
    translate([0, 0, disc_thickness])
        linear_extrude(label_height)
            text(str(od), size = label_size,
                 halign = "center", valign = "center",
                 font = "Liberation Sans:style=Bold");
}

// ── diagonal 2-ring plate ────────────────────────────────
offset = 35;
translate([-offset, -offset]) fit_ring(diameter_a);
translate([ offset,  offset]) fit_ring(diameter_b);
