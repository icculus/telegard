uses crt, dos;

function c2(i:integer):string;
var s:string;
begin
  str(i,s);
  if length(s)>2 then s:=copy(s,length(s)-1,2)
    else if length(s)=1 then s:='0'+s;
  c2:=s;
end;

function getspdate(i:integer):string;
var x,y,m,d:longint;
begin
  x:=i; if x<0 then x:=x+65536;
  y:=x div 512; x:=x-512*y;
  m:=x div 32; x:=x-32*m;
  d:=x;
  getspdate:=c2(m)+'/'+c2(d)+'/'+c2(y);
end;

var
  x:integer;

begin
  write('Enter SPDATE: ');
  readln(x);
  writeln('SPDATE (',x,') = '+getspdate(x));
end.
