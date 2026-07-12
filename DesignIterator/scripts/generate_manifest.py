#!/usr/bin/env python3
"""
Scans designs/*/ for .scad files, extracts @param comments,
reads git log, and writes docs/manifest.json.
"""

import os
import json
import re
import subprocess
from datetime import datetime, timezone

DESIGNS_DIR = "designs"
OUTPUT_PATH = "docs/manifest.json"


def git_log(path, fmt):
    try:
        result = subprocess.run(
            ["git", "log", "-1", f"--pretty={fmt}", "--", path],
            capture_output=True, text=True
        )
        return result.stdout.strip()
    except Exception:
        return ""


def extract_params(scad_path):
    params = {}
    with open(scad_path, encoding="utf-8") as f:
        for line in f:
            m = re.match(r"//\s*@param\s+(\w+)\s+(.+)", line.strip())
            if m:
                params[m.group(1)] = m.group(2).strip()
    return params


def main():
    designs = []

    if not os.path.isdir(DESIGNS_DIR):
        print(f"No '{DESIGNS_DIR}' directory found.")
        return

    for name in sorted(os.listdir(DESIGNS_DIR)):
        scad_path = os.path.join(DESIGNS_DIR, name, f"{name}.scad")
        if not os.path.exists(scad_path):
            continue

        params = extract_params(scad_path)

        last_commit = git_log(scad_path, "%s") or "initial design"
        raw_date   = git_log(scad_path, "%ci")
        updated    = raw_date[:10] if raw_date else datetime.now(timezone.utc).strftime("%Y-%m-%d")

        stl_path     = f"designs/{name}/{name}.stl"
        threemf_path = f"designs/{name}/{name}.3mf"
        bambu_path   = f"designs/{name}/{name}_bambu.3mf"
        preview_path = f"designs/{name}/preview.png"

        # Check whether compiled artifacts actually exist
        stl_exists     = os.path.exists(os.path.join("docs", stl_path))
        threemf_exists = os.path.exists(os.path.join("docs", threemf_path))
        bambu_exists   = os.path.exists(os.path.join("docs", bambu_path))
        preview_exists = os.path.exists(os.path.join("docs", preview_path))

        designs.append({
            "name":       name,
            "stl":        stl_path     if stl_exists     else None,
            "threeMF":    threemf_path if threemf_exists else None,
            "bambu3MF":   bambu_path   if bambu_exists   else None,
            "preview":    preview_path if preview_exists else None,
            "params":     params,
            "lastCommit": last_commit,
            "updated":    updated,
        })

    manifest = {
        "designs":   designs,
        "generated": datetime.now(timezone.utc).isoformat(),
    }

    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)

    print(f"✓ manifest.json — {len(designs)} design(s)")


if __name__ == "__main__":
    main()
