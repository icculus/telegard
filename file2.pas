{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit file2;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  execbat, file0,
  common;

procedure copyfile(var ok,nospace:boolean; showprog:boolean;
                   srcname,destname:astr);
procedure movefile(var ok,nospace:boolean; showprog:boolean;
                   srcname,destname:astr);

implementation

procedure copyfile(var ok,nospace:boolean; showprog:boolean;
                   srcname,destname:astr);
var buffer:array[1..16384] of byte;
    fs,dfs:longint;
    nrec,i:integer;
    src,dest:file;

  procedure dodate;
  {rcg11172000 DOSism. Stubbed.}
  {
  var r:registers;
      od,ot,ha:integer;
  begin
    srcname:=srcname+#0;
    destname:=destname+#0;
    with r do begin
      ax:=$3d00; ds:=seg(srcname[1]); dx:=ofs(srcname[1]); msdos(dos.registers(r));
      ha:=ax; bx:=ha; ax:=$5700; msdos(dos.registers(r));
      od:=dx; ot:=cx; bx:=ha; ax:=$3e00; msdos(dos.registers(r));
      ax:=$3d02; ds:=seg(destname[1]); dx:=ofs(destname[1]); msdos(dos.registers(r));
      ha:=ax; bx:=ha; ax:=$5701; cx:=ot; dx:=od; msdos(dos.registers(r));
      ax:=$3e00; bx:=ha; msdos(dos.registers(r));
    end;
  end;
  }
  begin
     writeln('STUB: file2.pas; dodate()...');
  end;

begin
  ok:=TRUE; nospace:=FALSE;
  assign(src,srcname);
  {$I-} reset(src,1); {$I+}
  if (ioresult<>0) then begin ok:=FALSE; exit; end;
  dfs:=freek(exdrv(destname));
  fs:=trunc(filesize(src)/1024.0)+1;
  if (fs>=dfs) then begin
    close(src);
    nospace:=TRUE; ok:=FALSE;
    exit;
  end else begin
    assign(dest,destname);
    {$I-} rewrite(dest,1); {$I+}
    if (ioresult<>0) then begin ok:=FALSE; exit; end;
    if (showprog) then begin
      cl(7);
      for i:=1 to fs div 16 do prompt('.');
      for i:=1 to fs div 16 do prompt(^H);
      cl(5);
    end;
    repeat
      blockread(src,buffer,16384,nrec);
      blockwrite(dest,buffer,nrec);
      if (showprog) then prompt('o');
    until (nrec<16384);
    if (showprog) then begin
      for i:=1 to (fs div 16)+1 do prompt(^H);
      for i:=1 to (fs div 16)+1 do prompt(' ');
      for i:=1 to (fs div 16)+1 do prompt(^H);
      sprompt('^7*^5DONE^7*');
    end;
    close(dest); close(src);
    dodate;
  end;
end;

{rcg11172000 had to change this to get it compiling under Free Pascal...}
{function substall(src,old,new:astr):astr;}
function substall(src,old,_new:astr):astr;
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

procedure movline(var src:astr; s1,s2:astr);
begin
  src:=substall(src,'@F',s1);
  src:=substall(src,'@I',s2);
end;

procedure movefile(var ok,nospace:boolean; showprog:boolean;
                   srcname,destname:astr);
var dfs,dft:integer;
    f:file;
    s,s1,s2,s3,opath:astr;
begin
  ok:=TRUE; nospace:=FALSE;

  getdir(0,opath);
  assign(f,srcname); reset(f,1);
  dft:=trunc(filesize(f)/1024.0)+1; close(f);

  dfs:=freek(exdrv(destname));
  copyfile(ok,nospace,showprog,srcname,destname);
  if ((ok) and (not nospace)) then begin
    {$I-} erase(f); {$I+}
  end;
  chdir(opath);
end;

end.
