uses dos;

var f:file;
    r:array[1..144] of byte;
    res:word;
    i:integer;

begin
  assign(f,'bbs.ovr');
  reset(f,1);
  seek(f,filesize(f)-144);
  blockread(f,r,144,res);

  for i:=1 to 144 do write(chr(r[i]));

  writeln;
  writeln('143="'+chr(r[143])+'" (',r[143],')');
  writeln('144="'+chr(r[144])+'" (',r[144],')');

  write('143:'); readln(r[143]);
  write('144:'); readln(r[144]);

  seek(f,filesize(f)-144);
  blockwrite(f,r,144,res);
  close(f);
end.
