{ Global Declarations }

{ 8086/8088 hardware flags }
const
  carry_flag     = 1;
  parity_flag    = 4;
  aux_carry_flag = 16;
  zero_flag      = 64;
  sign_flag      = 128;

type
  anystr   = string[255];  (* Matches any string for parameter passing *)
  shortstr = string[30];   (* Short string *)
  keystr   = string[65];   (* Function key string *)
  filestr  = string[65];   (* File name string *)
  text_file = text;

