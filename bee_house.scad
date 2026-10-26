// Bee House
// A hexagonal honeycomb block for solitary bees and other pollinators, on a
// solid backing plate that screws onto a fence, post or wall.
//
//  - Every honeycomb cell is a nesting tube, closed at the back by the plate
//  - Only whole cells are cut, so a solid rim runs all the way around
//  - Rounded outer corners, rounded cells and softened top and bottom edges
//  - The backing plate sticks out past the honeycomb, with a mounting hole
//    at each of its six corners
//
// Printing: print as modeled, backing plate on the bed. The cells are
// straight vertical holes, so no supports are needed.
$fn = 48;

/* [Color] */
print_color = "#EFE6D2"; // beige / off-white

/* [Size] */
plate_r     = 50;   // Point-to-point radius of the honeycomb [20:80]
thickness   = 30;   // How thick the honeycomb is [2:50]

/* [Backing plate] */
back_over   = 10;   // How far the backing sticks out past the honeycomb [0:1:25]
back_t      = 3;    // Backing plate thickness [1:0.5:8]
hole_d      = 4;    // Mounting hole diameter [1:0.5:6]
hole_in     = 5;    // How far the holes sit in from each corner [1:0.5:12]

/* [Honeycomb] */
cell_r      = 6;    // Size of one honeycomb cell [3:0.5:15]
wall        = 2;    // Material between neighboring cells [1:0.2:6]

/* [Edges] */
corner_out  = 4;    // Roundover on the six outer corners [0:0.5:10]
corner_cell = 1.2;  // Roundover on each honeycomb cell [0:0.2:3]
ease        = 0.4;  // How softened the top and bottom edges are [0:0.1:2]

steps       = 3;    // layers used to approximate that softened edge

// spacing between cell centers: flat-to-flat width plus one wall
pitch = sqrt(3) * cell_r + wall;

// distance from the middle out to one of the six flat sides
plate_flat = plate_r * cos(30);

// radius out to the backing plate's six corners
back_r = plate_r + back_over;

// how far a point sits from the center in one of the six side directions
function proj(cx, cy, a) = cx * cos(a) + cy * sin(a);

// true only when the WHOLE cell fits inside, leaving a solid rim all the way around
function on_plate(cx, cy) =
    max(proj(cx, cy, 30),  proj(cx, cy, 90),  proj(cx, cy, 150),
        proj(cx, cy, 210), proj(cx, cy, 270), proj(cx, cy, 330))
    <= plate_flat - cell_r - wall;

// a hexagon with rounded corners: pull the sides in, then grow back with a round tool
module rounded_hex(r, rd) {
    offset(r = rd, $fn = 16)
        offset(delta = -rd)
            circle(r = r, $fn = 6);
}

// rounded plate, minus every cell that fits fully inside the border
module plate_outline() {
    difference() {
        rounded_hex(plate_r, corner_out);

        for (i = [-6 : 6], j = [-6 : 6]) {
            cx = i * pitch * sqrt(3) / 2;
            cy = j * pitch + (i % 2 == 0 ? 0 : pitch / 2);
            if (on_plate(cx, cy))
                translate([cx, cy])
                    rounded_hex(cell_r, corner_cell);
        }
    }
}

// one slice of the plate, shrunk inward by "inset" on every edge and hole
module slice(inset, z, h) {
    translate([0, 0, z])
        linear_extrude(height = h)
            offset(delta = -inset, $fn = 16)
                plate_outline();
}

// a stack of slightly growing slices - reads as a soft rolled edge
module eased_edge() {
    for (k = [0 : steps - 1]) {
        a0 = 90 * k / steps;
        a1 = 90 * (k + 1) / steps;
        z0 = ease * (1 - cos(a0));
        z1 = ease * (1 - cos(a1));
        slice(ease * (1 - sin(a0)), z0, z1 - z0 + 0.01);
    }
}

// the honeycomb block, with its softened top and bottom
module honeycomb_block() {
    union() {
        eased_edge();
        slice(0, ease - 0.01, thickness - 2 * ease + 0.02);
        translate([0, 0, thickness]) mirror([0, 0, 1]) eased_edge();
    }
}

color(print_color)
union() {
    // solid backing plate, wider all around, with six mounting holes
    difference() {
        linear_extrude(height = back_t)
            rounded_hex(back_r, corner_out);

        for (a = [0 : 60 : 300])
            translate([(back_r - hole_in) * cos(a),
                       (back_r - hole_in) * sin(a),
                       -0.01])
                cylinder(d = hole_d, h = back_t + 0.02, $fn = 20);
    }

    // honeycomb sitting on the backing, overlapping slightly so they fuse
    translate([0, 0, back_t - 0.01]) honeycomb_block();
}
