{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit file11;

interface

uses
  crt,dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  myio,
  file0, file1,
  common;

function cansee(f:ulfrec):boolean;
procedure pbn(var abort,next:boolean);
procedure pfn(fnum:integer; f:ulfrec; var abort,next:boolean);
procedure searchb(b:integer; fn:astr; filestats:boolean; var abort,next:boolean);
procedure search;
procedure listfiles;
procedure searchbd(b:integer; ts:astr; var abort,next:boolean);
procedure searchd;
procedure newfiles(b:integer; var abort,next:boolean);
procedure gnfiles;
procedure nf(mstr:astr);
procedure fbasechange(var done:boolean; mstr:astr);
procedure createtempdir;
procedure fbasestats;

implementation

function cansee(f:ulfrec):boolean;
begin
  cansee:=((not (notval in f.filestat)) or (aacs(systat.seeunval)));
end;

function isulr:boolean;
begin
  isulr:=((systat.uldlratio) and (not systat.fileptratio));
end;

procedure pbn(var abort,next:boolean);
var s,s1:astr;
begin
  if (not bnp) then begin
    printacr('',abort,next);
    if (thisuser.flistopt<>30) then begin
      printacr('',abort,next);
      loaduboard(fileboard);
      s:=#3#5+memuboard.name+' '+#3#2+'#'+#3#4+cstr(ccuboards[1][fileboard]);
      s1:=#3#0; while (lenn(s1)<lenn(s)) do s1:=s1+'-';
      if (fbnoratio in memuboard.fbstat) then s:=s+#3#5+' <No-Ratio>';
      sprint(s);
      sprint(s1);
    end;
    case thisuser.flistopt of
      1:if (isulr) then begin
          printacr(#3#4+' Filename.Ext  Bytes  Description',abort,next);
          printacr(#3#4+' -------- --- ------- -------------------------------------------------------',
            abort,next);
        end else begin
          printacr(#3#4+' Filename.Ext Len Pts Description',abort,next);
          printacr(#3#4+' -------- --- --- --- -------------------------------------------------------',
            abort,next);
        end;
      2,30:begin
          s:=#3#4+' ###:Filename.Ext  Bytes  Pts DLs mm/dd/yy';
          s1:=#3#4+' ------------ --- ------- --- --- --------';
          if (aacs(memuboard.nameacs)) then begin
            s:=s+' ULed By';
            s1:=s1+' -----------------------------------';
          end;
          printacr(s,abort,next);
          printacr(s1,abort,next);
        end;
    end;
  end;
  bnp:=TRUE;
end;

procedure pfndd(fnum:integer; ts:astr; f:ulfrec; var abort,next:boolean);
var s,s1,dd,dd2:astr;
    v:verbrec;
    u:userrec;
    li:longint;
    i:integer;
    vfo:boolean;

  function ptsf:astr;
  begin
    if (isrequest in f.filestat) then ptsf:=#3#9+'Offline' else
      if (resumelater in f.filestat) then ptsf:=#3#7+'ResLatr' else
        if (notval in f.filestat) then ptsf:=#3#8+'Unvalid' else
          if ((isulr) and (f.filepoints=0)) then begin
            li:=f.blocks; li:=li*128;
            ptsf:=#3#4+mln(cstrl(li),7);
          end else
            ptsf:=#3#4+mln(cstr(f.blocks div 8),3)+' '+
                  mln(cstr(f.filepoints),3);
  end;

  function ptsf2:astr;
  begin
    if (isrequest in f.filestat) or (resumelater in f.filestat) or
       (notval in f.filestat) then ptsf2:=ptsf+'    '
    else begin
      li:=f.blocks; li:=li*128;
      ptsf2:=mln(cstrl(li),7)+' '+mln(cstr(f.filepoints),3);
    end;
  end;

  {rcg11172000 had to change this to get it compiling under Free Pascal...}
  {function substone(iscaps:boolean; src,old,new:astr):astr;}
  function substone(iscaps:boolean; src,old,_new:astr):astr;
  var p:integer;
  begin
    if (old<>'') then begin
      if (iscaps) then _new:=allcaps(_new);
      p:=pos(allcaps(old),allcaps(src));
      if (p>0) then begin
        insert(_new,src,p+length(old));
        delete(src,p,length(old));
      end;
    end;
    substone:=src;
  end;

begin
  loaduboard(fileboard);
  case thisuser.flistopt of
    1:begin
        dd:=f.description;
        if (ts<>'') then dd:=substone(TRUE,dd,ts,#3#0+allcaps(ts)+#3#5);
        if (f.daten>=daynum(newdate)) then s:=#3#8+'*' else s:=' ';
        dd2:=f.filename;
        if (ts<>'') then dd2:=substone(TRUE,dd2,ts,#3#0+allcaps(ts)+#3#3);
        s:=s+#3#3+dd2+' '+ptsf+' '+#3#5;
        s1:=copy(dd,1,55);
        if (not flistverb) and (f.vpointer<>-1) then begin
          if (lenn(dd)>52) then s1:=copy(dd,1,51)+#3#3+'+';
          s1:=s1+#3#9+'(v)';
        end else
          if (lenn(dd)>54) then s1:=copy(dd,1,53)+#3#3+'+';
        if ((isgifext(f.filename)) and (isgifdesc(s1))) then begin
          dd:=copy(s1,1,pos('c)',s1)+1);
          dd2:=#3#3+copy(s1,1,pos('c)',s1)+1)+#3#5;
          s1:=substone(FALSE,s1,dd,dd2);
        end;
        s:=s+s1;
      end;
    2,30:begin
        if (f.daten>=daynum(newdate)) then s:=#3#8+'*' else s:=' ';
        s:=s+#3#3+mn(fnum,3)+#3#4+':'+#3#3+f.filename+' '+ptsf2+' '+
           #3#5+mln(cstr(f.nacc),3)+' '+#3#7+f.date;
        if (aacs(memuboard.nameacs)) then
          s:=s+' '+#3#9+caps(f.stowner)+' #'+cstr(f.owner);
      end;
    3:begin
        printacr('',abort,next);

        dd:=f.description;
        if (ts<>'') then dd:=substone(TRUE,dd,ts,#3#0+allcaps(ts)+#3#5);
        dd2:=f.filename;
        if (ts<>'') then dd2:=substone(TRUE,dd2,ts,#3#0+allcaps(ts)+#3#3);

        if (f.daten>=daynum(newdate)) then s:=#3#8+'*' else s:=' ';
        s:=s+#3#3+dd2+#3#4+':'+#3#4+mln(cstr(f.nacc)+' DLs',7)+#3#4+':'+
             #3#4+'ULed on '+f.date;
        if (aacs(memuboard.nameacs)) then
          s:=s+' by '+#3#9+caps(f.stowner)+' #'+cstr(f.owner);
        printacr(s,abort,next);

        if (isrequest in f.filestat) then
          s1:=#3#9+'File stored off-line'
        else
          if (resumelater in f.filestat) then
            s1:=#3#7+'Resume-later file'
          else
            if (notval in f.filestat) then
              s1:=#3#8+'Not validated yet'
            else begin
              li:=f.blocks; li:=li*128;
              if ((isulr) and (f.filepoints=0)) then
                s1:=#3#4+cstrl(li)+' bytes'
              else
                s1:=#3#4+cstrl(li)+' bytes, '+cstr(f.filepoints)+' pts';
            end;
        s:=' '+mln(s1,20)+#3#4+':'+#3#5;
        s1:=copy(dd,1,55);
        if ((isgifext(f.filename)) and (isgifdesc(s1))) then begin
          dd:=copy(s1,1,pos('c)',s1)+1);
          dd2:=#3#3+copy(s1,1,pos('c)',s1)+1)+#3#5;
          s1:=substone(FALSE,s1,dd,dd2);
        end;
        s:=s+s1;
      end;
  end;
  printacr(s,abort,next);
  if ((f.vpointer<>-1) and (flistverb) and (thisuser.flistopt in [1,3])) then begin
    vfo:=(filerec(verbf).mode<>fmclosed);
    {$I-} if (not vfo) then reset(verbf); {$I+}
    if (ioresult=0) then begin
      {$I-} seek(verbf,f.vpointer); read(verbf,v); {$I+}
      if (ioresult=0) then
        for i:=1 to 4 do
          if (v.descr[i]='') then i:=4
          else begin
            dd:=substone(TRUE,v.descr[i],ts,#3#0+allcaps(ts)+#3#4);
            printacr('                          '+#3#2+':'+#3#4+dd,abort,next);
          end;
      if (not vfo) then close(verbf);
    end;
  end;
  if ((resumelater in f.filestat) and (f.owner=usernum)) then
    printacr(#3#8+'>'+#3#7+'>> '+#3#3+'You '+#3#5+'MUST RESUME'+#3#3+
             ' this file to receive credit for it',abort,next);
end;

procedure pfn(fnum:integer; f:ulfrec; var abort,next:boolean);
begin
  pfndd(fnum,'',f,abort,next);
end;

procedure searchb(b:integer; fn:astr; filestats:boolean; var abort,next:boolean);
var f:ulfrec;
    li,totfils,totsize:longint;
    oldboard,pl,rn:integer;
begin
  oldboard:=fileboard;
  if (fileboard<>b) then changefileboard(b);
  if (fileboard=b) then begin
    totfils:=0; totsize:=0;
    recno(fn,pl,rn);
    if (baddlpath) then exit;
    while ((rn<=pl) and (not abort) and (not hangup) and (rn<>0)) do begin
      seek(ulff,rn); read(ulff,f);
      if (cansee(f)) then begin
        pbn(abort,next);
        pfn(rn,f,abort,next);
        if (filestats) then begin
          inc(totfils);
          li:=f.blocks; li:=li*128; inc(totsize,li);
        end;
      end;
      nrecno(fn,pl,rn);
    end;
    if ((filestats) and (not abort) and (totfils>0)) then
      if (thisuser.flistopt<>3) then begin
        printacr(#3#4+' ------------ -------',abort,next);
        printacr(#3#4+' '+mln(cstr(totfils)+' files',12)+' '+cstr(totsize)+' bytes total',abort,next);
      end else begin
        nl;
        printacr(#3#4+cstr(totfils)+' files, '+cstr(totsize)+' bytes total.',abort,next);
      end;
    close(ulff);
  end;
  fileboard:=oldboard;
end;

procedure search;
var fn:astr;
    bn:integer;
    abort,next:boolean;
begin
  nl;
  sprint(fstring.searchline);
  sprint(fstring.pninfo);
  nl; gfn(fn);
  bn:=0; abort:=FALSE; next:=FALSE;
  while (not abort) and (bn<=maxulb) and (not hangup) do begin
    if (fbaseac(bn)) then searchb(bn,fn,FALSE,abort,next);
    inc(bn);
    wkey(abort,next);
    if (next) then begin abort:=FALSE; next:=FALSE; end;
  end;
end;

procedure listfiles;
var fn:astr;
    abort,next:boolean;
begin
  nl;
  sprint(fstring.listline);
  gfn(fn); abort:=FALSE;
  searchb(fileboard,fn,TRUE,abort,next);
end;

procedure searchbd(b:integer; ts:astr; var abort,next:boolean);
var oldboard,pl,rn,i:integer;
    f:ulfrec;
    ok,vfo:boolean;
    v:verbrec;
begin
  oldboard:=fileboard;
  if (fileboard<>b) then changefileboard(b);
  if (fileboard=b) then begin
    vfo:=(filerec(verbf).mode<>fmclosed);
    {$I-} if not vfo then reset(verbf); {$I+}
    fiscan(pl);
    if (baddlpath) then exit;
    rn:=1;
    while (rn<=pl) and (not abort) and (not hangup) do begin
      seek(ulff,rn); read(ulff,f);
      if (cansee(f)) then begin
        ok:=((pos(ts,allcaps(f.description))<>0) or
             (pos(ts,allcaps(f.filename))<>0));
        if (not ok) then
          if (f.vpointer<>-1) then begin
            {$I-} seek(verbf,f.vpointer); read(verbf,v); {$I+}
            if (ioresult=0) then begin
              i:=1;
              while (v.descr[i]<>'') and (i<=4) and (not ok) do begin
                if pos(ts,allcaps(v.descr[i]))<>0 then ok:=TRUE;
                inc(i);
              end;
            end;
          end;
      end;
      if (ok) then begin
        pbn(abort,next);
        pfndd(rn,ts,f,abort,next);
      end;
      inc(rn);
    end;
    close(ulff);
    reset(verbf); close(verbf);
  end;
  fileboard:=oldboard;
end;

procedure searchd;
var s:astr;
    bn:integer;
    abort,next:boolean;
begin
  nl;
  sprint(fstring.findline1);
  nl;
  sprint(fstring.findline2);
  prt(':'); mpl(20); input(s,20);
  if (s<>'') then begin
    nl; print('Searching for "'+s+'"'); nl;
    if pynq('Search all directories? ') then begin
      bn:=0; abort:=FALSE; next:=FALSE;
      while (not abort) and (bn<=maxulb) and (not hangup) do begin
        if (fbaseac(bn)) then searchbd(bn,s,abort,next);
        inc(bn);
        wkey(abort,next);
        if (next) then begin abort:=FALSE; next:=FALSE; end;
      end;
    end else begin
      abort:=FALSE; next:=FALSE;
      searchbd(fileboard,s,abort,next);
    end;
  end;
end;

procedure newfiles(b:integer; var abort,next:boolean);
var f:ulfrec;
    oldboard,pl,rn:integer;
begin
  oldboard:=fileboard;
  if (fileboard<>b) then changefileboard(b);
  if (fileboard=b) then begin
    fiscan(pl);
    if (baddlpath) then exit;
    rn:=1;
    while (rn<=pl) and (not abort) and (not hangup) do begin
      seek(ulff,rn); read(ulff,f);
      if ((cansee(f)) and (f.daten>=daynum(newdate))) or
         ((notval in f.filestat) and (cansee(f))) then begin
        pbn(abort,next);
        pfn(rn,f,abort,next);
      end;
      inc(rn);
    end;
    close(ulff);
  end;
  fileboard:=oldboard;
end;

procedure gnfiles;
var i:integer;
    abort,next:boolean;
begin
  sysoplog('NewScan of file bases');
  i:=0;
  abort:=FALSE; next:=FALSE;
  while (not abort) and (i<=maxulb) and (not hangup) do begin
    if ((fbaseac(i)) and (i in zscanr.fzscan)) then newfiles(i,abort,next);
    inc(i);
    wkey(abort,next);
    if (next) then begin abort:=FALSE; next:=FALSE; end;
  end;
end;

procedure nf(mstr:astr);
var bn:integer;
    abort,next:boolean;
begin
  if (mstr='C') then newfiles(board,abort,next)
  else if (mstr='G') then gnfiles
  else if (value(mstr)<>0) then newfiles(value(mstr),abort,next)
  else begin
    nl;
    sprint(fstring.newline);
    sprint(fstring.pninfo);
    nl;
    abort:=FALSE; next:=FALSE;
    if pynq('Search all directories? ') then gnfiles
      else newfiles(fileboard,abort,next);
  end;
end;

procedure fbasechange(var done:boolean; mstr:astr);
var s:astr;
    i:integer;
begin
  if (mstr<>'') then
    case mstr[1] of
      '+':begin
            i:=fileboard;
            if (fileboard>=maxulb) then i:=0 else
              repeat
                inc(i);
                if (fbaseac(i)) then changefileboard(i);
              until ((fileboard=i) or (i>maxulb));
            if (fileboard<>i) then sprint('@MHighest accessible file base.')
              else lastcommandovr:=TRUE;
          end;
      '-':begin
            i:=fileboard;
            if (fileboard<=0) then i:=maxulb else
              repeat
                dec(i);
                if fbaseac(i) then changefileboard(i);
              until ((fileboard=i) or (i<=0));
            if (fileboard<>i) then sprint('@MLowest accessible file base.')
              else lastcommandovr:=TRUE;
          end;
      'L':fbaselist;
    else
          begin
            changefileboard(value(mstr));
            if (pos(';',mstr)>0) then begin
              s:=copy(mstr,pos(';',mstr)+1,length(mstr));
              curmenu:=systat.menupath+s+'.mnu';
              newmenutoload:=TRUE;
              done:=TRUE;
            end;
            lastcommandovr:=TRUE;
          end;
    end
  else begin
    if (novice in thisuser.ac) then fbaselist;
    nl;
    s:='?';
    repeat
      prt('^7Change file base (^3?^7=^3List^7) : '); input(s,3);
      i:=ccuboards[0][value(s)];
      if (s='?') then begin fbaselist; nl; end else
        if (((i>=1) and (i<=maxulb)) or
           ((i=0) and (copy(s,1,1)='0'))) and
           (i<>fileboard) then
          changefileboard(i);
    until (s<>'?') or (hangup);
    lastcommandovr:=TRUE;
  end;
end;

procedure createtempdir;
var s:astr;
    i:integer;
begin
  nl;
  if (maxulb=maxuboards) then print('Too many file bases already.')
  else begin
    print('Enter file path for temporary directory');
    prt(':'); mpl(40); input(s,40);
    if (s<>'') then begin
      s:=fexpand(bslash(TRUE,s));
      fileboard:=maxulb+1;
      sysoplog('Created temporary directory #'+cstr(fileboard)+
               ' in "'+s+'"');
      with tempuboard do begin
        name:='<< Temporary >>';
        filename:='TEMPFILE';
        dlpath:=s;
        ulpath:=s;
        maxfiles:=2000;
        password:='';
        arctype:=0;
        cmttype:=1;
        fbdepth:=0;
        fbstat:=[];
        acs:='s'+cstr(thisuser.sl)+'d'+cstr(thisuser.dsl);
        ulacs:='s'+cstr(thisuser.sl)+'d'+cstr(thisuser.dsl);
        nameacs:='s'+cstr(thisuser.sl)+'d'+cstr(thisuser.dsl);
        for i:=1 to 6 do res[i]:=0;
      end;
      memuboard:=tempuboard;
    end;
  end;
end;

procedure fbasestats;
var s:astr;
    abort,next:boolean;

  procedure dd(var abort,next:boolean; s1,s2:astr; b:boolean);
  begin
    s1:=#3#3+s1+#3#5+' ';
    if (b) then printacr(s1+s2,abort,next)
      else printacr(s1+'None.',abort,next);
  end;

begin
  abort:=FALSE; next:=FALSE;
  nl;
  loaduboard(fileboard);
  with memuboard do begin
    s:=#3#3+'Statistics on "'+#3#5+memuboard.name+' #'+
       cstr(ccuboards[1][fileboard])+#3#3+'"';
    if (fbnoratio in fbstat) then s:=s+#3#5+' <No-Ratio>';
    printacr(s,abort,next);
    nl;
{    dd(abort,next,'AR requirement ....... :','"'+ar+'"',(ar<>'@'));}
    dd(abort,next,'Base password ........ :','"'+password+'"',(password<>''));
{    dd(abort,next,'SL requirement ....... :',cstr(sl)+' SL',(sl<>0));}
{    dd(abort,next,'DSL requirement ...... :',cstr(dsl)+' DSL',(dsl<>0));}
    dd(abort,next,'Max files allowed .... :',cstr(maxfiles),(maxfiles<>0));
{    dd(abort,next,'Age requirement ...... :',cstr(agereq),(agereq>1));}
    s:=systat.filearcinfo[arctype].ext;
    dd(abort,next,'Archive format ....... :','"'+s+'"',(arctype<>0));
    if (fso) then begin
      nl;
      {rcg11182000 lowercased this ".DIR" strings...}
      dd(abort,next,'Filename ...... :','"'+filename+'.dir"',TRUE);
      dd(abort,next,'DL file path .. :','"'+dlpath+'"',TRUE);
    end;
  end;
end;

end.
