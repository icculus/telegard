program test;

{$A+,D+}

uses crt,dos,
     myio;

var snowcheck,usebios:boolean;
    vidseg:word;

{$L fastchr}

{$F+}
procedure fastchr(wchr,wattr:byte); external;
{$F-}

procedure fastwrite(s:string);
var i:integer;
begin
  for i:=1 to length(s) do fastchr(ord(s[i]),$1B);
end;

var t:text;
    wind:windowrec;
    s:string;
    i,sx,sy:integer;
    c:char;
begin
  snowcheck:=TRUE; usebios:=FALSE; vidseg:=$B800;
  writeln;
  write('Snow checking [Y] : '); if (upcase(readkey)='N') then snowcheck:=FALSE;
  writeln;
  write('Use BIOS [N] : '); if (upcase(readkey)='Y') then snowcheck:=TRUE;
  writeln;
  textcolor(7); myio.box(7,1,1,80,25);
  window(1,1,80,25);
  assign(t,'bbs.pas'); reset(t);
  while (not eof(t)) do begin
    readln(t,s);
    fastwrite(s);
    gotoxy(80,wherey); fastwrite(' ');
    if (keypressed) then begin close(t); exit; end;
  end;
  close(t);
end.
