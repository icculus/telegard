(*****************************************************************************)
(*>                                                                         <*)
(*>  WFCMENU .PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  Waiting For Caller menu.  Allows SysOp to use SysOp functions, see     <*)
(*>  various status reports, and log on locally.                            <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit wfcmenu;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  initp,

  sysop1, sysop2, sysop3, sysop4, sysop5, sysop6,
  sysop7, sysop8, sysop9, sysop10, sysop11,

  mail0, mail1, mail2, mail3, mail4, mail5, mail6, mail9,

  file0, file1, file2, file4, file5, file6,
  file7, file8, file9, file10, file11, file12,
  archive1, archive2,

  {logon1, logon2,} misc1, misc2, misc3, miscX,

  cuser, doors,

  {miniterm,}

  tmpcom,
  mmodem,

  menus2, msgpack,
  {window2,} myio, common, logon1, logon2, newusers;

procedure wfcmdefine;
procedure hangupphone;
procedure wfcmenus(wanthangup:boolean);

implementation

var
  lactive:real;
  blankmenunow:boolean;
  lastkeypress:datetimerec;

procedure wfcmdefine;
var macrf:file of macrorec;
    i:integer;
begin
  etoday:=0; ptoday:=0; ftoday:=0; chatt:=0; shutupchatcall:=FALSE;
  flistverb:=TRUE; contlist:=FALSE; badfpath:=FALSE;

  cwindowon:=FALSE;
  telluserevent:=0;
  fastlogon:=FALSE;
  fileboard:=1; board:=1;
  readuboard:=-1; readboard:=-1;
  inwfcmenu:=TRUE;
  lmsg:=FALSE; wantfilename:=FALSE;
  nopfile:=FALSE; doitt:=FALSE; enddayf:=FALSE;
{  close(sysopf); append(sysopf);}
  reading_a_msg:=FALSE;
  mailread:=FALSE; smread:=FALSE; checkit:=FALSE;
  outcom:=FALSE; useron:=FALSE; ll:=''; chatr:=''; buf:='';
  hangup:=FALSE; usernum:=1; chatcall:=FALSE; hungup:=FALSE;
	textbackground(0); clrscr; pap:=0;
  lactive:=timer;
  reset(uf);
  if (filesize(uf)>1) then begin
    seek(uf,1); read(uf,thisuser);
    close(uf);
    newcomptables;
    usernum:=1;
    readinmacros; readinzscan;
  end else begin
    close(uf);
    with thisuser do begin
      linelen:=80; pagelen:=25;
      ac:=[onekey,pause,novice,ansi,color];
      ac:=ac-[avatar];
    end;
  end;
end;

procedure getcallera(var c:char; var chkcom:boolean);
var rl,rl1:real;
    s:astr;

  procedure getresultcode(rs:astr);
  var i,j:integer;
  begin
    with systat do
      for i:=1 to 2 do begin
        spdarq:=(i=2);
        for j:=0 to 4 do
          if (modemr.resultcode[i][j]<>0) and
             (value(rs)=modemr.resultcode[i][j]) then begin
            case j of
              0:spd:='300'; 1:spd:='1200'; 2:spd:='2400';
              3:spd:='4800';
              4:begin
                  if (not spdarq) then spd:='9600'
                    else spd:=cstrl(modemr.arq9600rate);
                end;
            end;
            chkcom:=TRUE;
            exit;
          end;
      end;
  end;
      
  procedure wmb(s:astr);
  begin
    textcolor(14); write(s[1]);
    textcolor(12); write(copy(s,2,length(s)-1));
  end;

begin
  if (chkcom) then begin
    if (recom1(c)) then ;
    cwr(1); cwr(2); wr(2,c);
    if (c='2') then begin
      chkcom:=TRUE; rl:=timer;
      while (c<>#13) and (abs(rl-timer)<0.2) do begin
        c:=ccinkey1;
        wr(2,c);
      end;
    end;
    if (chkcom) then begin
      if (not returna) then begin
        com_flush_rx;
        if (answerbaud=0) then outmodemstring(modemr.answer);
      end;
      if (sysopon) then cursoron(TRUE);
      gotoxy(1,24); tc(12); clreol;
      write(' Answering phone...');
      if (sysopon) then begin
        write(' Force- ');
        wmb('300 '); wmb('1200 '); wmb('2400 '); wmb('4800 ');
        wmb('9600 '); wmb('A19200 '); wmb('B38400 '); wmb('Hang up');
      end;
      gotoxy(1,24); tc(3);
      delay(50); com_flush_rx; rl1:=timer; s:=''; rl:=0.0;
      repeat
        chkcom:=FALSE;
        if (answerbaud>2) then begin
          spd:=cstr(answerbaud);
          chkcom:=TRUE;
          answerbaud:=0;
        end;
        if (keypressed) then begin
          c:=upcase(readkey);
          if (c='H') then begin
            cwr(1); wr(1,'A');
            chkcom:=TRUE;
            pr('A');
            delay(200);
            com_flush_rx;
          end;
          case c of
            '3':spd:='300';
            '1':spd:='1200';
            '2':spd:='2400';
            '4':spd:='4800';
            '9':spd:='9600';
            'A':spd:='19200';
            'B':spd:='38400';
          end;
          chkcom:=TRUE;
        end;
        c:=ccinkey1;
        if (rl<>0.0) and (abs(rl-timer)>2.0) and (c=#0) then c:=#13;
        if (c<#32) and (c<>#13) then c:=#0;
        if c<>#0 then
          if c<>#13 then begin
            cwr(2);
            s:=s+c;
            wrs(2,s);
            rl:=timer;
          end else begin
            if (s=cstr(modemr.nocarrier)) then chkcom:=TRUE;
            getresultcode(s);
            rl:=0.0;
          end;
        if (c=#13) then s:='';
        if (abs(timer-rl1)>45.0) then chkcom:=TRUE;
      until chkcom;
      if (abs(timer-rl1)>45.0) then begin c:='X'; lmsg:=TRUE; end;
      clrscr;
    end;
    if (spd<>'KB') then incom:=TRUE;
  end;
end;

procedure wfcmenu1;
var wfcimagef:file of windowrec;
    wfcwindow,wfcwindow0:windowrec;
    dfr,fdt1,fdt2:longint;
    h,i,j:integer;
    ww,regenerated:boolean;

  procedure tcenter(i:astr);
  var p,x,y:integer;
  begin
    p:=40-(length(i) div 2);
    x:=wherex; y:=wherey;
    x:=p;
    gotoxy(x,y);
    writeln(i);
  end;

  procedure logo(i:integer);
  begin
    tc(11); gotoxy(20,1+i);
    write('€ﬂﬂ€ €ﬂﬂﬂ ﬂ€ﬂ   €ﬂﬂﬂ €ﬂﬂﬂ €ﬂﬂ€ €ﬂﬂ€ €ﬂﬂ‹');
    tc(9); gotoxy(20,2+i);
    write('€    €ﬂﬂ   €    €ﬂﬂ  € ﬂ€ €ﬂﬂ€ €ﬂ€ﬂ €  €');
    tc(1); gotoxy(20,3+i);
    write('€‹   €‹‹‹  €‹‹€ €‹‹‹ €‹‹€ €  € €  € €‹‹ﬂ');
    gotoxy(1,4+i); clreol;
  end;

  procedure logoco(c:integer);
  begin
    if c<>2 then tc(9) else tc(11);
    if c<>1 then textbackground(0) else textbackground(1);
  end;

  procedure showlogo(anim:boolean);
  var i:integer;
  begin
    gotoxy(1,1); logoco(0); write(' ƒƒƒƒƒ'); logoco(1); write('‹‹‹‹‹‹‹‹‹‹'); logoco(2); write('€ﬂ');
    gotoxy(1,2); logoco(0); write('ƒƒƒƒ'); logoco(1); write('‹‹‹‹‹‹‹‹‹‹‹‹'); logoco(2); write('› ');
    gotoxy(1,3); logoco(0); write(' ƒƒƒƒƒ'); logoco(1); write('‹‹‹‹‹‹‹‹‹‹'); logoco(2); write('€‹');
    gotoxy(62,1); logoco(2); write('ﬂ€'); logoco(1); write('‹‹‹‹‹‹‹‹‹‹'); logoco(0); write('ƒƒƒƒƒ');
    gotoxy(62,2); logoco(2); write(' ﬁ'); logoco(1); write('‹‹‹‹‹‹‹‹‹‹‹‹'); logoco(0); write('ƒƒƒƒ');
    gotoxy(62,3); logoco(2); write('‹€'); logoco(1); write('‹‹‹‹‹‹‹‹‹‹'); logoco(0); write('ƒƒƒƒƒ ');

    if (anim) then for i:=22 downto 0 do logo(i) else logo(0);

    gotoxy(1,4);
    tc(14); tcenter(verline(1));
    tc(11); tcenter(verline(2));
  end;

  procedure dot(x,y:integer);
  begin
    gotoxy(x,y);
    write('˛');
  end;

  function datene(fn,dn:astr):boolean;
  var f:file;
  begin
    datene:=TRUE;
    if (exist(systat.afilepath+fn)) then fn:=systat.afilepath+fn else
      if (exist(systat.gfilepath+fn)) then fn:=systat.gfilepath+fn else
        exit;
    assign(f,fn); {$I-} reset(f); {$I+} if (ioresult<>0) then exit;
    getftime(f,fdt1);
    close(f);
    assign(f,dn); {$I-} reset(f); {$I+} if (ioresult<>0) then exit;
    getftime(f,fdt2);
    close(f);
    datene:=(fdt1<>fdt2);
  end;

begin
	window(1,1,80,25); cursoron(FALSE);  clrscr;
  if (not blankmenunow) then begin
    ww:=wantout; wantout:=TRUE;
    if (datene('sysfunc.ans',systat.gfilepath+'sysfunc.dat')) then begin
      clrscr; printf('sysfunc.ans');
      if (nofile) then writeln('NONE AVAILABLE --- SYSFUNC.ANS NOT FOUND');
      savescreen(wfcwindow,1,1,80,25);
      assign(wfcimagef,systat.gfilepath+'sysfunc.dat');
      rewrite(wfcimagef); write(wfcimagef,wfcwindow);
      setftime(wfcimagef,fdt1); close(wfcimagef);
			clrscr;
		end;

    if ((sysopon) and (systat.usewfclogo)) then showlogo(systat.specialfx);

    regenerated:=FALSE;

    if (not sysopon) then
      if (not datene('wfcmenu0.ans',systat.gfilepath+'wfcmenu0.dat')) then begin
        assign(wfcimagef,systat.gfilepath+'wfcmenu0.dat');
        reset(wfcimagef); {$I-} read(wfcimagef,wfcwindow); {$I+}
        close(wfcimagef);
      end else begin
        printf('wfcmenu0.ans');
        if (nofile) then begin
          gotoxy(1,15); writeln('NONE AVAILABLE --- WFCMENU0.ANS NOT FOUND');
        end;
        savescreen(wfcwindow,1,1,80,25);
        assign(wfcimagef,systat.gfilepath+'wfcmenu0.dat');
        rewrite(wfcimagef); write(wfcimagef,wfcwindow);
        setftime(wfcimagef,fdt1); close(wfcimagef);
        regenerated:=TRUE;
      end
    else
      if (not datene('wfcmenu.ans',systat.gfilepath+'wfcmenu.dat')) then begin
        assign(wfcimagef,systat.gfilepath+'wfcmenu.dat');
        reset(wfcimagef); {$I-} read(wfcimagef,wfcwindow); {$I+}
        close(wfcimagef);
      end else begin
        printf('wfcmenu.ans');
        if (nofile) then begin
          gotoxy(1,15); writeln('NONE AVAILABLE --- WFCMENU.ANS NOT FOUND');
        end;
        if (systat.usewfclogo) then savescreen(wfcwindow,1,6,80,25)
          else savescreen(wfcwindow,1,1,80,25);
        assign(wfcimagef,systat.gfilepath+'wfcmenu.dat');
        rewrite(wfcimagef); write(wfcimagef,wfcwindow);
        setftime(wfcimagef,fdt1); close(wfcimagef);
        regenerated:=TRUE;
      end;
    removewindow(wfcwindow);
    if ((regenerated) and (systat.usewfclogo) and (sysopon)) then
      showlogo(FALSE);

    gotoxy(1,20);
    wantout:=ww;

    if (sysopon) then begin
      with systat.todayzlog do begin
        tc(3);
        gotoxy(35,20); write(cstr(downloads)+'-'+cstr(dk)+'k');
        gotoxy(35,21); write(cstr(uploads)+'-'+cstr(uk)+'k');
        gotoxy(59,20); write(active/14.4:1:1,'% ('+cstr(calls)+' calls)');
        gotoxy(59,21); dfr:=freek(0);
                       if (dfr<systat.minspaceforupload) then tc(28);
                       if (dfr<systat.minspaceforpost) then tc(31);
                       write(cstrl(dfr)+'k'); tc(3);
      end;
    end;

    textcolor(3); gotoxy(1,22);
  end;
end;

procedure hangupphone;
begin
  dophonehangup(TRUE);
end;

procedure optimize_mail;
var x:smr;
    s,d:integer;
begin
  if (smread) then begin
    {$I-} reset(smf); {$I+}
    if (ioresult=0) then begin
      if (filesize(smf)>1) then begin
        s:=0; d:=0;
        while (s<filesize(smf)) do begin
          seek(smf,s); read(smf,x);
          if (x.destin<>-1) then
            if (s=d) then inc(d) else begin
              seek(smf,d); write(smf,x);
              inc(d);
            end;
          inc(s);
        end;
        seek(smf,d);
        truncate(smf);
      end;
      close(smf);
    end;
  end;
end;

procedure wfcmenus(wanthangup:boolean);
var u:userrec;
    x:smr;
    lcallf:file of lcallers;
    lcall:lcallers;
    dt,ddt:datetimerec;
    ltime,s,wfcmessage,lcaller:astr;
    rr,rl,rl1,rl2,lastinit:real;
    duh,duh2,txt,txt1,txt2,i,j,k,sk,rcode:integer;
    c,c1:char;
    nogoodcmd,wfcm,phoneoffhook,chkcom,tdoneafternext,oldphoneoffhook:boolean;
    sysopfo:boolean;

  procedure i1;
  var s:astr;
      rl,rl1:real;
      try:integer;
      c,isc:char;
      done:boolean;
  begin
    if ((modemr.init<>'') and (answerbaud=0) and (not localioonly)) then begin
      gotoxy(1,24); tc(12); clreol; write('Initializing modem...');
      if (not keypressed) then begin
        c:=#0; s:=''; done:=FALSE; try:=0;
        rl:=timer;

        while (keypressed) do c:=readkey;

        repeat
          cwr(1); cwr(2);

          com_set_speed(modemr.waitbaud);
          outmodemstring1(modemr.init);
          com_flush_rx;

          rl1:=timer;
          repeat
            if (recom1(c)) then begin
              if (c in ['0',^M]) then done:=TRUE;
              if (c in [#32..#255]) then wr(2,c);
            end;
          until ((abs(timer-rl1)>2.5) or (done)) or (keypressed);
          if (done) then delay(100);
          inc(try);
          if (try>10) then done:=TRUE;
        until ((done) or (keypressed));
      end;
      while (keypressed) do isc:=readkey;
      delay(100); com_flush_rx;
      rl1:=timer; repeat c:=ccinkey1 until (abs(timer-rl1)>0.1);

      tc(11);
      gotoxy(1,24); clreol;
      gotoxy(1,25); clreol;
    end;
    phoneoffhook:=FALSE;
    wfcmessage:='';
    lastinit:=timer;
    while (keypressed) do c:=readkey;
    com_flush_rx;
  end;

  procedure update_logo(txt:integer);
  var lin:integer;
       gr:string[12];
     c1,c2,c3:integer;
  begin
    if (txt and 1<>1) then begin
      txt2:=txt2 mod 7+1;
      c1:=txt2; c2:=txt2 mod 7+1; c3:=c2 mod 7+1;
      gotoxy(19,1); tc(8+c1); write(' €ﬂ€ﬂ€ €ﬂﬂﬂ ﬂ€ﬂ   €ﬂﬂﬂ €ﬂﬂﬂ €ﬂﬂ€ €ﬂﬂ€ €ﬂﬂ‹ ');
      gotoxy(19,2); tc(8+c2); write('   €   €ﬂﬂ   €    €ﬂﬂ  € ﬂ€ €ﬂﬂ€ €ﬂ€ﬂ €  € ');
      gotoxy(19,3); tc(8+c3); write('  ‹€‹  €‹‹‹  €‹‹€ €‹‹‹ €‹‹€ €  € €  € €‹‹ﬂ ');
    end;
  end;

  function cpw:boolean;
  var i:astr;
  begin
    if (not sysopon) then begin
      tc(8); write('Sysop PW? '); tc(1);
      echo:=FALSE;
      input(i,20);
      echo:=TRUE;
      clrscr;
      cpw:=(i=systat.sysoppw);
    end
    else cpw:=TRUE;
  end;

  procedure takeoffhook;
  begin
    if (not localioonly) then begin
      dophoneoffhook(TRUE);
      phoneoffhook:=TRUE;
      wfcmessage:='Phone off hook';
    end;
  end;

  procedure beephim;
  var rl,rl1:real; ch:char;
  begin
    takeoffhook;
    beepend:=FALSE;
    rl:=timer;
    repeat
      sound(1500); delay(20);
      sound(1000); delay(20);
      sound(800); delay(20);
      nosound;
      rl1:=timer;
      while (abs(rl1-timer)<0.9) and (not keypressed) do;
    until (abs(rl-timer)>30.0) or (keypressed);
    if keypressed then ch:=readkey;
    i1;
  end;

  procedure packallbases;
  var b:boolean;
  begin
    clrscr;
    b:=(pause in thisuser.ac);
    thisuser.ac:=thisuser.ac-[pause];
    doshowpackbases;
    if (b) then thisuser.ac:=thisuser.ac+[pause];
    clrscr; wfcm:=FALSE;
    sysoplog('Packed the message bases');
  end;

  procedure chkevents;
  var i,rcode:integer;
  begin
    if (checkevents(0)<>0) then
      for i:=0 to numevents do begin
        if (checkpreeventtime(i,0)) then
          if (not phoneoffhook) then begin
            takeoffhook;
            wfcmessage:='Phone off hook in preparation for event at '+
                        copy(ctim(events[i]^.exectime),4,5)+':00';
          end;
        if (checkeventtime(i,0)) then
          with events[i]^ do begin
            i1;
            if (busyduring) then takeoffhook;
            clrscr; write('<<< '+copy(ctim(exectime),4,5)+':00 >>> - Event: ');
            writeln('"'+description+'"');
            sl1('');
            sl1('[> Ran Event "'+description+'" on '+date+' '+time);
            case etype of
              'D':begin
                    sysopfo:=(textrec(sysopf).mode<>fmclosed);
                    if (sysopfo) then close(sysopf);
                    cursoron(TRUE);
                    shelldos(FALSE,execdata,rcode);
                    cursoron(FALSE);
                    if (sysopfo) then append(sysopf);
                    sl1('[> Returned from "'+description+'" on '+date+' '+time);
                    clrscr;
                    delay(1000);
                    outmodemstring1(modemr.hangup);
                    delay(300);
                    i1;
                    wfcm:=FALSE;
                  end;
              'E':begin
                    cursoron(TRUE);
                    doneday:=TRUE;
                    elevel:=value(execdata);
                  end;
              'P':begin
                    packallbases;
                    i1;
                  end;
            end;
          end;
      end;
  end;

  procedure closemenu;
  begin
    if (systat.localscreensec) then wantout:=FALSE;
    sysopon:=FALSE; sk:=0;
    wfcm:=FALSE;
  end;

  procedure showstats;
  var dfree:array[1..26] of longint;
      s:astr;
      i,ll,x,y:longint;
      abort,next:boolean;

    procedure wl(s1,s2:astr);
    begin
      printacr(#3#3+mln(s1,20)+':'+#3#5+s2,abort,next);
    end;

  begin
    for i:=1 to 26 do dfree[i]:=-1;
    reset(ulf); seek(ulf,0);
    for i:=0 to filesize(ulf)-1 do begin
      read(ulf,memuboard);
      x:=exdrv(memuboard.dlpath);
      dfree[x]:=1;
    end;
    close(ulf);
    x:=0;
    for i:=3 to 26 do if (dfree[i]<>-1) then inc(x);
    if (x<>0) then for i:=1 to 2 do dfree[i]:=-1;
    for i:=1 to 26 do
      if (dfree[i]=1) then dfree[i]:=freek(i);

    abort:=FALSE; next:=FALSE;

    with systat do begin
      wl('System is',aonoff(closedsystem,
                     'Rejecting new users','Accepting new users'));
      wl('Shuttle Logon is',aonoff(shuttlelog,'Active','Inactive'));
      s:='';
      if (localsec) then s:='Local security';
      if (localscreensec) then
        if (s='') then s:='Local screen security' else s:=s+' + Screen security';
      if (s='') then s:='None';
      wl('Security features',s);
      wl('Global trapping',aonoff(globaltrap,#3#0+'*ON*','Off'));
      wl('Number of callers',cstr(callernum));
      wl('Number of users',cstr(numusers-1));
      wl('Active today',sqoutsp(ctp(todayzlog.active,1440))+' ('+cstr(todayzlog.calls)+' calls)');
      s:='';
      if (todayzlog.pubpost<>0) then begin
        s:=cstr(todayzlog.pubpost)+' public post';
        if (todayzlog.pubpost<>1) then s:=s+'s';
      end;
      if (todayzlog.privpost<>0) then begin
        if (s<>'') then s:=s+', ';
        s:=s+cstr(todayzlog.privpost)+' private mail';
      end;
      if (todayzlog.fback<>0) then begin
        if (s<>'') then s:=s+', ';
        s:=s+cstr(todayzlog.fback)+' feedback';
      end;
      wl('Mail activity',s);
      wl('New users today',cstr(todayzlog.newusers));
      wl('SysOp is',aonoff(sysop,'Available','Not here'));
      wl('Space req. for ULs',cstr(minspaceforupload)+'k');
      wl('Space req. for posts',cstr(minspaceforpost)+'k');
      for i:=1 to 26 do
        if (dfree[i]<>-1) then begin
          x:=dfree[i]; y:=disksize(i); y:=y div 1024;
          s:=cstrl(x)+'k of '+cstrl(y)+'k';
          if (x<minspaceforupload) then s:=#3#8+s;
          if (x<minspaceforpost) then s:=#3#8+'*** '+s;
          wl('Disk space on '+chr(i+64),s);
        end;
      wl('Overlay read from',aonoff(overlayinems,'EMS','Disk'));
      wl('Comm driver in use',aonoff(usefossil,'FOSSIL','Internal'));
      nl;
    end;
  end;

  procedure wfcbat(i:integer);
  var wind:windowrec;
      s:string;
      t:real;
      xx,yy,z,ret:integer;
  begin
    xx:=wherex; yy:=wherey; z:=textattr;
    getdir(0,s);
    chdir(start_dir);
    savescreen(wind,1,1,80,25);
    t:=timer;
    shelldos(FALSE,'wfcbat'+chr(i+48),ret);
    getdatetime(tim);
    com_flush_rx;
    freetime:=freetime+timer-t;
    removewindow(wind);
    chdir(s);
    gotoxy(xx,yy); textattr:=z;
  end;

begin
  if (not systat.localsec) then sysopon:=TRUE;
  getdatetime(lastkeypress); blankmenunow:=FALSE;
  wantout:=not systat.localscreensec;
  sk:=0; duh:=0; duh2:=0; txt:=0; txt1:=0; txt2:=0;
  nogoodcmd:=FALSE;
  if (wanthangup) then begin
    hangupphone;
    wanthangup:=FALSE;
  end;
  optimize_mail;
  wfcmdefine;
  wfcmenu1; wfcm:=TRUE;

  iport;
  term_ready(TRUE);
  i1;

  assign(lcallf,systat.gfilepath+'laston.dat');
  {$I-} reset(lcallf); {$I+}
  if (ioresult=0) then begin
    lcall.callernum:=-1; i:=0;
    seek(lcallf,0);
    while ((i<10) and (lcall.callernum=-1)) do begin
      read(lcallf,lcall);
      inc(i);
    end;
    lcaller:=lcall.name+' #'+cstr(lcall.number);
    close(lcallf);
  end else
    lcaller:='No one.';

  tdoneafternext:=doneafternext;
  if (not systat.localsec) then sysopon:=TRUE;
  repeat
    if (beepend) then wfcmessage:='Phone off hook - paging System Operator';
    if (tdoneafternext) then wfcmessage:='Not answering any more calls.';
    if (not wfcm) and (lmsg) then lmsg:=FALSE;
    if (not wfcm) then begin
      wfcmenu1;
      wfcm:=TRUE;
    end;
    if (daynum(date)<>ldate) then
      if (daynum(date)-ldate)=1 then inc(ldate)
      else begin
        clrscr;
        star('Date corrupted.');
        halt(1);
      end;
    randomize; incom:=FALSE; outcom:=FALSE; trm:=FALSE; fastlogon:=FALSE;
    hangup:=FALSE; hungup:=FALSE; irt:=''; lastname:=''; macok:=TRUE; cfo:=FALSE;
    spd:='KB'; c:=#0; chkcom:=FALSE; freetime:=0.0; extratime:=0.0; choptime:=0.0;
    sdc; bread:=0; lil:=0; cursoron(FALSE);

    textbackground(0);

    if ((systat.specialfx) and (not blankmenunow) and
        (sysopon) and (systat.usewfclogo)) then begin
      inc(duh);
      if (duh=30) then begin
        duh:=0; inc(txt); if (txt>5) then txt:=0;
        update_logo(txt);
      end;
    end;
    tc(3);
    if ((not blankmenunow) and (systat.wfcblanktime>0)) then begin
      getdatetime(dt);
      timediff(ddt,lastkeypress,dt);
      if (ddt.min>=systat.wfcblanktime) then begin
        blankmenunow:=TRUE;
        clrscr;
      end;
    end;
    if (ltime<>time) then begin
      ltime:=time;
      inc(sk);
      if (timer-lastinit>modemr.nocallinittime*60) then begin
        lastinit:=timer;
        if (not phoneoffhook) then i1;
      end;
    end;
    rr:=timer;
    if (rr-lactive<0.0) then rr:=rr+(24.0*60*60);
    rr:=rr-lactive;
    if (sysopon) then begin
      if (not blankmenunow) then begin
        gotoxy(10,20);
        write(date+' '+time);
      end;
      if (doneafternext) then begin tc(30); write('*D*'); tc(3); end
        else write('   ');
      if (not blankmenunow) then begin
        gotoxy(10,21);
        if (nomail in thisuser.ac) then begin
          tc(28); write('Box closed!!'); tc(3);
        end else
          if (thisuser.waiting=0) then write('None')
          else begin
            tc(10);
            write(cstr(thisuser.waiting)+' letter');
            if (thisuser.waiting>1) then write('s');
            tc(3);
          end;
        gotoxy(16,22); write(ctim(rr)+' ago.');
        gotoxy(43,22); write(lcaller);
      end;
      if (sk=30) and (systat.localsec) then closemenu;
    end;
    if (nightly) or (numevents>=1) then chkevents;
    gotoxy(2,25); clreol;

    if (wfcmessage<>'') then begin
      textcolor(12); write('˛˛ '); textcolor(14); write(wfcmessage);
      textcolor(12); write(' ˛˛');
    end;
    if (beepend) then beephim;
    if (tdoneafternext) then begin
      takeoffhook;
      elevel:=exitnormal;
      hangup:=TRUE;
      doneday:=TRUE;
      clrscr;
    end;

    if (lmsg) then begin
      lmsg:=FALSE;
      wfcm:=FALSE;
    end;
    if (answerbaud>2) then begin
      c:='A';
      chkcom:=TRUE;
    end;
    if (returna) then begin
      returna:=FALSE;
      c:='A';
      chkcom:=TRUE;
    end else
      if (answerbaud=0) then c:=inkey;
    if (c<>#0) then begin
      if (blankmenunow) then begin
        blankmenunow:=FALSE;
        window(1,1,80,25); clrscr; wfcmenu1;
        getdatetime(lastkeypress);
      end;

      wfcm:=FALSE;
      cursoron(TRUE); gotoxy(2,24); tc(3);
      c:=upcase(c);

      if (not sysopon) then
        case c of
          'Q':begin
                elevel:=exitnormal;
                hangup:=TRUE;
                doneday:=TRUE;
              end;
          ' ':begin
                sysopon:=cpw;
                if (sysopon) then wantout:=TRUE;
                c:=#1;
              end;
          else
              nogoodcmd:=TRUE;
        end
      else begin
        sk:=0;
        textattr:=thisuser.cols[color in thisuser.ac][1];
        curco:=thisuser.cols[color in thisuser.ac][1];
        case c of
           ^C:closemenu;
          'H','+':
              begin
                i1;
                nogoodcmd:=TRUE;
              end;
          '!':begin
                clrscr;
                minidos;
              end;
          '0'..'9':wfcbat(ord(c)-48);
          'A':chkcom:=TRUE;
          'B':if cpw then boardedit;
          'C','/':begin clrscr; printfile(systat.gfilepath+'user.log'); pausescr; end;
          'D':SysopShell(FALSE);
          'E':if cpw then eventedit;
          'F':if cpw then dlboardedit;
          'G':if cpw then tfileedit;
          'I':if cpw then initvotes;
          'K':begin
                clrscr;
                if (pynq('Do you REALLY want to pack the message bases? '))
                  then doshowpackbases;
              end;
          'L':begin
                clrscr;
                showlogs;
                nl; pausescr;
              end;
          'M':if cpw then begin clrscr; mailr; end;
          'N':if cpw then tedit1;
          'O':begin
                if (not phoneoffhook) then takeoffhook else i1;
                nogoodcmd:=TRUE;
              end;
          'P':if cpw then changestuff;
          'Q':begin elevel:=exitnormal; hangup:=TRUE; doneday:=TRUE; end;
          'R':if cpw then begin
                clrscr;
                reset(uf); seek(uf,1); write(uf,thisuser); close(uf);
                write('Read which user''s mail? '); finduser(s,i);
                writeln;
                if (i<1) then pausescr
                else begin
                  usernum:=i;
                  reset(uf); seek(uf,i); read(uf,thisuser); close(uf);
                  readinmacros; readinzscan;
                  if (thisuser.waiting<>0) then begin
                    clrscr;
                    macok:=TRUE; readmail; macok:=FALSE;
                    reset(uf); seek(uf,i); write(uf,thisuser); close(uf);
                  end else begin
                    writeln('You have no mail waiting.');
                    writeln;
                    pausescr;
                  end;
                  usernum:=1;
                  reset(uf); seek(uf,1); read(uf,thisuser); close(uf);
                  readinmacros; readinzscan;
                end;
              end;
          'S':begin
                clrscr;
                showstats;
                pausescr;
              end;
          'T':if (exist('term.bat')) then begin
                clrscr; textcolor(14); write('Running TERM.BAT ....');
                writeln;
                sl1('');
                sl1('[> Ran terminal package at '+date+' '+time);
                shelldos(FALSE,'term.bat',rcode);
                sl1('[> Returned from "TERM.BAT" at '+date+' '+time);
                chdir(start_dir);
                clrscr;
                i1;
(*
              end else begin
                term;
{                iport;}
                if (not returna) then i1;
*)
              end;
          'U':if cpw then begin clrscr; uedit1; end;
          'V':if cpw then begin
                clrscr;
                voteprint;
                printfile(systat.afilepath+'votes.txt');
                pausescr;
              end;
          'W':if cpw then begin
                clrscr;
                reset(uf); seek(uf,1); write(uf,thisuser); close(uf);
                write('Which user is sending mail? '); finduser(s,i);
                writeln;
                if (i<1) then pausescr
                else begin
                  usernum:=i;
                  reset(uf); seek(uf,i); read(uf,thisuser); close(uf);
                  readinmacros; readinzscan;
                  macok:=TRUE; smail(pynq('Send mass mail? ')); macok:=FALSE;
                  nl; pausescr;
                  usernum:=1;
                  reset(uf); seek(uf,1); read(uf,thisuser); close(uf);
                  readinmacros; readinzscan;
                end;
              end;
          'X':if cpw then exproedit;
          'Z':begin clrscr; zlog; pausescr; end;
          '#':if cpw then menu_edit;
          ' ':begin
                oldphoneoffhook:=phoneoffhook;
                if (systat.offhooklocallogon) then takeoffhook;
                gotoxy(2,24);
                cwrite(#3#3+'Log on? ('+#3#11+'Y'+#3#3+'/'+#3#11+'N'+
                       #3#3+'-'+#3#11+'F'+#3#3+'ast) : ');
                rl2:=timer;
                while (not keypressed) and (abs(timer-rl2)<30.0) do;
                if (keypressed) then c:=readkey else c:='N';
                c:=upcase(c); writeln(c);
                case c of
                  'F':begin
                        fastlogon:=TRUE;
                        c:=' ';
                      end;
                  'Y':c:=' ';
                else
                      c:='@';
                end;
                if (c='@') then begin
                  gotoxy(2,24); clreol;
                  if ((systat.offhooklocallogon) and (not oldphoneoffhook)) then i1;
                  nogoodcmd:=TRUE;
                end;
              end;
          else
              nogoodcmd:=TRUE;
        end;
        if (not nogoodcmd) then getdatetime(lastkeypress);
      end;
      if (not nogoodcmd) then begin
        if (c<>'A') then begin
          curco:=7; sdc;
          window(1,1,80,25); clrscr;
          com_flush_rx;
        end;
        if ((sysopon) and (c<>#1)) then lactive:=timer;
      end else begin
        nogoodcmd:=FALSE;
        wfcm:=TRUE;
      end;
    end;
    if (c<>' ') then c:=#0;
    if (not com_rx_empty) then chkcom:=TRUE;
    if ((c<>#0) or (not com_rx_empty) or (chkcom)) then begin
      spdarq:=FALSE;
      if ((not phoneoffhook) and (not localioonly)) then begin
        getcallera(c1,chkcom);
        if (not incom) and ((spd='KB') and (c<>' ')) then begin
          wfcm:=FALSE;
          i1;
          if (quitafterdone) then begin
            elevel:=exitnormal; hangup:=TRUE;
            doneday:=TRUE;
          end;
        end;
      end;
    end;
  until ((incom) or (c=' ') or (doneday));

  etoday:=0; ptoday:=0; ftoday:=0; chatt:=0; shutupchatcall:=FALSE;
  flistverb:=TRUE; contlist:=FALSE; badfpath:=FALSE;

  if (not doneday) then begin
    window(1,1,80,25);
    clrscr;
    write('Baud = '+spd);
    if (spdarq) then writeln(' ARQ') else writeln;
  end;
  curco:=7; sdc;
  if (incom) then begin
    com_flush_rx; term_ready(TRUE);
    outcom:=TRUE;
    if (not modemr.noforcerate) then com_set_speed(value(spd));
  end else begin
    term_ready(FALSE);
    incom:=FALSE; outcom:=FALSE;
    wfcm:=FALSE;
  end;
  getdatetime(timeon); ftoday:=0;
  com_flush_rx;
  lil:=0;
  thisuser.ac:=thisuser.ac-[ansi];
  reset(uf);
  if (filesize(uf)>=2) then begin
    seek(uf,0); read(uf,u);
    thisuser.cols:=u.cols;
  end;
  close(uf);
  curco:=$07;
  checkit:=TRUE; beepend:=FALSE;
  inwfcmenu:=FALSE;

  mtcolors:=FALSE;

  if (systat.localscreensec) then wantout:=FALSE;
  if (spd='KB') and (not wantout) then wantout:=TRUE;
  if (wantout) then cursoron(TRUE);

  if (spd<>'KB') then
    case (value(spd) div 100) of
      3:inc(systat.todayzlog.userbaud[0]);
      12:inc(systat.todayzlog.userbaud[1]);
      24:inc(systat.todayzlog.userbaud[2]);
      48:inc(systat.todayzlog.userbaud[3]);
      96:inc(systat.todayzlog.userbaud[4]);
    end;
  savesystat;
  for i:=1 to 4 do macros.macro[i]:='';
end;

end.
