// Variables paramétriques partagées entre led_box.scad et control_box.scad.
// Ajuster ces valeurs ici en cas de mesures différentes sur tes composants
// (PCB matrice, écrans OLED, aimants, etc.).

// --- Impression / paroi ---
WALL          = 2.4;   // épaisseur paroi standard (3 perimeters @ 0.4mm)
FLOOR         = 2.0;   // épaisseur fond
LID_TH        = 4.0;   // épaisseur couvercle (suffisante pour loger l'aimant dans le plat)
$fn           = 64;

// --- Aimants néodyme Ø5×2.78 ---
MAG_D         = 5;
MAG_H         = 2.78;
MAG_TOL_D     = 0.2;
MAG_TOL_H     = 0.2;

// --- Rebord épaissi en haut du corps (loge les aimants) ---
// Le corps a des parois minces (WALL) sur la majeure partie de sa hauteur,
// et une section plus large (RIM_W) sur les RIM_H derniers mm pour pouvoir
// percer un logement Ø(MAG_D+jeu) sans casser la paroi.
RIM_W         = 6.5;                          // largeur rebord (vue de dessus)
RIM_H         = MAG_H + MAG_TOL_H + 1.0;      // hauteur ~4mm : magnet + 1mm de matière "plafond" sous le couvercle
MAG_PKT_OFFSET = RIM_W / 2;                   // 3.25mm : centre du logement, depuis la face extérieure

// --- Ergots d'alignement couvercle/corps (2 par boîte, coins diagonalement opposés) ---
PEG_D         = 2.5;
PEG_H         = 2.0;
PEG_HOLE_D    = 2.9;                          // jeu confortable dans le couvercle
PEG_HOLE_H    = PEG_H + 0.5;

// --- Bossage interne au fond (pour les aimants arrière de la boîte commande) ---
FLOOR_BOSS_W  = MAG_D + 3;                    // 8mm carré
FLOOR_BOSS_H  = MAG_H + MAG_TOL_H + 1.0;      // mesuré depuis la face extérieure du fond

// --- Plexi opalin ---
PLEXI_TH      = 3;
PLEXI_TOL     = 0.4;

// --- Matrice WS2812 ---
MATRIX_PCB    = 65;
MATRIX_HOLE   = 65;
MATRIX_MTG    = 58;
MATRIX_MTG_D  = 2.5;
MATRIX_POST_D = 5;
MATRIX_POST_H = 3;

// --- Composants panneau ---
POT_HOLE      = 7.2;    // Ø trou pot R09
BTN_HOLE      = 7.2;    // Ø trou bouton 6×6mm avec capuchon — corrigé d'après le modèle utilisateur
OLED_WIN_W    = 24;
OLED_WIN_H    = 14;
OLED_OUTER    = 27.5;
OLED_MTG_DX   = 23;
OLED_MTG_DY   = 23.5;
OLED_MTG_D    = 1.8;
OLED_POST_D   = 4;
OLED_POST_H   = 4;

// --- Arduino Uno R4 Minima ---
ARDUINO_W     = 53.34;
ARDUINO_L     = 68.85;
ARDUINO_POST_D= 6;
ARDUINO_HOLE  = 2.5;
ARDUINO_POST_H= 5;

// --- Pile 9V PP3 ---
PP3_L         = 48.5;
PP3_W         = 26.5;
PP3_H         = 17.5;
PP3_TOL       = 1.0;

// --- Interrupteur rocker 15×10mm ---
ROCKER_HOLE_W = 13.2;
ROCKER_HOLE_H = 8.2;

// --- Câble inter-boîtes : encoche en haut de la paroi (au niveau du rebord) ---
// Le câble exit la boîte par une encoche rectangulaire ouverte vers le haut,
// fermée par le couvercle. Imprimable sans support, pas de jonction câble/PCB
// dans la boîte (JST des 2 côtés → câble débrochable des 2 boîtes).
NOTCH_W       = 8.0;    // largeur (Ø câble ~6mm + jeu)
NOTCH_D       = 6.0;    // profondeur depuis le haut du rebord (laisse passer Ø6 confortablement)

// Encoche traversante dans la paroi, ouverte vers Z+.
//   side ∈ "L", "R", "F", "B"
//   t    : position le long de la paroi (Y pour L/R, X pour F/B)
//   box  : [BOX_X, BOX_Y, BOX_Z]
module cable_notch(side, t, box) {
    if (side == "L") {
        translate([-0.1, t - NOTCH_W/2, box.z - NOTCH_D])
            cube([RIM_W + 0.2, NOTCH_W, NOTCH_D + 0.1]);
    } else if (side == "R") {
        translate([box.x - RIM_W - 0.1, t - NOTCH_W/2, box.z - NOTCH_D])
            cube([RIM_W + 0.2, NOTCH_W, NOTCH_D + 0.1]);
    } else if (side == "F") {
        translate([t - NOTCH_W/2, -0.1, box.z - NOTCH_D])
            cube([NOTCH_W, RIM_W + 0.2, NOTCH_D + 0.1]);
    } else if (side == "B") {
        translate([t - NOTCH_W/2, box.y - RIM_W - 0.1, box.z - NOTCH_D])
            cube([NOTCH_W, RIM_W + 0.2, NOTCH_D + 0.1]);
    }
}

// ============================================================================
// Helpers géométriques
// ============================================================================

// Corps de boîte : fond + paroi mince + rebord épaissi en haut.
//   - fond plein de Z=0 à Z=FLOOR
//   - paroi WALL épaisse de Z=FLOOR à Z=dim.z-RIM_H
//   - rebord RIM_W épais de Z=dim.z-RIM_H à Z=dim.z (loge les aimants)
module stepped_box(dim) {
    union() {
        // Fond + paroi mince
        difference() {
            cube([dim.x, dim.y, dim.z - RIM_H]);
            translate([WALL, WALL, FLOOR])
                cube([dim.x - 2*WALL, dim.y - 2*WALL, dim.z - RIM_H + 0.1]);
        }
        // Rebord épaissi
        translate([0, 0, dim.z - RIM_H])
            difference() {
                cube([dim.x, dim.y, RIM_H]);
                translate([RIM_W, RIM_W, -0.1])
                    cube([dim.x - 2*RIM_W, dim.y - 2*RIM_W, RIM_H + 0.2]);
            }
    }
}

// Logement aimant carvé dans le rebord du corps, ouvert vers le haut (Z+).
// L'aimant se glisse depuis le haut avant fermeture, fixé à la cyano.
module rim_mag_pocket(p, box_z) {
    translate([p.x, p.y, box_z - MAG_H - MAG_TOL_H])
        cylinder(d=MAG_D + MAG_TOL_D, h=MAG_H + MAG_TOL_H + 0.1);
}

// Logement aimant dans le couvercle, carvé depuis la face inférieure (Z-).
module lid_mag_pocket(p) {
    translate([p.x, p.y, -0.1])
        cylinder(d=MAG_D + MAG_TOL_D, h=MAG_H + MAG_TOL_H + 0.1);
}

// Ergot d'alignement sur le rebord du corps (cylindre debout au sommet).
module rim_peg(p, box_z) {
    translate([p.x, p.y, box_z])
        cylinder(d=PEG_D, h=PEG_H);
}

// Trou d'ergot dans le couvercle (cylindre soustractif depuis la face inférieure).
module lid_peg_hole(p) {
    translate([p.x, p.y, -0.1])
        cylinder(d=PEG_HOLE_D, h=PEG_HOLE_H);
}

// Bossage interne au fond (pour aimant arrière sur la face extérieure du fond).
// Cube en union, centré sur (p.x, p.y), assis sur la face interne du fond.
module floor_boss(p) {
    translate([p.x - FLOOR_BOSS_W/2, p.y - FLOOR_BOSS_W/2, FLOOR])
        cube([FLOOR_BOSS_W, FLOOR_BOSS_W, FLOOR_BOSS_H - FLOOR]);
}

// Logement aimant dans le fond, carvé depuis la face EXTÉRIEURE (Z=0 vers Z+).
// L'aimant se glisse depuis le dessous, fixé à la cyano.
module floor_mag_pocket(p) {
    translate([p.x, p.y, -0.1])
        cylinder(d=MAG_D + MAG_TOL_D, h=MAG_H + MAG_TOL_H + 0.1);
}

// Plot vissable cylindrique.
module screw_post(post_d, hole_d, h) {
    difference() {
        cylinder(d=post_d, h=h);
        translate([0, 0, -0.1])
            cylinder(d=hole_d, h=h + 0.2);
    }
}
