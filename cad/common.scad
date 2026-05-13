// Variables paramétriques partagées entre led_box.scad et control_box.scad.
// Ajuster ces valeurs ici en cas de mesures différentes sur tes composants
// (PCB matrice, écrans OLED, aimants, etc.).

// --- Impression / paroi ---
WALL          = 2.4;   // épaisseur paroi standard (3 perimeters @ 0.4mm)
FLOOR         = 2.0;   // épaisseur fond
LID_TH        = 3.0;   // épaisseur couvercle
LIP_H         = 2.0;   // hauteur lèvre centrage couvercle
LIP_TOL       = 0.3;   // jeu lèvre/corps
$fn           = 64;

// --- Aimants néodyme Ø10×3 ---
MAG_D         = 10;
MAG_H         = 3;
MAG_TOL_D     = 0.2;   // jeu radial
MAG_TOL_H     = 0.2;   // jeu axial

// --- Plexi opalin ---
PLEXI_TH      = 3;
PLEXI_TOL     = 0.4;

// --- Matrice WS2812 ---
MATRIX_PCB    = 65;     // côté PCB
MATRIX_HOLE   = 65;     // côté trou couvercle (= PCB)
MATRIX_MTG    = 58;     // entraxe trous fixation PCB (à valider)
MATRIX_MTG_D  = 2.5;    // Ø trou plot (vis M2.5 autotaraudeuse)
MATRIX_POST_D = 5;      // Ø bossage plot
MATRIX_POST_H = 3;      // hauteur plot (sous-élève PCB)

// --- Composants panneau ---
POT_HOLE      = 7.2;    // Ø trou pot R09 (axe Ø6 + filetage M7)
BTN_HOLE      = 12.2;   // Ø trou bouton poussoir 12mm
OLED_WIN_W    = 24;     // fenêtre écran
OLED_WIN_H    = 14;
OLED_OUTER    = 27.5;   // PCB OLED 0.96"
OLED_MTG_DX   = 23;     // entraxe vis OLED
OLED_MTG_DY   = 23.5;
OLED_MTG_D    = 1.8;    // Ø trou vis OLED (M2 autotaraudeuse)
OLED_POST_D   = 4;
OLED_POST_H   = 4;

// --- Arduino Uno R4 Minima ---
// Trous officiels (origine = coin bas-gauche du PCB) :
//   (15.24, 2.54), (15.24, 50.80), (66.04, 7.62), (66.04, 35.56)
// (datasheet Arduino Uno — l'R4 Minima reprend le même form-factor)
ARDUINO_W     = 53.34;
ARDUINO_L     = 68.85;
ARDUINO_POST_D= 6;
ARDUINO_HOLE  = 2.5;    // M3 autotaraudeuse
ARDUINO_POST_H= 5;

// --- Pile 9V PP3 ---
PP3_L         = 48.5;
PP3_W         = 26.5;
PP3_H         = 17.5;
PP3_TOL       = 1.0;    // jeu cale pile (large : enfile/retire à la main)

// --- Interrupteur rocker 15×10mm (trou panneau 13×8mm) ---
ROCKER_HOLE_W = 13.2;
ROCKER_HOLE_H = 8.2;

// --- Câble inter-boîtes ---
CABLE_HOLE_D  = 6.0;    // Ø passe-câble

// --- Helpers ---

// Boîte creuse ouverte vers le haut : pavé extérieur dim, paroi WALL, fond FLOOR.
module hollow_box(dim, wall=WALL, floor=FLOOR) {
    difference() {
        cube(dim);
        translate([wall, wall, floor])
            cube([dim.x - 2*wall, dim.y - 2*wall, dim.z - floor + 0.1]);
    }
}

// Logement aimant (cylindre soustractif) — orienté Z+, ouverture vers le haut.
module magnet_pocket() {
    cylinder(d=MAG_D + MAG_TOL_D, h=MAG_H + MAG_TOL_H);
}

// Plot vissable cylindrique : bossage extérieur Ø post_d, trou Ø hole_d, hauteur h.
module screw_post(post_d, hole_d, h) {
    difference() {
        cylinder(d=post_d, h=h);
        translate([0, 0, -0.1])
            cylinder(d=hole_d, h=h + 0.2);
    }
}
