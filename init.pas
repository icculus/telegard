(*****************************************************************************)
(*>                                                                         <*)
(*>  Telegard Bulletin Board System - Copyright 1988,89,90 by               <*)
(*>  Eric Oman, Martin Pollard, and Todd Bolitho - All rights reserved.     <*)
(*>                                                                         <*)
(*>  Program name:      INIT.PAS                                            <*)
(*>  Program purpose:   Initialization program for new systems              <*)
(*>                                                                         <*)
(*****************************************************************************)
program init;

{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
{$M 50000,0,1024}       { Declared here suffices for all Units as well! }

uses
  crt, dos,
  myio, timejunk;

{$I rec25.pas}

var
  systatf:file of systatrec;
  systat:systatrec;
  modemf:file of modemrec;
  modemr:modemrec;
  fstringf:file of fstringrec;
  fstring:fstringrec;
  uf:file of userrec;
  u:userrec;
  sf:file of smalrec;
  sr:smalrec;
  bf:file of boardrec;
  br:boardrec;
  uff:file of ulrec;
  ufr:ulrec;
  xp:file of protrec;
  xpr:protrec;
  zf:file of zlogrec;
  zfr:zlogrec;
  brdf:file;
  mixf:file;
  tref:file;
(*  mailfile:file of mailrec;
  mr:mailrec;*)
  lcallf:file of lcallers;
  lcall:lcallers;
  tfilf:file of tfilerec;
  tfil:tfilerec;
  verbf:file of verbrec;
  vr:verbrec;
  vdata:file of vdatar;
  vd:vdatar;
  smf:file of smr;
  sm:smr;
  ulff:file of ulfrec;
  ulffr:ulfrec;
  evf:file of eventrec;
  evr:eventrec;
  macrf:file of macrorec;
  macr:macrorec;
  fidorf:file of fidorec;
  fidor:fidorec;

  curdir:string;
  path:array[1..8] of string;
  found:boolean;
  dirinfo:searchrec;
  i,j,k:integer;
  c:char;

function syn(b:boolean):astr;
begin
  if (b) then syn:='Yes' else syn:='No ';
end;
  
function yn:boolean;
var c:char;
    b:boolean;
begin
  repeat c:=upcase(readkey) until c in ['Y','N',^M];
  case c of 'Y':b:=TRUE; else b:=FALSE; end;
  write(syn(b));
  yn:=b;
end;

function pynq(s:string):boolean;
begin
  textcolor(4); write(s);
  textcolor(11); pynq:=yn;
end;

procedure prt(s:string);
begin
  textcolor(9); write(s);
end;

procedure star(s:string);
begin
  textcolor(9); write('þ ');
  textcolor(11); cwrite(s); writeln;
end;

function freek(d:integer):longint;
var lng:longint;
begin
  lng:=diskfree(d);
  freek:=lng div 1024;
end;

function exdrv(s:astr):byte;
begin
  {rcg11172000 always 'C' under Linux...}
  {
  s:=fexpand(s);
  exdrv:=ord(s[1])-64;
  }
  exdrv := 3;
end;

function leapyear(yr:integer):boolean;
begin
  leapyear:=(yr mod 4=0) and ((yr mod 100<>0) or (yr mod 400=0));
end;

function value(s:astr):longint;
var i,j:integer;
begin
  val(s,i,j);
  if (j<>0) then begin
    s:=copy(s,1,j-1);
    val(s,i,j)
  end;
  value:=i;
  if (s='') then value:=0;
end;

function days(mo,yr:integer):integer;
var d:integer;
begin
  d:=value(copy('312831303130313130313031',1+(mo-1)*2,2));
  if ((mo=2) and (leapyear(yr))) then inc(d);
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
    if (leapyear(c)) then inc(t,366) else inc(t,365);
  t:=t+daycount(m,y)+(d-1);
  daynum:=t;
  if y<1985 then daynum:=0;
end;

function tch(s:astr):astr;
begin
  if (length(s)>2) then s:=copy(s,length(s)-1,2) else
    if (length(s)=1) then s:='0'+s;
  tch:=s;
end;

function time:astr;
var h,m,s:string[3];
    hh,mm,ss,ss100:word;
begin
  gettime(hh,mm,ss,ss100);
  str(hh,h); str(mm,m); str(ss,s);
  time:=tch(h)+':'+tch(m)+':'+tch(s);
end;

function date:astr;
var r:registers;
    y,m,d:string[3];
    yy,mm,dd,dow:word;
begin
  getdate(yy,mm,dd,dow);
  str(yy-1900,y); str(mm,m); str(dd,d);
  date:=tch(m)+'/'+tch(d)+'/'+tch(y);
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

(* FIX THIS UP *)
procedure movefile(var ok,nospace:boolean; showprog:boolean;
                   srcname,destname:astr);
var buffer:array[1..16384] of byte;
    fs,dfs:longint;
    nrec,i:integer;
    src,dest:file;

  procedure dodate;
  var r:registers;
      od,ot,ha:integer;
  begin
    srcname:=srcname+#0;
    destname:=destname+#0;
    with r do begin
      ax:=$3d00; ds:=seg(srcname[1]); dx:=ofs(srcname[1]); msdos(dos.registers(r));
      ha:=ax; bx:=ha; ax:=$5700; msdos(dos.registers(r));
      od:=dx; ot:=cx; bx:=ha; ax:=$3e00; msdos(dos.registers(r));
      ax:=$3d02; ds:=seg(destname[1]); dx:=ofs(destname[1]); msdos(dos.registers(r));
      ha:=ax; bx:=ha; ax:=$5701; cx:=ot; dx:=od; msdos(dos.registers(r));
      ax:=$3e00; bx:=ha; msdos(dos.registers(r));
    end;
  end;

begin
  ok:=TRUE; nospace:=FALSE;
  assign(src,srcname);
  {$I-} reset(src,1); {$I+}
  if (ioresult<>0) then begin ok:=FALSE; exit; end;

  {rcg11172000 why bother checking total disk space in a modern OS?}
  {
  dfs:=freek(exdrv(destname));
  fs:=trunc(filesize(src)/1024.0)+1;
  if (fs>=dfs) then begin
    close(src);
    nospace:=TRUE; ok:=FALSE;
    exit;
  end else begin
  }

    assign(dest,destname);
    {$I-} rewrite(dest,1); {$I+}
    if (ioresult<>0) then begin ok:=FALSE; exit; end;
    repeat
      blockread(src,buffer,16384,nrec);
      blockwrite(dest,buffer,nrec);
    until (nrec<16384);
    close(dest); close(src);
    dodate;
    erase(src);

  {rcg11172000 why bother checking total disk space in a modern OS?}
  {end;}
end;

procedure ffile(fn:string);
begin
  findfirst(fn,anyfile,dirinfo);
  found:=(doserror=0);
end;

procedure nfile;
begin
  findnext(dirinfo);
  found:=(doserror=0);
end;

procedure movefile1(srcname,destpath:string);
var ps,ns,es:string;
    ok,nospace:boolean;
begin
  ok:=TRUE; nospace:=FALSE;
  fsplit(srcname,ps,ns,es);
  star(srcname+#3#9+' -- '+#3#11+destpath);
  movefile(ok,nospace,FALSE,srcname,destpath+ns+es);
  if (not ok) then
    if (nospace) then
      star('Move failed: Insufficient space!!'^G)
    else
      star('Move failed!!'^G);
end;

procedure movefiles(srcname,destpath:string);
var ok,nospace:boolean;
begin
  ffile(srcname);
  while found do begin
    movefile1(dirinfo.name,destpath);
    nfile;
  end;
end;


function make_path(s:string):boolean;
begin
  {rcg11182000 dosism.}
  {while (copy(s,length(s),1)='\') do s:=copy(s,1,length(s)-1);}
  while (copy(s,length(s),1)='/') do s:=copy(s,1,length(s)-1);
  make_path:=TRUE;
  {$I-} mkdir(fexpand(s)); {$I+}
  if (ioresult<>0) then begin
    writeln;
    star('Error creating directory "'+fexpand(s)+'"'^G^G);
    make_path:=FALSE;
  end;
end;

procedure make_paths;
var s:string;
begin

  {rcg11182000 1 to 7? Swap path is excluded...}
  {for i:=1 to 7 do begin}

  for i:=1 to 8 do begin
    {rcg11182000 dosism.}
    {while copy(path[i],length(path[i]),1)='\' do}
    while copy(path[i],length(path[i]),1)='/' do
      path[i]:=copy(path[i],1,length(path[i])-1);
    case i of 1:s:='GFILES'; 2:s:='MSGS'; 3:s:='MENUS'; 4:s:='TFILES';
              5:s:='AFILES'; 6:s:='TRAP'; 7:s:='TEMP'; 8:s:='SWAP'; end;
    star(s+' path ("'+fexpand(path[i])+'")');
    if (not make_path(path[i])) then halt(1);
    {rcg11182000 dosism.}
    {path[i]:=path[i]+'\';}
    path[i]:=path[i]+'/';
  end;
(*  star('Creating EMAIL and GENERAL message paths');
  if (not make_path(path[2]+'EMAIL\')) then halt(1);
  if (not make_path(path[2]+'GENERAL\')) then halt(1);*)
  star('Creating SYSOP and MISC file paths');

  {rcg11182000 dosisms.}
  {
  if (not make_path('DLS\')) then halt(1);
  if (not make_path('DLS\SYSOP')) then halt(1);
  if (not make_path('DLS\MISC')) then halt(1);
  star('Creating TEMP 1, 2, and 3 file paths');
  if (not make_path(path[7]+'1\')) then halt(1);
  if (not make_path(path[7]+'2\')) then halt(1);
  if (not make_path(path[7]+'3\')) then halt(1);
  }
  if (not make_path('DLS/')) then halt(1);
  if (not make_path('DLS/SYSOP')) then halt(1);
  if (not make_path('DLS/MISC')) then halt(1);
  star('Creating TEMP 1, 2, and 3 file paths');
  if (not make_path(path[7]+'1/')) then halt(1);
  if (not make_path(path[7]+'2/')) then halt(1);
  if (not make_path(path[7]+'3/')) then halt(1);
end;

procedure make_status_dat;
begin
  with systat do begin
    gfilepath:=path[1];
    msgpath:=path[2];
    menupath:=path[3];
    tfilepath:=path[4];
    afilepath:=path[5];
    trappath:=path[6];
    temppath:=path[7];

    bbsname:='Telegard BBS';
    bbsphone:='000-000-0000';
    sysopname:='System Operator';
    maxusers:=9999;
    lowtime:=0; hitime:=0;
    dllowtime:=0; dlhitime:=0;
    shuttlelog:=FALSE;
    lock300:=FALSE;
    sysoppw:='SYSOP';
    newuserpw:='';
    shuttlepw:='MATRIX';
    b300lowtime:=0; b300hitime:=0;
    b300dllowtime:=0; b300dlhitime:=0;
    closedsystem:=FALSE;
    swapshell:=FALSE;
    eventwarningtime:=60;
    tfiledate:=date;
   { with hmsg do begin ltr:='A'; number:=-32766; ext:=1; end; }
                       {* A-32767.1 is the "Greetings from Telegard" message *}
    for i:=1 to 20 do res1[i]:=0;

    sop:='s255';
    csop:='s250';
    msop:='s199';
    fsop:='s230';
    spw:='s250';
    seepw:='s255';
    normpubpost:='s11';
    normprivpost:='s11';
    anonpubread:='s100';
    anonprivread:='s100';
    anonpubpost:='s100';
    anonprivpost:='s100';
    seeunval:='s50';
    dlunval:='s230';
    nodlratio:='s255';
    nopostratio:='s200';
    nofilepts:='s255';
    ulvalreq:='s21';
    for i:=1 to 100 do res2[i]:=0;

    maxprivpost:=20;
    maxfback:=5;
    maxpubpost:=20;
    maxchat:=3;
    maxwaiting:=15;
    csmaxwaiting:=50;
    maxlines:=120;
    csmaxlines:=160;
    maxlogontries:=4;
    bsdelay:=20;
    sysopcolor:=4;
    usercolor:=3;
    minspaceforpost:=10;
    minspaceforupload:=100;
    backsysoplogs:=7;
    wfcblanktime:=0;
    linelen:=80;
    pagelen:=25;
    for i:=1 to 18 do res3[i]:=0;

    specialfx:=TRUE;
    fossil:=FALSE;
    allowalias:=TRUE;
    phonepw:=TRUE;
    localsec:=FALSE;
    localscreensec:=FALSE;
    globaltrap:=FALSE;
    autochatopen:=TRUE;
    autominlogon:=TRUE;
    bullinlogon:=TRUE;
    lcallinlogon:=TRUE;
    yourinfoinlogon:=TRUE;
    multitask:=FALSE;
    offhooklocallogon:=TRUE;
    forcevoting:=FALSE;
    compressbases:=FALSE;
    searchdup:=FALSE;
    slogtype:=0;
    stripclog:=FALSE;
    newapp:=1;
    guestuser:=-1;
    timeoutbell:=2;
    timeout:=5;
    usewfclogo:=TRUE;
    useems:=FALSE;
    usebios:=TRUE;
    cgasnow:=FALSE;
    for i:=1 to 16 do res4[i]:=0;

    for i:=1 to 5 do
      with filearcinfo[i] do
        case i of
          1:begin
              active:=TRUE;
              ext:='ZIP';
              listline:='/1';
              arcline:='PKZIP -aex @F @I';
              unarcline:='PKUNZIP @F @I';
              testline:='PKUNZIP -t @F';
              cmtline:='PKZIP -z @F';
              succlevel:=0;
            end;
          2:begin
              active:=FALSE;
              ext:='ARC';
              listline:='/2';
              arcline:='PKPAK a @F @I';
              unarcline:='PKUNPAK @F @I';
              testline:='PKUNPAK -t @F';
              cmtline:='PKPAK x @F';
              succlevel:=0;
            end;
          3:begin
              active:=FALSE;
              ext:='PAK';
              listline:='/2';
              arcline:='PAK a @F @I';
              unarcline:='PAK e @F @I';
              testline:='PAK t @F';
              cmtline:='';
              succlevel:=-1;
            end;
          4:begin
              active:=FALSE;
              ext:='LZH';
              listline:='/4';
              arcline:='LHARC a @F @I';
              unarcline:='LHARC e @F @I';
              testline:='LHARC t @F';
              cmtline:='';
              succlevel:=0;
            end;
          5:begin
              active:=FALSE;
              ext:='ZOO';
              listline:='/3';
              arcline:='ZOO aP: @F @I';
              unarcline:='ZOO x @F @I';
              testline:='ZOO xNd @F';
              cmtline:='ZOO cA @F';
              succlevel:=0;
            end;
          6:begin
              active:=FALSE;
              ext:='DWC';
              listline:='DWC v @F';
              arcline:='DWC a @F @I';
              unarcline:='DWC x @F @I';
              testline:='DWC t @F';
              cmtline:='';
              succlevel:=0;
            end;
        end;
    filearcinfo[6].ext:='';

    filearccomment[1]:=bbsname+'  '+bbsphone;
    filearccomment[2]:=''; filearccomment[3]:='';

    uldlratio:=TRUE;
    fileptratio:=FALSE;
    fileptcomp:=3;
    fileptcompbasesize:=10;
    ulrefund:=100;
    tosysopdir:=0;
    validateallfiles:=FALSE;
    remdevice:='COM1';
    maxintemp:=500;
    minresume:=100;
    maxdbatch:=20;
    maxubatch:=20;
    for i:=1 to 30 do res5[i]:=0;

    newsl:=20;
    newdsl:=20;
    newar:=[];
    newac:=[rpostan,rvoting];
    newfp:=0;
    autosl:=50;
    autodsl:=50;
    autoar:=[];
    autoac:=[];

    allstartmenu:='MAIN';
    chatcfilter1:='';
    chatcfilter2:='';
    bulletprefix:='BULLET';
    for i:=1 to 15 do res6[i]:=0;

    for i:=0 to 255 do begin
      case i of 0..9:k:=1; 10..19:k:=10; 20..29:k:=20; 30..39:k:=40;
                40..49:k:=50; 50..59:k:=80; 60..69:k:=90; 70..79:k:=100;
                80..89:k:=110; 90..99:k:=120; 100..199:k:=130;
                200..239:k:=150; 240..249:k:=200; 250:k:=250;
                251..255:k:=6000; end; timeallow[i]:=k;
      case i of 200..255:k:=20; 100..199:k:=15; 50..99:k:=10;
                30..49:k:=5; 20..29:k:=3; else k:=1; end; callallow[i]:=k;
      case i of 60..255:k:=5; 20..59:k:=3; else k:=2; end; dlratio[i]:=k;
      case i of 60..255:k:=10; 20..59:k:=5; else k:=2; end; dlkratio[i]:=k;
      postratio[i]:=100;
    end;                       

    lastdate:=date;
    curwindow:=1;
    istopwindow:=FALSE;
    callernum:=0;
    numusers:=1;

    with todayzlog do begin
      for i:=0 to 4 do userbaud[i]:=0;
      active:=0; calls:=0; newusers:=0; pubpost:=0;
      privpost:=0; fback:=0; criterr:=0;
      uploads:=0; downloads:=0;
      uk:=0; dk:=0;
    end;

    postcredits:=0;
    rebootforevent:=FALSE;
    watchdogdoor:=FALSE;

    windowon:=TRUE;
    swappath:=path[8];
    for i:=1 to 119 do res[i]:=0;
  end;

  assign(systatf,'status.dat');
  rewrite(systatf); write(systatf,systat); close(systatf);
end;

procedure make_fidonet_dat;
begin
  with fidor do begin
    zone:=0;
    net:=0;
    node:=0;
    point:=0;
    origin:=copy(systat.bbsname+' ('+systat.bbsphone+')',1,50);
    text_color:=1;
    quote_color:=3;
    tear_color:=9;
    origin_color:=5;
    skludge:=TRUE;
    sseenby:=TRUE;
    sorigin:=FALSE;
    scenter:=TRUE;
    sbox:=TRUE;
    mcenter:=TRUE;
    addtear:=TRUE;
  end;
  assign(fidorf,'fidonet.dat');
  rewrite(fidorf); write(fidorf,fidor); close(fidorf);
end;

procedure make_modem_dat;
var i,j:integer;
begin
  with modemr do begin
    waitbaud:=1200;
    comport:=1;
    init:='ATH0Q0V0E0M0X1S0=0S2=43S10=40&C1';
    answer:='ATA';
    hangup:='~~~+++~~~ATH0';
    offhook:='ATH1M0';
    nocallinittime:=30;
    arq9600rate:=9600;
    noforcerate:=FALSE;
    nocarrier:=3;
    nodialtone:=6;
    busy:=7;
    for i:=1 to 2 do
      for j:=0 to 4 do begin
        case i of
          1:case j of 0:k:=1; 1:k:=5; 2:k:=10; 3:k:=0; 4:k:=13; end;
          2:case j of 0:k:=0; 1:k:=15; 2:k:=16; 3:k:=0; 4:k:=17; end;
        end;
        resultcode[i][j]:=k;
      end;
    modemr.ctschecking:=TRUE;
    modemr.dsrchecking:=TRUE;
    modemr.usexonxoff:=FALSE;
    modemr.hardwired:=FALSE;
  end;
  assign(modemf,'modem.dat');
  rewrite(modemf); write(modemf,modemr); close(modemf);
end;

procedure make_string_dat;
begin
  with fstring do begin
    ansiq:='Display ANSI logon? ';
    note[1]:='Enter your Telegard NAME or USER NUMBER';
    note[2]:='* NEW USERS, enter "NEW" *';
    lprompt:='Logon : ';
    echoc:='X';
    sysopin:='^3The SysOp is probably around!';
    sysopout:='^3The SysOp is NOT here, or doesn''t want to chat';
    engage:='@M^3The SysOp brings you into chat!';
    endchat:='^3The SysOp returns you to the BBS....@M';
    wait:='^3{-^9Please Wait^3-}';
    pause:='(* pause *)';
    entermsg1:='Enter message now.  You have ^3@X^1 lines maximum.';
    entermsg2:='Enter ^3/S^1 to save.  ^3/?^1 for a list of commands.';
    newscan1:='^7[^5@Y ^7- ^5@W msgs^7]  ^4NewScan began.@M';
    newscan2:='^7[^5@Y ^7- ^5@W msgs^7]  ^4NewScan complete.@M';
    scanmessage:='^3[^1@Y^3]@M^5[@U] ^4Read (1-@W,<CR>,?=help) : ';
    automsgt:='^5AutoMessage by: ';
    autom:='-';

    shelldos1:=#3#5+'>> '+systat.sysopname+' has shelled to DOS, please wait ...';
    shelldos2:=#3#5+'>> Thank you for waiting';
    chatcall1:=#3#0+'Paging '+systat.sysopname+' for chat, please wait.....';
    chatcall2:=#3#7+' >>'+#3#5+'<'+#3#8+'*'+#3#5+'>'+#3#7+'<<';
    guestline:='Enter "GUEST" as your user name to be a guest user on the system.';
    namenotfound:=#3#5+'That name is'+#3#8+' NOT'+#3#5+' found in the user list.';
    bulletinline:=#3#4+'Enter Bulletin Selection (XX,?,Q=Quit) : ';
    thanxvote:=#3#3+'Thanks for taking the time to vote!';

    listline:='List files - P to Pause';
    newline:='Search for new files -';
    searchline:='Search all directories for a file mask -';
    findline1:='Search descriptions and filenames for keyword -';
    findline2:='Enter the string to search for:';
    downloadline:='Download - You have @P file points.';
    uploadline:='Upload - @Kk free on this drive';
    viewline:='View archive interior files -@MP to Pause, N for Next file';
    nofilepts:=#3#8+'Access denied: '+#3#5+'Insufficient file points to download.';
    unbalance:=#3#8+'Access denied: '+#3#5+'Your upload/download ratio is out of balance:';

    pninfo:='P to Pause, N for next directory';
    gfnline1:='[Enter]=All files';
    gfnline2:=#3#4+'File mask: ';
    batchadd:='File added to batch queue.';
  end;
  assign(fstringf,'string.dat');
  rewrite(fstringf); write(fstringf,fstring); close(fstringf);
end;

procedure make_user_lst;
const dcols:clrs=((15,7,7,15,15,15,112,7,143,7),(15,7,1,11,9,14,31,4,140,10));
begin
  with u do begin
    name:='SYSOP';
    realname:='System Operator';
    pw:='SYSOP';
    ph:='000-000-0000';
    bday:='00/00/00';
    firston:=date;
    laston:=date;
    street:='';
    citystate:='';
    zipcode:='';
    computer:='IBM Compatible';
    occupation:='';
    wherebbs:='';
    note:='Change these stats to yours.';
    lockedout:=FALSE;
    deleted:=FALSE;
    lockedfile:='';
    ac:=[onekey,pause,novice,ansi,color,
         smw,    {* short message waiting, in SHORTMSG.DAT *}
         fnodlratio,fnopostratio,fnofilepts,fnodeletion];
    ar:=[]; for c:='A' to 'Z' do ar:=ar+[c];
(*    with qscan[1] do begin ltr:='A'; number:=-32767; ext:=1; end;*)
(*    for i:=2 to maxboards do qscan[i]:=qscan[1];*)
(*    for i:=1 to maxboards do qscn[i]:=TRUE;*)
(*    dlnscn:=[];*)
(*    for i:=0 to maxuboards do dlnscn:=dlnscn+[i];*)
    for i:=1 to 20 do vote[i]:=0;
    sex:='M';
    ttimeon:=0;
    uk:=0;
    dk:=0;
    uploads:=0;
    downloads:=0;
    loggedon:=0;
    tltoday:=600;
    msgpost:=0;
    emailsent:=0;
    feedback:=0;
    forusr:=0;
    filepoints:=0;
    waiting:=1;         {* A-32767.1 -- "Greetings from Telegard" message *}
    linelen:=80;
    pagelen:=20;        {* to make room for SysOp window when on.. *}
    ontoday:=0;
    illegal:=0;
    sl:=255;
    dsl:=255;
    cols:=dcols;
    lastmsg:=1;
    lastfil:=0;
    credit:=0;
    timebank:=0;
    for i:=1 to 5 do boardsysop[i]:=255;
    trapactivity:=FALSE;
    trapseperate:=FALSE;
    timebankadd:=0;
    mpointer:=-1;
    chatauto:=FALSE;
    chatseperate:=FALSE;
    userstartmenu:='';
    slogseperate:=FALSE;

{* NEW STUFF *}

    clsmsg:=2;      { clear screen before displaying each message }
    flistopt:=1;    { use file listing option #1 (normal) }
    msgorder:=0;    { use Chrono message ordering }
    avadjust:=1;    { no AVATAR color adjustment }

{* NEW STUFF *ENDS* *}

    for i:=1 to 54 do res[i]:=0;
  end;
  assign(uf,'user.lst');
  rewrite(uf);
  seek(uf,0); write(uf,u);      { write dummy record }
  seek(uf,1); write(uf,u);      { write user #1 }
  close(uf);
end;

procedure make_names_lst;
begin
  with sr do begin
    name:='SYSOP';
    number:=1;
  end;
  assign(sf,'names.lst');
  rewrite(sf);
  seek(sf,0); write(sf,sr);
  seek(sf,1); write(sf,sr);  {* think that was the bug... time will tell *}
  close(sf);
end;

procedure make_macro_lst;
var i:integer;
begin
  with macr do
    for i:=1 to 4 do macro[i]:='';
  assign(macrf,'macro.lst');
  rewrite(macrf);
  seek(macrf,0); write(macrf,macr);
  close(macrf);
end;

procedure make_boards_dat;
begin
  with br do begin
    name:='General Messages';
    filename:='GENERAL';
    msgpath:='';
    acs:='';
    postacs:='vv';
    mciacs:='%';
    maxmsgs:=50;
    anonymous:=atno;
    password:='';
    mbstat:=[mbskludge,mbsseenby,mbscenter,mbsbox,mbmcenter,mbaddtear];
    permindx:=0;
    mbtype:=1;
    origin:=fidor.origin;
    text_color:=fidor.text_color;
    quote_color:=fidor.quote_color;
    tear_color:=fidor.tear_color;
    origin_color:=fidor.origin_color;
    for i:=1 to 11 do res[i]:=0;
  end;
  assign(bf,'boards.dat');
  rewrite(bf); write(bf,br); close(bf);
end;

procedure make_uploads_dat;
begin
  assign(uff,'uploads.dat');
  rewrite(uff);
  with ufr do begin
    name:='SysOp directory';
    filename:='SYSOP';
    {rcg11182000 dosisms}
    {dlpath:=curdir+'\DLS\SYSOP\';}
    dlpath:=curdir+'/DLS/SYSOP/';
    ulpath:=dlpath;
    maxfiles:=2000;
    password:='';
    arctype:=1;
    cmttype:=1;
    fbdepth:=0;
    fbstat:=[];
    acs:='s255d255';
    ulacs:='';
    nameacs:='s255';
    permindx:=0;
    for i:=1 to 6 do res[i]:=0;
  end;
  write(uff,ufr);
  with ufr do begin
    name:='Miscellaneous';
    filename:='MISC';
    {rcg11182000 dosisms}
    {dlpath:=curdir+'\DLS\MISC\';}
    dlpath:=curdir+'/DLS/MISC/';
    ulpath:=dlpath;
    maxfiles:=2000;
    password:='';
    arctype:=1;
    cmttype:=1;
    fbdepth:=0;
    fbstat:=[];
    acs:='d30';
    ulacs:='';
    nameacs:='';
    permindx:=1;
    for i:=1 to 6 do res[i]:=0;
  end;
  write(uff,ufr); close(uff);
end;

procedure make_zlog_dat;
var i:integer;
begin
  with zfr do begin
    date:='08/18/89';
    for i:=0 to 4 do userbaud[i]:=0;
    active:=0; calls:=0; newusers:=0; pubpost:=0; privpost:=0;
    fback:=0; criterr:=0;
    uploads:=0; downloads:=0;
    uk:=0; dk:=0;
  end;
  assign(zf,'zlog.dat');
  rewrite(zf); write(zf,zfr);
  zfr.date:=''; write(zf,zfr);
  close(zf);
end;

procedure blockwritestr(var f:file; s:string);
begin
  blockwrite(f,s[0],1);
  blockwrite(f,s[1],ord(s[0]));
end;

procedure savemhead1(var brdf:file; mhead:mheaderrec);

  procedure outftinfo(var ft:fromtoinfo);
  var s:string;
  begin
    with ft do begin
      blockwrite(brdf,anon,1);
      blockwrite(brdf,usernum,2);
      blockwritestr(brdf,as);
      blockwritestr(brdf,real);
      blockwritestr(brdf,alias);
    end;
  end;

begin
  with mhead do begin
    blockwrite(brdf,signature,4);
    blockwrite(brdf,msgptr,4);
    blockwrite(brdf,isreplyto_iddate,6);
    blockwrite(brdf,isreplyto_idrand,2);
    blockwritestr(brdf,title);
    outftinfo(fromi);
    outftinfo(toi);
    blockwritestr(brdf,originsite);
  end;
end;

procedure make_email_brd;
var t:text;
    fb:file;
    mheader:mheaderrec;
    mixr:msgindexrec;
    s:string;
    dt:ldatetimerec;
    pdt:packdatetime;
    lng,lsize:longint;
    i:integer;
    bb:byte;
    year,month,day,dow,hour,min,sec,sec100:word;
begin
  assign(fb,'tosysop.ltr'); reset(fb,1); lsize:=filesize(fb); close(fb);
  assign(t,'tosysop.ltr'); reset(t);

  assign(brdf,'email.brd');
  rewrite(brdf,1);
  lng:=$FC020010; blockwrite(brdf,lng,4);
  lng:=$DCBA0123; blockwrite(brdf,lng,4);
  blockwrite(brdf,lsize,4);

  while (not eof(t)) do begin
    readln(t,s);
    bb:=$FF; blockwrite(brdf,bb,1);
    blockwrite(brdf,s[0],1);
    blockwrite(brdf,s[1],ord(s[0]));
  end;
  close(t);
  erase(t);

  with mixr do begin
    messagenum:=1;
    hdrptr:=filesize(brdf);
    msgindexstat:=[miexist];
    msgid:=4242;

    getdate(year,month,day,dow);
    dt.year:=year; dt.month:=month; dt.day:=day;
    gettime(hour,min,sec,sec100);
    dt.hour:=hour; dt.min:=min; dt.sec:=sec; dt.sec100:=sec100;
    dt2pdt(dt,pdt);
    for i:=1 to 6 do msgdate[i]:=pdt[i];
    msgdowk:=0;

    for i:=1 to 6 do lastdate[i]:=pdt[i];
    lastdowk:=0;

    isreplyto:=65535;
    numreplys:=0;
  end;

  assign(mixf,'email.mix');
  rewrite(mixf,sizeof(mixr)); blockwrite(mixf,mixr,1); close(mixf);
  with mheader do begin
    signature:=$ABCD0123;
    msgptr:=4;
    for i:=1 to 6 do isreplyto_iddate[i]:=0;
    isreplyto_idrand:=0;
    title:='Greetings, new Telegard SysOp!!';
    with fromi do begin
      anon:=0;
      usernum:=1;
      as:='The Telegard Team';
      real:='The Telegard Team';
      alias:='The Telegard Team';
    end;
    with toi do begin
      anon:=0;
      usernum:=1;
      as:='SysOp #1';
      real:='System Operator';
      alias:='SysOp';
    end;

    originsite:='';
  end;
  savemhead1(brdf,mheader);
  close(brdf);
end;
 
procedure make_events_dat;
begin
  assign(evf,'events.dat'); rewrite(evf);
  with evr do begin
    active:=TRUE;                     (* event is active *)
    description:='Pack message bases';
    etype:='P';                       (* PACK BASES event type *)
    execdata:='';                     (* no exec data needed *)
    busytime:=0;                      (* no offhook before event *)
    exectime:=240;                    (* 240 mins past midnite -- i.e. 4:00a *)
    busyduring:=TRUE;                 (* take phone offhook during *)
    duration:=1;                      (* 1 minute long *)
    execdays:=127;                    (* every day of the week *)
    monthly:=FALSE;                   (* weekly, not monthly *)
  end;
  write(evf,evr);
  with evr do begin
    active:=FALSE;                    (* event is NOT active *)
    description:='Nightly events';
    etype:='D';                       (* DOS SHELL event type *)
    execdata:='night.bat';            (* call NIGHT.BAT *)
    busytime:=1;                      (* take phone offhook 1 min before *)
    exectime:=241;                    (* 241 mins past midnite -- i.e. 4:01a *)
    busyduring:=TRUE;                 (* take phone offhook during *)
    duration:=1;                      (* 1 minute long *)
    execdays:=127;                    (* every day of the week *)
    monthly:=FALSE;                   (* weekly, not monthly *)
  end;
  write(evf,evr); close(evf);
end;

procedure make_laston_dat;
begin
  with lcall do begin
    callernum:=0;
    name:='The Telegard Team';
    number:=0;
    citystate:='Telegard Development HQ, MI';
  end;
  assign(lcallf,'laston.dat');
  rewrite(lcallf); write(lcallf,lcall);
  lcall.callernum:=-1;
  for i:=1 to 9 do write(lcallf,lcall);
  close(lcallf);
end;

procedure make_gfiles_dat;
begin
  assign(tfilf,'gfiles.dat');
  rewrite(tfilf);
  for i:=0 to 1 do begin
    with tfil do
      case i of
        0:begin
            title:='';
            filen:='';
            gdate:=date;
            gdaten:=1;
            acs:='';
            ulacs:='';
            tbstat:=[];
            permindx:=0;
            tbdepth:=0;
            for j:=1 to 4 do res[j]:=0;
          end;
        1:begin
            title:='Miscellaneous';
            filen:=#1#0#0#0#0#0;
            gdate:=date;
            gdaten:=daynum(gdate);
            acs:='';
            ulacs:='';
            tbstat:=[];
            permindx:=0;
            tbdepth:=0;
            for j:=1 to 4 do res[j]:=0;
          end;
      end;
    write(tfilf,tfil);
  end;
  close(tfilf);
end;

procedure make_verbose_dat;
begin
  with vr do
    for i:=1 to 4 do descr[i]:='';
  assign(verbf,'verbose.dat');
  rewrite(verbf); write(verbf,vr); close(verbf);
end;

procedure make_voting_dat;
begin
  with vd do begin
    question:='<< No Question >>';
    numa:=0;
    for i:=0 to 9 do
      with answ[i] do begin
        if (i<>0) then ans:='Selection '+chr(i+48) else ans:='No Comment';
        numres:=0;
      end;
  end;
  assign(vdata,'voting.dat');
  rewrite(vdata);
  for i:=0 to 19 do write(vdata,vd);
  close(vdata);
end;

procedure make_shortmsg_dat;
begin
  with sm do begin
    msg:='Telegard system initialized on '+date+' at '+time+'.';
    destin:=1;
  end;
  assign(smf,'shortmsg.dat');
  rewrite(smf); write(smf,sm); close(smf);
end;

procedure make_mboard(s:string);
var f:file;
    mixr:msgindexrec;
    lng:longint;
    i:integer;
begin
  assign(brdf,s+'.brd');
  rewrite(brdf,1); lng:=$FC020010; blockwrite(brdf,lng,4); close(brdf);

  assign(mixf,s+'.mix');
  rewrite(mixf,sizeof(mixr));
  mixr.hdrptr:=0; for i:=0 to 99 do blockwrite(mixf,mixr,1);
  close(mixf);

  assign(tref,s+'.tre'); rewrite(tref,sizeof(mtreerec)); close(tref);
end;

procedure make_fboard(s:string);
begin
  ulffr.blocks:=0;
  {rcg11182000 lowercased this ".DIR" strings...}
  assign(ulff,s+'.dir');
  rewrite(ulff); write(ulff,ulffr); close(ulff);
end;

procedure dostuff;
begin
  ttl('Creating Telegard directory paths');
  make_paths;
  ttl('Creating Telegard data files');
  make_status_dat;
  make_modem_dat;
  make_string_dat;
  make_fidonet_dat;
  make_user_lst;
  make_names_lst;
  make_macro_lst;
  make_boards_dat;
  make_uploads_dat;
(*  make_protocol_dat;*)
  make_zlog_dat;
  make_email_brd;
  make_events_dat;
  make_laston_dat;
  make_gfiles_dat;
  make_verbose_dat;
  make_voting_dat;
  make_shortmsg_dat;
  make_mboard('general');
  make_fboard('sysop');
  make_fboard('misc');

  ttl('Moving data files into GFILES directory');
  movefile1('user.lst',path[1]);
  movefile1('names.lst',path[1]);
  movefile1('macro.lst',path[1]);
  movefile1('boards.dat',path[1]);
  movefile1('events.dat',path[1]);
  movefile1('fidonet.dat',path[1]);
  movefile1('gfiles.dat',path[1]);
  movefile1('laston.dat',path[1]);
  movefile1('modem.dat',path[1]);
  movefile1('protocol.dat',path[1]);
  movefile1('shortmsg.dat',path[1]);
  movefile1('string.dat',path[1]);
  movefile1('uploads.dat',path[1]);
  movefile1('verbose.dat',path[1]);
  movefile1('voting.dat',path[1]);
  movefile1('zlog.dat',path[1]);
  {rcg11182000 lowercased this ".DIR" string...}
  movefiles('*.dir',path[1]);

  ttl('Moving message files into MSGS directory');
  movefile1('email.brd',path[2]);
  movefile1('email.mix',path[2]);
  movefile1('general.brd',path[2]);
  movefile1('general.mix',path[2]);
  movefile1('general.tre',path[2]);

  {rcg11182000 Made ANS MSG CFG and MNU lowercase...}

  ttl('Moving ANSI text files into AFILES directory');
  movefiles('*.ans',path[5]);

  ttl('Moving normal text files into AFILES directory');
  movefiles('*.msg',path[5]);
  movefile1('computer.txt',path[5]);

  ttl('Moving color configuration files into AFILES directory');
  movefiles('*.cfg',path[5]);

(*  ttl('Moving message file into MSGS\EMAIL directory');
  movefile1('a-32767.1',path[2]+'EMAIL\');*)

  ttl('Moving menu files into MENUS directory');
  movefiles('*.mnu',path[3]);
end;

begin
  infield_out_fgrd:=11;
  infield_out_bkgd:=0;
  infield_inp_fgrd:=15;
  infield_inp_bkgd:=1;
  clrscr; textbackground(1); textcolor(15);
  gotoxy(1,1); clreol; gotoxy(10,1);
  write('Telegard v'+ver+' Initialization Utility - Copyright 1988,89,90 by');
  gotoxy(1,2); clreol; gotoxy(8,2);
  write('Eric Oman, Martin Pollard, and Todd Bolitho - All Rights Reserved.');
  textbackground(0); textcolor(7);
  window(1,3,80,25);
  writeln;
  assign(systatf,'status.dat');
  {$I-} reset(systatf); {$I+}
  if ioresult=0 then begin
    textcolor(28); write('WARNING!!');
    textcolor(14); writeln('  "STATUS.DAT" file already exists..');
    writeln('Telegard has already been initialized!');
    writeln('If you proceed, ALL DATA FILES WILL BE ERASED AND INITIALIZED!!!');
    writeln;
    if not pynq('Proceed? ') then halt(1);
    writeln;
  end;

  getdir(0,curdir);
  {rcg11182000 dosisms.}
  {
  path[1]:=curdir+'\GFILES\';
  path[2]:=curdir+'\MSGS\';
  path[3]:=curdir+'\MENUS\';
  path[4]:=curdir+'\TFILES\';
  path[5]:=curdir+'\AFILES\';
  path[6]:=curdir+'\TRAP\';
  path[7]:=curdir+'\TEMP\';
  path[8]:=curdir+'\SWAP\';
  }
  path[1]:=curdir+'/GFILES/';
  path[2]:=curdir+'/MSGS/';
  path[3]:=curdir+'/MENUS/';
  path[4]:=curdir+'/TFILES/';
  path[5]:=curdir+'/AFILES/';
  path[6]:=curdir+'/TRAP/';
  path[7]:=curdir+'/TEMP/';
  path[8]:=curdir+'/SWAP/';

  textcolor(14);
  writeln;
  writeln('You will now be prompted several times for names of directorys');
  writeln('that will be used by Telegard.  Each directory will be created');
  writeln('and the appropriate files will be moved there-in.');
  writeln;
  writeln('GFILES pathname.  This is the directory where the Telegard data');
  writeln('files and miscellaneous Telegard text files will be located.');
  writeln;
  prt('GFILES pathname: '); infielde(path[1],60); writeln; writeln;

  textcolor(14);
  writeln('MSGS pathname.  This directory should contain all the message');
  writeln('files (*.BRD, *.MIX, *.TRE) used by Telegard for both private');
  writeln('and public messages.');
  writeln;
  prt('MSGS pathname: '); infielde(path[2],60); writeln; writeln;

  textcolor(14);
  writeln('MENUS pathname.  This is the directory where the Telegard menu');
  writeln('files will be located.');
  writeln;
  prt('MENUS pathname: '); infielde(path[3],60); writeln; writeln;

  textcolor(14);
  writeln('TFILES pathname.  This is the directory where the Telegard');
  writeln('"text file section" text files will be located in.');
  writeln;
  prt('TFILES pathname: '); infielde(path[4],60); writeln; writeln;

  textcolor(14);
  writeln('AFILES pathname.  This is the directory where the Telegard');
  writeln('menu help files, ANSI displays, etc. will be located.');
  writeln;
  prt('AFILES pathname: '); infielde(path[5],60); writeln; writeln;

  textcolor(14);
  writeln('TRAP pathname.  This is the directory where Telegard will');
  writeln('output all User Audit traps, chat conversations (CHAT.MSG),');
  writeln('and SysOp logs (SYSOP*.LOG).');
  writeln;
  prt('TRAP pathname: '); infielde(path[6],60); writeln; writeln;

  textcolor(14);
  writeln('TEMP pathname.  Telegard uses this directory to convert between');
  writeln('archive formats, receive batch uploads, and allow users to');
  writeln('decompress archives to download single files, etc.');
  writeln;
  prt('TEMP pathname: '); infielde(path[7],60); writeln; writeln;

  textcolor(14);
  writeln('SWAP pathname.  This is the directory where Telegard''s swap');
  writeln('shell function will store its memory image file (if it cannot');
  writeln('swap to EMS memory).');
  writeln;
  prt('SWAP pathname: '); infielde(path[8],60); writeln; writeln;

  clrscr;

  dostuff;

  writeln;
  star('Telegard BBS installed and initialized successfully!');
  {rcg11172000 DOSism.}
  {star('This program, "INIT.EXE", can now be deleted.');}
  star('This program, "init", can now be deleted.');
  star('Thanks for trying Telegard!');

  {rcg11182000 added NormVideo.}
  NormVideo;
end.
