// Soccer whiff-kick cake topper — traced directly from the reference
// illustration (yellow #22 jersey, ball, splash and motion marks), so the
// print looks like the artwork instead of a simplified silhouette.
//
// Prints flat on the bed as a layered relief for clean multi-color on the
// Bambu A1 mini. Colors by height (add filament changes in Bambu Studio):
//   0.0 mm - 1.6 mm : WHITE  (backing plate, stake, gloves, shoes, face)
//   1.6 mm - 2.2 mm : YELLOW (jersey, shorts, socks, accents)
//   2.2 mm - 2.8 mm : BLACK  (linework, hair, ball pattern, the "22")
// With an AMS lite you can instead paint the raised regions in the slicer —
// each color sits on its own plateau, so painting snaps cleanly to them.
//
// Art is ~130 mm wide x ~165 mm tall including the stake — fits the
// A1 mini's 180x180 bed. No supports needed: every layer shrinks inward.
// Floating pieces (ball, motion marks, splash) are tied to the figure by
// the white sticker-style border, the way acrylic toppers do it.

// @param base_thickness 1.6
// @param yellow_relief 0.6
// @param black_relief 1.2
// @param scale_factor 1.0

base_thickness = 1.6;   // white backing + stake
yellow_relief  = 0.6;   // yellow raised above the base
black_relief   = 1.2;   // black raised above the base (hides the yellow band)
scale_factor   = 1.0;   // uniform XY resize of the whole topper

// SVG canvas size in mm. All three SVGs were traced from the same canvas,
// so importing them un-centered keeps the layers perfectly registered.
canvas_w = 157.97;
canvas_h = 169.81;

scale([scale_factor, scale_factor, 1])
translate([-canvas_w / 2, -canvas_h / 2, 0]) {

    // white base: full silhouette + sticker border + cake stake
    linear_extrude(height = base_thickness)
        import("topper_base.svg");

    // yellow fills
    translate([0, 0, base_thickness])
        linear_extrude(height = yellow_relief)
            import("topper_yellow.svg");

    // black linework sits proudest so it reads crisply
    translate([0, 0, base_thickness])
        linear_extrude(height = black_relief)
            import("topper_black.svg");
}
