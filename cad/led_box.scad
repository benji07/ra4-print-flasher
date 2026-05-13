// Boîte LED — abrite la matrice WS2812 8×8, suspendue sous la tête d'agrandisseur.
// Le câble et le trou de suspension Ø8 sont sur la même paroi (X+).
//
// Génération STL :
//   openscad -o stl/led_box_body.stl -D 'PART="body"' led_box.scad
//   openscad -o stl/led_box_lid.stl  -D 'PART="lid"'  led_box.scad

include <common.scad>

// --- Dimensions extérieures ---
BOX_X = 90;
BOX_Y = 75;
BOX_Z = 30;

// --- Trou de fixation suspension ---
FIX_HOLE_D    = 8.0;
FIX_BOSS_D    = 14.0;       // bossage de renfort autour du trou
FIX_CORNER_X  = BOX_X - 8;  // coin bas-droit
FIX_CORNER_Y  = 8;

// --- PCB matrice (collé au côté gauche, X-) ---
PCB_OFFSET_X  = WALL + 5;
PCB_OFFSET_Y  = (BOX_Y - MATRIX_PCB) / 2;
PCB_CENTER_X  = PCB_OFFSET_X + MATRIX_PCB / 2;
PCB_CENTER_Y  = BOX_Y / 2;

// --- Trou couvercle (aligné sur le PCB, pas centré dans la plaque) ---
HOLE_CENTER_X = PCB_CENTER_X;
HOLE_CENTER_Y = PCB_CENTER_Y;

// --- Sortie câble (paroi droite X+, près du trou de fix pour suivre l'axe de suspension) ---
CABLE_Z       = BOX_Z / 2;
CABLE_Y       = FIX_CORNER_Y + FIX_BOSS_D/2 + 5; // juste au-dessus du bossage de renfort

// --- Aimants fermeture (4 sur le rebord supérieur, milieu de chaque côté) ---
// Faces : -X (gauche), +X (droite, décalé), -Y (avant), +Y (arrière)
MAG_INSET     = MAG_H + MAG_TOL_H + 0.5;     // profondeur logement depuis face sup
MAG_FROM_TOP  = 1;                           // distance bord supérieur

// Positions de centres de logements aimants (X, Y) — debouchent vers le BAS (couvercle dessus)
function mag_positions() = [
    [WALL/2,         BOX_Y/2],          // gauche
    [BOX_X - WALL/2, BOX_Y - 15],       // droite, en haut (loin du câble qui est en bas)
    [BOX_X/2,        WALL/2],           // devant
    [BOX_X/2,        BOX_Y - WALL/2]    // derrière
];

// ─────────────────────────────────────────────────────────────────────────
// Corps : boîte creuse + plots PCB + bossage fix + passe-câble + aimants
// ─────────────────────────────────────────────────────────────────────────
module led_box_body() {
    difference() {
        union() {
            hollow_box([BOX_X, BOX_Y, BOX_Z]);
            // Bossage de renfort autour du trou de fixation (intérieur + extérieur)
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
            // Serre-câble interne (2 petits pions de chaque côté du passe-câble)
            for (dy = [-4, 4]) {
                translate([BOX_X - WALL - 3, CABLE_Y + dy, FLOOR])
                    cylinder(d=2.5, h=BOX_Z/2);
            }
        }
        // Trou de fixation Ø8 traversant
        translate([FIX_CORNER_X, FIX_CORNER_Y, -0.1])
            cylinder(d=FIX_HOLE_D, h=BOX_Z + 0.2);
        // Passe-câble dans paroi droite
        translate([BOX_X + 0.1, CABLE_Y, CABLE_Z])
            rotate([0, -90, 0])
                cylinder(d=CABLE_HOLE_D, h=WALL + 0.2);
        // Logements aimants — débouchent depuis le HAUT, à -MAG_INSET sous le bord
        for (p = mag_positions()) {
            translate([p.x, p.y, BOX_Z - MAG_INSET])
                magnet_pocket();
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────
// Couvercle : plaque + trou matrice + feuillure plexi + lèvre + aimants + trou fix
// ─────────────────────────────────────────────────────────────────────────
module led_box_lid() {
    difference() {
        union() {
            // Plaque
            cube([BOX_X, BOX_Y, LID_TH]);
            // Lèvre périphérique (descend dans le corps)
            translate([WALL + LIP_TOL, WALL + LIP_TOL, -LIP_H])
                difference() {
                    cube([
                        BOX_X - 2*(WALL + LIP_TOL),
                        BOX_Y - 2*(WALL + LIP_TOL),
                        LIP_H
                    ]);
                    // Creux pour matérialiser la lèvre (anneau, pas un bloc plein)
                    translate([WALL, WALL, -0.1])
                        cube([
                            BOX_X - 2*(WALL + LIP_TOL) - 2*WALL,
                            BOX_Y - 2*(WALL + LIP_TOL) - 2*WALL,
                            LIP_H + 0.2
                        ]);
                }
        }
        // Trou central matrice (traverse plaque + lèvre)
        translate([
            HOLE_CENTER_X - MATRIX_HOLE/2,
            HOLE_CENTER_Y - MATRIX_HOLE/2,
            -LIP_H - 0.1
        ])
            cube([MATRIX_HOLE, MATRIX_HOLE, LID_TH + LIP_H + 0.2]);
        // Feuillure plexi sur la face inférieure (intérieur de la boîte)
        translate([
            HOLE_CENTER_X - (MATRIX_HOLE + 2)/2,
            HOLE_CENTER_Y - (MATRIX_HOLE + 2)/2,
            -LIP_H - 0.1
        ])
            cube([MATRIX_HOLE + 2, MATRIX_HOLE + 2, PLEXI_TH + PLEXI_TOL]);
        // Trou de fixation Ø8 aligné sur celui du corps
        translate([FIX_CORNER_X, FIX_CORNER_Y, -LIP_H - 0.1])
            cylinder(d=FIX_HOLE_D, h=LID_TH + LIP_H + 0.2);
        // Logements aimants — débouchent depuis le BAS du couvercle (face interne)
        for (p = mag_positions()) {
            translate([p.x, p.y, -LIP_H - 0.1])
                cylinder(d=MAG_D + MAG_TOL_D, h=MAG_H + MAG_TOL_H);
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────
// Rendu — sélectionne la pièce via -D 'PART="body"' ou "lid"
// ─────────────────────────────────────────────────────────────────────────
PART = "both"; // "body" | "lid" | "both"

if      (PART == "body") led_box_body();
else if (PART == "lid")  translate([0, 0, BOX_Z + 10]) led_box_lid();
else {
    led_box_body();
    translate([BOX_X + 10, 0, 0]) led_box_lid();
}
