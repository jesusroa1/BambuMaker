# BambuMaker

Parametric 3D designs for the Bambu A1 Mini, with a GitHub Pages viewer.

## How it works

1. Designs live in `designs/<name>/<name>.scad` as parametric OpenSCAD files
2. On every push to `main`, GitHub Actions compiles each `.scad` → `.stl` + `preview.png`
3. A `docs/manifest.json` is auto-generated and committed back
4. GitHub Pages serves `docs/index.html` — a mobile-optimized 3D viewer with a design selector

## Creating a new design

```
mkdir designs/<name>
touch designs/<name>/<name>.scad
```

Write an OpenSCAD file. At the top, declare parameters using `@param` comments so they show up in the viewer:

```openscad
// @param height 100
// @param diameter 80
// @param wall_thickness 3

height         = 100;
diameter       = 80;
wall_thickness = 3;
```

Commit and push. The CI pipeline will compile it automatically.

## Modifying an existing design

Edit the `.scad` file directly. Change parameter values or geometry. Commit with a descriptive message — the message is shown in the viewer as "last commit."

Example: `fix: widen handle to 15mm`

## File conventions

- Design folder and SCAD filename must match: `designs/vase/vase.scad`
- Parameters use `// @param <name> <value>` (one per line)
- Generated files (`docs/designs/*/`) are committed by CI — don't edit them by hand

## Multi-color designs (3MF)

A design opts into multi-color by declaring one `// @part <name> #RRGGBB`
line per color and honoring a `part` variable that renders just that body
(with `part = "all"` as the default for the plain STL):

```openscad
// @part base #FFFFFF
// @part accent #F0B323

part = "all"; // "all" | "base" | "accent"

if (part == "all" || part == "base") { ... }
```

CI then compiles each part with `-D part="<name>"` and runs
`scripts/build_3mf.py` to package them into `docs/designs/<name>/<name>.3mf`
with the declared colors. The viewer renders the colored 3MF and offers it
as a download; in Bambu Studio each part maps to its own filament slot.
Part bodies must not overlap — stack them in Z or keep them side by side.

## What the CI does

`.github/workflows/build.yml` on every push to `main`:
1. Installs OpenSCAD on Ubuntu
2. For each `designs/*/`, runs:
   - `openscad -o docs/designs/<name>/<name>.stl` (export STL)
   - `xvfb-run openscad --imgsize=600,600 -o docs/designs/<name>/preview.png` (render thumbnail)
3. Runs `scripts/generate_manifest.py` → writes `docs/manifest.json`
4. Commits back with `[skip ci]` to avoid loops

## GitHub Pages setup

In repo Settings → Pages → set source to **main branch / docs folder**.

The viewer will be live at: `https://jesusroa1.github.io/BambuMaker/`

## Design ideas

Start simple — a parameter change per iteration, descriptive commit messages so you can read the history on your phone and know what changed.
