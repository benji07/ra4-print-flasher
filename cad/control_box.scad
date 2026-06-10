// Boîte de commande — abrite l'Arduino Uno R4 Minima et la pile 9V (PP3),
// et sur le couvercle : OLED + 3 pots Y/M/T + 2 boutons GO/OLED (tous Ø7.2).
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
BOX_X = 110;
BOX_Y = 78;
BOX_Z = 35;

// --- Zone Arduino (PCB Uno R4 Minima, coin bas-gauche du PCB) ---
ARDUINO_X = 3;
ARDUINO_Y = (BOX_Y - ARDUINO_W) / 2;
// Trous officiels Uno (origine PCB)
ARDUINO_HOLES = [
    [15.24,  2.54],
    [15.24, 50.80],
    [66.04,  7.62],
    [66.04, 35.56]
];

// --- Zone pile 9V (à plat, calée à droite sous le rebord) ---
PP3_OUT_W  = PP3_W + PP3_TOL;    // 27.5 (petit côté, le long de X)
PP3_OUT_L  = PP3_L + PP3_TOL;    // 49.5 (long côté, le long de Y)
RIB_TH     = 1.6;
RIB_H      = 16;
PP3_X      = BOX_X - WALL - 1.6 - RIB_TH - PP3_OUT_W;   // ≈76.9
PP3_Y      = (BOX_Y - PP3_OUT_L) / 2;                   // ≈14.25, nervures symétriques

// --- Sortie câble : encoche en haut du rebord, paroi gauche X− ---
// Placée entre les aimants gauche Y=39 (milieu) et Y=74.75 (coin) pour ne pas les chevaucher.
CABLE_NOTCH_Y = 58;

// --- Couvercle : cluster regroupé (OLED + 3 pots + 2 boutons) ---
// OLED en haut, 3 pots en ligne sous l'écran (entraxe 25), 2 boutons empilés à droite.
OLED_CX = 40;  OLED_CY = 54;
POT_PITCH = 25;
POT_Y     = 27;
pot_positions = [
    [OLED_CX - POT_PITCH, POT_Y],   // [15, 27]
    [OLED_CX,             POT_Y],   // [40, 27]
    [OLED_CX + POT_PITCH, POT_Y]    // [65, 27]
];
BTN_X     = OLED_CX + POT_PITCH;    // 65 : aligné avec le pot de droite (même colonne)
btn_positions = [
    [BTN_X, 46],
    [BTN_X, 64]
];

// --- Aimants fermeture (6 sur le rebord) ---
mag_positions = [
    [12,                  MAG_PKT_OFFSET],
    [BOX_X - 12,          MAG_PKT_OFFSET],
    [12,                  BOX_Y - MAG_PKT_OFFSET],
    [BOX_X - 12,          BOX_Y - MAG_PKT_OFFSET],
    [MAG_PKT_OFFSET,      BOX_Y / 2],
    [BOX_X - MAG_PKT_OFFSET, BOX_Y / 2]
];

// --- Ergots d'alignement (2 coins diagonalement opposés) ---
peg_positions = [
    [MAG_PKT_OFFSET,         MAG_PKT_OFFSET],
    [BOX_X - MAG_PKT_OFFSET, BOX_Y - MAG_PKT_OFFSET]
];

// --- Aimants arrière (4 au dos, sur le fond, vers la tête d'agrandisseur) ---
// Les 2 du côté gauche sont sous l'Arduino, mais celui-ci est surélevé sur ses
// plots (5mm) donc aucun conflit avec le bossage (~2mm). Les 2 du côté droit sont
// décalés en Y (10 / BOX_Y-10) pour rester HORS de l'empreinte de la pile, qui
// repose directement sur le fond (sinon le bossage soulèverait la pile).
back_mag_positions = [
    [12,         12],
    [BOX_X - 12, 10],
    [12,         BOX_Y - 12],
    [BOX_X - 12, BOX_Y - 10]
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
        // Fenêtre OLED (traversante)
        translate([OLED_CX - OLED_WIN_W/2, OLED_CY - OLED_WIN_H/2, -0.1])
            cube([OLED_WIN_W, OLED_WIN_H, LID_TH + 0.2]);
        // Feuillure (bezel) côté extérieur : amincit la fenêtre à ~1.5mm de membrane
        translate([OLED_CX - OLED_BEZEL_W/2, OLED_CY - OLED_BEZEL_H/2, LID_TH - OLED_BEZEL_D])
            cube([OLED_BEZEL_W, OLED_BEZEL_H, OLED_BEZEL_D + 0.1]);
        // 3 trous pots (en ligne sous l'écran) + 2 trous boutons (empilés à droite)
        for (p = pot_positions)
            translate([p.x, p.y, -0.1]) cylinder(d=POT_HOLE, h=LID_TH + 0.2);
        for (p = btn_positions)
            translate([p.x, p.y, -0.1]) cylinder(d=BTN_HOLE, h=LID_TH + 0.2);
        // Logements aimants miroirs du corps
        for (p = mag_positions) lid_mag_pocket(p);
        // Trous d'ergots
        for (p = peg_positions) lid_peg_hole(p);
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
