// BambuMaker: Blender Lid — 92 mm tapered fit
// Friction-fit lid for a blender jar. The 92 mm fit-tester ring was the
// match, so the plug is sized around that: a tapered (conical) plug ring
// enters the jar at 91 mm and widens to 92.4 mm at the cap, wedging snug
// as it seats — the taper is its own lead-in, no fiddling to insert.
//
// Prints cap-face-down: the flat top is on the bed and the plug ring rises
// straight up, narrowing as it goes — no overhangs, no supports.
//
// Recommended material: PETG (kitchen use, slight flex helps the wedge fit).
//
// @param seat_diameter 92.4
// @param tip_diameter 91
// @param cap_thickness 3
// @param cap_overhang 7
// @param plug_depth 12
// @param plug_wall 2.5
// @param tab_length 14
// @param tab_width 34

seat_diameter = 92.4;  // plug OD where it meets the cap — a touch over the
                       // 92 mm tester so the wedge lands snug, not loose
tip_diameter  = 91;    // plug OD at the free end — drops into the mouth easily
cap_thickness = 3;     // flat top plate
cap_overhang  = 7;     // how far the cap extends past the jar mouth
plug_depth    = 12;    // taper length — deeper taper = more wedge travel
plug_wall     = 2.5;   // plug ring wall thickness (at the tip)
tab_length    = 14;    // grip tab reach past the cap edge
tab_width     = 34;    // grip tab width along the cap edge

// High $fn so polygon faceting doesn't shrink the plug's effective
// diameter (matches the lid_fit_tester rings).
$fn = 180;

cap_r = seat_diameter / 2 + cap_overhang;
tab_r = 6;             // corner radius of the grip tabs

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

// ── Tapered plug ring ────────────────────────────────────
// Hollow cone under the cap (above it in print orientation): widest at the
// cap, narrowest at the free end, so pushing the lid down wedges it snug.
translate([0, 0, cap_thickness])
    difference() {
        cylinder(h = plug_depth,
                 r1 = seat_diameter / 2,
                 r2 = tip_diameter / 2);
        translate([0, 0, -0.5])
            cylinder(h = plug_depth + 1,
                     r = tip_diameter / 2 - plug_wall);
    }
