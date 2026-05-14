// Boîte de commande — abrite l'Arduino Uno R4 Minima, la pile 9V (PP3),
// l'interrupteur rocker (côté droit), et sur le couvercle :
// OLED + 3 pots Y/M/T + 2 boutons GO/OLED (tous Ø7.2).
// Câble vers la boîte LED sort par la paroi gauche.
//
// Architecture : paroi mince + rebord épaissi + plaque plate.
// Aimants Ø5×2.78 : 6 en fermeture (rebord), 4 au dos (bossages internes
// au fond, débouchent sur la face extérieure pour aimanter à la tête
// d'agrandisseur). 2 ergots d'alignement.
//
// Génération STL :
//   openscad -o stl/control_box_body.stl -D 'PART="body"' control_box.scad
//   openscad -o stl/control_box_lid.stl  -D 'PART="lid"'  control_box.scad

include <common.scad>

// --- Dimensions extérieures ---
BOX_X = 150;
BOX_Y = 90;
BOX_Z = 35;

// --- Zone Arduino (PCB Uno R4 Minima, coin bas-gauche du PCB) ---
ARDUINO_X = 10;
ARDUINO_Y = 18;
// Trous officiels Uno (origine PCB)
ARDUINO_HOLES = [
    [15.24,  2.54],
    [15.24, 50.80],
    [66.04,  7.62],
    [66.04, 35.56]
];

// --- Zone pile 9V (à droite de l'Arduino) ---
PP3_X      = 95;
PP3_Y      = (BOX_Y - PP3_L) / 2;
PP3_OUT_W  = PP3_W + PP3_TOL;
PP3_OUT_L  = PP3_L + PP3_TOL;
RIB_TH     = 1.6;
RIB_H      = 16;

// --- Interrupteur rocker (paroi droite X+) ---
ROCKER_Y = BOX_Y / 2;
ROCKER_Z = 17;

// --- Sortie câble : encoche en haut du rebord, paroi gauche X− ---
// Décalée de la position du mid-aimant gauche (Y=BOX_Y/2=45) pour ne pas le chevaucher.
CABLE_NOTCH_Y = 70;

// --- Panneau frontal : 5 trous Ø7.2 uniformément espacés ---
PANEL_Y    = 25;
HOLE_Xs    = [15, 30, 45, 60, 75];   // Y, M, T, GO, OLED
HOLE_LABELS= ["Y", "M", "T", "GO", "OLED"];

// --- OLED ---
OLED_CX = 25;  OLED_CY = 65;

// --- Aimants fermeture (6 sur le rebord) ---
mag_positions = [
    [15,                  MAG_PKT_OFFSET],
    [BOX_X - 15,          MAG_PKT_OFFSET],
    [15,                  BOX_Y - MAG_PKT_OFFSET],
    [BOX_X - 15,          BOX_Y - MAG_PKT_OFFSET],
    [MAG_PKT_OFFSET,      BOX_Y / 2],
    [BOX_X - MAG_PKT_OFFSET, BOX_Y / 2]
];

// --- Ergots d'alignement (2 coins diagonalement opposés) ---
peg_positions = [
    [MAG_PKT_OFFSET,         MAG_PKT_OFFSET],
    [BOX_X - MAG_PKT_OFFSET, BOX_Y - MAG_PKT_OFFSET]
];

// --- Aimants arrière (4 au dos, sur le fond, vers la tête d'agrandisseur) ---
back_mag_positions = [
    [15,         15],
    [BOX_X - 15, 15],
    [15,         BOX_Y - 15],
    [BOX_X - 15, BOX_Y - 15]
];

// ─────────────────────────────────────────────────────────────────────────
module control_box_body() {
    difference() {
        union() {
            stepped_box([BOX_X, BOX_Y, BOX_Z]);
            // Plots Arduino
            for (h = ARDUINO_HOLES) {
                translate([ARDUINO_X + h.x, ARDUINO_Y + h.y, FLOOR])
                    screw_post(ARDUINO_POST_D, ARDUINO_HOLE, ARDUINO_POST_H);
            }
            // Cale pile 9V (4 nervures en U)
            translate([PP3_X - RIB_TH, PP3_Y - RIB_TH, FLOOR])
                cube([RIB_TH, PP3_OUT_L + 2*RIB_TH, RIB_H]);
            translate([PP3_X + PP3_OUT_W, PP3_Y - RIB_TH, FLOOR])
                cube([RIB_TH, PP3_OUT_L + 2*RIB_TH, RIB_H]);
            translate([PP3_X - RIB_TH, PP3_Y - RIB_TH, FLOOR])
                cube([PP3_OUT_W + 2*RIB_TH, RIB_TH, RIB_H]);
            translate([PP3_X - RIB_TH, PP3_Y + PP3_OUT_L, FLOOR])
                cube([PP3_OUT_W + 2*RIB_TH, RIB_TH, RIB_H]);
            // Bossages internes pour aimants arrière (sur la face supérieure du fond)
            for (p = back_mag_positions) floor_boss(p);
            // Ergots d'alignement
            for (p = peg_positions) rim_peg(p, BOX_Z);
        }
        // Trou rocker paroi droite
        translate([BOX_X - WALL - 0.1, ROCKER_Y - ROCKER_HOLE_W/2, ROCKER_Z - ROCKER_HOLE_H/2])
            cube([WALL + 0.2, ROCKER_HOLE_W, ROCKER_HOLE_H]);
        // Passe-câble : encoche en haut du rebord, paroi gauche
        cable_notch("L", CABLE_NOTCH_Y, [BOX_X, BOX_Y, BOX_Z]);
        // Aimants fermeture (rebord)
        for (p = mag_positions) rim_mag_pocket(p, BOX_Z);
        // Aimants arrière (carvés depuis la face extérieure du fond, à travers le bossage)
        for (p = back_mag_positions) floor_mag_pocket(p);
    }
}

// ─────────────────────────────────────────────────────────────────────────
module control_box_lid() {
    difference() {
        union() {
            cube([BOX_X, BOX_Y, LID_TH]);
            // Plots OLED (à l'intérieur, sous le couvercle)
            translate([OLED_CX, OLED_CY, 0])
                for (sx = [-1, 1], sy = [-1, 1]) {
                    translate([sx * OLED_MTG_DX/2, sy * OLED_MTG_DY/2, -OLED_POST_H])
                        screw_post(OLED_POST_D, OLED_MTG_D, OLED_POST_H);
                }
        }
        // Fenêtre OLED
        translate([OLED_CX - OLED_WIN_W/2, OLED_CY - OLED_WIN_H/2, -0.1])
            cube([OLED_WIN_W, OLED_WIN_H, LID_TH + 0.2]);
        // 5 trous panneau (pots + boutons, Ø7.2 uniformes)
        for (x = HOLE_Xs) {
            translate([x, PANEL_Y, -0.1])
                cylinder(d=POT_HOLE, h=LID_TH + 0.2);
        }
        // Logements aimants miroirs du corps
        for (p = mag_positions) lid_mag_pocket(p);
        // Trous d'ergots
        for (p = peg_positions) lid_peg_hole(p);
        // Marquages gravés (debossé sur la face supérieure)
        ENGRAVE = 0.6;
        translate([0, 0, LID_TH - ENGRAVE]) {
            for (i = [0 : len(HOLE_Xs) - 1]) {
                translate([HOLE_Xs[i], PANEL_Y + 8, 0])
                    linear_extrude(ENGRAVE + 0.1)
                        text(HOLE_LABELS[i], size=3.5, halign="center", valign="center",
                             font="Liberation Sans:style=Bold");
            }
            // Logo sur la moitié droite libre
            translate([115, 60, 0])
                linear_extrude(ENGRAVE + 0.1)
                    text("PRINT", size=6, halign="center", valign="center",
                         font="Liberation Sans:style=Bold");
            translate([115, 50, 0])
                linear_extrude(ENGRAVE + 0.1)
                    text("FLASHER", size=6, halign="center", valign="center",
                         font="Liberation Sans:style=Bold");
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────
PART = "both";

if      (PART == "body") control_box_body();
else if (PART == "lid")  translate([0, 0, BOX_Z + 10]) control_box_lid();
else {
    control_box_body();
    translate([BOX_X + 10, 0, 0]) control_box_lid();
}
