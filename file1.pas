{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit file1;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  myio, common;

procedure dodl(fpneed:integer);
procedure doul(pts:integer);
procedure showuserfileinfo;
function okdl(f:ulfrec):boolean;
procedure dlx(f1:ulfrec; rn:integer; var abort:boolean);
procedure dl(fn:astr);
procedure dodescrs(var f:ulfrec; var v:verbrec; var pl:integer; var tosysop:boolean);
procedure writefv(rn:integer; f:ulfrec; v:verbrec);
procedure newff(f:ulfrec; v:verbrec);
procedure doffstuff(var f:ulfrec; fn:astr; var gotpts:integer);
procedure arcstuff(var ok,convt:boolean; var blks:integer; var convtime:real;
                   itest:boolean; fpath:astr; var fn,descr:astr);
procedure idl;
procedure iul;

procedure fbaselist;
procedure unlisted_download(s:astr);
procedure do_unlisted_download;
function nfvpointer:longint;

implementation

uses
  file0, file4, file8, file14,
  mail2,
  archive1;

var
  locbatup:boolean;

procedure dodl(fpneed:integer);
begin
  nl;
  nl;
  if (not aacs(systat.nofilepts)) or
     (not (fnofilepts in thisuser.ac)) then begin
    if (fpneed>0) then dec(thisuser.filepoints,fpneed);
    if (thisuser.filepoints<0) then thisuser.filepoints:=0;
    sprint(#3#5+'Enjoy the file, '+thisuser.name+'!');
    if (fpneed<>0) then
      sprint(#3#5+'Your file points have been deducted to '+cstr(thisuser.filepoints)+'.');
  end;
end;

procedure doul(pts:integer);
begin
  if (not aacs(systat.ulvalreq)) then begin
    sprint(#3#5+'Thanks for the upload, '+thisuser.name+'!');
    if (systat.uldlratio) then
      sprint(#3#5+'You will receive file credit as soon as the SysOp validates the file!')
    else
      sprint(#3#5+'You will receive file points as soon as the SysOp validates the file!');
  end else
    if ((not systat.uldlratio) and (not systat.fileptratio) and (pts=0)) then begin
      sprint(#3#5+'Thanks for the upload, '+thisuser.name+'!');
      sprint(#3#5+'You will receive file points as soon as the Sysop validates the file!');
    end else
      inc(thisuser.filepoints,pts);
end;

procedure showuserfileinfo;
begin
  with thisuser do
    commandline('U/L: '+cstr(uploads)+'/'+cstr(trunc(uk))+
            'k ³ D/L: '+cstr(downloads)+'/'+cstr(trunc(dk))+'k');
end;

function okdl(f:ulfrec):boolean;
var s:astr;
    b:boolean;

  procedure nope(s:astr);
  begin
    if (b) then sprint(s);
    b:=FALSE;
  end;

begin
  b:=TRUE;
  if (isrequest in f.filestat) then begin
    printf('reqfile');
    if (nofile) then begin
      nl;
      sprint(#3#5+'You must Request this file -- Ask '+
             systat.sysopname+' for it.');
      nl;
    end;
    dyny:=TRUE;
    if (pynq('Request this file now? [Y] : ')) then begin
      s:=sqoutsp(f.filename);
      irt:='File Request of "'+s+'" from file base #'+cstr(ccuboards[1][fileboard]);
      imail(1);
    end;
    b:=FALSE;
  end;
  if ((resumelater in f.filestat) and (not fso)) then
    nope('You can''t do anything with RESUME-LATER files.');
  if ((notval in f.filestat) and (not aacs(systat.dlunval))) then
    nope('You can''t do anything with UNVALIDATED files.');
  if (thisuser.filepoints<f.filepoints) and (f.filepoints>0) and
     (not aacs(systat.nofilepts)) and
     (not (fnofilepts in thisuser.ac)) and
     (not (fbnoratio in memuboard.fbstat)) then
    nope(fstring.nofilepts);
  if (nsl<rte*f.blocks) then
    nope('Not enough time to download.');
  if (not exist(memuboard.dlpath+f.filename)) then begin
    nope('File isn''t really there!');
    sysoplog('File missing in file list: '+sqoutsp(memuboard.dlpath+f.filename));
  end;
  okdl:=b;
end;

procedure dlx(f1:ulfrec; rn:integer; var abort:boolean);
var u:userrec;
    tooktime,xferstart,xferend:datetimerec;
    i,ii,tt,bar,s:astr;
    rl,tooktime1:real;
    cps,lng:longint;
    inte,pl,z:integer;
    c:char;
    next,ps,ok,tl:boolean;
begin
  abort:=FALSE; next:=FALSE;
  nl;
  fileinfo(f1,FALSE,abort,next);

  ps:=TRUE;
  abort:=FALSE;
  if (not okdl(f1)) then ps:=TRUE
  else begin
    ps:=FALSE;
    showuserfileinfo;

    getdatetime(xferstart);
    send1(memuboard.dlpath+f1.filename,ok,abort);
    getdatetime(xferend);
    timediff(tooktime,xferstart,xferend);

    if (not (-lastprot in [10,11,12])) then
      if (not abort) then
        if (not ok) then begin
          star('Download unsuccessful.');
          sysoplog(#3#3+'Tried download "'+sqoutsp(f1.filename)+
                   '" from '+memuboard.name);
          ps:=TRUE;
        end else begin
          if (not (fbnoratio in memuboard.fbstat)) then begin
            inc(thisuser.downloads);
            thisuser.dk:=thisuser.dk+(f1.blocks div 8);
          end;
          inc(systat.todayzlog.downloads);
          inc(systat.todayzlog.dk,(f1.blocks div 8));

          if (not incom) then nl;

          lng:=f1.blocks; lng:=lng*128;
          star('1 file successfully sent - Took: '+longtim(tooktime));
          s:=  'Total: '+cstrl(lng)+' bytes';
          if (fbnoratio in memuboard.fbstat) then s:=s+#3#5+' <No-Ratio>';
          star(s);

          s:=#3#3+'Download "'+sqoutsp(f1.filename)+'" from '+memuboard.name;

          tooktime1:=dt2r(tooktime);
          if (tooktime1>=1.0) then begin
            cps:=f1.blocks; cps:=cps*128;
            cps:=trunc(cps/tooktime1);
          end else
            cps:=0;

          s:=s+#3#3+' ('+cstr(f1.blocks div 8)+'k, '+ctim(dt2r(tooktime))+
               ', '+cstr(cps)+' cps)';
          sysoplog(s);
          if (not (fbnoratio in memuboard.fbstat)) and
             (f1.filepoints>0) then dodl(f1.filepoints);
          showuserfileinfo;

          if (rn<>-1) then begin
            inc(f1.nacc);
            seek(ulff,rn); write(ulff,f1);
          end;
        end;
  end;
  if (ps) then begin
    nl;
    sprompt(#3#5+'Continue with <CR> or [Q]uit :'+#3#3);
    onek(c,'Q '^M);
    abort:=(c='Q');
  end;
end;

procedure dl(fn:astr);
var pl,rn:integer;
    f:ulfrec;
    abort:boolean;
begin
  abort:=FALSE;
  recno(fn,pl,rn);
  if (baddlpath) then exit;
  if (rn=0) then print('File not found.')
  else
    while (rn<>0) and (not abort) and (not hangup) do begin
      reset(ulff);
      seek(ulff,rn); read(ulff,f);
      nl;
      dlx(f,rn,abort);
      nrecno(fn,pl,rn);
    end;
  reset(uf); close(uf);
  close(ulff);
end;

procedure idl;
var s:astr; down:boolean;
begin
  down:=TRUE;
  if (not intime(timer,systat.dllowtime,systat.dlhitime)) then down:=FALSE;
  if (spd='300') then
    if (not intime(timer,systat.b300dllowtime,systat.b300dlhitime)) then
      down:=FALSE;
  if (not down) then printf('dlhours')
  else begin
    nl;
    sprint(fstring.downloadline);
    nl;
    prt('Filename: '); mpl(12); input(s,12);
    if (s<>'') then dl(s);
  end;
end;

procedure dodescrs(var f:ulfrec;              {* file record      *}
                   var v:verbrec;             {* verbose description record *}
                   var pl:integer;            {* # files in dir   *}
                   var tosysop:boolean);      {* whether to-SysOp *}
var i,maxlen:integer;
    isgif:boolean;
begin
  if ((tosysop) and (systat.tosysopdir<>255) and
      (systat.tosysopdir>=0) and (systat.tosysopdir<=maxulb)) then begin
    nl;
    print('Enter a single "\" in front of the description if it');
    print('is for the SysOp ONLY.');
  end else
    tosysop:=FALSE;
  nl;

  loaduboard(fileboard);
  isgif:=isgifext(f.filename);
  maxlen:=54;
  if ((fbusegifspecs in memuboard.fbstat) and (isgif)) then dec(maxlen,14);

  print('Please enter a one line description ('+cstr(maxlen)+' chrs max)');
  repeat
    prt(':');
    mpl(maxlen); inputl(f.description,maxlen);
    if (((f.description[1]='\') or (rvalidate in thisuser.ac))
       and (tosysop)) then begin
      fileboard:=systat.tosysopdir;
      close(ulff);
      fiscan(pl);
      tosysop:=TRUE;
    end else
      tosysop:=FALSE;
    if (f.description[1]='\') then f.description:=copy(f.description,2,80);
    nl;
  until ((f.description<>'') or (fso) or (hangup));
  v.descr[1]:='';
  dyny:=FALSE;
  if (pynq('Leave a verbose description? ')) then begin
    nl;
    print('You may use up to four lines of 50 characters each.');
    print('Enter a blank line to end.');
    nl;
    i:=1;
    repeat
      prt(cstr(i)+':');
      mpl(50);
      inputl(v.descr[i],50);
      if (v.descr[i]='') then i:=4;
      inc(i);
    until ((i=5) or (hangup));
    if (v.descr[1]<>'') then f.vpointer:=nfvpointer
    else begin
      nl; sprint(#3#7+'No verbose description saved.');
    end;
  end;
  if (v.descr[1]='') then f.vpointer:=-1;
end;

procedure writefv(rn:integer; f:ulfrec; v:verbrec);
var vfo:boolean;
begin
  seek(ulff,rn);
  write(ulff,f);

  if (v.descr[1]<>#1#1#0#1#1) and (f.vpointer<>-1) then begin
    vfo:=(filerec(verbf).mode<>fmclosed);
    if (not vfo) then reset(verbf);
    seek(verbf,f.vpointer); write(verbf,v);
    if (not vfo) then close(verbf);
  end;
end;

procedure newff(f:ulfrec; v:verbrec); {* ulff needs to be open before calling *}
var i,pl:integer;
    fo:boolean;
    f1:ulfrec;
begin
  seek(ulff,0); read(ulff,f1); pl:=f1.blocks;

  for i:=pl downto 1 do begin
    seek(ulff,i); read(ulff,f1);
    seek(ulff,i+1); write(ulff,f1);
  end;
  writefv(1,f,v);

  inc(pl); f1.blocks:=pl;
  seek(ulff,0); write(ulff,f1);
end;

procedure doffstuff(var f:ulfrec; fn:astr; var gotpts:integer);
var rfpts:real;
begin
  f.filename:=align(fn);
  f.owner:=usernum;
  f.stowner:=allcaps(thisuser.name);
  f.date:=date;
  f.daten:=daynum(date);
  f.nacc:=0;

  if (not systat.fileptratio) then begin
    f.filepoints:=0;
    gotpts:=0;
  end else begin
    rfpts:=(f.blocks/8)/systat.fileptcompbasesize;
    f.filepoints:=round(rfpts);
    gotpts:=round(rfpts*systat.fileptcomp);
    if (gotpts<1) then gotpts:=1;
  end;

  f.filestat:=[];
  if (not fso) and (not systat.validateallfiles) then
    f.filestat:=f.filestat+[notval];
  f.ft:=255; {* ft; *}
end;

procedure arcstuff(var ok,convt:boolean;    { if ok - if converted }
                   var blks:integer;        { # blocks     }
                   var convtime:real;       { convert time }
                   itest:boolean;           { whether to test integrity }
                   fpath:astr;              { filepath     }
                   var fn:astr;             { filename     }
                   var descr:astr);         { description  }
var fi:file of byte;
    convtook,convstart,convend:datetimerec;
    oldnam,newnam,s,sig:astr;
    sttime:real;
    x,y,c:word;
    oldarc,newarc:integer;
begin
  {*  oldarc: current archive format, 0 if none
   *  newarc: desired archive format, 0 if none
   *  oldnam: current filename
   *  newnam: desired archive format filename
   *}

  convtime:=0.0;
  ok:=TRUE;

  assign(fi,fpath+fn);
  {$I-} reset(fi); {$I+}
  if (ioresult<>0) then blks:=0
  else begin
    blks:=trunc((filesize(fi)+127.0)/128.0);
    close(fi);
  end;

  newarc:=memuboard.arctype;
  oldarc:=1;
  oldnam:=sqoutsp(fpath+fn);
  while (systat.filearcinfo[oldarc].ext<>'') and
        (systat.filearcinfo[oldarc].ext<>copy(fn,length(fn)-2,3)) and
        (oldarc<maxarcs+1) do
    inc(oldarc);
  if (oldarc=maxarcs+1) or
     (systat.filearcinfo[oldarc].ext='') then oldarc:=0;
  if (not systat.filearcinfo[oldarc].active) then oldarc:=0;
  if (not systat.filearcinfo[newarc].active) then newarc:=0;
  if (newarc=0) then newarc:=oldarc;

  {* if both archive formats supported ... *}
  if ((oldarc<>0) and (newarc<>0)) then begin
  {* archive extension supported *}
    newnam:=fn;
    if (pos('.',newnam)<>0) then newnam:=copy(newnam,1,pos('.',newnam)-1);
    newnam:=sqoutsp(fpath+newnam+'.'+systat.filearcinfo[newarc].ext);
    {* if integrity tests supported ... *}
    if ((itest) and (systat.filearcinfo[oldarc].testline<>'')) then begin
      star('Testing file integrity ...');
      arcintegritytest(ok,oldarc,oldnam);
      if (not ok) then begin
        sysoplog(#3#8'>>>>'#3#5+' "'+oldnam+'" on #'+cstr(fileboard)+
                 ': Errors in integrity test');
        star('Errors in integrity test!  File not passed.');
      end else
        star('No errors in testing, file passed.');
    end;

    {* if conversion required ... *}
    if ((ok) and (oldarc<>newarc) and (newarc<>0)) then begin
      convt:=incom;   {* don't convert if local and non-file-SysOp *}
      s:=systat.filearcinfo[newarc].ext;
      if (fso) then begin
        dyny:=TRUE;
        convt:=pynq('Convert archive to .'+s+' format? [Yes] : ');
      end;
      if (convt) then begin
        nl;

        getdatetime(convstart);
        conva(ok,oldarc,newarc,'tgtemp5.$$$',oldnam,newnam);
        getdatetime(convend);
        timediff(convtook,convstart,convend);
        convtime:=dt2r(convtook);

        if (ok) then begin
          assign(fi,fpath+fn);
          rewrite(fi); close(fi); erase(fi);
          assign(fi,newnam);
          {$I-} reset(fi); {$I+}
          if (ioresult<>0) then ok:=FALSE
          else begin
            blks:=trunc((filesize(fi)+127.0)/128.0);
            close(fi);
            if (blks=0) then ok:=FALSE;
          end;
          fn:=align(stripname(newnam));
          star('No errors in conversion, file passed.');
        end else begin
          assign(fi,newnam);
          rewrite(fi); close(fi); erase(fi);
          sysoplog(#3#8+'>>>>'#3#5+' "'+oldnam+'" on #'+
                   cstr(fileboard)+': Conversion unsuccessful');
          star('Errors in conversion!  Original format retained.');
          newarc:=oldarc;
        end;
        ok:=TRUE;
      end else
        newarc:=oldarc;
    end;

    {* if comment fields supported/desired ... *}
    if (ok) and (systat.filearcinfo[newarc].cmtline<>'') then begin
      s:=sqoutsp(fpath+fn);
      arccomment(ok,newarc,memuboard.cmttype,s);
      ok:=TRUE;
    end;
  end;
  fn:=sqoutsp(fn);

  if ((isgifext(fn)) and (fbusegifspecs in memuboard.fbstat)) then begin
    getgifspecs(memuboard.dlpath+fn,sig,x,y,c);
    s:='('+cstrl(x)+'x'+cstrl(y)+','+cstr(c)+'c) ';
    descr:=s+descr;
    if (length(descr)>60) then descr:=copy(descr,1,60);
  end;
end;

function searchfordups(completefn:astr):boolean;
var wildfn,nearfn,s:astr;
    i:integer;
    fcompleteacc,fcompletenoacc,fnearacc,fnearnoacc,
    hadacc,b1,b2:boolean;

  procedure searchb(b:integer; fn:astr; var hadacc,fcl,fnr:boolean);
  var f:ulfrec;
      oldboard,pl,rn:integer;
  begin
    oldboard:=fileboard;
    hadacc:=fbaseac(b); { loads in memuboard }
    fileboard:=b;

    recno(fn,pl,rn);
    if (badfpath) then exit;
    while (rn<=pl) and (rn<>0) do begin
      seek(ulff,rn); read(ulff,f);
      if (align(f.filename)=align(completefn)) then fcl:=TRUE
      else begin
        nearfn:=align(f.filename);
        fnr:=TRUE;
      end;
      nrecno(fn,pl,rn);
    end;
    close(ulff);
    fileboard:=oldboard;
    fiscan(pl);
  end;

begin
  nl;
  sprompt(#3#5+'Searching for duplicate files ... ');

  searchfordups:=TRUE;

  wildfn:=copy(align(completefn),1,9)+'???';
  fcompleteacc:=FALSE; fcompletenoacc:=FALSE;
  fnearacc:=FALSE; fnearnoacc:=FALSE;
  b1:=FALSE; b2:=FALSE;

  i:=0;
  while (i<=maxulb) do begin
    searchb(i,wildfn,hadacc,b1,b2); { fbaseac loads in memuboard ... }
    loaduboard(i);
    if (b1) then begin
      s:='User tried upload "'+sqoutsp(completefn)+'" to #'+cstr(fileboard)+
         '; existed in #'+cstr(i);
      if (not hadacc) then s:=s+' - no access to';
      sysoplog(s);
      nl; nl;
      if (hadacc) then
        sprint(#3#5+'File "'+sqoutsp(completefn)+'" already exists in "'+
               memuboard.name+#3#5+' #'+cstr(i)+'".')
      else
        sprint(#3#5+'File "'+sqoutsp(completefn)+
               '" cannot be accepted by the system at this time.');
      sprint(#3#7+'Illegal filename.');
      exit;
    end;
    if (b2) then begin
      s:='User entered upload filename "'+sqoutsp(completefn)+'" in #'+
         cstr(fileboard)+'; was warned that "'+sqoutsp(nearfn)+
         '" existed in #'+cstr(i)+'.';
      if (not hadacc) then s:=s+' - no access to';
      sysoplog(s);
      nl; nl;
      if (hadacc) then
        sprint(#3#5+'Warning: file "'+sqoutsp(nearfn)+'" exists in "'+
               memuboard.name+#3#5+' #'+cstr(i)+'".')
      else
        sprint(#3#5+'Warning: file "'+sqoutsp(nearfn)+
               '" exists in a private SysOp directory.');
      searchfordups:=not pynq('Upload anyway? [No] : ');
      exit;
    end;
    inc(i);
  end;

  sprint('none found.'); nl;
  searchfordups:=FALSE;
end;

procedure ul(var abort:boolean; fn:astr; var addbatch:boolean);
var baf:text;
    fi:file of byte;
    f,f1:ulfrec;
    wind:windowrec;
    v:verbrec;
    s:astr;
    xferstart,xferend,tooktime,ulrefundgot1,convtime1:datetimerec;
    ulrefundgot,convtime,rfpts,tooktime1:real;
    cps,lng,origblocks:longint;
    x,rn,pl,cc,oldboard,np,sx,sy,gotpts:integer;
    c:char;
    uls,ok,kabort,convt,aexists,resumefile,wenttosysop,offline:boolean;
begin
  oldboard:=fileboard;
  fiscan(pl);
  if (badulpath) then exit;

  uls:=incom; ok:=TRUE; fn:=align(fn); rn:=0;
  if (fn[1]=' ') or (fn[10]=' ') then ok:=FALSE;
  for x:=1 to length(fn) do
    ok:=(pos(fn[x],'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ. -@#$%^&()_')<>0);
  np:=0;
  for x:=1 to length(fn) do if (fn[x]='.') then inc(np);
  if (np<>1) then ok:=FALSE;
  if (not ok) then begin
    print('Illegal filename.');
    exit;
  end;

  {* aexists:    if file already EXISTS in dir
     rn:         rec-num of file if already EXISTS in file listing
     resumefile: if user is going to RESUME THE UPLOAD
     uls:        whether file is to be actually UPLOADED
     offline:    if uploaded a file to be offline automatically..
  *}

  resumefile:=FALSE; uls:=TRUE; offline:=FALSE; abort:=FALSE;
  aexists:=exist(memuboard.ulpath+fn);

  recno(fn,pl,rn);
  if (badulpath) then exit;
  nl;
  if (rn<>0) then begin
    seek(ulff,rn); read(ulff,f);
    resumefile:=(resumelater in f.filestat);
    if (resumefile) then begin
      print('This is a resume-later file.');
      resumefile:=((f.owner=usernum) or (fso));
      if (resumefile) then begin
        if (not incom) then begin
          print('Cannot be resumed locally.');
          exit;
        end;
        dyny:=TRUE;
        resumefile:=pynq('Resume upload of "'+sqoutsp(fn)+'" ? ');
        if (not resumefile) then exit;
      end else begin
        print(#3#7+'You are not the uploader of this file.');
        exit;
      end;
    end;
  end;
  if ((not aexists) and (not incom)) then begin
    uls:=FALSE;
    offline:=TRUE;
    print('This file does not exist in the files directory.');
    if not pynq('Do you want to create an Offline file entry? ') then exit;
  end;
  if (not resumefile) then begin
    if (((aexists) or (rn<>0)) and (not fso)) then begin
      print('File already exists.');
      exit;
    end;
    if (pl>=memuboard.maxfiles) then begin
      star('This directory is full.');
      exit;
    end;
    if (not aexists) and (not offline) and
       (freek(exdrv(memuboard.ulpath))<=systat.minspaceforupload)
    then begin
      nl; star('Insufficient disk space.');
      c:=chr(exdrv(memuboard.ulpath)+64);
      if c='@' then
        sysoplog(#3#8+'>>>>'+#3#3+' Main BBS drive full!  Insufficient space to upload a file!')
      else sysoplog(#3#8+'>>>>'+#3#3+' '+c+': drive full!  Insufficient space to upload a file!');
      exit;
    end;
    if (aexists) then begin
      uls:=FALSE;
      print('Am using "'+sqoutsp(memuboard.ulpath+fn)+'"');
      if (rn<>0) then sprint(#3#5+'NOTE: File already exists in listing!');
      dyny:=(rn=0);
      if (locbatup) then begin
        sprompt(#3#7+'[Q]uit or Upload this? (Y/N) ['+
                syn(dyny)+'] : '+#3#3);
        onekcr:=FALSE; onekda:=FALSE;
        onek(c,'QYN'^M);
        if (rn<>0) then ok:=(c='Y') else ok:=(c in ['Y',^M]);
        abort:=(c='Q');
        if (abort) then print('Quit') else
          if (not ok) then print('No') else print('Yes');
      end else
        ok:=pynq('Upload this? (Y/N) ['+syn(dyny)+'] : ');
      rn:=0;
    end;

    if ((systat.searchdup) and (ok) and (not abort) and (incom)) then
      if (searchfordups(fn)) then exit;

    if (uls) then begin
      dyny:=TRUE;
      ok:=pynq('Upload "'+sqoutsp(fn)+'" ? ');
    end;
    if ((ok) and (uls) and (not resumefile)) then begin
      assign(fi,memuboard.ulpath+fn);
      {$I-} rewrite(fi); {$I+}
      if ioresult<>0 then begin
        {$I-} close(fi); {$I+}
        cc:=ioresult;
        ok:=FALSE;
      end else begin
        close(fi);
        erase(fi);
      end;
      if (not ok) then begin
        print('Unable to upload that filename.');
        exit;
      end;
    end;
  end;

  if (not ok) then exit;
  wenttosysop:=TRUE;
  if (not resumefile) then begin
    f.filename:=align(fn);
    dodescrs(f,v,pl,wenttosysop);
  end;
  ok:=TRUE;
  if (uls) then begin
    showuserfileinfo;

    getdatetime(xferstart);
    receive1(memuboard.ulpath+fn,resumefile,ok,kabort,addbatch);

    if (addbatch) then begin
      inc(numubatchfiles);
      ubatch[numubatchfiles].fn:=sqoutsp(fn);
      with ubatch[numubatchfiles] do begin
        section:=fileboard;
        description:=f.description;
        if (v.descr[1]<>'') then begin
          inc(hiubatchv);
          new(ubatchv[hiubatchv]);    {* define dynamic memory *}
          ubatchv[hiubatchv]^:=v;
          vr:=hiubatchv;
        end else
          vr:=0;
      end;
      nl;
      if (numubatchfiles<>1) then s:='s' else s:='';
      s:=cstr(numubatchfiles)+' file'+s+' now in upload batch queue.';
      star(s);
      star('Hit <CR> alone to stop adding to queue.');
      nl;
      fileboard:=oldboard;
      exit;
    end else begin
      getdatetime(xferend);
      timediff(tooktime,xferstart,xferend);
    end;

    if (kabort) then begin
      fileboard:=oldboard;
      exit;
    end;

    ulrefundgot:=(dt2r(tooktime))*(systat.ulrefund/100.0);
    freetime:=freetime+ulrefundgot;
    star('Gave time refund of '+ctim(ulrefundgot));

    showuserfileinfo;

    if (not kabort) then star('Transfer complete.');
    nl;
  end;
  nl;

  convt:=FALSE;
  if (not offline) then begin
    assign(fi,memuboard.ulpath+fn);
    {$I-} reset(fi); {$I+}
    if (ioresult<>0) then ok:=FALSE
    else begin
      f.blocks:=trunc((filesize(fi)+127.0)/128.0);
      close(fi);
      if (f.blocks=0) then ok:=FALSE;
      origblocks:=f.blocks;
    end;
  end;

  if ((ok) and (not offline)) then begin
    arcstuff(ok,convt,f.blocks,convtime,uls,memuboard.ulpath,fn,f.description);
    doffstuff(f,fn,gotpts);

    if (ok) then begin
      if ((not resumefile) or (rn=0)) then newff(f,v) else writefv(rn,f,v);

      if (uls) then begin
        if (aacs(systat.ulvalreq)) then begin
          inc(thisuser.uploads);
          inc(thisuser.uk,f.blocks div 8);
        end;
        inc(systat.todayzlog.uploads);
        inc(systat.todayzlog.uk,f.blocks div 8);
      end;

      s:=#3#3+'Upload "'+sqoutsp(fn)+'" on '+memuboard.name;
      if (uls) then begin
        tooktime1:=dt2r(tooktime);
        if (tooktime1>=1.0) then begin
          cps:=f.blocks; cps:=cps*128;
          cps:=trunc(cps/tooktime1);
        end else
          cps:=0;
        s:=s+#3#3+' ('+cstr(f.blocks div 8)+'k, '+ctim(tooktime1)+
             ', '+cstr(cps)+' cps)';
      end;
      sysoplog(s);
      if ((incom) and (uls)) then begin
        if (convt) then begin
          lng:=origblocks*128;
          star('Orig. file size: '+cstrl(lng)+' bytes.');
        end;
        lng:=f.blocks; lng:=lng*128;
        if (convt) then
          star('New file size:   '+cstrl(lng)+' bytes.') else
          star('File size:       '+cstrl(lng)+' bytes.');
        star('Upload time:     '+longtim(tooktime));
        r2dt(convtime,convtime1);
        if (convt) then
          star('Convert time:    '+longtim(convtime1)+' (not refunded)');
        star('Transfer rate:   '+cstr(cps)+' cps');
        r2dt(ulrefundgot,ulrefundgot1);
        star('Time refund:     '+longtim(ulrefundgot1)+'.');
        if (gotpts<>0) then
          star('File points:     '+cstr(gotpts)+' pts.');
        nl;
        if (choptime<>0.0) then begin
          choptime:=choptime+ulrefundgot;
          freetime:=freetime-ulrefundgot;
          star('Sorry, no upload time refund may be given at this time.');
          star('You will get your refund after the event.');
          nl;
        end;
        doul(gotpts);
      end
      else star('Entry added.');
    end;
  end;
  if (not ok) and (not offline) then begin
    if (exist(memuboard.ulpath+fn)) then begin
      star('Upload not received.');
      s:='file deleted';
      if ((thisuser.sl>0 {systat.minresumelatersl} ) and
          (f.blocks div 8>systat.minresume)) then begin
        nl;
        dyny:=TRUE;
        if pynq('Save file for a later resume? ') then begin
          doffstuff(f,fn,gotpts);
          f.filestat:=f.filestat+[resumelater];
          if (not aexists) or (rn=0) then newff(f,v) else writefv(rn,f,v);
          s:='file saved for later resume';
        end;
      end;
      if (not (resumelater in f.filestat)) then begin
        if (exist(memuboard.ulpath+fn)) then begin
          assign(fi,memuboard.ulpath+fn);
          {$I-} erase(fi); {$I+}
        end;
      end;
      sysoplog(#3#3+'Error uploading "'+sqoutsp(fn)+'" - '+s);
    end;
    star('Taking away time refund of '+ctim(ulrefundgot)+' minutes.');
    freetime:=freetime-ulrefundgot;
  end;
  if (offline) then begin
    f.blocks:=10;
    doffstuff(f,fn,gotpts);
    f.filestat:=f.filestat+[isrequest];
    newff(f,v);
  end;
  close(ulff);
  fileboard:=oldboard;
  fiscan(pl); close(ulff);
end;

procedure iul;
var s:astr;
    pl:integer;
    c:char;
    abort,done,addbatch:boolean;
begin
  fiscan(pl);
  if (badulpath) then exit;
  if (not aacs(memuboard.ulacs)) then begin
    nl; star('You cannot upload to this section.');
    exit;
  end;
  locbatup:=FALSE;
  if (incom) then printf('upload');
  nl;
  repeat
    sprint(fstring.uploadline);
    done:=TRUE; addbatch:=FALSE;
    nl;
    prt('Filename: '); mpl(12); input(s,12); s:=sqoutsp(s);
    if (s<>'') then
      if (not fso) then ul(abort,s,addbatch)
      else begin
        if (not iswildcard(s)) then ul(abort,s,addbatch)
        else begin
          locbatup:=TRUE;
          ffile(memuboard.ulpath+s);
          if (not found) then print('No files found.') else
            repeat
              if not ((dirinfo.attr and VolumeID=VolumeID) or
                      (dirinfo.attr and Directory=Directory)) then
                ul(abort,dirinfo.name,addbatch);
              nfile;
            until (not found) or (abort);
        end;
      end;
    done:=(not addbatch);
  until (done) or (hangup);
end;

procedure fbaselist;
var s,os:astr;
    onlin,nd,b,b2,i:integer;
    abort,next,acc,showtitles:boolean;

  procedure titles;
  var sep:astr;
  begin
    sep:=#3#4+':'+#3#3;
    if (showtitles) then begin
      sprint(#3#3+'NNN'+sep+'Flags            '+sep+'Arc'+sep+'Description');
      sprint(#3#4+'===:=================:===:========================================');
      showtitles:=FALSE;
    end;
  end;

  procedure longlist;
  begin
    nl;
    showtitles:=TRUE;
    while (b<=maxulb) and (not abort) do begin
      acc:=fbaseac(b); { fbaseac will load memuboard }
      if ((fbunhidden in memuboard.fbstat) or (acc)) then begin
        titles;
        if (acc) then begin
          s:=#3#5+cstr(ccuboards[1][b]);
          while (length(s)<6) do s:=s+' ';
          if (b in zscanr.fzscan) then s:=s+#3#9+'Scan ' else s:=s+#3#9+'    ';
        end else
          s:=#3#9+'         ';
        if (fbnoratio in memuboard.fbstat) then s:=s+'No-Ratio '
          else s:=s+'         ';
        if (fbusegifspecs in memuboard.fbstat) then s:=s+'GIF '
          else s:=s+'    ';
        if (memuboard.arctype=0) then s:=s+#3#3+'   '
          else s:=s+#3#3+allcaps(systat.filearcinfo[memuboard.arctype].ext);
        s:=s+' '+#3#5+memuboard.name;
        sprint(s);
        inc(nd);
        if (not empty) then wkey(abort,next);
      end;
      inc(b);
    end;
  end;

  procedure shortlist;
  begin
    nl;
    while (b<=maxulb) and (not abort) do begin
      acc:=fbaseac(b); { fbaseac will load memuboard }
      if ((fbunhidden in memuboard.fbstat) or (acc)) then begin
        if (acc) then begin
          b2:=ccuboards[1][b];
          s:=#3#5+cstr(b2); if (b2<10) then s:=' '+s;
          if (b in zscanr.fzscan) then s:=s+'* ' else s:=s+'  ';
        end else
          s:='    ';
        s:=s+{#3#5+}memuboard.name;
        if (fbnoratio in memuboard.fbstat) then s:=s+#3#5+' <NR>';
        inc(onlin); inc(nd);
        if (onlin=1) then begin
          if (thisuser.linelen>=80) and (b<maxulb) and (lennmci(s)>40) then
            s:=mlnmci(s,40);
          sprompt(s); os:=s;
        end else begin
          i:=40-lennmci(os); os:='';
          if (thisuser.linelen>=80) then begin
            while (lennmci(os)<i) do os:=os+' ';
            if (lennmci(s)>38) then s:=mlnmci(s,38);
          end else
            nl;
          sprint(os+s);
          onlin:=0;
        end;
        if (not empty) then wkey(abort,next);
      end;
      inc(b);
    end;
    if (onlin=1) and (thisuser.linelen>=80) then nl;
  end;

begin
  nl;
  abort:=FALSE;
  onlin:=0; s:=''; b:=0; nd:=0;
  if pynq('Display detailed area listing? ') then longlist else shortlist;
  if (nd=0) then sprompt(#3#7+'No file bases available.');
end;

procedure unlisted_download(s:astr);
var dok,kabort:boolean;
    pl,oldnumbatchfiles,oldfileboard:integer;
begin
  if (s<>'') then begin
    if (not exist(s)) then print('File not found.')
    else if (iswildcard(s)) then print('Can''t specify wildcards.')
      else begin
        oldnumbatchfiles:=numbatchfiles;
        oldfileboard:=fileboard; fileboard:=-1;
        send1(s,dok,kabort);
        if (numbatchfiles=oldnumbatchfiles) and (dok) and (not kabort) then
          dodl(5);
        fileboard:=oldfileboard;
      end;
  end;
end;

procedure do_unlisted_download;
var s:astr;
begin
  nl;
  print('Enter file name to download (d:path\filename.ext)');
  prt(':'); mpl(78); input(s,78);
  unlisted_download(s);
end;

function nfvpointer:longint;
var i,x:integer;
    v:verbrec;
    vfo:boolean;
begin
  vfo:=(filerec(verbf).mode<>fmclosed);
  if (not vfo) then reset(verbf);
  x:=filesize(verbf);
  for i:=0 to filesize(verbf)-1 do begin
    seek(verbf,i); read(verbf,v);
    if (v.descr[1]='') then x:=i;
  end;
  if (not vfo) then close(verbf);
  nfvpointer:=x;
end;

end.
