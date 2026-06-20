# BambuMaker Design Principles

Design guidelines for parametric models targeting the **Bambu Lab A1 Mini**
(180 × 180 × 180 mm build volume, 0.4 mm nozzle, single filament).
Material range: PLA through PETG.

---

## Print orientation

Design parts to print in their natural display orientation — the way they'll
sit on a desk or mount to something — with the flattest face on the bed.
This gives the best surface finish where it matters and avoids complex
supports.

## Overhangs

**Default rule:** keep downward-facing surfaces ≤ 45° from horizontal so the
slicer can bridge them without support material.

**Exception:** overhangs steeper than 45° are acceptable when they serve a
genuine functional purpose and the trade-off is worth it (e.g. a watch-cradle
ledge, a snap-fit hook). In those cases:

- Add a chamfer or fillet on the overhang transition to approach 45° as
  closely as the geometry allows.
- Note the overhang explicitly in the file header comment so the next person
  knows it's intentional, not an oversight.
- Prefer Bambu Studio's "support on build plate only" if supports are truly
  unavoidable, to keep them easy to remove.

## No enclosed tunnels or bridging voids

Open slots, channels, and grooves must exit through an open face.
Never close the top of a channel mid-print; bridging PLA/PETG over a wide gap
produces poor surfaces. If a passage must be enclosed, orient it so it
prints as a roof (flat bridging) rather than a dome.

## Wall thickness and infill

- Minimum wall: **1.6 mm** (4 × nozzle) for structural parts; **0.8 mm** for
  cosmetic/light-duty shells.
- Leave solid bodies solid and let the slicer control infill. Do not add
  internal voids that create hidden overhangs or bridging in the slice.
- For parts that need rigidity (stands, brackets), **3–4 perimeters + 15–20 %
  gyroid infill** in Bambu Studio works well in PLA and PETG.

## Tolerances and fit

| Fit type              | Clearance per side |
|-----------------------|--------------------|
| Slip fit (drop-in)    | 0.25 mm            |
| Press fit             | 0.10 mm            |
| Gridfinity standard   | 0.25 mm per side   |

PETG prints slightly larger than PLA due to lower shrinkage — tighten
clearances by ~0.05 mm when targeting PETG for tight fits.

## Corner radii

- Minimum **0.8 mm** fillet on any sharp exterior edge to prevent stress
  concentrations and bed-adhesion lifting.
- Gridfinity outer radius: **3.75 mm** (spec).
- Interior corners that form the bottom of a pocket: **≥ 0.4 mm** (one nozzle
  width) so the slicer can actually reach them.

## Fasteners and hardware

- Prefer snap-fits and friction fits over hardware when loads are light.
- Countersinks for M3 heat-set inserts: **4.5 mm** diameter, **6 mm** deep.
- Magnet pockets (6 × 2 mm disc): **6.1 mm** diameter, **2.1 mm** deep.

## Build volume awareness

Keep the bounding box comfortably inside **170 × 170 × 170 mm** to leave room
for brim and purge tower. Flag any design that exceeds **150 mm** in any axis
with a comment at the top of the SCAD file.

## Parametric style (OpenSCAD)

- All user-tunable values as named variables at the top; annotate with
  `// @param name default` so the web viewer can expose them.
- Use `$fn = 64` globally; locally override to `$fn = 32` for small detail
  features (< 5 mm diameter) to keep polygon counts sane.
- Derive everything else from those top-level variables — no magic numbers
  buried in modules.
- Prefer `hull()` and `minkowski()` for smooth transitions over manual
  polygon maths wherever the preview time is acceptable.

## Material notes

| Property          | PLA              | PETG             |
|-------------------|------------------|------------------|
| Bed temp          | 55 °C            | 70 °C            |
| Print temp        | 220 °C           | 235 °C           |
| Layer adhesion    | Good             | Excellent        |
| Heat resistance   | ~60 °C           | ~80 °C           |
| Flexibility       | Brittle          | Slight flex      |
| Best for          | Detail, display  | Functional parts |

Use **PLA** for display objects and cosmetic items.
Use **PETG** for clips, brackets, or anything that lives in a warm environment
(car, near electronics).
