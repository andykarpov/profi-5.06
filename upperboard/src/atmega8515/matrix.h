#ifndef matrix_h
#define matrix_h

// ZX Spectrum keyboard matrix:

// 1  2  3  4  5  6  7  8  9  0
// q  w  e  r  t  y  u  i  o  p
// a  s  d  f  g  h  j  k  l  enter
// cs z  x  c  v  b  n  m  ss space

//--------------------------------------------------------------
// Scan code tables
//
//                 D0       D1      D2      D3     D4
// 
//  A8.  A0:       CS  0    Z  8    X  16   C 24   V 32
//  A9.  A1:       A   1    S  9    D  17   F 25   G 33     
//  A10. A2:       Q   2    W  10   E  18   R 26   T 34      
//  A11. A3:       1   3    2  11   3  19   4 27   5 35
//  A12. A4:       0   4    9  12   8  20   7 28   6 36
//  A13. A5:       P   5    O  13   I  21   U 29   Y 37
//  A14. A6:       Ent 6    L  14   K  22   J 30   H 38
//  A15. A7:       Sp  7    SS 15   M  23   N 31   B 39
//--------------------------------------------------------------

// Key position in output array

//#define ZX_MATRIX_SIZE 71 // 40 keys + magic + reset + turbo + F1-F10 + 8bit mouse x + 8 bit mouse y + 2 mouse buttons
#define ZX_MATRIX_SIZE 41 // only 40 keys + bit6

#define ZX_K_CS  0
#define ZX_K_A   1
#define ZX_K_Q   2
#define ZX_K_1   3
#define ZX_K_0   4
#define ZX_K_P   5
#define ZX_K_ENT 6
#define ZX_K_SP  7
#define ZX_K_Z   8
#define ZX_K_S   9
#define ZX_K_W   10
#define ZX_K_2   11
#define ZX_K_9   12
#define ZX_K_O   13
#define ZX_K_L   14
#define ZX_K_SS  15
#define ZX_K_X   16
#define ZX_K_D   17
#define ZX_K_E   18
#define ZX_K_3   19
#define ZX_K_8   20
#define ZX_K_I   21
#define ZX_K_K   22
#define ZX_K_M   23
#define ZX_K_C   24
#define ZX_K_F   25
#define ZX_K_R   26
#define ZX_K_4   27
#define ZX_K_7   28
#define ZX_K_U   29
#define ZX_K_J   30
#define ZX_K_N   31
#define ZX_K_V   32
#define ZX_K_G   33
#define ZX_K_T   34
#define ZX_K_5   35
#define ZX_K_6   36
#define ZX_K_Y   37
#define ZX_K_H   38
#define ZX_K_B   39

// Fn keys ext bit
#define ZX_K_BIT6  40

// Mouse pos Y
#define ZX_M_X0  41
#define ZX_M_X1  42
#define ZX_M_X2  43
#define ZX_M_X3  44
#define ZX_M_X4  45
#define ZX_M_X5  46
#define ZX_M_X6  47
#define ZX_M_X7  48

// Mouse pos Y
#define ZX_M_Y0  49
#define ZX_M_Y1  50
#define ZX_M_Y2  51
#define ZX_M_Y3  52
#define ZX_M_Y4  53
#define ZX_M_Y5  54
#define ZX_M_Y6  55
#define ZX_M_Y7  56

// Mouse btns
#define ZX_M_B1  57
#define ZX_M_B2  58
#define ZX_M_B3  59



#endif

