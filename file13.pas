{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}

unit file13;

interface

uses
  crt,dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  myio,
  file0, file1, file2,
  common;

procedure sort;

implementation

var totfils,totbases:longint;
    bubblesortend:integer;
    sortt:char;
    isascend:boolean;

procedure switch(a,b:integer);
var f1,f2:ulfrec;
begin
  seek(ulff,a); read(ulff,f1);
  seek(ulff,b); read(ulff,f2); seek(ulff,b); write(ulff,f1);
  seek(ulff,a); write(ulff,f2);
end;

function greater(islesser,isequ:boolean; r1,r2:integer):boolean;
var f1,f2:ulfrec;
    b,c:boolean;

  procedure figure1;
  begin
    case sortt of
      'B':if (isequ) then b:=(f1.description<=f2.description)
                     else b:=(f1.description<f2.description);
      'D':if (isequ) then b:=(f1.daten<=f2.daten)
                     else b:=(f1.daten<f2.daten);
      'E':if (isequ) then b:=(copy(f1.filename,10,3)<=copy(f2.filename,10,3))
                     else b:=(copy(f1.filename,10,3)<copy(f2.filename,10,3));
      'F':if (isequ) then b:=(f1.filepoints<=f2.filepoints)
                     else b:=(f1.filepoints<f2.filepoints);
      'N':if (isequ) then b:=(f1.filename<=f2.filename)
                     else b:=(f1.filename<f2.filename);
      'O':if (isequ) then b:=(f1.owner<=f2.owner)
                     else b:=(f1.owner<f2.owner);
      'S':if (isequ) then b:=(f1.blocks<=f2.blocks)
                     else b:=(f1.blocks<f2.blocks);
      'T':if (isequ) then b:=(f1.nacc<=f2.nacc)
                     else b:=(f1.nacc<f2.nacc);
    end;
  end;

  procedure figure2;
  begin
    case sortt of
      'B':if (isequ) then b:=(f1.description>=f2.description)
                     else b:=(f1.description>f2.description);
      'D':if (isequ) then b:=(f1.daten>=f2.daten)
                     else b:=(f1.daten>f2.daten);
      'E':if (isequ) then b:=(copy(f1.filename,10,3)>=copy(f2.filename,10,3))
                     else b:=(copy(f1.filename,10,3)>copy(f2.filename,10,3));
      'F':if (isequ) then b:=(f1.filepoints>=f2.filepoints)
                     else b:=(f1.filepoints>f2.filepoints);
      'N':if (isequ) then b:=(f1.filename>=f2.filename)
                     else b:=(f1.filename>f2.filename);
      'O':if (isequ) then b:=(f1.owner>=f2.owner)
                     else b:=(f1.owner>f2.owner);
      'S':if (isequ) then b:=(f1.blocks>=f2.blocks)
                     else b:=(f1.blocks>f2.blocks);
      'T':if (isequ) then b:=(f1.nacc>=f2.nacc)
                     else b:=(f1.nacc>f2.nacc);
    end;
  end;

begin
  if (r1<r2) then begin
    seek(ulff,r1); read(ulff,f1);
    seek(ulff,r2); read(ulff,f2);
  end else begin
    seek(ulff,r2); read(ulff,f2);
    seek(ulff,r1); read(ulff,f1);
  end;

  if (isascend) then islesser:=not islesser;
  if (islesser) then figure1 else figure2;
  greater:=b;
end;

(*                                                                           *
 *  While I personally think labels are stupid as *@#((#@!#$, and they look  *
 *  like *#$@*, I kept them in for lack of a better idea!                    *
 *)
procedure mainsort(pl:integer);
label 10,20,30,40,50,60,70,80;
const maxsortrec=2000;   (* maximum size of directory which can be processed *)
var hold,pass:array[1..maxsortrec] of integer;
    a,b,c,d,e,f,x:integer;
begin
  a:=pl; b:=0; c:=0; d:=1; e:=1; f:=0;
10:
  if (a-e<9) then goto 70;
  b:=e; c:=a;
20:
  if (greater(TRUE,FALSE,b,c)) then begin
    switch(c,b);
    goto 60;
  end;
30:
  dec(c);
  if (c>b) then goto 20;
  inc(c);
40:
  inc(d);
  if (b-e<a-c) then begin
    hold[d]:=c; pass[d]:=a;
    a:=b;
    goto 10;
  end;
  hold[d]:=e; pass[d]:=b;
  e:=c;
  goto 10;
50:
  if (greater(FALSE,FALSE,c,b)) then begin
    switch(c,b);
    goto 30;
  end;
60:
  inc(b);
  if (c>b) then goto 50;
  inc(c);
  goto 40;
70:
  if (a-e+1=1) then goto 80;
  for b:=e+1 to a do
    for c:=e to (b-1) do begin
      f:=b-c+e-1;
      if (greater(TRUE,FALSE,f,f+1)) then begin
        x:=f+1;
        switch(f,x);
      end;
    end;
80:
  e:=hold[d]; a:=pass[d];
  dec(d);
  if (d=0) then exit;
  goto 10;
end;

procedure flipit(pl:integer);
var i:integer;
begin
  for i:=1 to pl div 2 do switch(i,(pl-i)+1);
end;

procedure bubblesort(pl:integer);
var f1,f2:ulfrec;
    i,j,numdone:integer;
    foundit:boolean;
begin
  if (bubblesortend>pl) then bubblesortend:=pl;  { should never happen, but...}
  numdone:=0;
  repeat
    i:=(bubblesortend+1)-numdone;
    foundit:=FALSE;
    while ((i<=pl) and (not foundit)) do
      if (greater(FALSE,TRUE,1,i)) then foundit:=TRUE else inc(i);

{    while ((i<=pl) and (not greater(FALSE,TRUE,1,i))) do inc(i);}
    seek(ulff,1); read(ulff,f1);

{                   (i-1) __(i)               }
{                     |  /                    }
      { x O + + + + + + + x x x x x x x ..... }
      { x + + + + + + +   x x x x x x x ..... }
    for j:=1 to i-2 do begin
      seek(ulff,j+1); read(ulff,f2);
      seek(ulff,j); write(ulff,f2);
    end;

      { x + + + + + + + O x x x x x x x ..... }
    seek(ulff,i-1); write(ulff,f1);
    inc(numdone);
  until ((numdone>=bubblesortend));

end;

function analysis(pl:integer):integer;
var i,j:integer;
    c1,c2:boolean;
begin
  analysis:=1;
  c1:=TRUE; c2:=TRUE;
  for i:=1 to pl-1 do begin
    if (not greater(TRUE,TRUE,i,i+1)) then c1:=FALSE;    { a }
    if (not greater(FALSE,TRUE,i,i+1)) then c2:=FALSE;   { d }
  end;
  if (c1) then analysis:=2;     { list is backwards, so flip it }
  if (c2) then analysis:=0;     { list is already sorted }
  if ((not c1) and (not c2)) then begin
    c1:=FALSE; j:=0;
    i:=pl-1;
    while ((i>=1) and (not c1)) do begin
      if (not greater(FALSE,TRUE,i,i+1)) then begin c1:=TRUE; j:=i; end;
      dec(i);
    end;
    if ((c1) and (j/pl<0.15)) then begin
      analysis:=3;
      bubblesortend:=j;
    end;
  end;
end;

procedure sortfiles(b:integer; var abort,next:boolean);
var s:string;
    oldboard,pl,sortt:integer;
begin
  oldboard:=fileboard;
  if (fileboard<>b) then changefileboard(b);
  if (fileboard=b) then begin
    fiscan(pl);
    seek(ulff,pl+1); truncate(ulff);
    sprompt('Sorting '+#3#5+memuboard.name+#3#5+' #'+cstr(fileboard)+#3#1+
           ' ('+cstr(pl)+' files)');
    abort:=FALSE; next:=FALSE;
    sortt:=analysis(pl);
    case sortt of 0:s:='.'; 1:s:=#3#0+'*'; 2:s:=#3#9+'x'; 3:s:=#3#9+'*'; end;
    sprint(s);
    case sortt of
      0:;
      1:mainsort(pl);
      2:flipit(pl);
      3:bubblesort(pl);
    end;
    wkey(abort,next);
    close(ulff);
    inc(totbases); inc(totfils,pl);
  end;
  fileboard:=oldboard;
end;

procedure sort;
var f:ulfrec;
    sortstart,sortend,tooktime:datetimerec;
    i:integer;
    c:char;
    global,abort,next,savepause:boolean;
begin
  savepause:=(pause in thisuser.ac);
  if (savepause) then thisuser.ac:=thisuser.ac-[pause];

  repeat
    nl; prt('Sorting method? (?=help) [N] : ');
    onek(sortt,'QBDEFNOST?'^M);
    if (sortt='?') then begin
      nl;
      lcmds(7,3,'Date','Brief description');
      lcmds(7,3,'Name','Extension');
      lcmds(7,3,'Owner','File points');
      lcmds(7,3,'Size','Times downloaded');
      lcmds(7,3,'Quit','');
    end;
  until ((sortt<>'?') or (hangup));

  if (sortt=^M) then sortt:='N';
  case sortt of
    'D','F','O','S','T':isascend:=FALSE;
    'Q':exit;
  else
        isascend:=TRUE;
  end;
  if (isascend) then c:='A' else c:='D';
  prt('Order: (^3A^4)scending (^3D^4)escending (^3Q^4)uit : ['+c+'] : ');
  onek(c,'QADN'^M);
  case c of
    'A':isascend:=TRUE;
    'D':isascend:=FALSE;
    'Q':exit;
  end;

  nl;
  global:=pynq('Sort all directories? ');
  nl;

  totfils:=0; totbases:=0;

  getdatetime(sortstart);
  abort:=FALSE; next:=FALSE;
  if (not global) then
    sortfiles(fileboard,abort,next)
  else begin
    i:=0;
    while ((not abort) and (i<=maxulb) and (not hangup)) do begin
      if (fbaseac(i)) then sortfiles(i,abort,next);
      inc(i);
      wkey(abort,next);
      if (next) then abort:=FALSE;
    end;
  end;
  getdatetime(sortend);
  timediff(tooktime,sortstart,sortend);
  
  nl;
  print('Sorted '+cstrl(totfils)+' file'+aonoff(totfils<>1,'s','')+
        ' in '+cstrl(totbases)+' base'+aonoff(totbases<>1,'s','')+
        ' - Took '+longtim(tooktime));

  if (savepause) then thisuser.ac:=thisuser.ac+[pause];
end;

end.
