// Pre-flasher RA-4 — Arduino Uno R4 Minima
// Matrice WS2812 8x8 + OLED SSD1306 128x64 I2C + 3 pots + 2 boutons

#include <Adafruit_NeoPixel.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

// --- Pins ---
#define LED_PIN        6
#define BTN_START      2
#define BTN_OLED       3
#define POT_Y         A0
#define POT_M         A1
#define POT_DURATION  A2

// --- Constantes ---
#define NUM_LEDS                    64
#define LIT_STRIDE                   2     // n'allume qu'une LED sur N (1=toutes, 2=moitie, 4=quart)
#define MASTER_BRIGHTNESS           10     // 0-255, ~4 % (plus bas = plus de plage utile sur le pot duree)
#define MIN_DURATION_MS            100
#define MAX_DURATION_MS          10000
#define DURATION_STEP_MS           100
#define DURATION_STEPS             ((MAX_DURATION_MS - MIN_DURATION_MS) / DURATION_STEP_MS + 1)
#define DEBOUNCE_MS                 15
#define OLED_REFRESH_MS             50
#define ANALOG_SAMPLES               8
#define ANALOG_SAMPLE_INTERVAL_MS    5
#define DONE_DURATION_MS          1000

// --- OLED ---
#define SCREEN_WIDTH  128
#define SCREEN_HEIGHT  64
#define OLED_RESET     -1
#define OLED_ADDRESS 0x3C

Adafruit_NeoPixel strip(NUM_LEDS, LED_PIN, NEO_GRB + NEO_KHZ800);
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// --- Etat ---
enum State { IDLE, EXPOSING, DONE };
State currentState = IDLE;

unsigned long exposureStartMs    = 0;
unsigned long exposureDurationMs = MIN_DURATION_MS;
uint8_t       exposureY          = 0;
uint8_t       exposureM          = 0;
unsigned long doneStartMs        = 0;
unsigned long lastOledRefreshMs  = 0;

bool oledUserOn = true;

// Filtrage analogique (moyenne glissante)
uint16_t analogBuf[3][ANALOG_SAMPLES];
uint8_t  analogIdx    = 0;
bool     analogFilled = false;

// --- Boutons ---
struct Button {
  uint8_t pin;
  bool lastReading;
  bool stableState;
  unsigned long lastChangeMs;
};
Button btnStart = { BTN_START, HIGH, HIGH, 0 };
Button btnOled  = { BTN_OLED,  HIGH, HIGH, 0 };

bool handleButton(Button &b) {
  bool reading = digitalRead(b.pin);
  unsigned long now = millis();
  bool pressed = false;
  if (reading != b.lastReading) {
    b.lastReading  = reading;
    b.lastChangeMs = now;
  }
  if ((now - b.lastChangeMs) >= DEBOUNCE_MS && reading != b.stableState) {
    b.stableState = reading;
    if (b.stableState == LOW) pressed = true;  // INPUT_PULLUP : LOW = appuye
  }
  return pressed;
}

// --- Lecture pots filtree ---
void sampleAnalog() {
  analogBuf[0][analogIdx] = analogRead(POT_Y);
  analogBuf[1][analogIdx] = analogRead(POT_M);
  analogBuf[2][analogIdx] = analogRead(POT_DURATION);
  analogIdx = (analogIdx + 1) % ANALOG_SAMPLES;
  if (analogIdx == 0) analogFilled = true;
}

uint16_t getFiltered(uint8_t channel) {
  uint8_t count = analogFilled ? ANALOG_SAMPLES : analogIdx;
  if (count == 0) count = 1;
  uint32_t sum = 0;
  for (uint8_t i = 0; i < count; i++) sum += analogBuf[channel][i];
  return sum / count;
}

uint8_t getYDensity()        { return map(getFiltered(0), 0, 1023, 0, 255); }
uint8_t getMDensity()        { return map(getFiltered(1), 0, 1023, 0, 255); }
unsigned long getDurationMs() {
  uint16_t steps = map(getFiltered(2), 0, 1023, 0, DURATION_STEPS - 1);
  return MIN_DURATION_MS + (unsigned long)steps * DURATION_STEP_MS;
}

// --- Matrice ---
void applyColor(uint8_t y, uint8_t m) {
  uint32_t c = strip.Color(255, 255 - m, 255 - y);
  strip.clear();
  for (uint16_t i = 0; i < NUM_LEDS; i += LIT_STRIDE) {
    strip.setPixelColor(i, c);
  }
  strip.show();
}

void clearStrip() {
  strip.clear();
  strip.show();
  delayMicroseconds(300);  // > 50 us de latch WS2812
  strip.show();            // 2e trame : rattrape un bit corrompu dans la 1ere
}

// --- OLED ---
void oledOn()  { display.ssd1306_command(SSD1306_DISPLAYON);  }
void oledOff() { display.ssd1306_command(SSD1306_DISPLAYOFF); }

void oledShow(uint8_t y, uint8_t m, unsigned long durMs, const char* status) {
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);

  // Zone jaune (y = 0 - 15) : titre + statut
  display.setTextSize(1);
  display.setCursor(0, 0);
  display.print("PRE-FLASH RA-4");
  display.setCursor(0, 8);
  display.print("[ ");
  display.print(status);
  display.print(" ]");

  // Zone bleue (y = 16 - 63) : valeurs Y / M / T
  char buf[24];
  display.setTextSize(2);
  display.setCursor(0, 18);
  snprintf(buf, sizeof(buf), "Y%03u M%03u", y, m);
  display.print(buf);

  unsigned long whole  = durMs / 1000;
  unsigned long tenths = (durMs / 100) % 10;
  display.setCursor(0, 40);
  snprintf(buf, sizeof(buf), "T %02lu.%lus", whole, tenths);
  display.print(buf);

  display.display();
}

// --- Setup ---
void setup() {
  pinMode(BTN_START, INPUT_PULLUP);
  pinMode(BTN_OLED,  INPUT_PULLUP);

  // Matrice : tout a zero AVANT le premier show, paper-safe au boot
  strip.begin();
  strip.setBrightness(MASTER_BRIGHTNESS);
  strip.clear();
  strip.show();
  delayMicroseconds(300);
  strip.show();  // 2e trame pour garantir all-off au demarrage

  // OLED : laisse le charge pump SSD1306 stabiliser, puis retry borne
  delay(100);
  unsigned long oledStartMs = millis();
  while (!display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDRESS)) {
    if (millis() - oledStartMs >= 2000) break;  // abandon apres 2 s si OLED HS
    delay(100);
  }
  display.clearDisplay();
  display.display();
}

// --- Loop ---
void loop() {
  unsigned long now = millis();

  static unsigned long lastAnalogSampleMs = 0;
  if ((now - lastAnalogSampleMs) >= ANALOG_SAMPLE_INTERVAL_MS) {
    lastAnalogSampleMs = now;
    sampleAnalog();
  }

  uint8_t y = getYDensity();
  uint8_t m = getMDensity();
  unsigned long dur = getDurationMs();

  bool startPressed = handleButton(btnStart);
  bool oledPressed  = handleButton(btnOled);

  if (oledPressed) {
    oledUserOn = !oledUserOn;
    if (oledUserOn) oledOn(); else oledOff();
  }

  switch (currentState) {
    case IDLE: {
      static unsigned long lastIdleRefreshMs = 0;
      if ((now - lastIdleRefreshMs) >= 100) {
        lastIdleRefreshMs = now;
        strip.show();  // buffer deja a zero, on re-flush au cas ou une LED a glitche
      }
      if (startPressed) {
        exposureDurationMs = dur;
        exposureStartMs    = now;
        exposureY          = y;
        exposureM          = m;
        applyColor(y, m);
        currentState = EXPOSING;
      }
      break;
    }

    case EXPOSING:
      if (startPressed || (now - exposureStartMs) >= exposureDurationMs) {
        clearStrip();
        doneStartMs = now;
        currentState = DONE;
      }
      break;

    case DONE:
      if ((now - doneStartMs) >= DONE_DURATION_MS) {
        currentState = IDLE;
      }
      break;
  }

  if (oledUserOn && (now - lastOledRefreshMs) >= OLED_REFRESH_MS) {
    lastOledRefreshMs = now;

    uint8_t showY = y;
    uint8_t showM = m;
    unsigned long showDur = dur;
    const char* status = "READY";

    if (currentState == EXPOSING) {
      unsigned long elapsed   = now - exposureStartMs;
      unsigned long remaining = (elapsed >= exposureDurationMs) ? 0 : (exposureDurationMs - elapsed);
      // Arrondi au dixieme superieur : on lit 0.1 juste avant la fin, jamais 0.0
      showDur = ((remaining + DURATION_STEP_MS - 1) / DURATION_STEP_MS) * DURATION_STEP_MS;
      showY   = exposureY;
      showM   = exposureM;
      status  = "EXPOSING";
    } else if (currentState == DONE) {
      status = "DONE";
    }

    static bool prevValid = false;
    static uint8_t prevY, prevM;
    static unsigned long prevDur;
    static State prevState;
    if (!prevValid || showY != prevY || showM != prevM || showDur != prevDur || currentState != prevState) {
      oledShow(showY, showM, showDur, status);
      prevY = showY; prevM = showM; prevDur = showDur; prevState = currentState;
      prevValid = true;
    }
  }
}
