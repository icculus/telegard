{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
{$M 50000,0,1024}

uses crt,dos,
     myio;

const 
  needconv = 'S23568CD';
  standard_conversion = TRUE;

{$I rcc17a.pas}
{$I rec18a.pas}

var
  a,b,lastss,mp,gp,sp:astr;
  h,i,j,k,savx,savy:integer;
  c:char;
  aw:boolean;  { author working }
  back:boolean;  { converting BACK TO PREVIOUS VERSION ! .. }
  found:boolean;
  dirinfo:searchrec;
  ptsforisrequest,ptsfornotval:integer;
  wind:windowrec;
  didit:boolean;
  needs:longint;

  artable:astr;

{  systatf17a4:file of systatrec17a4;}
{  systat17a4:systatrec17a4;}
  systatf1:file of systatrec1;
  systat1:systatrec1;
  systatf0:file of systatrec;
  systat0:systatrec;
  systatf:file of systatrec;
  systat:systatrec;

  modemrf:file of modemrec;
  modemr:modemrec;
  fstringf:file of fstringrec;
  fstring:fstringrec;

  sf1:file of smalrec1;
  sr1:smalrec1;
  sf:file of smalrec;
  sr:smalrec;

  uf1:file of userrec1;
  user1:userrec1;        {**}
  uf0:file of userrec;
  user0:userrec;
  uf:file of userrec;
  user:userrec;          {**}

  bf1:file of boardrec1;
  brd1:boardrec1;
{  bf17a5:file of boardrec17a5;}
{  brd17a5:boardrec17a5;}
  bf:file of boardrec;
  brd:boardrec;

  mailfile1:file of mailrec1;
  mail1:mailrec1;              {**}
  mailfile:file of mailrec;
  mail:mailrec;                {**}

  ulf1:file of ulrec1;
  ubrd1:ulrec1;
{  ulf17a2:file of ulrec17a2;}
{  ubrd17a2:ulrec17a2;}
  ulf0:file of ulrec;
  ubrd0:ulrec;
  ulf:file of ulrec;
  ubrd:ulrec;

  ulff1:file of ulfrec1;
  uld1:ulfrec1;
  ulff:file of ulfrec;
  uld:ulfrec;

{  slf1:file of slr1;
  seclev1:array[0..255] of slr1;
  slf:file of seclevrec;
  seclev:seclevrec;}

  gfilef1:file of gft1;   {**}
  gfile1:gft1;            {**}
  gfilef:file of tfilerec;{**}
  gfile:tfilerec;         {**}

  smf1:file of smr1;
  sm1:smr1;
  smf:file of smr;
  sm:smr;

  ztf1:file of zlogt1;    {**}
  zt1:zlogt1;             {**}
  ztf:file of zlogrec;      {**}
  zt:zlogrec;               {**}

  vdf1:file of vdatar1;   {**}
  vd1:vdatar1;            {**}
  vdf:file of vdatar;     {**}
  vd:vdatar;              {**}

  macrf:file of macrorec;
  macr:macrorec;

  xp1:file of protrec1;
  xpr1:protrec1;
  xp0:file of protrec;
  xpr0:protrec;
  xp:file of protrec;
  xpr:protrec;

  mbasef1:file of messagerec1;
  mbase1:messagerec1;
  mbasef:file of messagerec;
  mbase:messagerec;

  ff:file;

  {**} (* NOT defined globally in COMMON.PAS .... *)

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

function cstrl(li:longint):astr;
var c:astr;
begin
  str(li,c);
  cstrl:=c;
end;

function cstr(i:integer):astr;
var c:astr;
begin
  str(i,c);
  cstr:=c;
end;



function tch(i:astr):astr;
begin
  if length(i)>2 then i:=copy(i,length(i)-1,2) else
    if length(i)=1 then i:='0'+i;
  tch:=i;
end;

{rcg11272000 dunno if this is even used, but it won't fly under Linux.}
{ below is a working implementation.}
{
function time:astr;
var reg:registers;
    h,m,s:string[4];
begin
  reg.ax:=$2c00; intr($21,Dos.Registers(reg));
  str(reg.cx shr 8,h); str(reg.cx mod 256,m); str(reg.dx shr 8,s);
  time:=tch(h)+':'+tch(m)+':'+tch(s);
end;
}

function time:string;
var h,m,s:string[3];
    hh,mm,ss,ss100:word;
begin
  gettime(hh,mm,ss,ss100);
  str(hh,h); str(mm,m); str(ss,s);
  time:=tch(h)+':'+tch(m)+':'+tch(s);
end;

{rcg11272000 dunno if this is even used, but it won't fly under Linux.}
{ below is a working implementation, Y2K fixes included.}
{
function date:astr;
var reg:registers;
    m,d,y:string[4];
begin
  reg.ax:=$2a00; msdos(Dos.Registers(reg)); str(reg.cx,y); str(reg.dx mod 256,d);
  str(reg.dx shr 8,m);
  date:=tch(m)+'/'+tch(d)+'/'+tch(y);
end;
}

function date:string;
var
    {rcg11272000 unused variable.}
    {r:registers;}

    {rcg11272000 Y2K-proofing.}
    {y,m,d:string[3];}
    m,d:string[3];
    y:string[5];
    yy,mm,dd,dow:word;

begin
  getdate(yy,mm,dd,dow);
  {rcg11272000 Y2K-proofing.}
  {str(yy-1900,y); str(mm,m); str(dd,d);}
  str(yy,y); str(mm,m); str(dd,d);
  date:=tch(m)+'/'+tch(d)+'/'+y;
end;


function leapyear(yr:integer):boolean;
begin
  leapyear:=(yr mod 4=0) and ((yr mod 100<>0) or (yr mod 400=0));
end;

function days(mo,yr:integer):integer;
var d:integer;
begin
  d:=value(copy('312831303130313130313031',1+(mo-1)*2,2));
  if (mo=2) and leapyear(yr) then d:=d+1;
  days:=d;
end;

function daycount(mo,yr:integer):integer;
var m,t:integer;
begin
  t:=0;
  for m:=1 to (mo-1) do t:=t+days(m,yr);
  daycount:=t;
end;

function daynum(dt:astr):integer;
var d,m,y,t,c:integer;
begin
  t:=0;
  m:=value(copy(dt,1,2));
  d:=value(copy(dt,4,2));

  {rcg11182000 hahahaha...a Y2K bug.  :) }
  {rcg11272000 Let's make sure the values coming in here are four }
  {digits in the first place, which should save us some hacks elsewhere...}
  {y:=value(copy(dt,7,2))+1900;}

  {rcg11272000 my adds...}
  if (length(dt) < 10) then rcgpanic('WHOA! TWO DIGIT YEAR IN DATE!');
  y:=value(copy(dt,7,4));
  {rcg11272000 end my adds...}

  for c:=1985 to y-1 do
    if leapyear(c) then t:=t+366 else t:=t+365;
  t:=t+daycount(m,y)+(d-1);
  daynum:=t;
  if y<1985 then daynum:=0;
end;


function freek(d:integer):longint;    (* See disk space *)
{var r:registers;}
begin
  freek:=diskfree(d) div 1024;
{  r.ax:=$3600;
  r.dx:=d;
  msdos(dos.registers(r));
  freek:=trunc(1.0*r.bx*r.ax*r.cx/1024.0);}
end;

procedure tc(i:integer);
begin
  textcolor(i);
end;

procedure star(s:astr);
begin
  tc(9); write('þ ');
  tc(11); writeln(s);
end;

function exdrv(s:astr):byte;
begin
  {rcg11242000 point at root drive always. Ugh.}
  {
  s:=fexpand(s);
  exdrv:=ord(s[1])-64;
  }
  exdrv:=3;
end;

procedure movefile(srcname,destpath:string);
var buffer:array[1..16384] of byte;
    dfs,nrec:integer;
    src,dest:file;
    dd,dn,de:string;

  procedure dodate;
  var r:registers;
      od,ot,ha:integer;
  begin
    srcname:=srcname+#0;
    destpath:=destpath+#0;
    with r do begin
      ax:=$3d00; ds:=seg(srcname[1]); dx:=ofs(srcname[1]); msdos(dos.registers(r));
      ha:=ax; bx:=ha; ax:=$5700; msdos(dos.registers(r));
      od:=dx; ot:=cx; bx:=ha; ax:=$3e00; msdos(dos.registers(r));
      ax:=$3d02; ds:=seg(destpath[1]); dx:=ofs(destpath[1]); msdos(dos.registers(r));
      ha:=ax; bx:=ha; ax:=$5701; cx:=ot; dx:=od; msdos(dos.registers(r));
      ax:=$3e00; bx:=ha; msdos(dos.registers(r));
    end;
  end;

begin
  fsplit(srcname,dd,dn,de);
  destpath:=destpath+dn+de;
  assign(src,srcname);
  {$I-} reset(src,1); {$I+}
  if (ioresult<>0) then begin
    writeln;
    star('"'+srcname+'": File not found.'^G^G);
{    halt(1);}
  end else begin
    dfs:=freek(exdrv(destpath));

    {rcg11172000 don't have LONGfilesize()...}
    {if (trunc(longfilesize(src)/1024.0)+1>=dfs) then begin}
    if (trunc(filesize(src)/1024.0)+1>=dfs) then begin
      writeln;
      star('"'+srcname+'": Disk full.');
      halt(1);
    end else begin
      assign(dest,destpath); rewrite(dest,1);
      repeat
        blockread(src,buffer,16384,nrec);
        blockwrite(dest,buffer,nrec);
      until (nrec<16384);
      close(dest);
      close(src);
      dodate;
      erase(src);
    end;
  end;
end;

procedure smovefile(srcname,destpath:string);
begin
  star('Moving "'+srcname+'" to "'+destpath+'"');
  movefile(srcname,destpath);
end;

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

function allcaps(s:astr):astr;    (* returns a COMPLETELY capitalized string *)
var i:integer;
begin
  for i:=1 to length(s) do
    s[i]:=upcase(s[i]);
  allcaps:=s;
end;

procedure cursoron;
var reg:registers;
begin
  with reg do begin
    ch:=07; cl:=08; ah:=1;
    intr($10,reg);
  end;
end;

procedure cursoroff;
var reg:registers;
begin
  with reg do begin
    ch:=09; cl:=00; ah:=1;
    intr($10,reg);
  end;
end;

procedure prt(s:string);
begin
  textcolor(9); write(s);
end;

procedure ttl(s:string);
begin
  writeln;
  textcolor(9); write('ÄÄ[');
  textbackground(1); textcolor(15);
  write(' '+s+' ');
  textbackground(0); textcolor(9);
  write(']');
  repeat write('Ä') until wherex=80;
  writeln;
end;

procedure ee(s:astr);
begin
  clrscr;
  writeln;
  tc(4); writeln('ERROR:');
  writeln;
  tc(15); write('  '+s);
  writeln;
  writeln;
  tc(9); write('Hit any key to exit : ');
  repeat until keypressed;
  c:=readkey;
  removewindow(wind); gotoxy(savx,savy);
  halt(1);
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

function needc(c:char):boolean;
begin
  if pos(c,needconv)<>0 then needc:=TRUE else needc:=FALSE;
end;

procedure fvers;
var i:integer;
begin
  needs:=0;

  writeln;
  ss('status.dat');
  assign(systatf1,'status.dat');
  {$I-} reset(systatf1); {$I+}
  if (ioresult<>0) then cantopen;
  {$I-} read(systatf1,systat1); {$I+}
  if (ioresult<>0) then begin
    close(systatf1);
    assign(systatf,'status.dat');
    reset(systatf);
    {$I-} read(systatf,systat); {$I+}
    gp:=systat.gfilepath;
    mp:=systat.menupath;
    close(systatf);
  end else begin
    gp:=systat1.gfilepath;
    mp:=systat1.menupath;
    close(systatf1);
  end;
  inc(needs,sizeof(systatrec));

  if needc('1') then begin
    ss('names.lst');
    assign(sf1,gp+'names.lst');
    {$I-} reset(sf1); {$I+}
    if (ioresult<>0) then begin
      assign(systatf,'status.dat');
      reset(systatf);
      {$I-} read(systatf,systat); {$I+}
      gp:=systat.gfilepath;
      mp:=systat.menupath;
      close(systatf);
      assign(sf1,gp+'names.lst');
      {$I-} reset(sf1); {$I+}
      if (ioresult<>0) then cantopen;
    end;
    {$I-} read(sf1,sr1); {$I+}
    inc(needs,sizeof(smalrec)*filesize(sf1));
    close(sf1);
  end;

  if needc('2') then begin
    ss('user.lst');
    assign(uf1,gp+'user.lst');
    {$I-} reset(uf1); {$I+}
    if (ioresult<>0) then cantopen;
    {$I-} read(uf1,user1); {$I+}
    inc(needs,sizeof(userrec)*filesize(uf1));
    close(uf1);
  end;

  if needc('3') then begin
    ss('boards.dat');
    assign(bf1,gp+'boards.dat');
    {$I-} reset(bf1); {$I+}
    if (ioresult<>0) then cantopen;
    {$I-} read(bf1,brd1); {$I+}
    inc(needs,sizeof(boardrec)*filesize(bf1));
    close(bf1);
  end;

  if needc('4') then begin
    ss('email.dat');
    assign(mailfile1,gp+'email.dat');
    {$I-} reset(mailfile1); {$I+}
    if (ioresult<>0) then cantopen;
    {$I-} read(mailfile1,mail1); {$I+}
    inc(needs,sizeof(mailrec)*filesize(mailfile1));
    close(mailfile1);
  end;

  if needc('5') then begin
    ss('gfiles.dat');
    assign(gfilef1,gp+'gfiles.dat');
    {$I-} reset(gfilef1); {$I+}
    if (ioresult<>0) then cantopen;
    {$I-} read(gfilef1,gfile1); {$I+}
    inc(needs,sizeof(tfilerec)*filesize(gfilef1));
    close(gfilef1);
  end;

  if needc('6') then begin
    ss('protocol.dat');
    assign(xp1,gp+'protocol.dat');
    {$I-} reset(xp1); {$I+}
    if (ioresult<>0) then cantopen;
    inc(needs,sizeof(protrec)*filesize(xp1));
    close(xp1);
  end;

  if needc('7') then begin
    ss('shortmsg.dat');
    assign(smf1,gp+'shortmsg.dat');
    {$I-} reset(smf1); {$I+}
    if (ioresult<>0) then cantopen;
    {$I-} read(smf1,sm1); {$I+}
    inc(needs,sizeof(smalrec)*filesize(smf1));
    close(smf1);
  end;

  if needc('8') then begin
    ss('uploads.dat');
    assign(ulf1,gp+'uploads.dat');
    {$I-} reset(ulf1); {$I+}
    if (ioresult<>0) then cantopen;
    {$I-} read(ulf1,ubrd1); {$I+}
    inc(needs,sizeof(ulrec)*filesize(ulf1));
    close(ulf1);
  end;

  if needc('9') then begin
    ss('voting.dat');
    assign(vdf1,gp+'voting.dat');
    {$I-} reset(vdf1); {$I+}
    inc(needs,sizeof(vdatar)*filesize(vdf1));
    if (ioresult=0) then close(vdf1);
  end;

  if needc('A') then begin
    ss('zlog.dat');
    assign(ztf1,gp+'zlog.dat');
    {$I-} reset(ztf1); {$I+}
    if (ioresult<>0) then cantopen;
    {$I-} read(ztf1,zt1); {$I+}
    inc(needs,sizeof(zlogrec)*filesize(ztf1));
    close(ztf1);
  end;

  if needc('B') then begin
    ss('*.dir');
    ffile(gp+'*.dir');
    while (found) do begin
      assign(ulff1,fexpand(gp+dirinfo.name));
      {$I-} reset(ulff1); {$I+}
      inc(needs,sizeof(ulfrec)*filesize(ulff1));
      close(ulff1);
      nfile;
    end;
  end;
end;

function barconv(c:char):char;
var s:astr;
begin
  if (pos(c,artable)<>0) then s:=copy('ABCDEFG',pos(c,artable),1) else s:='@';
  barconv:=s[1];
end;

function arconv(c:char):char;
begin
  if (c in ['A'..'G']) then
    if (length(artable)>=ord(c)-64) and (artable[ord(c)-64] in ['@'..'Z']) then
      arconv:=artable[ord(c)-64]
    else arconv:='@'
  else arconv:='@';
end;


{rcg11172000 had to change this to get it compiling under Free Pascal...}
{function substall(src,old,new:astr):astr;}
function substall(src,old,_new:astr):astr;
var p:integer;
begin
  p:=1;
  while (p>0) do begin
    p:=pos(old,src);
    if (p>0) then begin
      insert(_new,src,p+length(old));
      delete(src,p,length(old));
    end;
  end;
  substall:=src;
end;

procedure bconvert(xx:integer);
var i,j,k:integer;
    s:astr;
    b:boolean;
begin
  case xx of
(*
    6:begin
        ttl('BACKWARD Converting "PROTOCOL.DAT');
        chdir(copy(gp,1,length(gp)-1));
        ffile('protocol.dat');
        if (not found) then star('PROTOCOL.DAT not found.')
        else begin

          assign(xp,'protocol.old'); rewrite(xp); close(xp); erase(xp);
          assign(xp,'protocol.tcp'); rewrite(xp); close(xp); erase(xp);
          assign(xp,'protocol.dat'); reset(xp);
          assign(xp1,'protocol.tcp'); rewrite(xp1);

          for i:=0 to filesize(xp)-1 do begin
            seek(xp,i); read(xp,xpr);
            star('  (record #'+cstr(i)+' of '+cstr(filesize(xp)-1)+')'); gotoxy(1,wherey-1);

            with xpr1 do begin
              active:=(xbactive in xpr.xbstat);
              isbatch:=(xbisbatch in xpr.xbstat);
              isresume:=(xbisresume in xpr.xbstat);
              xferokcode:=(xbxferokcode in xpr.xbstat);
              ckeys:=xpr.ckeys;
              descr:=xpr.descr;
              minbaud:=xpr.minbaud;
              maxbaud:=19200; maxbaud:=maxbaud*2;
              sl:=xpr.sl;
              dsl:=xpr.dsl;
              ar:=xpr.ar;
              templog:=xpr.templog;
              uloadlog:=xpr.uloadlog;
              dloadlog:=xpr.dloadlog;
              ulcmd:=xpr.ulcmd;
              dlcmd:=xpr.dlcmd;
              for j:=1 to 6 do begin
                ulcode[j]:=xpr.ulcode[j];
                dlcode[j]:=xpr.dlcode[j];
              end;
              envcmd:=xpr.envcmd;
              dlflist:=xpr.dlflist;
              maxchrs:=xpr.maxchrs;
              logpf:=xpr.logpf;
              logps:=xpr.logps;
            end;

            seek(xp1,i); write(xp1,xpr1);
          end;
          close(xp);
          close(xp1);
          rename(xp,'protocol.old');
          rename(xp1,'protocol.dat');
          writeln;
        end;
        chdir(sp);
      end;
*)
   12:begin
        ttl('-®<®--BACKWARD--®<®- Converting "*.BRD" message base info files');
        chdir(copy(gp,1,length(gp)-1));
        ffile('*.brd');
        if not found then star('No *.BRD files present.')
        else begin
          repeat
            s:=dirinfo.name;

            assign(mbasef,copy(s,1,length(s)-3)+'old'); rewrite(mbasef);
            close(mbasef); erase(mbasef);

            assign(mbasef,copy(s,1,length(s)-3)+'tcp'); rewrite(mbasef);
            close(mbasef); erase(mbasef);

            assign(mbasef,s); reset(mbasef);

            assign(mbasef1,copy(s,1,length(s)-3)+'tcp'); rewrite(mbasef1);

            star('Converting "'+s+'" ('+cstr(filesize(mbasef)-1)+' messages)');

            for i:=0 to filesize(mbasef)-1 do begin
              seek(mbasef,i); read(mbasef,mbase);
              with mbase do begin
                mbase1.title:=title;
                if (validated in messagestat) then mbase1.messagestat:=validated1;
                if (unvalidated in messagestat) then mbase1.messagestat:=unvalidated1;
                if (deleted in messagestat) then mbase1.messagestat:=deleted1;
                mbase1.message.ltr:=message.ltr;
                mbase1.message.number:=message.number;
                mbase1.message.ext:=message.ext;
                mbase1.owner:=owner;
                mbase1.date:=mbase1.date;
                mbase1.mage:=255;
              end;
              write(mbasef1,mbase1);
            end;

            close(mbasef1);
            close(mbasef);
            rename(mbasef1,copy(s,1,length(s)-3)+'obr');

            nfile;
          until (not found);
          ffile('*.obr');
          while (found) do begin
            s:=dirinfo.name;
            assign(mbasef1,copy(s,1,length(s)-3)+'brd');
            rename(mbasef1,copy(s,1,length(s)-3)+'old');
            assign(mbasef,s); rename(mbasef,copy(s,1,length(s)-3)+'brd');
            nfile;
          end;
        end;
        chdir(sp);
      end;
  end;
end;

procedure fconvert(xx:integer);
const dcols:clrs=((15,7,7,15,15,15,112,7,143,7),(15,3,1,11,9,14,31,4,140,10));
var i,j,k:integer;
    b:boolean;
    s,s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15:astr;
    c:char;
    mf,mf1:text;
    sepmsgs,nocopy,bla,b1,b2:boolean;
    f:file;
    mary:array[0..200] of messagerec;
    curdir:astr;
    newpath:array[1..3] of astr;
    fff:file;
    menuline:array[1..13] of string[255];
    uu:uflags1;
    numread:word;

  procedure make_paths;
  var s:string;
      i,j:integer;
  begin
    for i:=1 to 3 do begin
      {rcg11242000 Dosism.}
      {while copy(newpath[i],length(newpath[i]),1)='\' do}
      while copy(newpath[i],length(newpath[i]),1)='/' do
        newpath[i]:=copy(newpath[i],1,length(newpath[i])-1);
      case i of 1:s:='AFILES'; 2:s:='TRAP'; 3:s:='TEMP'; end;
      star(s+' path ("'+fexpand(newpath[i])+'")');
      {$I-} mkdir(fexpand(newpath[i])); {$I+}
      if (ioresult<>0) then begin
        writeln;
        star('Error creating directory "'+fexpand(newpath[i])+'"');
        halt(1);
      end;
      if (i=3) then
        for j:=1 to 3 do begin
          {rcg11242000 DOSism.}
          (*{$I-} mkdir(fexpand(newpath[i]+'\'+cstr(j))); {$I+}*)
          {$I-} mkdir(fexpand(newpath[i]+'/'+cstr(j))); {$I+}
          if (ioresult<>0) then begin
            writeln;
            {rcg11242000 DOSism.}
            {star('Error creating directory "'+fexpand(newpath[i]+'\'+cstr(j))+'"');}
            star('Error creating directory "'+fexpand(newpath[i]+'/'+cstr(j))+'"');
            halt(1);
          end;
        end;
      {rcg11242000 DOSism.}
      {newpath[i]:=newpath[i]+'\';}
      newpath[i]:=newpath[i]+'/';
    end;
  end;

  function sacs(b:byte):string;
  begin
    if (b>0) then sacs:='s'+cstr(b) else sacs:='';
  end;

begin
  case xx of
    0:begin
        ttl('Converting "STATUS.DAT"');
        ffile('status.dat');
        if (not found) then star('STATUS.DAT not found.')
        else begin

          assign(systatf1,'status.old'); rewrite(systatf1); close(systatf1); erase(systatf1);
          assign(systatf1,'status.tcp'); rewrite(systatf1); close(systatf1); erase(systatf1);

          assign(systatf,'status.tcp'); rewrite(systatf);
          assign(systatf1,'status.dat');

          reset(systatf1); read(systatf1,systat1);

          if (standard_conversion) then    { default settings for STANDARDs }
            with systat1 do begin
              arq9600rate:=9600;
              allstartmenu:='MAIN';
              wfcblanktime:=0;
              validateallfiles:=FALSE;
              maxintemp:=500;
              slogtype:=0;
              stripclog:=FALSE;
              noforcerate:=FALSE;
              rebootforevent:=TRUE;
              minresume:=100;
              windowon:=TRUE;
              curwindow:=1;
            end;

          with systat1 do begin
            systat.gfilepath:=gfilepath;
            systat.afilepath:=afilepath;
            systat.menupath:=menupath;
            systat.trappath:=trappath;
            systat.pmsgpath:=pmsgpath;
            systat.tfilepath:=tfilepath;
            systat.temppath:=temppath;

            systat.bbsname:=bbsname;
            systat.bbsphone:=bbsphone;
            systat.sysopname:=sysopfirst+' '+sysoplast;
{**}         systat.maxusers:=500;
            systat.lowtime:=lowtime;
            systat.hitime:=hitime;
            systat.dllowtime:=dllowtime;
            systat.dlhitime:=dlhitime;
            systat.shuttlelog:=matrix;
            systat.lock300:=lock300;
            systat.sysoppw:=sysoppw;
            systat.newuserpw:=boardpw;
            systat.shuttlepw:=bbspw;
            systat.b300lowtime:=b300lowtime;
            systat.b300hitime:=b300hitime;
            systat.b300dllowtime:=b300dllowtime;
            systat.b300dlhitime:=b300dlhitime;
            systat.closedsystem:=closedsystem;
            systat.snowchecking:=snowchecking;
            systat.eventwarningtime:=eventwarningtime;
            systat.tfiledate:=tfiledate;
            systat.hmsg.ltr:=hmsg.ltr;
            systat.hmsg.number:=hmsg.number;
            systat.hmsg.ext:=hmsg.ext;
            for j:=1 to 20 do systat.res[j]:=0;

            systat.sop:=sacs(sop);
            systat.csop:=sacs(csop);
            systat.msop:=sacs(msop);
            systat.fsop:=sacs(fsop);
            systat.spw:=sacs(spw);
            systat.seepw:=sacs(seepw);
            systat.normpubpost:=sacs(normpubpost);
            systat.normprivpost:=sacs(normprivpost);
            systat.anonpubread:=sacs(anonpubread);
            systat.anonprivread:=sacs(anonprivread);
            systat.anonpubpost:=sacs(anonpubpost);
            systat.anonprivpost:=sacs(anonprivpost);
            systat.seeunval:=sacs(seeunval);
            systat.dlunval:=sacs(dlunval);
            systat.nodlratio:=sacs(nodlratio);
            systat.nopostratio:=sacs(nopostratio);
            systat.nofilepts:=sacs(nofilepts);
            systat.ulvalreq:=sacs(ulvalreq);
            for j:=1 to 100 do systat.res2[j]:=0;

            systat.maxprivpost:=maxprivpost;
            systat.maxfback:=maxfback;
            systat.maxpubpost:=maxpubpost;
            systat.maxchat:=maxchat;
            systat.maxwaiting:=maxwaiting;
            systat.csmaxwaiting:=csmaxwaiting;
            systat.maxlines:=maxlines;
            systat.csmaxlines:=csmaxlines;
            systat.maxlogontries:=tries;
            systat.bsdelay:=bsdelay;
            systat.sysopcolor:=sysopcolor;
            systat.usercolor:=usercolor;
            systat.minspaceforpost:=minspaceforpost;
            systat.minspaceforupload:=minspaceforupload;
            systat.backsysoplogs:=backsysoplogs;
            systat.wfcblanktime:=wfcblanktime;
            for j:=1 to 20 do systat.res3[j]:=0;

            systat.specialfx:=special;
            systat.clearmsg:=clearmsg;
            systat.allowalias:=alias;
            systat.phonepw:=fone;
            systat.localsec:=localsec;
            systat.localscreensec:=localscreensec;
            systat.globaltrap:=globaltrap;
            systat.autochatopen:=autochatopen;
            systat.autominlogon:=autominlogon;
            systat.bullinlogon:=bullinlogon;
            systat.lcallinlogon:=lcallinlogon;
            systat.yourinfoinlogon:=yourinfoinlogon;
            systat.multitask:=multitask;
            systat.offhooklocallogon:=offhooklocallogon;
            systat.forcevoting:=forcevoting;
            systat.compressbases:=compressbases;
            systat.searchdup:=searchdup;
            systat.slogtype:=slogtype;
            systat.stripclog:=stripclog;
            systat.newapp:=app;
            systat.guestuser:=guestuser;
            systat.timeoutbell:=timeoutbell;
            systat.timeout:=timeout;
            for j:=1 to 20 do systat.res4[j]:=0;

            for j:=1 to maxarcs1 do begin
              systat.filearcinfo[j].active:=filearcinfo[j].active;
              systat.filearcinfo[j].ext:=filearcinfo[j].ext;
              systat.filearcinfo[j].listline:=filearcinfo[j].listline;
              systat.filearcinfo[j].arcline:=filearcinfo[j].arcline;
              systat.filearcinfo[j].unarcline:=filearcinfo[j].unarcline;
              systat.filearcinfo[j].testline:=filearcinfo[j].testline;
              systat.filearcinfo[j].cmtline:=filearcinfo[j].cmtline;
              systat.filearcinfo[j].succlevel:=filearcinfo[j].succlevel;
            end;
            systat.filearcinfo[7].ext:='';
            systat.filearcinfo[8].ext:='';
            for j:=1 to 3 do systat.filearccomment[j]:=filearccomment[j];
            systat.uldlratio:=uldlratio;
            systat.fileptratio:=fileptratio;
            systat.fileptcomp:=fileptcomp;
            systat.fileptcompbasesize:=fileptcompbasesize;
            systat.ulrefund:=ulrefund;
            systat.tosysopdir:=tosysopdir;
            systat.validateallfiles:=validateallfiles;
            systat.remdevice:=remdevice;
            systat.maxintemp:=maxintemp;
            systat.minresume:=minresume;
{**}         systat.maxdbatch:=30;
{**}         systat.maxubatch:=30;
            for j:=1 to 30 do systat.res5[j]:=0;

            systat.newsl:=newsl;
            systat.newdsl:=newdsl;
            systat.newar:=[];
            for c:='A' to 'Z' do
              if (c in newar) then systat.newar:=systat.newar+[c];
            systat.newac:=[];
            if (rlogon1 in newac) then systat.newac:=systat.newac+[rlogon];
            if (rchat1 in newac) then systat.newac:=systat.newac+[rchat];
            if (rvalidate1 in newac) then systat.newac:=systat.newac+[rvalidate];
            if (rbackspace1 in newac) then systat.newac:=systat.newac+[rbackspace];
            if (ramsg1 in newac) then systat.newac:=systat.newac+[ramsg];
            if (rpostan1 in newac) then systat.newac:=systat.newac+[rpostan];
            if (rpost1 in newac) then systat.newac:=systat.newac+[rpost];
            if (remail1 in newac) then systat.newac:=systat.newac+[remail];
            if (rvoting1 in newac) then systat.newac:=systat.newac+[rvoting];
            if (rmsg1 in newac) then systat.newac:=systat.newac+[rmsg];
            if (fnodlratio1 in newac) then systat.newac:=systat.newac+[fnodlratio];
            if (fnopostratio1 in newac) then systat.newac:=systat.newac+[fnopostratio];
            if (fnofilepts1 in newac) then systat.newac:=systat.newac+[fnofilepts];
            if (fnodeletion1 in newac) then systat.newac:=systat.newac+[fnodeletion];
            systat.newfp:=newfp;
            systat.autosl:=autosl;
            systat.autodsl:=autodsl;
            systat.autoar:=[];
            for c:='A' to 'Z' do
              if (c in autoar) then systat.autoar:=systat.autoar+[c];
            systat.autoac:=[];
            if (rlogon1 in autoac) then systat.autoac:=systat.autoac+[rlogon];
            if (rchat1 in autoac) then systat.autoac:=systat.autoac+[rchat];
            if (rvalidate1 in autoac) then systat.autoac:=systat.autoac+[rvalidate];
            if (rbackspace1 in autoac) then systat.autoac:=systat.autoac+[rbackspace];
            if (ramsg1 in autoac) then systat.autoac:=systat.autoac+[ramsg];
            if (rpostan1 in autoac) then systat.autoac:=systat.autoac+[rpostan];
            if (rpost1 in autoac) then systat.autoac:=systat.autoac+[rpost];
            if (remail1 in autoac) then systat.autoac:=systat.autoac+[remail];
            if (rvoting1 in autoac) then systat.autoac:=systat.autoac+[rvoting];
            if (rmsg1 in autoac) then systat.autoac:=systat.autoac+[rmsg];
            if (fnodlratio1 in autoac) then systat.autoac:=systat.autoac+[fnodlratio];
            if (fnopostratio1 in autoac) then systat.autoac:=systat.autoac+[fnopostratio];
            if (fnofilepts1 in autoac) then systat.autoac:=systat.autoac+[fnofilepts];
            if (fnodeletion1 in autoac) then systat.autoac:=systat.autoac+[fnodeletion];

            systat.allstartmenu:=allstartmenu;
            for j:=1 to 50 do systat.res6[j]:=0;

            for j:=0 to 255 do systat.timeallow[j]:=timeallow[j];
            for j:=0 to 255 do systat.callallow[j]:=callallow[j];
            for j:=0 to 255 do systat.dlratio[j]:=dlratio[j];
            for j:=0 to 255 do systat.dlkratio[j]:=dlkratio[j];
            for j:=0 to 255 do systat.postratio[j]:=postratio[j];

            systat.lastdate:=lastdate;
            systat.curwindow:=1;
            systat.istopwindow:=istopwindow;
            systat.callernum:=callernum;
            systat.numusers:=users;

            systat.todayzlog.date:=lastdate;
            for j:=0 to 4 do systat.todayzlog.userbaud[j]:=userbaud[j];
            systat.todayzlog.active:=activetoday;
            systat.todayzlog.calls:=callstoday;
            systat.todayzlog.newusers:=newusertoday;
            systat.todayzlog.pubpost:=msgposttoday;
            systat.todayzlog.privpost:=emailtoday;
            systat.todayzlog.fback:=fbacktoday;
            systat.todayzlog.criterr:=criterr;
            systat.todayzlog.uploads:=uptoday;
            systat.todayzlog.downloads:=dntoday;
            systat.todayzlog.uk:=newuk;
            systat.todayzlog.dk:=newdk;

{**}         systat.postcredits:=0;
{**}         systat.rebootforevent:=TRUE;
{**}         systat.watchdogdoor:=TRUE;
            for j:=1 to 200 do res[j]:=0;

          end;

          seek(systatf,0); write(systatf,systat);

          star('Done.');
          writeln;
          ttl('Generating "MODEM.DAT" *from* "STATUS.DAT"');

          assign(modemrf,systat.gfilepath+'modem.dat');
          rewrite(modemrf);
          with systat1 do begin
            modemr.waitbaud:=maxbaud;
            modemr.comport:=comport;
            modemr.init:=init;
            modemr.answer:=answer;
            modemr.hangup:=hangup;
            modemr.offhook:=offhook;
            modemr.nocallinittime:=nocallinittime;
            modemr.arq9600rate:=arq9600rate;
            modemr.noforcerate:=noforcerate;
            modemr.nocarrier:=nocarrier;
            modemr.nodialtone:=nodialtone;
            modemr.busy:=busy;
            for i:=1 to 2 do
              for j:=0 to 4 do modemr.resultcode[i][j]:=resultcode[i][j];
            modemr.ctschecking:=TRUE;
            modemr.dsrchecking:=TRUE;
            modemr.usexonxoff:=FALSE;
            modemr.hardwired:=FALSE;
          end;
          write(modemrf,modemr);
          close(modemrf);

          star('Done.');
          writeln;
          ttl('Generating "STRING.DAT" *from* "STATUS.DAT"');

          assign(fstringf,systat.gfilepath+'string.dat');
          rewrite(fstringf);
          with systat1 do begin
            fstring.ansiq:=ansiq;
            for j:=1 to 2 do fstring.note[j]:=note[j];
            fstring.lprompt:=lprompt;
            fstring.echoc:=echoc;
            fstring.sysopin:=sysopin;
            fstring.sysopout:=sysopout;
            fstring.engage:=engage;
            fstring.endchat:=endchat;
            fstring.wait:=wait;
            fstring.pause:=pause;
            fstring.entermsg1:=msg1;
            fstring.entermsg2:=msg2;
            fstring.newscan1:=new1;
            fstring.newscan2:=new2;
            fstring.scanmessage:=read;
            fstring.automsgt:=auto1;
            fstring.autom:=autom;

            fstring.shelldos1:=#3#5+'>> '+systat.sysopname+' has Shelled to dos, please wait ...';
            fstring.shelldos2:=#3#5+'>> Thank you for waiting';
            fstring.chatcall1:=#3#0+'Paging '+systat.sysopname+' for chat, please wait.....';
            fstring.chatcall2:=#3#7+' >>'+#3#5+'<'+#3#8+'*'+#3#5+'>'+#3#7+'<<';
            fstring.guestline:='Enter "GUEST" as your user name to be a guest user on the system.';
            fstring.namenotfound:=#3#5+'That name is'+#3#8+' NOT'+#3#5+' found in the user list.';
            fstring.bulletinline:=#3#4+'Enter Bulletin Selection (XX,?,Q=Quit) : ';
            fstring.thanxvote:=#3#3+'Thanks for taking the time to vote!';

            fstring.listline:='List files - P to Pause';
            fstring.newline:='Search for new files -';
            fstring.searchline:='Search all directories for a file mask -';
            fstring.findline1:='Search descriptions and filenames for keyword -';
            fstring.findline2:='Enter the string to search for:';
            fstring.downloadline:='Download - You have @P file points.';
            fstring.uploadline:='Upload - @Kk free on this drive';
            fstring.viewline:='View archive interior files -@MP to Pause, N for Next file';
            fstring.nofilepts:=#3#8+'Access denied: '+#3#5+'Insufficient file points to download.';
            fstring.unbalance:=#3#8+'Access denied: '+#3#5+'Your upload/download ratio is out of balance:';

            fstring.pninfo:='P to Pause, N for next directory';
            fstring.gfnline1:='[Enter]=All files';
            fstring.gfnline2:=#3#4+'File mask: ';
            fstring.batchadd:='File added to batch queue.';
          end;
          write(fstringf,fstring);
          close(fstringf);

          star('Done.');
          writeln;

          close(systatf);
          close(systatf1);
          rename(systatf1,'status.old');
          rename(systatf,'status.dat');

          writeln;
        end;
      end;
    2:begin
        ttl('PATCHING "USER.LST" - No conversion necessary');
        chdir(copy(gp,1,length(gp)-1));
        ffile('user.lst');
        if not found then star('USER.LST not found.')
        else begin
          assign(uf0,'user.old'); rewrite(uf0); close(uf0); erase(uf0);
          assign(uf0,'user.lst'); rename(uf0,'user.old'); reset(uf0);
          assign(uf1,'user.old'); reset(uf1);
          assign(uf,'user.lst'); rewrite(uf);

          for i:=0 to filesize(uf0)-1 do begin
            seek(uf0,i); read(uf0,user0);
            seek(uf1,i); read(uf1,user1);
            star('  (record #'+cstr(i)+' of '+cstr(filesize(uf0)-1)+')'); gotoxy(1,wherey-1);
            user:=user0;

            user.ttimeon:=round(user1.ttimeon);
            user.uk:=round(user1.uk);
            user.dk:=round(user1.dk);
            user.credit:=round(user1.credit);

            user.chatauto:=FALSE;
            user.chatseperate:=FALSE;

            seek(uf,i); write(uf,user);
          end;
          close(uf0);
          close(uf);
          writeln;
        end;
        chdir(sp);
      end;
    3:begin
        ttl('Converting "BOARDS.DAT');
        chdir(copy(gp,1,length(gp)-1));
        ffile('boards.dat');
        if (not found) then star('BOARDS.DAT not found.')
        else begin
          assign(bf1,'boards.old'); rewrite(bf1); close(bf1); erase(bf1);
          assign(bf1,'boards.tcp'); rewrite(bf1); close(bf1); erase(bf1);
          assign(bf1,'boards.dat'); reset(bf1);
          assign(bf,'boards.tcp'); rewrite(bf);

          for i:=0 to filesize(bf1)-1 do begin
            seek(bf1,i); read(bf1,brd1);
            star('  (record #'+cstr(i)+' of '+cstr(filesize(bf1)-1)+')'); gotoxy(1,wherey-1);

            with brd1 do begin
              brd.name:=name;
              brd.filename:=filename;
              brd.msgpath:=msgpath;
              brd.acs:='';
              if (sl<>0) then brd.acs:=brd.acs+'s'+cstr(sl);
              if (ar in ['A'..'Z']) then brd.acs:=brd.acs+'f'+ar;
              brd.postacs:='';
              if (postsl<>0) then brd.postacs:=brd.postacs+'s'+cstr(postsl);
              brd.mciacs:='';
              brd.maxmsgs:=maxmsgs;
              if (anonymous=yes1) then brd.anonymous:=yes else
                if (anonymous=no1) then brd.anonymous:=no else
                  if (anonymous=forced1) then brd.anonymous:=forced else
                    if (anonymous=dearabby1) then brd.anonymous:=dearabby;
              brd.password:=password;
              brd.mbstat:=[];
              brd.permindx:=i;
              brd.mbdepth:=0;
              for j:=1 to 4 do brd.res[j]:=0;
            end;

            seek(bf,i); write(bf,brd);
          end;
          close(bf1);
          close(bf);
          rename(bf1,'boards.old');
          rename(bf,'boards.dat');
          writeln;
        end;
        chdir(sp);
      end;
    5:begin
        ttl('Converting "GFILES.DAT');
        chdir(copy(gp,1,length(gp)-1));
        ffile('gfiles.dat');
        if (not found) then star('GFILES.DAT not found.')
        else begin

          assign(gfilef1,'gfiles.old'); rewrite(gfilef1); close(gfilef1); erase(gfilef1);
          assign(gfilef1,'gfiles.tcp'); rewrite(gfilef1); close(gfilef1); erase(gfilef1);
          assign(gfilef1,'gfiles.dat'); reset(gfilef1);
          assign(gfilef,'gfiles.tcp'); rewrite(gfilef);

          for i:=0 to filesize(gfilef1)-1 do begin
            seek(gfilef1,i); read(gfilef1,gfile1);
            star('  (record #'+cstr(i)+' of '+cstr(filesize(gfilef1)-1)+')'); gotoxy(1,wherey-1);

            if (i=0) then gfile.gdaten:=gfile1.num
            else
              with gfile do begin
                title:=gfile1.title;
                filen:=gfile1.filen;
                gdate:=gfile1.gdate;
                gdaten:=gfile1.gdaten;
                acs:='';
                if (gfile1.num>0) then acs:=acs+'s'+cstr(gfile1.num);
                if (gfile1.ar in ['A'..'Z']) then acs:=acs+'f'+gfile1.ar;
                if (filen=#1#0#0#0#0#0) then ulacs:='%' else ulacs:='';
                tbstat:=[];
                permindx:=i;
                tbdepth:=0;
                for j:=1 to 4 do res[j]:=0;
              end;

            seek(gfilef,i); write(gfilef,gfile);
          end;
          close(gfilef1);
          close(gfilef);
          rename(gfilef1,'gfiles.old');
          rename(gfilef,'gfiles.dat');
          writeln;
        end;
        chdir(sp);
      end;
    6:begin
        ttl('Converting "PROTOCOL.DAT');
        chdir(copy(gp,1,length(gp)-1));
        ffile('protocol.dat');
        if (not found) then star('PROTOCOL.DAT not found.')
        else begin
          assign(xp1,'protocol.old'); rewrite(xp1); close(xp1); erase(xp1);
          assign(xp1,'protocol.tcp'); rewrite(xp1); close(xp1); erase(xp1);
          assign(xp1,'protocol.dat'); reset(xp1);
          assign(xp,'protocol.tcp'); rewrite(xp);

          for i:=0 to filesize(xp1)-1 do begin
            seek(xp1,i); read(xp1,xpr1);
            star('  (record #'+cstr(i)+' of '+cstr(filesize(xp1)-1)+')'); gotoxy(1,wherey-1);

            with xpr1 do begin
              xpr.xbstat:=[];
              if (active) then xpr.xbstat:=xpr.xbstat+[xbactive];
              if (isbatch) then xpr.xbstat:=xpr.xbstat+[xbisbatch];
              if (isresume) then xpr.xbstat:=xpr.xbstat+[xbisresume];
              if (xferokcode) then xpr.xbstat:=xpr.xbstat+[xbxferokcode];
              xpr.ckeys:=ckeys;
              xpr.descr:=descr;
              xpr.acs:='';
              if (sl>0) then xpr.acs:=xpr.acs+'s'+cstr(sl);
              if (dsl>0) then xpr.acs:=xpr.acs+'d'+cstr(dsl);
              if (ar in ['A'..'Z']) then xpr.acs:=xpr.acs+'f'+ar;
(*              if ((minbaud<>300) or (maxbaud<>38400)) then begin
                if (minbaud<>300) then xpr.acs:=xpr.acs+'b'+cstr(minbaud div 100);
                if (maxbaud<>38400) then xpr.acs:=xpr.acs+'!b'+cstr(maxbaud div 100);
              end;*)
              xpr.templog:=templog;
              xpr.uloadlog:=uloadlog;
              xpr.dloadlog:=dloadlog;
              (* MUST PUT DSZ PARAMS IN HERE .....  vvv *)
              if (ulcmd='XMODEM') then xpr.ulcmd:='dsz port %P speed %B rx %F' else
                if (ulcmd='XMODEM-CRC') then xpr.ulcmd:='dsz port %P speed %B rc %F' else
                  if (ulcmd='YMODEM') then begin
                    if (isbatch) then
                      xpr.ulcmd:='dsz port %P speed %B rb -k'
                    else
                      xpr.ulcmd:='dsz port %P speed %B rb -k %F';
                  end else
                    xpr.ulcmd:=ulcmd;
              if (dlcmd='XMODEM') then xpr.dlcmd:='dsz port %P speed %B sx %F' else
                if (dlcmd='XMODEM-CRC') then xpr.dlcmd:='dsz port %P speed %B sx %F' else
                  if (dlcmd='YMODEM') then begin
                    if (isbatch) then
                      xpr.dlcmd:='dsz port %P speed %B sb @%L'
                    else
                      xpr.dlcmd:='dsz port %P speed %B sb %F';
                  end else
                    xpr.dlcmd:=dlcmd;
              for j:=1 to 6 do begin
                xpr.ulcode[j]:=ulcode[j];
                xpr.dlcode[j]:=dlcode[j];
              end;
              xpr.envcmd:=envcmd;
              xpr.dlflist:=dlflist;
              xpr.maxchrs:=maxchrs;
              xpr.logpf:=logpf;
              xpr.logps:=logps;
              xpr.permindx:=i;
              for j:=1 to 11 do xpr.res[j]:=0;
            end;

            seek(xp,i); write(xp,xpr);
          end;

          close(xp1);
          close(xp);
          rename(xp1,'protocol.old');
          rename(xp,'protocol.dat');
          writeln;
        end;
        chdir(sp);
      end;
    8:begin
        ttl('Converting "UPLOADS.DAT');
        chdir(copy(gp,1,length(gp)-1));
        ffile('uploads.dat');
        if (not found) then star('UPLOADS.DAT not found.')
        else begin

          assign(ulf1,'uploads.old'); rewrite(ulf1); close(ulf1); erase(ulf1);
          assign(ulf1,'uploads.tcp'); rewrite(ulf1); close(ulf1); erase(ulf1);
          assign(ulf1,'uploads.dat'); reset(ulf1);
          assign(ulf,'uploads.tcp'); rewrite(ulf);

          for i:=0 to filesize(ulf1)-1 do begin
            seek(ulf1,i); read(ulf1,ubrd1);
            star('  (record #'+cstr(i)+' of '+cstr(filesize(ulf1)-1)+')'); gotoxy(1,wherey-1);

            with ubrd1 do begin
              ubrd.name:=name;
              ubrd.filename:=filename;
              ubrd.dlpath:=dlpath;
              ubrd.ulpath:=dlpath;
              ubrd.maxfiles:=maxfiles;
              if (ubrd.maxfiles>2000) then ubrd.maxfiles:=2000;
              ubrd.password:=password;
              ubrd.arctype:=arctype;
              ubrd.cmttype:=cmttype;
              ubrd.fbdepth:=0;
              ubrd.fbstat:=[];
              if (noratio) then ubrd.fbstat:=ubrd.fbstat+[fbnoratio];
              if (unhidden) then ubrd.fbstat:=ubrd.fbstat+[fbunhidden];
              ubrd.acs:='';
              if (sl>0) then ubrd.acs:=ubrd.acs+'s'+cstr(sl);
              if (dsl>0) then ubrd.acs:=ubrd.acs+'d'+cstr(dsl);
              if (ar in ['A'..'Z']) then ubrd.acs:=ubrd.acs+'f'+ar;
              if (agereq>1) then ubrd.acs:=ubrd.acs+'a'+cstr(agereq);
              ubrd.ulacs:='';
              ubrd.nameacs:='';
              if (namesl>0) then
                ubrd.nameacs:=ubrd.nameacs+'s'+cstr(namesl);
              ubrd.permindx:=i;
              for j:=1 to 6 do ubrd.res[j]:=0;
            end;

            seek(ulf,i); write(ulf,ubrd);
          end;
          close(ulf1);
          close(ulf);
          rename(ulf1,'uploads.old');
          rename(ulf,'uploads.dat');
          writeln;
        end;
        chdir(sp);
      end;
   12:begin
        ttl('Converting "*.BRD" message base info files');
        chdir(copy(gp,1,length(gp)-1));
        ffile('*.brd');
        if not found then star('No *.BRD files present.')
        else begin
          repeat
            s:=dirinfo.name;

            assign(mbasef1,copy(s,1,length(s)-3)+'old'); rewrite(mbasef1);
            close(mbasef1); erase(mbasef1);

            assign(mbasef1,copy(s,1,length(s)-3)+'tcp'); rewrite(mbasef1);
            close(mbasef1); erase(mbasef1);

            assign(mbasef1,s); reset(mbasef1);

            assign(mbasef,copy(s,1,length(s)-3)+'tcp'); rewrite(mbasef);

            star('Converting "'+s+'" ('+cstr(filesize(mbasef1)-1)+' messages)');

            for i:=0 to filesize(mbasef1)-1 do begin
              seek(mbasef1,i); read(mbasef1,mbase1);
              with mbase1 do begin
                mbase.title:=title;
                if (messagestat=validated1) then mbase.messagestat:=[validated];
                if (messagestat=unvalidated1) then mbase.messagestat:=[unvalidated];
                if (messagestat=deleted1) then mbase.messagestat:=[deleted];
                mbase.message.ltr:=message.ltr;
                mbase.message.number:=message.number;
                mbase.message.ext:=message.ext;
                mbase.owner:=owner;
                mbase.date:=mbase1.date;
                mbase.nacc:=0;
              end;
              write(mbasef,mbase);
            end;

            close(mbasef);
            close(mbasef1);
            rename(mbasef,copy(s,1,length(s)-3)+'obr');

            nfile;
          until (not found);
          ffile('*.obr');
          while (found) do begin
            s:=dirinfo.name;
            assign(mbasef1,copy(s,1,length(s)-3)+'brd');
            rename(mbasef1,copy(s,1,length(s)-3)+'old');
            assign(mbasef,s); rename(mbasef,copy(s,1,length(s)-3)+'brd');
            nfile;
          end;
        end;
        chdir(sp);
      end;
   13:begin
        ttl('Converting "*.MNU" menu files');
        chdir(copy(mp,1,length(mp)-1));
        ffile('*.mnu');
        if not found then star('No *.MNU files present.')
        else begin
          repeat

            { Converts MNU --> TCP, and only upon successful conversion of
               ALL MNU files does "CO" rename all MNU --> OLD,
               and TCP --> MNU }

            s:=dirinfo.name;
            assign(mf1,copy(s,1,length(s)-3)+'OLD'); rewrite(mf1); close(mf1);
            erase(mf1);

            assign(mf1,copy(s,1,length(s)-3)+'TCP'); rewrite(mf1); close(mf1);
            erase(mf1);

            if (ioresult<>0) then star('Error renaming "'+s+'" -  Nothing done.')
            else begin
              assign(mf1,s); {$I-} reset(mf1); {$I+}
              assign(mf,copy(s,1,length(s)-3)+'TCP'); {$I-} rewrite(mf); {$I+}

              star('Converting "'+s+'"');

              for i:=1 to 13 do readln(mf1,menuline[i]);

              writeln(mf,menuline[1]);
              writeln(mf,'');
              writeln(mf,'');
              writeln(mf,menuline[2]);
              writeln(mf,menuline[3]);
              writeln(mf,menuline[4]);

              b1:=(pos('D',menuline[13])<>0);
              s1:='';
              if (value(menuline[5])>0) then
                if (b1) then s1:=s1+'d'+menuline[5]
                else s1:=s1+'s'+menuline[5];
              if (menuline[6][1] in ['A'..'Z']) then s1:=s1+'f'+menuline[6][1];
              writeln(mf,s1);

              writeln(mf,menuline[7]);
              writeln(mf,menuline[8]);

              s1:='0';
              if (pos('H',menuline[13])<>0) then s1:='2';
              writeln(mf,s1);

              writeln(mf,menuline[9]);
              writeln(mf,menuline[10]);
              writeln(mf,menuline[11]);
              writeln(mf,menuline[12]);
              s1:=menuline[13];
              if (pos('D',s1)<>0) then delete(s1,pos('D',s1),1);
              if (pos('H',s1)<>0) then delete(s1,pos('H',s1),1);
              writeln(mf,s1);

              repeat
                nocopy:=FALSE;

                for i:=1 to 8 do readln(mf1,menuline[i]);

                if (not nocopy) then begin
                  writeln(mf,menuline[1]);
                  writeln(mf,menuline[2]);
                  writeln(mf,menuline[3]);

                  b1:=(pos('D',menuline[8])<>0);
                  b2:=(pos('C',menuline[8])<>0);
                  s1:='';
                  if (value(menuline[4])>0) then
                    if (b1) then s1:=s1+'d'+menuline[4]
                    else s1:=s1+'s'+menuline[4];
                  if ((b2) and (value(menuline[4])>0) and
                      (menuline[5][1] in ['A'..'Z'])) then s1:=s1+'|';
                  if (menuline[5][1] in ['A'..'Z']) then s1:=s1+'f'+menuline[5][1];
                  writeln(mf,s1);

                  writeln(mf,menuline[6]);
                  writeln(mf,menuline[7]);
                  s1:=menuline[8];
                  if (pos('C',s1)<>0) then delete(s1,pos('C',s1),1);
                  if (pos('D',s1)<>0) then delete(s1,pos('D',s1),1);
                  if (pos('H',s1)<>0) then delete(s1,pos('H',s1),1)
                    else s1:=s1+'U';
                  writeln(mf,s1);
                end;
              until (eof(mf1));

              close(mf);
              close(mf1);
            end;
            nfile;
          until (not found);

          ffile('*.TCP');
          repeat
            s:=dirinfo.name;
            assign(mf1,copy(s,1,length(s)-3)+'MNU');
            rename(mf1,copy(s,1,length(s)-3)+'OLD');
            assign(mf,s);
            rename(mf,copy(s,1,length(s)-3)+'MNU');
            nfile;
          until (not found);

        end;
        chdir(sp);
      end;
  end;
end;

procedure convert(xx:integer);
var s:astr;
    i,j,k:integer;
    c:char;
begin
  case xx of
    0     :c:='S';
    1..9  :c:=chr(xx+48);
    10..20:c:=chr(xx+55);
  end;
  if (needc(c)) then
    if (back) then bconvert(xx) else fconvert(xx);
end;

begin
  if (standard_conversion) then ver:=s_ver;

  infield_out_fgrd:=15;
  infield_out_bkgd:=1;
  infield_inp_fgrd:=0;
  infield_inp_bkgd:=7;

  getdir(0,sp);
  aw:=FALSE;
  didit:=FALSE;
  if paramcount>0 then if allcaps(paramstr(1))='C' then aw:=TRUE;
  savx:=wherex; savy:=wherey;
  setwindow(wind,1,1,80,25,7,0,0);
  clrscr;
  textbackground(1); textcolor(15); clreol;
  write(' Telegard Conversion for '+ver1+' ¯¯¯¯¯¯¯¯¯ '+ver);
  textbackground(0);
  window(1,2,80,25); clrscr;
  tc(14);
  writeln;
  writeln('This program is provided to add/modify/create files used by Telegard to');
  writeln('make it 100% functional under the '+ver+' environment.  This file MUST');
  writeln('be ran in the directory in which STATUS.DAT is found, and STATUS.DAT MUST');
  writeln('be in '+ver1+' format!!!  If STATUS.DAT is not in the current directory,');
  writeln('or if you have already ran this program (STATUS.DAT has already been');
  writeln('converted), this program will abort.');
  writeln;
  tc(9); write('Hit any key to continue (<ESC> to abort NOW) : ');
  repeat until keypressed;
  c:=readkey;
  if (c=#27) then ee('ABORTED CONVERSION');

  repeat
    clrscr;
    fvers;

    if (not aw) then begin
      writeln;
      star('WARNING!  This conversion program needs APPROXIMATELY');
      star(cstrl(needs)+' bytes free on your main BBS drive!!!!!!!!');
      writeln;
      star('You currently have '+cstrl(freek(0)*1024)+' bytes left on the current drive.');
      writeln;
      star('If you DO NOT have enough space left, your drive will probably');
      star('explode, and your house will burn to the ground.  If you are');
      star('skeptical of this, feel free to call Garfield, SysOp of Electric');
      star('Eye ][ BBS (313/776-8928), who can tell you how bad HIS messed up');
      star('when he converted from 1.6d3 --> 1.6e1 with only 500k!');
      writeln;
      if (not l_pynq('Proceed? ')) then ee('Aborted conversion');
    end;

    clrscr;
    writeln;
    if aw then begin
      for i:=0 to 13 do begin
        if (i>=1) and (i<=9) then c:=chr(i+48) else
          if (i=0) then c:='S' else
            if (i>=10) then c:=chr(i+55);
        if needc(c) then begin
          tc(9); write('['+cstr(i)+'] ');
          if i<10 then write(' ');
          tc(11);
          case i of
            0:write('(S)tatus.dat');
            1:write('names.lst');
            2:write('user.lst');
            3:write('boards.dat');
            4:write('email.dat');
            5:write('gfiles.dat');
            6:write('protocol.dat');
            7:write('shortmsg.dat');
            8:write('uploads.dat');
            9:write('voting.dat');
           10:write('zlog.dat');
           11:write(gp+'*.dir');
           12:write(gp+'*.brd');
           13:write(mp+'*.mnu');
          end;
          writeln;
        end;
      end;
      writeln;
      tc(14); write('Enter # to convert, [A]ll or [Q]uit :');
      tc(9); readln(a); a:=allcaps(a);

      j:=value(a);
    end else
      a:='A';

    if (j=0) then
      if (copy(a,1,1)='S') then j:=0 else j:=-1;

    if (copy(a,1,1)<>'Q') or ((j>=0) and (j<=13)) then begin
      writeln;
      if aw then begin
        tc(14); write('[1]Convert to '+ver+' - [2]Convert back to '+ver1+' : ');
        tc(9); readln(b); b:=allcaps(b);
        h:=value(b);
      end else
        h:=1;

      if (h in [1,2]) then begin
        clrscr; tc(15);
        back:=FALSE;
        if h=2 then back:=TRUE;
        if back then begin
          tc(31);
          writeln('Convert '+ver+' ¯¯¯¯¯¯¯¯¯ '+ver1);
        end else
          writeln('Convert '+ver1+' ¯¯¯¯¯¯¯¯¯ '+ver);
        writeln;
        tc(4); write('WARNING: ');
        tc(12);
        if back then writeln('If files are not in version '+ver+' format,') else
                    writeln('If files are NOT in version '+ver1+' format,');
        writeln('the data will be COMPLETELY LOST *FOREVER*!!');
        writeln;
        writeln;
        tc(14); writeln('ARE YOU ABSOLUTELY SURE?');
        writeln('(Enter "YES" in ALL CAPS, without quotes, if you are...)');
        write(':');
        readln(b);

        if b='YES' then begin
          clrscr;

          if copy(a,1,1)<>'A' then convert(j)
          else begin
            for i:=0 to 13 do convert(i);
{            ttl('Moving new files into their directories');
            smovefile('protocol.dat',systat.gfilepath);
            smovefile('sysfunc.ans',systat.afilepath);}
          end;
          didit:=TRUE;
        end;
      end;
    end;
    if (not aw) then a:='Q';
  until copy(a,1,1)='Q';

  writeln;
  star('Press any key...'); c:=readkey;
  clrscr;
  removewindow(wind);

  if didit then begin
    setwindow(wind,20,11,59,17,9,1,1);
    clrscr; tc(15);
    gotoxy(4,3);
    write('Thank you for choosing Telegard!');
    CursorOff; delay(1500); CursorOn;
    removewindow(wind);
  end;
  gotoxy(savx,savy);
  chdir(sp);
end.
