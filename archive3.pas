{$A+,B+,D-,E+,F+,I+,L-,N-,O+,R-,S+,V-}
unit archive3;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  archive1,
  common,
  execbat,
  file0, file11;

procedure rezipstuff;

implementation

var rezipcmd:string;

procedure cvtfiles(b:integer; fn:astr; var c_files,c_oldsiz,c_newsiz:longint;
                   var abort,next:boolean);
var fi:file of byte;
    f:ulfrec;
    s,ps,ns,es:astr;
    oldsiz,newsiz:longint;
    oldboard,pl,rn,atype:integer;
    ok:boolean;
begin
  oldboard:=fileboard;
  if (fileboard<>b) then changefileboard(b);
  if (fileboard=b) then begin
    recno(fn,pl,rn); { loads in memuboard }
    abort:=FALSE; next:=FALSE;
    while (fn<>'') and (rn<>0) and (not abort) and (not hangup) do begin
      seek(ulff,rn); read(ulff,f);
      fn:=memuboard.dlpath+f.filename;
      atype:=arctype(fn);
      if (atype<>0) then begin
        pbn(abort,next); nl;
        star('Converting "'+sqoutsp(fn)+'"');
        ok:=FALSE;
        if (not exist(fn)) then
          star('File "'+sqoutsp(fn)+'" doesn''t exist.')
        else begin
          if (rezipcmd<>'') then begin
            assign(fi,sqoutsp(fn));
            {$I-} reset(fi); {$I+}
            if (ioresult=0) then begin
              oldsiz:=trunc(filesize(fi));
              close(fi);
            end;
            shel1;
            execbatch(ok,TRUE,'tgtemp1.bat','tgtest1.$$$',systat.temppath+'1\',
                      rezipcmd+' '+sqoutsp(fn),-1);
            shel2;
            assign(fi,sqoutsp(fn));
            {$I-} reset(fi); {$I+}
            if (ioresult=0) then begin
              newsiz:=trunc(filesize(fi));
              f.blocks:=trunc((filesize(fi)+127.0)/128.0);
              close(fi);
              seek(ulff,rn); write(ulff,f);
            end;
          end else begin
            ok:=TRUE;
            s:=fn;
            conva(ok,atype,atype,systat.temppath+'1\',sqoutsp(fn),sqoutsp(s));
            if (ok) then begin
              fsplit(fn,ps,ns,es); fn:=ps+ns+'.#$%';
              assign(fi,sqoutsp(fn));
              {$I-} reset(fi); {$I+}
              ok:=(ioresult=0);
              if (ok) then begin
                oldsiz:=trunc(filesize(fi));
                close(fi);
              end else
                star('Unable to access "'+sqoutsp(fn)+'"');
              if (ok) then
                if (not exist(sqoutsp(s))) then begin
                  star('Unable to access "'+sqoutsp(s)+'"');
                  sysoplog('Unable to access "'+sqoutsp(s)+'"');
                  ok:=FALSE;
                end;
            end;
            if (ok) then begin
              f.filename:=align(stripname(sqoutsp(s)));
              seek(ulff,rn); write(ulff,f);

              fsplit(fn,ps,ns,es); fn:=ps+ns+'.#$%';
              assign(fi,fn); {$I-} erase(fi); {$I+}

              if (ioresult<>0) then begin
                star('Unable to erase "'+sqoutsp(fn)+'"');
                sysoplog('Unable to erase "'+sqoutsp(fn)+'"');
              end;

              assign(fi,sqoutsp(s));
              {$I-} reset(fi); {$I+}
              ok:=(ioresult=0);
              if (not ok) then begin
                star('Unable to access "'+sqoutsp(s)+'"');
                sysoplog('Unable to access "'+sqoutsp(s)+'"');
              end else begin
                newsiz:=trunc(filesize(fi));
                f.blocks:=trunc((filesize(fi)+127.0)/128.0);
                close(fi);
                seek(ulff,rn); write(ulff,f);
                arccomment(ok,atype,memuboard.cmttype,sqoutsp(s));
              end;
            end else begin
              sysoplog('Unable to convert "'+sqoutsp(fn)+'"');
              star('Unable to convert "'+sqoutsp(fn)+'"');
            end;
          end;
          if (ok) then begin
            inc(c_oldsiz,oldsiz);
            inc(c_newsiz,newsiz);
            inc(c_files);
            star('Old total space took up  : '+cstrl(oldsiz)+' bytes');
            star('New total space taken up : '+cstrl(newsiz)+' bytes');
            if (oldsiz-newsiz>0) then
              star('Space saved              : '+cstrl(oldsiz-newsiz)+' bytes')
            else
              star('Space wasted             : '+cstrl(newsiz-oldsiz)+' bytes');
          end;
        end;
      end;
      nrecno(fn,pl,rn);
      wkey(abort,next);
    end;
    close(ulff);
  end;
  fileboard:=oldboard;
end;

procedure rezipstuff;
var fn:astr;
    c_files,c_oldsiz,c_newsiz:longint;
    i:integer;
    abort,next,ok1:boolean;
begin
  nl;
  print('Re-compress archives -');
  nl;
  print('Filespec:');
  prt(':'); mpl(78); input(fn,78);
  c_files:=0; c_oldsiz:=0; c_newsiz:=0;
  if (fn<>'') then begin
    nl;
    sprint(#3#7+'Do you wish to use a REZIP external utility?');
    if pynq('(such as REZIP.EXE) ? (Y/N) : ') then begin
      nl;
      prt('Enter commandline (example: "REZIP") : ');
      input(rezipcmd,100);
      if (rezipcmd='') then exit;
    end else
      rezipcmd:='';
    nl;
    abort:=FALSE; next:=FALSE;
    ok1:=pynq('Search all directories? ');
    nl;
    sysoplog('Conversion process began at '+date+' '+time+'.');
    print('Conversion process began at '+date+' '+time+'.');
    nl;
    if (ok1) then begin
      i:=0; abort:=FALSE; next:=FALSE;
      while ((not abort) and (i<=maxulb) and (not hangup)) do begin
        if (fbaseac(i)) then
          cvtfiles(i,fn,c_files,c_oldsiz,c_newsiz,abort,next);
        inc(i);
        wkey(abort,next);
        if (next) then abort:=FALSE;
      end;
    end else
      cvtfiles(fileboard,fn,c_files,c_oldsiz,c_newsiz,abort,next);
  end;
  nl;
  sysoplog('Conversion process ended at '+date+' '+time+'.');
  print('Conversion process ended at '+date+' '+time+'.');
  nl;
  nl;
  star('Total archives converted : '+cstr(c_files));
  star('Old total space took up  : '+cstrl(c_oldsiz)+' bytes');
  star('New total space taken up : '+cstrl(c_newsiz)+' bytes');
  if (c_oldsiz-c_newsiz>0) then
    star('Space saved              : '+cstrl(c_oldsiz-c_newsiz)+' bytes')
  else
    star('Space wasted             : '+cstrl(c_newsiz-c_oldsiz)+' bytes');
  sysoplog('Converted '+cstr(c_files)+' archives; old size='+
           cstrl(c_oldsiz)+' bytes, new size='+cstrl(c_newsiz)+' bytes');
end;

end.
