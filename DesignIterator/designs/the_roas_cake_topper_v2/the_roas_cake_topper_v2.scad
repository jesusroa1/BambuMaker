// "The Roas" wedding cake topper (v2) — single-color script lettering.
// Traced from the second mock-up photo (crossed "Th", looped "R" leg running
// into the stake). Strokes were grown by ~0.5 mm so the hairlines come out
// around 1.5 mm at the default width and survive printing and handling.
//
// Prints flat on the bed (both faces are flat). "The", "Roas", the swashes
// and the stake form one connected piece, so there are no loose islands.
// No supports required.
//
// SIZE FLAG: ~140 mm wide x ~223 mm tall at the default settings (lettering
// ~123 mm tall + 100 mm stake). That is too tall to lie straight on the
// A1 Mini's 180 mm bed, so the model is rotated by print_angle (42 degrees)
// to sit diagonally: the exported STL is ~170 x 170 mm and prints as-is.
// 100 mm is the longest stake that keeps that inside the 170 mm safety
// margin. Set print_angle = 0 for an upright view.
//
// The stake is widened to 7 mm so the long stake stays stiff. Check the
// cake tier is taller than ~100 mm, or shorten stake_length to suit.
//
// Suggested: PLA (black, gold or silk), 0.2 mm layers, 3 walls, 100% infill
// (it's thin, so this is effectively solid). Wrap the stake in food-safe
// film or a straw before inserting it into the cake.
//
// @param topper_width 140
// @param thickness 3
// @param stake_length 100
// @param stake_width 7
// @param print_angle 42

topper_width = 140;   // overall width of the lettering, mm
thickness    = 3;     // plate thickness, mm
stake_length = 100;   // how far the stake extends below the lettering, mm
stake_width  = 7;     // stake width where it goes into the cake, mm
print_angle  = 42;    // rotation on the bed so the long piece fits diagonally, degrees

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

rotate([0, 0, print_angle])
    linear_extrude(height = thickness)
        union() {
            lettering();
            stake();
        }
