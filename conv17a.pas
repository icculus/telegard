{$B+}                   { Boolean complete evaluation on }
{$F+}                   { Far calls on }
{$I+}                   { I/O checking off }
{$N-}                   { No numeric coprocessor }
{$R-}                   { Range checking off }
{$S+}                   { Stack checking off }
{$V-}                   { Var-checking off }

{$M 50000,0,90000}      { Declared here suffices for all Units as well! }

uses
  crt,dos,
  myio;

const
  needconv = 'S';

{rcg11172000 hmm...don't have this file...}
{I rcc16e2.pas}

{$I rec17a.pas}
{$I rcc17a.pas}

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

  systatf1:file of systatrec1;
  systat1:systatrec1;
  systatf0:file of systatrec;
  systat0:systatrec;
  systatf:file of systatrec;
  systat:systatrec;

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
  bf:file of boardrec;
  brd:boardrec;

  mailfile1:file of mailrec1;
  mail1:mailrec1;              {**}
  mailfile:file of mailrec;
  mail:mailrec;                {**}

  ulf1:file of ulrec1;
  ubrd1:ulrec1;
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
  gfilef:file of gft;     {**}
  gfile:gft;              {**}

  smf1:file of smr1;
  sm1:smr1;
  smf:file of smr;
  sm:smr;

  ztf1:file of zlogt1;    {**}
  zt1:zlogt1;             {**}
  ztf:file of zlogt;      {**}
  zt:zlogt;               {**}

  vdf1:file of vdatar1;   {**}
  vd1:vdatar1;            {**}
  vdf:file of vdatar;     {**}
  vd:vdatar;              {**}

  macrf:file of macrorec;
  macr:macrorec;

  xp1:file of expro1;
  xp:file of expro;
  xpr1:expro1;
  xpr:expro;

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
  y:=value(copy(dt,7,2))+1900;
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
  s:=fexpand(s);
  exdrv:=ord(s[1])-64;
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
  assign(systatf0,'status.dat');
  {$I-} reset(systatf0); {$I+}
  if (ioresult<>0) then cantopen;
  {$I-} read(systatf0,systat0); {$I+}
  if (ioresult<>0) then begin
    close(systatf0);
    assign(systatf,'status.dat');
    reset(systatf);
    {$I-} read(systatf,systat); {$I+}
    gp:=systat.gfilepath;
    mp:=systat.menupath;
    close(systatf);
  end else begin
    gp:=systat0.gfilepath;
    mp:=systat0.menupath;
    close(systatf0);
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
    inc(needs,sizeof(gft)*filesize(gfilef1));
    close(gfilef1);
  end;

  if needc('6') then begin
    ss('protocol.dat');
    assign(xp1,gp+'protocol.dat');
    {$I-} reset(xp1); {$I+}
    if (ioresult<>0) then cantopen;
    inc(needs,sizeof(expro)*filesize(xp1));
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
    inc(needs,sizeof(zlogt)*filesize(ztf1));
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
end;

procedure fconvert(xx:integer);
const dcols:clrs=((15,7,7,15,15,15,112,7,143,7),(15,3,1,11,9,14,31,4,140,10));
var i,j,k:integer;
    b:boolean;
    s,s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15:astr;
    c:char;
    mf,mf1:text;
    sepmsgs,nocopy:boolean;
    f:file;
    mary:array[0..200] of messagerec;
    curdir:astr;
    newpath:array[1..3] of astr;

  procedure make_paths;
  var s:string;
      i,j:integer;
  begin
    for i:=1 to 3 do begin
      while copy(newpath[i],length(newpath[i]),1)='\' do
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
          {$I-} mkdir(fexpand(newpath[i]+'\'+cstr(j))); {$I+}
          if (ioresult<>0) then begin
            writeln;
            star('Error creating directory "'+fexpand(newpath[i]+'\'+cstr(j))+'"');
            halt(1);
          end;
        end;
      newpath[i]:=newpath[i]+'\';
    end;
  end;

begin
  case xx of
    0:begin
        ttl('PATCHING "STATUS.DAT" - No conversion necessary');
        ffile('status.dat');
        if not found then star('STATUS.DAT not found.')
        else begin
          assign(systatf0,'status.old');
          rewrite(systatf0);
          close(systatf0);
          erase(systatf0);
          assign(systatf0,'status.dat');
          rename(systatf0,'status.old');
          reset(systatf0);
          assign(systatf,'status.dat');
          rewrite(systatf);
          seek(systatf0,0); read(systatf0,systat0);
          systat:=systat0;
          with systat do begin
            hangup:='~~~'^A^A^A'~~~ATH0'^M;
            offhook:='ATH1M0'^M;
            answer:=answer+^M;
            if (length(init)=40) then init:=copy(init,1,39);
            init:=init+^M;

            for i:=1 to 140 do res[i]:=0;
          end;
          seek(systatf,0); write(systatf,systat);
          close(systatf);
          close(systatf0);
        end;
      end;
(*
    2:begin
        ttl('PATCHING "USER.LST" - No conversion necessary');
        chdir(copy(gp,1,length(gp)-1));
        ffile('user.lst');
        if not found then star('USER.LST not found.')
        else begin
          assign(uf0,'user.old');
          rewrite(uf0);
          close(uf0);
          erase(uf0);
          assign(uf0,'user.lst');
          rename(uf0,'user.old');
          reset(uf0);
          assign(uf1,'user.old');
          reset(uf1);
          assign(uf,'user.lst');
          rewrite(uf);
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
   10:begin
        ttl('Converting "ZLOG.DAT');
        chdir(copy(gp,1,length(gp)-1));
        ffile('zlog.dat');
        if (not found) then star('ZLOG.DAT not found.')
        else begin
          assign(ztf1,'zlog.old');
          rewrite(ztf1);
          close(ztf1);
          erase(ztf1);
          assign(ztf1,'zlog.dat');
          rename(ztf1,'zlog.old');
          reset(ztf1);
          assign(ztf,'zlog.dat');
          rewrite(ztf);
          for i:=0 to filesize(ztf1)-1 do begin
            seek(ztf1,i); read(ztf1,zt1);
            star('  (record #'+cstr(i)+' of '+cstr(filesize(ztf1)-1)+')'); gotoxy(1,wherey-1);

            with zt do begin
              date:=zt1.date;
              for j:=0 to 4 do userbaud[j]:=0;
              active:=zt1.active;
              calls:=zt1.calls;
              newusers:=0;
              pubpost:=zt1.post;
              privpost:=zt1.email;
              fback:=zt1.fback;
              criterr:=0;
              uploads:=zt1.up;
              downloads:=0;
              uk:=0;
              dk:=0;
            end;

            seek(ztf,i); write(ztf,zt);
          end;
          close(ztf1);
          close(ztf);
          writeln;
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
            s:=dirinfo.name;
            assign(mf1,copy(s,1,length(s)-3)+'OLD');
            rewrite(mf1);
            close(mf1);
            erase(mf1);
            assign(mf1,s);
            {$I-} rename(mf1,copy(s,1,length(s)-3)+'OLD'); {$I+}
            if (ioresult<>0) then star('Error renaming "'+s+'" -  Nothing done.')
            else begin
              assign(mf1,copy(s,1,length(s)-3)+'OLD');
              {$I-} reset(mf1); {$I+}
              assign(mf,s);
              {$I-} rewrite(mf); {$I+}
              star('Converting "'+s+'"');

              readln(mf1,s1);
              readln(mf1,s2);

              s3:='T';            {* DEFAULT: auto-time display *}
              if (copy(s2,1,1)='*') or (copy(s2,1,1)='!') or (copy(s2,1,1)='#') then begin
                c:=s2[1];
                case c of
                  '*':s3:='';
                  '!':s3:='H';    {* auto-help display *}
                  '#':s3:='HT';   {* auto-help and time display *}
                end;
                s2:=copy(s2,2,length(s2)-1);
              end;

              writeln(mf,'');
              writeln(mf,s1); writeln(mf,'');
              writeln(mf,s2);
              writeln(mf,'0'); writeln(mf,'@'); writeln(mf,'');
              writeln(mf,'MAIN'); writeln(mf,'4');
              writeln(mf,'1'); writeln(mf,'3'); writeln(mf,'1');
              writeln(mf,s3);

              repeat
                nocopy:=FALSE;

                readln(mf1,s1);    {* command letters     *}
                readln(mf1,s2);    {* SL requirement      *}
                readln(mf1,s3);    {* Cmdkeys             *}
                readln(mf1,s4);    {* MString             *}
                readln(mf1,s5);    {* AR level            *}

                if (not nocopy) then begin
                  writeln(mf,'');  {* long description    *}
                  writeln(mf,'');  {* short description   *}
                  writeln(mf,s1);  {* command letters     *}
                  writeln(mf,s2);  {* security requirement *}
                  writeln(mf,s5);  {* AR flag requirement *}
                  writeln(mf,s3);  {* Cmdkeys             *}
                  writeln(mf,s4);  {* MString             *}
                  writeln(mf,'');  {* command flags       *}
                end;

              until (eof(mf1));

              close(mf);
              close(mf1);
              rename(mf,copy(s,1,length(s)-3)+'TCP');
            end;
            nfile;
          until not found;
          ffile('*.TCP');
          repeat
            s:=dirinfo.name;
            assign(mf,s);
            rename(mf,copy(s,1,length(s)-3)+'MNU');
            nfile;
          until not found;
        end;
        chdir(sp);
      end;
*)
  end;
end;

procedure convert(xx:integer);
var i,j,k:integer;
    s:astr;
begin
  if back then bconvert(xx) else fconvert(xx);
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
  write('Telegard Conversion for '+ver1+' ¯¯¯¯¯¯¯¯¯ '+ver);
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
    end
    else a:='A';

    if (j=0) then
      if (copy(a,1,1)='S') then j:=0 else j:=-1;

    if (copy(a,1,1)<>'Q') or
       ((j>=0) and (j<=13)) then begin
      writeln;
      if aw then begin
        tc(14); write('[1]Convert to '+ver+' - [2]Convert back to '+ver1+' : ');
        tc(9); readln(b); b:=allcaps(b);
        h:=value(b);
      end else h:=1;

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
    if not aw then a:='Q';
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
