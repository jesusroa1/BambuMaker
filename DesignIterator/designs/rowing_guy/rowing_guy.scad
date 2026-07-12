// BambuMaker: Rowing Guy — a small seated sculling figure.
// A stylized chibi rower (Norway-style red jersey + blonde top-knot, traced
// from the reference render) built entirely from spheres/capsules so it slices
// cleanly on the A1 mini. He sits sculling with two oars whose blades rest on
// the bed.
//
// PRINT ORIENTATION: as modeled. Five points touch the bed — the butt, both
// shoes, and both oar blades — a stable stance that needs NO supports.
//
// OVERHANGS (intentional, per DESIGN_PRINCIPLES "genuine functional purpose"
// exception): the arms and oar shafts are thin diagonal struts that hang in
// air, but each one slopes DOWN to a bed contact (shoulder -> hand -> oar ->
// blade). The slicer grows them upward from the blade with only a small
// per-layer overhang, so they print unsupported. Below ~0.9 scale they get
// fragile — keep scale_factor >= 0.9 for a robust print.
//
// SIZE: bounding box is roughly 68 (X) x 44 (Y) x 56 (Z) mm at scale 1.0, so
// the footprint is ~2600 mm^2 — about 1/12 of the A1 mini's 180 x 180 mm plate
// (the requested "~1/10th"), and every axis is far inside the 150 mm flag line.
//
// MULTI-COLOR 3MF: each "// @part" line below is one filament. Touching regions
// of different colors are carved so they butt instead of interpenetrate; the
// plain STL (part = "all") welds everything into one body for the viewer.
//
// @part skin   #E8B98F
// @part hair   #F2B33D
// @part jersey #C8102E
// @part navy   #14213D
// @part black  #1A1A1A
// @part oar    #6B4A2B

// @param scale_factor 1.0

scale_factor = 1.0;   // uniform resize of the whole figure

part = "all";         // "all" | "skin" | "hair" | "jersey" | "navy" | "shoes" | "oar"

$fn = 32;
eps = 0.02;

// Preview colors (ignored by STL export; make the CI thumbnail read true).
c_skin   = "#E8B98F";
c_hair   = "#F2B33D";
c_jersey = "#C8102E";
c_navy   = "#14213D";
c_black  = "#1A1A1A";
c_oar    = "#6B4A2B";

// ---------------------------------------------------------------------------
// Key anatomy points (mm). z = 0 is the bed.
// ---------------------------------------------------------------------------
head_c   = [0, 2, 40];   // head sphere center, nudged forward
head_r   = 9;

// Left/right symmetry uses sd = -1 (his right / screen left) and sd = +1.

// ---------------------------------------------------------------------------
// Primitive helpers
// ---------------------------------------------------------------------------
module rbox(sx, sy, sz, r = 2) {           // rounded box, centered
    hull() for (dx = [-1, 1], dy = [-1, 1], dz = [-1, 1])
        translate([dx*(sx/2 - r), dy*(sy/2 - r), dz*(sz/2 - r)]) sphere(r);
}

module capsule(p1, p2, r1, r2) {           // tapered capsule between two points
    hull() {
        translate(p1) sphere(r1);
        translate(p2) sphere(r2);
    }
}

// ---------------------------------------------------------------------------
// Raw body modules (pre-carve). Each is a simple solid; the part assemblies
// below difference the overlaps away so colors butt cleanly.
// ---------------------------------------------------------------------------
module m_hip()  translate([0, -3, 6.5]) rbox(24, 18, 13, 4);   // butt / shorts

module m_torso()                                                 // jersey
    hull() {
        translate([0, -1, 13]) rbox(20, 14, 3, 2);   // waist
        translate([0, -1, 25]) rbox(21, 13, 3, 2);   // chest
        translate([ 10, -1, 25]) sphere(4.5);         // shoulders
        translate([-10, -1, 25]) sphere(4.5);
    }

module m_neck()
    capsule([0, 0, 27], [0, 1.5, 31.5], 5, 4.5);

module m_head() translate(head_c) sphere(head_r);

module m_hair_shell() {                                          // blonde cap
    difference() {
        translate(head_c) sphere(head_r + 1.3);
        translate(head_c) sphere(head_r);                        // hollow inside
        // Remove the face opening (front + lower) so hair sits on top & back.
        translate(head_c + [0, 8.5, -2.5]) cube([34, 22, 30], center = true);
    }
}

module m_bun()                                                   // top-knot
    translate(head_c + [0, -1.5, 11]) sphere(4.6);

// Handlebar mustache: a wide bar under the nose with the ends curling up.
// Centers sit just inside the face sphere so the carved caps stay attached.
module m_mustache() {
    translate(head_c + [0, 7.4, -4.2]) scale([1.7, 0.7, 0.55]) sphere(2.6);
    for (sd = [-1, 1]) {
        translate(head_c + [sd*3.4, 6.9, -4.0]) sphere(1.5);   // sweep out
        translate(head_c + [sd*4.4, 6.4, -2.7]) sphere(1.2);   // curl up
    }
}

module m_eyes()                                                  // proud black dots
    for (sd = [-1, 1]) translate(head_c + [sd*3.2, 7.9, 1.2]) sphere(1.5);

module m_nose()                                                  // small skin bump
    translate(head_c + [0, 8.6, -1.0]) sphere(1.7);

module m_arm(sd)                                                 // shoulder->hand
    union() {
        capsule([sd*10, -1, 25], [sd*11, 6, 17], 3.3, 3);   // upper arm
        capsule([sd*11, 6, 17], [sd*9, 15, 11], 3,   3.2);  // forearm + hand
    }

module m_thigh(sd)                                               // navy, on bed
    capsule([sd*6.5, 5, 5], [sd*6.5, 16, 4.5], 5, 4.5);

module m_shin(sd)                                               // skin, on bed
    capsule([sd*6.5, 16, 4.2], [sd*6.5, 24, 3.6], 4.2, 3.6);

module m_foot(sd)                                               // shoe, on bed
    hull() {
        translate([sd*6.5, 24, 3.8]) sphere(3.8);
        translate([sd*6.5, 31, 3.2]) sphere(3.2);
        translate([sd*6.5, 32, 4.5]) sphere(2.2);   // toe lifts slightly
    }

// Oar: wooden handle + shaft from the hand out and down to the blade neck.
module m_oar(sd)
    capsule([sd*8, 15, 11], [sd*25, 4, 4.5], 2, 2);

// Oar blade: chunky red paddle resting on the bed at the figure's side.
module m_blade(sd)
    translate([sd*29, 3, 2.2]) rotate([0, 0, sd*-18]) rbox(11, 7, 4.4, 1.6);

// ---------------------------------------------------------------------------
// Raw per-color groups (overlapping). Unioned together for the welded "all"
// STL they merge into one clean manifold; each is also the starting point for
// its carved single-filament part.
// ---------------------------------------------------------------------------
module skin_raw()
    for (sd = [-1, 1]) { m_arm(sd); m_shin(sd); }
    // head + neck added explicitly below so they render once, not per side
module skin_group()  { m_head(); m_neck(); m_nose(); skin_raw(); }
module hair_group()  { m_hair_shell(); m_bun(); m_mustache(); }
module jersey_group(){ m_torso(); for (sd = [-1, 1]) m_blade(sd); }
module navy_group()  { m_hip(); for (sd = [-1, 1]) m_thigh(sd); }
module black_group() { m_eyes(); for (sd = [-1, 1]) m_foot(sd); }
module oar_group()   { for (sd = [-1, 1]) m_oar(sd); }

// Carved variants: subtract the neighbors of a different color so touching
// filaments butt instead of interpenetrating in the 3MF.
module skin_part() {
    difference() {
        skin_group();
        m_torso(); m_hip();
        for (sd = [-1, 1]) { m_thigh(sd); m_foot(sd); m_oar(sd); }
    }
}
module hair_part()   { difference() { hair_group();   m_head(); } }
module jersey_part() { difference() { jersey_group(); m_hip(); for (sd=[-1,1]) m_oar(sd); } }
module navy_part()   { navy_group(); }   // butts are handled by skin/jersey carves
module black_part()  { difference() { black_group(); m_head(); } } // eyes butt the face
module oar_part()    { difference() { oar_group(); for (sd=[-1,1]) m_arm(sd); } }

// ---------------------------------------------------------------------------
// Render — "all" welds the overlapping raw groups; a named part carves.
// ---------------------------------------------------------------------------
scale([scale_factor, scale_factor, scale_factor]) {
    if (part == "all") {
        color(c_skin)   skin_group();
        color(c_hair)   hair_group();
        color(c_jersey) jersey_group();
        color(c_navy)   navy_group();
        color(c_black)  black_group();
        color(c_oar)    oar_group();
    }
    if (part == "skin")   skin_part();
    if (part == "hair")   hair_part();
    if (part == "jersey") jersey_part();
    if (part == "navy")   navy_part();
    if (part == "black")  black_part();
    if (part == "oar")    oar_part();
}
