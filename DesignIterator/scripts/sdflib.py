"""
sdflib — tiny signed-distance-field modeling kit for BambuMaker figures.

Why: OpenSCAD can only hard-union primitives, which makes organic figures
look like lumpy sphere piles. SDFs support *smooth* unions (the polynomial
blend from Inigo Quilez's reference formulas), giving the filleted
vinyl-toy surface where a neck flows into a torso. The workflow:

    1. Model each colored region as an SDF callable (numpy, mm units)
    2. Carve touching colors so they butt (max(d, -other))
    3. Extract watertight meshes with marching cubes at print resolution
    4. Decimate to web-viewer-friendly triangle counts
    5. Write binary STLs -> the existing build_3mf.py packages colors

Dependencies (CI: pip install numpy scikit-image matplotlib fast-simplification):
    numpy, scikit-image (marching cubes), matplotlib (preview renders),
    fast-simplification (optional; quadric decimation).

All SDF callables take an (N, 3) float32 array of points and return (N,)
distances (negative inside). Distances only need to be exact near the
surface — approximate interior fields are fine for marching cubes.
"""

import struct

import numpy as np


# ---------------------------------------------------------------------------
# Primitives
# ---------------------------------------------------------------------------
def sphere(center, r):
    c = np.asarray(center, np.float32)
    return lambda p: np.linalg.norm(p - c, axis=1) - r


def ellipsoid(center, radii):
    """iq's approximation — good near the surface for mild aspect ratios."""
    c = np.asarray(center, np.float32)
    r = np.asarray(radii, np.float32)

    def f(p):
        q = p - c
        k0 = np.linalg.norm(q / r, axis=1)
        k1 = np.linalg.norm(q / (r * r), axis=1)
        return np.where(k1 > 1e-9, k0 * (k0 - 1.0) / np.maximum(k1, 1e-9), -np.min(r))

    return f


def capsule(a, b, ra, rb=None):
    """Capsule from a to b; radius lerps ra -> rb along the axis (tapered)."""
    a = np.asarray(a, np.float32)
    b = np.asarray(b, np.float32)
    rb_ = ra if rb is None else rb
    ba = b - a
    l2 = float(ba @ ba) or 1e-9

    def f(p):
        pa = p - a
        h = np.clip((pa @ ba) / l2, 0.0, 1.0)
        d = np.linalg.norm(pa - np.outer(h, ba), axis=1)
        return d - (ra + (rb_ - ra) * h)

    return f


def round_box(center, size, r):
    """Box of `size` (full extents) with edges rounded by r."""
    c = np.asarray(center, np.float32)
    half = np.asarray(size, np.float32) / 2.0 - r

    def f(p):
        q = np.abs(p - c) - half
        outside = np.linalg.norm(np.maximum(q, 0.0), axis=1)
        inside = np.minimum(np.max(q, axis=1), 0.0)
        return outside + inside - r

    return f


def torus(center, axis, R, r):
    """Torus around `axis` (unit-ish vector) — ring radius R, tube radius r."""
    c = np.asarray(center, np.float32)
    ax = np.asarray(axis, np.float32)
    ax = ax / np.linalg.norm(ax)

    def f(p):
        q = p - c
        z = q @ ax
        radial = np.sqrt(np.maximum(np.einsum("ij,ij->i", q, q) - z * z, 0.0))
        return np.sqrt((radial - R) ** 2 + z * z) - r

    return f


def half_space(normal, offset):
    """d = dot(p, n) - offset. Positive side of the plane is 'outside'."""
    n = np.asarray(normal, np.float32)
    n = n / np.linalg.norm(n)
    return lambda p: -((p @ n) - offset)


# ---------------------------------------------------------------------------
# Operators
# ---------------------------------------------------------------------------
def union(*fs):
    def f(p):
        d = fs[0](p)
        for g in fs[1:]:
            np.minimum(d, g(p), out=d)
        return d

    return f


def smooth_union(k, *fs):
    """Polynomial smooth min — k is the blend radius in mm."""

    def smin(d1, d2):
        h = np.clip(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0)
        return d2 + (d1 - d2) * h - k * h * (1.0 - h)

    def f(p):
        d = fs[0](p)
        for g in fs[1:]:
            d = smin(d, g(p))
        return d

    return f


def intersect(*fs):
    def f(p):
        d = fs[0](p)
        for g in fs[1:]:
            np.maximum(d, g(p), out=d)
        return d

    return f


def subtract(base, *cutters):
    def f(p):
        d = base(p)
        for g in cutters:
            np.maximum(d, -g(p), out=d)
        return d

    return f


def smooth_subtract(k, base, cutter):
    def f(p):
        d1, d2 = base(p), cutter(p)
        h = np.clip(0.5 - 0.5 * (d1 + d2) / k, 0.0, 1.0)
        return d1 + (-d2 - d1) * h + k * h * (1.0 - h)

    return f


def dilate(f, r):
    """Positive r grows the body outward (offset surface)."""
    return lambda p: f(p) - r


def scale_pts(f, s):
    """Uniform scale of a finished SDF about the origin."""
    return lambda p: f(p / s) * s


# ---------------------------------------------------------------------------
# Meshing
# ---------------------------------------------------------------------------
def _eval_grid(f, origin, shape, voxel, slab=32):
    """Evaluate f over a regular grid in z-slabs to bound peak memory."""
    nx, ny, nz = shape
    field = np.empty(shape, np.float32)
    xs = origin[0] + voxel * np.arange(nx, dtype=np.float32)
    ys = origin[1] + voxel * np.arange(ny, dtype=np.float32)
    for z0 in range(0, nz, slab):
        z1 = min(z0 + slab, nz)
        zs = origin[2] + voxel * np.arange(z0, z1, dtype=np.float32)
        gx, gy, gz = np.meshgrid(xs, ys, zs, indexing="ij")
        pts = np.stack([gx.ravel(), gy.ravel(), gz.ravel()], axis=1)
        field[:, :, z0:z1] = f(pts).reshape(nx, ny, z1 - z0)
    return field


def mesh(f, bounds, voxel=0.25, target_tris=None):
    """Marching-cubes mesh of {f < 0} inside bounds ((xmin,ymin,zmin),(max...)).

    Pads the grid so the surface never touches the boundary -> watertight.
    Returns (verts float32 (V,3), faces int32 (F,3)) with outward normals.
    """
    from skimage import measure

    lo = np.asarray(bounds[0], np.float32) - 3 * voxel
    hi = np.asarray(bounds[1], np.float32) + 3 * voxel
    shape = tuple(int(np.ceil((hi[i] - lo[i]) / voxel)) + 1 for i in range(3))
    field = _eval_grid(f, lo, shape, voxel)

    if field.min() >= 0:  # nothing inside (an empty carved part)
        return np.zeros((0, 3), np.float32), np.zeros((0, 3), np.int32)

    verts, faces, _, _ = measure.marching_cubes(
        field, level=0.0, spacing=(voxel, voxel, voxel),
        gradient_direction="ascent", allow_degenerate=False,
    )
    verts = (verts + lo).astype(np.float32)
    faces = faces.astype(np.int32)

    if target_tris and len(faces) > target_tris:
        try:
            import fast_simplification

            ratio = 1.0 - target_tris / len(faces)
            verts, faces = fast_simplification.simplify(verts, faces, ratio)
            verts = verts.astype(np.float32)
            faces = faces.astype(np.int32)
        except ImportError:
            pass  # keep the full-resolution mesh

    # Guarantee outward orientation via signed volume.
    v0, v1, v2 = verts[faces[:, 0]], verts[faces[:, 1]], verts[faces[:, 2]]
    vol = np.einsum("ij,ij->i", v0, np.cross(v1, v2)).sum() / 6.0
    if vol < 0:
        faces = faces[:, ::-1]
    return verts, faces


def save_stl(path, verts, faces):
    """Binary STL."""
    v0, v1, v2 = verts[faces[:, 0]], verts[faces[:, 1]], verts[faces[:, 2]]
    n = np.cross(v1 - v0, v2 - v0)
    lens = np.linalg.norm(n, axis=1, keepdims=True)
    n = np.where(lens > 1e-12, n / np.maximum(lens, 1e-12), 0.0)
    tri = np.zeros((len(faces), 12), np.float32)
    tri[:, 0:3], tri[:, 3:6], tri[:, 6:9], tri[:, 9:12] = n, v0, v1, v2
    blob = np.zeros((len(faces), 50), np.uint8)
    blob[:, :48] = tri.view(np.uint8).reshape(len(faces), 48)
    with open(path, "wb") as fh:
        fh.write(b"\0" * 80)
        fh.write(struct.pack("<I", len(faces)))
        fh.write(blob.tobytes())


# ---------------------------------------------------------------------------
# Preview rendering (painter's algorithm — no GPU needed)
# ---------------------------------------------------------------------------
def render_views(colored_meshes, out_path, views, size=600, bg="#FFFFFF"):
    """Render orthographic views of [(verts, faces, '#RRGGBB'), ...].

    views: list of (azim_deg, elev_deg) tuples; laid out in a row grid.
    """
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib.collections import PolyCollection

    allv = np.concatenate([v for v, f, c in colored_meshes if len(v)])
    center = (allv.min(0) + allv.max(0)) / 2.0
    radius = float(np.linalg.norm(allv - center, axis=1).max()) * 1.05

    ncols = min(len(views), 3)
    nrows = (len(views) + ncols - 1) // ncols
    fig, axes = plt.subplots(
        nrows, ncols, figsize=(size / 100 * ncols, size / 100 * nrows), dpi=100
    )
    axes = np.atleast_1d(axes).ravel()

    for ax, (azim, elev) in zip(axes, views):
        az, el = np.radians(azim), np.radians(elev)
        fwd = np.array(  # camera looks along -fwd
            [np.cos(el) * np.sin(az), -np.cos(el) * np.cos(az), np.sin(el)],
            np.float32,
        )
        right = np.array([np.cos(az), np.sin(az), 0.0], np.float32)
        up = np.cross(fwd, right)
        light = fwd + right * 0.35 + up * 0.55
        light /= np.linalg.norm(light)

        polys, shades, depths = [], [], []
        for verts, faces, color in colored_meshes:
            if not len(faces):
                continue
            rgb = np.array(
                [int(color[i : i + 2], 16) / 255 for i in (1, 3, 5)], np.float32
            )
            q = verts - center
            pv = np.stack([q @ right, q @ up, q @ fwd], axis=1)
            t0, t1, t2 = pv[faces[:, 0]], pv[faces[:, 1]], pv[faces[:, 2]]
            nrm = np.cross(t1 - t0, t2 - t0)
            keep = nrm[:, 2] > 0  # backface cull
            t0, t1, t2, nrm = t0[keep], t1[keep], t2[keep], nrm[keep]
            nrm /= np.maximum(np.linalg.norm(nrm, axis=1, keepdims=True), 1e-12)
            lam = np.clip(
                nrm @ np.array([light @ right, light @ up, light @ fwd]), 0, 1
            )
            shade = np.clip(0.35 + 0.65 * lam[:, None], 0, 1) * rgb
            polys.append(np.stack([t0[:, :2], t1[:, :2], t2[:, :2]], axis=1))
            shades.append(shade)
            depths.append((t0[:, 2] + t1[:, 2] + t2[:, 2]) / 3.0)

        polys = np.concatenate(polys)
        shades = np.concatenate(shades)
        order = np.argsort(np.concatenate(depths))  # back to front
        ax.add_collection(
            PolyCollection(
                polys[order], facecolors=shades[order], edgecolors="none",
                antialiaseds=False,
            )
        )
        ax.set_xlim(-radius, radius)
        ax.set_ylim(-radius, radius)
        ax.set_aspect("equal")
        ax.axis("off")
    for ax in axes[len(views):]:
        ax.axis("off")

    fig.patch.set_facecolor(bg)
    fig.tight_layout(pad=0.2)
    fig.savefig(out_path, facecolor=bg)
    plt.close(fig)
