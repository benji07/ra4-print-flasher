// Boîte LED — abrite la matrice WS2812 8×8, suspendue sous la tête d'agrandisseur.
// Le câble et le trou de suspension Ø8 sont sur la même paroi (X+).
//
// Architecture : paroi mince (WALL) + rebord épaissi en haut (RIM_W × RIM_H)
// qui loge les aimants néodyme Ø5×2.78mm.
// Couvercle = simple plaque plate avec logements aimants en miroir,
// alignement par 2 ergots aux coins diagonalement opposés.
//
// Génération STL :
//   openscad -o stl/led_box_body.stl -D 'PART="body"' led_box.scad
//   openscad -o stl/led_box_lid.stl  -D 'PART="lid"'  led_box.scad

include <common.scad>

// --- Dimensions extérieures ---
BOX_X = 95;
BOX_Y = 80;
BOX_Z = 30;

// --- Trou de fixation suspension ---
FIX_HOLE_D    = 8.0;
FIX_BOSS_D    = 14.0;
FIX_CORNER_X  = BOX_X - 8;
FIX_CORNER_Y  = 8;

// --- PCB matrice (collé au côté gauche X−, centré en Y) ---
PCB_OFFSET_X  = 7;
PCB_OFFSET_Y  = (BOX_Y - MATRIX_PCB) / 2;
PCB_CENTER_X  = PCB_OFFSET_X + MATRIX_PCB / 2;
PCB_CENTER_Y  = BOX_Y / 2;

// --- Trou couvercle aligné sur le PCB ---
HOLE_CENTER_X = PCB_CENTER_X;
HOLE_CENTER_Y = PCB_CENTER_Y;

// --- Sortie câble : encoche en haut du rebord, paroi droite X+, au-dessus du bossage de fix ---
CABLE_NOTCH_Y = FIX_CORNER_Y + FIX_BOSS_D/2 + 5;  // 20mm — au-dessus du bossage

// --- Positions aimants (4 sur le rebord, 1 par côté) ---
mag_positions = [
    [MAG_PKT_OFFSET,           BOX_Y / 2],          // gauche
    [BOX_X - MAG_PKT_OFFSET,   BOX_Y - 15],         // droite (haute, loin du câble bas)
    [BOX_X / 2,                MAG_PKT_OFFSET],     // devant
    [BOX_X / 2,                BOX_Y - MAG_PKT_OFFSET] // derrière
];

// --- Ergots d'alignement (2 coins diagonalement opposés du rebord) ---
peg_positions = [
    [MAG_PKT_OFFSET,           MAG_PKT_OFFSET],
    [BOX_X - MAG_PKT_OFFSET,   BOX_Y - MAG_PKT_OFFSET]
];

// ─────────────────────────────────────────────────────────────────────────
module led_box_body() {
    difference() {
        union() {
            stepped_box([BOX_X, BOX_Y, BOX_Z]);
            // Bossage de renfort autour du trou de fixation (intérieur)
            translate([FIX_CORNER_X, FIX_CORNER_Y, 0])
                cylinder(d=FIX_BOSS_D, h=BOX_Z);
            // Plots PCB matrice
            for (sx = [-1, 1], sy = [-1, 1]) {
                translate([
                    PCB_CENTER_X + sx * MATRIX_MTG/2,
                    PCB_CENTER_Y + sy * MATRIX_MTG/2,
                    FLOOR
                ])
                    screw_post(MATRIX_POST_D, MATRIX_MTG_D, MATRIX_POST_H);
            }
            // Ergots d'alignement
            for (p = peg_positions) rim_peg(p, BOX_Z);
        }
        // Trou de fixation Ø8 traversant
        translate([FIX_CORNER_X, FIX_CORNER_Y, -0.1])
            cylinder(d=FIX_HOLE_D, h=BOX_Z + 0.2);
        // Passe-câble : encoche en haut du rebord, paroi droite
        cable_notch("R", CABLE_NOTCH_Y, [BOX_X, BOX_Y, BOX_Z]);
        // Logements aimants dans le rebord
        for (p = mag_positions) rim_mag_pocket(p, BOX_Z);
    }
}

// ─────────────────────────────────────────────────────────────────────────
module led_box_lid() {
    difference() {
        cube([BOX_X, BOX_Y, LID_TH]);
        // Trou central matrice (traversant)
        translate([
            HOLE_CENTER_X - MATRIX_HOLE/2,
            HOLE_CENTER_Y - MATRIX_HOLE/2,
            -0.1
        ])
            cube([MATRIX_HOLE, MATRIX_HOLE, LID_TH + 0.2]);
        // Feuillure plexi sur la face inférieure
        translate([
            HOLE_CENTER_X - (MATRIX_HOLE + 2)/2,
            HOLE_CENTER_Y - (MATRIX_HOLE + 2)/2,
            -0.1
        ])
            cube([MATRIX_HOLE + 2, MATRIX_HOLE + 2, PLEXI_TH + PLEXI_TOL]);
        // Trou Ø8 fixation aligné sur le corps
        translate([FIX_CORNER_X, FIX_CORNER_Y, -0.1])
            cylinder(d=FIX_HOLE_D, h=LID_TH + 0.2);
        // Logements aimants miroirs du corps
        for (p = mag_positions) lid_mag_pocket(p);
        // Trous d'ergots
        for (p = peg_positions) lid_peg_hole(p);
    }
}

// ─────────────────────────────────────────────────────────────────────────
PART = "both";

if      (PART == "body") led_box_body();
else if (PART == "lid")  translate([0, 0, BOX_Z + 10]) led_box_lid();
else {
    led_box_body();
    translate([BOX_X + 10, 0, 0]) led_box_lid();
}
