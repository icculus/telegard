(*****************************************************************************)
(*>                                                                         <*)
(*>  SYSOP2  .PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  SysOp functions: System Configuration Editor.                          <*)
(*>                                                                         <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit sysop2;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  sysop2a, sysop2b, sysop2c, sysop2d, sysop2e, sysop2f, sysop2g, sysop2h,
  sysop2i, sysop2z, sysop2s, sysop21,
  common;

procedure changestuff;

implementation

const
  aresure='Are you positive this is exactly what you want? ';

function wantit:boolean;
begin
  nl; wantit:=pynq(aresure);
end;

procedure changestuff;
var c:char;
    done,abort,next,savepause:boolean;
begin
  repeat
    done:=FALSE;
    cls;
    sprint(#3#5+'System configuration:');
    nl;
    abort:=FALSE; next:=FALSE; savepause:=FALSE;
    printacr('[A]. Modem configuration                [B]. File paths & BBS configuration',abort,next);
    nl;
    printacr('[C]. System ACS settings                [D]. System variables',abort,next);
    nl;
    printacr('[E]. System flagged functions           [F]. File section configuration',abort,next);
    nl;
    printacr('[G]. New user and Validation settings   [H]. Miscellaneous configuration',abort,next);
    nl;
    printacr('[I]. Net configuration                  [S]. String configuration',abort,next);
    nl;
    printacr('[Z]. Default colors',abort,next);
    nl;
    printacr('1. Time limitations',abort,next);
    printacr('2. Call allowance/day',abort,next);
    printacr('3. UL/DL # files ratio',abort,next);
    printacr('4. UL/DL K-bytes ratio',abort,next);
    printacr('5. Post/Call ratio',abort,next);
    nl;
    prt('Enter selection (A-I,S,Z,1-4) [Q]uit : ');
    onek(c,'QABCDEFGHIZS1234'^M);
    case c of
      'A':pomodem;
      'B':pofile;
      'C':poslsettings;
      'D':pogenvar;
      'E':poflagfunc;
      'F':pofilesconfig;
      'G':ponewauto;
      'H':pomisc1;
      'I':pofido;
      'S':postring;
      'Z':pocolors;
      '1':getsecrange('Time limitations',systat.timeallow);
      '2':getsecrange('Call allowance per day',systat.callallow);
      '3':getsecrange('UL/DL # files ratio (# files can DL per UL)',systat.dlratio);
      '4':getsecrange('UL/DL K-bytes ratio (#k can DL per 1k UL)',systat.dlkratio);
      '5':getsecrange('Post/Call ratio (# 1/10''s of calls per public post to have AR flag)',systat.postratio);
      'Q':done:=TRUE;
    end;
  until ((done) or (hangup));
  savesystat;
  if (savepause) then thisuser.ac:=thisuser.ac+[pause];
end;

end.
