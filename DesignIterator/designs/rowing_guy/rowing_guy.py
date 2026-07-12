#!/usr/bin/env python3
"""
Rowing Guy v2 — smooth SDF sculpt of the reference vinyl-toy render.

A chibi sculler seated on the bed: blonde top-knot bun + handlebar
mustache, red jersey with the Norwegian cross (navy on white), navy
shorts, striped socks, black shoes, and two crossed oars whose red
blades rest on the plate.

Built with scripts/sdflib.py: every body part is a signed distance
field and same-color parts merge with *smooth unions*, so surfaces
flow into each other like the reference instead of reading as stacked
spheres (the failure mode of the OpenSCAD v1). Different colors are
carved against each other by priority so the multi-color 3MF parts
butt without overlapping.

PRINT NOTES
- Prints in display orientation. Bed contacts: butt, both shoes, both
  oar blades. The oar shafts are shallow-angle struts and the underside
  of the chin/head overhangs >45 deg — print with tree supports
  (auto) for a clean result, or accept minor drooping there.
- Footprint ~58 x 42 mm, height ~54 mm: about 1/13 of the A1 mini
  plate (tune with scale_factor). Colors map to filament slots 1..7 in
  Bambu Studio; merge brown->black and white->skin on a 4-slot AMS.

Parameters (viewer):
# @param scale_factor 1.0
# @param voxel 0.22

Color parts (filament order = carve priority, low to high):
# @part brown #6B4A2B
# @part skin  #E8B98F
# @part red   #C8102E
# @part white #F4F4F4
# @part navy  #14213D
# @part hair  #F2B33D
# @part black #1A1A1A
"""

import argparse
import os
import sys

import numpy as np

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                os.pardir, os.pardir, "scripts"))
import sdflib as s  # noqa: E402

scale_factor = 1.0
voxel = 0.22

COLORS = {
    "brown": "#6B4A2B",
    "skin":  "#E8B98F",
    "red":   "#C8102E",
    "white": "#F4F4F4",
    "navy":  "#14213D",
    "hair":  "#F2B33D",
    "black": "#1A1A1A",
}
PRIORITY = ["brown", "skin", "red", "white", "navy", "hair", "black"]

BOUNDS = ((-34.0, -13.0, -0.8), (34.0, 33.0, 56.0))


def mirror(fn):
    """Build fn(sd) for sd = -1 and +1 and return both SDFs."""
    return [fn(sd) for sd in (-1.0, 1.0)]


def slab(axis, lo, hi):
    """Region lo < p[axis] < hi (infinite in the other two axes)."""
    def f(p):
        return np.maximum(lo - p[:, axis], p[:, axis] - hi)
    return f


def build_groups():
    """Raw (overlapping) SDF per color. +y = forward, z = up, bed at z=0."""

    # --- skin ---------------------------------------------------------
    skull = s.ellipsoid([0, 1.5, 36], [10.5, 10.0, 10.5])
    jaw = s.sphere([0, 2.5, 33.5], 8.0)
    ears = mirror(lambda sd: s.sphere([sd * 10.3, 1.5, 35.5], 1.7))
    nose = s.sphere([0, 11.2, 35.3], 1.6)
    head = s.smooth_union(1.2, skull, jaw, *ears, nose)

    neck = s.capsule([0, 1.5, 22], [0, 1.8, 27], 4.2, 3.9)

    def arm(sd):
        forearm = s.capsule([sd * 11.3, 3.4, 16.0], [sd * 5.6, 10.6, 13.0],
                            2.9, 2.5)
        fist = s.sphere([sd * 4.4, 12.0, 13.0], 2.8)
        return s.smooth_union(1.5, forearm, fist)

    def leg(sd):
        return s.capsule([sd * 6.4, 11.5, 6.2], [sd * 6.6, 20.5, 3.5],
                         3.4, 2.7)

    skin = s.smooth_union(1.0, s.smooth_union(2.5, head, neck),
                          *mirror(arm), *mirror(leg))

    # --- red: jersey + sleeves + oar blades + sock stripe --------------
    belly = s.ellipsoid([0, 0.5, 10.5], [11.5, 9.5, 8.5])
    chest = s.ellipsoid([0, 1.0, 17.5], [10.0, 8.5, 8.0])
    shoulders = s.capsule([-8.5, 0.8, 21.5], [8.5, 0.8, 21.5], 4.4)
    torso = s.smooth_union(3.0, belly, chest, shoulders)

    def sleeve(sd):
        return s.capsule([sd * 8.7, 0.8, 21.3], [sd * 11.6, 3.2, 15.5],
                         4.0, 3.4)

    sleeves = mirror(sleeve)
    jersey = s.smooth_union(2.0, torso, *sleeves)

    def blade(sd):
        return s.round_box([sd * 23.4, 18.5, 2.6], [10.5, 6.2, 4.2], 1.5)

    blades = mirror(blade)

    def sock_stripe_red(sd):
        return s.capsule([sd * 6.62, 21.2, 3.55], [sd * 6.64, 21.9, 3.45], 3.1)

    red = s.union(jersey, *blades, *mirror(sock_stripe_red))

    # --- oars (brown shafts, black grips) -------------------------------
    def oar_pts(sd):
        """Crossover sculling: the sd-side blade connects to the -sd hand."""
        hand = np.array([-sd * 4.4, 12.0, 13.0])
        tip = np.array([sd * 23.0, 18.5, 2.4])
        d = tip - hand
        d = d / np.linalg.norm(d)
        return hand - d * 4.5, tip, d  # handle end sticks past the fist

    def shaft(sd):
        h, tip, _ = oar_pts(sd)
        return s.capsule(h, tip, 1.5)

    def grip(sd):
        h, _, d = oar_pts(sd)
        return s.capsule(h, h + d * 2.0, 1.5)

    brown = s.union(*mirror(shaft))

    # --- jersey cross (white border under navy center) -----------------
    band_zone = s.union(
        s.intersect(slab(0, -3.1, 3.1), slab(2, -99, 23.5)),   # vertical
        s.intersect(slab(2, 13.9, 20.1), slab(0, -9.0, 9.0)),  # horizontal
    )
    band_zone_navy = s.union(
        s.intersect(slab(0, -1.9, 1.9), slab(2, -99, 23.0)),
        s.intersect(slab(2, 15.1, 18.9), slab(0, -9.0, 9.0)),
    )
    sleeves_grown = s.dilate(s.union(*sleeves), 0.4)
    cross_white = s.subtract(
        s.intersect(s.dilate(torso, 0.55), band_zone), sleeves_grown)
    cross_navy = s.subtract(
        s.intersect(s.dilate(torso, 0.95), band_zone_navy), sleeves_grown)

    def blade_stripe(sd):
        return s.intersect(s.dilate(blade(sd), 0.5),
                           slab(0, sd * 25.1 - 1.0, sd * 25.1 + 1.0))

    def sock(sd):
        return s.capsule([sd * 6.6, 19.2, 4.0], [sd * 6.7, 23.6, 3.2], 3.0, 2.9)

    white = s.union(cross_white, *mirror(blade_stripe), *mirror(sock))

    # --- navy: shorts + collar + cross center + sock stripe ------------
    pelvis = s.ellipsoid([0, 1.0, 5.8], [12.0, 10.5, 6.2])

    def short_leg(sd):
        return s.capsule([sd * 5.8, 3.0, 5.4], [sd * 6.4, 12.0, 6.2], 4.6, 4.2)

    shorts = s.smooth_union(2.5, pelvis, *mirror(short_leg))
    collar = s.torus([0, 1.8, 24.6], [0, 0.28, 1], 4.9, 1.35)

    def sock_stripe_navy(sd):
        return s.capsule([sd * 6.6, 20.2, 3.75], [sd * 6.62, 20.9, 3.65], 3.1)

    navy = s.union(shorts, collar, cross_navy, *mirror(sock_stripe_navy))

    # --- hair: solid cap + bun + brows + mustache -----------------------
    cap = s.subtract(
        s.dilate(skull, 1.7),
        s.ellipsoid([0, 12.0, 35.0], [10.6, 8.5, 10.0]),        # face opening
        s.intersect(slab(2, -99, 30.5), slab(1, 1.5, 99)),      # clear the chin
        *mirror(lambda sd: s.ellipsoid([sd * 10.9, 3.5, 35.0],  # ear pockets
                                       [2.8, 4.5, 3.4])),       # (join the face)
    )
    bun = s.smooth_union(
        1.4,
        s.ellipsoid([0, -1.0, 47.6], [4.9, 4.9, 3.4]),
        s.ellipsoid([0, -1.0, 49.7], [2.7, 2.7, 1.9]),
    )

    def brow(sd):
        return s.capsule([sd * 2.6, 10.0, 39.8], [sd * 5.6, 9.3, 40.1], 0.55)

    def stache(sd):
        return s.smooth_union(
            0.8,
            s.sphere([0, 11.1, 34.6], 1.05),
            s.sphere([sd * 2.1, 10.9, 34.5], 1.05),
            s.sphere([sd * 4.0, 10.3, 34.9], 0.9),
            s.sphere([sd * 5.3, 9.5, 35.9], 0.7),
        )

    hair = s.union(s.smooth_union(1.2, cap, bun), *mirror(brow),
                   *mirror(stache))

    # --- black: eyes + shoes + oar grips --------------------------------
    def eye(sd):
        return s.ellipsoid([sd * 3.9, 10.5, 37.5], [1.15, 0.95, 1.45])

    def shoe(sd):
        return s.smooth_union(
            2.0,
            s.sphere([sd * 6.7, 23.5, 2.8], 3.2),
            s.sphere([sd * 7.3, 28.5, 2.4], 2.8),
        )

    black = s.union(*mirror(eye), *mirror(shoe), *mirror(grip))

    return {
        "brown": brown, "skin": skin, "red": red, "white": white,
        "navy": navy, "hair": hair, "black": black,
    }


def build_parts():
    """Carve raw groups so higher-priority colors own shared boundaries,
    then sit everything flat on the bed (flat butt / soles / blades)."""
    groups = build_groups()
    floor = lambda p: -p[:, 2]  # keep z > 0 -> flat bases on the bed

    parts = {}
    for i, name in enumerate(PRIORITY):
        higher = [groups[n] for n in PRIORITY[i + 1:]]
        f = s.subtract(groups[name], *higher) if higher else groups[name]
        parts[name] = s.intersect(f, floor)
    return parts


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--outdir", default=None, help="write <name>.stl + preview.png here")
    ap.add_argument("--parts-dir", default=None, help="write part_<color>.stl here")
    ap.add_argument("--sheet", default=None, help="write a 6-view review sheet PNG")
    ap.add_argument("--voxel", type=float, default=voxel)
    ap.add_argument("--scale", type=float, default=scale_factor)
    args = ap.parse_args()

    parts = build_parts()
    if args.scale != 1.0:
        parts = {n: s.scale_pts(f, args.scale) for n, f in parts.items()}
    bounds = tuple(tuple(c * args.scale for c in corner) for corner in BOUNDS)

    budgets = {"brown": 12000, "skin": 60000, "red": 45000, "white": 20000,
               "navy": 30000, "hair": 45000, "black": 18000}
    meshes = {}
    for name, f in parts.items():
        verts, faces = s.mesh(f, bounds, args.voxel, target_tris=budgets[name])
        meshes[name] = (verts, faces)
        print(f"  {name:6s}: {len(faces):7d} tris")

    if args.parts_dir:
        os.makedirs(args.parts_dir, exist_ok=True)
        for name, (verts, faces) in meshes.items():
            s.save_stl(os.path.join(args.parts_dir, f"part_{name}.stl"),
                       verts, faces)

    colored = [(meshes[n][0], meshes[n][1], COLORS[n]) for n in PRIORITY]

    if args.outdir:
        os.makedirs(args.outdir, exist_ok=True)
        whole = s.intersect(s.union(*build_groups().values()),
                            lambda p: -p[:, 2])
        if args.scale != 1.0:
            whole = s.scale_pts(whole, args.scale)
        verts, faces = s.mesh(whole, bounds, args.voxel, target_tris=150000)
        print(f"  all   : {len(faces):7d} tris")
        s.save_stl(os.path.join(args.outdir, "rowing_guy.stl"), verts, faces)
        s.render_views(colored, os.path.join(args.outdir, "preview.png"),
                       views=[(215, 12)], size=600)

    if args.sheet:  # front / left / rear / 3-4 front / 3-4 rear / iso
        s.render_views(
            colored, args.sheet, size=500,
            views=[(180, 8), (90, 8), (0, 8), (215, 10), (325, 10), (215, 35)],
        )


if __name__ == "__main__":
    main()
