(*****************************************************************************)
(*>                                                                         <*)
(*>  SYSOP2I .PAS -  Written by Martin Pollard                              <*)
(*>                                                                         <*)
(*>  SysOp functions: System Configuration Editor -- "I" command.           <*)
(*>                                                                         <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit sysop2i;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common;

procedure pofido;

implementation

procedure incolor(msg:string; var i:byte);
var c:char;
begin
  prt('Enter new '+msg+' color (0-9) : ');
  onek(c,^M'0123456789');
  if (c<>^M) then i:=ord(c)-48;
end;

function toggle(b:boolean):boolean;
begin
  if (b) then toggle:=FALSE else toggle:=TRUE;
end;

procedure pofido;
var fidorf:file of fidorec;
    c:char;
    cc:integer;
    s:string[27];
    abort,next,done,changed:boolean;
begin
  done:=FALSE;
  repeat
    with fidor do begin
      cls;
      sprint(#3#5+'FidoNet configuration');
      nl;
      abort:=FALSE; next:=FALSE;
      s:=cstr(zone)+':'+cstr(net)+'/'+cstr(node)+'.'+cstr(point);
      printacr('A. FidoNet address : '+s,abort,next);
      printacr('B. Origin line     : "'+origin+'"',abort,next);
      nl;
      printacr('C. Strip IFNA kludge lines : '+syn(skludge)+
        '     1. Color of standard text : '+cstr(ord(text_color)),abort,next);
      printacr('D. Strip SEEN-BY lines     : '+syn(sseenby)+
        '     2. Color of quoted text   : '+cstr(ord(quote_color)),abort,next);
      printacr('E. Strip origin line       : '+syn(sorigin)+
        '     3. Color of tear line     : '+cstr(ord(tear_color)),abort,next);
      printacr('F. Strip centering codes   : '+syn(scenter)+
        '     4. Color of origin line   : '+cstr(ord(origin_color)),abort,next);
      printacr('G. Strip box codes         : '+syn(sbox),abort,next);
      printacr('H. Center box/center lines : '+syn(mcenter),abort,next);
      printacr('I. Add tear/origin lines   : '+syn(addtear),abort,next);
      nl;
      prt('Enter selection (A-I,1-4) [Q]uit : ');
      onek(c,'QABCDEFGHI1234'^M);
      nl;
      case c of
        'Q':done:=TRUE;
        'A':begin
              prt('Enter your zone number  : ');
              inu(cc); if (not badini) then zone:=cc;
              prt('Enter your net number   : ');
              inu(cc); if (not badini) then net:=cc;
              prt('Enter your node number  : ');
              inu(cc); if (not badini) then node:=cc;
              prt('Enter your point number : ');
              inu(cc); if (not badini) then point:=cc;
            end;
        'B':begin
              print('Enter new origin line');
              prt(':'); mpl(50); inputwn(origin,50,changed);
            end;
        'C':skludge:=toggle(skludge);
        'D':sseenby:=toggle(sseenby);
        'E':sorigin:=toggle(sorigin);
        'F':scenter:=toggle(scenter);
        'G':sbox:=toggle(sbox);
        'H':mcenter:=toggle(mcenter);
        'I':addtear:=toggle(addtear);
        '1':incolor('standard text',text_color);
        '2':incolor('quoted text',quote_color);
        '3':incolor('tear line',tear_color);
        '4':incolor('origin line',origin_color);
      end;
    end;
  until ((done) or (hangup));
  assign(fidorf,systat.gfilepath+'FIDONET.DAT');
  reset(fidorf);
  seek(fidorf,0);
  write(fidorf,fidor);
  close(fidorf);
end;

end.
