# Boîtiers 3D — Print Flasher

Deux boîtes imprimables, reliées par un câble 3 fils :

- **`led_box`** : abrite la matrice WS2812 8×8 + plexi opalin diffuseur. Se suspend sous la tête de l'agrandisseur par un trou Ø8mm.
- **`control_box`** : abrite l'Arduino Uno R4 Minima + pile 9V + interrupteur, avec sur le panneau frontal l'OLED, 3 potentiomètres (Y/M/T) et 2 boutons (GO/OLED). Aimantée à la tête de l'agrandisseur ou posée à côté.

## Génération des STL

Pré-requis : OpenSCAD installé (`brew install openscad` sur macOS).

Depuis ce dossier :

```bash
openscad -o stl/led_box_body.stl     -D 'PART="body"' led_box.scad
openscad -o stl/led_box_lid.stl      -D 'PART="lid"'  led_box.scad
openscad -o stl/control_box_body.stl -D 'PART="body"' control_box.scad
openscad -o stl/control_box_lid.stl  -D 'PART="lid"'  control_box.scad
```

Pour visualiser en preview avant export : ouvrir un `.scad` dans l'app OpenSCAD, F5 pour preview, F6 pour render.

## Paramètres ajustables

Toutes les dimensions partagées sont dans `common.scad` (tolérances, dimensions composants, épaisseurs paroi). Ajuster en haut du fichier si tes composants diffèrent — par exemple :

- `MATRIX_PCB` / `MATRIX_MTG` : si ton PCB matrice fait autre chose que 65mm avec entraxe 58mm
- `MAG_TOL_D` / `MAG_TOL_H` : si les aimants flottent ou ne rentrent pas
- `LIP_TOL` : si le couvercle est trop serré ou trop libre dans le corps
- `POT_HOLE` / `BTN_HOLE` : si tes pots/boutons ont un Ø différent

## BOM impression / matériel

| Élément | Quantité | Notes |
|---|---|---|
| PLA noir ou PETG noir | ~150 g | Noir = anti-fuite lumineuse |
| Aimants néodyme Ø10×3 mm | 14 | 4 LED fermeture + 6 control fermeture + 4 control arrière |
| Plexi opalin 65×65×3 mm | 1 | Diffuseur |
| Vis M2.5×6 autotaraudeuses | 4 | Fixation PCB matrice |
| Vis M3×8 autotaraudeuses | 4 | Fixation Arduino |
| Vis M2×4 autotaraudeuses | 4 | Fixation OLED |
| Câble 3 conducteurs ~22AWG | 80–120 cm | 5V / GND / Data |
| JST-XH 3 broches mâle + femelle | 1 paire | Connecteur côté commande |
| Clip pile 9V | 1 | Connecteur batterie |
| Interrupteur rocker 15×10mm | 1 | Trou panneau 13×8mm |

## Paramètres slicer conseillés

- Couches : 0.2 mm
- Périmètres : 3 (cohérent avec WALL = 2.4mm sur buse 0.4)
- Infill : 20 % gyroid (boîte commande), 30 % (boîte LED, à cause de la suspension Ø8)
- Supports : aucun (toutes les surfaces critiques sont ≤ 45° de surplomb)
- Orientation : poser chaque pièce **fond/face en bas**, surface visible vers le haut
- Bord (brim) : 5mm si décollage observé sur la boîte commande (grande surface)

## Assemblage

1. **Coller les aimants** dans tous les logements à la cyano (s'assurer de la polarité : couvercle vs corps doivent s'attirer ; aimants arrière de la boîte commande dans le même sens entre eux).
2. **Boîte LED** :
   - Souder le câble 3 fils sur le PCB matrice (V+, V−, DIN). V− côté **IN** si soudable, sinon **OUT** (voir [`README.md`](../README.md) racine).
   - Passer le câble par le trou Ø6 de la paroi droite, faire passer entre les 2 serre-câbles internes.
   - Visser le PCB matrice sur ses 4 plots (M2.5).
   - Glisser le plexi opalin dans la feuillure du couvercle (par-dessous le couvercle).
   - Fermer le couvercle (aimants).
3. **Boîte commande** :
   - Visser l'Arduino sur ses 4 plots (M3).
   - Visser l'OLED sur les 4 plots du couvercle (M2). Souder VCC / GND / SDA / SCL aux pins correspondants.
   - Câbler 3 pots (5V / curseur sur A0,A1,A2 / GND) et 2 boutons (D2,D3 vers GND).
   - Câbler la pile 9V : (+) → interrupteur entrée, interrupteur sortie → VIN Arduino ; (−) → GND Arduino. Clipser le rocker dans son trou latéral.
   - Glisser la pile 9V entre les 4 nervures de cale.
   - Souder l'autre extrémité du câble inter-boîtes à une embase JST-XH 3 broches femelle. Brancher sur le connecteur mâle JST-XH soudé à 3 fils dupont (5V Arduino / GND Arduino / D6 Arduino).
   - Faire passer le câble par le trou Ø6 de la paroi gauche, entre les serre-câbles.
   - Fermer le couvercle (aimants).

## Vérification avant impression

Ouvrir chaque STL dans le slicer et vérifier visuellement :

- **`led_box_body.stl`** : trou Ø8 dans un coin, passe-câble Ø6 sur la même paroi (X+), 4 plots PCB centrés à gauche.
- **`led_box_lid.stl`** : trou central 65×65 mm aligné à gauche (pas centré), feuillure plexi visible en-dessous, trou Ø8 dans le coin.
- **`control_box_body.stl`** : 4 plots Arduino à gauche, cale 4 nervures à droite pour pile, trou rectangulaire rocker sur paroi droite, trou Ø6 sur paroi gauche, 4 logements aimants sur le fond extérieur.
- **`control_box_lid.stl`** : OLED + 3 pots + 2 boutons regroupés à gauche, marquage `PRINT FLASHER` à droite.

Imprimer **un bord de 20mm de haut** avec un logement aimant pour calibrer `MAG_TOL_D` avant l'impression complète.
