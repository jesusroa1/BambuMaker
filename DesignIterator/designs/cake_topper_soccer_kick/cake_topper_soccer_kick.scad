// BambuMaker: "Whiffed Kick" Soccer Cake Topper
// Comic-style back-view soccer player caught mid-whiff, plus a matching
// soccer ball — flat silhouette picks, the way store-bought acrylic cake
// toppers are made. Two independent parts share one bed layout: the
// player (left) and the ball (right), each with its own integrated stake
// for pushing into a cake.
//
// Print orientation: lay flat, large face down on the bed. Both parts are
// a single uniform-thickness 2D extrusion (no taper, no relief), so every
// printed layer has the same footprint — zero overhangs, zero supports,
// regardless of how wild the pose looks.
//
// This is a single-material silhouette rendition: fine line detail from
// source art (jersey number, cleat logo, ball seams, motion lines) can't
// survive a single-filament FDM print at this scale, so it's simplified
// to a bold, chunky outline. Paint or add a vinyl decal afterward if you
// want that detail back.
//
// Default footprint lands right around 148 x 150 mm — comfortably inside
// the 170 mm safety margin, but close enough to the 150 mm flag threshold
// to call out explicitly (per design principles).
//
// @param figure_height_mm 150
// @param plate_thickness 3
// @param ball_diameter_mm 30
// @param ball_stake_len_mm 40
// @param ball_stake_width_mm 10
// @param gap_mm 18

figure_height_mm    = 150;  // player pick height: hair tips to stake tip (mm)
plate_thickness     = 3;    // uniform slab thickness (mm) - prints flat, no supports
ball_diameter_mm    = 30;   // soccer ball pick diameter (mm)
ball_stake_len_mm   = 40;   // ball pick's own stake length (mm)
ball_stake_width_mm = 10;   // ball pick's stake width where it meets the ball (mm)
gap_mm              = 18;   // clearance between the two picks on the bed (mm)

$fn = 48;

// ---------------------------------------------------------------------------
// 2D helpers
// ---------------------------------------------------------------------------
module limb(p1, r1, p2, r2) {
    hull() {
        translate(p1) circle(r = r1);
        translate(p2) circle(r = r2);
    }
}

module spike(base, r_base, tip, r_tip) {
    hull() {
        translate(base) circle(r = r_base);
        translate(tip) circle(r = r_tip);
    }
}

// ---------------------------------------------------------------------------
// Player silhouette, drawn in fixed "design units" then uniformly scaled to
// figure_height_mm so the whole pose stays proportional as it's resized.
// ---------------------------------------------------------------------------
module player_design() {
    // Named joints (design units) — everything else derives from these.
    head_c     = [2, 200];    head_r      = 22;
    shoulder_L = [-18, 178];  shoulder_r  = 15;
    shoulder_R = [20, 182];
    elbow_L    = [-55, 166];  elbow_r     = 11;
    hand_L     = [-92, 182];  hand_r      = 13;
    elbow_R    = [60, 158];
    hand_R     = [96, 140];
    hip        = [8, 110];    hip_r       = 20;
    knee_R     = [20, 58];    knee_r      = 15;   // planted (standing) leg
    ankle_R    = [24, 18];    ankle_r     = 12;
    foot_R     = [30, 10];    foot_rx     = 20;  foot_ry = 10;
    knee_L     = [-30, 66];                        // kicking (whiffed) leg
    ankle_L    = [-66, 26];
    foot_L     = [-78, 10];   stake_top_w = 22;   // design units (~10 mm @ default scale)
    stake_tip  = foot_L + [0, -110];

    union() {
        // torso
        hull() {
            translate(shoulder_L) circle(r = shoulder_r);
            translate(shoulder_R) circle(r = shoulder_r);
            translate(hip)        circle(r = hip_r);
        }

        // head
        translate(head_c) circle(r = head_r);

        // spiky hair fanned around the crown
        for (a = [-70, -42, -16, 12, 40, 66])
            spike(head_c + head_r * 0.75 * [sin(a), cos(a)], 6.5,
                  head_c + (head_r + 26) * [sin(a), cos(a)], 2.5);

        // arms spread wide for balance
        limb(shoulder_L, shoulder_r, elbow_L, elbow_r);
        limb(elbow_L, elbow_r, hand_L, hand_r);
        limb(shoulder_R, shoulder_r, elbow_R, elbow_r);
        limb(elbow_R, elbow_r, hand_R, hand_r);

        // planted leg (standing, weight-bearing)
        limb(hip, hip_r, knee_R, knee_r);
        limb(knee_R, knee_r, ankle_R, ankle_r);
        translate(foot_R) scale([foot_rx / 10, foot_ry / 10]) circle(r = 10);

        // kicking leg, swung through empty air past where the ball was
        limb(hip, hip_r, knee_L, knee_r);
        limb(knee_L, knee_r, ankle_L, ankle_r);
        translate(foot_L) scale([foot_rx / 10, foot_ry / 10]) circle(r = 10);

        // little "whiff" impact burst at the kicking foot
        for (a = [200, 245, 290, 335])
            spike(foot_L + 12 * [cos(a), sin(a)], 5,
                  foot_L + 30 * [cos(a), sin(a)], 2.5);

        // comic motion marks above the head
        spike(head_c + [34, 18], 4, head_c + [40, 42], 2.5);
        spike(head_c + [44, 12], 4, head_c + [52, 34], 2.5);

        // integrated stake, rooted at the whiffed foot
        translate(foot_L)
            polygon([[-stake_top_w / 2, 0], [stake_top_w / 2, 0],
                     stake_tip - foot_L]);
    }
}

// Measured span of player_design(): tallest hair spike (~249.4) down to
// stake tip (-100) — verified against the exported mesh's bounding box.
design_span  = 349.4;
player_scale = figure_height_mm / design_span;

module player_pick() {
    linear_extrude(plate_thickness)
        scale([player_scale, player_scale])
            player_design();
}

// ---------------------------------------------------------------------------
// Ball pick — plain silhouette disc (seams simplified to a few chunky hint
// marks; true stitch lines are too fine to survive at this scale) plus its
// own small stake.
// ---------------------------------------------------------------------------
module ball_pick() {
    r = ball_diameter_mm / 2;
    linear_extrude(plate_thickness)
        union() {
            circle(r = r);
            for (a = [30, 150, 270])
                translate(r * 0.45 * [cos(a), sin(a)]) circle(r = r * 0.18);
            polygon([[-ball_stake_width_mm / 2, -r + 1],
                     [ ball_stake_width_mm / 2, -r + 1],
                     [0, -r - ball_stake_len_mm]]);
        }
}

// ---------------------------------------------------------------------------
// Bed layout — two separate picks, each flat and self-supporting.
// ---------------------------------------------------------------------------
player_right_extent = 109;  // design-unit x of the player's far hand + radius

player_pick();

translate([player_right_extent * player_scale + gap_mm + ball_diameter_mm / 2, 40, 0])
    ball_pick();
