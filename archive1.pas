{$A+,B+,E+,F+,I+,L-,N-,O+,R-,S+,V-}
unit archive1;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  myio,
  execbat,
  common;

procedure purgedir(s:astr);                {* erase all non-dir files in dir *}
function arcmci(src,fn,ifn:astr):astr;
procedure arcdecomp(var ok:boolean; atype:integer; fn,fspec:astr);
procedure arccomp(var ok:boolean; atype:integer; fn,fspec:astr);
procedure arccomment(var ok:boolean; atype,cnum:integer; fn:astr);
procedure arcintegritytest(var ok:boolean; atype:integer; fn:astr);
procedure conva(var ok:boolean; otype,ntype:integer; tdir,ofn,nfn:astr);
function arctype(s:astr):integer;
procedure listarctypes;
procedure invarc;
procedure extracttotemp;
procedure userarchive;

implementation

uses file0, file1, file2, file4, file7, file9, file11;

const
  maxdoschrline=127;

procedure purgedir(s:astr);                {* erase all non-dir files in dir *}
var odir,odir2:astr;
    dirinfo:searchrec;
    f:file;
    att:word;
begin
  s:=fexpand(s);
  {rcg11242000 DOSism}
  {while copy(s,length(s),1)='\' do s:=copy(s,1,length(s)-1);}
  while copy(s,length(s),1)='/' do s:=copy(s,1,length(s)-1);
  getdir(0,odir); getdir(exdrv(s),odir2);
  chdir(s);
  findfirst('*.*',AnyFile-Directory,dirinfo);
  while (doserror=0) do begin
    assign(f,fexpand(dirinfo.name));
    setfattr(f,$00);           {* remove possible read-only, etc, attributes *}
    {$I-} erase(f); {$I+}      {* erase the $*@( file !!     *}
    findnext(dirinfo);         {* move on to the next one... *}
  end;
  chdir(odir2); chdir(odir);
end;

function arcmci(src,fn,ifn:astr):astr;
begin
  src:=substall(src,'@F',fn);
  src:=substall(src,'@I',ifn);
  arcmci:=src;
end;

procedure arcdecomp(var ok:boolean; atype:integer; fn,fspec:astr);
begin
  {rcg11242000 DOSism.}
  {purgedir(systat.temppath+'1\');}
  purgedir(systat.temppath+'1/');

  shel1;
  {rcg11242000 DOSism.}
  {
  execbatch(ok,TRUE,'tgtemp1.bat','tgtest1.$$$',systat.temppath+'1\',
            arcmci(systat.filearcinfo[atype].unarcline,fn,fspec),
            systat.filearcinfo[atype].succlevel);
  }
  execbatch(ok,TRUE,'tgtemp1.bat','tgtest1.$$$',systat.temppath+'1/',
            arcmci(systat.filearcinfo[atype].unarcline,fn,fspec),
            systat.filearcinfo[atype].succlevel);
  shel2;

  if (not ok) then
    sysoplog('Archive "'+fn+'": Errors during de-compression');
end;

procedure arccomp(var ok:boolean; atype:integer; fn,fspec:astr);
{* ok: result
 * atype: archive method
 * fn   : archive filename
 *}
begin
  shel1;
  {rcg11242000 DOSism.}
  {
  execbatch(ok,TRUE,'tgtemp1.bat','tgtest1.$$$',systat.temppath+'1\',
            arcmci(systat.filearcinfo[atype].arcline,fn,fspec),
            systat.filearcinfo[atype].succlevel);
  }
  execbatch(ok,TRUE,'tgtemp1.bat','tgtest1.$$$',systat.temppath+'1/',
            arcmci(systat.filearcinfo[atype].arcline,fn,fspec),
            systat.filearcinfo[atype].succlevel);
  shel2;

  if (not ok) then
    sysoplog('Archive "'+fn+'": Errors during compression');

  {rcg11242000 DOSism.}
  {purgedir(systat.temppath+'1\');}
  purgedir(systat.temppath+'1/');
end;

procedure arccomment(var ok:boolean; atype,cnum:integer; fn:astr);
var ff:text;
    tfn:astr;
    b:boolean;
begin
  if (cnum<>0) and (systat.filearccomment[cnum]<>'') then begin
    tfn:=fexpand('tgtemp2.$$$');
    assign(ff,tfn); rewrite(ff);
    writeln(ff,systat.filearccomment[cnum]); close(ff);

    shel1;
    b:=systat.swapshell; systat.swapshell:=FALSE;

    {rcg11242000 DOSism.}
    {
    execbatch(ok,FALSE,'tgtemp1.bat','tgtest1.$$$',systat.temppath+'1\',
              arcmci(systat.filearcinfo[atype].cmtline,fn,'')+' <'+tfn,
              systat.filearcinfo[atype].succlevel);
    }
    execbatch(ok,FALSE,'tgtemp1.bat','tgtest1.$$$',systat.temppath+'1/',
              arcmci(systat.filearcinfo[atype].cmtline,fn,'')+' <'+tfn,
              systat.filearcinfo[atype].succlevel);
    systat.swapshell:=b;
    shel2;

    erase(ff);
  end;
end;

procedure arcintegritytest(var ok:boolean; atype:integer; fn:astr);
begin
  if (systat.filearcinfo[atype].testline<>'') then begin
    shel1;
    {rcg11242000 DOSism.}
    {
    execbatch(ok,TRUE,'tgtemp1.bat','tgtest1.$$$',systat.temppath+'1\',
              arcmci(systat.filearcinfo[atype].testline,fn,''),
              systat.filearcinfo[atype].succlevel);
    }
    execbatch(ok,TRUE,'tgtemp1.bat','tgtest1.$$$',systat.temppath+'1/',
              arcmci(systat.filearcinfo[atype].testline,fn,''),
              systat.filearcinfo[atype].succlevel);
    shel2;
  end;
end;

procedure conva(var ok:boolean; otype,ntype:integer; tdir,ofn,nfn:astr);
var f:file;
    nofn,ps,ns,es:astr;
    eq:boolean;
begin
  star('Converting archive - stage one.');
  eq:=(otype=ntype);
  if (eq) then begin
    fsplit(ofn,ps,ns,es);
    nofn:=ps+ns+'.#$%';
  end;
  arcdecomp(ok,otype,ofn,'*.*');
  if (not ok) then star('Errors in decompression!')
  else begin
    star('Converting archive - stage two.');
    if (eq) then begin assign(f,ofn); rename(f,nofn); end;
    arccomp(ok,ntype,nfn,'*.*');
    if (not ok) then begin
      star('Errors in compression!');
      if (eq) then begin assign(f,nofn); rename(f,ofn); end;
    end;
    if (not exist(sqoutsp(nfn))) then ok:=FALSE;
  end;
end;

function arctype(s:astr):integer;
var atype:integer;
begin
  s:=align(stripname(s)); s:=copy(s,length(s)-2,3);
  atype:=1;
  while (systat.filearcinfo[atype].ext<>'') and
        (systat.filearcinfo[atype].ext<>s) and
        (atype<maxarcs+1) do
    inc(atype);
  if (atype=maxarcs+1) or (systat.filearcinfo[atype].ext='') or
     (not systat.filearcinfo[atype].active) then atype:=0;
  arctype:=atype;
end;

procedure listarctypes;
var i,j:integer;
begin
  i:=1; j:=0;
  while (systat.filearcinfo[i].ext<>'') and (i<maxarcs) do begin
    if (systat.filearcinfo[i].active) then begin
      inc(j);
      if (j=1) then prompt('Available archive formats: ') else prompt(',');
      prompt(systat.filearcinfo[i].ext);
    end;
    inc(i);
  end;
  if (j=0) then prompt('No archive formats available.');
  nl;
end;

procedure invarc;
begin
  print('Unsupported archive format.');
  nl;
  listarctypes;
  nl;
end;

procedure extracttotemp;
var fi:file of byte;
    f:ulfrec;
    s,fn,ps,ns,es:astr;
    numfiles,tsiz,lng:longint;
    pl,rn,atype:integer;
    c:char;
    abort,next,done,ok,toextract,tocopy,didsomething,nospace:boolean;
begin
  didsomething:=FALSE;
  nl;
  print('Extract to temporary directory -');
  nl;
  prompt('Already in TEMP: ');
  numfiles:=0; tsiz:=0;
  {rcg11242000 DOSism.}
  {findfirst(systat.temppath+'3\*.*',anyfile-dos.directory,dirinfo);}
  findfirst(systat.temppath+'3/*.*',anyfile-dos.directory,dirinfo);
  found:=(doserror=0);
  while (found) do begin
    inc(tsiz,dirinfo.size);
    inc(numfiles);
    findnext(dirinfo);
    found:=(doserror=0);
  end;
  if (numfiles=0) then print('Nothing.')
    else print(cstrl(numfiles)+' files totalling '+cstrl(tsiz)+' bytes.');

  if (not fso) then begin
    print('The limit is '+cstrl(systat.maxintemp)+'k bytes.');
    lng:=systat.maxintemp; lng:=lng*1024;
    if (tsiz>lng) then begin
      nl;
      print('You have exceeded this limit.');
      nl;
      print('Please remove some files from the TEMP directory using');
      print('the user-archive command to free up some space.');
      exit;
    end;
  end;

  nl;
  prt('Filename: ');
  if (fso) then input(s,69) else input(s,12);
  if (hangup) then exit;
  if (s<>'') then begin
    if ((isul(s)) and (not fso)) then begin
      nl;
      print('Invalid filename.');
    end else begin
      if (pos('.',s)=0) then s:=s+'*.*';

      ok:=TRUE; abort:=FALSE; next:=FALSE;
      if (not isul(s)) then begin
        recno(s,pl,rn); { loads memuboard ... }
        ok:=(rn<>0);
        if (ok) then begin
          seek(ulff,rn); read(ulff,f);
          fn:=fexpand(memuboard.dlpath+sqoutsp(f.filename));
          ok:=(okdl(f));
        end else
          print('File not found: "'+s+'"');
      end else begin
        fn:=fexpand(s);
        ok:=(exist(fn));
        if (ok) then begin
          assign(fi,fn);
          {$I-} reset(fi); {$I+}
          if (ioresult<>0) then print('Error accessing file.')
          else begin
            with f do begin
              filename:=align(stripname(fn));
              description:='Unlisted file.';
              filepoints:=0;
              nacc:=0;
              ft:=255;
              blocks:=trunc((filesize(fi)+127.0)/128.0);
              owner:=usernum;
              stowner:=caps(thisuser.name);
              vpointer:=-1;
              filestat:=[];
            end;
            f.date:=date;
            f.daten:=daynum(date);
          end;
        end else
          print('File not found: "'+fn+'"');
      end;
      fsplit(fn,ps,ns,es);

      if (ok) then begin
        toextract:=TRUE; tocopy:=FALSE;
        atype:=arctype(fn);
        if (atype=0) then begin
          nl;
          print('Unsupported archive format.');
          listarctypes;
          toextract:=FALSE;
        end;
        nl;
        print('You can (C)opy this file into the TEMP directory,');
        if (toextract) then begin
          print('or (E)xtract files FROM it into the TEMP directory.');
          nl; prt('Which? (CE,Q=Quit) : '); onek(c,'QCE');
        end else begin
          print('but you can''t extract files from it.');
          nl; prt('Which? (C,Q=Quit) : '); onek(c,'QC');
        end;
        nl;
        if (hangup) then exit;
        case c of
          'C':tocopy:=TRUE;
          'E':toextract:=TRUE;
        else  begin
                tocopy:=FALSE;
                toextract:=FALSE;
              end;
        end;
        if (tocopy) then toextract:=FALSE;
        if (toextract) then begin
          nl; fileinfo(f,FALSE,abort,next); nl;
          done:=FALSE;
          repeat
            prt('Extract files (<CR>=All,V=View,Q=Quit) : '); input(s,12);
            if (hangup) then exit;
            abort:=FALSE; next:=FALSE;
            if (s='') then s:='*.*';
            if (s='V') then begin
              abort:=FALSE; next:=FALSE;
              if (isul(fn)) then lfi(fn,abort,next) else lfin(rn,abort,next);
            end
            else
            if (s='Q') then done:=TRUE
            else begin
              if (isul(s)) then print('Illegal filespec.')
              else begin
                ok:=TRUE;
                s:=sqoutsp(s);
                shel1;
                {rcg11242000 DOSism}
                {
                execbatch(ok,TRUE,'tgtemp1.bat','tgtest1.$$$',systat.temppath+'3\',
                          arcmci(systat.filearcinfo[atype].unarcline,fn,s),
                          systat.filearcinfo[atype].succlevel);
                }
                execbatch(ok,TRUE,'tgtemp1.bat','tgtest1.$$$',systat.temppath+'3/',
                          arcmci(systat.filearcinfo[atype].unarcline,fn,s),
                          systat.filearcinfo[atype].succlevel);
                shel2;

                if (not ok) then begin
                  sysoplog('Archive "'+fn+'": Errors during user decompression');
                  star('Errors in decompression!');
                  nl;
                end else
                  sysoplog('User decompressed "'+s+'" into TEMP from "'+fn+'"');
                if (ok) then didsomething:=TRUE;
              end;
            end;
          until (done) or (hangup);
        end;
        if (tocopy) then begin
          {rcg11242000 DOSism.}
          {s:=systat.temppath+'3\'+ns+es; (*sqoutsp(f.filename);*)}
          s:=systat.temppath+'3/'+ns+es; (*sqoutsp(f.filename);*)
          sprompt(#3#5+'Progress: ');
          copyfile(ok,nospace,TRUE,fn,s);
          if (ok) then
            sprint(#3#5+' - Copy successful.')
          else
            if (nospace) then
              sprint(#3#7+'Copy unsuccessful - insufficient space!')
            else
              sprint(#3#7+'Copy unsuccessful!');
          sysoplog('User copied "'+fn+'" into TEMP directory.');
          if (ok) then didsomething:=TRUE;
        end;
        if (didsomething) then begin
          nl;
          print('Use the user archive menu command to access');
          print('files in the TEMP directory.');
        end;
      end;
    end;
  end;
end;

procedure userarchive;
var fi:file of byte;
    f:ulfrec;
    su:ulrec;
    s,s1,fn,savpath:astr;
    pl,atype,gotpts,oldnumbatchfiles:integer;
    c:char;
    abort,next,done,ok,savefileptratio:boolean;

  function okname(s:astr):boolean;
  begin
    okname:=TRUE;
    okname:=not iswildcard(s);
    if (isul(s)) then okname:=FALSE;
  end;

begin
  nl;
  done:=FALSE;
  repeat
    prt('Temp archive menu (?=help) : ');
    onek(c,'QADLRVT?');
    case c of
      'Q':done:=TRUE;
      '?':begin
            nl;
            listarctypes;
            nl;
            lcmds(30,3,'Add to archive','');
            lcmds(30,3,'Download files','');
            lcmds(30,3,'List files in directory','');
            lcmds(30,3,'Remove files','');
            lcmds(30,3,'Text view file','');
            lcmds(30,3,'View archive','');
            lcmds(30,3,'Quit','');
            nl;
          end;
      'A':begin
            nl; prt('Archive name: '); input(fn,12);
            if (hangup) then exit;
            {rcg11242000 DOSism.}
            {fn:=systat.temppath+'3\'+fn;}
            fn:=systat.temppath+'3/'+fn;
            loaduboard(fileboard);
            if (pos('.',fn)=0) and (memuboard.arctype<>0) then
              fn:=fn+'.'+systat.filearcinfo[memuboard.arctype].ext;
            atype:=arctype(fn);
            if (atype=0) then begin
              nl;
              print('Archive format not supported.');
              listarctypes;
              nl;
            end else begin
              prt('File mask: '); input(s,12);
              if (hangup) then exit;
              if (isul(s)) then print('Illegal file mask.')
              else
              if (s<>'') then begin
                nl;
                ok:=TRUE;
                shel1;
                {rcg11242000 DOSism.}
                {
                execbatch(ok,TRUE,'tgtemp1.bat','tgtest1.$$$',systat.temppath+'3\',
                          arcmci(systat.filearcinfo[atype].arcline,fn,s),
                          systat.filearcinfo[atype].succlevel);
                }
                execbatch(ok,TRUE,'tgtemp1.bat','tgtest1.$$$',systat.temppath+'3/',
                          arcmci(systat.filearcinfo[atype].arcline,fn,s),
                          systat.filearcinfo[atype].succlevel);
                shel2;
                if (not ok) then begin
                  sysoplog('Archive "'+fn+'": Errors during user compression');
                  star('Errors in compression!');
                  nl;
                end else
                  sysoplog('User compressed "'+s+'" into "'+fn+'"');
              end;
            end;
          end;
      'D':begin
            nl; prt('Filename: '); input(s,12);
            if (hangup) then exit;
            if (not okname(s)) then print('Illegal filename.')
            else begin
              {rcg11242000 DOSism.}
              {s:=systat.temppath+'3\'+s;}
              s:=systat.temppath+'3/'+s;
              assign(fi,s);
              {$I-} reset(fi); {$I+}
              if (ioresult=0) then begin
                f.blocks:=trunc((filesize(fi)+127.0)/128.0);
                close(fi);
                if (f.blocks<>0) then begin
                  savefileptratio:=systat.fileptratio;
                  if ((not systat.uldlratio) and
                      (not systat.fileptratio)) then
                    systat.fileptratio:=TRUE;

                  doffstuff(f,stripname(s),gotpts);

                  systat.fileptratio:=savefileptratio;

                  with f do begin
                    description:='Temporary file';
                    ft:=255;
                    vpointer:=-1;
                    filestat:=[];
                  end;

                  fiscan(pl); { loads in memuboard }
                  su:=memuboard;
                  with memuboard do begin
                    {rcg11242000 DOSisms.}
                    {
                    dlpath:=systat.temppath+'3\';
                    ulpath:=systat.temppath+'3\';
                    }
                    dlpath:=systat.temppath+'3/';
                    ulpath:=systat.temppath+'3/';
                    name:='Temporary directory';
                    fbstat:=[];
                  end;

                  oldnumbatchfiles:=numbatchfiles;
                  dlx(f,-1,abort);

                  memuboard:=su;
                  close(ulff);

                  if (numbatchfiles<>oldnumbatchfiles) then begin
                    nl;
                    sprint(#3#5+'REMEMBER: If you delete this file from the temporary directory,');
                    sprint(#3#5+'you will not be able to download it in your batch queue.');
                  end;
                end;
              end;
              nl;
            end;
          end;
      'L':begin
            nl;
            {rcg11242000 DOSism.}
            {dir(systat.temppath+'3\','*.*',TRUE);}
            dir(systat.temppath+'3/','*.*',TRUE);
            nl;
          end;
      'R':begin
            nl; prt('File mask: '); input(s,12);
            if (hangup) then exit;
            if (isul(s)) then print('Illegal filename.')
            else begin
              {rcg11242000 DOSism.}
              {s:=systat.temppath+'3\'+s;}
              s:=systat.temppath+'3/'+s;
              ffile(s);
              if (not found) then
                print('File not found.')
              else
                repeat
                  if not ((dirinfo.attr and VolumeID=VolumeID) or
                          (dirinfo.attr and Directory=Directory)) then begin
                    s:=dirinfo.name;
                    {rcg11242000 DOSism.}
                    {assign(fi,systat.temppath+'3\'+s);}
                    assign(fi,systat.temppath+'3/'+s);
                    {$I-} erase(fi); {$I+}
                    if (ioresult<>0) then begin
                      sysoplog('Error removing from temp. dir: "'+s+'"');
                      print('Error erasing "'+s+'"');
                    end else
                      sysoplog('User removed from temp. dir: "'+s+'"');
                  end;
                  nfile;
                until (not found);
            end;
            nl;
          end;
      'T':begin
            nl; prt('Filename: '); input(s,12);
            if (hangup) then exit;
            if (not okname(s)) then print('Illegal filename.')
            else begin
              {rcg11242000 DOSism.}
              {s1:=systat.temppath+'3\'+s;}
              s1:=systat.temppath+'3/'+s;
              if (not exist(s1)) then
                print('File not found.')
              else begin
                sysoplog('User ASCII viewed in temp. dir: "'+s+'"');
                nl;
                sendascii(s1);
              end;
            end;
          end;
      'V':begin
            nl; prt('File mask: '); input(fn,12);
            if (hangup) then exit;
            abort:=FALSE; next:=FALSE;
            {rcg11242000 DOSism.}
            {ffile(systat.temppath+'3\'+fn);}
            ffile(systat.temppath+'3/'+fn);
            repeat
              {rcg11242000 DOSism.}
              {lfi(systat.temppath+'3\'+dirinfo.name,abort,next);}
              lfi(systat.temppath+'3/'+dirinfo.name,abort,next);
              nfile;
            until (not found) or (abort) or (hangup);
          end;
    end;  
  until ((done) or (hangup));
  lastcommandovr:=TRUE;
end;

end.
