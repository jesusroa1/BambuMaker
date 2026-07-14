// BambuMaker: Lid Fit Tester — plate B (oversize: -1 / -2)
// Companion to lid_fit_tester (plate A, "+2" / "+1"). Same flat test rings
// for a 92 mm blender jar mouth, but oversize in case the mouth measures
// over 92 mm: "-1" = 1 mm oversize per side, "-2" = 2 mm.
//
// Rings instead of solid discs to save filament; the crossbar carries the
// label and doubles as the grip — pinch it through the ring openings to
// pull the tester back out.
//
// NOTE: two 92 mm circles side by side exceed the A1 Mini bed, so the two
// rings are packed diagonally; the plate spans ~160 mm in X/Y — over the
// 150 mm flag threshold, inside the 170 mm comfort zone.
//
// High $fn so polygon faceting doesn't shrink the effective diameter.
//
// @param jar_inner_diameter 92
// @param clearance_a -1
// @param clearance_b -2
// @param ring_wall 8
// @param disc_thickness 2
// @param bar_width 14
// @param label_size 9
// @param label_height 0.6

jar_inner_diameter = 92;    // measured across the jar mouth opening (mm)
clearance_a        = -1;    // first ring, labeled "-1" (1 mm oversize per side)
clearance_b        = -2;    // second ring, labeled "-2" (2 mm oversize per side)
ring_wall          = 8;     // radial wall of each test ring
disc_thickness     = 2;     // keep testers thin to save filament
bar_width          = 14;    // crossbar = label surface + pinch grip
label_size         = 9;
label_height       = 0.6;   // raised text

$fn = 180;

lead_in = 0.6;              // bottom-edge chamfer so rings enter the jar easily

// "+2" / "-1" shorthand: clearance in whole millimetres per side
function clearance_label(c) = str(c > 0 ? "+" : "-", abs(round(c)));

// chamfered solid blank the ring and bar are carved from
module blank(od) {
    cylinder(h = lead_in, d1 = od - 2 * lead_in, d2 = od);
    translate([0, 0, lead_in])
        cylinder(h = disc_thickness - lead_in, d = od);
}

module fit_ring(clearance) {
    od = jar_inner_diameter - 2 * clearance;

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

    // clearance label
    translate([0, 0, disc_thickness])
        linear_extrude(label_height)
            text(clearance_label(clearance), size = label_size,
                 halign = "center", valign = "center",
                 font = "Liberation Sans:style=Bold");
}

// ── diagonal 2-ring plate ────────────────────────────────
offset = 35;
translate([-offset, -offset]) fit_ring(clearance_a);
translate([ offset,  offset]) fit_ring(clearance_b);
