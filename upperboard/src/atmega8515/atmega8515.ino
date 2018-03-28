/*
 * AVR keyboard & mouse firmware for Profi 5.06
 * Atmega8515 replacement on Atmega328p :)
 * 
 * @author Andy Karpov <andy.karpov@gmail.com>
 */

#include "ps2.h"
#include "matrix.h"
#include "ps2_codes.h"
#include "ps2mouse.h"

#define DEBUG_MODE 1

// ---- Pins for Atmega328 ----
#define PIN_KBD_CLK 2 // pin 28 (CLKK)
#define PIN_KBD_DAT 4 // pin 27 (DATK)

#define PIN_MOUSE_CLK 3 // pin 26 (CLKM)
#define PIN_MOUSE_DAT 5 // pin 25 (DATM)

#define PIN_AVR_CLK 11 // pin 14 (ATM_ADR0 - CPLD PIN 102)
#define PIN_AVR_RST 12 // pin 5 (ATM_PB4 - CPLD PIN 123)
#define PIN_AVR_DAT 13 // pin 15 (ATM_ADD1 - CPLD PIN 103)

#define PIN_RESET 10 // pin 1 (/RESET)
#define PIN_TURBO 9 //  pin 3 (/TURBO)
#define PIN_MAGIC 8 //  pin 2 (ATM_/MAGIC)

/*
// ---- Pins for Atmega8515 ----
// Profi upper board modifications:
// 1) replace crystal with 16MHz
// 2) add wire between D34:28 and D34:13
#define PIN_KBD_CLK_ORIG 23 // pin 28 (CLKK)
#define PIN_KBD_CLK 11 // pin 13 must be connected to pin 28.
#define PIN_KBD_DAT 22 // pin 27 (DATK)

#define PIN_MOUSE_CLK 21 // pin 26 (CLKM)
#define PIN_MOUSE_DAT 20 // pin 25 (DATM)

#define PIN_AVR_CLK 12 // pin 14 (ATM_ADR0 - CPLD PIN 102)
#define PIN_AVR_RST 4 // pin 5 (ATM_PB4 - CPLD PIN 123)
#define PIN_AVR_DAT 13 // pin 15 (ATM_ADD1 - CPLD PIN 103)

#define PIN_RESET 0 // pin 1 (/RESET)
#define PIN_TURBO 2 //  pin 3 (/TURBO)
#define PIN_MAGIC 1 //  pin 2 (ATM_/MAGIC)
*/

PS2KeyRaw kbd;
PS2Mouse mouse(PIN_MOUSE_CLK, PIN_MOUSE_DAT);

bool matrix[ZX_MATRIX_SIZE];
bool profi_mode = true; // false = zx spectrum mode
bool is_turbo = false; // turbo toggle
bool mouse_present = false; // mouse present flag
long t = 0;

void fill_kbd_matrix(int sc)
{

  static bool is_up=false, is_e=false, is_e1=false;
  static bool is_ctrl=false, is_alt=false, is_del=false;

  // is extended scancode prefix
  if (sc == 0xE0) {
    is_e = 1;
    return;
  }

 if (sc == 0xE1) {
    is_e = 1;
    is_e1 = 1;
    return;
  }

  // is key released prefix
  if (sc == 0xF0 && !is_up) {
    is_up = 1;
    return;
  }

  int scancode = sc + ((is_e || is_e1) ? 0x100 : 0);

  switch (scancode) {
  
    // Shift -> SS for Profi, CS for ZX
    case PS2_L_SHIFT: 
    case PS2_R_SHIFT:
      matrix[profi_mode ? ZX_K_SS : ZX_K_CS] = !is_up;
      break;

    // Ctrl -> CS for Profi, SS for ZX
    case PS2_L_CTRL:
    case PS2_R_CTRL:
      matrix[profi_mode ? ZX_K_CS : ZX_K_SS] = !is_up;
      is_ctrl = !is_up;
      break;

    // Alt (L) -> SS+Enter for Profi, SS+CS for ZX
    case PS2_L_ALT:
      matrix[ZX_K_SS] = !is_up;
      matrix[profi_mode ? ZX_K_ENT : ZX_K_CS] = !is_up;
      is_alt = !is_up;
      break;

    // Alt (R) -> SS + Space for Profi, SS+CS for ZX
    case PS2_R_ALT:
      matrix[ZX_K_SS] = !is_up;
      matrix[profi_mode ? ZX_K_SP : ZX_K_CS] = !is_up;
      is_alt = !is_up;
      break;

    // Del -> P+b6 for Profi, SS+C for ZX
    case PS2_DELETE:
      if (profi_mode) {
         matrix[ZX_K_P] = !is_up;
         matrix[ZX_K_BIT6] = !is_up;
      } else {
        matrix[ZX_K_SS] = !is_up;
        matrix[ZX_K_C] =  !is_up;
      }
      is_del = !is_up;
    break;

    // Ins -> O+b6 for Profi, SS+A for ZX
    case PS2_INSERT:
      if (profi_mode) {
        matrix[ZX_K_O] = !is_up;
        matrix[ZX_K_BIT6] = !is_up;
      } else {
        matrix[ZX_K_SS] = !is_up;
        matrix[ZX_K_A] =  !is_up;
      }
    break;

    // Cursor -> CS + 5,6,7,8
    case PS2_UP:
      matrix[ZX_K_CS] = !is_up;
      matrix[ZX_K_7] = !is_up;
      break;
    case PS2_DOWN:
      matrix[ZX_K_CS] = !is_up;
      matrix[ZX_K_6] = !is_up;
      break;
    case PS2_LEFT:
      matrix[ZX_K_CS] = !is_up;
      matrix[ZX_K_5] = !is_up;
      break;
    case PS2_RIGHT:
      matrix[ZX_K_CS] = !is_up;
      matrix[ZX_K_8] = !is_up;
      break;

    // ESC -> CS+1 for Profi, CS+SPACE for ZX
    case PS2_ESC:
      matrix[ZX_K_CS] = !is_up;
      matrix[profi_mode ? ZX_K_1 : ZX_K_SP] = !is_up;
      break;

    // Backspace -> CS+0
    case PS2_BACKSPACE:
      matrix[ZX_K_CS] = !is_up;
      matrix[ZX_K_0] = !is_up;
      break;

    // Enter
    case PS2_ENTER:
    case PS2_KP_ENTER:
      matrix[ZX_K_ENT] = !is_up;
      break;

    // Space
    case PS2_SPACE:
      matrix[ZX_K_SP] = !is_up;
      break;

    // Letters & numbers
    case PS2_A: matrix[ZX_K_A] = !is_up; break;
    case PS2_B: matrix[ZX_K_B] = !is_up; break;
    case PS2_C: matrix[ZX_K_C] = !is_up; break;
    case PS2_D: matrix[ZX_K_D] = !is_up; break;
    case PS2_E: matrix[ZX_K_E] = !is_up; break;
    case PS2_F: matrix[ZX_K_F] = !is_up; break;
    case PS2_G: matrix[ZX_K_G] = !is_up; break;
    case PS2_H: matrix[ZX_K_H] = !is_up; break;
    case PS2_I: matrix[ZX_K_I] = !is_up; break;
    case PS2_J: matrix[ZX_K_J] = !is_up; break;
    case PS2_K: matrix[ZX_K_K] = !is_up; break;
    case PS2_L: matrix[ZX_K_L] = !is_up; break;
    case PS2_M: matrix[ZX_K_M] = !is_up; break;
    case PS2_N: matrix[ZX_K_N] = !is_up; break;
    case PS2_O: matrix[ZX_K_O] = !is_up; break;
    case PS2_P: matrix[ZX_K_P] = !is_up; break;
    case PS2_Q: matrix[ZX_K_Q] = !is_up; break;
    case PS2_R: matrix[ZX_K_R] = !is_up; break;
    case PS2_S: matrix[ZX_K_S] = !is_up; break;
    case PS2_T: matrix[ZX_K_T] = !is_up; break;
    case PS2_U: matrix[ZX_K_U] = !is_up; break;
    case PS2_V: matrix[ZX_K_V] = !is_up; break;
    case PS2_W: matrix[ZX_K_W] = !is_up; break;
    case PS2_X: matrix[ZX_K_X] = !is_up; break;
    case PS2_Y: matrix[ZX_K_Y] = !is_up; break;
    case PS2_Z: matrix[ZX_K_Z] = !is_up; break;

    // digits
    case PS2_0: matrix[ZX_K_0] = !is_up; break;
    case PS2_1: matrix[ZX_K_1] = !is_up; break;
    case PS2_2: matrix[ZX_K_2] = !is_up; break;
    case PS2_3: matrix[ZX_K_3] = !is_up; break;
    case PS2_4: matrix[ZX_K_4] = !is_up; break;
    case PS2_5: matrix[ZX_K_5] = !is_up; break;
    case PS2_6: matrix[ZX_K_6] = !is_up; break;
    case PS2_7: matrix[ZX_K_7] = !is_up; break;
    case PS2_8: matrix[ZX_K_8] = !is_up; break;
    case PS2_9: matrix[ZX_K_9] = !is_up; break;

    // Keypad digits
    case PS2_KP_0: matrix[ZX_K_0] = !is_up; break;
    case PS2_KP_1: matrix[ZX_K_1] = !is_up; break;
    case PS2_KP_2: matrix[ZX_K_2] = !is_up; break;
    case PS2_KP_3: matrix[ZX_K_3] = !is_up; break;
    case PS2_KP_4: matrix[ZX_K_4] = !is_up; break;
    case PS2_KP_5: matrix[ZX_K_5] = !is_up; break;
    case PS2_KP_6: matrix[ZX_K_6] = !is_up; break;
    case PS2_KP_7: matrix[ZX_K_7] = !is_up; break;
    case PS2_KP_8: matrix[ZX_K_8] = !is_up; break;
    case PS2_KP_9: matrix[ZX_K_9] = !is_up; break;

    // Quote -> SS+P
    case PS2_QUOTE:
      matrix[ZX_K_SS] = !is_up;
      matrix[ZX_K_P] = !is_up;
      break;

    // , -> SS+N
    case PS2_COMMA:
      matrix[ZX_K_SS] = !is_up;
      matrix[ZX_K_N] = !is_up;
      break;

    // . -> SS+M
    case PS2_PERIOD:
    case PS2_KP_PERIOD:
      matrix[ZX_K_SS] = !is_up;
      matrix[ZX_K_M] = !is_up;
      break;

    // ;,: -> SS+O
    case PS2_SEMICOLON:
      matrix[ZX_K_SS] = !is_up;
      matrix[ZX_K_O] = !is_up;
      break;

    // [,{ -> SS+Y
    case PS2_L_BRACKET:
      matrix[ZX_K_SS] = !is_up;
      matrix[ZX_K_Y] = !is_up;
      break;

    // ],} -> SS+U
    case PS2_R_BRACKET:
      matrix[ZX_K_SS] = !is_up;
      matrix[ZX_K_U] = !is_up;
      break;

    // /,? -> SS+V
    case PS2_SLASH:
    case PS2_KP_SLASH:
      matrix[ZX_K_SS] = !is_up;
      matrix[ZX_K_V] = !is_up;
      break;

    // \,| -> SS+D
    case PS2_BACK_SLASH:
      matrix[ZX_K_SS] = !is_up;
      matrix[ZX_K_D] = !is_up;
      break;

    // =,+ -> SS+L
    case PS2_EQUALS:
      matrix[ZX_K_SS] = !is_up;
      matrix[ZX_K_L] = !is_up;
      break;

    // -,_ -> SS+J
    case PS2_MINUS:
      matrix[ZX_K_SS] = !is_up;
      matrix[ZX_K_J] = !is_up;
      break;

    // `,~ -> SS+7
    case PS2_ACCENT:
      matrix[ZX_K_SS] = !is_up;
      matrix[ZX_K_7] = !is_up;
      break;

    // Keypad * -> SS+B
    case PS2_KP_STAR:
      matrix[ZX_K_SS] = !is_up;
      matrix[ZX_K_B] = !is_up;
      break;

    // Keypad - -> SS+J
    case PS2_KP_MINUS:
      matrix[ZX_K_SS] = !is_up;
      matrix[ZX_K_J] = !is_up;
      break;

    // Keypad + -> SS+K
    case PS2_KP_PLUS:
      matrix[ZX_K_SS] = !is_up;
      matrix[ZX_K_K] = !is_up;
      break;

    // Tab
    case PS2_TAB:
      matrix[ZX_K_CS] = !is_up;
      matrix[ZX_K_I] = !is_up;
      break;

    // CapsLock
    case PS2_CAPS:
      matrix[ZX_K_SS] = !is_up;
      matrix[ZX_K_CS] = !is_up;
      break;

    // PgUp -> M+BIT6 for Profi, CS+3 for ZX
    case PS2_PGUP:
      if (profi_mode) {
        matrix[ZX_K_M] = !is_up;
        matrix[ZX_K_BIT6] = !is_up;        
      } else {
        matrix[ZX_K_CS] = !is_up;
        matrix[ZX_K_3] = !is_up;
      }
      break;

    // PgDn -> N+BIT6 for Profi, CS+4 for ZX
    case PS2_PGDN:
      if (profi_mode) {
        matrix[ZX_K_N] = !is_up;
        matrix[ZX_K_BIT6] = !is_up;        
      } else {
        matrix[ZX_K_CS] = !is_up;
        matrix[ZX_K_4] = !is_up;
      }
      break;

    // Home -> K+BIT6 for Profi
    case PS2_HOME:
      matrix[ZX_K_K] = !is_up;
      matrix[ZX_K_BIT6] = !is_up;
      break;

    // End -> L+BIT6 for Profi
    case PS2_END:
      matrix[ZX_K_L] = !is_up;
      matrix[ZX_K_BIT6] = !is_up;
      break;


    // Fn keys
    case PS2_F1: matrix[ZX_K_A] = !is_up; matrix[ZX_K_BIT6] = !is_up; break;
    case PS2_F2: matrix[ZX_K_B] = !is_up; matrix[ZX_K_BIT6] = !is_up; break;
    case PS2_F3: matrix[ZX_K_C] = !is_up; matrix[ZX_K_BIT6] = !is_up; break;
    case PS2_F4: matrix[ZX_K_D] = !is_up; matrix[ZX_K_BIT6] = !is_up; break;
    case PS2_F5: matrix[ZX_K_E] = !is_up; matrix[ZX_K_BIT6] = !is_up; break;
    case PS2_F6: matrix[ZX_K_F] = !is_up; matrix[ZX_K_BIT6] = !is_up; break;
    case PS2_F7: matrix[ZX_K_G] = !is_up; matrix[ZX_K_BIT6] = !is_up; break;
    case PS2_F8: matrix[ZX_K_H] = !is_up; matrix[ZX_K_BIT6] = !is_up; break;
    case PS2_F9: matrix[ZX_K_I] = !is_up; matrix[ZX_K_BIT6] = !is_up; break;
    case PS2_F10: matrix[ZX_K_J] = !is_up; matrix[ZX_K_BIT6] = !is_up; break;
    case PS2_F11: matrix[ZX_K_Q] = !is_up; matrix[ZX_K_SS] = !is_up; break;
    case PS2_F12: matrix[ZX_K_W] = !is_up; matrix[ZX_K_SS] = !is_up; break;

    // Scroll Lock -> Turbo
    case PS2_SCROLL: 
      if (is_up) {
        is_turbo = !is_turbo;
        digitalWrite(PIN_TURBO, is_turbo ? LOW : HIGH);
      }
    break;

    // PrtScr -> Mode profi / zx
    case PS2_PSCR1:
      if (is_up) {
        profi_mode = !profi_mode;
      }
    break;

    // TODO:
    // Windows L / Home -> SS+F
    // Windiws R / End -> SS+G
  
  }

  // Ctrl+Alt+Del -> RESET
  digitalWrite(PIN_RESET, (is_ctrl && is_alt && is_del) ? LOW : HIGH);

   // clear flags
   is_up = 0;
   if (is_e1) {
    is_e1 = 0;
   } else {
     is_e = 0;
   }
}

void transmit_matrix()
{
    // reset the address
    digitalWrite(PIN_AVR_RST, HIGH);
    delayMicroseconds(1);
    digitalWrite(PIN_AVR_RST, LOW);
    delayMicroseconds(1);

    // transmit the matrix
    for(int i=0; i<ZX_MATRIX_SIZE; i++) {
    	digitalWrite(PIN_AVR_DAT, matrix[i]);

    	digitalWrite(PIN_AVR_CLK, HIGH);
    	delayMicroseconds(1);
    	digitalWrite(PIN_AVR_CLK, LOW);
    	delayMicroseconds(1);
    }

    // low data line
    digitalWrite(PIN_AVR_DAT, LOW);
    delayMicroseconds(1);
}

void setup()
{
#if DEBUG_MODE
    Serial.begin(115200);
    Serial.println(F("ZX Keyboard v1.0"));
#endif

// 8515 trick
#ifdef PIN_KBD_CLK_ORIG
  pinMode(PIN_KBD_CLK_ORIG, INPUT);
#endif 

  pinMode(PIN_KBD_CLK, INPUT_PULLUP);
  pinMode(PIN_KBD_DAT, INPUT_PULLUP);

  pinMode(PIN_MOUSE_CLK, INPUT_PULLUP);
  pinMode(PIN_MOUSE_DAT, INPUT_PULLUP);
  
  // serial interface setup
  pinMode(PIN_AVR_CLK, OUTPUT);
  pinMode(PIN_AVR_RST, OUTPUT);
  pinMode(PIN_AVR_DAT, OUTPUT);
  digitalWrite(PIN_AVR_CLK, LOW);
  digitalWrite(PIN_AVR_RST, LOW);
  digitalWrite(PIN_AVR_DAT, LOW);

  pinMode(PIN_RESET, OUTPUT);
  digitalWrite(PIN_RESET, HIGH);

  pinMode(PIN_TURBO, OUTPUT);
  digitalWrite(PIN_TURBO, HIGH);

  pinMode(PIN_MAGIC, OUTPUT);
  digitalWrite(PIN_MAGIC, HIGH);

  // all keys up
  for (int i=0; i<ZX_MATRIX_SIZE; i++) {
      matrix[i] = false;
  }

  kbd.begin(PIN_KBD_DAT, PIN_KBD_CLK);
  mouse_present = mouse.initialize();
#if DEBUG_MODE
  if (!mouse_present) {
    Serial.println(F("Mouse does not exists"));
  } else {
    Serial.println(F("Mouse present"));
  }
#endif
}

void loop()
{
  if (kbd.available()) {
    int c = kbd.read();
    //Serial.println(c, HEX);
    fill_kbd_matrix(c);
  }

  long n = millis();

  if (mouse_present && n - t > 100) {

    MouseData m = mouse.readData();

    matrix[ZX_M_X0] = bitRead(m.position.x, 0);
    matrix[ZX_M_X1] = bitRead(m.position.x, 1);
    matrix[ZX_M_X2] = bitRead(m.position.x, 2);
    matrix[ZX_M_X3] = bitRead(m.position.x, 3);
    matrix[ZX_M_X4] = bitRead(m.position.x, 4);
    matrix[ZX_M_X5] = bitRead(m.position.x, 5);
    matrix[ZX_M_X6] = bitRead(m.position.x, 6);
    matrix[ZX_M_X7] = bitRead(m.position.x, 7);

    matrix[ZX_M_Y0] = bitRead(m.position.y, 0);
    matrix[ZX_M_Y1] = bitRead(m.position.y, 1);
    matrix[ZX_M_Y2] = bitRead(m.position.y, 2);
    matrix[ZX_M_Y3] = bitRead(m.position.y, 3);
    matrix[ZX_M_Y4] = bitRead(m.position.y, 4);
    matrix[ZX_M_Y5] = bitRead(m.position.y, 5);
    matrix[ZX_M_Y6] = bitRead(m.position.y, 6);
    matrix[ZX_M_Y7] = bitRead(m.position.y, 7);

    matrix[ZX_M_B1] = bitRead(m.status, 0);
    matrix[ZX_M_B2] = bitRead(m.status, 1);
    matrix[ZX_M_B3] = bitRead(m.status, 2);

    matrix[ZX_M_S0] = bitRead(m.wheel, 3);
    matrix[ZX_M_S1] = bitRead(m.wheel, 4);
    matrix[ZX_M_S2] = bitRead(m.wheel, 5);
    matrix[ZX_M_S3] = bitRead(m.wheel, 6);

    matrix[ZX_M_NEW_PACKET] = !matrix[ZX_M_NEW_PACKET];

    t = n;

#if DEBUG_MODE
    Serial.print(m.status, BIN);
    Serial.print(F("\tx="));
    Serial.print(m.position.x);
    Serial.print(F("\ty="));
    Serial.print(m.position.y);
    Serial.print(F("\tw="));
    Serial.print(m.wheel);
    Serial.println();
#endif

  }
  
  // transmit
  transmit_matrix();
}

