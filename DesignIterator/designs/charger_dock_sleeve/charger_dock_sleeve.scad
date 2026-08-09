// BambuMaker: Charger Dock — Sleeve Fit Tester
//
// Step 1 of a magnetic dock for a MagSafe-style portable battery pack.
// This part is *only* the cradle: a thin open-top sleeve that the bottom of
// the pack drops into, so the cavity dimensions can be verified in a ~20 min
// print before any of the dock body (stand angle, magnet pocket, quick
// disconnect) gets built around it.
//
// Pack dimensions came off a tape measure in inches and were rounded, so
// treat them as approximate: 4" tall x 2 1/2" wide x 1/2" thick
// = 101.6 x 63.5 x 12.7 mm. Only the width and thickness matter here.
//
// Fit clearance defaults to 0.4 mm per side rather than the house slip-fit
// value of 0.25 mm, because the input dimensions are rounded — better to
// print slightly loose and measure the slop than to print unusable.
// Once the real numbers are known, drop fit_clearance to 0.25.
//
// USB-C: the port sits on the bottom edge of the pack, so the slot passes
// straight through the sleeve floor and is centered. If the port turns out
// to be off-center, shift it with port_offset instead of moving geometry.
//
// Printing: floor down on the bed, exactly as it sits on a desk. No
// overhangs anywhere — the thumb notches open upward through the top edge,
// and the USB-C slot is a through hole starting on the build plate.
// Suggested: 3 perimeters, 15% gyroid, PETG (lives next to electronics).
//
// HOW TO READ THE TEST PRINT
//   - Pack won't enter          -> increase fit_clearance
//   - Pack rattles side to side -> decrease fit_clearance
//   - Cable won't seat          -> increase port_slot_width / port_slot_depth
//   - Port not centered in slot -> set port_offset (+X = toward right wall)
//
// @param pack_width 63.5
// @param pack_thickness 12.7
// @param fit_clearance 0.4
// @param sleeve_height 30
// @param wall 1.6
// @param base_thickness 1.6
// @param port_slot_width 16
// @param port_slot_depth 9
// @param port_offset 0
// @param notch_width 26
// @param notch_depth 12
// @param corner_radius 3

pack_width      = 63.5;  // measured 2 1/2" across the flat face
pack_thickness  = 12.7;  // measured 1/2" through the body
fit_clearance   = 0.4;   // per side; tighten to 0.25 once dims are confirmed
sleeve_height   = 30;    // how far up the 101.6 mm pack the sleeve reaches
wall            = 1.6;   // 4 x nozzle — house minimum for a structural wall
base_thickness  = 1.6;   // floor the pack rests on
port_slot_width = 16;    // USB-C slot, across the width of the pack
port_slot_depth = 9;     // USB-C slot, through the thickness of the pack
port_offset     = 0;     // shift slot along X if the port isn't centered
notch_width     = 26;    // thumb notch, front and back, to push the pack out
notch_depth     = 12;    // how far the notch cuts down from the top edge
corner_radius   = 3;     // outer corner radius, roughly matches the pack

$fn = 64;

lead_in = 0.8;  // flare at the mouth so the pack self-centers going in

// ── derived ──────────────────────────────────────────────
cavity_width     = pack_width     + 2 * fit_clearance;
cavity_thickness = pack_thickness + 2 * fit_clearance;
outer_width      = cavity_width     + 2 * wall;
outer_thickness  = cavity_thickness + 2 * wall;
inner_radius     = max(corner_radius - wall, 1.5);

// rounded rectangular prism, centered in X/Y, sitting on z = 0
module rrect(w, d, h, r) {
    hull()
        for (x = [-1, 1], y = [-1, 1])
            translate([x * (w / 2 - r), y * (d / 2 - r), 0])
                cylinder(h = h, r = r);
}

// the pocket the pack drops into, plus the flared mouth at the top
module cavity() {
    translate([0, 0, base_thickness])
        rrect(cavity_width, cavity_thickness, sleeve_height, inner_radius);

    translate([0, 0, sleeve_height - lead_in])
        hull() {
            rrect(cavity_width, cavity_thickness, 0.01, inner_radius);
            translate([0, 0, lead_in])
                rrect(cavity_width     + 2 * lead_in,
                      cavity_thickness + 2 * lead_in,
                      0.01, inner_radius + lead_in);
        }
}

// rounded slot through the floor for the USB-C cable
module port_slot() {
    r    = port_slot_depth / 2;
    span = max(port_slot_width / 2 - r, 0);

    translate([port_offset, 0, -1])
        hull()
            for (x = [-span, span])
                translate([x, 0, 0])
                    cylinder(h = base_thickness + 2, r = r, $fn = 32);
}

// thumb notches in the front and back walls — open at the top, so the
// exposed face points upward and nothing needs to bridge
module thumb_notches() {
    r = notch_width / 2;

    rotate([90, 0, 0])
        linear_extrude(height = outer_thickness + 10, center = true)
            hull() {
                translate([0, sleeve_height - notch_depth + r])
                    circle(r = r);
                translate([-r, sleeve_height])
                    square([notch_width, r + 5]);
            }
}

// ── part ─────────────────────────────────────────────────
difference() {
    rrect(outer_width, outer_thickness, sleeve_height, corner_radius);
    cavity();
    port_slot();
    thumb_notches();
}
