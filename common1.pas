{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit common1;

interface

uses
  crt, dos,
  myio,
  tmpcom;

function checkpw:boolean;
procedure newcomptables;
procedure cline(var s:string; dd:string);
procedure pausescr;
procedure wait(b:boolean);
(*procedure fix_window;*)
procedure inittrapfile;
procedure chatfile(b:boolean);
procedure local_input1(var i:string; ml:integer; tf:boolean);
procedure local_input(var i:string; ml:integer);
procedure local_inputl(var i:string; ml:integer);
procedure local_onek(var c:char; ch:string);
function chinkey:char;
procedure inli1(var s:string);
procedure chat;
procedure sysopshell(takeuser:boolean);
procedure globat(i:integer);
procedure exiterrorlevel;
procedure showsysfunc;
procedure readinzscan;
procedure savezscanr;
procedure redrawforansi;

implementation

uses
  common, common2, common3;

var
  chcfilter:array[1..2] of cfilterrec;
  chcfilteron:boolean;

function checkpw:boolean;
var s:string[20];
    savsl,savdsl:integer;
begin
  checkpw:=TRUE;
  prompt('SysOp Password: ');

  savsl:=thisuser.sl; savdsl:=thisuser.dsl;
  thisuser.sl:=realsl; thisuser.dsl:=realdsl;
  echo:=((aacs(systat.seepw)) and (not systat.localsec));
  thisuser.sl:=savsl; thisuser.dsl:=savdsl;

  input(s,20);
  echo:=TRUE;

  if (s<>systat.sysoppw) then
  begin
    checkpw:=FALSE;
    if (incom) and (s<>'') then sysoplog('*** Wrong SysOp Password = '+s+' ***');
  end;
end;

procedure newcomptables;
var savuboard:ulrec;
    savboard:boardrec;
    savreaduboard,savreadboard,i,j:integer;
    bfo,ulfo,done:boolean;
begin
  for i:=0 to 1 do for j:=0 to maxuboards do ccuboards[i][j]:=j;
  for i:=0 to 1 do for j:=1 to maxboards do ccboards[i][j]:=j;
  if (systat.compressbases) then begin

    savuboard:=memuboard; savreaduboard:=readuboard;
    savboard:=memboard; savreadboard:=readboard;

    bfo:=(filerec(bf).mode<>fmclosed);
    ulfo:=(filerec(ulf).mode<>fmclosed);
    if (not bfo) then reset(bf);
    if (not ulfo) then reset(ulf);

    seek(ulf,0); i:=0; j:=0; done:=FALSE;
    while ((not done) and (i<=maxuboards)) do begin
      {$I-} read(ulf,memuboard); {$I+}
      done:=(ioresult<>0);


      if (not done) then
        if (i>maxulb) then begin
          ccuboards[0][i]:=maxuboards+1;
          ccuboards[1][i]:=maxuboards+1;
        end else
          if (aacs(memuboard.acs)) then begin
            ccuboards[1][i]:=j; ccuboards[0][j]:=i;
            inc(j);
          end;
      inc(i);
    end;
{    seek(ulf,loaduboard); read(ulf,memuboard);}
    if (maxulb<maxuboards) then begin
      ccuboards[1][maxulb+1]:=j;
      ccuboards[0][j]:=maxulb+1;
    end;

    seek(bf,0); i:=1; j:=1; done:=FALSE;
    while ((not done) and (i<=maxboards)) do begin
      {$I-} read(bf,memboard); {$I+}
      done:=(ioresult<>0);

      if (not done) then
        if (i>numboards) then begin
          ccboards[0][i]:=maxboards+1;
          ccboards[1][i]:=maxboards+1;
        end else
          if (mbaseac(i)) then begin
            ccboards[1][i]:=j; ccboards[0][j]:=i;
            inc(j);
          end;
      inc(i);
    end;
{    seek(bf,loadboard); read(bf,memboard);}
    if (numboards<maxboards) then begin
      ccboards[1][numboards+1]:=j;
      ccboards[0][j]:=maxboards+1;
    end;

    if (not bfo) then close(bf);
    if (not ulfo) then close(ulf);

    memuboard:=savuboard; readuboard:=savreaduboard;
    memboard:=savboard; readboard:=savreadboard;

  end;
end;

procedure cline(var s:string; dd:string);
var i,u:integer;
    sx,sy,sz:byte;
    b,savwindowon:boolean;
begin
  sx:=wherex; sy:=wherey; sz:=textattr;
  savwindowon:=cwindowon;

  if (not cwindowon) then begin
    cwindowon:=TRUE;
    schangewindow(TRUE,1);
  end;
  commandline('');
  window(1,1,80,25);

  if (systat.istopwindow) then
    gotoxy(2,getwindysize(systat.curwindow))
  else
    gotoxy(2,26-getwindysize(systat.curwindow));
  tc(15); textbackground(1); write(dd+' ');
  tc(14); local_inputl(s,78-wherex);

  inuserwindow;
  gotoxy(sx,sy); textattr:=sz;
  if (not savwindowon) then sclearwindow;
end;

procedure pausescr;
var ddt,dt1,dt2:datetimerec;
    i,x:integer;
    s:string[3];
    c:char;
    bb:byte;
begin
  nosound;
  bb:=curco;
  cl(8);
  x:=lenn(fstring.pause); sprompt(fstring.pause); lil:=0;

  getkey(c);
(*
  getdatetime(dt1);
  repeat
    checkhangup; c:=inkey;
    getdatetime(dt2);
    timediff(ddt,dt1,dt2);
    if ((dt2r(ddt)>systat.timeoutbell*60) and (c=#0)) then begin
      outkey(^G); delay(100); outkey(^G);
    end;
    if ((systat.timeout<>-1) and (dt2r(ddt)>systat.timeout*60)) then begin
      nl;
      nl;
      printf('timedout');
      if (nofile) then
        print('Time out has occurred.  Log off time was at '+time+'.');
      nl; nl;
      hangup:=TRUE;
      sysoplog(#3#7+'!*!*! Time-out at '+time+' !*!*!');
      exit;
    end;
  until ((c<>#0) or (hangup));
*)

  if ((okansi) and (not hangup)) then begin
    s:=cstr(x);
    if (outcom) then begin
      if (okavatar) then pr1(^Y^H+chr(x)+^Y+' '+chr(x)+^Y^H+chr(x))
      else begin
        pr1(#27+'['+s+'D');
        for i:=1 to x do pr1(' ');
        pr1(#27+'['+s+'D');
      end;
    end;
    if (wantout) then begin
      for i:=1 to x do write(^H);
      for i:=1 to x do write(' ');
      for i:=1 to x do write(^H);
    end;
  end else begin
    for i:=1 to x do outkey(^H);
    for i:=1 to x do outkey(' ');
    for i:=1 to x do outkey(^H);
    if (trapping) then begin
      for i:=1 to x do write(trapfile,^H);
      for i:=1 to x do write(trapfile,' ');
      for i:=1 to x do write(trapfile,^H);
    end;
  end;
  if (not hangup) then setc(bb);
end;

procedure wait(b:boolean);
const lastc:byte=0;
var c,len:integer;
begin
  if (b) then begin
    lastc:=curco;
    sprompt(fstring.wait)
  end else begin
    len:=lenn(fstring.wait);
    for c:=1 to len do prompt(^H);
    for c:=1 to len do prompt(' ');
    for c:=1 to len do prompt(^H);
    setc(lastc);
  end;
end;

(*procedure fix_window;
var wind:windowrec;
    x,y,i,z:integer;
begin
  if (useron) then begin
    x:=wherex; y:=wherey;
    if (not systat.istopwindow) then begin
      if (systat.bwindow) then begin
        window(1,1,80,25);
        gotoxy(1,25);
        if (y>=22) then for i:=1 to 4-(25-y) do writeln;
        if (y>=22) then dec(y,4-(25-y));
      end;
      gotoxy(x,y);
    end else begin
      if (systat.bwindow) then begin
        window(1,1,80,25);
        savescreen(wind,1,1,80,y);
        if (y>=22) then z:=25-y else z:=5;
        if (z>=2) then movewindow(wind,1,z);
        if (z<=4) then y:=(y-z)+1;
        if (y>=22) then y:=21;
        if (y<=0) then y:=1;
        gotoxy(x,y);
      end;
    end;
    if (systat.bwindow) then topscr;
  end;
end;*)

procedure inittrapfile;
begin
  if (systat.globaltrap) or (thisuser.trapactivity) then trapping:=TRUE
    else trapping:=FALSE;
  if (trapping) then begin
    if (thisuser.trapseperate) then
      assign(trapfile,systat.trappath+'trap'+cstr(usernum)+'.msg')
    else
      assign(trapfile,systat.trappath+'trap.msg');
    {$I-} append(trapfile); {$I+}
    if (ioresult<>0) then begin
      rewrite(trapfile);
      writeln(trapfile);
    end;
    writeln(trapfile,'***** TeleGard-X User Audit - '+nam+' on at '+date+' '+time+' *****');
  end;
end;

procedure chatfile(b:boolean);
var bf:file of byte;
    s:string[91];
    cr:boolean;
begin
  s:='chat';
  if (thisuser.chatseperate) then s:=s+cstr(usernum);
  s:=systat.trappath+s+'.msg';
  if (not b) then begin
    if (cfo) then begin
      commandline('Chat Capture OFF (Recorded in "'+s+'")');
      cfo:=FALSE;
      if (textrec(cf).mode<>fmclosed) then close(cf);
    end;
  end else begin
    cfo:=TRUE;
    if (textrec(cf).mode=fmoutput) then close(cf);
    assign(cf,s); assign(bf,s);
    cr:=FALSE;
    {$I-} reset(cf); {$I+}
    if (ioresult<>0) then
      rewrite(cf)
    else begin
      close(cf);
      append(cf);
    end;
    writeln(cf,^M^J^M^J+dat+^M^J+'Recorded with user: '+nam+^M^J+'------------------------------------'+^M^J);
    commandline('Chat Capture ON ("'+s+'")');
  end;
end;

procedure local_input1(var i:string; ml:integer; tf:boolean);
var r:real;
    cp:integer;
    cc:char;
begin
  cp:=1;
  repeat
    cc:=readkey;
    if (not tf) then cc:=upcase(cc);
    if (cc in [#32..#255]) then
      if (cp<=ml) then begin
        i[cp]:=cc;
        inc(cp);
        write(cc);
      end
      else
    else
      case cc of
        ^H:if (cp>1) then begin
            cc:=^H;
            write(^H' '^H);
            dec(cp);
          end;
    ^U,^X:while (cp<>1) do begin
            dec(cp);
            write(^H' '^H);
          end;
      end;
  until (cc in [^M,^N]);
  i[0]:=chr(cp-1);
  if (wherey<=hi(windmax)-hi(windmin)) then writeln;
end;

procedure local_input(var i:string; ml:integer);  (* Input uppercase only *)
begin
  local_input1(i,ml,FALSE);
end;

procedure local_inputl(var i:string; ml:integer);   (* Input lower & upper case *)
begin
  local_input1(i,ml,TRUE);
end;

procedure local_onek(var c:char; ch:string);                    (* 1 key input *)
begin
  repeat c:=upcase(readkey) until (pos(c,ch)>0);
  writeln(c);
end;

function chinkey:char;
var c:char;
begin
  c:=#0; chinkey:=#0;
  if (keypressed) then begin
    c:=readkey;
    if (chcfilteron) then setc(chcfilter[1][ord(c)])
      else if (not wcolor) then cl(systat.sysopcolor);
    wcolor:=TRUE;
    if (c=#0) then
      if (keypressed) then begin
        c:=readkey;
        skey1(c);
        if (c=#68) then c:=#1 else c:=#0;
        if (buf<>'') then begin
          c:=buf[1];
          buf:=copy(buf,2,length(buf)-1);
        end;
      end;
    chinkey:=c;
  end else
    if ((not com_rx_empty) and (incom) and (not trm)) then begin
      c:=cinkey;
      if (chcfilteron) then setc(chcfilter[2][ord(c)])
        else if (wcolor) then cl(systat.usercolor);
      wcolor:=FALSE;
      chinkey:=c;
    end;
end;

procedure inli1(var s:string);             (* Input routine for chat *)
var cv,cc,cp,g,i,j:integer;
    c,c1:char;
begin
  cp:=1;
  s:='';
  if (ll<>'') then begin
    if (chcfilteron) then begin
      if (wcolor) then j:=1 else j:=2;
      for i:=1 to length(ll) do begin
        setc(chcfilter[j][ord(ll[i])]);
        outkey(ll[i]);
        if (trapping) then write(trapfile,ll[i]);
      end;
    end else
      prompt(ll);
    s:=ll; ll:='';
    cp:=length(s)+1;
  end;
  repeat
    getkey(c); checkhangup;
    case ord(c) of
      32..255:if (cp<79) then begin
                s[cp]:=c; pap:=cp; inc(cp);
                outkey(c);
                if (trapping) then write(trapfile,c);
              end;
      16:if okansi then begin
           getkey(c1);
           cl(ord(c1)-48);
         end;
      27:if (cp<79) then begin
           s[cp]:=c; inc(cp);
           outkey(c);
           if (trapping) then write(trapfile,c);
         end;
      8:if (cp>1) then begin
          dec(cp); pap:=cp;
          prompt(^H' '^H);
        end;
      24:begin
           for cv:=1 to cp-1 do prompt(^H' '^H);
           cp:=1;
           pap:=0;
         end;
       7:if (outcom) then sendcom1(^G);
      23:if cp>1 then
           repeat
             dec(cp); pap:=cp;
             prompt(^H' '^H);
           until (cp=1) or (s[cp]=' ');
       9:begin
           cv:=5-(cp mod 5);
           if (cp+cv<79) then
             for cc:=1 to cv do begin
               s[cp]:=' ';
               inc(cp); pap:=cp;
               prompt(' ');
             end;
         end;
  end;
  until ((c=^M) or (cp=79) or (hangup) or (not ch));
  if (not ch) then begin c:=#13; ch:=FALSE; end;
  s[0]:=chr(cp-1);
  if (c<>^M) then begin
    cv:=cp-1;
    while (cv>0) and (s[cv]<>' ') and (s[cv]<>^H) do dec(cv);
    if (cv>(cp div 2)) and (cv<>cp-1) then begin
      ll:=copy(s,cv+1,cp-cv);
      for cc:=cp-2 downto cv do prompt(^H);
      for cc:=cp-2 downto cv do prompt(' ');
      s[0]:=chr(cv-1);
    end;
  end;
  if (wcolor) then j:=1 else j:=2;
  if ((chcfilteron) and ((chcfilter[j][32] and 112)<>0)) then begin
    setc(chcfilter[j][32]);
    if (okavatar) then pr1(^V+^G) else pr1(^['[K');
    clreol;
    setc(7);
    nl;
    setc(chcfilter[j][32]);
  end else
    nl;
end;

procedure loadchcfilter(i:integer);
var chcfilterf:file of cfilterrec;
    s,os:string;
    ps:string[67];
    ns:string[8];
    es:string[4];
begin
  os:=s;
  if (i=1) then s:=systat.chatcfilter1 else s:=systat.chatcfilter2;

  if (s='') then begin
    sysoplog(aonoff((i=1),'SysOp','User')+' chat-filter set to NULL string');
    exit;
  end;

  fsplit(s,ps,ns,es);
  if (exist(systat.afilepath+ns+es)) then s:=systat.afilepath+ns+es
  else
  if (exist(systat.gfilepath+ns+es)) then s:=systat.gfilepath+ns+es;

  assign(chcfilterf,s);
  {$I-} reset(chcfilterf); {$I+}
  if (ioresult=0) then begin
    {$I-} read(chcfilterf,chcfilter[i]); {$I+}
    if (ioresult=0) then chcfilteron:=TRUE;
    close(chcfilterf);
  end else
    sysoplog('Missing chat color filter: "'+os+'"');
end;

procedure chat;
var chatstart,chatend,tchatted:datetimerec;
    s,xx:string;
    t1:real;
    i,savpap:integer;
    c:char;
    savecho,savprintingfile:boolean;
begin
  nosound;
  getdatetime(chatstart);
  dosansion:=FALSE;

  savprintingfile:=printingfile;
  savpap:=pap; ch:=TRUE; chatcall:=FALSE; savecho:=echo; echo:=TRUE;
  if (systat.autochatopen) then chatfile(TRUE)
     else if (thisuser.chatauto) then chatfile(TRUE);
  nl; nl;
  thisuser.ac:=thisuser.ac-[alert];

  printf('chatinit');
  if (nofile) then begin sprompt(#3#5+fstring.engage); nl; nl; end;

  cl(systat.sysopcolor); wcolor:=TRUE;

  chcfilteron:=FALSE;

  if (okansi) then
    if ((systat.chatcfilter1<>'') or (systat.chatcfilter2<>'')) then begin
      loadchcfilter(1);
      if (chcfilteron) then loadchcfilter(2);
    end;

  if (chatr<>'') then begin
    commandline(chatr); print(' '); chatr:='';
  end;
  repeat
    inli1(xx);
    if (xx[1]='/') then xx:=allcaps(xx);
    if (copy(xx,1,6)='/TYPE ') then begin
      s:=copy(xx,7,length(xx));
      if (s<>'') then begin
        printfile(s);
        if (nofile) then print('*File not found*');
      end;
    end
    else if (xx='/SHELL') and (thisuser.sl=255) then begin
      print('Shelling to DOS...');
      sysopshell(TRUE)
    end
    else if (xx='/CC') then begin
      print(syn(dosansion));
    end
    else if (xx='/C') then begin
      print(syn(mtcolors));
    end
    else if ((xx='/HELP') or (xx='/?')) then begin
      nl;
      {rcg11242000 DOSism.}
      {sprint('^5/TYPE d:\path\filename.ext^3: Type a file');}
      sprint('^5/TYPE /path/filename.ext^3: Type a file');
      sprint('^5/BYE^3:   Hang up');
      sprint('^5/CLS^3:   Clear the screen');
      sprint('^5/PAGE^3:  Page the SysOp and User');
      {rcg11242000 DOSism}
      {
      if (thisuser.sl=255) then
        sprint('^5/SHELL^3: Shell to DOS with user (255 SL ^5ONLY^3)');
      }
      if (thisuser.sl=255) then
        sprint('^5/SHELL^3: Shell to operating system with user (255 SL ^5ONLY^3)');
      sprint('^5/Q^3:     Exit chat mode');
      nl;
    end
    else if (xx='/CLS') then cls
    else if (xx='/PAGE') then begin
      for i:=650 to 700 do begin
        sound(i); delay(4);
        nosound;
      end;
      repeat
        dec(i); sound(i); delay(2);
        nosound;
      until (i=200);
      prompt(^G^G);
    end

    else if (xx='/ACS') then begin
      prt('ACS:'); inputl(s,20);
      if (aacs(s)) then print('You have access to that!')
        else print('You DO NOT have access to that.');
    end

    else if (xx='/BYE') then begin
      print('Hanging up...');
      hangup:=TRUE;
    end
    else if (xx='/Q') then begin
      t1:=timer;
      while (abs(t1-timer)<0.6) and (empty) do;
      if (empty) then begin ch:=FALSE; print('Chat Aborted...'); end;
    end;
    if (cfo) then writeln(cf,xx);
  until ((not ch) or (hangup));

  printf('chatend');
  if (nofile) then begin nl; sprint(#3#5+fstring.endchat); end;

  getdatetime(chatend);
  timediff(tchatted,chatstart,chatend);

  freetime:=freetime+dt2r(tchatted);

  tleft;
  s:='Chatted for '+longtim(tchatted);
  if (cfo) then begin
    s:=s+'  -{ Recorded in CHAT';
    if (thisuser.chatseperate) then s:=s+cstr(usernum);
    s:=s+'.MSG }-';
  end;
  sysoplog(s);
  ch:=FALSE; echo:=savecho;
  if ((hangup) and (cfo)) then
  begin
    writeln(cf);
    writeln(cf,'NO CARRIER');
    writeln(cf);
    writeln(cf,'>> Carrier lost ...');
    writeln(cf);
  end;
  pap:=savpap; printingfile:=savprintingfile;
  commandline('');
  if (cfo) then chatfile(FALSE);
end;

procedure sysopshell(takeuser:boolean);
var wind:windowrec;
    opath:string;
    t:real;
    sx,sy,ret:integer;
    bb:byte;

  procedure dosc;
  var s:string;
      i:integer;
  begin
    s:=^M^J+#27+'[0m';
    for i:=1 to length(s) do dosansi(s[i]);
  end;

begin
  bb:=curco;
  getdir(0,opath);
  t:=timer;
  if (useron) and (incom) then begin
    nl; nl;
    sprompt(fstring.shelldos1);
  end;
  sx:=wherex; sy:=wherey;
  setwindow(wind,1,1,80,25,7,0,0);
  clrscr;
  tc(11); writeln('[> Type "EXIT" to return to Project Coyote.');
  dosc;
  dosansion:=FALSE;
  if (not takeuser) then shelldos(FALSE,'',ret)
    else shelldos(FALSE,'remote.bat',ret);
  getdatetime(tim);
  if (useron) then com_flush_rx;
  if (not trm) then chdir(opath);
  clrscr;
  removewindow(wind);
  gotoxy(sx,sy);
  if (useron) then begin
    freetime:=freetime+timer-t;
    topscr;
    sdc;
    if (incom) then begin
      nl;
      sprint(fstring.shelldos2);
    end;
  end;
  setc(bb);
end;

procedure globat(i:integer);
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
  shelldos(FALSE,'globat'+chr(i+48),ret);
  getdatetime(tim);
  com_flush_rx;
  freetime:=freetime+timer-t;
  removewindow(wind);
  chdir(s);
  if (useron) then topscr;
  gotoxy(xx,yy); textattr:=z;
end;

procedure exiterrorlevel;
var wind:windowrec;
    s:string;
    xx,yy,z,ee:integer;
    c:char;
    re:boolean;
begin
  savescreen(wind,1,1,80,25);
  xx:=wherex; yy:=wherey; z:=textattr;
  clrscr;
  writeln('[> Exit at ERRORLEVEL '+cstr(exiterrors)+', correct? ');
  writeln;
  write('[A]bort [Y]es [O]ther : ');
  repeat c:=upcase(readkey) until (c in ['A','Y','O',^M]);
  if (c<>^M) then write(c);
  writeln;
  ee:=-1;
  case c of
    'O':begin
          writeln;
          write('Enter ERRORLEVEL (-1 to abort) : ');
          readln(s);
          if (s<>'') then ee:=value(s);
        end;
    'Y':ee:=exiterrors;
  end;
  if (ee<>-1) then begin
    writeln;
    write('Generate a run-time error? [Yes] : ');
    repeat c:=upcase(readkey) until (c in ['Y','N',^M]);
    re:=(c<>'N');
  end;
  removewindow(wind);
  if (useron) then topscr;
  gotoxy(xx,yy); textattr:=z;
  if (ee<>-1) then begin
    exiterrors:=ee;
    if (re) then runerror(0) else halt(ee);
  end;
end;

procedure showsysfunc;
var imagef:file of windowrec;
    wind,swind:windowrec;
    xx,yy,z:integer;
    c:char;
    badd:boolean;
begin
  assign(imagef,systat.gfilepath+'sysfunc.dat');
  {$I-} reset(imagef); {$I+}
  if (ioresult<>0) then commandline('"'+systat.gfilepath+'SYSFUNC.DAT" missing')
  else begin
    {$I-} read(imagef,wind); {$I+} badd:=(ioresult<>0);
    if (badd) then commandline('Errors reading image data from SYSFUNC.DAT');
    close(imagef);
    if (not badd) then begin
      savescreen(swind,1,1,80,25);
      xx:=wherex; yy:=wherey; z:=textattr;
      removewindow(wind);
      cursoron(FALSE);
      c:=readkey;
      removewindow(swind);
      if (useron) then topscr;
      gotoxy(xx,yy); textattr:=z;
      cursoron(TRUE);
    end;
  end;
end;

procedure readinzscan;
var zscanf:file of zscanrec;
    i,j:integer;
begin
  assign(zscanf,systat.gfilepath+'zscan.dat');
  {$I-} reset(zscanf); {$I+} if (ioresult<>0) then rewrite(zscanf);
  if (usernum<filesize(zscanf)) then begin
    seek(zscanf,usernum); read(zscanf,zscanr);
    close(zscanf);
    exit;
  end;
  with zscanr do begin
    for i:=1 to maxboards do
      for j:=1 to 6 do mhiread[i][j]:=0;
    mzscan:=[]; fzscan:=[];
    for i:=1 to maxboards do mzscan:=mzscan+[i];
    for i:=0 to maxuboards do fzscan:=fzscan+[i];
  end;
  seek(zscanf,filesize(zscanf));
  repeat write(zscanf,zscanr) until (filesize(zscanf)>=usernum+1);
  close(zscanf);
end;

procedure savezscanr;
var zscanf:file of zscanrec;
begin
  assign(zscanf,systat.gfilepath+'zscan.dat');
  {$I-} reset(zscanf); {$I+} if (ioresult<>0) then rewrite(zscanf);
  if (usernum<filesize(zscanf)) then begin
    seek(zscanf,usernum); write(zscanf,zscanr);
    close(zscanf);
    exit;
  end;
  close(zscanf);
end;

procedure redrawforansi;
begin
  if (dosansion) then begin dosansion:=FALSE; topscr; end;
  textattr:=7; curco:=7;
  if ((outcom) and (okansi)) then begin
    if (okavatar) then pr1(^V+^A+#7) else pr1(#27+'[0m');
  end;
end;

end.
