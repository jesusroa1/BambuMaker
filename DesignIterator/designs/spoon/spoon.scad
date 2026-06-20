// BambuMaker: Spoon
// @param bowl_length 55
// @param bowl_width 40
// @param bowl_depth 10
// @param handle_length 110
// @param handle_width 13
// @param wall 2

bowl_length   = 55;
bowl_width    = 40;
bowl_depth    = 10;
handle_length = 110;
handle_width  = 13;
wall          = 2;

$fn = 64;

// Hollow dome bowl
module bowl() {
    difference() {
        scale([bowl_length/2, bowl_width/2, bowl_depth])
            sphere(1);
        // Scoop out the inside
        translate([0, 0, wall])
            scale([bowl_length/2 - wall, bowl_width/2 - wall, bowl_depth])
                sphere(1);
        // Flatten the bottom for bed adhesion
        translate([0, 0, -bowl_depth - 0.1])
            cube([bowl_length*2, bowl_width*2, bowl_depth*2], center=true);
    }
}

// Flat tapered handle
module handle() {
    hull() {
        translate([bowl_length/2, 0, 0])
            cube([0.01, handle_width, wall], center=true);
        translate([bowl_length/2 + handle_length, 0, 0])
            cube([0.01, handle_width * 0.5, wall], center=true);
    }
}

bowl();
handle();
