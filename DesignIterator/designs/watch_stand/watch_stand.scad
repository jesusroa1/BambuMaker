// BambuMaker: Gridfinity Watch Display Stand
// A 1x2 Gridfinity bin base with a leaning watch display wedge on top.
// Print in display orientation (feet flat on bed), no supports.
//
// @param display_angle 62
// @param backrest_height 55
// @param strap_slot_width 24
// @param strap_channel_width 24
// @param strap_channel_depth 3
// @param nub_height 5
// @param top_chamfer 1

// ---------------------------------------------------------------------------
// Tunable parameters
// ---------------------------------------------------------------------------
display_angle        = 62;   // backrest angle from horizontal (deg)
backrest_height      = 55;   // top of wedge above the base floor (mm)
strap_slot_width     = 24;   // gap between the two toe nubs (mm)
strap_channel_width  = 24;   // width of the open groove up the backrest (mm)
strap_channel_depth  = 3;    // depth of that groove (mm)
nub_height           = 5;    // height of the toe-stop nubs (mm)
top_chamfer          = 1;    // chamfer on the sharp back-top ridge (mm)

// --- Gridfinity (fit-critical, "Zack" profile) ---
grid       = 42;    // standard cell pitch (mm)
cells_x    = 1;
cells_y    = 2;
clearance  = 0.25;  // per-side inset from the grid -> drop-in fit
body_r     = 3.75;  // outer corner radius

foot_ch1   = 0.8;   // bottom 45 deg chamfer height
foot_vert  = 1.8;   // vertical mid section height
foot_ch2   = 2.15;  // top 45 deg chamfer height
floor_thick = 1.2;  // solid floor tying the feet together

$fn = 64;

// ---------------------------------------------------------------------------
// Derived values
// ---------------------------------------------------------------------------
eps    = 0.01;
BIG    = 400;

body_x = cells_x * grid - 2 * clearance;   // 41.5
body_y = cells_y * grid - 2 * clearance;   // 83.5
cell   = grid - 2 * clearance;             // 41.5

foot_h   = foot_ch1 + foot_vert + foot_ch2; // 4.75
base_top = foot_h + floor_thick;            // 5.95 (top of base floor)

// foot cross-section sizes / corner radii at each level
foot_top   = cell;                 // 41.5
foot_mid   = cell - 2 * foot_ch2;  // 37.2
foot_bot   = foot_mid - 2 * foot_ch1; // 35.6
foot_top_r = body_r;               // 3.75
foot_mid_r = body_r - foot_ch2;    // 1.6
foot_bot_r = foot_mid_r - foot_ch1; // 0.8

// wedge geometry (z measured from the base floor top)
back_y   = body_y / 2;                       // back vertical face position
run      = backrest_height / tan(display_angle);
toe_y    = back_y - run;                      // toe (front-bottom of backrest)
ramp_len = backrest_height / sin(display_angle);

// toe nub footprint in X (flanking the central strap gap)
nub_x_inner = strap_slot_width / 2;
nub_x_outer = body_x / 2 - 1;     // 1mm margin from the side
nub_front   = nub_height;         // 45 deg front face

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
// Gridfinity foot (one per cell) — swept rounded square keeps corners filleted
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
    // one foot centered in each 42mm cell
    for (i = [0 : cells_x - 1], j = [0 : cells_y - 1])
        translate([(i + 0.5) * grid - cells_x * grid / 2,
                   (j + 0.5) * grid - cells_y * grid / 2, 0])
            foot();

    // solid floor spanning the whole body, tying the feet together
    translate([0, 0, foot_h - eps])
        linear_extrude(floor_thick + eps)
            rounded_rect(body_x, body_y, body_r);
}

// ---------------------------------------------------------------------------
// Display wedge (built with z = 0 at the base floor top)
// ---------------------------------------------------------------------------
// Solid right-triangle wedge: vertical back face, flat bottom, sloped backrest,
// clipped to the rounded base footprint so it never overhangs the base.
module wedge_solid() {
    intersection() {
        translate([0, 0, -eps])
            linear_extrude(backrest_height + 5)
                rounded_rect(body_x, body_y, body_r);

        // keep everything below the backrest plane (slope through the toe line)
        translate([0, toe_y, 0])
            rotate([display_angle, 0, 0])
                translate([0, 0, -BIG / 2])
                    cube([body_x + 20, BIG, BIG], center = true);
    }
}

// Open-topped strap groove cut along the backrest centerline, aligned with the
// toe gap. Worked in the ramp's local frame: lz = 0 is the backrest surface,
// +ly runs up the slope. Cutting only the top few mm keeps it an open groove.
module groove_cutter() {
    translate([0, toe_y, 0])
        rotate([display_angle, 0, 0])
            translate([-strap_channel_width / 2, -3, -strap_channel_depth])
                cube([strap_channel_width, ramp_len + 3,
                      strap_channel_depth + 20]);
}

// 45 deg chamfer along the sharp back-top ridge.
module back_ridge_chamfer() {
    translate([0, back_y, backrest_height])
        rotate([45, 0, 0])
            cube([body_x + 2, top_chamfer * sqrt(2), top_chamfer * sqrt(2)],
                 center = true);
}

// One triangular toe nub spanning x = [x0, x1]. Vertical catch face toward the
// watch (+Y), shallow ramp on the front (-Y), flat underside. The back/bottom
// overlap the wedge and floor so the nub fuses into one solid body.
nub_overlap = 2;   // penetration back into the wedge (fusion)
nub_sink    = 1;   // penetration down into the floor (fusion)
module nub(x0, x1) {
    // multmatrix maps the (Y,Z) profile, extruded along its local Z, onto X.
    translate([x0, 0, 0])
        multmatrix([[0, 0, 1, 0],
                    [1, 0, 0, 0],
                    [0, 1, 0, 0],
                    [0, 0, 0, 1]])
            linear_extrude(x1 - x0)
                polygon([[toe_y + nub_overlap, -nub_sink],
                         [toe_y + nub_overlap, nub_height],
                         [toe_y - nub_front,   -nub_sink]]);
}

module stand() {
    union() {
        base();

        translate([0, 0, base_top]) {
            difference() {
                wedge_solid();
                groove_cutter();
                back_ridge_chamfer();
            }
            nub(-nub_x_outer, -nub_x_inner);
            nub( nub_x_inner,  nub_x_outer);
        }
    }
}

stand();
