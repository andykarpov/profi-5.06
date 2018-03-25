/*
 * Atmega8515 firmware for Profi 5.06
 * @author <andy.karpov@gmail.com>
 */

#include "ps2.h"
#include "matrix.h"
#include "ps2_codes.h"

#define PIN_KBD_CLK 2 // pin 28 (CLKK)
#define PIN_KBD_DAT 4 // pin 27 (DATK)

//#define PIN_MOUSE_CLK 3 // pin 26 (CLKM)
//#define PIN_MOUSE_DAT 5 // pin 25 (DATM)

#define PIN_AVR_CLK 11 // pin 14 (ATM_ADR0 - CPLD PIN 102)
#define PIN_AVR_RST 12 // pin 5 (ATM_PB4 - CPLD PIN 123)
#define PIN_AVR_DAT 13 // pin 15 (ATM_ADD1 - CPLD PIN 103)

PS2KeyRaw kbd;
//PS2KeyRaw mouse;

bool matrix[ZX_MATRIX_SIZE];

void fill_kbd_matrix(int sc)
{

  static unsigned char is_up=0, is_e=0;
  static unsigned char is_ctrl=0, is_alt=0, is_del=0;
  unsigned char i;

  // is extended scancode prefix
  if (sc == 0xE0) {
    is_e = 1;
    return;
  }

  // is key released prefix
  if (sc == 0xF0 && !is_up) {
    is_up = 1;
    return;
  }

  int scancode = sc + ((is_e) ? 0x100 : 0);

  switch (scancode) {
  
    // Shift -> CS
    case PS2_L_SHIFT: 
    case PS2_R_SHIFT:
      matrix[ZX_K_CS] = !is_up;
      break;

    // Ctrl -> SS
    case PS2_L_CTRL:
    case PS2_R_CTRL:
      matrix[ZX_K_SS] = !is_up;
      is_ctrl = !is_up;
      break;

    // Alt (L/R) -> CS+SS
    case PS2_L_ALT:
    case PS2_R_ALT:
      matrix[ZX_K_SS] = !is_up;
      matrix[ZX_K_CS] = !is_up;
      is_alt = !is_up;
      break;

    // Del -> SS+C
    case PS2_DELETE:
      matrix[ZX_K_SS] = !is_up;
      matrix[ZX_K_C] =  !is_up;
      is_del = !is_up;
    break;

    // Ins -> SS+A
    case PS2_INSERT:
      matrix[ZX_K_SS] = !is_up;
      matrix[ZX_K_A] =  !is_up;
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

    // ESC -> CS+SPACE
    case PS2_ESC:
      matrix[ZX_K_CS] = !is_up;
      matrix[ZX_K_SP] = !is_up;
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

    // Fn keys
    case PS2_F1: matrix[ZX_K_F1] = !is_up; break;
    case PS2_F2: matrix[ZX_K_F2] = !is_up; break;
    case PS2_F3: matrix[ZX_K_F3] = !is_up; break;
    case PS2_F4: matrix[ZX_K_F4] = !is_up; break;
    case PS2_F5: matrix[ZX_K_F5] = !is_up; break;
    case PS2_F6: matrix[ZX_K_F6] = !is_up; break;
    case PS2_F7: matrix[ZX_K_F7] = !is_up; break;
    case PS2_F8: matrix[ZX_K_F8] = !is_up; break;
    case PS2_F9: matrix[ZX_K_F9] = !is_up; break;
    case PS2_F10: matrix[ZX_K_F10] = !is_up; break;

    // TODO:

    // PgUp -> CS+3
    // PgDn -> CS+4
    // Windows L / Home -> SS+F
    // Windiws R / End -> SS+G
    // Scroll Lock -> CS+9
    // PrtScr -> CS+SS+P  
  
  }

  // Ctrl+Alt+Del -> RESET
  matrix[ZX_K_RST] = (is_ctrl && is_alt && is_del);

   // clear flags
   is_up = 0;
   is_e = 0;
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
  Serial.begin(115200);

  // serial interface setup
  pinMode(PIN_AVR_CLK, OUTPUT);
  pinMode(PIN_AVR_RST, OUTPUT);
  pinMode(PIN_AVR_DAT, OUTPUT);
  digitalWrite(PIN_AVR_CLK, LOW);
  digitalWrite(PIN_AVR_RST, LOW);
  digitalWrite(PIN_AVR_DAT, LOW);

  // all keys up
  for (int i=0; i<ZX_MATRIX_SIZE; i++) {
      matrix[i] = false;
  }

  kbd.begin(PIN_KBD_DAT, PIN_KBD_CLK);
//  mouse.begin(PIN_MOUSE_DAT, PIN_MOUSE_CLK);
  
}

void loop()
{
  if (kbd.available()) {
    int c = kbd.read();
    Serial.println(c, HEX);
    fill_kbd_matrix(c);
  }
  // transmit
  transmit_matrix();

  // debug
//  bool a = false;
//  if (matrix[ZX_K_A] != a) {
//    Serial.println(matrix[ZX_K_A]);
//    a = matrix[ZX_K_A];
//  }
}

