{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
{$M 32150,0,0}          { Declared here suffices for all Units as well! }

uses
  crt,dos,
  myio;

{$I rec16e1.pas}

var a,b,lastss,gp,sp:astr;
    h,i,j,k,savx,savy:integer;
    c:char;
    found:boolean;
    dta:string[44];
    eelevel:integer;
    wind:windowrec;
    dirinfo:searchrec;

    fil_pkunpak,fil_pkzip,fil_errlog:astr;
    zip_comments:astr;
    errlog,batfile,zipcommentsfile:text;
    ok:boolean;
    pl,rn,lrn:integer;
    fn,lfn:astr;
    fbases_to_convert,arcs_to_convert:integer;
    arcs_succ_converted:integer;

    systatf:file of systatrec;
    systat:systatrec;
    ulf:file of ulrec;
    ulff:file of ulfrec;
    ulr:ulrec;
    ulfr:ulfrec;

procedure ffile(fn:astr);
begin
  findfirst(fn,anyfile,dirinfo);
  found:=(doserror=0);
end;

procedure nfile;
var r:registers;
begin
  findnext(dirinfo);
  found:=(doserror=0);
end;

function tch(i:astr):astr;
begin
  if length(i)>2 then i:=copy(i,length(i)-1,2) else
    if length(i)=1 then i:='0'+i;
  tch:=i;
end;

function date:astr;
var reg:registers;
    m,d,y:string[4];
begin
  reg.ax:=$2a00; msdos(Dos.Registers(reg)); str(reg.cx,y); str(reg.dx mod 256,d);
  str(reg.dx shr 8,m);
  date:=tch(m)+'/'+tch(d)+'/'+tch(y);
end;

function time:astr;
var reg:registers;
    h,m,s:string[4];
begin
  reg.ax:=$2c00; intr($21,Dos.Registers(reg));
  str(reg.cx shr 8,h); str(reg.cx mod 256,m); str(reg.dx shr 8,s);
  time:=tch(h)+':'+tch(m)+':'+tch(s);
end;

function value(I:astr):integer;
var n,n1:integer;
begin
  val(i,n,n1);
  if n1<>0 then begin
    i:=copy(i,1,n1-1);
    val(i,n,n1)
  end;
  value:=n;
  if i='' then value:=0;
end;

function cstr(i:integer):astr;
var c:astr;
begin
  str(i,c);
  cstr:=c;
end;

function allcaps(s:astr):astr;    (* returns a COMPLETELY capitalized string *)
var i:integer;
begin
  for i:=1 to length(s) do
    s[i]:=upcase(s[i]);
  allcaps:=s;
end;

procedure star(s:astr);
begin
  textcolor(9); write('þ ');
  textcolor(11); writeln(s);
end;

procedure exitnow;
begin
  CursorOn;
  removewindow(wind);
  gotoxy(savx,savy);
  chdir(sp);
  halt(eelevel);
end;

procedure ee(s:astr);
begin
  clrscr;
  textcolor(4); writeln('ERROR:');
  writeln;
  textcolor(15); write('  '+s);
  gotoxy(1,15);
  textcolor(14); write('Hit any key to exit');
  CursorOff;
  repeat until keypressed;
  read(kbd,c);
  eelevel:=1;
  exitnow;
end;

procedure ss(s:astr);
begin
  lastss:=allcaps(s);
  star('Searching for "'+lastss+'"');
end;

procedure cantopen;
begin
  ee('Unable to open "'+lastss+'"');
end;

procedure alignpathname(var s:astr);
begin
  {rcg11242000 DOSisms.}
  {
  if copy(s,length(s),1)<>'\' then s:=s+'\';
  while (copy(s,length(s)-1,2)='\\') and (length(s)>2) do
  }
  if copy(s,length(s),1)<>'/' then s:=s+'/';
  while (copy(s,length(s)-1,2)='//') and (length(s)>2) do
    s:=copy(s,1,length(s)-1);
end;

function c2(i:integer):astr;
var s:astr;
begin
  str(i,s);
  if length(s)>2 then s:=copy(s,length(s)-1,2)
    else if length(s)=1 then s:='0'+s;
  c2:=s;
end;

function stripname(i:astr):astr;
var i1:astr; n:integer;

  function nextn:integer;
  var n:integer;
  begin
    n:=pos(':',i1);
    if n=0 then
      n:=pos('\',i1);
    if n=0 then
      n:=pos('/',i1);
    nextn:=n;
  end;

begin
  i1:=i;
  while nextn<>0 do
    i1:=copy(i1,nextn+1,80);
  stripname:=i1;
end;

function fit(f1,f2:astr):boolean;
var tf:boolean; c:integer;
begin
  tf:=TRUE;
  for c:=1 to 12 do
    if (f1[c]<>f2[c]) and (f1[c]<>'?') then tf:=FALSE;
  fit:=tf;
end;

function align(fn:astr):astr;
var f,e,t:astr;
    c,c1:integer;
begin
  c:=pos('.',fn);
  if c=0 then begin
    f:=fn; e:='   ';
  end else begin
    f:=copy(fn,1,c-1); e:=copy(fn,c+1,3);
  end;
  while length(f)<8 do f:=f+' ';
  while length(e)<3 do e:=e+' ';
  if length(f)>8 then f:=copy(f,1,8);
  if length(e)>3 then e:=copy(e,1,3);
  c:=pos('*',f); if c<>0 then for c1:=c to 8 do f[c1]:='?';
  c:=pos('*',e); if c<>0 then for c1:=c to 3 do e[c1]:='?';
  c:=pos(' ',f); if c<>0 then for c1:=c to 8 do f[c1]:=' ';
  c:=pos(' ',e); if c<>0 then for c1:=c to 3 do e[c1]:=' ';
  align:=f+'.'+e;
end;

procedure fiscan(var pl:integer);
var f:ulfrec;
begin
  assign(ulff,systat.gfilepath+ulr.filename+'.DIR');
  {$I-} reset(ulff); {$I+}
  if ioresult<>0 then begin
    rewrite(ulff);
    f.blocks:=0;
    write(ulff,f);
  end;
  seek(ulff,0);
  read(ulff,f);
  pl:=f.blocks;
end;

procedure recno(fn:astr; var pl,rn:integer);
var c:integer;
    f:ulfrec;
begin
  fn:=align(fn);
  fiscan(pl);
  rn:=0; c:=1;
  while (c<=pl) and (rn=0) do begin
    seek(ulff,c); read(ulff,f);
    if pos('.',f.filename)<>9 then begin
      f.filename:=align(f.filename);
      seek(ulff,c); write(ulff,f);
    end;
    if fit(fn,f.filename) then rn:=c;
    inc(c);
  end;
  lrn:=rn;
  lfn:=fn;
end;

procedure nrecno(fn:astr; var pl,rn:integer);
var c:integer;
    f:ulfrec;
begin
  rn:=0;
  if (lrn<pl) and (lrn>=0) then begin
    c:=lrn+1;
    while (c<=pl) and (rn=0) do begin
      seek(ulff,c); read(ulff,f);
      if pos('.',f.filename)<>9 then begin
        f.filename:=align(f.filename);
        seek(ulff,c); write(ulff,f);
      end;
      if fit(lfn,f.filename) then rn:=c;
      inc(c);
    end;
    lrn:=rn;
  end;
end;

procedure readulr(b:integer);
begin
  seek(ulf,b); read(ulf,ulr);
end;

procedure elog(s:astr);
begin
  writeln(errlog,s);
end;

procedure scan_file_bases;
begin
  gotoxy(1,1);
  star('Scanning file bases...');
  fbases_to_convert:=0; arcs_to_convert:=0;

  for i:=0 to filesize(ulf)-1 do begin
    readulr(i);
    recno('*.ARC',pl,rn);
    while (fn<>'') and (rn<>0) do begin
      inc(arcs_to_convert);
      nrecno('*.ARC',pl,rn);
    end;
    close(ulff);
    inc(fbases_to_convert);
    gotoxy(1,2);
    star('Total file bases to convert: '+cstr(fbases_to_convert));
  end;

  gotoxy(1,1);
  star('Total file bases to convert: '+cstr(fbases_to_convert));
  star('Total .ARC files to convert: '+cstr(arcs_to_convert));
  elog('Total file bases to convert: '+cstr(fbases_to_convert));
  elog('Total .ARC files to convert: '+cstr(arcs_to_convert));
  elog('');
end;

procedure conv_file_bases;
var arcf:astr;
    f:file of byte;
    dwind:windowrec;
    sx,sy:integer;
    oldsiz,newsiz,toldsiz,tnewsiz,ttoldsiz,ttnewsiz:real;
    numarcs,numsuccarcs:integer;
begin
  gotoxy(1,4);
  star('Converting file bases...');
  arcs_succ_converted:=0;

  ttoldsiz:=0.0; ttnewsiz:=0.0;

  for i:=0 to filesize(ulf)-1 do begin
    toldsiz:=0.0; tnewsiz:=0.0; numarcs:=0; numsuccarcs:=0;
    gotoxy(1,5);
    star('Converting file base: '+cstr(i));
    readulr(i);
    recno('*.ARC',pl,rn);
    while (fn<>'') and (rn<>0) do begin
      seek(ulff,rn); read(ulff,ulfr);
      arcf:=copy(ulfr.filename,1,8);
      if pos(' ',arcf)>0 then arcf:=copy(arcf,1,pos(' ',arcf)-1);
      arcf:=ulr.dlpath+arcf;

      gotoxy(1,6); clreol; star('Converting file: '+arcf+'.ARC');

      inc(numarcs);
      assign(f,arcf+'.ARC');
      {$I-} reset(f); {$I+}
      if ioresult<>0 then begin
        elog(arcf+'.ARC: File not found.');
      end else begin
        {rcg11172000 don't have LONGfilesize()...}
        {oldsiz:=longfilesize(f);}
        oldsiz:=filesize(f);
        close(f);
        ttoldsiz:=ttoldsiz+oldsiz; toldsiz:=toldsiz+oldsiz;

        sx:=wherex; sy:=wherey;
        savescreen(dwind,1,1,80,25);
        window(1,1,80,25); gotoxy(1,1);
        exec(getenv('COMSPEC'),'/c temp$$$.bat '+arcf+' >nul');
        removewindow(dwind);
        window(11,6,71,20); textbackground(1); textcolor(9); gotoxy(sx,sy);

        assign(f,arcf+'.ZIP');
        {$I-} reset(f); {$I+}
        if ioresult<>0 then begin
          elog(arcf+'.ARC: Incomplete conversion.');
        end else begin
          {rcg11172000 don't have LONGfilesize()...}
          {newsiz:=longfilesize(f);}
          newsiz:=filesize(f);
          close(f);
          ttnewsiz:=ttnewsiz+newsiz; tnewsiz:=tnewsiz+newsiz;
          if newsiz=0 then begin
            elog(arcf+'.ARC: Incomplete conversion.');
          end else begin
            assign(f,arcf+'.ARC');
            {$I-} erase(f); {$I+}
            if ioresult<>0 then elog(arcf+'.ARC: Unable to delete.');

            ulfr.filename:=align(stripname(arcf+'.ZIP'));
            ulfr.blocks:=trunc((newsiz+127.0)/128.0);
            seek(ulff,rn); write(ulff,ulfr);
            inc(arcs_succ_converted);
            inc(numsuccarcs);
          end;
        end;
        chdir('A2Z.$$$');
        if ioresult=0 then begin
          ffile('*.*');
          if found then
            repeat
              if (dirinfo.attr and Directory=0) then begin
                assign(f,dirinfo.name);
                {$I-} erase(f); {$I+}
              end;
              nfile;
            until not found;
          chdir('..');
        end;
      end;

      nrecno('*.ARC',pl,rn);
    end;
    close(ulff);
    if numarcs<>0 then begin
      elog('File base '+cstr(i)+': '+cstr(numsuccarcs)+' of '+cstr(numarcs)+' .ARC files successfully converted.');
      elog('          Old .ARC file size: '+cstr(trunc((toldsiz+0.1)/1024.0))+
           'k / New size: '+cstr(trunc((tnewsiz+0.1)/1024.0))+
           'k / Saved: '+cstr(trunc((toldsiz-tnewsiz+0.1)/1024.0))+'k.');
    end else
      elog('File base '+cstr(i)+': No .ARC files.');
  end;

  writeln;
  star('Total .ARC files successfully converted: '+cstr(arcs_succ_converted)+'.');

  elog('');
  elog('Total .ARC files successfully converted: '+cstr(arcs_succ_converted)+'.');
  elog('Old .ARC file size: '+cstr(trunc((ttoldsiz+0.1)/1024.0))+
       'k / New size: '+cstr(trunc((ttnewsiz+0.1)/1024.0))+
       'k / Saved: '+cstr(trunc((ttoldsiz-ttnewsiz+0.1)/1024.0))+'k.');
end;

begin
  infield_out_fgrd:=15;
  infield_out_bkgd:=1;
  infield_inp_fgrd:=0;
  infield_inp_bkgd:=7;

  eelevel:=0;

  getdir(0,sp);

  savx:=wherex; savy:=wherey;
  setwindow(wind,10,3,72,21,9,1,1);
  clrscr;
  textcolor(15); write('CONVERSION UTILITY for Telegard '+ver+': ');
  textcolor(10); write('.ARC');
  textcolor(4); write(' ¯¯¯¯¯¯¯¯¯ ');
  textcolor(9); write('.ZIP');
  writeln;
  textcolor(9); for i:=1 to 69 do write('Ä');
  window(11,6,71,20); clrscr;
  textcolor(15);
           {-----------------------------------------------------------}
  writeln('This program is provided to convert ALL of the .ARC files on');
  writeln('your Telegard v'+ver+' BBS to the newer .ZIP format.  PKZIP.EXE');
  writeln('and PKUNPAK.EXE/PKXARC.EXE are required for operation, and');
  writeln('should be somewhere on the PATH.');
  writeln;
  writeln('This program will abort if it is NOT being executed from');
  writeln('your main BBS directory, with STATUS.DAT in it.');
  gotoxy(1,15);
  CursorOff;
  textcolor(14); write('Hit <ESC> to abort now, any other key to continue');
  repeat until keypressed;
  read(kbd,c);
  if c=#27 then exitnow;
  CursorOn;

  assign(systatf,'status.dat');
  {$I-} reset(systatf); {$I+}
  if ioresult<>0 then ee('STATUS.DAT: File not found.');
  read(systatf,systat); close(systatf);

  assign(ulf,systat.gfilepath+'uploads.dat');
  {$I-} reset(ulf); {$I+}
  if ioresult<>0 then ee(systat.gfilepath+'UPLOADS.DAT: File not found.');

  {$I-} rmdir('A2Z.$$$'); {$I+}
  if ioresult=0 then CursorOn; {do nothing}
  {$I-} mkdir('A2Z.$$$'); {$I+}
  if ioresult<>0 then ee('A2Z.$$$: Unable to create directory.');

  assign(batfile,'temp$$$.bat');
  {$I-} rewrite(batfile); {$I+}
  if ioresult<>0 then ee('TEMP$$$.BAT: Unable to create file.');

  repeat
    fil_pkunpak:='PKUNPAK'; fil_pkzip:='PKZIP -aeb4z';
    clrscr;
    textcolor(15);
    writeln('ARC/ZIP utility filenames');
    textcolor(11);
    writeln;
    writeln('Enter the filename and parameters of your ARC extract');
    writeln('utility.  It should be somewhere on the PATH.');
    writeln;
    textcolor(9); write('UNARCing params: ');
    infield1(wherex,wherey,fil_pkunpak,40);
    writeln;
    writeln;
    writeln;
    textcolor(11);
    writeln('Enter the filename and parameters of your ZIP create/update');
    writeln('utility.  It should be somewhere on the PATH.');
    writeln;
    textcolor(9); write('ZIPing params: ');
    infield1(wherex,wherey,fil_pkzip,40);
    clrscr;
    fil_errlog:='TA2Z.LOG';
    repeat
      clrscr;
      textcolor(15);
      writeln('Error log file');
      textcolor(11);
      writeln;
      writeln('A list of all conversion errors that occur will be output to');
      writeln('a log file.');
      writeln;
      textcolor(9); write('A2Z log filespec: ');
      infield1(wherex,wherey,fil_errlog,40); fil_errlog:=allcaps(fil_errlog);
      ok:=TRUE;
      assign(errlog,fil_errlog);
      {$I-} reset(errlog); {$I+}
      if ioresult=0 then begin
        close(errlog);
        writeln;
        writeln;
        ok:=l_pynq('"'+fil_errlog+'" exists --  Append to end? ');
      end;
    until ok;

    zip_comments:=systat.bbsname+'  '+systat.bbsphone;
    clrscr;
    textcolor(15);
    writeln('BBS advertisement');
    textcolor(11);
    writeln;
    writeln('The comment field of each .ZIP file may be used to for');
    writeln('advertising your BBS.  If you wish to do so, you may place');
    writeln('whatever comments you like into each converted .ZIP file.');
    writeln;
    textcolor(9); write('Comments: ');
    infield1(wherex,wherey,zip_comments,32);

    clrscr;
    textcolor(9); write('UNARC params: '); textcolor(15); writeln(fil_pkunpak);
    textcolor(9); write('ZIP params:   '); textcolor(15); writeln(fil_pkzip);
    textcolor(9); write('Log filespec: '); textcolor(15); writeln(fil_errlog);
    textcolor(9); write('Advertisement:'); textcolor(15); writeln(zip_comments);
    writeln;
    writeln;
  until l_pynq('Is this OK? ');

  clrscr;
  textcolor(9);

  assign(zipcommentsfile,'temp$$$.txt');
  {$I-} rewrite(zipcommentsfile); {$I+}
  if ioresult<>0 then ee('TEMP$$$.TXT: Unable to open.');
  writeln(zipcommentsfile,zip_comments);
  close(zipcommentsfile);

  writeln(batfile,'@echo off');
  writeln(batfile,'cd a2z.$$$');
  writeln(batfile,fil_pkunpak+' %1.ARC >nul');
  writeln(batfile,fil_pkzip+' %1.ZIP <..\temp$$$.txt >nul');
  writeln(batfile,'cd ..');
  close(batfile);

  {$I-} reset(errlog); {$I+}
  if ioresult<>0 then begin
    {$I-} rewrite(errlog); {$I+}
    if ioresult<>0 then ee(fil_errlog+': Unable to create.');
  end;
  {$I-} append(errlog); {$I+}
  if ioresult<>0 then ee(fil_errlog+': Unable to append to.');

  elog('');
  elog('');
  elog('');
  elog('Telegard v'+ver+' ARC ---> ZIP file conversion utility');
  elog('');
  elog('Began conversion on '+date+' '+time+'.');
  elog('');

  scan_file_bases;
  conv_file_bases;

  elog('');
  elog('Completed conversion on '+date+' '+time+'.');

  writeln;
  star('Press any key to continue');
  c:=readkey;

  close(ulf);
  {$I-} rmdir('A2Z.$$$'); {$I+}
  close(errlog);
  erase(batfile); erase(zipcommentsfile);

  removewindow(wind);

  setwindow(wind,20,11,59,17,9,1,1);
  clrscr; textcolor(15);
  gotoxy(4,3);
  write('Thank you for choosing Telegard!');
  CursorOff; delay(1500);
  exitnow;
end.
