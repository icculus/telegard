(*****************************************************************************)
(*>                                                                         <*)
(*>  LOGON1  .PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  Logon functions -- Part 1.                                             <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit logon1;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  logon2, newusers,
  mail0, mail1, mail2, mail3, mail4,
  misc2, miscx,
  cuser,
  doors,
  archive1,
  menus, menus2,
  common;

function getuser:boolean;

implementation

const
  ilogon=^G'FAILED LOGON ATEMP'^G;

procedure getpws(var ok:boolean; var tries:integer);
var phone,pw,s:astr;
begin
  ok:=TRUE; echo:=FALSE;
  commandline('Password - "'+thisuser.pw+'"');
  sprompt(#3#0+'User password   : '+#3#5); input(pw,20);
  if (systat.phonepw) then
  begin
    commandline('Phone # - "'+thisuser.ph+'"');
    sprompt(#3#0+'Complete phone #: '+#3#5+'###-###-');
    input(phone,4); echo:=TRUE;
  end else
    phone:=(copy(thisuser.ph,9,4));
  echo:=TRUE;
  if ((thisuser.pw<>pw) or (copy(thisuser.ph,9,4)<>phone)) then
  begin
    nl; print(ilogon); nl;
    if (not hangup) and (usernum<>0) then begin
      s:=#3#8+'>>'+#3#1+' Illegal logon attempt! Tried: '+
         caps(thisuser.name)+' #'+cstr(usernum);
      if (usernum<>1) then
      begin
        s:=s+' PW="'+pw+'"';
        if (systat.phonepw) then s:=s+', PH#="'+phone+'"';
      end;
      sl1(s);
    end;
    inc(thisuser.illegal);
    seek(uf,usernum); write(uf,thisuser);
    inc(tries); if (tries>=systat.maxlogontries) then hangup:=TRUE;
    ok:=FALSE;
  end;
  if ((aacs(systat.spw)) and (ok) and (incom) and (not hangup)) then
  begin
    echo:=FALSE;
    sprompt(#3#0+'System password: '+#3#5);
    input(pw,20);
    if (pw<>systat.sysoppw) then
    begin
      nl; print(ilogon); nl;
      sl1(#3#8+'>>'+#3#1+' Illegal System password'); inc(tries);
      if (tries>=systat.maxlogontries) then hangup:=TRUE;
      ok:=FALSE;
    end;
    echo:=TRUE;
  end;
  if ((ok) and (systat.shuttlelog) and (thisuser.lockedout)) then
  begin
    printf(thisuser.lockedfile);
    sysoplog(#3#7+'['+#3#8+'*'+#3#7+'] '+#3#3+thisuser.name+#3#7+' --> '+#3#5+
             'Attempt to access system when locked out'+#3#7+' <--');
    hangup:=TRUE;
  end;
end;

procedure doshuttle;
var s,cmd,pw,newmenucmd:astr;
    tries,i,nocsave:integer;
    loggedon,gotname,noneedname,ok,cmdnothid,cmdexists:boolean;
begin
  nl;
  print('[> Project Coyote / Shuttle Logon @ '+dat+' ('+spd+' bps)');
  nl;
  with thisuser do
  begin
    if pynq('Do you desire ANSI graphics? ') then ac:=ac+[ansi] else ac:=ac-[ansi];
    ac:=ac-[avatar];
  end;
  nl; printf('preshutl'); last_menu:='shuttle.mnu';
  curmenu:=systat.menupath+last_menu; readin;

  loggedon:=FALSE; gotname:=FALSE; tries:=0;

  chelplevel:=2;
  repeat
    tshuttlelogon:=0;
    mainmenuhandle(cmd);
    if ((not gotname) and (cmd<>'')) then
    begin
      noneedname:=TRUE; i:=0;
      repeat
        fcmd(cmd,i,noc,cmdexists,cmdnothid);
        if (i<>0) then
          if (cmdr[i].cmdkeys<>'OP') and (cmdr[i].cmdkeys<>'O1') and
             (cmdr[i].cmdkeys<>'O2') and (cmdr[i].cmdkeys[1]<>'H') then
            noneedname:=FALSE;
      until (i=0);
      if (not noneedname) then
      begin
        nl;
        sprompt(#3#0+'Enter your user name or number : ');
        finduser(s,usernum);
        if (usernum>=1) then begin
          reset(uf); seek(uf,usernum); read(uf,thisuser);
          getpws(ok,tries);
          gotname:=ok;
          nl;
          if (gotname) then
          begin
            readinmacros; readinzscan; useron:=TRUE;
            schangewindow(TRUE,systat.curwindow); commandline('');
            print('"'+thisuser.name+'" logged on.');
            sysoplog('Logged on to Shuttle Menu as '+caps(thisuser.name)+' #'+
                     cstr(usernum));
            if (thisuser.waiting<>0) then
            begin
              nl; nl;
              sprint(#3#5+'NOTE: '+#3#3+'You have '+
                     #3#0+cstr(thisuser.waiting)+
                     #3#3+' pieces of mail waiting.');
              nl;
              if pynq('Read it now? ') then readmail;
              nl;
            end;
          end;
        end else
          print('You are not a member of this BBS.');
      end;
    end;
    if ((gotname) or (noneedname)) then
    begin
      newmenucmd:='';
      repeat domenuexec(cmd,newmenucmd) until (newmenucmd='');
      case tshuttlelogon of
        1:if (systat.shuttlepw='') then loggedon:=TRUE
          else begin
            nl;
            echo:=FALSE;
            sprompt(#3#0+'Enter BBS Password: '); input(pw,20); nl;
            echo:=TRUE;
            if (pw=systat.shuttlepw) then loggedon:=TRUE
            else begin
              sl1(#3#8+'>>'+#3#1+' Illegal Shuttle Logon password: "'+pw+'"');
              print(ilogon);
              inc(tries);
            end;
          end;
        2:if (gotname) then
        begin
            nl;
            print('You already ARE a user!');
            print('Why do you want to log on as new again!?');
            print('Sheesshhhhh.....');
            delay(1500);
          end else
          begin
            nl;
            if pynq('Log on as a NEW USER? ') then
            begin
              newuserinit('');
              newuser;
              if (usernum>0) and (not hangup) then
              begin
                gotname:=TRUE; useron:=TRUE; logon1st;
              end;
            end;
          end;
        3:if ((thisuser.sl>systat.newsl) or
              (thisuser.dsl>systat.newdsl)) then
          begin
            sysoplog('Found out the Shuttle password.'); nl;
            print('You are a validated member of this BBS.');
            print('The BBS password is "'+systat.shuttlepw+'"');
            sprint('^3Write it down ^1for faster logons in the future!');
            nl; loggedon:=pynq('Log on now? ');
          end else
          begin
            nl; print('Sorry, you have not been validated yet.');
            sysoplog('Tried to find out Shuttle password - was not validated.');
          end;
      end;
    end;
    if (tries=systat.maxlogontries) then hangup:=TRUE;
  until (loggedon) or (hangup);
end;

procedure getacsuser(eventnum:integer; acsreq:astr);
var user:userrec;
    sr:smalrec;
    r:real;
    s,pw:astr;
    cp,un,i:integer;
    c:char;
    sfo:boolean;

  procedure dobackspace;
  begin
    dec(cp);
    outkey(^H); outkey(' '); outkey(^H);
  end;

begin
  printf('acsea'+cstr(eventnum));
  if (nofile) then begin
    print('Restricted time zone.');
    print('Only certain users allowed online at this time.');
  end;
  nl;
  print('Current time: '+date+' '+time+'.');
  print('Enter your user name/number *now*.');
  print('If you do not enter within 20 seconds, you will be hung up.');
  prt(':');
  checkhangup;
  if (hangup) then exit;
  r:=timer; s:=''; cp:=1; echo:=TRUE;
  repeat
    checkhangup;
    c:=inkey;
    if (c<>#0) then
      case c of
        ^H:if (cp>1) then dobackspace;
        ^X:while (cp<>1) do dobackspace;
        #32..#255:
           if (cp<=36) then begin
             c:=upcase(c);
             outkey(c);
             s[cp]:=c; inc(cp);
           end;
      end;
    if (timer-r>20.0) then hangup:=TRUE;
  until ((c=^M) or (hangup));
  s[0]:=chr(cp-1);
  if (not hangup) then begin
    nl; nl;
    un:=value(s);
    if (un<>0) then begin
      reset(uf);
      if (un>filesize(uf)-1) then un:=0
      else begin
        seek(uf,un);
        read(uf,user);
      end;
      close(uf);
    end else begin
      sfo:=(filerec(sf).mode<>fmclosed);
      if (not sfo) then reset(sf);
      un:=0; i:=1;
      while ((i<=filesize(sf)-1) and (un=0)) do begin
        seek(sf,i); read(sf,sr);
        if (s=sr.name) then un:=sr.number;
        inc(i);
      end;
      if (un>filesize(sf)-1) then un:=0;
      if (not sfo) then close(sf);
      if (un<>0) then begin
        reset(uf);
        seek(uf,un); read(uf,user);
        close(uf);
      end;
    end;
    if (un<>0) then usernum:=un;
    if ((user.deleted) or (not aacs1(user,usernum,acsreq))) then un:=0;
    if (un=0) then begin
      print('Invalid user account.'); nl;
      printf('acseb'+cstr(eventnum));
      if (nofile) then begin
        print('This time window allows certain other users to get online.');
        print('Please call back later, after it has ended.');
      end;
      hangup:=TRUE;
    end else begin
      print('Valid user account - Welcome.');
      nl;
      echo:=FALSE;
      sprompt('Enter your password: '); input(pw,20);
      if (pw<>user.pw) then begin
        nl;
        print('Invalid password.  Hanging up.'); nl;
        printf('acseb'+cstr(eventnum));
        if (nofile) then begin
          print('This time window allows certain other users to get online.');
          print('Please call back later, after it has ended.');
        end;
        hangup:=TRUE;
      end else
        nl;
      echo:=TRUE;
    end;
  end;
end;

function getuser:boolean;
var pw,s,phone,newusername,acsreq:astr;
    lng:longint;
    tries,i,ttimes,z,zz,eventnum:integer;
    done,nu,ok,toomuch,wantnewuser,acsuser:boolean;
begin
  wasnewuser:=FALSE; wasguestuser:=FALSE;
  thisuser.tltoday:=15;  { allow user 15 minutes to log on >MAX< }
  extratime:=0.0; freetime:=0.0; choptime:=0.0;
  with thisuser do begin
    usernum:=-1;
    name:='NO USER'; realname:='Not entered yet';
    sl:=0; dsl:=0; ar:=[];
    ac:=[onekey,pause,novice,color]; ac:=ac+systat.newac;
    linelen:=80; pagelen:=25;
  end;
  getdatetime(timeon);
  mread:=0; extratime:=0.0; freetime:=0.0;
  realsl:=-1; realdsl:=-1;
  newusername:='';

  sl1('');
  s:=#3#3+'Logon '+#3#5+'['+dat+']'+#3#4+' (';
  if (spd<>'KB') then s:=s+spd+' baud)' else s:=s+'Keyboard)';
  sl1(s);
  wantnewuser:=FALSE;
  macok:=FALSE; nu:=FALSE;
  echo:=TRUE; nl;
  pw:='';

  if (spd='300') then
  begin
    if (systat.lock300) then
    begin
      printf('no300.msg');
      if (nofile) then print('300 baud callers not allowed on this BBS.');
      hangup:=TRUE;
    end;
    if ((systat.b300lowtime<>0) or (systat.b300hitime<>0)) then
      if (not intime(timer,systat.b300lowtime,systat.b300hitime)) then begin
        printf('no300h.msg');
        if (nofile) then
          print('300 baud calling hours are from '+ctim(systat.b300lowtime)+
                ' to '+ctim(systat.b300hitime));
        hangup:=TRUE;
      end;
    if (not hangup) then
      if ((systat.b300lowtime<>0) or (systat.b300hitime<>0)) then begin
        printf('yes300h.msg');
        if (nofile) then begin
          print('NOTE: 300 baud calling times are');
          print('restricted to the following hours ONLY:');
          print('  '+ctim(systat.b300lowtime)+' to '+ctim(systat.b300hitime));
        end;
      end;
  end;

  acsuser:=FALSE;
  for i:=0 to numevents do
    with events[i]^ do
      if ((etype='A') and (active) and (checkeventtime(i,0))) then begin
        acsuser:=TRUE;
        acsreq:=events[i]^.execdata;
        eventnum:=i;
      end;

  if (acsuser) then getacsuser(eventnum,acsreq);

  if ((systat.shuttlelog) and (not fastlogon) and (not hangup)) then doshuttle;

  nl;
  pver;
  if (not wantnewuser) and (not fastlogon) then begin
    if pynq(fstring.ansiq) then thisuser.ac:=thisuser.ac+[ansi]
      else thisuser.ac:=thisuser.ac-[ansi];
    thisuser.ac:=thisuser.ac-[avatar];
    printf('welcome');
    z:=0;
    repeat
      inc(z);
      printf('welcome'+cstr(z));
    until (z=9) or (nofile) or (hangup);
  end;
  ttimes:=0; tries:=0; s:='';
  repeat
    repeat
      if (not wantnewuser) then begin
        if (systat.multitask) then
          print('[> System under Multitasking environment <]');
        if (fstring.note[1]<>'') then sprint(fstring.note[1]);
        if (fstring.note[2]<>'') then sprint(fstring.note[2]);
        if ((systat.guestuser<>-1) and (fstring.guestline<>'')) then
          sprint(fstring.guestline);
        if (fstring.lprompt<>'') then sprompt(fstring.lprompt);
      end;
      if (systat.shuttlelog) and (wantnewuser) then begin
        s:='';
        usernum:=-1;
      end else
        finduser(s,usernum);

      if (pos('@',s)<>0) then begin
        nl;
        print('Nice try, idiot - that no longer works.');
        print('(SysOp has been notified.)');
        sl1('Idiot tried to gain illegal system info with @@ MCI usage at logon');
        hangup:=TRUE;
      end;

      if (not hangup) then begin
        nl;
        newusername:='';
        if (usernum=0) then
          if (s<>'') then begin
            sprint(fstring.namenotfound);
            if pynq('"'+s+'" - Log on as NEW? ') then usernum:=-1;
            nl;
            newusername:=s;
          end else begin
            inc(ttimes);
            if (ttimes>systat.maxlogontries) then hangup:=TRUE;
          end;
      end;
    until ((usernum<>0) or (hangup));
    ok:=TRUE; done:=FALSE;
    if (not hangup) then
      case usernum of
       -1:begin
            newuserinit(newusername);
            nu:=TRUE;
            done:=TRUE; ok:=FALSE;
          end;
       -2:begin
            reset(uf);
            usernum:=systat.guestuser;
            if (usernum>filesize(uf)-1) then begin
              sl1(#3#8+'>>'+#3#1+' Guest user account unavailable!');
              print('Guest user account unavailable.');
              print('SysOp will be notified.');
              hangup:=TRUE;
            end else begin
              seek(uf,systat.guestuser); read(uf,thisuser);
              print('Terminal configuration:');
              cstuff(11,1,thisuser);
              cstuff(3,1,thisuser);
              nl;
              print('As a guest user we ask that you enter a unique name for our system records.');
              cstuff(7,1,thisuser);
              nl;
              wasguestuser:=TRUE; done:=TRUE;
            end;
            close(uf);
          end;
      else
          if (usernum=-3) then begin
            nl;
            print('Nice try, idiot - that no longer works.');
            print('(SysOp has been notified.)');
            sl1('Idiot tried to crash system with negative number entry at logon');
            hangup:=TRUE;
          end else begin
            reset(uf);
            seek(uf,usernum); read(uf,thisuser);
            echo:=FALSE;
            if (not systat.localsec) then begin
              if (not useron) then begin
                useron:=TRUE;
                schangewindow(TRUE,systat.curwindow);
              end else
                schangewindow(FALSE,systat.curwindow);
              commandline('Password - "'+thisuser.pw+'"');
              useron:=FALSE;
            end;

            getpws(ok,tries);
            if (ok) then
            begin
              done:=TRUE;
              readinmacros; readinzscan;
            end;

            close(uf);
            if (not ok) then begin
              useron:=TRUE; sclearwindow; useron:=FALSE;
            end;
          end;
    end;
  until ((done) or (hangup));
  if ((thisuser.lockedout) and (not hangup)) then begin
    printf(thisuser.lockedfile);
    sysoplog(#3#7+'['+#3#8+'*'+#3#7+'] '+#3#3+thisuser.name+#3#7+' --> '+#3#5+
             'Attempt to access system when locked out'+#3#7+' <--');
    hangup:=TRUE;
  end;
  if ((not nu) and (not hangup)) then
  begin
    toomuch:=FALSE;
    if (thisuser.laston<>date) then begin
      thisuser.ontoday:=0;
      thisuser.tltoday:=systat.timeallow[thisuser.sl];
    end;
    if (((rlogon in thisuser.ac) or (systat.callallow[thisuser.sl]=1)) and
       (thisuser.ontoday>=1) and (thisuser.laston=date)) then begin
      printf('2manycal');
      if (nofile) then print('You can only log on once per day.');
      toomuch:=TRUE;
    end else
      if ((thisuser.ontoday>=systat.callallow[thisuser.sl]) and
          (thisuser.laston=date)) then begin
        printf('2manycal');
        if (nofile) then
          print('You can only log on '+cstr(systat.callallow[thisuser.sl])+' times per day.');
        toomuch:=TRUE;
      end else
        if ((thisuser.tltoday<=0) and (thisuser.laston=date)) then begin
          printf('notlefta');
          if (nofile) then
            prompt('You can only log on for '+cstr(systat.timeallow[thisuser.sl])+' minutes per day.');
          toomuch:=TRUE;
          if (thisuser.timebank>0) then begin
            nl; nl;
            sprint(#3#5+'However, you have '+cstrl(thisuser.timebank)+
                   ' minutes left in your Time Bank.');
            dyny:=TRUE;
            if pynq('Withdraw from Time Bank? [Y] : ') then begin
              prt('Withdraw how many minutes? '); inu(zz); lng:=zz;
              if (lng>0) then begin
                if (lng>thisuser.timebank) then lng:=thisuser.timebank;
                dec(thisuser.timebankadd,lng);
                if (thisuser.timebankadd<0) then thisuser.timebankadd:=0;
                dec(thisuser.timebank,lng);
                inc(thisuser.tltoday,lng);
                sprint('^5In your account: ^3'+cstr(thisuser.timebank)+
                        '^5   Time left online: ^3'+cstr(trunc(nsl) div 60));
                sysoplog('TimeBank: No time left at logon, withdrew '+cstrl(lng)+' minutes.');
              end;
            end;
            if (nsl>=0) then toomuch:=FALSE else sprint(#3#7+'Hanging up.');
          end;
        end;
    if (toomuch) then
    begin
      sl1(#3#7+' [*] '+#3#1+thisuser.name+' #'+cstr(usernum)+' tried logging on more than allowed.');
      hangup:=TRUE;
    end;
    if (tries=systat.maxlogontries) then hangup:=TRUE;
    if (not hangup) then inc(thisuser.ontoday);
  end;
  checkit:=FALSE;
  if ((usernum>0) and (not hangup)) then
  begin
    getuser:=nu;
    useron:=TRUE;
    schangewindow(not cwindowon,systat.curwindow);
    commandline('- Successful Logon -');
    useron:=FALSE;
    inittrapfile;
    s:=#3#3+'Welcome to '+systat.bbsname+#3#3;
    if (fidor.net<>0) then s:=s+' ('+cstr(fidor.zone)+':'+cstr(fidor.net)+'/'+
      cstr(fidor.node)+'.'+cstr(fidor.point)+')';
    s:=s+', '+nam;
    nl; sprint(s); nl;
  end;
  if (hangup) then getuser:=FALSE;
end;

end.
