// BambuMaker: Blender Lid
// Friction-fit lid for a blender jar with an 80 mm inner mouth diameter.
// A flat cap with two grip tabs sits on the rim; a hollow plug ring drops
// inside the jar and holds by light friction (slip-fit clearance).
//
// Prints cap-face-down: the flat top is on the bed and the plug ring rises
// straight up — no overhangs, no supports.
//
// Recommended material: PETG (kitchen use, slight flex helps the fit).
//
// @param jar_inner_diameter 80
// @param fit_clearance 0.25
// @param cap_thickness 3
// @param cap_overhang 7
// @param plug_depth 10
// @param plug_wall 2.5
// @param tab_length 14
// @param tab_width 34

jar_inner_diameter = 80;    // measured across the jar mouth opening (mm)
fit_clearance      = 0.25;  // per-side gap between plug and jar wall
cap_thickness      = 3;     // flat top plate
cap_overhang       = 7;     // how far the cap extends past the jar mouth
plug_depth         = 10;    // how deep the ring reaches into the jar
plug_wall          = 2.5;   // plug ring wall thickness
tab_length         = 14;    // grip tab reach past the cap edge
tab_width          = 34;    // grip tab width along the cap edge

$fn = 96;

plug_r  = jar_inner_diameter / 2 - fit_clearance;
cap_r   = jar_inner_diameter / 2 + cap_overhang;
tab_r   = 6;                // corner radius of the grip tabs
lead_in = 1.2;              // chamfer on the plug's free end for easy insertion

// ── Cap plate with grip tabs ─────────────────────────────
linear_extrude(cap_thickness)
    union() {
        circle(r = cap_r);
        for (s = [-1, 1])
            scale([s, 1])
                hull()
                    for (y = [-1, 1]) {
                        // outer tab corners
                        translate([cap_r + tab_length - tab_r,
                                   y * (tab_width / 2 - tab_r)])
                            circle(tab_r);
                        // anchor corners well inside the cap circle
                        translate([cap_r * 0.6,
                                   y * (tab_width / 2 - tab_r)])
                            circle(tab_r);
                    }
    }

// ── Plug ring ────────────────────────────────────────────
// Hollow ring under the cap (above it in print orientation); the free end
// is chamfered so the lid drops into the jar mouth without fiddling.
translate([0, 0, cap_thickness])
    difference() {
        union() {
            cylinder(h = plug_depth - lead_in, r = plug_r);
            translate([0, 0, plug_depth - lead_in])
                cylinder(h = lead_in, r1 = plug_r, r2 = plug_r - lead_in);
        }
        translate([0, 0, -0.5])
            cylinder(h = plug_depth + 1, r = plug_r - plug_wall);
    }
