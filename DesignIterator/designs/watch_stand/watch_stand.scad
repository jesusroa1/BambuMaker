// BambuMaker: Gridfinity Watch Display Stand
// A 1x2 Gridfinity bin base with a leaning watch display wedge on top.
// Print in display orientation (feet flat on bed).
// Overhangs exist on the watch-pad chamfers (~45 deg) and are intentional.
//
// @param display_angle 62
// @param backrest_height 55
// @param watch_pad_height 6
// @param watch_pad_depth 12
// @param strap_slot_width 24
// @param strap_channel_width 24
// @param strap_channel_depth 3
// @param top_chamfer 1

// ---------------------------------------------------------------------------
// Tunable parameters
// ---------------------------------------------------------------------------
display_angle        = 62;   // backrest angle from horizontal (deg)
backrest_height      = 55;   // top of wedge above the base floor (mm)
watch_pad_height     = 6;    // height of the watch-resting ledge pads (mm)
watch_pad_depth      = 12;   // how far the pads extend forward from the toe (mm)
strap_slot_width     = 24;   // central gap between the two watch pads (mm)
strap_channel_width  = 24;   // width of the open groove up the backrest (mm)
strap_channel_depth  = 3;    // depth of that groove (mm)
top_chamfer          = 1;    // chamfer on the sharp back-top ridge (mm)

// --- Gridfinity (fit-critical, "Zack" profile) ---
grid        = 42;    // standard cell pitch (mm)
cells_x     = 1;
cells_y     = 2;
clearance   = 0.25;  // per-side inset from the grid -> drop-in fit
body_r      = 3.75;  // outer corner radius

foot_ch1    = 0.8;   // bottom 45 deg chamfer height
foot_vert   = 1.8;   // vertical mid section height
foot_ch2    = 2.15;  // top 45 deg chamfer height
floor_thick = 1.2;   // solid floor tying the feet together

$fn = 64;

// ---------------------------------------------------------------------------
// Derived values
// ---------------------------------------------------------------------------
eps = 0.01;
BIG = 400;

body_x = cells_x * grid - 2 * clearance;   // 41.5
body_y = cells_y * grid - 2 * clearance;   // 83.5
cell   = grid - 2 * clearance;             // 41.5

foot_h   = foot_ch1 + foot_vert + foot_ch2; // 4.75
base_top = foot_h + floor_thick;            // 5.95 (top of base floor)

// foot cross-section sizes / corner radii at each level
foot_top   = cell;
foot_mid   = cell - 2 * foot_ch2;
foot_bot   = foot_mid - 2 * foot_ch1;
foot_top_r = body_r;
foot_mid_r = body_r - foot_ch2;
foot_bot_r = foot_mid_r - foot_ch1;

// wedge geometry (z measured from the base floor top)
back_y   = body_y / 2;
run      = backrest_height / tan(display_angle);
toe_y    = back_y - run;        // front-bottom of the backrest slope
ramp_len = backrest_height / sin(display_angle);

// watch-pad X extents (flanking the central strap gap)
pad_x_inner = strap_slot_width / 2;
pad_x_outer = body_x / 2 - 1;  // 1 mm margin from side walls

// pad overlap into the wedge/floor for solid fusion
pad_overlap = 2;
pad_sink    = 1;

// ---------------------------------------------------------------------------
// 2D helpers
// ---------------------------------------------------------------------------
module rounded_square(size, r) {
    offset(r = r) square([size - 2 * r, size - 2 * r], center = true);
}

module rounded_rect(sx, sy, r) {
    offset(r = r) square([sx - 2 * r, sy - 2 * r], center = true);
}

// ---------------------------------------------------------------------------
// Gridfinity foot — swept rounded square keeps corners filleted at every level
// ---------------------------------------------------------------------------
module foot() {
    // 1. bottom 45 deg chamfer
    hull() {
        linear_extrude(eps) rounded_square(foot_bot, foot_bot_r);
        translate([0, 0, foot_ch1])
            linear_extrude(eps) rounded_square(foot_mid, foot_mid_r);
    }
    // 2. vertical mid section
    translate([0, 0, foot_ch1])
        linear_extrude(foot_vert + eps) rounded_square(foot_mid, foot_mid_r);
    // 3. top 45 deg chamfer up to full body cross-section
    translate([0, 0, foot_ch1 + foot_vert])
        hull() {
            linear_extrude(eps) rounded_square(foot_mid, foot_mid_r);
            translate([0, 0, foot_ch2])
                linear_extrude(eps) rounded_square(foot_top, foot_top_r);
        }
}

module base() {
    for (i = [0 : cells_x - 1], j = [0 : cells_y - 1])
        translate([(i + 0.5) * grid - cells_x * grid / 2,
                   (j + 0.5) * grid - cells_y * grid / 2, 0])
            foot();

    translate([0, 0, foot_h - eps])
        linear_extrude(floor_thick + eps)
            rounded_rect(body_x, body_y, body_r);
}

// ---------------------------------------------------------------------------
// Display wedge
// ---------------------------------------------------------------------------
module wedge_solid() {
    intersection() {
        translate([0, 0, -eps])
            linear_extrude(backrest_height + 5)
                rounded_rect(body_x, body_y, body_r);

        translate([0, toe_y, 0])
            rotate([display_angle, 0, 0])
                translate([0, 0, -BIG / 2])
                    cube([body_x + 20, BIG, BIG], center = true);
    }
}

// Open-topped strap groove along the backrest centerline.
module groove_cutter() {
    translate([0, toe_y, 0])
        rotate([display_angle, 0, 0])
            translate([-strap_channel_width / 2, -3, -strap_channel_depth])
                cube([strap_channel_width, ramp_len + 3, strap_channel_depth + 20]);
}

// 45 deg chamfer along the back-top ridge.
module back_ridge_chamfer() {
    translate([0, back_y, backrest_height])
        rotate([45, 0, 0])
            cube([body_x + 2, top_chamfer * sqrt(2), top_chamfer * sqrt(2)],
                 center = true);
}

// ---------------------------------------------------------------------------
// Watch resting pad — one per side of the strap gap.
//
// Cross-section in the Y–Z plane (local coords, origin at base_top):
//   back face:   vertical at y = toe_y + pad_overlap (overlaps wedge to fuse)
//   top surface: flat at z = watch_pad_height (watch case bottom edge rests here)
//   front face:  45 deg chamfer from the top-front corner down to the floor
//   bottom:      flat at z = -pad_sink (overlaps floor to fuse)
//
// The 45 deg front chamfer eliminates any downward-facing overhang steeper
// than 45 deg, so no support material is needed.
// ---------------------------------------------------------------------------
module watch_pad(x0, x1) {
    h  = watch_pad_height;
    d  = watch_pad_depth;
    ov = pad_overlap;
    sk = pad_sink;

    // Y coords
    y_back  = toe_y + ov;
    y_front = toe_y - d;

    // 45 deg chamfer: top-front corner (y_front, h) drops to floor at
    // (y_front + h, 0).  Requires d >= h to have a flat floor ahead of it.
    y_chamfer_base = toe_y - d + h;

    // Extrude the profile along X using multmatrix to swap axes cleanly.
    translate([x0, 0, 0])
        multmatrix([[0, 0, 1, 0],
                    [1, 0, 0, 0],
                    [0, 1, 0, 0],
                    [0, 0, 0, 1]])
            linear_extrude(x1 - x0)
                polygon([
                    [y_back,         -sk],   // back-bottom
                    [y_back,          h ],   // back-top
                    [y_front,         h ],   // front-top
                    [y_chamfer_base, -sk]    // front-bottom (45 deg chamfer)
                ]);
}

// ---------------------------------------------------------------------------
// Full assembly
// ---------------------------------------------------------------------------
module stand() {
    union() {
        base();

        translate([0, 0, base_top]) {
            difference() {
                wedge_solid();
                groove_cutter();
                back_ridge_chamfer();
            }
            watch_pad(-pad_x_outer, -pad_x_inner);
            watch_pad( pad_x_inner,  pad_x_outer);
        }
    }
}

stand();
