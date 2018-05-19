/*
 * AVR keyboard & mouse firmware for Profi 5.06
 * Atmega8515 replacement on Atmega328p :)
 * 
 * Designed to build on Arduino IDE.
 * 
 * @author Andy Karpov <andy.karpov@gmail.com>
 * Ukraine, 2018
 */

#include "ps2.h"
#include "matrix.h"
#include "ps2_codes.h"
#include "ps2mouse.h"
#include <SPI.h>

#define DEBUG_MODE 0

// ---- Pins for Atmega328
#define PIN_KBD_CLK 2 // pin 28 (CLKK)
#define PIN_KBD_DAT 4 // pin 27 (DATK)

#define PIN_MOUSE_CLK 3 // pin 26 (CLKM)
#define PIN_MOUSE_DAT 5 // pin 25 (DATM)

// 13,12,11 - hardware SPI
#define PIN_SS 7 // SPI slave select
#define PIN_BUSY 6 // Busy LED

#define PIN_RESET 10 // pin 1 (/RESET)
#define PIN_TURBO 9 //  pin 3 (/TURBO)
#define PIN_MAGIC 8 //  pin 2 (ATM_/MAGIC)

#define PIN_SDA A4 // pin 23 
#define PIN_SCL A5 // ping 24

#define PIN_IRX 0 // pin 10
#define PIN_OTX 1 // pin 11

#define PIN_ICTS A1 // pin 22
#define PIN_ORTS A0 // pin 21


PS2KeyRaw kbd;
PS2Mouse mouse(PIN_MOUSE_CLK, PIN_MOUSE_DAT);

bool matrix[ZX_MATRIX_SIZE]; // matrix of pressed keys + mouse reports to be transmitted on CPLD side by simple serial protocol
bool profi_mode = true; // false = zx spectrum mode (switched by PrtSrc button in run-time)
bool is_turbo = false; // turbo toggle (switched by ScrollLock button)
bool mouse_present = false; // mouse present flag (detected by signal change on CLKM pin)
unsigned long t = 0;
unsigned long tm = 0;
unsigned long tl = 0;
int mouse_tries = 5;

uint8_t mouse_x = 0;
uint8_t mouse_y = 0;
uint8_t mouse_z = 0;
uint8_t mouse_btns = 0;
bool mouse_new_packet = false;

SPISettings settingsA(8000000, MSBFIRST, SPI_MODE0);

// transform PS/2 scancodes into internal matrix of pressed keys
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

uint8_t get_matrix_byte(uint8_t pos)
{
  uint8_t result = 0;
  for (uint8_t i=0; i<8; i++) {
    uint8_t k = pos*8 + i;
    if (k < ZX_MATRIX_SIZE) {
      bitWrite(result, i, matrix[k]);
    }
  }
  return result;
}

// transmit keyboard matrix from AVR to CPLD side via SPI
void transmit_keyboard_matrix()
{
    uint8_t bytes = 6;
    for (uint8_t i=0; i<bytes; i++) {
      uint8_t data = get_matrix_byte(i);
      SPI.beginTransaction(settingsA);
      digitalWrite(PIN_SS, LOW);
      uint8_t cmd = SPI.transfer(i+1); // command (1...6)
      uint8_t res = SPI.transfer(data); // data byte
      digitalWrite(PIN_SS, HIGH);
      SPI.endTransaction();
      if (cmd > 0) {
        process_in_cmd(cmd, res);
      }
    }
}

void transmit_mouse_data()
{
  uint8_t cmd = 0;
  uint8_t res = 0;

  SPI.beginTransaction(settingsA);
  digitalWrite(PIN_SS, LOW);
  cmd = SPI.transfer(CMD_MOUSE_X); // command (0x0A)
  res = SPI.transfer(mouse_x);     // X coord
  digitalWrite(PIN_SS, HIGH);
  SPI.endTransaction();
  if (cmd > 0) {
    process_in_cmd(cmd, res);
  }

  SPI.beginTransaction(settingsA);
  digitalWrite(PIN_SS, LOW);
  cmd = SPI.transfer(CMD_MOUSE_Y); // command (0x0B)
  res = SPI.transfer(mouse_y);     // Y coord
  digitalWrite(PIN_SS, HIGH);
  SPI.endTransaction();
  if (cmd > 0) {
    process_in_cmd(cmd, res);
  }

  SPI.beginTransaction(settingsA);
  digitalWrite(PIN_SS, LOW);
  cmd = SPI.transfer(CMD_MOUSE_Z); // command (0x0C)
  res = SPI.transfer(mouse_z);     // Z coord + buttons
  digitalWrite(PIN_SS, HIGH);
  SPI.endTransaction();
  if (cmd > 0) {
        process_in_cmd(cmd, res);
  }  
}

void process_in_cmd(uint8_t cmd, uint8_t data)
{
  // TODO
}

void init_mouse()
{
    mouse_present = mouse.initialize();
  
#if DEBUG_MODE
  if (!mouse_present) {
    Serial.println(F("Mouse does not exists"));
  } else {
    Serial.println(F("Mouse present"));
  }
#endif

}

// initial setup
void setup()
{
  SPI.begin();

  pinMode(PIN_SS, OUTPUT);
  digitalWrite(PIN_SS, HIGH);

  pinMode(PIN_BUSY, OUTPUT);
  digitalWrite(PIN_BUSY, LOW);

  // ps/2

  pinMode(PIN_KBD_CLK, INPUT_PULLUP);
  pinMode(PIN_KBD_DAT, INPUT_PULLUP);

  pinMode(PIN_MOUSE_CLK, INPUT_PULLUP);
  pinMode(PIN_MOUSE_DAT, INPUT_PULLUP);
  
  // zx signals (output)

  pinMode(PIN_RESET, OUTPUT);
  digitalWrite(PIN_RESET, HIGH);

  pinMode(PIN_TURBO, OUTPUT);
  digitalWrite(PIN_TURBO, HIGH);

  pinMode(PIN_MAGIC, OUTPUT);
  digitalWrite(PIN_MAGIC, HIGH);

  // uart
  pinMode(PIN_ICTS, INPUT_PULLUP);
  pinMode(PIN_ORTS, OUTPUT);
  

  // all keys up
  for (int i=0; i<ZX_MATRIX_SIZE; i++) {
      matrix[i] = false;
  }

#if DEBUG_MODE
  Serial.begin(115200);
  Serial.println(F("ZX Keyboard / mouse controller v1.0"));
  Serial.println(F("Keyboard init..."));
#endif

  kbd.begin(PIN_KBD_DAT, PIN_KBD_CLK);

#if DEBUG_MODE
  Serial.println(F("done"));
  Serial.println(F("Mouse init..."));
#endif

init_mouse();
  
}

// main loop
void loop()
{
  digitalWrite(PIN_BUSY, LOW);
  
  if (kbd.available()) {
    int c = kbd.read();
    digitalWrite(PIN_BUSY, HIGH);
#if DEBUG_MODE    
    Serial.print(F("Scancode: "));
    Serial.println(c, HEX);
#endif
    fill_kbd_matrix(c);
  }

  // transmit kbd always
  transmit_keyboard_matrix();

  unsigned long n = millis();

  // try to re-init mouse every 5s if not present, up to 5 tries
  if (mouse_tries > 0 && !mouse_present && n - tm > 5000) {
    mouse_tries--;
    init_mouse();
    tm = n;
  }

  // polling for mouse data every 100ms
  if (mouse_present && n - t > 100) {

    MouseData m = mouse.readData();

    mouse_new_packet = !mouse_new_packet;
    mouse_x = m.position.x;
    mouse_y = m.position.y;
    mouse_z = m.wheel;

    bool btn1 = bitRead(m.status, 0);
    bool btn2 = bitRead(m.status, 1);
    bool btn3 = bitRead(m.status, 2);    
    bitWrite(mouse_z, 4, btn1);
    bitWrite(mouse_z, 5, btn2);
    bitWrite(mouse_z, 6, btn3);
    bitWrite(mouse_z, 7, mouse_new_packet);

    // transmit mouse only if present, every 100ms
    transmit_mouse_data();

    t = n;

#if DEBUG_MODE
    Serial.print(F("Mouse: "));
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
  
}

