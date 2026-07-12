# From Idea to 3D Printed Part

The end-to-end workflow for BambuMaker: how a rough idea becomes a printable
part on the Bambu A1 Mini, and where each tool fits.

> **Keep this current.** This file is the living description of how we actually
> work. When we change the pipeline — new CI steps, new file formats, a
> different slicer flow — update this doc in the same change.

---

## The pipeline at a glance

```
Idea
  │
  ▼
ChatGPT (image + specs)  ──►  reference image + rough dimensions/intent
  │
  ▼
Claude (this repo)       ──►  parametric OpenSCAD .scad file  ← source of truth
  │
  ▼
Push branch → merge to main
  │
  ▼
GitHub Actions           ──►  .stl + preview.png + .3mf + _bambu.3mf + manifest.json
  │
  ▼
GitHub Pages viewer      ──►  review the render on your phone
  │
  ▼
Download _bambu.3mf → Bambu Studio  ──►  slice → print
  │
  ▼
Physical part → learn → tweak a @param → re-push  (loop)
```

---

## Step 1 — Idea

Have the idea. A stand, a holder, a bracket, a topper — anything that fits
inside the A1 Mini's 180 × 180 × 180 mm build volume.

## Step 2 — ChatGPT: image + specs

Use an image-capable AI tool (ChatGPT, etc.) to turn the idea into something
concrete:

- **A reference image** — what the thing should look like. This is mood and
  aesthetics: proportions, style, the vibe of the object.
- **Rough specs** — dimensions, function, what it holds or mounts to, any
  clearances that matter.

**Why the image matters — and what it does *not* do.** The picture is the
fastest way to pin down *shape and proportion* and to align on intent before a
single line of geometry exists. It's genuinely important: a good reference
image removes a whole round of "no, more like this" back-and-forth. But the
image does **not** get turned into geometry directly — Claude does not trace a
mesh from a photo. What actually drives the model is the **specs plus the
design principles**. So:

- Lead with numbers and function; let the image carry the look.
- Pull real measurements off the object you're designing for (the watch, the
  phone, the bottle) — those matter far more than the render.
- Treat the image as the tiebreaker on aesthetics, not the spec.

Hand both the image and the specs to Claude in this repo.

## Step 3 — Claude: parametric OpenSCAD

Claude writes a **parametric OpenSCAD `.scad` file** — not a finished mesh.
This is the single most important idea in the whole workflow: **the artifact
is editable source code in git, not an opaque STL.** That's what makes designs
iterable, diffable, and reviewable on your phone.

The file lives at `DesignIterator/designs/<name>/<name>.scad` and follows the
rules in [`DESIGN_PRINCIPLES.md`](DESIGN_PRINCIPLES.md) — A1 Mini build volume,
the 45° overhang rule, minimum wall thickness, fit tolerances, fillets, etc.
Those constraints are what make AI output actually printable.

Tunable values are declared at the top with `@param` comments so the web
viewer can expose them:

```openscad
// @param height 100
// @param diameter 80
// @param wall_thickness 3
```

Multi-color parts declare `// @part <name> #RRGGBB` and honor a `part`
variable — see `DesignIterator/CLAUDE.md` for the full convention.

## Step 4 — Push and merge to main

**CI only runs on push to `main`.** Development happens on a feature branch, so
nothing compiles, previews, or reaches the website until the branch is merged.
The merge is a real, explicit step between "Claude generated it" and "it's on
the site."

## Step 5 — GitHub Actions builds everything

On every push to `main`, `.github/workflows/build.yml`:

1. Installs OpenSCAD.
2. For each `designs/*/`, exports:
   - `<name>.stl` (geometry)
   - `preview.png` (thumbnail, rendered headless via xvfb)
   - `<name>.3mf` and `<name>_bambu.3mf` for multi-color designs
3. Regenerates `docs/manifest.json`.
4. Commits the generated files back with `[skip ci]` so it doesn't loop.

Generated files under `docs/designs/*/` are **CI-owned — don't edit them by
hand.**

## Step 6 — Review in the GitHub Pages viewer

GitHub Pages serves `docs/index.html`, a mobile-optimized 3D viewer with a
design selector, live at:

**https://jesusroa1.github.io/BambuMaker/**

This is your cheap check *before burning filament*. Look at the render, confirm
proportions and geometry, read the "last commit" message to see what changed.
If it's wrong, go back to Step 3 — change a parameter, re-push.

## Step 7 — Download into Bambu Studio

Download the model and open it in Bambu Studio on your laptop.

> **Download `_bambu.3mf`, not the plain `.3mf`, for multi-color parts.**
> The build produces two 3MF flavors on purpose:
> - `<name>.3mf` — generic 3MF. Renders in color on the web viewer, but Bambu
>   Studio imports it as a single flattened object and you **lose per-color
>   filament slot assignment.**
> - `<name>_bambu.3mf` — Bambu Studio project 3MF. Carries the
>   `model_settings.config` so each part arrives **pre-assigned to filament
>   1 / 2 / 3.**
>
> For single-color parts, the `.stl` or plain `.3mf` is fine.

## Step 8 — Slice and print

Pick material at slice time — this is a print-time decision, not a design one:

- **PLA** — display and cosmetic parts, fine detail.
- **PETG** — functional parts, clips/brackets, anything that lives somewhere
  warm (a car, near electronics).

See the material table in `DESIGN_PRINCIPLES.md` for temps and settings. Slice,
send to the A1 Mini, print.

## Step 9 — Learn from the physical part, then loop

There is no automatic feedback loop after printing — the real world is the only
thing that tells you whether a tolerance is right. Tolerances (slip fit, press
fit, heat-set inserts) are documented in `DESIGN_PRINCIPLES.md`, but the first
print will teach you where they're off.

This is exactly what the parametric design is *for*: bad fit → change one
`@param` → re-push → reprint. A design isn't "done," it's just at its current
iteration.

---

## Roles, quickly

| Tool | Job |
|------|-----|
| **ChatGPT** (image AI) | Reference image + rough specs. Shape and intent. |
| **Claude** (this repo) | Parametric `.scad` source, following the design rules. |
| **GitHub Actions** | Compile `.scad` → STL / preview / 3MF; build manifest. |
| **GitHub Pages** | Phone-friendly 3D viewer to review before printing. |
| **Bambu Studio** | Slice the `_bambu.3mf`, choose material, print. |
| **The A1 Mini** | Makes the thing. |

## Where the risk is

The gap that bites is **"looks right in the viewer" vs "fits and prints right
in reality."** Two separate problems:

- **Geometry validity** (overhangs, bridging, walls) — mitigated up front by
  `DESIGN_PRINCIPLES.md`.
- **Physical tolerances** (does it actually fit?) — only real prints fix these.

A future improvement worth considering: a **printability lint** in CI
(bounding box, overhang angle, minimum wall) that flags problems automatically
before a design ever reaches Bambu Studio.
