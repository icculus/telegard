{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit common2;

interface

uses
  crt, dos,
  myio,
  tmpcom;

procedure showudstats;
procedure skey1(c:char);
procedure savesystat;
procedure remove_port;
procedure openport(comport:byte; baud:longint; parity:char; databits,stopbits:byte);
{procedure initthething;}
procedure iport;
procedure gameport;
procedure sendcom1(c:char);
function recom1(var c:char):boolean;
procedure term_ready(ready_status:boolean);
function getwindysize(wind:integer):integer;
procedure inuserwindow;
procedure commandline(s:string);
procedure sclearwindow;
procedure schangewindow(needcreate:boolean; newwind:integer);
procedure topscr;
procedure tleft;
procedure readinmacros;
procedure changeuserdatawindow;
procedure saveuf;

implementation

uses
  common, common1, common3;

procedure cpr(c1,c2:byte; u:userrec);
var r:uflags;
begin
  for r:=rlogon to rmsg do begin
    if (r in u.ac) then textattr:=c1 else textattr:=c2;
    write(copy('LCVBA*PEKM',ord(r)+1,1));
  end;
  textattr:=c2; write('/');
  for r:=fnodlratio to fnodeletion do begin
    if (r in u.ac) then textattr:=c1 else textattr:=c2;
    write(copy('1234',ord(r)-19,1));
  end;
end;

procedure showudstats;
begin
  commandline('U/L: '+cstr(thisuser.uploads)+'/'+cstr(trunc(thisuser.uk))+'k'+
           ' ³ D/L: '+cstr(thisuser.downloads)+'/'+cstr(trunc(thisuser.dk))+'k'+
           ' File Points:' +cstr(thisuser.filepoints));
end;

procedure skey1(c:char);
var s:string[50];
    cz,i:integer;
    cc:char;
    b,savwantout:boolean;
begin
  case ord(c) of
    ALT_1..ALT_9:globat((ord(c)-ALT_1)+1);
    ALT_MINUS:begin
      writeln;
      writeln('Stack space left : ',sptr,' bytes');
      writeln;
    end;
    ALT_EQUAL:begin doneafternext:=not doneafternext; tleft; end;
    CTRL_PRTSC:exiterrorlevel;
  end;
  if (not inwfcmenu) then
  begin
    case ord(c) of
      ALT_F:showsysfunc;
      ALT_G:
        begin
          commandline('Log options - [T]rap activity [C]hat buffering');
          cc:=upcase(readkey);
          with thisuser do
            case cc of
              'C':begin
                    commandline('Auto chat buffering - [O]ff [S]eperate [M]ain (CHAT.MSG)');
                    cc:=upcase(readkey);
                    if (cc in ['O','S','M']) then chatfile(FALSE);
                    case cc of
                      'O':begin chatauto:=FALSE; chatseperate:=FALSE; end;
                      'S':begin chatauto:=TRUE; chatseperate:=TRUE; end;
                      'M':begin chatauto:=TRUE; chatseperate:=FALSE; end;
                    end;
                    if (cc in ['S','M']) then chatfile(TRUE);
                    topscr;
                  end;
              'T':begin
                    commandline('Activity trapping - [O]ff [S]eperate [M]ain (TRAP.MSG)');
                    cc:=upcase(readkey);
                    if (cc in ['O','S','M']) then
                      if (trapping) then begin
                        close(trapfile);
                        trapping:=FALSE;
                      end;
                    case cc of
                      'O':begin trapactivity:=FALSE; trapseperate:=FALSE; end;
                      'S':begin trapactivity:=TRUE; trapseperate:=TRUE; end;
                      'M':begin trapactivity:=TRUE; trapseperate:=FALSE; end;
                    end;
                    if (cc in ['S','M']) then inittrapfile;
                    topscr;
                  end;
            end;
          commandline('');
        end;
      ALT_L:cls;
      ALT_T:
        if (cwindowon) then begin
          i:=systat.curwindow;
          sclearwindow;
          systat.istopwindow:=not systat.istopwindow;
          cwindowon:=TRUE;
          schangewindow(TRUE,i);
        end;
      ALT_V:
        begin
          autovalidate(thisuser,usernum);
          topscr; commandline('User Validated.');
        end;
      F1:if (useron) then begin
          wait(TRUE);
          changeuserdatawindow;
          wait(FALSE);
        end;
      SHIFT_F1:if (useron) then changeuserdatawindow;
      F2:
        if (useron) then begin
          i:=systat.curwindow;
          if (systat.windowon) then begin
            inc(i);
            if (i>2) then i:=1;
          end else
            systat.windowon:=TRUE;
          schangewindow(TRUE,i);
        end;
      SHIFT_F2:
         if (useron) then
           if (not systat.windowon) then begin
             systat.windowon:=TRUE;
             cwindowon:=TRUE;
             schangewindow(TRUE,systat.curwindow);
           end else begin
             sclearwindow;
             systat.windowon:=FALSE;
           end;
      F3:
        if (not com_carrier) then commandline('No carrier detected!')
        else begin
          if (outcom) then
            if (incom) then incom:=FALSE else
              if (com_carrier) then incom:=TRUE;
          if (incom) then commandline('User keyboard ON.')
                     else commandline('User keyboard OFF.');
          com_flush_rx;
        end;
      F4:
        begin
          chatcall:=FALSE; chatr:='';
          thisuser.ac:=thisuser.ac-[alert]; tleft;
        end;
      F5:hangup:=TRUE;
      F6:if (useron) then topscr;
      F7:
        begin
          b:=ch; ch:=TRUE;
          dec(thisuser.tltoday,5);
          tleft;
          ch:=b;
        end;
      F8:
        begin
          b:=ch; ch:=TRUE;
          inc(thisuser.tltoday,5);
          if (thisuser.tltoday<0) then thisuser.tltoday:=32767;
          tleft;
          ch:=b;
        end;
      F9:
        if (useron) then
          with thisuser do begin
            if (sl=255) then
              if (realsl<>255) or (realdsl<>255) then begin
                thisuser.sl:=realsl;
                thisuser.dsl:=realdsl;
                if (systat.compressbases) then newcomptables;
                topscr; commandline('Normal access restored.');
              end else
            else begin
              realsl:=sl; realdsl:=dsl;
              thisuser.sl:=255;
              thisuser.dsl:=255;
              if (systat.compressbases) then newcomptables;
              topscr; commandline('Temporary SysOp access granted.');
            end;
          end;
      F10:
        if (ch) then begin
          ch:=FALSE;
          chatr:='';
        end else
          chat;
      ARROW_HOME:
        if (ch) then chatfile(not cfo);
      ARROW_UP,
      ARROW_LEFT,
      ARROW_RIGHT,
      ARROW_DOWN:
        if ((ch) or (write_msg)) then begin
          if (okavatar) then buf:=buf+^V else buf:=buf+^[+'[';
          case ord(c) of
            ARROW_UP:if (okavatar) then buf:=buf+^C else buf:=buf+'A';
            ARROW_LEFT:if (okavatar) then buf:=buf+^E else buf:=buf+'D';
            ARROW_RIGHT:if (okavatar) then buf:=buf+^F else buf:=buf+'C';
            ARROW_DOWN:if (okavatar) then buf:=buf+^D else buf:=buf+'B';
          end;
        end;
      SHIFT_F3:
        if (outcom) then begin
          savwantout:=wantout; wantout:=FALSE;
          wait(TRUE);
          wantout:=savwantout;
          commandline('User screen OFF ³ User keyboard OFF');
          outcom:=FALSE; incom:=FALSE;
        end else
          if (not com_carrier) then commandline('No carrier detected!')
          else begin
            commandline('User screen ON ³ User keyboard ON');
            savwantout:=wantout; wantout:=FALSE;
            wait(FALSE);
            wantout:=savwantout;
            outcom:=TRUE; incom:=TRUE;
          end;
      SHIFT_F5:
        begin
          cline(s,'Display what hangup file (HANGUPxx.*) :');
          commandline('');
          if (s<>'') then begin
						nl; nl; incom:=FALSE;
            printf('hangup'+s);
            sysoplog('++ Displayed hangup file HANGUP'+s);
            hangup:=TRUE;
          end;
        end;
      SHIFT_F7:
        begin
          wait(TRUE);
          cline(s,'Subtract from user''s time left: ');
          commandline('');
          if (s<>'') then begin
            b:=ch; ch:=TRUE;
            dec(thisuser.tltoday,value(s));
            tleft;
            ch:=b;
          end;
          wait(FALSE);
        end;
      SHIFT_F8:
        begin
          wait(TRUE);
          cline(s,'Add to user''s time left: ');
          commandline('');
          if (s<>'') then begin
            b:=ch; ch:=TRUE;
            inc(thisuser.tltoday,value(s));
            if (thisuser.tltoday<=0) then thisuser.tltoday:=32767;
            tleft;
            ch:=b;
          end;
          wait(FALSE);
        end;
      SHIFT_F10:
        begin
          beepend:=not beepend;
          b:=ch; ch:=TRUE;
          tleft; ch:=b;
        end;
      ALT_F3:
        if (wantout) then begin
          clrscr; tc(11); writeln('Text OFF');
          wantout:=FALSE;
          cursoron(FALSE);
        end else begin
          clrscr; tc(11); writeln('Text ON');
          wantout:=TRUE;
          cursoron(TRUE);
        end;
      ALT_J,
      ALT_F4:SysopShell(FALSE);
      ALT_F5:
        begin
          randomize;
          for i:=1 to 50 do prompt(chr(random(255)));
          hangup:=TRUE;
        end;
      ALT_F9:
        begin
          repeat
            outkey(^G);
            commandline('Paging user...');
            delay(100);
            commandline('');
            checkhangup;
          until ((not empty) or (hangup));
        end;
      ALT_F10:commandline(chatr);
      CTRL_F4:SysopShell(TRUE);
      CTRL_F5:
        begin
          randomize;
          s:='';
          for i:=1 to random(50) do s:=s+chr(random(255));
          prompt(s); (* dm(' '+s,c); *)
        end;
    end;
  end;
end;

procedure savesystat;
var systatf:file of systatrec;
begin
  {rcg11242000 DOSism.}
  {assign(systatf,start_dir+'\status.dat');}
  assign(systatf,start_dir+'/status.dat');
  rewrite(systatf); write(systatf,systat); close(systatf);
end;

procedure setacch(c:char; b:boolean; var u:userrec);
begin
  if (b) then if (not (tacch(c) in u.ac)) then acch(c,u);
  if (not b) then if (tacch(c) in u.ac) then acch(c,u);
end;

procedure remove_port;
begin
  if (not localioonly) then com_deinstall;
end;

procedure openport(comport:byte; baud:longint; parity:char;
                   databits,stopbits:byte);
begin
  if (not localioonly) then begin
    com_set_parity(com_none,stopbits);
    com_set_speed(baud);
  end;
end;

procedure iport;
var anyerrors:word;
begin
  if (not localioonly) then begin
    if (com_installed) then com_deinstall;
    com_install(modemr.comport,anyerrors,systat.fossil);
    openport(modemr.comport,modemr.waitbaud,'N',8,1);
  end;
end;

procedure gameport;
var speed:longint;
begin
  if (not localioonly) then begin
    if (spd='KB') then speed:=modemr.waitbaud else speed:=value(spd);
    if ((not modemr.noforcerate) or (value(spd)<9600)) then
      openport(modemr.comport,speed,'N',8,1);
  end;
end;

procedure sendcom1(c:char);
begin
  if (not localioonly) then com_tx(c);
end;

function recom1(var c:char):boolean;
begin
  c:=#0;
  if (localioonly) then recom1:=TRUE else begin
    if (not com_rx_empty) then begin
      c:=com_rx;
      recom1:=TRUE;
    end else
      recom1:=FALSE;
  end;
end;

procedure term_ready(ready_status:boolean);
var mcr_value:byte;
begin
  if (not localioonly) then
    if (ready_status) then com_raise_dtr else com_lower_dtr;
end;

function getwindysize(wind:integer):integer;
begin
  case wind of
    0:getwindysize:=0;
    1:getwindysize:=5;
    2:getwindysize:=11;
  end;
end;

procedure inuserwindow;
begin
  if (cwindowon) then
    if (systat.istopwindow) then
      window(1,getwindysize(systat.curwindow)+1,80,25)
    else
      window(1,1,80,25-getwindysize(systat.curwindow));
end;

procedure commandline(s:string);
var p,xx,yy:integer;
    sx,sy,sz:byte;
begin
  if (not useron) then exit;

  sx:=wherex; sy:=wherey; sz:=textattr;
  p:=40-(length(s) div 2);

  window(1,1,80,25);
  xx:=4; yy:=1;
  if (not cwindowon) then xx:=1 else
    if (systat.istopwindow) then
      yy:=getwindysize(systat.curwindow)
    else
      yy:=26-getwindysize(systat.curwindow);

  gotoxy(xx,yy);
  if (not ismono) then textattr:=$1F else textattr:=$70;
  if (not cwindowon) then clreol else
    write('                                                                          ');
  gotoxy(xx,yy); write(s);

  inuserwindow;
  gotoxy(sx,sy); textattr:=sz;
end;

procedure clrline(y:integer);
begin
  gotoxy(1,y); clreol;
end;

procedure sclearwindow;
var wind:windowrec;
    i,windysize:integer;
    x,y,z:byte;
begin
  if ((not cwindowon) or (not useron) or (not systat.windowon)) then exit;

  x:=wherex; y:=wherey; z:=textattr;
  windysize:=getwindysize(systat.curwindow);
  cursoron(FALSE);

  window(1,1,80,25); textattr:=7;
  if (not systat.istopwindow) then
    for i:=26-windysize to 25 do clrline(i)
  else begin
    savescreen(wind,1,windysize+1,80,25);
    for i:=1 to windysize do clrline(i);
    movewindow(wind,1,1);
    for i:=26-windysize to 25 do clrline(i);
  end;
  cwindowon:=FALSE;

  gotoxy(x,y); textattr:=z;
  cursoron(TRUE);
end;

procedure schangewindow(needcreate:boolean; newwind:integer);
var wind:windowrec;
    i,j,k,windysize,z:integer;
    sx,sy,sz:byte;
begin
  if (((not useron) and (not needcreate)) or (not systat.windowon)) then exit;

  sx:=wherex; sy:=wherey; sz:=textattr;
  windysize:=getwindysize(newwind);

  if (not needcreate) then needcreate:=(newwind<>systat.curwindow);
  if ((windysize<>getwindysize(systat.curwindow)) and (cwindowon)) then
    sclearwindow;

  if (not systat.istopwindow) then begin
    cursoron(FALSE);
    if ((needcreate) and (newwind in [1,2])) then begin
      window(1,1,80,25);
      gotoxy(1,25);
      if (sy>25-windysize) then begin
        z:=windysize-(25-sy);
        for i:=1 to z do writeln;
        dec(sy,z);
      end;
    end;
    gotoxy(sx,sy);
  end else begin
    if ((needcreate) and (newwind in [1,2])) then begin
      window(1,1,80,25);
      savescreen(wind,1,1,80,sy);
      if (sy<=25-windysize) then z:=windysize+1 else z:=26-sy;
      if (z>=2) then movewindow(wind,1,z);
      if (z<=4) then sy:=(sy-z)+1;

      if (sy>25-windysize) then sy:=25-windysize;
      if (sy<1) then sy:=1;
    end;
    cursoron(TRUE);
  end;

  systat.curwindow:=newwind;
  if (systat.curwindow<>0) then cwindowon:=TRUE;
  gotoxy(sx,sy); textattr:=sz;
  if (systat.curwindow in [1,2]) then topscr;
end;

procedure blankzlog(var zz:zlogrec);
var i:integer;
begin
  with zz do begin
    date:=' ------ ';
    for i:=0 to 4 do userbaud[i]:=0;
    active:=0; calls:=0; newusers:=0; pubpost:=0; privpost:=0;
    fback:=0; criterr:=0; uploads:=0; downloads:=0; uk:=0; dk:=0;
  end;
end;

function mrnn(i,l:integer):string;
begin
  mrnn:=mrn(cstr(i),l);
end;

function ctp(t,b:longint):string;
var s,s1:string[32];
    n:real;
begin
  s:=cstr((t*100) div b);
  if (length(s)=1) then s:=' '+s;
  s:=s+'.';
  if (length(s)=3) then s:=' '+s;
  n:=t/b+0.0005;
  s1:=cstr(trunc(n*1000) mod 10);
  ctp:=s+s1+'%';
end;

procedure topscr;
var zf:file of zlogrec;
    zz:array[1..3] of zlogrec;
    s,spe:string;
    i,j,k,windysize:integer;
    sx,sy,sz:byte;
    c:char;
begin
  if ((usernum=0) or (not cwindowon) or (not useron)) then exit;

  cursoron(FALSE);
  sx:=wherex; sy:=wherey; sz:=textattr;
  window(1,1,80,25); windysize:=getwindysize(systat.curwindow);
  textbackground(0);

  if (systat.istopwindow) then window(1,1,80,windysize)
    else window(1,26-windysize,80,25);
  for i:=1 to windysize do begin gotoxy(1,i); clreol; end;

  if (systat.istopwindow) then gotoxy(1,windysize) else gotoxy(1,1);
  tc(9); textbackground(1); clreol; textbackground(0);

  if (systat.istopwindow) then window(1,1,80,windysize-1)
    else window(1,27-windysize,80,25);

  with thisuser do
    case systat.curwindow of
      1:begin
          cwriteat(1,1, #3#11+nam);
          cwriteat(36,1,#3#14+'PS:'+#3#11+mn(msgpost,6)+
                        #3#14+'ES:'+#3#11+mn(emailsent,6)+
                        #3#14+'FS:'+#3#11+mn(feedback,4)+
                        #3#14+'MW:'+#3#11+mn(waiting,3));
          cwrite(#3#14+'UL:'+#3#11+cstr(uploads)+'-'+cstr(uk)+'k');
          cwriteat(1,2, #3#11+realname);
          cwriteat(36,2,#3#14+'TC:'+#3#11+mn(loggedon,6)+
                        #3#14+'TT:'+#3#11+mn(ttimeon,6)+
                        #3#14+'CT:'+#3#11+mn(ontoday,4)+
                        #3#14+'IL:'+#3#11+mn(illegal,3));
          cwrite(#3#14+'DL:'+#3#11+cstr(downloads)+'-'+cstr(dk)+'k');
          spe:=spd;
          if (length(spe)=5) then spe:=copy(spe,1,2)+'.'+copy(spe,3,1);
          if (spe='KB') then spe:='Keys';
          cwriteat(1,3, #3#10+note);
          cwriteat(36,3,#3#11+sex+mn(ageuser(bday),2)+
                        #3#14+'('+#3#11+bday+#3#14+')  '+
                        #3#14+'LO:('+#3#11+laston+#3#14+') '+
                        #3#9+'['+spe+'] '+
                        #3#14+'Pts:'+#3#11+cstr(filepoints));
          cwriteat(1,4, #3#14+'SL:'+#3#11+mn(sl,4)+
                        #3#14+'DSL:'+#3#11+mn(dsl,4)+
                        #3#14+'AR:');
          for c:='A' to 'Z' do begin
            if (c in ar) then tc(4) else tc(7);
            write(c);
          end;
          cwrite(#3#14+' AC:');
          if (ismono) then cpr($70,$07,thisuser) else cpr(4,7,thisuser);
        end;
      2:begin
          if ((aacs(systat.nodlratio)) or (fnodlratio in thisuser.ac)) then
            s:=#3#10+'Exempt'
          else
            s:=#3#11+'1/'+cstr(systat.dlratio[thisuser.sl])+
                   '-1k/'+cstr(systat.dlkratio[thisuser.sl])+'k';
          cwriteat(1,1, #3#11+caps(name)+' ('+caps(realname)+')');
          cwriteat(38,1,#3#11+sex+mn(ageuser(bday),2)+'('+bday+') '+
                        #3#14+'FileRatio='+s);

          if ((aacs(systat.nopostratio)) or (fnopostratio in thisuser.ac)) then
            s:=#3#10+'Exempt'
          else begin
            i:=systat.postratio[thisuser.sl];
            s:=#3#11+cstr(i div 10)+'.'+cstr(i mod 10)+' calls/1 post';
          end;
          cwriteat(1,2, #3#14+street);
          cwriteat(38,2,#3#14+'FO:('+#3#11+firston+#3#14+') '+
                        'PostRatio='+s);

          cwriteat(1,3, #3#14+citystate+' '+zipcode);
          cwriteat(38,3,#3#14+'LO:('+#3#11+laston+#3#14+') AR=');
          for c:='A' to 'Z' do begin
            if (c in ar) then tc(4) else tc(7);
            write(c);
          end;

          cwriteat(1,4, #3#11+stripcolor(computer)+
                        ' ('+cstr(linelen)+'x'+cstr(pagelen)+')');
          cwriteat(38,4,#3#14+ph+'  AC=');
          if (ismono) then cpr($70,$07,thisuser) else cpr(4,7,thisuser);

          cwriteat(1,5, #3#10+note);
          cwriteat(50,5,#3#14+'SL='+#3#11+mn(sl,4)+
                        #3#14+'DSL='+#3#11+mn(dsl,3));

          cwriteat(1,6, #3#9+'ÄÄÄÄÄÄÄÄÂ'+#3#11+'Mins'+
                        #3#9+'ÄÂÄÄÄÄÂÄÄÄÄÄÄÂ'+#3#11+'#New'+
                        #3#9+'Â'+#3#11+'Tim/'+
                        #3#9+'Â'+#3#11+'Pub'+
                        #3#9+'ÄÂ'+#3#11+'Priv'+
                        #3#9+'Â'+#3#11+'Feed'+
                        #3#9+'ÂÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄ');

          cwriteat(1,7, #3#11+'  Date   Activ Call %Activ User User '+
                              'Post Post Back Errs Uploads    Downloads');

          zz[1]:=systat.todayzlog;

          assign(zf,systat.gfilepath+'zlog.dat');
          {$I-} reset(zf); {$I+}
          if (ioresult=0) then begin
            if (eof(zf)) then blankzlog(zz[2]) else read(zf,zz[2]);
            if (eof(zf)) then blankzlog(zz[3]) else read(zf,zz[3]);
            close(zf);
          end else begin
            blankzlog(zz[2]);
            blankzlog(zz[3]);
          end;

          textcolor(9);
          for i:=7 to 10 do
            for j:=1 to 12 do begin
              case j of
                1:k:=9; 2:k:=15; 3:k:=20; 4:k:=27; 5:k:=32; 6:k:=37;
                7:k:=42; 8:k:=47; 9:k:=52; 10:k:=57; 11:k:=68; 12:k:=79;
              end;
              gotoxy(k,i); write('³');
            end;

          textcolor(14);
          for i:=1 to 3 do begin
            if (i=2) then textcolor(11);
            if (i=1) then cwriteat(1,8,'Today''s')
              else cwriteat(1,i+7,zz[i].date);
            cwriteat(10,i+7,mrnn(zz[i].active,5));
            cwriteat(16,i+7,mrnn(zz[i].calls,4));
            cwriteat(21,i+7,ctp(zz[i].active,1440));
            cwriteat(28,i+7,mrnn(zz[i].newusers,4));
            if (zz[i].calls>0) then s:=mrnn(zz[i].active div zz[i].calls,4)
              else s:='';
            cwriteat(33,i+7,s);
            cwriteat(38,i+7,mrnn(zz[i].pubpost,4));
            cwriteat(43,i+7,mrnn(zz[i].privpost,4));
            cwriteat(48,i+7,mrnn(zz[i].fback,4));
            cwriteat(53,i+7,mrnn(zz[i].criterr,4));
            cwriteat(58,i+7,mn(zz[i].uploads,3)+'-'+cstr(zz[i].uk)+'k');
            cwriteat(69,i+7,mn(zz[i].downloads,3)+'-'+cstr(zz[i].dk)+'k');
          end;
        end;
    end;

(*  with thisuser do begin
    gotoxy(2,1);
    tc(14); write(nam+' '); tc(11); write('('+realname+')');
    tc(14);
    gotoxy(2,2); write('SL=     AR=');
    gotoxy(2,3); write('DSL=    AC=');
    tc(11);
    gotoxy(6,2); if res[1]<>255 then write(sl) else write(res[2]);
    gotoxy(6,3); if res[1]<>255 then write(dsl) else write(res[3]);
    gotoxy(13,2);
    for c:='A' to 'Z' do begin
      if (c in ar) then tc(4) else tc(7);
      write(c);
    end;
    gotoxy(13,3); cpr(7,thisuser);
    gotoxy(28,3); write('        ');

    tc(10);
    gotoxy(40,1); write(note);
    tc(14);
    gotoxy(40,2); write(stripcolor(computer)+' (',linelen,'x',pagelen,')');
    gotoxy(40,3); write(ph);
    tc(9);
    spe:=spd;
    if (length(spe)=5) then spe:=copy(spe,1,2)+'.'+copy(spe,3,1);
    if (spe='KB') then spe:='Keys';
    gotoxy(61,3); write('['+spe+']');
    tc(11);
    gotoxy(76,2); write(sex,ageuser(bday));
  end;*)

  commandline(chatr);
  textbackground(0);
  inuserwindow;
  gotoxy(sx,sy); textattr:=sz;
  sde;
  tleft;
  cursoron(TRUE);
end;

procedure gotopx(i:integer; dy:integer);
var y:integer;
begin
  if (systat.istopwindow) then y:=getwindysize(systat.curwindow)-1
    else y:=25;
  if (systat.curwindow=2) then dec(y,5);
  gotoxy(i,y+dy);
end;

procedure tleft;
var s:string[16];
    lng:longint;
    zz:integer;
    sx,sy,sz:byte;
begin
  stsc;
  if ((usernum<>0) and (cwindowon) and (useron)) then begin
    cursoron(FALSE);
    sx:=wherex; sy:=wherey; sz:=textattr;
    window(1,1,80,25);
    gotopx(65,0); clreol;
    if (hangup) then cwrite(#3#21+'Ä'+#3#29+'DROP'+#3#21+'Ä') else
      if (doneafternext) then cwrite(#3#20+'Í'+#3#30+'DNXT'+#3#20+'Í') else
      if (beepend) then cwrite(#3#20+'<'+#3#28+'('+#3#14+'**'+#3#28+')'+#3#20+'>') else
      if (trapping) then cwrite(#3#20+'Ä'+#3#30+'TRAP'+#3#20+'Ä') else
      if (alert in thisuser.ac) then cwrite(#3#20+'Ä'+#3#30+'ALRT'+#3#20+'Ä') else
      if (chatr<>'') then cwrite(#3#25+'Ä'+#3#27+'CHAT'+#3#25+'Ä');
    gotopx(72,0);
    cwrite(#3#7+'TL='+cstrl(trunc(nsl/60)));
    if (sysop) then cwrite(#3#15+'*');
    if (systat.curwindow=2) then begin
      gotopx(72,-1);
      if (thisuser.chatauto) then s:=#3#15 else
        if (systat.autochatopen) then s:=#3#11 else s:=#3#8;
      s:=s+'C';
      if (thisuser.chatseperate) then s:=s+#3#15+'S' else
        s:=s+#3#8+'S';
      if (thisuser.trapactivity) then s:=s+#3#15+'T' else
        if (systat.globaltrap) then s:=s+#3#11+'T' else s:=s+#3#8+'T';
      if (thisuser.trapseperate) then s:=s+#3#15+'S' else
        s:=s+#3#8+'S';
      cwrite(s);
    end;
    inuserwindow;
    gotoxy(sx,sy); textattr:=sz;
    cursoron(TRUE);
  end;
  if ((nsl<0) and (choptime<>0.0)) then begin
    sysoplog('++ Logged user off in preparation for system event');
    nl; nl;
    sprint(#3#7+^G'Shutting down for System Event.'^G);
    nl;
    hangup:=TRUE;
  end;
  if ((not ch) and (nsl<0) and (useron) and (choptime=0.0)) then begin
    nl; nl;

    printf('notleft');
    if (nofile) then
      sprint(#3#7+'You have used up all your time.  Time expired.');

    if (thisuser.timebank<>0) then begin
      nl;
      sprint(#3#5+'Your Time Bank account has '+
             #3#3+cstr(thisuser.timebank)+#3#5+' minutes left in it.');
      dyny:=TRUE;
      if pynq('Withdraw from Time Bank? [Y] : ') then begin
        prt('Withdraw how many minutes? '); inu(zz); lng:=zz;
        if (lng>0) then begin
          if lng>thisuser.timebank then lng:=thisuser.timebank;
          dec(thisuser.timebankadd,lng);
          if (thisuser.timebankadd<0) then thisuser.timebankadd:=0;
          dec(thisuser.timebank,lng);
          inc(thisuser.tltoday,lng);
          sprint('^5In your account: ^3'+cstr(thisuser.timebank)+
                  '^5   Time left online: ^3'+cstr(trunc(nsl) div 60));
          sysoplog('TimeBank: Time expired, withdrew '+cstrl(lng)+' minutes.');
        end;
      end else
        sprint(#3#7+'Hanging up.');
    end;
    if (nsl<0) then hangup:=TRUE;
  end;
  checkhangup;
  sde;
end;

procedure gp(i,j:integer);
var x:integer;
begin
  case j of
    0:gotoxy(58,8);
    1:gotoxy(20,7); 2:gotoxy(20,8); 3:gotoxy(20,9);
    4:gotoxy(20,10); 5:gotoxy(36,7); 6:gotoxy(36,8);
  end;
  if (j in [1..4]) then x:=5 else x:=3;
  if (i=2) then inc(x);
  if (i>0) then gotoxy(wherex+x,wherey);
end;

procedure changeuserdatawindow;
var wind:windowrec;
    s:string[39];
    oo,i,oldsl,{realsl,realdsl,}savsl,savdsl:integer;
    c:char;
    sx,sy,ta:byte;
    done,done1:boolean;

  procedure shd(i:integer; b:boolean);
  var j:integer;
      c:char;
  begin
    gp(0,i);
    if (b) then textcolor(14) else textcolor(9);
    case i of
      1:write('SL  :'); 2:write('DSL :'); 3:write('FP  :');
      4:write('Note:'); 5:write('AR:');   6:write('AC:');
    end;
    if (b) then begin textcolor(0); textbackground(7); end else textcolor(14);
    write(' ');
    with thisuser do
      case i of
        0:if (b) then write('ÄDoneÄ')
          else begin
            textcolor(9); write('Ä');
            textcolor(11); write('Done');
            textcolor(9); write('Ä');
          end;
        1:write(mln(cstr(sl),3));
        2:write(mln(cstr(dsl),3));
        3:write(mln(cstrl(filepoints),5));
        4:write(mln(note,39));
        5:for c:='A' to 'Z' do begin
            if (c in ar) then textcolor(4)
              else if (b) then textcolor(0) else textcolor(7);
            write(c);
          end;
        6:if (b) then cpr($07,$70,thisuser) else cpr($70,$07,thisuser);
      end;
    write(' ');
    textbackground(0);
    cursoron(i in [1..4]);

    if (b) then begin
      gotoxy(26,12); textcolor(14);
      for j:=1 to 41 do write(' ');
      gotoxy(26,12);
      case i of
        0:write('Done -  exit back to BBS');
        1:write('Security Level (0..255)');
        2:write('Download Security Level (0..255)');
        3:write('File Points');
        4:write('Special SysOp note for this user');
        5:write('Special access flags ("!" to toggle all)');
        6:write('Restrictions & special ("!" to clear)');
      end;
    end;
  end;

  procedure ddwind;
  var i:integer;
      c:char;
  begin
    cursoron(FALSE);
    textcolor(9);
    box(1,18,6,68,13); window(19,7,67,12); clrscr;
    box(1,18,6,68,11); window(19,7,67,10);

    window(1,1,80,25);
    gotoxy(20,12); textcolor(9); write('Desc:');

    for i:=0 to 6 do shd(i,FALSE);

    shd(oo,TRUE);
  end;

  procedure ar_tog(c:char);
  begin
    if (c in thisuser.ar) then thisuser.ar:=thisuser.ar-[c]
      else thisuser.ar:=thisuser.ar+[c];
  end;

begin
  saveuf;
{
  if ((realsl<>-1) and (realdsl<>-1)) then begin
    savsl:=thisuser.sl; savdsl:=thisuser.dsl;
    thisuser.sl:=realsl; thisuser.dsl:=realdsl;
    saveuf;
    thisuser.sl:=savsl; thisuser.dsl:=savdsl;
  end;}

  infield_out_fgrd:=0;
  infield_out_bkgd:=7;
  infield_inp_fgrd:=0;
  infield_inp_bkgd:=7;
  infield_arrow_exit:=TRUE;
  infield_arrow_exited:=FALSE;

  sx:=wherex; sy:=wherey; ta:=textattr;
  savescreen(wind,18,6,68,13);
  oo:=1;

  ddwind;
  done:=FALSE;
  repeat
    infield_arrow_exited:=FALSE;
    case oo of
      0:begin
          done1:=FALSE;
          shd(oo,TRUE);
          repeat
            c:=readkey;
            case upcase(c) of
              ^M:begin done:=TRUE; done1:=TRUE; end;
              #0:begin
                   c:=readkey;
                   case ord(c) of
                     ARROW_DOWN,ARROW_UP:
                       begin
                         infield_arrow_exited:=TRUE;
                         infield_last_arrow:=ord(c);
                         done1:=TRUE;
                       end;
                   end;
                 end;
            end;
          until (done1);
        end;
      1:begin
          s:=cstr(thisuser.sl); infield1(26,7,s,3);
          if (value(s)<>thisuser.sl) then begin
            realsl:=value(s);
            thisuser.sl:=value(s);
            inc(thisuser.tltoday,
                systat.timeallow[thisuser.sl]-systat.timeallow[realsl]);
          end;
        end;
      2:begin
          s:=cstr(thisuser.dsl); infield1(26,8,s,3);
          if (value(s)<>thisuser.dsl) then begin
            realdsl:=value(s);
            thisuser.dsl:=value(s);
          end;
        end;
      3:begin
          s:=cstr(thisuser.filepoints); infield1(26,9,s,5);
          thisuser.filepoints:=value(s);
        end;
      4:begin
          s:=thisuser.note; infield1(26,10,s,39);
          thisuser.note:=s;
        end;
      5:begin
          done1:=FALSE;
          repeat
            c:=upcase(readkey);
            case c of
              #13:done1:=TRUE;
              #0:begin
                   c:=readkey;
                   case ord(c) of
                     ARROW_DOWN,ARROW_UP:
                       begin
                         infield_arrow_exited:=TRUE;
                         infield_last_arrow:=ord(c);
                         done1:=TRUE;
                       end;
                   end;
                 end;
              '!':begin
                    for c:='A' to 'Z' do ar_tog(c);
                    shd(oo,TRUE);
                  end;
              'A'..'Z':begin ar_tog(c); shd(oo,TRUE); end;
            end;
          until (done1);
        end;
      6:begin
          s:='LCVBA*PEKM1234';
          done1:=FALSE;
          repeat
            c:=upcase(readkey);
            if (c=#13) then done1:=TRUE
            else
            if (c=#0) then begin
              c:=readkey;
              case ord(c) of
                ARROW_DOWN,ARROW_UP:
                  begin
                    infield_arrow_exited:=TRUE;
                    infield_last_arrow:=ord(c);
                    done1:=TRUE;
                  end;
              end;
            end
            else
            if (pos(c,s)<>0) then begin
              acch(c,thisuser);
              shd(oo,TRUE);
            end
            else begin
              if (c='!') then
                for i:=1 to length(s) do setacch(s[i],FALSE,thisuser);
              shd(oo,TRUE);
            end;
          until (done1);
        end;
    end;
    if (not infield_arrow_exited) then begin
      infield_arrow_exited:=TRUE;
      infield_last_arrow:=ARROW_DOWN;
    end;
    if (infield_arrow_exited) then
      case infield_last_arrow of
        ARROW_DOWN,ARROW_UP:begin
          shd(oo,FALSE);
          if (infield_last_arrow=ARROW_DOWN) then begin
            inc(oo);
            if (oo>6) then oo:=0;
          end else begin
            dec(oo);
            if (oo<0) then oo:=6;
          end;
          shd(oo,TRUE);
        end;
      end;
  until (done);

  removewindow(wind); topscr;
  gotoxy(sx,sy); textattr:=ta;
  cursoron(TRUE);
  if (systat.compressbases) then newcomptables;

  saveuf;

{  if ((realsl<>-1) and (realdsl<>-1)) then begin
    savsl:=thisuser.sl; savdsl:=thisuser.dsl;
    thisuser.sl:=realsl; thisuser.dsl:=realdsl;
    saveuf;
    thisuser.sl:=savsl; thisuser.dsl:=savdsl;
  end;}
end;

procedure readinmacros;
var macrf:file of macrorec;
    i:integer;
begin
  for i:=1 to 4 do macros.macro[i]:='';
  if (thisuser.mpointer<>-1) then begin
    assign(macrf,systat.gfilepath+'macro.lst');
    {$I-} reset(macrf); {$I+}
    if (ioresult<>0) then begin
      sysoplog('!!! "MACRO.LST" file not found.  Created.');
      rewrite(macrf); close(macrf); reset(macrf);
    end;
    if (filesize(macrf)>thisuser.mpointer) then begin
      seek(macrf,thisuser.mpointer);
      read(macrf,macros);
    end else
      thisuser.mpointer:=-1;
    close(macrf);
  end;
end;

procedure saveuf;
var savsl,savdsl:integer;
    ufo:boolean;
begin
  if ((realsl<>-1) and (realdsl<>-1)) then begin
    savsl:=thisuser.sl; savdsl:=thisuser.dsl;
    thisuser.sl:=realsl; thisuser.dsl:=realdsl;

    ufo:=(filerec(uf).mode<>fmclosed);
    if (not ufo) then reset(uf);
    seek(uf,usernum); write(uf,thisuser);
    if (not ufo) then close(uf);

    thisuser.sl:=savsl; thisuser.dsl:=savdsl;
  end;
end;

end.
