# Print Flasher — Pre-flasher RA-4

Outil de pre-flashing pour papier photo couleur RA-4, basé sur un Arduino Uno R4 Minima et une matrice LED WS2812 8×8. Le pre-flashing consiste à exposer brièvement le papier à une lumière de faible intensité avant l'exposition principale, pour lever les ombres et/ou introduire une dominante de correction.

## Matériel (BOM)

- 1× Arduino Uno R4 Minima
- 1× Matrice LED WS2812 8×8 (64 LEDs)
- 1× Écran OLED SSD1306 128×64 I2C (adresse `0x3C`)
- 3× Potentiomètres linéaires 10 kΩ (Y, M, durée)
- 2× Boutons poussoirs (NO)
- Câblage, fils dupont

Note : un 4ᵉ potentiomètre peut être prévu physiquement mais n'est **pas câblé** dans cette version.

## Boîtiers 3D

Modèles OpenSCAD paramétriques + STL prêts à imprimer dans [`cad/`](cad/) : une boîte LED suspendue (matrice + plexi opalin) et une boîte de commande aimantée (Arduino + pile 9V + écran + commandes). Voir [`cad/README.md`](cad/README.md) pour les instructions de génération STL, BOM impression et assemblage.

## Câblage

| Composant | Pin Arduino | Remarque |
|---|---|---|
| WS2812 — DIN | D6 | idéalement via résistance 330 Ω (voir « Recommandations électriques ») |
| WS2812 — 5V (V+ IN) | 5V | OK sur USB tant que `MASTER_BRIGHTNESS` ≤ 25 |
| WS2812 — GND (V− IN, sinon V− OUT) | GND | masse commune — voir note ci-dessous |
| OLED — SDA | SDA | broche dédiée du R4 Minima |
| OLED — SCL | SCL | broche dédiée du R4 Minima |
| OLED — VCC | 3V3 ou 5V | selon le module |
| OLED — GND | GND | |
| Bouton START | D2 → GND | `INPUT_PULLUP` côté firmware |
| Bouton OLED | D3 → GND | `INPUT_PULLUP` côté firmware |
| Pot Y (curseur) | A0 | extrémités sur 5V et GND |
| Pot M (curseur) | A1 | idem |
| Pot Durée (curseur) | A2 | idem |

```
            +5V ──┬───────────── WS2812 V+ (IN, côté DIN)
                  │
                  ├── pot Y ── A0
                  ├── pot M ── A1
                  └── pot T ── A2

            GND ──┬───────────── WS2812 V- (IN si soudable, sinon V- OUT)
                  ├── tous les pots (autre extrémité)
                  ├── bouton START ── D2
                  └── bouton OLED  ── D3

            D6 ───────────────── WS2812 DIN (IN)
            SDA ──────────────── OLED SDA
            SCL ──────────────── OLED SCL
```

### Notes sur le montage physique

- **Layout matrice : row-by-row** (pas serpentine). L'indice `i` parcourt la matrice ligne par ligne, gauche → droite, ligne 0 en haut. Pour un motif (row, col), faire `row = i / 8`, `col = i % 8`. C'est pour ça qu'avec `LIT_STRIDE = 2` on voit des **rayures verticales** et pas un damier.
- **GND matrice** : sur cette matrice, le pad V− côté **IN** n'a souvent pas de trou traversant utilisable. Si tu ne peux pas y souder, raccorde le GND côté **OUT** (V− OUT) — électriquement c'est la même masse, mais soigne le contact : une pince crocodile lâche sur ce point est un contributeur classique aux glitches data sur les WS2812.
- **R330 / cap 1000 µF** : absents dans la version actuelle du montage. Le firmware compense par des défenses logicielles (double `show()` après `clear()`, refresh périodique en IDLE). Pour un montage durable ou si tu remontes `MASTER_BRIGHTNESS`, ajoute-les (voir « Recommandations électriques »).
- **Diffuseur** : prévoir un calque / plexi dépoli posé quelques mm au-dessus de la matrice. Le `LIT_STRIDE = 2` économise du courant mais produit un éclairement non uniforme (1 LED sur 2 allumée) — le diffuseur homogénéise.

## Installation des librairies

Dans Arduino IDE → **Tools → Manage Libraries…**, installer :

- `Adafruit NeoPixel` (≥ 1.12.x — version compatible Renesas RA4M1)
- `Adafruit SSD1306`
- `Adafruit GFX Library` (s'installe automatiquement comme dépendance)

Et le board package : **Tools → Board → Boards Manager…**, installer `Arduino UNO R4 Boards`. Sélectionner ensuite `Arduino UNO R4 Minima` comme carte cible.

## Upload

1. Brancher l'Arduino en USB.
2. Sélectionner la carte `Arduino UNO R4 Minima` et le bon port série.
3. Ouvrir `print-flasher.ino`.
4. **Upload**.

## Utilisation

1. **Réglages** (matrice éteinte, OLED affichant les valeurs courantes)
   - Pot Y : densité du filtre **jaune** (atténue le canal bleu). `Y=0` ↔ pas de filtre.
   - Pot M : densité du filtre **magenta** (atténue le canal vert). `M=0` ↔ pas de filtre.
   - Pot Durée : durée du flash, de **0.1 s à 10.0 s** par pas de 0.1 s.
2. **Bouton OLED** (D3) : éteint/rallume l'écran. À utiliser quand le papier est en place pour éviter tout voile parasite.
3. **Bouton START** (D2) :
   - En IDLE : déclenche le flash. L'OLED **n'est pas touché** par ce bouton — si tu veux l'éteindre pour éviter de voiler le papier, appuie sur le bouton OLED **avant** de déclencher.
   - Pendant le flash : ré-appuyer **interrompt** immédiatement l'exposition.
4. Après le flash, brève phase « DONE » (1 s) puis retour automatique en IDLE.

### Mapping couleur (rappel)

Le firmware simule une filtration soustractive d'agrandisseur :

| Sortie LED | Formule | Effet |
|---|---|---|
| Rouge | `255` (constant) | pas de filtre cyan disponible |
| Vert  | `255 − M` | M filtre le vert |
| Bleu  | `255 − Y` | Y filtre le bleu |

- `Y=0,   M=0`   → blanc (les 3 canaux à fond, ramené à 10 % par `MASTER_BRIGHTNESS`).
- `Y=255, M=255` → rouge pur.
- `Y=0,   M=255` → magenta.
- `Y=255, M=0`   → jaune.

## Sécurité / Recommandations électriques

Le firmware fixe `MASTER_BRIGHTNESS = 25` (≈ 10 % de la luminosité max). À ce niveau :

- Pic de courant matrice ≈ **380 mA** (vs. ~3.8 A à 100 %), ce qui rentre dans les **500 mA fournis par USB** sur l'Uno R4 Minima.
- Tu peux fonctionner **sans** résistance série sur la data ni condensateur de découplage, mais c'est du proto — pas du définitif.

Si tu veux remonter `MASTER_BRIGHTNESS` au-delà de ~40, ou si la matrice fait des couleurs erratiques :

- **Résistance 330 Ω** en série entre D6 et l'entrée DIN de la première LED.
- **Condensateur 1000 µF** entre +5V et GND au plus près de la matrice.
- **Alim 5V externe ≥ 4 A**, masse commune avec l'Arduino (ne **pas** alimenter la matrice par la broche 5V de l'Arduino dans ce cas).

L'OLED émet aussi de la lumière : le bouton D3 le coupe à la demande. Le firmware **ne touche jamais** à l'état physique de l'OLED de lui-même (notamment pas pendant un flash) — c'est à toi de l'éteindre via D3 avant l'exposition si tu veux éviter tout voile parasite. Pendant le flash, le rafraîchissement du contenu est suspendu mais l'écran reste dans l'état que tu as choisi.

## Workflow conseillé

1. Avec une chute de RA-4 et ton workflow d'expo habituel, faire une **bande test pre-flash** : par exemple `Y=20, M=10, Durée=0.5 s`, puis varier la durée par paliers (0.3 / 0.5 / 0.7 / 1.0 s).
2. Une fois la **durée** calée (intensité globale du pre-flash), affiner la **balance Y/M** pour ajuster la dominante.
3. Garder une fiche des valeurs qui marchent par type de papier / type de négatif (le firmware ne mémorise pas les presets pour l'instant).

## Constantes ajustables (dans le `.ino`)

| Constante | Défaut | Effet |
|---|---|---|
| `MASTER_BRIGHTNESS` | `25` | Luminosité globale 0–255. **Ne pas dépasser 40 sur USB seul.** |
| `MIN_DURATION_MS` / `MAX_DURATION_MS` | `100` / `10000` | Plage du pot durée |
| `DURATION_STEP_MS` | `100` | Pas de quantification de la durée |
| `DEBOUNCE_MS` | `15` | Anti-rebond software des boutons |
| `OLED_REFRESH_MS` | `50` | Cadence max de rafraîchissement OLED (20 Hz, redessine seulement si valeurs changent) |
| `ANALOG_SAMPLES` | `8` | Taille de la moyenne glissante sur les pots |
| `ANALOG_SAMPLE_INTERVAL_MS` | `5` | Intervalle entre 2 échantillonnages des pots (8 × 5 ms = fenêtre de filtrage de 40 ms) |
