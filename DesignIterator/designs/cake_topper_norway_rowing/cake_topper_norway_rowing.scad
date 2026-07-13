// Norway soccer-fan rowing cake topper — traced directly from the reference
// illustration (blonde rower in a Norwegian-flag jersey pulling a red/white
// oar, mounted on a cake stake), so the print looks like the artwork instead
// of a simplified silhouette.
//
// Prints flat on the bed as a layered relief for clean multi-color on the
// Bambu A1 mini. Heights by layer (assign filaments in Bambu Studio, or use
// the AMS lite and paint each raised region — every color sits on its own
// body so painting snaps cleanly to it):
//   0.0 mm - 1.6 mm : WHITE  (backing plate, sticker border, stake,
//                             flag whites, sock + oar white stripes)
//   1.6 mm - 2.4 mm : SKIN / RED / NAVY / BLONDE fills (disjoint in XY)
//   1.6 mm - 2.8 mm : BLACK  (outlines, hair + face linework) — proudest so
//                             the linework reads crisply.
// The colored fill masks never overlap each other or the black linework in
// XY (each source pixel was assigned to exactly one color), so stacking them
// on the shared white base creates no hidden overhangs.
//
// SIZE: 156.75 mm square canvas → figure ~106 x 150 mm including the stake.
// Inside the 170 mm A1-mini safety margin, and under 150 mm on the short
// axis, so no size flag is needed. No supports: every layer only shrinks
// inward, and the stake/oar/limbs are tied to the figure by the white
// sticker-style border the way acrylic toppers do it.
//
// Multi-color export: each @part line below names a single-color body and
// its filament color. CI compiles each with -D part="<name>" and packages
// them into <design>.3mf, where Bambu Studio lets you assign one filament
// per part. The plain STL (part = "all") stays single-body for the viewer.
//
// @part base   #FFFFFF
// @part skin   #F0C078
// @part red    #C8102E
// @part navy   #002868
// @part blonde #F0B323
// @part black  #1A1A1A

// @param base_thickness 1.6
// @param color_relief 0.8
// @param black_relief 1.2
// @param scale_factor 1.0

base_thickness = 1.6;   // white backing + sticker border + stake
color_relief   = 0.8;   // skin/red/navy/blonde raised above the base
black_relief   = 1.2;   // black raised above the base, proudest for crisp line
scale_factor   = 1.0;   // uniform XY resize of the whole topper

part = "all";           // "all" | "base" | "skin" | "red" | "navy" | "blonde" | "black"

// SVG canvas size in mm (OpenSCAD imports the 156.75 mm potrace canvas). All
// six SVGs were traced from the same canvas, so importing them un-centered
// keeps the layers perfectly registered.
canvas_w = 156.75;
canvas_h = 156.75;

module fill_layer(name)
    translate([0, 0, base_thickness])
        linear_extrude(height = color_relief)
            import(name);

scale([scale_factor, scale_factor, 1])
translate([-canvas_w / 2, -canvas_h / 2, 0]) {

    // white base: full silhouette + sticker border + cake stake
    if (part == "all" || part == "base")
        linear_extrude(height = base_thickness)
            import("topper_base.svg");

    // colored fills — all rise to the same plateau, disjoint in XY
    if (part == "all" || part == "skin")   fill_layer("topper_skin.svg");
    if (part == "all" || part == "red")    fill_layer("topper_red.svg");
    if (part == "all" || part == "navy")   fill_layer("topper_navy.svg");
    if (part == "all" || part == "blonde") fill_layer("topper_blonde.svg");

    // black linework sits proudest so it reads crisply
    if (part == "all" || part == "black")
        translate([0, 0, base_thickness])
            linear_extrude(height = black_relief)
                import("topper_black.svg");
}
