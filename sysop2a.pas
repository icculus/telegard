(*****************************************************************************)
(*>                                                                         <*)
(*>  Telegard Bulletin Board System - Copyright 1988,89,90 by               <*)
(*>  Eric Oman, Martin Pollard, and Todd Bolitho - All rights reserved.     <*)
(*>                                                                         <*)
(*>  Module name:       SYSOP2A.PAS                                         <*)
(*>  Module purpose:    System Configuration "A" command                    <*)
(*>                     (Modem Configuration)                               <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit sysop2a;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  cuser,
  common;

procedure pomodem;

implementation

const
  aresure='Are you sure this is what you want? ';

function wantit:boolean;
begin
  nl; wantit:=pynq(aresure);
end;

procedure noch;
begin
  print('No change.');
end;

function showmodemstring(s:astr):astr;
var o:astr;
    i:integer;
begin
  o:='';
  for i:=1 to length(s) do
    case s[i] of
      ^@..^L,^N..^[:
         o:=o+'^'+chr(ord(s[i])+64);
      ^M:o:=o+'|';
    else
         o:=o+s[i];
    end;
  showmodemstring:=o;
end;

procedure newmodemstring(var vs:astr; what:astr; len:integer);
var i:integer;
    changed:boolean;
begin
  print('Current modem '+what+' string: "'+showmodemstring(vs)+'"');
  nl;
  print('Use: "^" preceding control codes (^@..^[)');
  print('     "|" for a carriage return');
  print('     "~" for a half-second delay');
  nl;
  print('Enter NEW modem '+what+' string:');
  prt(':');
  if (len>78) then mpl(78) else mpl(len);
  inputwn(vs,len,changed);
  if (changed) then begin
    for i:=1 to length(vs) do
      case vs[i] of
        '|':vs[i]:=^M;
        '^':if ((i<>length(vs)) and (vs[i+1] in ['@'..'['])) then begin
              vs[i]:=chr(ord(vs[i+1])-64);
              delete(vs,i+1,1);
            end;
      end;
  end else
    noch;
end;

(*
function whatflags:astr;
var s:string[64];
begin
  with modemr do begin
    if (ctschecking) then s:='CTS check ON, ' else s:='CTS check OFF, ';
    if (dsrchecking) then s:=s+'DSR check ON, ' else s:=s+'DSR check OFF, ';
    if (usexonxoff) then s:=s+'XON/XOFF ON, ' else s:=s+'XON/XOFF OFF, ';
    if (hardwired) then s:=s+'"Hard-wired" carrier' else s:=s+'Normal carrier';
  end;
  whatflags:=s;
end;
*)

procedure pomodem;
var modemrf:file of modemrec;
    s:string[80];
    i,c1,c2,cc:integer;
    c,ccc:char;
    abort,next,done:boolean;
begin
  done:=FALSE;
  repeat
    with modemr do begin
      cls;
      sprint(#3#5+'Modem configuration');
      nl;
      abort:=FALSE; next:=FALSE;
      printacr('1. Maximum baud rate    : '+cstrl(waitbaud),abort,next);
      printacr('2. COM port number      : '+cstr(comport),abort,next);
      printacr('3. Modem initialization string:',abort,next);
      printacr('   "'+showmodemstring(init)+'"',abort,next);
      printacr('4. Modem answer string  : "'+showmodemstring(answer)+'"',abort,next);
      printacr('5. Modem hangup string  : "'+showmodemstring(hangup)+'"',abort,next);
      printacr('6. Modem offhook string : "'+showmodemstring(offhook)+'"',abort,next);
      printacr('7. No-call init time    : '+cstr(nocallinittime),abort,next);
      printacr('A. 9600 ARQ rate baud   : '+cstrl(arq9600rate)+' baud',abort,next);
(*
      printacr('F. Comm flags: '+whatflags,abort,next);
*)
      printacr('F. Force baud rates?    : '+syn(not noforcerate),abort,next);
      printacr('R. Modem result codes:',abort,next);
      printacr('                     Case 1   Case 2 (ARQ)',abort,next);
      printacr('    R1. NO CARRIER : '+cstr(nocarrier),abort,next);
      printacr('    R2. NO DIALTONE: '+cstr(nodialtone),abort,next);
      printacr('    R3. BUSY       : '+cstr(busy),abort,next);
      for i:=0 to 5 do begin
        case i of
          0:s:=' 300'; 1:s:='1200'; 2:s:='2400';
          3:s:='4800'; 4:s:='9600'; 5:s:='19200';
        end;
        s:='    R'+cstr(i+4)+'. '+s+' BAUD  : '+
         mn(resultcode[1][i],3)+'      '+
           mn(resultcode[2][i],3);
        printacr(s,abort,next);
      end;
      nl;
      prt('Enter selection or (Q)uit : ');
      onek(c,'Q1234567AFR'^M); nl;
      case c of
        '1':if (incom) then begin
              sprint(#3#7+'This can only be changed locally!!@M');
              pausescr;
            end else begin
              print('This is the baud rate that Telegard will use when waiting for calls');
              print('at the WFC menu.  This should be your modem''s MAXIMUM BAUD RATE.');
              nl;
              print('The current rate is: '+cstrl(waitbaud)+' baud.');
              nl;
              print('A:300 B:1200 C:2400 D:4800 E:9600 F:19200 G:38400');
              prt('Modem speed? (A-G) : '); onek(ccc,'QABCDEFG'^M);
              if (ccc in ['A'..'G']) then
                case ccc of
                  'A':waitbaud:=300;
                  'B':waitbaud:=1200;
                  'C':waitbaud:=2400;
                  'D':waitbaud:=4800;
                  'E':waitbaud:=9600;
                  'F':waitbaud:=19200;
                  'G':waitbaud:=38400;
                end;
            end;
        '2':if (incom) then begin
              sprint(#3#7+'This can only be changed locally!!@M');
              pausescr;
            end else begin
              prt('Com port (1-4)? '); inu(cc);
              if (cc in [1..4]) then
                if (wantit) then begin
                  remove_port;
                  comport:=cc;
                  iport;
                end
                else noch;
            end;
        '3':newmodemstring(init,'init',80);
        '4':newmodemstring(answer,'answer',40);
        '5':newmodemstring(hangup,'hangup',40);
        '6':newmodemstring(offhook,'offhook',40);
        '7':begin
              prt('No call modem re-initialization: '); inu(c1);
              if (not badini) then nocallinittime:=c1;
            end;
        'A':begin
              print('This is the baud rate Telegard will USE between Telegard and your');
              print('modem when a 9600 ARQ result code is received.  Note that in most');
              print('9600+ modems, the rate is 19,200 baud.  Some even newer modems');
              print('support 38,400 baud.  OLDER modems (very old ones) only support 9600');
              print('baud.  CONSULT YOUR MODEM MANUAL, and make the best choice!');
              nl;
              print('The current rate is: '+cstrl(arq9600rate)+' baud.');
              nl;
              print('Valid SUPPORTED rates are 9600, 19200, and 38400 bauds.');
              nl;
              prt('(A):9600 (B):19200 (C):38400 or (Q)uit : ');
              onek(ccc,'QABC'^M);
              if (ccc in ['A'..'C']) then
                case ccc of
                  'A':arq9600rate:=9600;
                  'B':arq9600rate:=19200;
                  'C':arq9600rate:=38400;
                end;
            end;
(*
        'F':begin
              print('These are communications flags used by Telegard.');
              print('Do NOT change them unless you are having problems with');
              print('your *current* setup, and you KNOW what you are doing!');
              nl;
              print('Current flag setup: '+whatflags);
              nl;
              print('(C)TS checking, (D)SR checking,');
              print('(X)ON/XOFF, (H)ard-wired carrier');
              nl;
              prt('Which flag: '); onek(c,'QCDHX'^M);
              case c of
                'C':ctschecking:=not ctschecking;
                'D':dsrchecking:=not dsrchecking;
                'H':hardwired:=not hardwired;
                'X':usexonxoff:=not usexonxoff;
              end;
              c:=#0;
            end;
*)
        'F':noforcerate:=not noforcerate;
        'R':begin
              prt('Which result code? '); onek(ccc,'Q123456789');
              cc:=ord(ccc)-48;
              if (cc in [1..9]) then begin
                if (cc in [1..3]) then begin
                  prt('Enter new result code: '); inu(c1);
                  if not badini then
                    if wantit then
                      case cc of
                        1:nocarrier:=c1;
                        2:nodialtone:=c1;
                        3:busy:=c1;
                      end
                    else noch;
                end else begin
                  prt('Enter case 1 result code: '); inu(c1);
                  if (not badini) then resultcode[1][cc-4]:=c1;
                  prt('Enter case 2 result code: '); inu(c2);
                  if (not badini) then resultcode[2][cc-4]:=c2;
                end;
              end;
            end;
        'Q':done:=TRUE;
      end;
    end;
  until ((done) or (hangup));
  assign(modemrf,systat.gfilepath+'modem.dat');
  reset(modemrf); seek(modemrf,0); write(modemrf,modemr); close(modemrf);
end;

end.
