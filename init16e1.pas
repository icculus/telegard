program init;

{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
{$M 50000,0,90000}      { Declared here suffices for all Units as well! }

uses
  crt,dos,
  myio,
  common;

{$I rec16e1.pas}

var
  systatf:file of systatrec;
  systat:systatrec;
  uf:file of userrec;
  u:userrec;
  sf:file of smalrec;
  sr:smalrec;
  bf:file of boardrec;
  br:boardrec;
  uff:file of ulrec;
  ufr:ulrec;
  xp:file of expro;
  xpr:expro;
  zf:file of zlogt;
  zfr:zlogt;
  mailfile:file of mailrec;
  mr:mailrec;
  lcallf:file of lcallers;
  lcall:lcallers;
  tfilf:file of gft;
  tfil:gft;
  verbf:file of verbrec;
  vr:verbrec;
  vdata:file of vdatar;
  vd:vdatar;
  smf:file of smr;
  sm:smr;
  msr:messagerec;
  ulff:file of ulfrec;
  ulffr:ulfrec;
  evf:file of eventrec;
  evr:eventrec;
  macrf:file of macrorec;
  macr:macrorec;

  curdir:string;
  path:array[1..7] of string;
  found:boolean;
  dirinfo:searchrec;
  i,j,k:integer;
  c:char;

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
  textcolor(11); writeln(s);
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

procedure movefile(srcname,destpath:string);
var buffer:array[1..16384] of byte;
    dfs,nrec:integer;
    src,dest:file;

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
  star('Moving "'+srcname+'" to "'+destpath+'"');
  destpath:=destpath+srcname;
  assign(src,srcname);
  {$I-} reset(src,1); {$I+}
  if ioresult<>0 then begin
    writeln;
    star('"'+srcname+'": File not found.'^G^G);
    halt(1);
  end else begin
    dfs:=freek(exdrv(destpath));

    {rcg11172000 don't have LONGfilesize()...}
    {if trunc(longfilesize(src)/1024.0)+1>=dfs then begin}
    if trunc(filesize(src)/1024.0)+1>=dfs then begin
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

procedure movefiles(srcname,destpath:string);
begin
  ffile(srcname);
  while found do begin
    movefile(dirinfo.name,destpath);
    nfile;
  end;
end;


function make_path(s:string):boolean;
begin
  while (copy(s,length(s),1)='\') do s:=copy(s,1,length(s)-1);
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
  for i:=1 to 7 do begin
    while copy(path[i],length(path[i]),1)='\' do
      path[i]:=copy(path[i],1,length(path[i])-1);
    case i of 1:s:='GFILES'; 2:s:='MSGS'; 3:s:='MENUS'; 4:s:='TFILES';
              5:s:='AFILES'; 6:s:='TRAP'; 7:s:='TEMP'; end;
    star(s+' path ("'+fexpand(path[i])+'")');
    if (not make_path(path[i])) then halt(1);
    path[i]:=path[i]+'\';
  end;
  star('Creating EMAIL and GENERAL message paths');
  if (not make_path(path[2]+'EMAIL\')) then halt(1);
  if (not make_path(path[2]+'GENERAL\')) then halt(1);
  star('Creating SYSOP and MISC file paths');
  if (not make_path('DLS\')) then halt(1);
  if (not make_path('DLS\SYSOP')) then halt(1);
  if (not make_path('DLS\MISC')) then halt(1);
  star('Creating TEMP 1, 2, and 3 file paths');
  if (not make_path(path[7]+'1\')) then halt(1);
  if (not make_path(path[7]+'2\')) then halt(1);
  if (not make_path(path[7]+'3\')) then halt(1);
end;

procedure make_status_dat;
begin
  with systat do begin
    bbsname:='Telegard BBS';
    bbsphone:='000-000-0000';
    sysopfirst:='System';
    sysoplast:='Operator';
    boardpw:='';
    sysoppw:='SYSOP';
    bbspw:='MATRIX';
    closedsystem:=FALSE;
    matrix:=FALSE;
    alias:=TRUE;
    clearmsg:=TRUE;
    fone:=TRUE;
    multitask:=FALSE;
    bwindow:=TRUE;
    lock300:=FALSE;
    wantquote:=TRUE;  {* /// *}
    mcimsg:=TRUE;     {* /// *}
    special:=TRUE;
    localsec:=FALSE;
    localscreensec:=FALSE;
    autominlogon:=TRUE;
    bullinlogon:=TRUE;
    lcallinlogon:=TRUE;
    autochatopen:=TRUE;
    yourinfoinlogon:=TRUE;
    globaltrap:=FALSE;
    snowchecking:=FALSE;
    forcevoting:=FALSE;
    offhooklocallogon:=TRUE;

    with hmsg do begin ltr:='A'; number:=-32766; ext:=1; end;
                       {* A-32767.1 is the "Greetings from Telegard" message *}
    tfiledate:='04/21/89';
    lastdate:='04/21/89';
    users:=1;
    callernum:=0;
    activetoday:=0;
    callstoday:=0;
    msgposttoday:=0;
    emailtoday:=0;
    fbacktoday:=0;
    uptoday:=0;
    newuk:=0;
    newusertoday:=0;
    dntoday:=0;
    newdk:=0;
    gfilepath:=path[1];
    pmsgpath:=path[2]+'EMAIL\';
    menupath:=path[3];
    tfilepath:=path[4];
    afilepath:=path[5];
    trappath:=path[6];
    temppath:=path[7];
    lowtime:=0; hitime:=0;
    dllowtime:=0; dlhitime:=0;
    b300lowtime:=0; b300hitime:=0;
    b300dllowtime:=0; b300dlhitime:=0;
    app:=1;
    guestuser:=-1;
    timeoutbell:=2;
    timeout:=5;
    sysopcolor:=4; usercolor:=3;
    bsdelay:=20;
    tosysopdir:=0;
    comport:=1;
    maxbaud:=1200;
    init:='ATH0Q0V0E0M0X1S0=0S2=1S10=40&C1';
    hangup:='ATH';
    offhook:='ATH1';
    answer:='ATA';
    for i:=1 to 2 do
      for j:=0 to 4 do begin
        case i of
          1:case j of 0:k:=1; 1:k:=5; 2:k:=10; 3:k:=0; 4:k:=13; end;
          2:case j of 0:k:=0; 1:k:=15; 2:k:=16; 3:k:=0; 4:k:=17; end;
        end;
        resultcode[i][j]:=k;
      end;
    nocarrier:=3;
    nodialtone:=6;
    busy:=7;
    nocallinittime:=30;
    tries:=4;
    newsl:=20; newdsl:=20;
    newar:=[];
    newac:=[rpostan,rvoting];
    newfp:=0;
    autosl:=50; autodsl:=50;
    autoar:=[];
    autoac:=[];
    ansiq:='Display ANSI logon? ';
    engage:='@M^3The SysOp brings you into chat!';
    endchat:='^3The SysOp returns you to the BBS....@M';
    sysopin:='^3The SysOp is probably around!';
    sysopout:='^3The SysOp is NOT here, or doesn''t want to chat';
    note[1]:='Enter your Telegard NAME or USER NUMBER';
    note[2]:='* NEW USERS, enter "NEW" *';
    lprompt:='Logon : ';
    wait:='^3{-^9Please Wait^3-}';
    pause:='(* pause *)';
    msg1:='Enter message now.  You have ^3@X^1 lines maximum.';
    msg2:='Enter ^3/S^1 to save.  ^3/?^1 for a list of commands.';
    new1:='^7[^5@Y ^7- ^5@W msgs^7]  ^4NewScan began.@M';
    new2:='^7[^5@Y ^7- ^5@W msgs^7]  ^4NewScan complete.@M';
    read:='^3[^1@Y^3]@M^5[@U] ^4Read (1-@W,<CR>,T,Q,P,A,R,B,W,D) : ';
    auto1:='^5AutoMessage by: ';
    autom:='-';
    echoc:='X';

    uldlratio:=TRUE;
    fileptratio:=FALSE;
    fileptcomp:=3;
    fileptcompbasesize:=10;

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

    normpubpost:=11; anonpubpost:=100; anonpubread:=100;
    normprivpost:=11; anonprivpost:=100; anonprivread:=100;
    maxpubpost:=20; maxprivpost:=20;
    maxfback:=5; maxchat:=3;
    maxwaiting:=15; csmaxwaiting:=50;
    maxlines:=120; csmaxlines:=160;

    sop:=255; csop:=250;
    msop:=199; fsop:=230;
    spw:=250; seepw:=255;
    nodlratio:=255; nopostratio:=200;
    nofilepts:=255; seeunval:=50;
    dlunval:=230; ulrefund:=100;

    eventwarningtime:=60;
    filearccomment[1]:=bbsname+'  '+bbsphone;
    filearccomment[2]:=''; filearccomment[3]:='';

    for i:=1 to 5 do
      with filearcinfo[i] do
        case i of
          1:begin
              active:=TRUE;
              ext:='ZIP';
              listline:='/1';
              arcline:='PKZIP -aeb4 @F @I';
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
              testline:='';
              cmtline:='';
              succlevel:=-1;
            end;
          4:begin
              active:=FALSE;
              ext:='LZH';
              listline:='/4';
              arcline:='LHARC a @F @I';
              unarcline:='LHARC e @F @I';
              testline:='';
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
        end;
    filearcinfo[6].ext:='';

    minspaceforpost:=10;
    minspaceforupload:=100;
postcredits:=0; {* not implemented *}
ulvalreq:=0;    {* not implemented *}
    moveline:='';
    backsysoplogs:=7;
    compressbases:=FALSE;

    for i:=1 to 165 do res[i]:=0;
  end;
  assign(systatf,'status.dat');
  rewrite(systatf); write(systatf,systat); close(systatf);
end;

procedure make_user_lst;
const dcols:clrs=((15,7,7,15,15,15,112,7,143,7),(15,3,1,11,9,14,31,4,140,10));
begin
  with u do begin
    name:='SYSOP';
    realname:='System Operator';
    pw:='SYSOP';
    ph:='000-000-0000';
    bday:='00/00/00';
    firston:='04/21/89';
    laston:='04/21/89';
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
    ac:=[onekey,wordwrap,pause,novice,ansi,color,
         smw,    {* short message waiting, in SHORTMSG.DAT *}
         fnodlratio,fnopostratio,fnofilepts,fnodeletion];
    ar:=[]; for c:='A' to 'Z' do ar:=ar+[c];
    with qscan[1] do begin ltr:='A'; number:=-32767; ext:=1; end;
    for i:=2 to maxboards do qscan[i]:=qscan[1];
    for i:=1 to maxboards do qscn[i]:=TRUE;
    dlnscn:=[];
    for i:=0 to maxuboards do dlnscn:=dlnscn+[i];
    for i:=1 to 20 do vote[i]:=0;
    sex:='M';
    ttimeon:=0.0;
    uk:=0.0;
    dk:=0.0;
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
    pagelen:=23;        {* to make room for SysOp window when on.. *}
    ontoday:=0;
    illegal:=0;
    sl:=255;
    dsl:=255;
    cols:=dcols;
    lastmsg:=1;
    lastfil:=0;
    credit:=0.0;
    timebank:=0;
    for i:=1 to 5 do boardsysop[i]:=255;

    trapactivity:=FALSE;
    trapseperate:=FALSE;

{* NEW STUFF *}

    timebankadd:=0;
    mpointer:=-1;

{* NEW STUFF *ENDS* *}

    for i:=1 to 70 do res[i]:=0;
  end;
  assign(uf,'user.lst');
  rewrite(uf);
  seek(uf,0); write(uf,u);
  seek(uf,1); write(uf,u);
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
  seek(sf,1); write(sf,sr);
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
    msgpath:=path[2]+'GENERAL\';
    sl:=30;
    maxmsgs:=50;
    password:='';
    anonymous:=no;
    ar:='@';
    postsl:=30;
  end;
  assign(bf,'boards.dat');
  rewrite(bf);
  seek(bf,0); write(bf,br);
  close(bf);
end;

procedure make_uploads_dat;
begin
  assign(uff,'uploads.dat');
  rewrite(uff);
  with ufr do begin
    name:='SysOp directory';
    filename:='SYSOP';
    dlpath:=curdir+'\DLS\SYSOP\';
    noratio:=FALSE;
    sl:=255;
    dsl:=255;
    namesl:=255;
    ar:='@';
    maxfiles:=999;
    agereq:=1;
    password:='';
    arctype:=1;
    cmttype:=1;
    unhidden:=FALSE;
  end;
  write(uff,ufr);
  with ufr do begin
    name:='Miscellaneous';
    filename:='MISC';
    dlpath:=curdir+'\DLS\MISC\';
    noratio:=FALSE;
    sl:=30;
    dsl:=30;
    namesl:=10;
    ar:='@';
    maxfiles:=999;
    agereq:=1;
    password:='';
    arctype:=1;
    cmttype:=1;
    unhidden:=TRUE;
  end;
  write(uff,ufr); close(uff);
end;

procedure make_protocol_dat;
begin
  assign(xp,'protocol.dat');
  rewrite(xp);
  for i:=1 to 11 do
    with xpr do begin
      rcmd:=''; scmd:='';
      rul:=FALSE; rdl:=FALSE;
      sl:=0; dsl:=0; ar:='@';
      xferok:=-1;
      if (i in [1..5]) then active:=TRUE else active:=FALSE;
      case i of
        1:begin descr:='Ascii'; key:='A'; ptype:=1; rul:=TRUE; end;
        2:begin descr:='Xmodem'; key:='X'; ptype:=2; end;
        3:begin descr:='Xmodem CRC'; key:='C'; ptype:=3; end;
        4:begin descr:='Ymodem'; key:='Y'; ptype:=4; end;
        5:begin descr:='Ymodem'; key:='Y'; ptype:=5; rul:=TRUE; end;
        6:begin
            descr:='Zmodem';
            key:='Z';
            ptype:=6;
            rcmd:='dsz port @2 speed @1 rz @3';
            scmd:='dsz port @2 speed @1 sz @3';
            xferok:=0;
          end;
        7:begin
            descr:='Zmodem';
            key:='Z';
            ptype:=7;
            rcmd:='dsz port @2 speed @1 rz';
            scmd:='dsz port @2 speed @1 @@4';
            xferok:=0;
          end;
        8:begin
            descr:='Zmodem '+#3#5+'Recovery';
            key:='Z';
            ptype:=8;
            rcmd:='dsz port @2 speed @1 -r rz @3';
            scmd:='---';
            xferok:=0;
            rdl:=TRUE;
          end;
        9:begin
            descr:='Lynx';
            key:='L';
            ptype:=6;
            rcmd:='lynx R /@1 /@2 @3';
            scmd:='lynx S /@1 /@2 @3';
            xferok:=0;
          end;
       10:begin
            descr:='Lynx';
            key:='L';
            ptype:=7;
            rcmd:='lynx R /@1 /@2';
            scmd:='lynx S /@1 /@2 @3';
            xferok:=0;
          end;
       11:begin
            descr:='Lynx '+#3#5+'Recovery';
            key:='L';
            ptype:=8;
            rcmd:='lynx R /@1 /@2';
            scmd:='---';
            xferok:=0;
            rdl:=TRUE;
          end;
       12:begin
            descr:='Jmodem';
            key:='J';
            ptype:=6;
            rcmd:='jmodem R@2 @3';
            scmd:='jmodem S@2 @3';
            xferok:=-1;
          end;
       13:begin
            descr:='Megalink';
            key:='M';
            ptype:=6;
            rcmd:='mlink PORT @2 SPEED @1 RM @3';
            scmd:='mlink PORT @2 SPEED @1 SM @3';
            xferok:=0;
          end;
      end;
      write(xp,xpr);
    end;
  close(xp);
end;

procedure make_zlog_dat;
begin
  with zfr do begin
    date:='04/21/89';
    active:=0;
    calls:=0;
    post:=0;
    email:=0;
    fback:=0;
    up:=0;
  end;
  assign(zf,'zlog.dat');
  rewrite(zf); write(zf,zfr);
  zfr.date:='';
  for i:=1 to 96 do write(zf,zfr);
  close(zf);
end;

procedure make_email_dat;
begin
  with mr do begin
    title:='Greetings from Telegard';
    from:=1; destin:=1;
    with msg do begin ltr:='A'; number:=-32767; ext:=1; end;
    mage:=255;
  end;
  mr.date:=daynum(date);
  assign(mailfile,'email.dat');
  rewrite(mailfile); write(mailfile,mr); close(mailfile);
end;
 
procedure make_events_dat;
begin
  with evr do begin
    active:=FALSE;
    description:='A NEW Telegard Event';
    etype:='D';
    execdata:='event.bat';
    busytime:=5;
    exectime:=0;
    busyduring:=TRUE;
    duration:=1;
    execdays:=0;
    monthly:=FALSE;
  end;
  assign(evf,'events.dat');
  rewrite(evf); write(evf,evr); close(evf);
end;

procedure make_laston_dat;
begin
  with lcall do begin
    callernum:=0;
    name:='Eric Oman';
    number:=1;
    citystate:='Grosse Pointe Woods, Michigan';
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
            num:=1;   {* 1 entry total *}
            title:='';
            filen:='';
            ar:='@';
            gdate:='04/21/89';
            gdaten:=daynum(gdate);
          end;
        1:begin
            num:=0;   {* SL level *}
            title:='Miscellaneous';
            filen:=#1#0#0#0#0#0;
            ar:='@';
            gdate:='04/21/89';
            gdaten:=daynum(gdate);
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
    msg:='Telegard files initialized on '+date+' '+time+'.';
    destin:=1;
  end;
  assign(smf,'shortmsg.dat');
  rewrite(smf); write(smf,sm); close(smf);
end;

procedure make_mboard(s:string);
var f:file;
begin
  msr.message.number:=0;
  assign(f,s+'.BRD');
  rewrite(f,sizeof(messagerec)); blockwrite(f,msr,1); close(f);
end;

procedure make_fboard(s:string);
begin
  ulffr.blocks:=0;
  assign(ulff,s+'.DIR');
  rewrite(ulff); write(ulff,ulffr); close(ulff);
end;

procedure dostuff;
begin
  ttl('Creating Telegard directory paths');
  make_paths;
  ttl('Creating Telegard data files');
  make_status_dat;
  make_user_lst;
  make_names_lst;
  make_macro_lst;
  make_boards_dat;
  make_uploads_dat;
  make_protocol_dat;
  make_zlog_dat;
  make_email_dat;
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
  movefile('user.lst',path[1]);
  movefile('names.lst',path[1]);
  movefile('macro.lst',path[1]);
  movefile('boards.dat',path[1]);
  movefile('email.dat',path[1]);
  movefile('events.dat',path[1]);
  movefile('gfiles.dat',path[1]);
  movefile('laston.dat',path[1]);
  movefile('protocol.dat',path[1]);
  movefile('shortmsg.dat',path[1]);
  movefile('uploads.dat',path[1]);
  movefile('verbose.dat',path[1]);
  movefile('voting.dat',path[1]);
  movefile('zlog.dat',path[1]);
  movefiles('*.BRD',path[1]);
  movefiles('*.DIR',path[1]);
  ttl('Moving miscellaneous text files into AFILES directory');
  movefiles('*.ANS',path[5]);
  movefiles('*.MSG',path[5]);
  movefiles('*.TUT',path[5]);
  movefile('computer.txt',path[5]);
  ttl('Moving message file into MSGS\EMAIL directory');
  movefile('a-32767.1',path[2]+'EMAIL\');
  ttl('Moving menu files into MENUS directory');
  movefiles('*.MNU',path[3]);
end;

begin
  infield_out_fgrd:=11;
  infield_out_bkgd:=0;
  infield_inp_fgrd:=15;
  infield_inp_bkgd:=1;

  clrscr;
  gotoxy(1,1); textbackground(1); textcolor(15);
  clreol; write(' Initialization Utility for Telegard version '+ver);
  textbackground(0); textcolor(7);
  window(1,2,80,25);
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
  path[1]:=curdir+'\GFILES\';
  path[2]:=curdir+'\MSGS\';
  path[3]:=curdir+'\MENUS\';
  path[4]:=curdir+'\TFILES\';
  path[5]:=curdir+'\AFILES\';
  path[6]:=curdir+'\TRAP\';
  path[7]:=curdir+'\TEMP\';

  textcolor(14);
  writeln;
  writeln('You will now be prompted several times for names of directorys');
  writeln('that will be used by Telegard.  Each directory will be created');
  writeln('and the appropriate files will be moved there-in.');
  writeln;
  writeln('GFILES pathname.  This is the directory where the Telegard data');
  writeln('files and miscellaneous Telegard text files will be located.');
  writeln;
  prt('GFILES dirname: '); infielde(path[1],60); writeln; writeln;

  textcolor(14);
  writeln('MSGS pathname.  This directory should contain all the other message');
  writeln('directory paths used by Telegard, including private mail (EMAIL).');
  writeln('Located in these paths are the text of the Telegard messages.');
  writeln;
  prt('MSGS dirname: '); infielde(path[2],60); writeln; writeln;

  textcolor(14);
  writeln('MENUS pathname.  This is the directory where the Telegard menu');
  writeln('files will be located.');
  writeln;
  prt('MENUS dirname: '); infielde(path[3],60); writeln; writeln;

  textcolor(14);
  writeln('TFILES pathname.  This is the directory where the Telegard');
  writeln('"text file section" text files will be located in.');
  writeln;
  prt('TFILES dirname: '); infielde(path[4],60); writeln; writeln;

  textcolor(14);
  writeln('AFILES pathname.  This is the directory where the Telegard');
  writeln('menu help files, ANSI displays, etc. will be located.');
  writeln;
  prt('AFILES dirname: '); infielde(path[5],60); writeln; writeln;

  textcolor(14);
  writeln('TRAP pathname.  This is the directory where Telegard will');
  writeln('output all User Audit traps to.  In the future, CHAT.MSG,');
  writeln('SYSOP*.LOG, FILE*.LOG, etc. will be stored here as well.');
  writeln;
  prt('TRAP dirname: '); infielde(path[6],60); writeln; writeln;

  textcolor(14);
  writeln('TEMP pathname.  Telegard uses this directory to convert between');
  writeln('archive formats, receive batch uploads, and allow users to');
  writeln('decompress archives to download single files, etc.');
  writeln;
  prt('TEMP dirname: '); infielde(path[7],60); writeln; writeln;

  clrscr;

  dostuff;

  writeln;
  star('Telegard BBS installed and initialized successfully!');
  star('This program, "INIT.EXE", can now be deleted.');
  star('Thanks for trying Telegard!');
end.
