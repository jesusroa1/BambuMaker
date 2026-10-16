// "The Roas" wedding cake topper (v2) — single-color script lettering.
// Traced from the second mock-up photo (crossed "Th", looped "R" leg running
// into the stake). Strokes were grown by ~0.5 mm so the hairlines come out
// around 1.5 mm at the default width and survive printing and handling.
//
// Prints flat on the bed (both faces are flat). "The", "Roas", the swashes
// and the stake form one connected piece, so there are no loose islands.
// No supports required.
//
// SIZE FLAG: ~140 mm wide x ~168 mm tall at the default settings (lettering
// ~123 mm tall + 45 mm stake). Fits inside the A1 Mini's 170 mm safety
// margin, but it fills most of the bed. This artwork is taller than the v1
// topper, so keep topper_width + stake_length in check: total height is
// ~0.876 * topper_width + stake_length.
//
// Suggested: PLA (black, gold or silk), 0.2 mm layers, 3 walls, 100% infill
// (it's thin, so this is effectively solid). Wrap the stake in food-safe
// film or a straw before inserting it into the cake.
//
// @param topper_width 140
// @param thickness 3
// @param stake_length 45
// @param stake_width 5

topper_width = 140;   // overall width of the lettering, mm
thickness    = 3;     // plate thickness, mm
stake_length = 45;    // how far the stake extends below the lettering, mm
stake_width  = 5;     // stake width where it goes into the cake, mm

// --- Traced artwork geometry (SVG units; 1 unit = 1 mm before scaling) ---
art_x_min  = 191;     // left edge of the lettering
art_x_max  = 3041;    // right edge of the lettering
art_y_cut  = 0;       // bottom of the traced stake stub
stake_x    = 1340.5;  // centre line of the traced stake stub
stub_width = 4.6;     // traced stub width after scaling, mm

art_scale = topper_width / (art_x_max - art_x_min);

stake_cx      = (stake_x - (art_x_min + art_x_max) / 2) * art_scale;
stake_overlap = 8;    // how far the stake reaches up into the traced stub
flare_length  = 6;    // stub width -> stake width transition
tip_length    = 8;    // pointed tip for easy insertion

module lettering() {
    scale([art_scale, art_scale])
        translate([-(art_x_min + art_x_max) / 2, -art_y_cut])
            import("topper_lettering.svg");
}

module stake() {
    translate([stake_cx, 0])
        polygon([
            [-stub_width / 2,  stake_overlap],
            [ stub_width / 2,  stake_overlap],
            [ stake_width / 2, -flare_length],
            [ stake_width / 2, -(stake_length - tip_length)],
            [ 0,               -stake_length],
            [-stake_width / 2, -(stake_length - tip_length)],
            [-stake_width / 2, -flare_length],
        ]);
}

linear_extrude(height = thickness)
    union() {
        lettering();
        stake();
    }
