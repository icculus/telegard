{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit file14;

interface

uses
  crt,dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  myio,
  file0, file11,
  common;

procedure getgifspecs(fn:astr; var sig:astr; var x,y,c:word);
procedure dogifspecs(fn:astr; var abort,next:boolean);
procedure addgifspecs;

implementation

procedure getgifspecs(fn:astr; var sig:astr; var x,y,c:word);
var f:file;
    rec:array[1..11] of byte;
    c1,i,numread:word;
begin
  assign(f,fn);
  {$I-} reset(f,1); {$I+}
  if (ioresult<>0) then begin
    sig:='NOTFOUND';
    exit;
  end;

  blockread(f,rec,11,numread);
  close(f);

  if (numread<>11) then begin
    sig:='BADGIF';
    exit;
  end;

  sig:='';
  for i:=1 to 6 do sig:=sig+chr(rec[i]);

  x:=rec[7]+rec[8]*256;
  y:=rec[9]+rec[10]*256;
  c1:=(rec[11] and 7)+1;
  c:=1;
  for i:=1 to c1 do c:=c*2;
end;

procedure dogifspecs(fn:astr; var abort,next:boolean);
var s,sig:astr;
    x,y,c:word;
begin
  getgifspecs(fn,sig,x,y,c);
  s:=#3#3+align(stripname(fn));
  if (sig='NOTFOUND') then
    s:=s+'   '+#3#7+'NOT FOUND'
  else
    s:=s+'   '+#3#5+mln(cstrl(x)+'x'+cstrl(y),10)+'   '+
         mln(cstr(c)+' colors',10)+'   '+#3#7+sig;
  printacr(s,abort,next);
end;

procedure addgifspecs;
var f:ulfrec;
    gifstart,gifend,tooktime:datetimerec;
    s,sig:astr;
    totfils:longint;
    x,y,c:word;
    pl,rn,savflistopt:integer;
    abort,next:boolean;
begin
  nl;
  print('Adding GifSpecs to files -');
  nl;
  recno('*.*',pl,rn);
  if (baddlpath) then exit;

  savflistopt:=thisuser.flistopt;

  totfils:=0; abort:=FALSE; next:=FALSE;
  getdatetime(gifstart);

  while (rn<>0) and (pl<>0) and (rn<=pl) and
        (not abort) and (not hangup) do begin
    seek(ulff,rn); read(ulff,f);
    if ((isgifext(f.filename)) and (not isgifdesc(f.description))) then begin
      getgifspecs(memuboard.dlpath+sqoutsp(f.filename),sig,x,y,c);
      if (sig<>'NOTFOUND') then begin
        s:='('+cstrl(x)+'x'+cstrl(y)+','+cstr(c)+'c) ';
        f.description:=s+f.description;
        if (length(f.description)>54) then
          f.description:=copy(f.description,1,54);
        seek(ulff,rn); write(ulff,f);
        pfn(rn,f,abort,next);
        inc(totfils);
      end;
    end;
    nrecno('*.*',pl,rn);
    wkey(abort,next);
  end;
  getdatetime(gifend);
  timediff(tooktime,gifstart,gifend);

  thisuser.flistopt:=savflistopt;

  nl;
  s:='Added GifSpecs to '+cstrl(totfils)+' file';
  if (totfils<>1) then s:=s+'s';
  s:=s+' - Took '+longtim(tooktime);
  print(s);

  close(ulff);
end;

end.
