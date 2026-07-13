// Norwegian rower cake topper — four-color layered relief.
// Based on the supplied side-view illustration and simplified for an AMS Lite:
// white backing, warm gold hair/skin, Norwegian red, and dark navy linework.
//
// Prints flat with the relief face upward. The figure, oar, boat rail, paddle,
// and stake form one connected backing, so there are no loose islands.
// SIZE FLAG: approximately 161 x 161 mm at the default scale, including the
// integral stake. This fits inside the A1 Mini's 170 mm safety margin.
// No supports are required.
//
// @part base #FFFFFF
// @part gold #F2B84B
// @part red #D71920
// @part navy #0A2443
//
// @param base_thickness 1.6
// @param color_relief 0.6
// @param scale_factor 0.128

base_thickness = 1.6;
color_relief   = 0.6;
scale_factor   = 0.128;

part = "all"; // "all" | "base" | "gold" | "red" | "navy"

canvas = 1254;

scale([scale_factor, scale_factor, 1])
translate([-canvas / 2, -canvas / 2, 0]) {
    if (part == "all" || part == "base")
        linear_extrude(height = base_thickness)
            import("topper_base.svg");

    if (part == "all" || part == "gold")
        translate([0, 0, base_thickness])
            linear_extrude(height = color_relief)
                import("topper_gold.svg");

    if (part == "all" || part == "red")
        translate([0, 0, base_thickness])
            linear_extrude(height = color_relief)
                import("topper_red.svg");

    if (part == "all" || part == "navy")
        translate([0, 0, base_thickness])
            linear_extrude(height = color_relief)
                import("topper_navy.svg");
}
