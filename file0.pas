{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit file0;

interface

uses
  crt,dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}


  myio,
  common;

const
  ulffopen1:boolean=TRUE;   { whether ulff has been opened before }

var
  dirinfo:searchrec;
  found:boolean;

function align(fn:astr):astr;
function baddlpath:boolean;
function badulpath:boolean;
function bslash(b:boolean; s:astr):astr;
function existdir(s:astr):boolean;
procedure ffile(fn:astr);
procedure fileinfo(f:ulfrec; editing:boolean; var abort,next:boolean);
procedure fiscan(var pl:integer);
function fit(f1,f2:astr):boolean;
procedure gfn(var fn:astr);
function isgifdesc(d:astr):boolean;
function isgifext(fn:astr):boolean;
function isul(s:astr):boolean;
function iswildcard(s:astr):boolean;
procedure nfile;
procedure nrecno(fn:astr; var pl,rn:integer);
procedure recno(fn:astr; var pl,rn:integer);
function rte:real;
procedure star(s:astr);
function stripname(i:astr):astr;
function tcheck(s:real; i:integer):boolean;
function tchk(s:real; i:real):boolean;
procedure verbfileinfo(pt:integer; editing,abort,next:boolean);

implementation

function align(fn:astr):astr;
var f,e,t:astr; c,c1:integer;
begin
  c:=pos('.',fn);
  if (c=0) then begin
    f:=fn; e:='   ';
  end else begin
    f:=copy(fn,1,c-1); e:=copy(fn,c+1,3);
  end;
  f:=mln(f,8);
  e:=mln(e,3);
  c:=pos('*',f); if (c<>0) then for c1:=c to 8 do f[c1]:='?';
  c:=pos('*',e); if (c<>0) then for c1:=c to 3 do e[c1]:='?';
  c:=pos(' ',f); if (c<>0) then for c1:=c to 8 do f[c1]:=' ';
  c:=pos(' ',e); if (c<>0) then for c1:=c to 3 do e[c1]:=' ';
  align:=f+'.'+e;
end;

function baddlpath:boolean;
var s:string;
begin
  if (badfpath) then begin
    nl;
    sprint(#3#7+'File base #'+cstr(fileboard)+': Unable to perform command.');
    sprint(#3#5+'Bad DL file path: "'+memuboard.dlpath+'".');
    sprint(#3#5+'Please inform the SysOp.');
    sysoplog('Invalid DL path (file base #'+cstr(fileboard)+'): "'+
             memuboard.dlpath+'"');
  end;
  baddlpath:=badfpath;
end;

function badulpath:boolean;
var s:string;
begin
  if (badufpath) then begin
    nl;
    sprint(#3#7+'File base #'+cstr(fileboard)+': Unable to perform command.');
    sprint(#3#5+'Bad UL file path: "'+memuboard.ulpath+'".');
    sprint(#3#5+'Please inform the SysOp.');
    sysoplog('Invalid UL path (file base #'+cstr(fileboard)+'): "'+
             memuboard.ulpath+'"');
  end;
  badulpath:=badufpath;
end;

function bslash(b:boolean; s:astr):astr;
begin
  if (b) then begin
    while (copy(s,length(s)-1,2)='\\') do s:=copy(s,1,length(s)-2);
    if (copy(s,length(s),1)<>'\') then s:=s+'\';
  end else
    while (copy(s,length(s),1)='\') do s:=copy(s,1,length(s)-1);
  bslash:=s;
end;

function existdir(s:astr):boolean;
var savedir:astr;
    okd:boolean;
begin
  okd:=TRUE;
  s:=bslash(FALSE,fexpand(s));

  if ((length(s)=2) and (copy(s,2,1)=':')) then begin
    getdir(0,savedir);
    {$I-} chdir(s); {$I+}
    if (ioresult<>0) then okd:=FALSE;
    chdir(savedir);
    exit;
  end;

  okd:=(exist(s));

  if (okd) then begin
    findfirst(s,anyfile,dirinfo);
    if (dirinfo.attr and directory<>directory) or
       (doserror<>0) then okd:=FALSE;
  end;

  existdir:=okd;
end;

procedure fiscan(var pl:integer); { loads in memuboard ... }
var f:ulfrec;
    dirinfo:searchrec;
    s:astr;
begin
  s:=memuboard.dlpath; s:=copy(s,1,length(s)-1);
  if ((length(s)=2) and (s[2]=':')) then badfpath:=FALSE
  else begin
    findfirst(s,dos.directory,dirinfo);
    badfpath:=(doserror<>0);
  end;

  s:=memuboard.ulpath; s:=copy(s,1,length(s)-1);
  if ((length(s)=2) and (s[2]=':')) then badufpath:=FALSE
  else begin
    findfirst(s,dos.directory,dirinfo);
    badufpath:=(doserror<>0);
  end;

  if (not ulffopen1) then
    if (filerec(ulff).mode<>fmclosed) then close(ulff)
  else
  begin
  end
  else
    ulffopen1:=FALSE;
  loaduboard(fileboard);
  if (fbdirdlpath in memuboard.fbstat) then
    assign(ulff,memuboard.dlpath+memuboard.filename+'.DIR')
  else
    assign(ulff,systat.gfilepath+memuboard.filename+'.DIR');
  {$I-} reset(ulff); {$I+}
  if (ioresult<>0) then begin
    rewrite(ulff);
    f.blocks:=0;
    write(ulff,f);
  end;
  seek(ulff,0); read(ulff,f);
  pl:=f.blocks;
  bnp:=FALSE;
end;

procedure ffile(fn:astr);
begin
  findfirst(fn,anyfile,dirinfo);
  found:=(doserror=0);
end;

procedure fileinfo(f:ulfrec; editing:boolean; var abort,next:boolean);
var dt:datetimerec;
    s:astr;
    r:real;
    x:longint;
    i,j:integer;
    u:userrec;
begin
  j:=0;
  with f do
    for i:=1 to 8 do begin
      if (i=4) and (editing) then inc(i);
      inc(j);
      if (editing) then s:=#3#3+cstr(j)+'. ' else s:=#3#1;
      case i of
        1:s:=s+'Filename   : '+#3#3+'"'+filename+'"';
        2:s:=s+'Description: '+#3#3+description;
        3:begin
            x:=blocks; x:=x*128;
            s:=s+'File size  : '+#3#5+cstrl(x)+' bytes ('+cstr((blocks+7) div 8)+'K) / '+cstr(blocks)+' blocks';
          end;
        4:begin
            r:=rte*blocks; r2dt(r,dt);
            s:=s+'Aprox. time: '+#3#5+longtim(dt);
          end;
        5:if (editing) or (aacs(memuboard.nameacs)) then
            s:=s+'UL''d by    : '+#3#9+caps(stowner)+' #'+cstr(owner);
        6:s:=s+'UL''d on    : '+#3#9+date;
        7:s:=s+'Times DL''d : '+#3#9+cstr(nacc);
        8:begin
            s:=s+'File points: '+#3#4+cstr(filepoints);
            if (notval in filestat) then s:=s+' '+#3#8+'<NV>';
            if (isrequest in filestat) then s:=s+' '+#3#9+'Ask (Request File)';
            if (resumelater in filestat) then s:=s+' '+#3#7+'Resume later';
          end;
      end;
      if (s<>#3#1) then printacr(s,abort,next);
    end;
  if (f.vpointer<>-1) then verbfileinfo(f.vpointer,editing,abort,next);
end;

function fit(f1,f2:astr):boolean;
var tf:boolean; c:integer;
begin
  tf:=TRUE;
  for c:=1 to 12 do
    if (f1[c]<>f2[c]) and (f1[c]<>'?') then tf:=FALSE;
  fit:=tf;
end;

procedure gfn(var fn:astr);
begin
  sprint(fstring.gfnline1);
  prt(fstring.gfnline2); input(fn,12);
  if (pos('.',fn)=0) then fn:=fn+'*.*';
  fn:=align(fn);
end;

function isgifdesc(d:astr):boolean;
begin
  isgifdesc:=((copy(d,1,1)='(') and (pos('x',d) in [1..7]) and
              (pos('c)',d)<>0));
end;

function isgifext(fn:astr):boolean;
begin
  fn:=align(stripname(sqoutsp(fn)));
  fn:=allcaps(copy(fn,length(fn)-2,3));
  isgifext:=((fn='GIF') or (fn='GYF'));
end;

function isul(s:astr):boolean;
begin
  isul:=((pos('\',s)<>0) or (pos(':',s)<>0) or (pos('|',s)<>0));
end;

function iswildcard(s:astr):boolean;
begin
  iswildcard:=((pos('*',s)<>0) or (pos('?',s)<>0));
end;

procedure nfile;
begin
  findnext(dirinfo);
  found:=(doserror=0);
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

procedure recno(fn:astr; var pl,rn:integer);
var f:ulfrec;
    c:integer;
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

function rte:real;
var i:integer;
begin
  i:=value(spd); if (i=0) then i:=modemr.waitbaud;
  rte:=1400.0/i;
end;

procedure star(s:astr);
begin
  cl(4); if (okansi) then prompt('þ ') else prompt('* ');
  cl(3); if (s<>#1) then sprint(s);
end;

function stripname(i:astr):astr;
var i1:astr;
    n:integer;

  function nextn:integer;
  var n:integer;
  begin
    n:=pos(':',i1);
    if (n=0) then n:=pos('\',i1);
    if (n=0) then n:=pos('/',i1);
    nextn:=n;
  end;

begin
  i1:=i;
  while (nextn<>0) do i1:=copy(i1,nextn+1,80);
  stripname:=i1;
end;

function tcheck(s:real; i:integer):boolean;
var r:real;
begin
  r:=timer-s;
  if r<0.0 then r:=r+86400.0;
  if (r<0.0) or (r>32760.0) then r:=32766.0;
  if trunc(r)>i then tcheck:=FALSE else tcheck:=TRUE;
end;

function tchk(s:real; i:real):boolean;
var r:real;
begin
  r:=timer;
  if r<s then r:=r+86400.0;
  if (r-s)>i then tchk:=FALSE else tchk:=TRUE;
end;

procedure verbfileinfo(pt:integer; editing,abort,next:boolean);
var v:verbrec;
    i:integer;
    s:astr;
    vfo:boolean;
begin
  v.descr[1]:='';
  if pt<>-1 then begin
    vfo:=(filerec(verbf).mode<>fmclosed);
    {$I-} if not vfo then reset(verbf); {$I+}
    if ioresult=0 then begin
      {$I-} seek(verbf,pt); read(verbf,v); {$I+}
      if ioresult=0 then
        with v do
          for i:=1 to 4 do
            if descr[i]='' then i:=4
            else begin
              s:=#3#5;
              if (editing) then s:=s+'   ';
              if (i=1) then s:=s+'Verbose    : ' else s:=s+'           : ';
              s:=s+#3#4+descr[i];
              if (editing) and (i=1) then s:=s+#3#2+' ('+cstr(pt)+')';
              printacr(s,abort,next);
            end;
      if (not vfo) then close(verbf);
    end;
  end;
  if (editing) then
    if (pt=-1) then printacr(#3#5'   No Verbose',abort,next)
    else
      if (v.descr[1]='') then
        printacr(#3#7'   No Verbose YET'+#3#2+' ('+cstr(pt)+')',abort,next);
end;

end.
