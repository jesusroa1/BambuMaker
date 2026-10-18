// "Welcome to the Wedding of Chelsea & Jesus" mirror sign — TOP HALF.
// Thin single-color (white) lettering that sticks onto a mirror. Traced from
// the supplied sign mock-up; hairlines were thickened to ~1 mm so they print
// with a 0.4 mm nozzle and survive being peeled off the bed.
//
// The full sign is ~210 x 385 mm, too big for the A1 Mini, so it is split
// across two designs that share one coordinate system:
//   chelsea_jesus_mirror_sign_top    — "Welcome to" / "the Wedding of" / "Chelsea"
//   chelsea_jesus_mirror_sign_bottom — "&" / "Jesus" / "November 1, 2026"
// "THE WEDDING OF" is ~210 mm wide, so "the" prints as its own piece.
//
// Set layout = "sign" to preview the pieces where they sit on the mirror
// (not printable in one go); "plate" (default) packs them for printing.
//
// On the mirror (default size), centred left-to-right:
//   "Welcome to"            -> 11.5 mm gap ->
//   "the" + 10 mm + "Wedding of" (bottoms aligned) -> 56 mm gap ->
//   "Chelsea" (76 mm tall)  -> then the bottom-half pieces
//
// Prints flat, no supports. Script letters are mostly connected, but the
// serif caps are separate letters: before lifting the print off the plate,
// lay painter's / transfer tape over each line so the letters come up
// together with their spacing, add a thin adhesive to the back, place it on
// the mirror and peel the tape.
//
// SIZE FLAG: plate is ~164 x 137 mm at the default settings (Chelsea is
// ~164 mm wide). Fits the A1 Mini's 170 mm safety margin; if name_height is
// raised much past 76 mm the plate layout will no longer fit.
//
// Suggested: white PLA, 0.2 mm layers (0.6 mm = 3 layers), smooth or
// textured plate depending on the finish you want on the mirror side.
//
// @param name_height 76.2
// @param thickness 0.6
// @param piece_gap 5

name_height = 76.2;    // height of "Chelsea", mm (3 in)
thickness   = 0.6;     // label thickness, mm
piece_gap   = 5;       // spacing between pieces on the print plate, mm
layout      = "plate"; // "plate" (print) | "sign" (as placed on the mirror)

// --- Traced artwork geometry (sign coordinates, mm at name_height 76.2) ---
art_name_height = 76.2;
sign_center     = [148, 244];   // centre of the whole sign (both halves)

// [svg file, [min x, min y], [width, height], plate row]
pieces = [
    ["welcome_to.svg", [ 67.6, 419.0], [158.0, 16.6], 0],
    ["the.svg",        [ 43.1, 391.2], [ 44.4, 11.8], 1],
    ["wedding_of.svg", [ 97.9, 390.9], [154.9, 16.5], 2],
    ["chelsea.svg",    [ 60.3, 258.2], [163.5, 77.0], 3],
];

art_scale = name_height / art_name_height;

// Plate: pieces sharing a row sit side by side; rows are centred and
// stacked top to bottom.
row_count = max([for (p = pieces) p[3]]) + 1;

function row_height(r) = max([for (p = pieces) if (p[3] == r) p[2][1]]);
function row_width(r) =
    sum([for (p = pieces) if (p[3] == r) p[2][0] + piece_gap]) - piece_gap;
function sum(v, i = 0) = i < len(v) ? v[i] + sum(v, i + 1) : 0;
function upto(n) = n > 0 ? [0 : n - 1] : [];   // 0 .. n-1, empty for n = 0
function rows_above(r) = sum([for (k = upto(r)) row_height(k) + piece_gap]);

plate_height = rows_above(row_count) - piece_gap;

function plate_pos(i) =
    let (r      = pieces[i][3],
         before = sum([for (j = upto(i)) if (pieces[j][3] == r)
                           pieces[j][2][0] + piece_gap]))
    [-row_width(r) / 2 + before,
     plate_height / 2 - rows_above(r) - (row_height(r) + pieces[i][2][1]) / 2];

module piece_art(i) {
    import(pieces[i][0]);
}

linear_extrude(height = thickness)
    scale([art_scale, art_scale])
        for (i = [0 : len(pieces) - 1])
            if (layout == "sign")
                translate(-sign_center) piece_art(i);
            else
                translate(plate_pos(i) - pieces[i][1]) piece_art(i);
