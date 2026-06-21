// BambuMaker: Gridfinity Watch Display Stand (post style)
// Watch drapes over the rounded head — like a wrist stand pillar.
// Print upright with Gridfinity feet flat on the bed. No supports needed.
// Overhangs on the neck-to-head flare are intentional (~41 deg, within limits).
//
// @param base_thick 14
// @param neck_width 22
// @param neck_depth 16
// @param neck_height 55
// @param head_width 36
// @param head_depth 22
// @param head_body_height 8
// @param head_dome_height 12

// ---------------------------------------------------------------------------
// Tunable parameters
// ---------------------------------------------------------------------------
base_thick       = 14;  // height of the wide base platform above the Gridfinity floor
neck_width       = 22;  // neck cross-section width  (X, mm)
neck_depth       = 16;  // neck cross-section depth  (Y, mm)
neck_height      = 55;  // straight neck height above the base platform (mm)
head_width       = 36;  // head width across the watch case (X, mm)
head_depth       = 22;  // head front-to-back depth (Y, mm)
head_body_height =  8;  // straight cylindrical portion of the head (mm)
head_dome_height = 12;  // dome that tapers to a rounded top (mm)

// --- Gridfinity (fit-critical, "Zack" profile) ---
grid        = 42;
cells_x     = 1;
cells_y     = 2;
clearance   = 0.25;
body_r      = 3.75;

foot_ch1    = 0.8;
foot_vert   = 1.8;
foot_ch2    = 2.15;
floor_thick = 1.2;

$fn = 64;

// ---------------------------------------------------------------------------
// Derived values
// ---------------------------------------------------------------------------
eps = 0.01;

body_x = cells_x * grid - 2 * clearance;   // 41.5
body_y = cells_y * grid - 2 * clearance;   // 83.5
cell   = grid - 2 * clearance;

foot_h   = foot_ch1 + foot_vert + foot_ch2; // 4.75
base_top = foot_h + floor_thick;            // 5.95

foot_top   = cell;
foot_mid   = cell - 2 * foot_ch2;
foot_bot   = foot_mid - 2 * foot_ch1;
foot_top_r = body_r;
foot_mid_r = body_r - foot_ch2;
foot_bot_r = foot_mid_r - foot_ch1;

neck_r = 5;
// Head corner radius: ~35 % of the shorter head dimension gives a pill-like oval
head_r = min(head_width, head_depth) * 0.35;

// Flare zone — neck expands to head size.
// For ≤45° overhang on the outer face: flare height ≥ max per-side expansion.
// X expansion = (36-22)/2 = 7 mm; Y expansion = (22-16)/2 = 3 mm.
// We set flare = 8 mm → outer face angle ≈ arctan(7/8) = 41° from horizontal. ✓
flare_height = max((head_width - neck_width) / 2,
                   (head_depth - neck_depth) / 2) + 1;

// ---------------------------------------------------------------------------
// 2D helpers
// ---------------------------------------------------------------------------
module rounded_square(size, r) {
    offset(r = r) square([size - 2*r, size - 2*r], center = true);
}

module rounded_rect(sx, sy, r) {
    offset(r = r) square([sx - 2*r, sy - 2*r], center = true);
}

// ---------------------------------------------------------------------------
// Gridfinity foot (one per cell)
// ---------------------------------------------------------------------------
module foot() {
    hull() {
        linear_extrude(eps) rounded_square(foot_bot, foot_bot_r);
        translate([0, 0, foot_ch1])
            linear_extrude(eps) rounded_square(foot_mid, foot_mid_r);
    }
    translate([0, 0, foot_ch1])
        linear_extrude(foot_vert + eps) rounded_square(foot_mid, foot_mid_r);
    translate([0, 0, foot_ch1 + foot_vert])
        hull() {
            linear_extrude(eps) rounded_square(foot_mid, foot_mid_r);
            translate([0, 0, foot_ch2])
                linear_extrude(eps) rounded_square(foot_top, foot_top_r);
        }
}

module base() {
    for (i = [0:cells_x-1], j = [0:cells_y-1])
        translate([(i+0.5)*grid - cells_x*grid/2,
                   (j+0.5)*grid - cells_y*grid/2, 0])
            foot();
    translate([0, 0, foot_h - eps])
        linear_extrude(floor_thick + eps)
            rounded_rect(body_x, body_y, body_r);
}

// ---------------------------------------------------------------------------
// Post + head (z = 0 at base platform top)
// ---------------------------------------------------------------------------
module neck_profile() { rounded_rect(neck_width, neck_depth, neck_r); }
module head_profile() { rounded_rect(head_width, head_depth, head_r); }

module watch_post() {
    // Wide base platform — starts eps below base_top to fuse with Gridfinity floor
    translate([0, 0, -eps])
        linear_extrude(base_thick + eps) rounded_rect(body_x, body_y, body_r);

    translate([0, 0, base_thick]) {
        // Straight neck column
        linear_extrude(neck_height) neck_profile();

        // Flare: neck → head cross-section (≤45° overhang)
        translate([0, 0, neck_height])
            hull() {
                linear_extrude(eps) neck_profile();
                translate([0, 0, flare_height])
                    linear_extrude(eps) head_profile();
            }

        // Straight head body
        translate([0, 0, neck_height + flare_height])
            linear_extrude(head_body_height) head_profile();

        // Dome: head profile tapers to a small circle at the top.
        // The dome surface faces outward-and-upward — no downward overhang. ✓
        translate([0, 0, neck_height + flare_height + head_body_height])
            hull() {
                linear_extrude(eps) head_profile();
                translate([0, 0, head_dome_height])
                    linear_extrude(eps) circle(r = 2);
            }
    }
}

// ---------------------------------------------------------------------------
// Assembly
// ---------------------------------------------------------------------------
module stand() {
    union() {
        base();
        translate([0, 0, base_top])
            watch_post();
    }
}

stand();
