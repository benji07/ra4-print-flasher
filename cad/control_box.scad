// Boîte de commande — abrite l'Arduino Uno R4 Minima, la pile 9V (PP3),
// l'interrupteur rocker (côté droit), et sur le couvercle : OLED + 3 pots + 2 boutons.
// Câble vers la boîte LED sort par la paroi gauche.
//
// Génération STL :
//   openscad -o stl/control_box_body.stl -D 'PART="body"' control_box.scad
//   openscad -o stl/control_box_lid.stl  -D 'PART="lid"'  control_box.scad

include <common.scad>

// --- Dimensions extérieures ---
BOX_X = 150;
BOX_Y = 90;
BOX_Z = 35;

// --- Zone Arduino (origine = coin bas-gauche du PCB Arduino, vue de dessus) ---
ARDUINO_X = 10;       // X coin BL du PCB Arduino
ARDUINO_Y = 18;       // Y coin BL du PCB Arduino

// Trous officiels Uno (origine PCB) — l'Uno R4 Minima reprend ce form-factor
ARDUINO_HOLES = [
    [15.24,  2.54],
    [15.24, 50.80],
    [66.04,  7.62],
    [66.04, 35.56]
];

// --- Zone pile 9V (à droite de l'Arduino, axe long de la pile selon Y) ---
// On loge la pile couchée sur sa plus grande face, longueur PP3_L=48.5 selon Y.
PP3_X      = 95;                                  // coin BL de la cale
PP3_Y      = (BOX_Y - PP3_L) / 2;                 // centré en Y
PP3_OUT_W  = PP3_W + PP3_TOL;                     // dim interne X
PP3_OUT_L  = PP3_L + PP3_TOL;                     // dim interne Y
RIB_TH     = 1.6;                                 // épaisseur nervure cale
RIB_H      = 16;                                  // hauteur nervure (< PP3_H pour glisser)

// --- Interrupteur rocker (paroi droite X+) ---
ROCKER_Y = BOX_Y / 2;
ROCKER_Z = 17;        // mi-hauteur

// --- Sortie câble vers boîte LED (paroi gauche X-) ---
CABLE_Y = BOX_Y / 2;
CABLE_Z = BOX_Z / 2;

// --- Composants panneau frontal (positions sur le couvercle, repère lid) ---
OLED_CX  = 25;  OLED_CY  = 65;
POT_Y_X  = 15;  POTS_CY  = 25;
POT_M_X  = 37;
POT_T_X  = 59;
BTN1_X   = 72;  BTNS_CY  = 25;
BTN2_X   = 88;

// --- Aimants ---
MAG_INSET = MAG_H + MAG_TOL_H + 0.5;  // profondeur depuis la face

// Aimants fermeture (rebord supérieur du corps, alignés avec le couvercle)
function lid_mag_positions() = [
    [WALL/2,          WALL/2],
    [WALL/2,          BOX_Y - WALL/2],
    [BOX_X/2,         WALL/2],
    [BOX_X/2,         BOX_Y - WALL/2],
    [BOX_X - WALL/2,  WALL/2],
    [BOX_X - WALL/2,  BOX_Y - WALL/2]
];

// Aimants arrière (FOND extérieur, fixation à la tête d'agrandisseur)
function back_mag_positions() = [
    [10,           10],
    [BOX_X - 10,   10],
    [10,           BOX_Y - 10],
    [BOX_X - 10,   BOX_Y - 10]
];

// ─────────────────────────────────────────────────────────────────────────
// Corps
// ─────────────────────────────────────────────────────────────────────────
module control_box_body() {
    difference() {
        union() {
            hollow_box([BOX_X, BOX_Y, BOX_Z]);
            // Plots Arduino
            for (h = ARDUINO_HOLES) {
                translate([ARDUINO_X + h.x, ARDUINO_Y + h.y, FLOOR])
                    screw_post(ARDUINO_POST_D, ARDUINO_HOLE, ARDUINO_POST_H);
            }
            // Cale pile 9V : 4 nervures verticales en U
            // Deux longues (parallèles à Y) sur les côtés ±X
            translate([PP3_X - RIB_TH, PP3_Y - RIB_TH, FLOOR])
                cube([RIB_TH, PP3_OUT_L + 2*RIB_TH, RIB_H]);
            translate([PP3_X + PP3_OUT_W, PP3_Y - RIB_TH, FLOOR])
                cube([RIB_TH, PP3_OUT_L + 2*RIB_TH, RIB_H]);
            // Deux courtes (parallèles à X) sur les côtés ±Y
            translate([PP3_X - RIB_TH, PP3_Y - RIB_TH, FLOOR])
                cube([PP3_OUT_W + 2*RIB_TH, RIB_TH, RIB_H]);
            translate([PP3_X - RIB_TH, PP3_Y + PP3_OUT_L, FLOOR])
                cube([PP3_OUT_W + 2*RIB_TH, RIB_TH, RIB_H]);
            // Serre-câble interne près du passe-câble (paroi gauche)
            for (dy = [-4, 4]) {
                translate([WALL + 3, CABLE_Y + dy, FLOOR])
                    cylinder(d=2.5, h=BOX_Z/2);
            }
        }
        // Trou rocker paroi droite
        translate([BOX_X - WALL - 0.1, ROCKER_Y - ROCKER_HOLE_W/2, ROCKER_Z - ROCKER_HOLE_H/2])
            cube([WALL + 0.2, ROCKER_HOLE_W, ROCKER_HOLE_H]);
        // Passe-câble paroi gauche
        translate([-0.1, CABLE_Y, CABLE_Z])
            rotate([0, 90, 0])
                cylinder(d=CABLE_HOLE_D, h=WALL + 0.2);
        // Logements aimants fermeture (depuis le HAUT du rebord)
        for (p = lid_mag_positions()) {
            translate([p.x, p.y, BOX_Z - MAG_INSET])
                magnet_pocket();
        }
        // Logements aimants arrière (depuis le DESSOUS, sur le fond extérieur)
        for (p = back_mag_positions()) {
            translate([p.x, p.y, -0.1])
                cylinder(d=MAG_D + MAG_TOL_D, h=MAG_H + MAG_TOL_H + 0.1);
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────
// Couvercle (panneau frontal) : trous OLED + pots + boutons + aimants + lèvre
// ─────────────────────────────────────────────────────────────────────────
module control_box_lid() {
    difference() {
        union() {
            cube([BOX_X, BOX_Y, LID_TH]);
            // Lèvre périphérique (descend dans le corps)
            translate([WALL + LIP_TOL, WALL + LIP_TOL, -LIP_H])
                difference() {
                    cube([
                        BOX_X - 2*(WALL + LIP_TOL),
                        BOX_Y - 2*(WALL + LIP_TOL),
                        LIP_H
                    ]);
                    translate([WALL, WALL, -0.1])
                        cube([
                            BOX_X - 2*(WALL + LIP_TOL) - 2*WALL,
                            BOX_Y - 2*(WALL + LIP_TOL) - 2*WALL,
                            LIP_H + 0.2
                        ]);
                }
            // Plots OLED (à l'intérieur, sous le couvercle)
            translate([OLED_CX, OLED_CY, 0])
                for (sx = [-1, 1], sy = [-1, 1]) {
                    translate([sx * OLED_MTG_DX/2, sy * OLED_MTG_DY/2, -OLED_POST_H])
                        screw_post(OLED_POST_D, OLED_MTG_D, OLED_POST_H);
                }
        }
        // Fenêtre OLED (traversante)
        translate([OLED_CX - OLED_WIN_W/2, OLED_CY - OLED_WIN_H/2, -LIP_H - 0.1])
            cube([OLED_WIN_W, OLED_WIN_H, LID_TH + LIP_H + 0.2]);
        // 3 pots
        for (px = [POT_Y_X, POT_M_X, POT_T_X]) {
            translate([px, POTS_CY, -LIP_H - 0.1])
                cylinder(d=POT_HOLE, h=LID_TH + LIP_H + 0.2);
        }
        // 2 boutons
        for (bx = [BTN1_X, BTN2_X]) {
            translate([bx, BTNS_CY, -LIP_H - 0.1])
                cylinder(d=BTN_HOLE, h=LID_TH + LIP_H + 0.2);
        }
        // Logements aimants (face interne du couvercle)
        for (p = lid_mag_positions()) {
            translate([p.x, p.y, -LIP_H - 0.1])
                cylinder(d=MAG_D + MAG_TOL_D, h=MAG_H + MAG_TOL_H);
        }
        // Marquages gravés (debossé 0.6mm depuis la face supérieure)
        ENGRAVE = 0.6;
        translate([0, 0, LID_TH - ENGRAVE]) {
            // Y / M / T au-dessus des pots
            for (item = [["Y", POT_Y_X], ["M", POT_M_X], ["T", POT_T_X]]) {
                translate([item[1], POTS_CY + 8, 0])
                    linear_extrude(ENGRAVE + 0.1)
                        text(item[0], size=4, halign="center", valign="center",
                             font="Liberation Sans:style=Bold");
            }
            // GO / OLED au-dessus des boutons
            translate([BTN1_X, BTNS_CY + 10, 0])
                linear_extrude(ENGRAVE + 0.1)
                    text("GO", size=3.5, halign="center", valign="center",
                         font="Liberation Sans:style=Bold");
            translate([BTN2_X, BTNS_CY + 10, 0])
                linear_extrude(ENGRAVE + 0.1)
                    text("OLED", size=3, halign="center", valign="center",
                         font="Liberation Sans:style=Bold");
            // Logo / titre sur la moitié droite libre
            translate([115, 55, 0])
                linear_extrude(ENGRAVE + 0.1)
                    text("PRINT", size=6, halign="center", valign="center",
                         font="Liberation Sans:style=Bold");
            translate([115, 45, 0])
                linear_extrude(ENGRAVE + 0.1)
                    text("FLASHER", size=6, halign="center", valign="center",
                         font="Liberation Sans:style=Bold");
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────
PART = "both"; // "body" | "lid" | "both"

if      (PART == "body") control_box_body();
else if (PART == "lid")  translate([0, 0, BOX_Z + 10]) control_box_lid();
else {
    control_box_body();
    translate([BOX_X + 10, 0, 0]) control_box_lid();
}
