{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit fvtype;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  mdek, myio, timejunk;

procedure findvertypeout(s:string;
                         var vercs:string;
                         var vertype:string;
                         var vertypes:byte;
                         var serialnumber:longint;
                         var siteinfo:string;
                         var sitedatetime:packdatetime);

implementation

type
  infoheaderrec=array[1..6] of byte;

const
  infoheader:infoheaderrec=($FA,$CD,$20,$EF,$02,$AA);

procedure domessage;
var x,y,cx,c1,c2:integer;
    c:char;
begin
  cursoron(FALSE);
  clrscr;
  writeln('             €ﬂﬂ‹ ‹ﬂﬂ‹ €‹  € € ﬂﬂ€ﬂﬂ       €‹ ‹€ €ﬂﬂﬂﬂ ‹ﬂﬂﬂﬂ ‹ﬂﬂﬂﬂ');
  writeln('             €  € €  € € ﬂ‹€     €         € ﬂ € €ﬂﬂﬂ   ﬂﬂﬂ‹  ﬂﬂﬂ‹');
  writeln('             ﬂﬂﬂ   ﬂﬂ  ﬂ   ﬂ     ﬂ         ﬂ   ﬂ ﬂﬂﬂﬂﬂ ﬂﬂﬂﬂ  ﬂﬂﬂﬂ');
  writeln;
  writeln('                             € € € ﬂ€ﬂ ﬂﬂ€ﬂﬂ €   €');
  writeln('                             € € €  €    €   €ﬂﬂﬂ€');
  writeln('                             ﬂﬂ ﬂﬂ ﬂﬂﬂ   ﬂ   ﬂ   ﬂ');
  writeln;
  writeln('              ﬂﬂ€ﬂﬂ €   € €ﬂﬂﬂﬂ       €ﬂﬂﬂ‹ €ﬂﬂﬂ‹ ‹ﬂﬂﬂﬂ   €€  €€€');
  writeln('                €   €ﬂﬂﬂ€ €ﬂﬂﬂ        €ﬂﬂﬂ‹ €ﬂﬂﬂ‹  ﬂﬂﬂ‹   ﬂﬂ  ﬂﬂﬂ');
  writeln('                ﬂ   ﬂ   ﬂ ﬂﬂﬂﬂﬂ       ﬂﬂﬂﬂ  ﬂﬂﬂﬂ  ﬂﬂﬂﬂ    ﬂﬂ  ﬂﬂﬂ');
  writeln;
  writeln;
  writeln('              Analysis of the BBS.EXE and BBS.OVR files has shown');
  writeln('            that they have been tampered with.  Don''t do it again!!');
  writeln('           We - the authors of this BBS - feel it is already a pretty');
  writeln('                 good piece of software... don''t mess with it!');
  writeln;
  c1:=0;

  {rcg11172000 this doesn't fly under Linux. Is this all necessary anyway?}
  repeat
  {
    for x:=39 downto 2 do begin
      cx:=cx mod 3+1;
      case cx of 1:c1:=4; 2:c1:=12; 3:c1:=14; end;
      case cx of 1:c2:=12; 2:c2:=14; 3:c2:=15; end;
      inline($FA);
      for y:=1 to 11 do begin
        mem[vidseg:(160*(y-1)+2*(x-1))+1]:=c1;
        mem[vidseg:(160*(y-1)+2*((79-x)-1))+1]:=c1;
      end;
      delay(1);
      inline($FB);
    end;
  }
  until (keypressed);
  c:=readkey;
  cursoron(TRUE);
  gotoxy(1,19);
  halt(255);
end;

procedure findvertypeout(s:string;
                         var vercs:string;
                         var vertype:string;
                         var vertypes:byte;
                         var serialnumber:longint;
                         var siteinfo:string;
                         var sitedatetime:packdatetime);
var f:file;
    rs:string;
    r:array[1..144] of byte;
    chk,chk1,chk2:word;
    i,res:integer;
    b1,b2:byte;

  procedure decryptinfo;
  var s:string;
      i:integer;
  begin
    for i:=13 to 142 do s[i-12]:=chr(r[i]); s[0]:=chr(132);
    s:=decrypt(s,r[7],r[8],r[9],r[10],r[11],r[12]);
    for i:=13 to 142 do r[i]:=ord(s[i-12]);
  end;

begin
  vertype:='Standard'; vertypes:=0; vercs:='';
  filemode:=0; assign(f,s); reset(f,1);
  seek(f,filesize(f)-144); blockread(f,r,144,res);
  close(f); filemode:=2;

  for i:=1 to 6 do
    if (r[i]<>infoheader[i]) then exit;

  decryptinfo;

  chk:=0;

  for i:=13 to 142 do inc(chk,r[i]);
  chk1:=(chk div 6)*5;
  chk2:=(chk div 19)*25;
  b1:=chk1 mod 256;
  b2:=chk2 mod 256;
  if ((r[143]<>b1) or (r[144]<>b2)) then domessage;
  vertypes:=r[19];
  case (r[19] and $07) of
    $01:begin vercs:='‡'; vertype:='Alpha'; end;
    $02:begin vercs:='Ä'; vertype:='Center'; end;
    $03:begin vercs:='·'; vertype:='Beta'; end;
    $04:begin vercs:='‰'; vertype:='Special'; end;
  else  begin vercs:='';  vertype:='Standard'; end;
  end;
  if (r[19] and $10=$10) then vertype:=vertype+' Node';
  if (r[19] and $08=$08) then begin
    vercs:=vercs+'$';
    if (vertype='Standard') then vertype:='Registered'
                            else vertype:='Registered '+vertype;
  end;
  serialnumber:=r[20]+(r[21] shl 8)+(r[22] shl 16)+(r[23] shl 24);
  for i:=1 to 6 do sitedatetime[i]:=r[12+i];
  siteinfo:='';
  for i:=1 to r[24] do siteinfo:=siteinfo+chr(r[i+24]);
end;

end.
