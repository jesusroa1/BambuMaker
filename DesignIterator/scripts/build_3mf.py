#!/usr/bin/env python3
"""
Package per-color part STLs into a colored 3MF.

A design opts in by declaring parts in its .scad header:

    // @part base #FFFFFF
    // @part yellow #F0B323
    // @part black #1A1A1A

CI compiles each part with `openscad -D part="<name>"` into
<parts_dir>/part_<name>.stl, then this script welds each mesh and writes a
single 3MF whose objects carry the declared display colors. Slicers like
Bambu Studio open it as one model with per-part filament assignment.

Usage: build_3mf.py <design.scad> <parts_dir> <out.3mf>
"""

import os
import re
import struct
import sys
import zipfile


def parse_parts(scad_path):
    parts = []
    with open(scad_path, encoding="utf-8") as f:
        for line in f:
            m = re.match(r"//\s*@part\s+(\w+)\s+(#[0-9A-Fa-f]{6})", line.strip())
            if m:
                parts.append((m.group(1), m.group(2).upper()))
    return parts


def read_stl(path):
    """Return (vertices, triangles) with welded vertices."""
    with open(path, "rb") as f:
        data = f.read()

    tris_xyz = []
    if data[:5] == b"solid" and b"facet normal" in data[:300]:
        cur = []
        for line in data.decode("ascii", errors="ignore").splitlines():
            line = line.strip()
            if line.startswith("vertex"):
                cur.append(tuple(float(x) for x in line.split()[1:4]))
                if len(cur) == 3:
                    tris_xyz.append(cur)
                    cur = []
    else:
        (n,) = struct.unpack_from("<I", data, 80)
        off = 84
        for _ in range(n):
            v = struct.unpack_from("<12f", data, off)
            tris_xyz.append([tuple(v[3:6]), tuple(v[6:9]), tuple(v[9:12])])
            off += 50

    verts, index, tris = [], {}, []
    for tri in tris_xyz:
        ids = []
        for p in tri:
            key = (round(p[0], 4), round(p[1], 4), round(p[2], 4))
            i = index.get(key)
            if i is None:
                i = len(verts)
                index[key] = i
                verts.append(key)
            ids.append(i)
        if ids[0] != ids[1] and ids[1] != ids[2] and ids[0] != ids[2]:
            tris.append(tuple(ids))
    return verts, tris


def mesh_xml(obj_id, pid, pindex, name, verts, tris):
    out = [f'<object id="{obj_id}" type="model" name="{name}" '
           f'pid="{pid}" pindex="{pindex}"><mesh><vertices>']
    out += [f'<vertex x="{x:g}" y="{y:g}" z="{z:g}"/>' for x, y, z in verts]
    out.append("</vertices><triangles>")
    out += [f'<triangle v1="{a}" v2="{b}" v3="{c}"/>' for a, b, c in tris]
    out.append("</triangles></mesh></object>")
    return "".join(out)


def main():
    scad_path, parts_dir, out_path = sys.argv[1], sys.argv[2], sys.argv[3]
    parts = parse_parts(scad_path)
    if not parts:
        print(f"no @part lines in {scad_path} — nothing to do")
        return

    materials = "".join(
        f'<base name="{name}" displaycolor="{color}FF"/>' for name, color in parts
    )
    objects, components = [], []
    for i, (name, _color) in enumerate(parts):
        stl = os.path.join(parts_dir, f"part_{name}.stl")
        verts, tris = read_stl(stl)
        print(f"  {name}: {len(verts)} verts, {len(tris)} tris")
        obj_id = i + 2  # id 1 = basematerials
        objects.append(mesh_xml(obj_id, 1, i, name, verts, tris))
        components.append(f'<component objectid="{obj_id}"/>')

    parent_id = len(parts) + 2
    model = (
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<model unit="millimeter" xml:lang="en-US" '
        'xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">'
        f'<resources><basematerials id="1">{materials}</basematerials>'
        f'{"".join(objects)}'
        f'<object id="{parent_id}" type="model"><components>'
        f'{"".join(components)}</components></object>'
        f'</resources><build><item objectid="{parent_id}"/></build></model>'
    )

    content_types = (
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" '
        'ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="model" '
        'ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>'
        "</Types>"
    )
    rels = (
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Target="/3D/3dmodel.model" Id="rel0" '
        'Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>'
        "</Relationships>"
    )

    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml", content_types)
        z.writestr("_rels/.rels", rels)
        z.writestr("3D/3dmodel.model", model)
    print(f"wrote {out_path} ({os.path.getsize(out_path) // 1024} KB)")


if __name__ == "__main__":
    main()
