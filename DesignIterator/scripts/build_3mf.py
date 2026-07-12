#!/usr/bin/env python3
"""
Package per-color part STLs into a colored 3MF.

A design opts in by declaring parts in its .scad header:

    // @part base #FFFFFF
    // @part yellow #F0B323
    // @part black #1A1A1A

CI compiles each part with `openscad -D part="<name>"` into
<parts_dir>/part_<name>.stl, then this script welds each mesh and writes TWO
files:

  <out>.3mf        — generic core-spec 3MF with basematerials colors.
                     The web viewer (three.js) renders this in color.
  <out>_bambu.3mf  — Bambu Studio project 3MF. Bambu Studio imports generic
                     3MFs as a single flattened object ("not from Bambu Lab,
                     load geometry only"), losing per-part filament choice;
                     this flavor carries Metadata/model_settings.config so
                     each color part arrives pre-assigned to filament 1/2/3.

Usage: build_3mf.py <design.scad> <parts_dir> <out.3mf>
"""

import os
import re
import struct
import sys
import uuid
import zipfile


def parse_parts(scad_path):
    """Read @part declarations from a design source (.scad `//` or .py `#`)."""
    parts = []
    with open(scad_path, encoding="utf-8") as f:
        for line in f:
            m = re.match(r"(?://|#)\s*@part\s+(\w+)\s+(#[0-9A-Fa-f]{6})",
                         line.strip())
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


CONTENT_TYPES = (
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
    '<Default Extension="rels" '
    'ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
    '<Default Extension="model" '
    'ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>'
    "</Types>"
)
RELS = (
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Target="/3D/3dmodel.model" Id="rel0" '
    'Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>'
    "</Relationships>"
)


def write_generic(out_path, parts, meshes):
    """Core-spec 3MF with basematerials colors — for the web viewer."""
    materials = "".join(
        f'<base name="{name}" displaycolor="{color}FF"/>' for name, color in parts
    )
    objects, components = [], []
    for i, ((name, _c), (verts, tris)) in enumerate(zip(parts, meshes)):
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
    with zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml", CONTENT_TYPES)
        z.writestr("_rels/.rels", RELS)
        z.writestr("3D/3dmodel.model", model)
    print(f"wrote {out_path} ({os.path.getsize(out_path) // 1024} KB)")


def write_bambu(out_path, design_name, parts, meshes):
    """Bambu Studio project 3MF: one object whose parts are pre-assigned to
    filaments 1..N, so the color mapping survives import."""
    def uid(tag):
        return str(uuid.uuid5(uuid.NAMESPACE_URL, f"bambumaker/{design_name}/{tag}"))

    # Center the art on the 180x180 A1 mini plate.
    minx = min(v[0] for verts, _ in meshes for v in verts)
    maxx = max(v[0] for verts, _ in meshes for v in verts)
    miny = min(v[1] for verts, _ in meshes for v in verts)
    maxy = max(v[1] for verts, _ in meshes for v in verts)
    tx, ty = 90 - (minx + maxx) / 2, 90 - (miny + maxy) / 2
    placement = f"1 0 0 0 1 0 0 0 1 {tx:.3f} {ty:.3f} 0"

    objects, components, config_parts = [], [], []
    for i, ((name, _c), (verts, tris)) in enumerate(zip(parts, meshes)):
        obj_id = i + 2
        objects.append(
            f'<object id="{obj_id}" p:UUID="{uid(f"part{i}")}" type="model">'
            "<mesh><vertices>"
            + "".join(f'<vertex x="{x:g}" y="{y:g}" z="{z:g}"/>' for x, y, z in verts)
            + "</vertices><triangles>"
            + "".join(f'<triangle v1="{a}" v2="{b}" v3="{c}"/>' for a, b, c in tris)
            + "</triangles></mesh></object>"
        )
        components.append(
            f'<component p:UUID="{uid(f"comp{i}")}" objectid="{obj_id}" '
            'transform="1 0 0 0 1 0 0 0 1 0 0 0"/>'
        )
        config_parts.append(
            f'<part id="{obj_id}" subtype="normal_part">'
            f'<metadata key="name" value="{name}"/>'
            '<metadata key="matrix" value="1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1"/>'
            f'<metadata key="extruder" value="{i + 1}"/>'
            "</part>"
        )

    parent_id = len(parts) + 2
    model = (
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<model unit="millimeter" xml:lang="en-US" '
        'xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" '
        'xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" '
        'requiredextensions="p">'
        '<metadata name="Application">BambuStudio-01.09.00.00</metadata>'
        '<metadata name="BambuStudio:3mfVersion">1</metadata>'
        f'<resources>{"".join(objects)}'
        f'<object id="{parent_id}" p:UUID="{uid("object")}" type="model">'
        f'<components>{"".join(components)}</components></object>'
        f'</resources><build p:UUID="{uid("build")}">'
        f'<item objectid="{parent_id}" p:UUID="{uid("item")}" '
        f'transform="{placement}" printable="1"/></build></model>'
    )

    model_settings = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        "<config>\n"
        f'  <object id="{parent_id}">\n'
        f'    <metadata key="name" value="{design_name}"/>\n'
        '    <metadata key="extruder" value="1"/>\n'
        + "".join(f"    {p}\n" for p in config_parts)
        + "  </object>\n"
        "  <plate>\n"
        '    <metadata key="plater_id" value="1"/>\n'
        '    <metadata key="plater_name" value=""/>\n'
        '    <metadata key="locked" value="false"/>\n'
        "    <model_instance>\n"
        f'      <metadata key="object_id" value="{parent_id}"/>\n'
        '      <metadata key="instance_id" value="0"/>\n'
        '      <metadata key="identify_id" value="1"/>\n'
        "    </model_instance>\n"
        "  </plate>\n"
        "  <assemble>\n"
        f'   <assemble_item object_id="{parent_id}" instance_id="0" '
        f'transform="{placement}" offset="0 0 0" />\n'
        "  </assemble>\n"
        "</config>\n"
    )

    with zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml", CONTENT_TYPES)
        z.writestr("_rels/.rels", RELS)
        z.writestr("3D/3dmodel.model", model)
        z.writestr("Metadata/model_settings.config", model_settings)
    print(f"wrote {out_path} ({os.path.getsize(out_path) // 1024} KB)")


def main():
    scad_path, parts_dir, out_path = sys.argv[1], sys.argv[2], sys.argv[3]
    parts = parse_parts(scad_path)
    if not parts:
        print(f"no @part lines in {scad_path} — nothing to do")
        return

    meshes = []
    for name, _color in parts:
        verts, tris = read_stl(os.path.join(parts_dir, f"part_{name}.stl"))
        print(f"  {name}: {len(verts)} verts, {len(tris)} tris")
        meshes.append((verts, tris))

    design_name = os.path.splitext(os.path.basename(out_path))[0]
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    write_generic(out_path, parts, meshes)
    write_bambu(os.path.splitext(out_path)[0] + "_bambu.3mf",
                design_name, parts, meshes)


if __name__ == "__main__":
    main()
