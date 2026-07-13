// BambuMaker: Lid Fit Tester
// Calibration plate for the blender lid: four thin discs sized to drop
// into an 80 mm jar mouth at different clearances, so the right friction
// fit can be found before reprinting the full lid. Each disc carries a
// raised label with its clearance (+ = smaller than the jar mouth,
// - = oversize) and a grip bar for pulling it back out.
//
// Clearances tested: +0.15, +0.05, -0.05, -0.15 mm per side
// → disc diameters 79.7, 79.9, 80.1, 80.3 mm.
//
// NOTE: the 2 × 2 plate spans ~166 mm in X/Y — over the 150 mm flag
// threshold but inside the A1 Mini's 170 mm comfort zone.
//
// @param jar_inner_diameter 80
// @param clearance_start 0.15
// @param clearance_step 0.1
// @param disc_count 4
// @param disc_thickness 2
// @param label_size 9
// @param label_height 0.6
// @param grip_length 50
// @param grip_height 8

jar_inner_diameter = 80;    // measured across the jar mouth opening (mm)
clearance_start    = 0.15;  // loosest fit tested (per side)
clearance_step     = 0.1;   // each disc is this much tighter than the last
disc_count         = 4;
disc_thickness     = 2;     // keep discs thin to save filament
label_size         = 9;
label_height       = 0.6;   // raised text
grip_length        = 50;
grip_height        = 8;

$fn = 64;

lead_in = 0.6;              // bottom-edge chamfer so discs enter the jar easily

function pad2(n) = n < 10 ? str("0", n) : str(n);

// "+0.15" / "-0.05" built from integer hundredths to dodge float noise
function clearance_label(c) =
    let (h = round(c * 100))
    str(h < 0 ? "-" : "+", floor(abs(h) / 100), ".", pad2(abs(h) % 100));

module fit_disc(clearance) {
    d = jar_inner_diameter - 2 * clearance;

    // disc with chamfered bottom edge
    cylinder(h = lead_in, d1 = d - 2 * lead_in, d2 = d);
    translate([0, 0, lead_in])
        cylinder(h = disc_thickness - lead_in, d = d);

    // grip bar below center
    translate([-grip_length / 2, -13, disc_thickness])
        cube([grip_length, 6, grip_height]);

    // clearance label above center
    translate([0, 6, disc_thickness])
        linear_extrude(label_height)
            text(clearance_label(clearance), size = label_size,
                 halign = "center", font = "Liberation Sans:style=Bold");
}

// ── 2 × 2 plate ──────────────────────────────────────────
cols    = 2;
rows    = ceil(disc_count / cols);
spacing = jar_inner_diameter
          + 2 * abs(clearance_start - (disc_count - 1) * clearance_step)
          + 5;

for (i = [0 : disc_count - 1]) {
    c = clearance_start - i * clearance_step;
    translate([(i % cols - (cols - 1) / 2) * spacing,
               ((rows - 1) / 2 - floor(i / cols)) * spacing, 0])
        fit_disc(c);
}
