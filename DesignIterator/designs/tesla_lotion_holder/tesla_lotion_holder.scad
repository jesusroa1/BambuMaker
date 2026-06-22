// Tesla Model 3 (2017–2023) Lotion Holder
// Mounts behind the top of the 15" landscape center touchscreen.
// The flange rests on the screen's top frame; the hook lip catches the front
// bezel edge — friction + gravity fit, no tools or adhesive needed.
//
// 2017–2023 Tesla Model 3 center screen reference dimensions:
//   Screen housing width             ≈ 358 mm  → holder centered, 44 mm each side
//   Top bezel depth (front-to-back)  ≈ 36 mm  → flange_d = 40 mm covers it fully
//   Front bezel edge height          ≈ 18 mm  → hook_h   = 15 mm (3 mm clearance)
//   Usable space behind screen top   ≈ 140 mm → tray_d   = 140 mm
//
// Installation: lower holder from above into the space behind the screen.
// Flange slides over the top of the screen frame; hook lip drops down on the
// driver side of the bezel. The bottle is accessible by reaching over the screen.
//
// @param tray_w 270
// @param tray_d 140
// @param tray_h 68
// @param wall_t 3
// @param flange_d 40
// @param hook_h 15
// @param corner_r 5

tray_w   = 270;   // total holder width, left to right (mm)
tray_d   = 140;   // depth of bottle cavity, screen-side to rear wall (mm)
tray_h   = 68;    // height of side and back walls (mm)
wall_t   = 3;     // wall and floor thickness (mm)
flange_d = 40;    // mounting flange depth — overlaps screen top bezel (mm)
hook_h   = 15;    // hook lip drop below flange — catches front bezel edge (mm)
corner_r = 5;     // outer corner radius (mm)

$fn = 64;
eps = 0.01;

// Coordinate origin: rear-left corner of tray, at floor level.
// +X  → right
// +Y  → toward driver (front of tray, then flange, then hook tip)
// +Z  → up (walls rise here; hook lip hangs at Z < 0)

// ─── Helper: axis-aligned rounded box ────────────────────────────────────────
module rbox(w, d, h, r) {
    hull()
        for (x = [r, w-r], y = [r, d-r])
            translate([x, y, 0]) cylinder(r=r, h=h);
}

// ─── Main tray shell (open top) ───────────────────────────────────────────────
module tray() {
    inner_r = max(corner_r - wall_t, 1);
    difference() {
        rbox(tray_w, tray_d, tray_h, corner_r);
        // hollow interior — floor and all walls remain
        translate([wall_t, wall_t, wall_t])
            rbox(tray_w - 2*wall_t, tray_d - 2*wall_t, tray_h, inner_r);
    }
}

// ─── Mounting flange (rests flat on top of screen frame) ──────────────────────
// Extends from the front wall of the tray toward the driver / screen side.
module flange() {
    translate([0, tray_d, 0])
        rbox(tray_w, flange_d, wall_t, max(corner_r - wall_t, 2));
}

// ─── Hook lip (drops below flange, catches front edge of screen bezel) ────────
// Prevents the holder from sliding toward the driver when removing the bottle.
module hook_lip() {
    translate([corner_r, tray_d + flange_d - wall_t, -hook_h])
        cube([tray_w - 2*corner_r, wall_t, hook_h]);
}

// ─── Assembly ─────────────────────────────────────────────────────────────────
module lotion_holder() {
    union() {
        tray();
        flange();
        hook_lip();
    }
}

lotion_holder();
