uses crt,dos,
     myio;

var b:array[1..16384] of byte;
    c:char;

procedure obliterate(s:string);
var f:file;
    siz,siz1:longint;
    i:integer;
    c:char;
begin
  assign(f,s); reset(f,1);
  siz:=filesize(f); siz1:=((siz-1) div 16384);

  textcolor(12); write('"'+s+'": ');
  textcolor(4); write('®');
  textcolor(14); for i:=1 to siz1+1 do write('ù');
  textcolor(4); write('¯');
  for i:=1 to siz1+2 do write(^H);

  textcolor(14);
  for i:=0 to siz1 do begin blockwrite(f,b,16384); write('*'); end;
  close(f);

  gotoxy(wherex+1,wherey);
  textcolor(4); write(' - Obliterated.  Delete? ');
  repeat c:=upcase(readkey) until (c in ['Y','N']);
  gotoxy(wherex-8,wherey); write('        '); gotoxy(wherex-8,wherey);
  if (c='Y') then begin
    erase(f);
    write('Deleted.');
  end;
  writeln;
end;

procedure obliterate1(s:string);
var dirinfo:searchrec;
begin
  findfirst(s,anyfile-directory,dirinfo);
  while (doserror=0) do begin
    obliterate(dirinfo.name);
    findnext(dirinfo);
  end;
  writeln;
  cwrite(#3#9+'þ '+#3#11+'Obliteration complete');
  writeln;
  writeln;
end;

procedure init;
var i:integer;
begin
  for i:=1 to 16384 do b[i]:=1;
end;

begin
  writeln;
  cwrite(#2#0+#3#14+'OBLIT '+#3#7+'- '+#3#11+'Aug 20 1989'+#3#7+' - '+
         #3#11+'Total File Obliteration');
  writeln;
  cwrite(#3#11+'Written by Eric Oman '+#3#7+'- '+
         #3#4+'The '+#3#15+'Pointe '+#3#9+'BBS '+#3#7+'- '+
         #3#11+'313-885-1779 '+#3#7+'- '+
         #3#11+'1200/2400');
  writeln;
  writeln;
  if (paramcount=1) then begin
    cwrite(#3#9+'þ '+#3#11+'Obliterate: "'+paramstr(1)+'"'); writeln;
    cwrite(#3#4+'  Confirm? '+#3#11);
    repeat c:=upcase(readkey) until (c in ['Y','N']);
    if (c='Y') then write('Yes') else write('No');
    writeln;
    if (c='Y') then begin
      writeln;
      init;
      obliterate1(paramstr(1));
    end;
  end else begin
    cwrite(#3#9+'þ '+#3#11+'Invalid parameters.');
    writeln;
    halt(1);
  end;
end.
