{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
{$M 50000,0,1000}      { Declared here suffices for all Units as well! }

uses
  crt,dos,
  myio;

{$I tagr24d.pas}
{$I rec18a.pas}

var
  a,b,lastss,mp,gp,sp:astr;
  h,i,j,k,savx,savy:integer;
  c:char;
  aw:boolean;  { author working }
  backtotag:boolean;  { CONVERTING TO TELEGARD .. }
  found:boolean;
  dirinfo:searchrec;
  ptsforisrequest,ptsfornotval:integer;
  wind:windowrec;
  didit:boolean;

  tag_uf:file of tag_userrec;
  tag_ulf:file of tag_ulrec;
  tag_ulff:file of tag_ulfrec;
  tag_bff:file of tag_messagerec;
  tag_sf:file of tag_smalrec;
  tag_bf:file of tag_boardrec;
  tag_vf:file of tag_vdatar;
  tag_u1:tag_userrec;
  tag_ub:tag_ulrec;
  tag_ulffr:tag_ulfrec;
  tag_bffr:tag_messagerec;
  tag_sr:tag_smalrec;
  tag_bb:tag_boardrec;
  tag_vv:tag_vdatar;

  uf:file of userrec;
  ulf:file of ulrec;
  ulff:file of ulfrec;
  bff:file of messagerec;
  sf:file of smalrec;
  bf:file of boardrec;
  vf:file of vdatar;
  u1:userrec;
  ub:ulrec;
  ulffr:ulfrec;
  bffr:messagerec;
  sr:smalrec;
  bb:boardrec;
  vv:vdatar;

  tagpath,tgpath,tmsgpath:astr;
  artable:astr;

  tag_systatf:file of tag_systatrec;
  tag_systat:tag_systatrec;
  systatf:file of systatrec;
  systat:systatrec;

  macrf:file of macrorec;
  macr:macrorec;

  ff:file;

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



procedure alignpathname(var s:astr);
begin
  if copy(s,length(s),1)<>'\' then s:=s+'\';
  while (copy(s,length(s)-1,2)='\\') and (length(s)>2) do
    s:=copy(s,1,length(s)-1);
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

var ther:array[1..10] of boolean;

procedure nott(i:integer; s:astr);
begin
  if (not backtotag) then begin
    star(s);
    ther[i]:=FALSE;
  end;
end;

procedure findnotther;
var i,n:integer;
begin
  n:=0;
  for i:=1 to 10 do
    if not ther[i] then inc(n);
  if n<>0 then begin
    star('File(s) not found.  Abort conversion? [Yes] : ');
    repeat c:=upcase(readkey) until c in ['Y','N',^M];
    if c<>'N' then ee('File(s) not found -- Aborted.');
  end;
end;

procedure fvers;
var i:integer;
begin
  clrscr;
  star('Checking files');

  for i:=1 to 10 do ther[i]:=TRUE;

  assign(tag_uf,tagpath+'user.lst');
  {$I-} reset(tag_uf); {$I+}
  if (ioresult<>0) then nott(1,'"'+tagpath+'user.lst": file not found.');

  assign(tag_sf,tagpath+'names.lst');
  {$I-} reset(tag_sf); {$I+}
  if (ioresult<>0) then nott(2,'"'+tagpath+'names.lst": file not found.');

  assign(tag_ulf,tagpath+'fboards.dat');
  {$I-} reset(tag_ulf); {$I+}
  if (ioresult<>0) then nott(3,'"'+tagpath+'fboards.dat": file not found.');

  assign(tag_bf,tagpath+'boards.dat');
  {$I-} reset(tag_bf); {$I+}
  if (ioresult<>0) then nott(4,'"'+tagpath+'boards.dat": file not found.');

  assign(tag_vf,tagpath+'voting.dat');
  {$I-} reset(tag_vf); {$I+}
  if (ioresult<>0) then nott(5,'"'+tagpath+'voting.dat": file not found.');

  findnotther;
end;

{rcg11172000 had to change this to get it compiling under Free Pascal...}
{function substall(src,old,new:astr):astr;}
function substall(src,old,_new:astr):astr;
var p:integer;
begin
  p:=1;
  while p>0 do begin
    p:=pos(old,src);
    if p>0 then begin
      insert(_new,src,p+length(old));
      delete(src,p,length(old));
    end;
  end;
  substall:=src;
end;

function c2(i:integer):astr;
var s:astr;
begin
  str(i,s);
  if length(s)>2 then s:=copy(s,length(s)-1,2)
    else if length(s)=1 then s:='0'+s;
  c2:=s;
end;

function spdate(y,m,d:integer):integer;
begin
  spdate:=((y-1920)*512)+(m*32)+d;
end;

function sptime(h,m,s:integer):integer;
begin
  sptime:=(h*2048)+(m*32)+(s div 2);
end;

function getspdate(i:integer):astr;
var x,y,m,d:longint;
begin
  x:=i; if x<0 then x:=x+65536;
  y:=x div 512; x:=x-512*y;
  m:=x div 32; x:=x-32*m;
  d:=x;
  getspdate:=c2(m)+'/'+c2(d)+'/'+c2(y);
end;

function getsptime(i:integer):astr;
var x,h,m,s:longint;
begin
  x:=i; if x<0 then x:=x+65536;
  h:=x div 2048; x:=x-2048*h;
  m:=x div 32; x:=x-32*m;
  s:=x div 2;
  getsptime:=c2(h)+':'+c2(m)+':'+c2(s);
end;

procedure bconvert(xx:integer);
var ttt:uflags;
    s:astr;
    siz,siz1:longint;
    i,j,k:integer;
    b:boolean;

  procedure donothing;
  begin end;

begin
  case xx of
    1:begin
        ttl('Converting "NAMES.LST" to TAG format');
        assign(sf,tgpath+'names.lst');
        reset(sf);
        rewrite(tag_sf);
        for i:=0 to filesize(sf)-1 do begin
          seek(sf,i); read(sf,sr);
          star('  (record #'+cstr(i)+' of '+cstr(filesize(sf))+')'); gotoxy(1,wherey-1);
          with sr do begin
            tag_sr.name:=name;
            tag_sr.number:=number;
          end;
          seek(tag_sf,i); write(tag_sf,tag_sr);
        end;
        close(sf);
        writeln;
      end;
    2:begin
        ttl('Converting "USER.LST" to TAG format');
        assign(uf,tgpath+'user.lst');
        reset(uf);
        rewrite(tag_uf);
        for i:=0 to filesize(uf)-1 do begin
          seek(uf,i); read(uf,u1);
          star('  (record #'+cstr(i)+' of '+cstr(filesize(uf)-1)+')'); gotoxy(1,wherey-1);
          with u1 do begin
            tag_u1.uname:=name;
            tag_u1.rname:=realname;
            tag_u1.addr:=street;
            tag_u1.comtype:=computer;
            tag_u1.citystate:=citystate;
            tag_u1.snote:=note;
            tag_u1.lastdate:=spdate(value(copy(laston,7,2)),
                                    value(copy(laston,1,2)),
                                    value(copy(laston,4,2)));
            tag_u1.lasttime:=spdate(0,0,0);
            tag_u1.pw:=pw;
            tag_u1.phone:=ph;
            tag_u1.zcode:=zipcode;

            with tag_u1.qscan[1] do begin
              ltr:='A';
              number:=-32767;
            end;
            for j:=2 to tag_maxboards do tag_u1.qscan[j]:=tag_u1.qscan[1];
            for j:=1 to 20 do tag_u1.vote[j]:=vote[j];
            for j:=1 to 15 do tag_u1.callspr[j]:=255;
            tag_u1.ttimeon:=ttimeon;
            tag_u1.ulk:=0.0; tag_u1.dlk:=0.0;
            if (uk>0) and (uk<2147483647) then tag_u1.ulk:=round(uk);
            if (dk>0) and (dk<2147483647) then tag_u1.dlk:=round(dk);
            tag_u1.usernum:=i;
            if (lockedout) then tag_u1.usernum:=i-1;
            if (deleted) then tag_u1.usernum:=0;

            tag_u1.privpost:=emailsent;
            tag_u1.pubpost:=msgpost;
            tag_u1.feedback:=feedback;
            tag_u1.numcalls:=loggedon;
            tag_u1.numul:=uploads;
            tag_u1.numdl:=downloads;
            tag_u1.fmail:=forusr;
            tag_u1.hbaud:=1200;
            tag_u1.timetoday:=0;
            tag_u1.credit:=0;
            tag_u1.debit:=0;
            tag_u1.points:=filepoints;
            tag_u1.timebank:=timebank;
            tag_u1.bday:=spdate(value(copy(bday,7,2)),
                                value(copy(bday,1,2)),
                                value(copy(bday,4,2)));

            tag_u1.strtmenu:=1;
            tag_u1.sl:=sl;
            tag_u1.dsl:=dsl;
            if (novice in ac) then tag_u1.hlvl:=3 else tag_u1.hlvl:=1;
            tag_u1.colms:=linelen;
            tag_u1.lines:=pagelen;
            tag_u1.callstoday:=ontoday;
            tag_u1.illegal:=illegal;
            tag_u1.waiting:=waiting;
            tag_u1.lmsgbase:=lastmsg;
            tag_u1.ldlbase:=lastfil;
            tag_u1.cls:=ord(^L);
            tag_u1.nulls:=0;

            for c:='A' to 'Z' do
              if (c in ar) then tag_u1.ar:=tag_u1.ar+[c];

            tag_u1.flags:=[];
            for ttt:=rlogon to fnodeletion do
              if ttt in ac then
                case ttt of
                  rlogon      :tag_u1.flags:=tag_u1.flags+[txonecall];
                  rchat       :tag_u1.flags:=tag_u1.flags+[txrchat];
                  rvalidate   :tag_u1.flags:=tag_u1.flags+[txpubnotval];
                  rbackspace  :;
                  ramsg       :tag_u1.flags:=tag_u1.flags+[txrautomsg];
                  rpostan     :tag_u1.flags:=tag_u1.flags+[txranon];
                  rpost       :tag_u1.flags:=tag_u1.flags+[txrpubmsg];
                  remail      :tag_u1.flags:=tag_u1.flags+[txrprivmsg];
                  rvoting     :tag_u1.flags:=tag_u1.flags+[txrvoting];
                  rmsg        :tag_u1.flags:=tag_u1.flags+[txautoprivdel];
                  spcsr       :;
                  onekey      :tag_u1.flags:=tag_u1.flags+[txonekey];
                  pause       :tag_u1.flags:=tag_u1.flags+[txpause];
                  ansi        :tag_u1.flags:=tag_u1.flags+[txansi];
                  color       :tag_u1.flags:=tag_u1.flags+[txcolor];
                  alert       :tag_u1.flags:=tag_u1.flags+[txalert];
                  smw         :;
                  nomail      :tag_u1.flags:=tag_u1.flags+[txmboxclosed];
                  fnodlratio  :tag_u1.flags:=tag_u1.flags+[txnodllimit];
                  fnopostratio:tag_u1.flags:=tag_u1.flags+[txnopostcall];
                  fnofilepts  :tag_u1.flags:=tag_u1.flags+[txnofilepts];
                  fnodeletion :tag_u1.flags:=tag_u1.flags+[txprotdel];
                end;
            if (sex='M') then tag_u1.flags:=tag_u1.flags+[txusermale];
            tag_u1.flags:=tag_u1.flags+[txclschar];

            for j:=1 to 4 do tag_u1.msgsysop[j]:=255;

            tag_u1.dlscan:=[]; tag_u1.msgscan:=[];
            for j:=0 to tag_maxuboards do tag_u1.dlscan:=tag_u1.dlscan+[j];
            for j:=0 to tag_maxboards do tag_u1.msgscan:=tag_u1.msgscan+[j];

            for b:=FALSE to TRUE do
              for j:=0 to 9 do
                tag_u1.colors[b][j]:=cols[b][j];
          end;
          seek(tag_uf,i); write(tag_uf,tag_u1);
        end;
        close(uf);
        writeln;
      end;
    3:begin
        ttl('Converting "BOARDS.DAT" to TAG format');
        assign(bf,tgpath+'boards.dat');
        reset(bf);
        rewrite(tag_bf);
        for i:=0 to filesize(bf)-1 do begin
          seek(bf,i); read(bf,bb);
          star('  (record #'+cstr(i)+' of '+cstr(filesize(bf)-1)+')'); gotoxy(1,wherey-1);
          with bb do begin
            tag_bb.name:=name;
            tag_bb.filename:=filename;
            tag_bb.sl:=0;
            if (maxmsgs>200) then tag_bb.maxmsgs:=200 else tag_bb.maxmsgs:=maxmsgs;
            tag_bb.pw:=password;
            if (anonymous=yes) then tag_bb.anonymous:=yesanon
            else if (anonymous=forced) then tag_bb.anonymous:=forcedanon
            else tag_bb.anonymous:=noanon;
            tag_bb.ar:='@';
            tag_bb.noansi:=FALSE;
            tag_bb.postsl:=0;
          end;
          seek(tag_bf,i); write(tag_bf,tag_bb);

          with bb do
            assign(bff,tgpath+filename+'.BRD');

          {$I-} reset(bff); {$I+}
          if (ioresult=0) then begin
            seek(bff,0); read(bff,bffr);
            siz:=bffr.message.number;
            if (siz>filesize(bff)-1) then siz:=filesize(bff)-1;
            assign(tag_bff,tagpath+tag_bb.filename+'.BRD');
            clreol;
            star('  (record #'+cstr(i)+' of '+cstr(filesize(bf)-1)+
                 ') -- "'+bb.filename+'.BRD"');
            rewrite(tag_bff); write(tag_bff,tag_bffr);
            if (siz>200) then siz1:=siz-199 else siz1:=1;
            for j:=siz1 to siz do begin
              seek(bff,j); read(bff,bffr);
              star('    (record #'+cstr(j)+' of '+cstr(siz)+')');
              gotoxy(1,wherey-1);
              with bffr do begin
                tag_bffr.title:=title;
                if (validated in messagestat) then
                  tag_bffr.messagestat:=tag_validated
                else
                if (unvalidated in messagestat) then
                  tag_bffr.messagestat:=tag_unvalidated
                else
                if (deleted in messagestat) then
                  tag_bffr.messagestat:=tag_deleted;
                tag_bffr.message.ltr:=message.ltr;
                tag_bffr.message.number:=message.number;
                tag_bffr.message.ext:=message.ext;
                tag_bffr.owner:=owner;
                tag_bffr.date:=bffr.date;
                tag_bffr.mage:=255;
              end;
              {seek(tag_bff,j);} write(tag_bff,tag_bffr);
            end;
            clreol; gotoxy(1,wherey-1);
            close(bff);
            close(tag_bff);
          end;
        end;
        close(bf);
        writeln;
      end;
    8:begin
        ttl('Converting "UPLOADS.DAT" to TAG format ("FBOARDS.DAT")');
        assign(ulf,tgpath+'uploads.dat');
        reset(ulf);
        rewrite(tag_ulf);
        for i:=0 to filesize(ulf)-1 do begin
          seek(ulf,i); read(ulf,ub);
          star('  (record #'+cstr(i)+' of '+cstr(filesize(ulf)-1)+')');
          gotoxy(1,wherey-1);
          with ub do begin
            tag_ub.name:=name;
            tag_ub.filename:=filename;
            tag_ub.dlpath:=dlpath;
            tag_ub.ulpath:=ulpath;
            tag_ub.password:=password;
            tag_ub.dsl:=0;
            tag_ub.namedsl:=255;
            tag_ub.ar:='@';
            tag_ub.noratio:=(fbnoratio in fbstat);
          end;
          seek(tag_ulf,i); write(tag_ulf,tag_ub);

          with ub do
            assign(ulff,tgpath+filename+'.DIR');

          {$I-} reset(ulff); {$I+}
          if (ioresult=0) then begin
            seek(ulff,0); read(ulff,ulffr);
            siz:=ulffr.blocks;
            if (siz>filesize(ulff)-1) then siz:=filesize(ulff)-1;
            assign(tag_ulff,tag_ub.dlpath+tag_ub.filename+'.DIR');
            clreol;
            star('  (record #'+cstr(i)+' of '+cstr(filesize(ulf)-1)+
                 ') -- "'+ub.filename+'.dir"');
            rewrite(tag_ulff); write(tag_ulff,tag_ulffr);
            for j:=1 to siz do begin
              seek(ulff,j); read(ulff,ulffr);
              star('    (record #'+cstr(j)+' of '+cstr(siz)+')');
              gotoxy(1,wherey-1);
              with ulffr do begin
                tag_ulffr.filename:=filename;
                tag_ulffr.description:=description;
                tag_ulffr.nacc:=nacc;
                tag_ulffr.ft:=ft;
                tag_ulffr.blocks:=blocks;
                tag_ulffr.owner:=stowner;
                tag_ulffr.date:=date;
                tag_ulffr.daten:=daten;
                tag_ulffr.unval:=(notval in filestat);
                tag_ulffr.filepoints:=filepoints;
              end;
              seek(tag_ulff,j); write(tag_ulff,tag_ulffr);
            end;
            clreol; gotoxy(1,wherey-1);
            close(ulff);
            close(tag_ulff);
          end;
        end;
        close(ulf);
        writeln;
      end;
    9:begin
        ttl('Converting "VOTING.DAT" to TAG format.');
        assign(vf,tgpath+'voting.dat');
        reset(vf);
        rewrite(tag_vf);
        for i:=0 to filesize(vf)-1 do begin
          seek(vf,i); read(vf,vv);
          star('  (record #'+cstr(i+1)+' of '+cstr(filesize(vf))+')');
          gotoxy(1,wherey-1);
          with vv do begin
            tag_vv.question:=question;
            tag_vv.numa:=numa;
            for j:=0 to 9 do begin
              tag_vv.answ[j].ans:=answ[j].ans;
              tag_vv.answ[j].numres:=answ[j].numres;
            end;
          end;
          seek(tag_vf,i); write(tag_vf,tag_vv);
        end;
        close(vf);
        writeln;
      end;
  end;
end;

procedure fconvert(xx:integer);
const dcols:clrs=((15,7,7,15,15,15,112,7,143,7),(15,3,1,11,9,14,31,4,140,10));
var i,j,k:integer;
    b:boolean;
    s,s1,s2,s3,s4,s5:astr;
    c:char;
    mf,mf1:text;
    sepmsgs,nocopy:boolean;
    f:file;
    mary:array[0..200] of messagerec;
    curdir:astr;
    newpath:array[1..3] of astr;
    ttt:tag_flagrec;
    tt:tag_acrq;
    siz:longint;
begin
  case xx of
    1:begin
        ttl('Converting "NAMES.LST" to Telegard format');
        assign(sf,tgpath+'names.lst');
        rewrite(sf);
        for i:=0 to filesize(tag_sf)-1 do begin
          seek(tag_sf,i); read(tag_sf,tag_sr);
          star('  (record #'+cstr(i+1)+' of '+cstr(filesize(tag_sf))+')'); gotoxy(1,wherey-1);
          with tag_sr do begin
            sr.name:=name;
            sr.number:=number;
          end;
          seek(sf,i); write(sf,sr);
        end;
        close(sf);
        writeln;
      end;
    2:begin
        ttl('Converting "USER.LST" to Telegard format');
        assign(uf,tgpath+'user.lst');
        rewrite(uf);
        for i:=0 to filesize(tag_uf)-1 do begin
          seek(tag_uf,i); read(tag_uf,tag_u1);
          star('  (record #'+cstr(i)+' of '+cstr(filesize(tag_uf)-1)+')'); gotoxy(1,wherey-1);
          with tag_u1 do begin
            u1.name:=uname;
            u1.realname:=rname;
            u1.pw:=pw;
            u1.ph:=phone;
            u1.bday:=getspdate(bday);
            u1.firston:=getspdate(lastdate);
            u1.laston:=getspdate(lastdate);
            u1.street:=addr;
            u1.citystate:=citystate;
            u1.zipcode:=zcode;
            u1.computer:=comtype;
            u1.occupation:='';
            u1.wherebbs:='';
            u1.note:=snote;
            u1.lockedout:=(usernum<>i);
            u1.deleted:=(usernum=0);
            u1.lockedfile:='LOCKOUT';
            u1.ac:=[];

            u1.sex:='F';
            for ttt:=txautoprivdel to txclschar do
              if (ttt in flags) then
                case ttt of
                  txautoprivdel:u1.ac:=u1.ac+[rmsg];
                  txnopostcall :u1.ac:=u1.ac+[fnopostratio];
                  txrautomsg   :u1.ac:=u1.ac+[ramsg];
                  txranon      :u1.ac:=u1.ac+[rpostan];
                  txrchat      :u1.ac:=u1.ac+[rchat];
                  txnodllimit  :u1.ac:=u1.ac+[fnodlratio];
                  txrpubmsg    :u1.ac:=u1.ac+[rpost];
                  txrprivmsg   :u1.ac:=u1.ac+[remail];
                  txrvoting    :u1.ac:=u1.ac+[rvoting];
                  txonecall    :u1.ac:=u1.ac+[rlogon];
                  txpubnotval  :u1.ac:=u1.ac+[rvalidate];
                  txprotdel    :u1.ac:=u1.ac+[fnodeletion];
                  txnofilepts  :u1.ac:=u1.ac+[fnofilepts];
                  txpause      :u1.ac:=u1.ac+[pause];
                  txansi       :u1.ac:=u1.ac+[ansi];
                  txcolor      :u1.ac:=u1.ac+[color];
                  txonekey     :u1.ac:=u1.ac+[onekey];
                  txalert      :u1.ac:=u1.ac+[alert];
                  txusermale   :u1.sex:='M';
                  txmboxclosed :u1.ac:=u1.ac+[nomail];
                end;
            if (hlvl>2) then u1.ac:=u1.ac+[novice];

            u1.ar:=[];
            for c:='A' to 'Z' do
              if (c in ar) then u1.ar:=u1.ar+[c];

            with u1.qscan[1] do begin
              ltr:='A';
              number:=-32767;
              ext:=1;
            end;
            for j:=2 to maxboards do u1.qscan[j]:=u1.qscan[1];

            for j:=1 to maxboards do u1.qscn[j]:=TRUE;

            u1.dlnscn:=[];
            for j:=0 to maxuboards do u1.dlnscn:=u1.dlnscn+[j];

            for j:=1 to 20 do u1.vote[j]:=vote[j];

            u1.ttimeon:=trunc(ttimeon);
            if (ulk>0) and (ulk<2147483647) then u1.uk:=round(ulk) else u1.uk:=0;
            if (dlk>0) and (dlk<2147483647) then u1.dk:=round(dlk) else u1.dk:=0;
            u1.uploads:=numul;
            u1.downloads:=numdl;
            u1.loggedon:=numcalls;
            u1.tltoday:=120;
            u1.msgpost:=pubpost;
            u1.emailsent:=privpost;
            u1.feedback:=feedback;
            u1.forusr:=fmail;
            u1.filepoints:=points;

            u1.waiting:=waiting;
            u1.linelen:=colms;
            u1.pagelen:=lines;
            u1.ontoday:=callstoday;
            u1.illegal:=illegal;
            u1.sl:=sl;
            u1.dsl:=dsl;
            for b:=FALSE to TRUE do
              for j:=0 to 9 do u1.cols[b][j]:=colors[b][j];
            u1.lastmsg:=lmsgbase;
            u1.lastfil:=ldlbase;
            u1.credit:=trunc(credit);
            u1.timebank:=timebank;
            for j:=1 to 5 do u1.boardsysop[j]:=255;
            u1.trapactivity:=FALSE;
            u1.trapseperate:=FALSE;
            u1.timebankadd:=0;
            u1.mpointer:=-1;
            u1.chatauto:=FALSE;
            u1.chatseperate:=FALSE;
            u1.userstartmenu:='';
            u1.slogseperate:=FALSE;
            u1.clsmsg:=0;

            for j:=1 to 57 do u1.res[j]:=0;
          end;
          seek(uf,i); write(uf,u1);
        end;
        close(uf);
        writeln;
      end;
    3:begin
        ttl('Converting "BOARDS.DAT" to Telegard format');
        assign(bf,tgpath+'boards.dat');
        rewrite(bf);
        for i:=0 to filesize(tag_bf)-1 do begin
          seek(tag_bf,i); read(tag_bf,tag_bb);
          star('  (record #'+cstr(i)+' of '+cstr(filesize(tag_bf)-1)+')'); gotoxy(1,wherey-1);
          with tag_bb do begin
            bb.name:=name;
            bb.filename:=filename;
            bb.msgpath:=systat.pmsgpath;
            bb.acs:='';
            if (sl>0) then bb.acs:=bb.acs+'s'+cstr(sl);
            if (ar in ['A'..'Z']) then bb.acs:=bb.acs+'f'+ar;
            bb.postacs:='';
            if (postsl>0) then bb.postacs:=bb.postacs+'s'+cstr(postsl);
            bb.mciacs:='%';
            bb.maxmsgs:=maxmsgs;
            if (anonymous=noanon) then bb.anonymous:=no
            else
            if (anonymous=yesanon) then bb.anonymous:=yes
            else
            if (anonymous=forcedanon) then bb.anonymous:=forced;
            bb.password:=pw;
            bb.mbstat:=[];
            bb.permindx:=i;
            bb.mbdepth:=0;
          end;
          seek(bf,i); write(bf,bb);
          with tag_bb do
            assign(tag_bff,tagpath+filename+'.BRD');

          {$I-} reset(tag_bff); {$I+}
          if (ioresult=0) then begin
            siz:=filesize(tag_bff)-1;
            assign(bff,tgpath+tag_bb.filename+'.BRD');
            star('  (record #'+cstr(i)+' of '+cstr(filesize(tag_bf)-1)+
                 ') -- "'+tag_bb.filename+'.dir"'); gotoxy(1,wherey-1);
            writeln;
            rewrite(bff);
            bffr.message.number:=siz;
            seek(bff,0); write(bff,bffr);
            for j:=1 to siz do begin
              seek(tag_bff,j); read(tag_bff,tag_bffr);
              star('    (record #'+cstr(j)+' of '+cstr(siz)+')');
              gotoxy(1,wherey-1);
              with tag_bffr do begin
                bffr.title:=title;
                bffr.messagestat:=[];
                if (messagestat=tag_validated) then
                  bffr.messagestat:=bffr.messagestat+[validated]
                else
                if (messagestat=tag_unvalidated) then
                  bffr.messagestat:=bffr.messagestat+[unvalidated]
                else
                if (messagestat=tag_deleted) then
                  bffr.messagestat:=bffr.messagestat+[deleted];
                bffr.message.ltr:=message.ltr;
                bffr.message.number:=message.number;
                bffr.message.ext:=message.ext;
                bffr.owner:=owner;
                bffr.date:=tag_bffr.date;
                bffr.nacc:=0;
              end;
              seek(bff,j); write(bff,bffr);
            end;
            clreol; gotoxy(1,wherey-1);
            close(bff);
            close(tag_bff);
          end;
        end;
        close(bf);
        writeln;
      end;
    8:begin
        ttl('Converting "FBOARDS.DAT" to Telegard format ("UPLOADS.DAT")');
        assign(ulf,tgpath+'uploads.dat');
        rewrite(ulf);
        for i:=0 to filesize(tag_ulf)-1 do begin
          seek(tag_ulf,i); read(tag_ulf,tag_ub);
          star('  (record #'+cstr(i)+' of '+cstr(filesize(tag_ulf)-1)+')'); gotoxy(1,wherey-1);
          with tag_ub do begin
            ub.name:=name;
            ub.filename:=filename;
            ub.dlpath:=dlpath;
            ub.ulpath:=ulpath;
            ub.maxfiles:=2000;
            ub.password:=password;
            ub.arctype:=1;
            ub.cmttype:=1;
            ub.fbdepth:=0;
            ub.fbstat:=[];
            if (noratio) then ub.fbstat:=ub.fbstat+[fbnoratio];
            ub.acs:='';
            if (dsl>0) then ub.acs:=ub.acs+'d'+cstr(dsl);
            if (ar in ['A'..'Z']) then ub.acs:=ub.acs+'f'+ar;
            ub.ulacs:='';
            ub.nameacs:='';
            if (namedsl>0) then ub.acs:=ub.acs+'d'+cstr(namedsl);
            ub.permindx:=i;
            for j:=1 to 6 do ub.res[j]:=0;
          end;
          seek(ulf,i); write(ulf,ub);
          with tag_ub do
            assign(tag_ulff,dlpath+filename+'.DIR');

          {$I-} reset(tag_ulff); {$I+}
          if (ioresult=0) then begin
            siz:=filesize(tag_ulff)-1;
            assign(ulff,tgpath+tag_ub.filename+'.DIR');
            star('  (record #'+cstr(i)+' of '+cstr(filesize(tag_ulf)-1)+
                 ') -- "'+tag_ub.filename+'.dir"'); gotoxy(1,wherey-1);
            writeln;
            rewrite(ulff);
            ulffr.blocks:=siz;
            seek(ulff,0); write(ulff,ulffr);
            for j:=1 to siz do begin
              seek(tag_ulff,j); read(tag_ulff,tag_ulffr);
              star('    (record #'+cstr(j)+' of '+cstr(siz)+')');
              gotoxy(1,wherey-1);
              with tag_ulffr do begin
                ulffr.filename:=filename;
                ulffr.description:=description;
                ulffr.filepoints:=filepoints;
                ulffr.nacc:=nacc;
                ulffr.ft:=ft;
                ulffr.blocks:=blocks;
                ulffr.owner:=1;
                ulffr.stowner:=owner;
                ulffr.date:=date;
                ulffr.daten:=daten;
                ulffr.vpointer:=-1;
                ulffr.filestat:=[];
                if (unval) then ulffr.filestat:=ulffr.filestat+[notval];
              end;
              seek(ulff,j); write(ulff,ulffr);
            end;
            clreol; gotoxy(1,wherey-1);
            close(ulff);
            close(tag_ulff);
          end;
        end;
        close(ulf);
        writeln;
      end;
    9:begin
        ttl('Converting "VOTING.DAT" to Telegard format.');
        assign(vf,tgpath+'voting.dat');
        rewrite(vf);
        for i:=0 to filesize(tag_vf)-1 do begin
          seek(tag_vf,i); read(tag_vf,tag_vv);
          star('  (record #'+cstr(i+1)+' of '+cstr(filesize(tag_vf))+')');
          gotoxy(1,wherey-1);
          with tag_vv do begin
            vv.question:=question;
            vv.numa:=numa;
            for j:=0 to 9 do begin
              vv.answ[j].ans:=answ[j].ans;
              vv.answ[j].numres:=answ[j].numres;
            end;
          end;
          seek(vf,i); write(vf,vv);
        end;
        close(vf);
        writeln;
      end;
  end;
end;

procedure convert(xx:integer);
var i,j,k:integer;
    s:astr;
begin
  if (backtotag) then bconvert(xx) else fconvert(xx);
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
  write(' Conversion for TAG '+tag_ver+' ®®®®®-¯¯¯¯¯ Telegard '+s_ver);
  textbackground(0);
  window(1,2,80,25); clrscr;
  tc(14);
  writeln;
  writeln('This program is provided to convert data files used by');
  writeln('TAG '+tag_ver+' to the proper formats used by Telegard '+s_ver+'.');
  writeln('It may ALSO be used to convert from Telegard format to TAG.');
  writeln;
  writeln('   TAG '+tag_ver+'                Telegard '+s_ver);
  writeln('   ÄÄÄÄÄÄÄÄÄÄÄÄÄÄ          ÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
  writeln('    USER    .LST   ®®-¯¯  USER    .LST');
  writeln('    NAMES   .LST   ®®-¯¯  NAMES   .LST');
  writeln('    FBOARDS .DAT   ®®-¯¯  UPLOADS .DAT');
  writeln('    ????????.DIR   ®®-¯¯  ????????.DIR');
  writeln(' *  EMAIL   .DAT   ®®-¯¯  EMAIL   .DAT');
  writeln(' *  SHORTMSG.DAT   ®®-¯¯  SHORTMSG.DAT');
  writeln('    BOARDS  .DAT   ®®-¯¯  BOARDS  .DAT');
  writeln('    ????????.BRD   ®®-¯¯  ????????.BRD');
  writeln('    VOTING  .DAT   ®®-¯¯  VOTING  .DAT');
  writeln('   ÄÄÄÄÄÄÄÄÄÄÄÄÄÄ          ÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
  writeln(' * means files require NO conversion and are');
  writeln('   already in the correct Telegard '+s_ver+' format.');
  writeln;
  textcolor(14); write('Hit <CR> to continue, any other key to abort now : ');
  repeat until keypressed;
  c:=readkey;
  if (c<>^M) then ee('ABORTED CONVERSION');

  repeat
    clrscr;
    writeln;
    textcolor(14);
    writeln('Will you be converting ...');
    writeln;
    writeln('1. From TAG to Telegard format');
    writeln('2. From Telegard to TAG format');
    writeln('Q. Abort');
    writeln;
    textcolor(9); write('Select : ');
    repeat c:=upcase(readkey) until (c in ['1','2','Q']);
    if (c='Q') then ee('ABORTED CONVERSION');
    backtotag:=(c='2');
    writeln(c);
    writeln;
    writeln;

    if (not backtotag) then begin
      writeln;
      textcolor(15); writeln('Enter your TAG GFILES pathname.');
      textcolor(14);
      writeln('USER.LST, NAMES.LST, FBOARDS.DAT, BOARDS.DAT, and other');
      writeln('such files are here, and will be used to create the Telegard');
      writeln('equivalents in your Telegard paths.');
      writeln;
      textcolor(9); write('TAG Path: '); infield(tagpath,40);
      if (tagpath='') then ee('ABORTED');
      alignpathname(tagpath); clreol; writeln(tagpath);
      writeln;
      writeln;
      textcolor(15); writeln('Enter your Telegard MAIN BBS pathname.');
      textcolor(14);
      writeln('The data file STATUS.DAT should exist in this directory.');
      writeln('The GFILES path will be located by searching STATUS.DAT.');
      writeln('This step is involved to ensure you have a version of Telegard');
      writeln('ALREADY set up; it is an essential part of the conversion.');
      writeln;
      textcolor(9); write('Telegard Path: '); infield(tgpath,40);
      if (tgpath='') then ee('ABORTED');
      alignpathname(tgpath); clreol; writeln(tgpath);
    end else begin
      writeln;
      textcolor(15); writeln('Enter your Telegard MAIN BBS pathname.');
      textcolor(14);
      writeln('The Telegard file STATUS.DAT should exist in this directory.');
      writeln('Other files will be located by searching STATUS.DAT.');
      writeln;
      textcolor(9); write('Telegard Path: '); infield(tgpath,40);
      if (tgpath='') then ee('ABORTED');
      alignpathname(tgpath); clreol; writeln(tgpath);
      writeln;
      writeln;
      textcolor(15); writeln('Enter your TAG GFILES pathname.');
      textcolor(14);
      writeln('The converted TAG data files will be created in this directory.');
      writeln('If they already exist, they will be overwritten.');
      writeln;
      textcolor(9); write('TAG Path: '); infield(tagpath,40);
      if (tagpath='') then ee('ABORTED');
      alignpathname(tagpath); clreol; writeln(tagpath);
    end;
    clrscr;
    writeln;
    textcolor(9); write('Converting:    ');
    textcolor(14);
    if (backtotag) then writeln('TO TAG FORMAT')
      else writeln('TO TELEGARD FORMAT');
    textcolor(9); write('TAG Path:      '); textcolor(15); writeln(tagpath);
    textcolor(9); write('Telegard Path: '); textcolor(15); writeln(tgpath);
    writeln;
    writeln;
  until l_pynq('Is this OK? ');

  if (not backtotag) then begin
    writeln;
    textcolor(14);
    writeln('Now you need to enter your Telegard MSGS directory, where you');
    writeln('will later be putting all of your message files in.');
    writeln;
    writeln('This is probably "'+tgpath+'MSGS\" ...');
    writeln;
    textcolor(9); write('Telegard MSGS Path: '); infield(tmsgpath,40);
    if (tmsgpath='') then ee('ABORTED');
    alignpathname(tmsgpath); clreol; writeln(tmsgpath);
  end;

  assign(systatf,tgpath+'status.dat'); reset(systatf); read(systatf,systat);
  systat.pmsgpath:=tmsgpath;
  rewrite(systatf); write(systatf,systat); close(systatf);
  tgpath:=systat.gfilepath;

  repeat
    clrscr;
    fvers;

    clrscr;
    writeln;
(*
    if aw then begin
      for i:=0 to 13 do begin
        if (i>=1) and (i<=9) then c:=chr(i+48) else
          if (i=0) then c:='S' else
            if (i>=10) then c:=chr(i+55);
        tc(9); write('['+cstr(i)+'] ');
        if (i<10) then write(' ');
        tc(11);
        case i of
          0:write('(S)tatus.dat');
          1:write('names.lst');
          2:write('user.lst');
          3:write('boards.dat');
{          4:write('email.dat');}
{          5:write('gfiles.dat');}
{          6:write('protocol.dat');}
{          7:write('shortmsg.dat');}
          8:write('uploads.dat');
          9:write('voting.dat');
{         10:write('zlog.dat');}
         11:write('*.dir');
{         12:write('*.brd');}
{         13:write(mp+'*.mnu');}
        end;
        writeln;
      end;
      writeln;
      tc(14); write('Enter # to convert, [A]ll or [Q]uit :');
      tc(9); readln(a); a:=allcaps(a);

      j:=value(a);
    end
    else a:='A';
*)
    a:='A';

    if (j=0) then
      if (copy(a,1,1)='S') then j:=0 else j:=-1;

    if (copy(a,1,1)<>'Q') or ((j>=0) and (j<=13)) then begin
      clrscr; tc(15);
      if (backtotag) then
        writeln('Convert Telegard '+s_ver+' ¯¯¯¯¯¯¯¯¯ TAG '+tag_ver)
      else
        writeln('Convert TAG '+tag_ver+' ¯¯¯¯¯¯¯¯¯ Telegard '+s_ver);
      writeln;
      tc(4); write('WARNING: ');
      tc(12);
      if (backtotag) then
        writeln('If Telegard data files are not in version '+s_ver+' format,')
        else
        writeln('If TAG data files are NOT in version '+tag_ver+' format,');
      writeln('the data will be COMPLETELY LOST *FOREVER*!!');
      writeln;
      writeln;
      tc(14); writeln('ARE YOU ABSOLUTELY SURE?');
      writeln('(Enter "YES" in ALL CAPS, without quotes, if you are...)');
      write(':');
      readln(b);

      if (b='YES') then begin
        clrscr;
        for i:=0 to 13 do convert(i);
        didit:=TRUE;
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
    if (not backtotag) then write('Thank you for choosing Telegard!')
                       else write('Well, thanks for TRYING Telegard!');
    CursorOff; delay(1500); CursorOn;
    removewindow(wind);
  end;
  gotoxy(savx,savy);
  chdir(sp);
end.
