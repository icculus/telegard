{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
{$M 32150,0,0}          { Declared here suffices for all Units as well! }

program BatchBackup;

uses
  crt,dos,
  myio, common;

{$I func.pas}

type
  lbrec=record
          drv:char;
          lb:datetime;
          nacc:integer;
        end;

const
  {rcg11242000 uh...DOSism. uh...}
  {lastspec='c:\lastbak.txt';}
  lastspec='./lastbak.txt';
  cline='tape SBK @D:\/S-\TRAP*.MSG/S-\BBS.OVR/S-\BBS.EXE/S/A/C/C+/-O/R@T/LBAK@D@N';
  lodrv:char='C';
  hidrv:char='E';
  go:boolean=FALSE;
  abort:boolean=FALSE;
  firstq:boolean=TRUE;

var
  lbdrv:array['C'..'G'] of lbrec;
  tagged:array['C'..'G'] of boolean;
  wind,winds:windowrec;
  y,oy:char;
  sx,sy:integer;
  lbf:file of lbrec;

{rcg11172000 had to change this to get it compiling under Free Pascal...}
{function substall(src,old,new:string):string;}
function substall(src,old,_new:string):string;
var p:integer;
begin
  p:=1;
  while p>0 do begin
    p:=pos(old,src);
    if p>0 then begin
      insert(_new,src,p+length(old));
      delete(src,p,length(old));
    end;
  end;
  substall:=src;
end;

function sdat(dt:datetime):string;
{rcg11272000 my add.}
var yearstr:string;

  function tch(i:integer):string;
  var s:string;
  begin
    str(i,s);
    if i<10 then s:='0'+s;
    if i<0 then s:='00';
    tch:=s;
  end;

begin
  with dt do begin
    {rcg11272000 y2k stuff.}
    {sdat:=tch(month)+'/'+tch(day)+'/'+tch(year-1900)+' '+tch(hour)+':'+tch(min)+':'+tch(sec);}
    str(year,yearstr);
    sdat:=tch(month)+'/'+tch(day)+'/'+yearstr+' '+tch(hour)+':'+tch(min)+':'+tch(sec);
  end;
end;

procedure unsdat(s:string; var dt:datetime);
var x:integer;
begin

  {rcg11272000 my add...}
  if (length(s) < 10) then rcgpanic('WHOA! TWO DIGIT YEAR IN DATE!');

  with dt do begin
    {rcg11272000 Y2K-proofing.}
    {val(copy(s,7,2),year,x); inc(year,1900);}
    val(copy(s,7,4),year,x);
    val(copy(s,1,2),month,x);
    val(copy(s,4,2),day,x);
    val(copy(s,10,2),hour,x);
    val(copy(s,13,2),min,x);
    val(copy(s,16,2),sec,x);
  end;
end;

procedure datnow(var dt:datetime);
var r:registers;
begin
  with dt, r do begin
    ax:=$2a00; msdos(dos.registers(r));
    year:=cx;
    month:=dx shr 8;
    day:=dx mod 256;
    ax:=$2c00; msdos(dos.registers(r)); {intr($21,dos.registers(r));}
    hour:=cx shr 8;
    min:=cx mod 256;
    sec:=dx shr 8;
  end;
end;

function dtchk(s:string):boolean;
begin
  dtchk:=FALSE;
  if (s[1] in ['0'..'9']) and (s[2] in ['0'..'9']) and
     (s[4] in ['0'..'9']) and (s[5] in ['0'..'9']) and
     (s[7] in ['0'..'9']) and (s[8] in ['0'..'9']) then dtchk:=TRUE;
end;

function gooddate(s:string):boolean;
begin
  gooddate:=FALSE;
  if (s[3] in ['-','/']) and (s[6] in ['-','/']) and (length(s)=8) then
    if dtchk(s) then gooddate:=TRUE;
end;

procedure inlast;
var c:char;
    dt:datetime;
begin
  datnow(dt);
  assign(lbf,lastspec);
  {$I-} reset(lbf); {$I+}
  if ioresult=0 then
    for c:=lodrv to hidrv do
      read(lbf,lbdrv[c])
  else begin
    rewrite(lbf);
    for c:=lodrv to hidrv do begin
      with lbdrv[c] do begin
        drv:=c;
        lb:=dt;
        nacc:=0;
      end;
      write(lbf,lbdrv[c]);
    end;
  end;
  close(lbf);
end;

procedure tagall;
var c:char;
begin
  for c:=lodrv to hidrv do tagged[c]:=TRUE;
end;

procedure setscreen;
begin
  sx:=wherex; sy:=wherey;
  savescreen(winds,1,1,80,25);
  setwindow(wind,10,3,53,ord(hidrv)-ord(lodrv)+10,9,1,1);
  window(12,4,52,ord(hidrv)-ord(lodrv)+9);
  clrscr;
end;

procedure init;
begin
  inlast;
  tagall;
  setscreen;
end;

procedure closeup;
begin
  removewindow(winds);
  gotoxy(sx,sy);
end;

procedure sc(s:string);
const bcol:boolean=FALSE;
      fcol:boolean=FALSE;
var i:integer;
begin
  for i:=1 to length(s) do
    if not fcol then
      if not bcol then
        case s[i] of
          #3:fcol:=TRUE;
          #4:bcol:=TRUE;
        else
             write(s[i]);
        end
      else begin
        bcol:=FALSE;
        textbackground(ord(s[i]));
      end
    else begin
      fcol:=FALSE;
      textcolor(ord(s[i]));
    end;
end;

procedure scln(s:string);
begin
  sc(s);
  writeln;
end;

procedure showstuff;
var c:char;
    s:string;
begin
  gotoxy(1,3);
  for c:=lodrv to hidrv do begin
    if tagged[c] then sc(#3#15+'+') else sc(#3#9+'-');
    sc(#3#11+' Drive '+c+':'+#3#9+' Since '+#3#14+sdat(lbdrv[c].lb));
    str(lbdrv[c].nacc,s);
    scln(#3#9+' (#'+s+')');
  end;
  writeln;
  scln(#3#11+'  OK');
  sc(#3#11+'  Abort');
end;

procedure lin(i:integer);

  procedure dd(y:char);
  begin
    if y<=hidrv then sc('Drive '+y+':') else
      if y=chr(ord(hidrv)+2) then sc('OK') else
        if y=chr(ord(hidrv)+3) then sc('Abort');
  end;

begin
  case i of
    0:begin
        gotoxy(3,ord(oy)-64);
        sc(#4#1+#3#11);
        dd(oy);
      end;
    1:begin
        gotoxy(3,ord(y)-64);
        sc(#4#3+#3#0);
        dd(y);
      end;
  end;
end;

procedure glin;
begin
  lin(0); lin(1);
  oy:=y;
end;

procedure tell(s:string);
var i:integer;
begin
  CursorOff;
  i:=40-(length(s) div 2)-3;
  setwindow(wind,i,10,i+length(s)+5,14,9,1,1);
  gotoxy(3,2); textcolor(15); writeln(s);
end;


{rcg11172000 added by me.}
procedure CursorOn;
begin
  writeln('STUB: bb.pas; CursorOn()...');
end;
{rcg11172000 adds end.}


procedure makesound;
var i,j,k:integer;
begin
  i:=100;
  repeat
    sound(i);
    delay(i div 100);
    j:=100;
    repeat
      sound(j);
      delay(j div 100);
      k:=100;
      repeat
        sound(k);
        delay(k div 30);
        inc(k,j);
      until (k>=2000) or (keypressed);
      inc(j,i);
    until (j>=500) or (keypressed);
    inc(i,k);
  until (i>=1000) or (keypressed);
  nosound;
end;

var
  c:char;
  s,s1,s2:string;
  changed:boolean;
  dt:datetime;
  bf:text;
  i:integer;

begin
  init;

  infield_out_fgrd:=14; infield_out_bkgd:=1;
  infield_inp_fgrd:=0; infield_inp_bkgd:=7;

  scln(#3#15+'Backup new files');
  writeln;
  showstuff;
  y:=chr(ord(hidrv)+2); oy:=y; glin;

  repeat
    case readkey of
      #0 :case ord(readkey) of
            ARROW_UP   :if y=chr(ord(hidrv)+2) then y:=pred(pred(y)) else y:=pred(y);
            ARROW_DOWN :if y=hidrv then y:=succ(succ(y)) else y:=succ(y);
            ARROW_LEFT,
            ARROW_RIGHT:begin
                          changed:=FALSE;
                          s:=sdat(lbdrv[y].lb);
                          s1:=copy(s,1,8); s2:=copy(s,10,8);
                          infield1(18,ord(y)-64,s1,8);
                          if not gooddate(s1) then s1:=copy(s,1,8);
                          if s1<>copy(s,1,8) then changed:=TRUE;
                          gotoxy(18,ord(y)-64); write(s1);
                          if changed then unsdat(s1+' '+s2,lbdrv[y].lb);
                          changed:=FALSE;
                        end;
          end;
      #13:if y>hidrv then go:=TRUE
          else begin
            tagged[y]:=not tagged[y];
            lin(0); showstuff;
            glin;
          end;
      #27:begin
            y:=chr(ord(hidrv)+3);
            go:=TRUE;
          end;
    end;
    if y>chr(ord(hidrv)+3) then y:=lodrv;
    if y<lodrv then y:=chr(ord(hidrv)+3);
    if y<>oy then glin;
  until (go);
  lin(0);

  abort:=(y=chr(ord(hidrv)+3));

  removewindow(wind);

  if not abort then begin
    for c:=lodrv to hidrv do
      if tagged[c] then begin
        inc(lbdrv[c].nacc);

        assign(bf,'tempbat.bat');
        rewrite(bf);
{        writeln(bf,'@echo off');}
        writeln(bf,'cls');
        s1:=sdat(lbdrv[c].lb); s1:=copy(s1,1,8); str(lbdrv[c].nacc,s2);
        s:=substall(cline,'@D',c);
        s:=substall(s,'@N',s2);
        s:=substall(s,'@T',s1);
        writeln(bf,s);
        close(bf);

        datnow(dt);
        lbdrv[c].lb:=dt;

        removewindow(winds);
        tell('Insert tape for drive '+c+': ...');
        if not firstq then begin
          repeat
            makesound;
            i:=0;
            repeat
              inc(i);
            until (i=0) or (keypressed);
          until keypressed;
        end;

        firstq:=FALSE;
        y:=readkey;
        removewindow(wind);
        CursorOn;

        rewrite(lbf);
        for c:=lodrv to hidrv do
          with lbdrv[c] do
            write(lbf,lbdrv[c]);
        close(lbf);

        exec(getenv('COMSPEC'),'/c tempbat.bat');
        erase(bf);
        abort:=TRUE;
        makesound;
      end;
  end;

  closeup;
end.
