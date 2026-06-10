# Boîtiers 3D — Print Flasher

Deux boîtes imprimables, reliées par un câble 3 fils :

- **`led_box`** (95×80×30 mm) : abrite la matrice WS2812 8×8 + plexi opalin diffuseur. Se suspend sous la tête de l'agrandisseur par un trou Ø8mm.
- **`control_box`** (150×90×35 mm) : abrite l'Arduino Uno R4 Minima + pile 9V, avec sur le panneau frontal l'OLED, 3 potentiomètres (Y/M/T) et 2 boutons (GO/OLED). Aimantée à la tête de l'agrandisseur ou posée à côté.

## Architecture de fermeture

Les deux boîtes ont la même structure :
- **Corps** = fond + paroi mince (2.4 mm) + **rebord épaissi en haut** (6.5 mm × 4 mm) qui loge les aimants Ø5×2.78mm
- **Couvercle** = simple plaque plate 4 mm, avec logements aimants en miroir
- **Alignement** par 2 ergots Ø2.5×2 mm aux coins diagonalement opposés du rebord
- Les aimants se collent à la cyano dans leurs logements ; le couvercle se "clique" sur le corps

Pour la boîte commande, 4 aimants supplémentaires sont logés dans des **bossages internes au fond** et débouchent sur la face extérieure du dos — c'est ce qui aimante la boîte à la tête métallique de l'agrandisseur.

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
- `MAG_D` / `MAG_H` : pour des aimants d'autre dimensions (par défaut Ø5×2.78)
- `MAG_TOL_D` / `MAG_TOL_H` : si les aimants flottent ou ne rentrent pas dans les logements
- `RIM_W` / `RIM_H` : largeur et hauteur du rebord (par défaut 6.5×4 mm — augmenter si aimants plus gros)
- `POT_HOLE` / `BTN_HOLE` : Ø des trous panneau (par défaut 7.2 mm pour les deux types)

## BOM impression / matériel

| Élément | Quantité | Notes |
|---|---|---|
| PLA noir ou PETG noir | ~150 g | Noir = anti-fuite lumineuse |
| Aimants néodyme Ø5×2.78 mm | 24 | 8 LED fermeture (4 paires) + 12 control fermeture (6 paires) + 4 control arrière (sur fond, contre tête métallique) |
| Plexi opalin 65×65×3 mm | 1 | Diffuseur |
| Vis M2.5×6 autotaraudeuses | 4 | Fixation PCB matrice |
| Vis M3×8 autotaraudeuses | 4 | Fixation Arduino |
| Vis M2×4 autotaraudeuses | 4 | Fixation OLED |
| Câble 3 conducteurs ~22AWG | 80–120 cm | 5V / GND / Data, JST mâle aux 2 bouts |
| JST-XH 3 broches mâle (sur câble) | 2 | Un à chaque extrémité du câble |
| JST-XH 3 broches femelle | 2 | Une dans chaque boîte (soudée aux fils internes) |
| Clip pile 9V | 1 | Connecteur batterie |

## Paramètres slicer conseillés

- Couches : 0.2 mm
- Périmètres : 3 (cohérent avec WALL = 2.4mm sur buse 0.4)
- Infill : 20 % gyroid (boîte commande), 30 % (boîte LED, à cause de la suspension Ø8)
- Supports : aucun (toutes les surfaces critiques sont ≤ 45° de surplomb)
- Orientation : poser chaque pièce **fond/face en bas**, surface visible vers le haut
- Bord (brim) : 5mm si décollage observé sur la boîte commande (grande surface)

## Assemblage

1. **Coller les aimants** dans tous les logements à la cyano. Faire attention à la polarité : pour chaque paire de fermeture, le pôle de l'aimant du couvercle doit attirer celui du corps (tester avec 2 aimants à la main avant de coller). Les 4 aimants arrière de la boîte commande peuvent être collés tous dans le même sens (peu importe lequel — l'autre face est la tête métallique de l'agrandisseur).
1. **Glisser les ergots du corps dans les trous du couvercle** au moment de la fermeture — c'est ce qui empêche le couvercle de glisser latéralement.
2. **Câble inter-boîtes** :
   - Câble 3 conducteurs avec un connecteur JST-XH mâle 3 broches serti à chaque extrémité (commerce ou DIY).
3. **Boîte LED** :
   - Souder 3 fils courts sur le PCB matrice (V+, V−, DIN). V− côté **IN** si soudable, sinon **OUT** (voir [`README.md`](../README.md) racine).
   - Souder l'autre bout de ces 3 fils à une embase JST-XH 3 broches femelle.
   - Visser le PCB matrice sur ses 4 plots (M2.5).
   - Glisser le plexi opalin dans la feuillure du couvercle (par-dessous le couvercle).
   - Brancher le câble inter-boîtes (JST mâle) sur l'embase femelle interne et faire sortir le câble par l'encoche de la paroi droite (au-dessus du trou de fix).
   - Fermer le couvercle (aimants + ergots).
4. **Boîte commande** :
   - Visser l'Arduino sur ses 4 plots (M3).
   - Visser l'OLED sur les 4 plots du couvercle (M2). Souder VCC / GND / SDA / SCL aux pins correspondants.
   - Câbler 3 pots (5V / curseur sur A0,A1,A2 / GND) et 2 boutons (D2,D3 vers GND).
   - Câbler la pile 9V : (+) → VIN Arduino ; (−) → GND Arduino.
   - Glisser la pile 9V entre les 4 nervures de cale.
   - Souder 3 fils dupont 5V / GND / D6 de l'Arduino à une embase JST-XH 3 broches femelle.
   - Brancher le câble inter-boîtes (JST mâle) sur l'embase femelle et faire sortir le câble par l'encoche de la paroi gauche.
   - Fermer le couvercle (aimants + ergots).

Le câble se débranche des deux côtés (JST mâle/femelle aux 2 boîtes) — pratique pour ranger ou remplacer.

## Vérification avant impression

Ouvrir chaque STL dans le slicer et vérifier visuellement :

- **`led_box_body.stl`** : trou Ø8 dans un coin, passe-câble Ø6 sur la même paroi (X+), 4 plots PCB centrés à gauche, rebord épaissi visible en haut avec 4 logements aimants ronds + 2 ergots aux coins.
- **`led_box_lid.stl`** : plaque plate avec trou central 65×65 mm aligné sur le PCB, feuillure plexi visible sur la face inférieure, trou Ø8 dans le coin, 4 logements aimants en miroir + 2 trous d'ergots.
- **`control_box_body.stl`** : plots Arduino à gauche, cale 4 nervures à droite, encoche Ø6 sur paroi gauche, rebord épaissi en haut (6 logements aimants + 2 ergots), 4 bossages internes au fond avec logements aimants traversants (visibles depuis le dessous).
- **`control_box_lid.stl`** : plaque plate avec OLED + 5 trous Ø7.2 uniformes (Y, M, T, GO, OLED), marquages texte des labels décalés ~13 mm au-dessus des trous, logements aimants en miroir + 2 trous d'ergots.

Imprimer **un coin du rebord seul** (5×5×10 mm avec un logement aimant) pour calibrer `MAG_TOL_D` avant l'impression complète.
