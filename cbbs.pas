uses dos;

var f:text;

function tch(i:string):string;
begin
  if length(i)>2 then i:=copy(i,length(i)-1,2) else
    if length(i)=1 then i:='0'+i;
  tch:=i;
end;

function cstr(i:integer):string;
var c:string;
begin
  str(i,c);
  cstr:=c;
end;

function value(s:string):integer;
var n,n1:integer;
begin
  val(s,n,n1);
  if n1<>0 then begin
    s:=copy(s,1,n1-1);
    val(s,n,n1)
  end;
  value:=n;
  if s='' then value:=0;
end;

function time:string;
var r:registers;
    h,m,s:string[4];
begin
  r.ax:=$2c00; intr($21,dos.registers(r));
  str(r.cx shr 8,h); str(r.cx mod 256,m); str(r.dx shr 8,s);
  time:=tch(h)+':'+tch(m)+':'+tch(s);
end;

function date:string;
var r:registers;
    m,d,y:string[4];
begin
  r.ax:=$2a00; msdos(dos.registers(r)); str(r.cx,y); str(r.dx mod 256,d);
  str(r.dx shr 8,m);
  date:=tch(m)+'/'+tch(d)+'/'+tch(y);
end;

function leapyear(yr:integer):boolean;
begin
  leapyear:=(yr mod 4=0) and ((yr mod 100<>0) or (yr mod 400=0));
end;

function days(mo,yr:integer):integer;
var d:integer;
begin
  d:=value(copy('312831303130313130313031',1+(mo-1)*2,2));
  if (mo=2) and leapyear(yr) then d:=d+1;
  days:=d;
end;

function daycount(mo,yr:integer):integer;
var m,t:integer;
begin
  t:=0;
  for m:=1 to (mo-1) do t:=t+days(m,yr);
  daycount:=t;
end;

function daynum(dt:string):integer;
var d,m,y,t,c:integer;
begin
  t:=0;
  m:=value(copy(dt,1,2));
  d:=value(copy(dt,4,2));

  {rcg11182000 hahahaha...a Y2K bug.  :) }
  y:=value(copy(dt,7,2))+1900;

  {rcg11182000 added this conditional. }
  if (y < 1977) then  { Ugh...this is so bad. }
    y := y + 100;

  for c:=1985 to y-1 do
    if leapyear(c) then t:=t+366 else t:=t+365;
  t:=t+daycount(m,y)+(d-1);
  daynum:=t;
  if y<1985 then daynum:=0;
end;

function dat:string;
const mon:array [1..12] of string[3] =
          ('Jan','Feb','Mar','Apr','May','Jun',
           'Jul','Aug','Sep','Oct','Nov','Dec');
var ap,x,y:string;
    i:integer;
begin
  case daynum(date) mod 7 of
    6:x:='Mon';    3:x:='Fri';
    0:x:='Tue';    4:x:='Sat';
    1:x:='Wed';    5:x:='Sun';
    2:x:='Thu';
  end;
  y:=mon[value(copy(date,1,2))];
  x:=x+' '+y+' '+copy(date,4,2)+', '+cstr(1900+value(copy(date,7,2)));
  y:=time; i:=value(copy(y,1,2));
  if i>11 then ap:='pm' else ap:='am';
  if i>12 then i:=i-12;
  if i=0 then i:=12;
  dat:=cstr(i)+copy(y,3,3)+' '+ap+'  '+x;
end;

begin
  assign(f,paramstr(1)); rewrite(f);
  writeln(f,'lastcompiled=''Last official compilation date:  < '+dat+' >'';');
  close(f);
end.
