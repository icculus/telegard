{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
{$M 50000,0,1024}       { Declared here suffices for all Units as well! }

uses
  crt,dos,

  {rcg11172000 No semicolon?}
  {myio,}

  myio;


const
  needconv = 'E';
  standard_conversion = FALSE;

{$I rcc17a.pas}

{rcg11172000 hmm...don't have this file...}
{I rec17b.pas}

{$I brec17a2.pas}

{rcg11172000 ...but need this...}
{$I recc.pas}

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

  modemrf17a7:file of modemrec17a7;
  modemr17a7:modemrec17a7;
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

function time:astr;
var reg:registers;
    h,m,s:string[4];
begin
  reg.ax:=$2c00; intr($21,Dos.Registers(reg));
  str(reg.cx shr 8,h); str(reg.cx mod 256,m); str(reg.dx shr 8,s);
  time:=tch(h)+':'+tch(m)+':'+tch(s);
end;

function date:astr;
var reg:registers;
    m,d,y:string[4];
begin
  reg.ax:=$2a00; msdos(Dos.Registers(reg)); str(reg.cx,y); str(reg.dx mod 256,d);
  str(reg.dx shr 8,m);
  date:=tch(m)+'/'+tch(d)+'/'+tch(y);
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
  y:=value(copy(dt,7,2))+1900;

  {rcg11182000 added this conditional. }
  if (y < 1977) then  { Ugh...this is so bad. }
    y := y + 100;

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

function substall(src,old,new:astr):astr;
var p:integer;
begin
  p:=1;
  while (p>0) do begin
    p:=pos(old,src);
    if (p>0) then begin
      insert(new,src,p+length(old));
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
      {rcg11242000 DOSism.}
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
          {rcg11242000 dosism.}
          (*{$I-} mkdir(fexpand(newpath[i]+'\'+cstr(j))); {$I+}*)
          {$I-} mkdir(fexpand(newpath[i]+'/'+cstr(j))); {$I+}
          if (ioresult<>0) then begin
            writeln;
            {rcg11242000 dosism.}
            {star('Error creating directory "'+fexpand(newpath[i]+'\'+cstr(j))+'"');}
            star('Error creating directory "'+fexpand(newpath[i]+'/'+cstr(j))+'"');
            halt(1);
          end;
        end;
      {rcg11242000 dosism.}
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
    14:begin
        ttl('Adding records to "MODEM.DAT"');
        chdir(copy(gp,1,length(gp)-1));
        ffile('modem.dat');
        if (not found) then star('MODEM.DAT not found.')
        else begin
          assign(modemrf17a7,'modem.old'); rewrite(modemrf17a7);
          close(modemrf17a7); erase(modemrf17a7);

          assign(modemrf17a7,'modem.tcp'); rewrite(modemrf17a7);
          close(modemrf17a7); erase(modemrf17a7);

          assign(modemrf,'modem.tcp'); rewrite(modemrf);
          assign(modemrf17a7,'modem.dat');
          reset(modemrf17a7); read(modemrf17a7,modemr17a7);

          with modemr17a7 do begin
            modemr.waitbaud:=waitbaud;
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
          rename(modemrf17a7,'modem.old');
          rename(modemrf,'modem.dat');

          star('Done.');
          writeln;
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
      for i:=0 to 15 do begin
        if (i>=1) and (i<=9) then c:=chr(i+48) else
          if (i=0) then c:='S' else
            if (i>=10) then c:=chr(i+55);
        if (needc(c)) then begin
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
           14:write('modem.dat');
           15:write('string.dat');
          end;
          writeln;
        end;
      end;
      writeln;
      tc(14); write('Enter # to convert, (A)ll or (Q)uit :');
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
            for i:=0 to 20 do convert(i);
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
