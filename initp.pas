{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit initp;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  myio,
  common;

procedure readp;
procedure initp1;
procedure init;

implementation

const
  openedyet:boolean=FALSE;

procedure scroll_clear(t:integer);
var i,j,k:integer;
begin
  case t of
    1:for i:=0 to 1 do
        for j:=1 to 5 do
          for k:=1 to 5 do
          begin
            window(1,(k-1)*5+1,80,k*5);
            textcolor(7);
            textbackground(i);
            gotoxy(1,5);
            writeln;
          end;
    2:for i:=1 downto 0 do
        for j:=1 to 5 do
          for k:=1 to 5 do
          begin
            window(1,(k-1)*5+1,80,k*5);
            textcolor(7);
            textbackground(i);
            gotoxy(1,j);
            clreol;
          end;
  end;
  window(1,1,80,25);
end;

procedure tanim;
var s:array[1..5] of string;
    i,j:integer;
begin
  s[1]:=' °±²²²²²²²² °±²²²²²² °±²²      °±²²²²²²  °±²²²²²²  °±²²²²²  °±²²²²²²  °±²²²²²² ';
  s[2]:='    °±²²    °±²²     °±²²      °±²²     °±²²      °±²² °±²² °±²² °±²² °±²² °±²²';
  s[3]:='    °±²²    °±²²²²²  °±²²      °±²²²²²  °±²² °±²² °±²²²²²²² °±²²²²²²  °±²² °±²²';
  s[4]:='    °±²²    °±²²     °±²²      °±²²     °±²² °±²² °±²² °±²² °±²² °±²² °±²² °±²²';
  s[5]:='    °±²²    °±²²²²²² °±²²²²²²² °±²²²²²²  °±²²²²²² °±²² °±²² °±²² °±²² °±²²²²²² ';
  textbackground(1); textcolor(15); clrscr;
(*
  for i:=30 downto 0 do begin
    gotoxy(1,20);
    for j:=1 to 5 do writeln(copy(s[j],(i)*(j-1),length(s[j])));
  end;
  for i:=18 downto 2 do begin
    gotoxy(1,i);
    for j:=1 to 5 do writeln(s[j]);
    writeln(s[5]);
  end;
  for i:=24 downto 7 do begin
    gotoxy(1,i);
    clreol;
  end;
*)
  gotoxy(1,2);
  for j:=1 to 5 do writeln(s[j]);
end;

procedure readp;
var filv:text;
    d:astr;
    a,count:integer;

  function sc(s:astr; i:integer):char;
  begin
    s:=allcaps(s); sc:=s[i];
  end;

  procedure wpar(s:astr);
  begin
    writeln('       '+s);
  end;

  function atoi(s:astr):word;
  var i,code:integer;
  begin
    val(s,i,code);
    if code<>0 then i:=0;
    atoi:=i;
  end;

begin
  cursoron(FALSE); exteventtime:=0;
  answerbaud:=0; quitafterdone:=FALSE; returna:=FALSE; nightly:=FALSE;
  {minitermonly:=FALSE;} localioonly:=FALSE;
  a:=0;
  while (a<paramcount) do begin
    inc(a);
    if ((sc(paramstr(a),1)='-') or (sc(paramstr(a),1)='/')) then
      case sc(paramstr(a),2) of
        'B':answerbaud:=atoi(copy(paramstr(a),3,length(paramstr(a))-2));
        'E':if (length(paramstr(a))>=4) then begin
              d:=allcaps(paramstr(a));
              case d[3] of
                'E':exiterrors:=value(copy(d,4,length(d)-3));
                'N':exitnormal:=value(copy(d,4,length(d)-3));
              end;
            end;
        'K':localioonly:=TRUE;
        {'M':minitermonly:=TRUE;}
        'N':nightly:=TRUE;
        'P':packbasesonly:=TRUE;
        'Q':quitafterdone:=TRUE;
        'X':exteventtime:=atoi(copy(paramstr(a),3,length(paramstr(a))-2));
      end;
  end;

  textcolor(15); textbackground(1); gotoxy(1,2);
  tanim;
  gotoxy(6,10); writeln('Initializing file');
  textbackground(7); textcolor(0);
  gotoxy(6,11); repeat write(' ') until wherex>=76;
  textbackground(1);

  gotoxy(6,15); textcolor(14); write('Command parameters specified:');
  writeln;
  textcolor(15);
  if (paramcount=0) then wpar('None');
  if (exitnormal<>255) then wpar('Normal exit Errorlevel = '+cstr(exitnormal));
  if (exiterrors<>254) then wpar('Critical Error exit Errorlevel = '+cstr(exiterrors));
  if (nightly) then wpar('Execute Nightly Event');
  if (localioonly) then wpar('Local I/O ONLY');
  if (answerbaud>0) then wpar('Answer at '+cstr(answerbaud)+' baud');
  if (exteventtime>0) then wpar('External event in '+cstr(exteventtime)+' minute(s)');
  if (quitafterdone) then wpar('Quit after user logoff');
  {if (minitermonly) then wpar('MiniTerm only');}
  if (packbasesonly) then wpar('Pack message bases only');
  allowabort:=TRUE;
end;

procedure initp1;
var filv:text;
    {systatf:file of systatrec;}
    evf:file of eventrec;
    fstringf:file of fstringrec;
    modemrf:file of modemrec;
    fidorf:file of fidorec;
    fp:file;
    wind:windowrec;
    v:verbrec;
    sx,sy,numread,i:integer;
    errs,npatch:boolean;
    s:astr;

  procedure showmem;
  var i,p:longint;
  begin
exit;
    textbackground(1); textcolor(15); gotoxy(20,13);
    p:=40-(((40*memavail) div MaxHeapSpace)+1);
    for i:=1 to 40 do
      if (p>i+1) then begin
        inc(i); write('Û');
      end else
        if (p>i) then write('Ý');
    gotoxy(49,13); write(memavail,' bytes left');
  end;

  procedure show_initfile(s:astr);

    function nocaps(s:astr):astr;
    var i:integer;
    begin
      for i:=1 to length(s) do
        if (s[i] in ['A'..'Z']) then s[i]:=chr(ord(s[i])+32);
      nocaps:=s;
    end;

  begin
    textbackground(7); textcolor(0);
    gotoxy(6,11); repeat write(' ') until wherex>=76;
    gotoxy(6,11);
    if (copy(s,length(s),1)<>'!') then s:=systat.gfilepath+s
                                  else s:=copy(s,1,length(s)-1);

    {rcg11182000 this caps call is confusing with a case-sensitive filesystem.}
    {write(caps(s));}
    write(s);
    textbackground(1);
    showmem;
    errs:=FALSE; npatch:=FALSE;
  end;

  procedure openwmsgs;
  begin
    openedyet:=TRUE;
    setwindow(wind,6,15,75,23,15,1,7); clrscr;
    sx:=1; sy:=1;
  end;

  procedure wmsgs(s:astr);
  var x,y:integer;
  begin
  {rcg1118 this doesn't work without savescreen() and such in common.pas...}
  {
    x:=wherex; y:=wherey;
    if (not openedyet) then openwmsgs;
    textbackground(1); textcolor(15);
    window(8,16,73,22);
    gotoxy(sx,sy); writeln(s); sx:=wherex; sy:=wherey;
    window(1,1,80,25); gotoxy(x,y);
  }

        writeln('STUB: initp.pas; wmsgs(''' + s + ''')...');
  end;

  procedure inmsgs(sh:astr; var s:astr; len:integer);
  var x,y:integer;
  begin
    x:=wherex; y:=wherey;
    wmsgs(sh);
    textbackground(1); textcolor(15);
    window(8,16,73,22);
    gotoxy(sx,sy);
    infielde(s,len);
    window(1,1,80,25); gotoxy(x,y);
  end;

  function existdir(fn:astr):boolean;
  var srec:searchrec;
  begin
    {rcg11182000 dosism.}
    {while (fn[length(fn)]='\') do fn:=copy(fn,1,length(fn)-1);}
    while (fn[length(fn)]='/') do fn:=copy(fn,1,length(fn)-1);
    findfirst(fexpand(sqoutsp(fn)),anyfile,srec);
    existdir:=(doserror=0) and (srec.attr and directory=directory);
  end;
    
  procedure abend(s:astr);
  begin
    wmsgs('*'+s+'*  --  Aborting');
    window(1,1,80,25); gotoxy(1,24); delay(3000);
    halt(exiterrors);
  end;

  procedure findbadpaths;
  var s,s1,s2:astr;
      i:integer;
  begin
    infield_out_fgrd:=15;
    infield_out_bkgd:=1;
    infield_inp_fgrd:=0;
    infield_inp_bkgd:=7;

    with systat do
      for i:=1 to 8 do begin
        case i of 1:s1:='GFILES'; 2:s1:='MSGS'; 3:s1:='MENUS'; 4:s1:='TFILES';
                  5:s1:='AFILES'; 6:s1:='LOG'; 7:s1:='TEMP'; 8:s1:='SWAP';
        end;
        case i of
          1:s:=gfilepath;  2:s:=msgpath;
          3:s:=menupath;   4:s:=tfilepath;
          5:s:=afilepath;  6:s:=trappath;
          7:s:=temppath;   8:s:=swappath;
        end;
        if (not existdir(s)) then begin
          cursoron(TRUE);
          wmsgs('');
          wmsgs('');
          wmsgs(s1+' path is currently "'+s+'"');
          wmsgs('This path is bad or missing.');
          repeat
            wmsgs('');
            s2:=s; inmsgs('New '+s1+' path: ',s2,60); s2:=allcaps(sqoutsp(s2));
            if (s=s2) or (s2='') then abend('Illegal pathname error')
            else begin
              if (s2<>'') then
                {rcg11182000 dosism}
                {if (copy(s2,length(s2),1)<>'\') then s2:=s2+'\';}
                if (copy(s2,length(s2),1)<>'/') then s2:=s2+'/';
              if (existdir(s2)) then
                case i of
                  1:gfilepath:=s2;  2:msgpath:=s2;
                  3:menupath:=s2;   4:tfilepath:=s2;
                  5:afilepath:=s2;  6:trappath:=s2;
                  7:temppath:=s2;   8:swappath:=s2;
                end
              else begin
                wmsgs('');
                wmsgs('That path does not exist!');
              end;
            end;
          until (existdir(s2));
          cursoron(FALSE);
        end;
      end;
  end;

begin
  gotoxy(6,10); writeln('Initializing file');
  textbackground(7); textcolor(0);
  gotoxy(6,11); repeat write(' ') until wherex>=76;

  textbackground(1); textcolor(15);
  gotoxy(6,13); writeln('Record space ÞúúúúúúúúúúúúúúúúúúúúÝ');

  wantout:=TRUE;
  ldate:=daynum(date);
  ch:=FALSE; lil:=0; thisuser.pagelen:=20; buf:=''; chatcall:=FALSE;
  spd:=''; lastname:=''; ll:=''; chatr:=''; textcolor(0);
  cursoron(FALSE); textcolor(0);

(*
  show_initfile(start_dir+'\status.dat!');
  assign(systatf,'status.dat');
  {$I-} reset(systatf); {$I+}
  errs:=(ioresult<>0);
  if (errs) then begin
    wmsgs('Unable to find STATUS.DAT data file.  This file is absolutely');
    wmsgs('*REQUIRED* to even load the BBS.  If you cannot find your');
    wmsgs('STATUS.DAT data file, re-create one using the INIT package.');
    wmsgs('');
    delay(1000); abend('Cannot find STATUS.DAT');
  end else begin
    {$I-} read(systatf,systat); {$I+}
    errs:=(ioresult<>0);
    close(systatf);
  end;
*)

  {rcg11182000 DOSism.}
  {if (exist(start_dir+'\critical.err')) then begin      }
  {  assign(filv,start_dir+'\critical.err'); erase(filv);}

  if (exist(start_dir+'/critical.err')) then begin
    assign(filv,start_dir+'/critical.err'); erase(filv);
    wmsgs('*** Critical error during last BBS execution! ***');
    wmsgs('[>>> Updating STATUS.DAT <<<]');
    inc(systat.todayzlog.criterr);
    savesystat;
    wascriterr:=TRUE;
  end;

  findbadpaths;

  assign(fp,'msgtmp');
  {$I-} reset(fp); {$I+}
  if (ioresult=0) then begin close(fp); erase(fp); end;

  show_initfile(systat.trappath+'sysop.log!');
  assign(sysopf,systat.trappath+'sysop.log');
  {$I-} append(sysopf); {$I+}
  if (ioresult<>0) then begin
    wmsgs('Bad or missing SYSOP.LOG - creating...');
    rewrite(sysopf);
    writeln(sysopf);
  end;

  assign(sysopf1,systat.trappath+'slogxxxx.log');

  showmem;

  first_time:=TRUE;
  sl1(#3#7+'---------------> '+#3#5+'System booted on '+dat+#3#7+' <---------------');


  show_initfile('modem.dat');
  assign(modemrf,systat.gfilepath+'modem.dat');
  reset(modemrf); read(modemrf,modemr); close(modemrf);

  show_initfile('string.dat');
  assign(fstringf,systat.gfilepath+'string.dat');
  reset(fstringf); read(fstringf,fstring); close(fstringf);

  show_initfile('fidonet.dat');
  assign(fidorf,systat.gfilepath+'fidonet.dat');
  {$I-} reset(fidorf); {$I+}
  if (ioresult<>0) then begin
    wmsgs('Bad or missing FIDONET.DAT - creating...');
    rewrite(fidorf);
    with fidor do begin
      zone:=0; net:=0; node:=0; point:=0;
      for i:=1 to 50 do origin[i]:=chr(0);
      origin:=copy(stripcolor(systat.bbsname),1,50);
      text_color:=1; quote_color:=3; tear_color:=9; origin_color:=5;
      skludge:=TRUE; sseenby:=TRUE; sorigin:=FALSE;
      scenter:=TRUE; sbox:=TRUE; mcenter:=TRUE;
      for i:=1 to sizeof(res) do res[i]:=0;
    end;
    write(fidorf,fidor);
  end else read(fidorf,fidor);
  close(fidorf);

  show_initfile('names.lst');
  assign(sf,systat.gfilepath+'names.lst');
  {$I-} reset(sf); {$I+}
  if (ioresult<>0) then abend('Bad or missing NAMES.LST');
  close(sf);
  showmem;

  show_initfile('user.lst');
  assign(uf,systat.gfilepath+'user.lst');
  reset(uf);
  if (filesize(uf)>1) then begin
    seek(uf,1);
    read(uf,thisuser);
  end else
    thisuser.slogseperate:=FALSE;
  reset(sf);
  if (systat.numusers<>filesize(sf)) then begin
    wmsgs('User count does not match with names list - fixing...');
    wmsgs('(NAMEFIX should be used, just to be safe)');
    systat.numusers:=filesize(sf);
    savesystat;
  end;
(*  if (systat.numusers>filesize(uf)-1) then begin
    wmsgs('NAMES.LST does not match up with USER.LST');
    wmsgs('NAMEFIX should be ran!');
    sysoplog(#3#7+'NAMES.LST does not match up with USER.LST');
    sysoplog(#3#8+'NAMEFIX should be ran!');
  end;*)
  close(sf);
  close(uf);

(*  show_initfile('macro.lst');
  assign(macrf,systat.gfilepath+'macro.lst');
  {$I-} reset(macrf); {$I+}
  if (ioresult<>0) then begin
    wmsgs('Missing MACRO.LST - creating...');
    rewrite(macrf);
  end;
  close(macrf);*)

  show_initfile('verbose.dat');
  assign(verbf,systat.gfilepath+'verbose.dat');
  {$I-} reset(verbf); {$I+}
  if (ioresult<>0) then rewrite(verbf);
  close(verbf); reset(verbf);
  {$I-} seek(verbf,0); read(verbf,v); {$I+}
  if (ioresult<>0) then begin
    wmsgs('Bad or missing VERBOSE.DAT - creating...');
    rewrite(verbf);
    v.descr[1]:='';
    write(verbf,v);
  end;
  close(verbf);

  show_initfile('protocol.dat');
  assign(xf,systat.gfilepath+'protocol.dat');
  reset(xf); close(xf);

  show_initfile('events.dat');
  new(events[0]);
  with events[0]^ do begin
    active:=nightly;
    description:='Telegard Nightly Events';
    etype:='D';
    execdata:='night.bat';
    busytime:=15;
    exectime:=240;  {* 4:00am *}
    busyduring:=TRUE;
    duration:=1;
    execdays:=127;  {* SMTWTFS *}
    monthly:=FALSE;
  end;
  assign(fp,systat.gfilepath+'events.dat');
  assign(evf,systat.gfilepath+'events.dat');
  {$I-} reset(fp,1); {$I+}
  if (ioresult<>0) then begin
    wmsgs('Bad or missing EVENTS.DAT - creating...');
    rewrite(evf); numevents:=1; new(events[1]);
    with events[1]^ do begin
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
    write(evf,events[1]^);
  end else begin
    numevents:=0;
    repeat
      inc(numevents);
      new(events[numevents]);           (* DEFINE DYNAMIC MEMORY! *)
      blockread(fp,events[numevents]^,sizeof(eventrec),numread);
      if ((numread<>sizeof(eventrec)) and (numread<>0)) then npatch:=TRUE;
      showmem;
    until (numread<>sizeof(eventrec)) or (eof(fp));
  end;
  close(fp);
  if (npatch) then begin
    wmsgs('Errors in EVENTS.DAT - patching...');
    rewrite(evf);
    for i:=1 to numevents do write(evf,events[i]^);
    close(evf);
  end;

  show_initfile('boards.dat');
  assign(fp,systat.gfilepath+'boards.dat');
  assign(bf,systat.gfilepath+'boards.dat');
  reset(fp,1); numboards:=0;
  repeat
    inc(numboards);
    blockread(fp,memboard,sizeof(boardrec),numread);
    if ((numread<>sizeof(boardrec)) and (numread<>0)) then npatch:=TRUE;
    showmem;
  until (numread<>sizeof(boardrec)) or (eof(fp));
  close(fp);
  if (npatch) then
    wmsgs(^G'Errors in BOARDS.DAT - run FIX for BOARDS.DAT...'^G);

  show_initfile('uploads.dat');
  assign(fp,systat.gfilepath+'uploads.dat');
  assign(ulf,systat.gfilepath+'uploads.dat');
  reset(fp,1); maxulb:=-1;
  repeat
    inc(maxulb);
    blockread(fp,memuboard,sizeof(ulrec),numread);
    if ((numread<>sizeof(ulrec)) and (numread<>0)) then npatch:=TRUE;
    showmem;
  until (numread<>sizeof(ulrec)) or (eof(fp));
  close(fp);
  if (npatch) then
    wmsgs(^G'Errors in UPLOADS.DAT - run FIX for UPLOADS.DAT...'^G);

(*  show_initfile('email.dat');
  assign(mailfile,systat.gfilepath+'email.dat');*)

  show_initfile('shortmsg.dat');
  assign(smf,systat.gfilepath+'shortmsg.dat');

{  show_initfile(systat.trappath+'chat.msg!');
  assign(cf,systat.trappath+'chat.msg');}
  cfo:=FALSE;

  if (openedyet) then removewindow(wind);
  textbackground(0); textcolor(7); clrscr;
end;

procedure init;
var rcode:integer;
begin
  if (daynum(date)=0) then begin
    clrscr;
    writeln('Please set the date & time, it is required for operation.');
    halt(exiterrors);
  end;

  hangup:=FALSE; incom:=FALSE; outcom:=FALSE;
  echo:=TRUE; doneday:=FALSE;
  checkbreak:=FALSE;
  slogging:=TRUE; trapping:=FALSE;
  readingmail:=FALSE; sysopon:=FALSE; inmsgfileopen:=FALSE;
  beepend:=FALSE;
  wascriterr:=FALSE;
  checksnow:=systat.cgasnow;
  directvideo:=not systat.usebios;

  readp; initp1;

(*  setuprs232(modemr.comport,4,0,8,1);
  installint(modemr.comport); {installint(2);}*)
  iport;

  if (exist('bbsstart.bat')) then shelldos(FALSE,'bbsstart.bat',rcode);
end;

end.
