// "The Roas" wedding cake topper — single-color script lettering.
// Traced from the supplied mock-up photo; hairline strokes were thickened to
// roughly 1.5 mm so the swashes survive printing and handling.
//
// Prints flat on the bed (lettering face down or up — both faces are flat).
// "The", "Roas", the swashes and the stake form one connected piece, so
// there are no loose islands. No supports required.
//
// SIZE FLAG: ~150 mm wide x ~152 mm tall at the default settings (lettering
// ~97 mm tall + stake). Fits inside the A1 Mini's 170 mm safety margin, but
// it fills most of the bed — skip the purge tower / prime line clutter.
//
// Suggested: PLA (black, gold or silk), 0.2 mm layers, 3 walls, 100% infill
// (it's thin, so this is effectively solid). Wrap the stake in food-safe
// film or a straw before inserting it into the cake.
//
// @param topper_width 150
// @param thickness 3
// @param stake_length 55
// @param stake_width 5

topper_width = 150;   // overall width of the lettering, mm
thickness    = 3;     // plate thickness, mm
stake_length = 55;    // how far the stake extends below the lettering, mm
stake_width  = 5;     // stake width where it goes into the cake, mm

// --- Traced artwork geometry (SVG units; 1 unit = 1 mm before scaling) ---
art_x_min  = 57;      // left edge of the lettering
art_x_max  = 2705;    // right edge of the lettering
art_y_cut  = 82;      // bottom of the traced stake stub
stake_x    = 1212.5;  // centre line of the traced stake stub
stub_width = 2.3;     // traced stub width after scaling, mm

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
