{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit mdek;

interface


{rcg11172000 no overlay under Linux.}
{uses overlay;}


function encrypt(os:string; c1,c2,c3,c4,c5,c6:byte):string;
function decrypt(os:string; c1,c2,c3,c4,c5,c6:byte):string;

implementation

function encrypt(os:string; c1,c2,c3,c4,c5,c6:byte):string;
var ns:string;
    codes:array[1..6] of byte;
    c,d,i,j,k,l:integer;
begin
  for i:=1 to 6 do
    case i of 1:codes[i]:=c1; 2:codes[i]:=c2; 3:codes[i]:=c3;
              4:codes[i]:=c4; 5:codes[i]:=c5; 6:codes[i]:=c6; end;
  j:=0; k:=1; l:=1;
  for i:=1 to length(os) do begin
    inc(j);
    if (j>6) then begin
      dec(k); j:=1;
      if (k<1) then begin
        dec(l); k:=6;
        if (l<1) then begin
          j:=1; k:=6; l:=6;
        end;
      end;
    end;
    d:=codes[j]+codes[k]+codes[l];
    os[i]:=chr((ord(os[i])+d) mod 256);
  end;
  encrypt:=os;
end;

function decrypt(os:string; c1,c2,c3,c4,c5,c6:byte):string;
var ns:string;
    codes:array[1..6] of byte;
    c,d,i,j,k,l:integer;
begin
  for i:=1 to 6 do
    case i of 1:codes[i]:=c1; 2:codes[i]:=c2; 3:codes[i]:=c3;
              4:codes[i]:=c4; 5:codes[i]:=c5; 6:codes[i]:=c6; end;
  j:=0; k:=1; l:=1;
  for i:=1 to length(os) do begin
    inc(j);
    if (j>6) then begin
      dec(k); j:=1;
      if (k<1) then begin
        dec(l); k:=6;
        if (l<1) then begin
          j:=1; k:=6; l:=6;
        end;
      end;
    end;
    d:=codes[j]+codes[k]+codes[l];
    os[i]:=chr((1024+(ord(os[i])-d)) mod 256);
  end;
  decrypt:=os;
end;

end.
