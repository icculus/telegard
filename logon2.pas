(*****************************************************************************)
(*>                                                                         <*)
(*>  LOGON2  .PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  Logon functions -- Part 2.                                             <*)
(*>                                                                         <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit logon2;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  mail0, mail1, mail2, mail3, mail4, mail9,
  misc2, miscx,
  cuser,
  doors,
  archive1,
  menus,
  common;

procedure logon;
procedure logoff;
procedure endday;
procedure pver;

implementation

procedure logon;
var ul:text;
    vdata:file of vdatar;
    lcallf:file of lcallers;
    u:userrec;
    vd:vdatar;
    lcall:lcallers;
    lo:array[1..8] of astr;
    s:astr;
    zz:string[5];
    lng:longint;
    num,lcts,hilc,vna,callsleft,ct,z,qq,rcode:integer;
    c:char;
    abort,lastinit:boolean;
    datet:string;
    h, m, x: Word;

  procedure day_desc(dat:astr);
  var d:astr;
      hs:boolean;

    procedure p(s:astr);
    begin
      sprompt(s);
      hs:=TRUE;
    end;

  begin
    hs:=FALSE; d:=copy(date,1,5);
    if (d='01/01') then p('Happy New Year') else
    if (d='07/04') then p('Happy '+#3#7+'4th '+#3#0+'of '+#3#4+'July'+#3#3) else
    if (d='12/24') then p('Happy Christmas Eve') else
    if (d='12/25') then p(#3#9+'Merry '+#3#7+'Christmas'+#3#3);
    
    if (not hs) then
    begin
      if (timer<21600) or (timer>=64800) then p('Good evening') else
      if (timer<43200) and (timer>=21600) then p('Good morning') else
                                               p('Good afternoon');
    end;
  end;

  function checkbday:boolean;
  var i,j:integer;
  begin
    i:=85;
    repeat
      j:=daynum(copy(thisuser.bday,1,6)+tch(cstr(i)));
      if (daynum(date)>=j) and (daynum(thisuser.laston)<j) then begin
        checkbday:=TRUE;
        exit;
      end;
      inc(i);
    until (i>value(copy(date,7,2)));
    checkbday:=FALSE;
  end;

  function bsince:boolean;
  begin
    bsince:=(not (copy(thisuser.bday,1,5)=copy(date,1,5)));
  end;

  procedure showbday(s:astr);
  begin
    nofile:=TRUE;
    if (bsince) then printf('bdys'+s);      {* birthday occured SINCE laston *}
    if (nofile) then printf('bday'+s);      {* birthday TODAY *}
  end;

  procedure findchoptime;
  var lng,lng2,lng3:longint;

    procedure onlinetime;
    var dt:datetimerec;
        secs:longint;
    begin
      secs:=trunc(nsl);
      dt.day:=secs div 86400; secs:=secs-(dt.day*86400);
      dt.hour:=secs div 3600; secs:=secs-(dt.hour*3600);
      dt.min:=secs div 60; secs:=secs-(dt.min*60);
      dt.sec:=secs;
      sprint(^G);
      sprint(#3#8+'** '+#3#5+'System event approaching - online time adjusted to:');
      sprint(#3#8+'** '+#3#0+longtim(dt));
      sprint(^G);
    end;

  begin
    if (exteventtime<>0) then
    begin
      lng:=exteventtime;
      if (lng<trunc(nsl/60.0)) then
      begin
        choptime:=(nsl-(lng*60.0))+120.0; onlinetime; exit;
      end;
    end;
    lng:=1; lng2:=trunc(nsl/60);
    if (lng2>180) then lng2:=180;
    while (lng<=lng2) do
    begin
      lng3:=lng*60;
      if (checkevents(lng3)<>0) then
      begin
        choptime:=(nsl-(lng*60.0))+60.0; onlinetime; exit;
      end;
      inc(lng,2);
    end;
  end;

begin
  getdatetime(timeon); mread:=0; extratime:=0.0; freetime:=0.0;
  useron:=TRUE; com_flush_rx; logon1st;

  if ((thisuser.sl=255) and (not fastlogon) and (spd<>'KB')) then
  begin
    if pynq('Fast logon? ') then fastlogon:=TRUE;
    nl;
  end;

  lastinit:=FALSE; assign(lcallf,systat.gfilepath+'laston.dat');
  {$I-} reset(lcallf); {$I+}
  if (ioresult<>0) then
  begin
    lastinit:=TRUE; rewrite(lcallf); lcall.callernum:=-1;
    for z:=0 to 9 do write(lcallf,lcall);
  end;
  if (systat.lcallinlogon) then
  begin
    if (cso) then lcts:=10 else lcts:=4;
    lcall.callernum:=0; z:=0; hilc:=9;
    for z:=0 to 9 do
    begin
      seek(lcallf,z); read(lcallf,lcall);
      if (lcall.callernum=-1) and (hilc=9) then hilc:=z-1;
    end;
    if (hilc<>-1) then
    begin
      if (not cso) and (hilc>3) then hilc:=3;
      sprint(#3#5+'Last few callers:');
      for z:=hilc downto 0 do
      begin
        seek(lcallf,z); read(lcallf,lcall);
        with lcall do
          sprint(#3#3+cstr(callernum)+': '+#3#0+name+
                 #3#2+' #'+#3#4+cstr(number)+#3#3+' from '+#3#0+citystate+#3#3+' at '+#3#4+datet);
      end;
    end;
    nl;
  end;
  if ((spd<>'KB') or (lastinit)) then
  begin
    for z:=9 downto 1 do
    begin
      seek(lcallf,z-1); read(lcallf,lcall);
      seek(lcallf,z); write(lcallf,lcall);
    end;
    with lcall do
    begin
      callernum:=systat.callernum; name:=caps(thisuser.name);
      number:=usernum;             citystate:=thisuser.citystate;
      datet:=dat;
     end;
    seek(lcallf,0); write(lcallf,lcall);
  end;
  close(lcallf);

  if ((not fastlogon) and (not hangup)) then
  begin
    printf('logon'); pausescr; nofile:=FALSE; z:=0;
    repeat
      inc(z); printf('logon'+cstr(z));
    until (z=9) or (nofile) or (hangup);

    printf('sl'+cstr(thisuser.sl));
    printf('dsl'+cstr(thisuser.dsl));
    for c:='A' to 'Z' do
      if (c in thisuser.ar) then printf('arlevel'+c);
    printf('user'+cstr(usernum));

    if (checkbday) then
    begin
      showbday(cstr(usernum));
      if nofile then showbday('');
      if nofile then
        if bsince then begin
          sprint(#3#4+'-------------------------------------------------------------------');
          sprint(#3#3+'Happy Birthday, '+caps(thisuser.name)+' !!!');
          sprint(#3#3+'You turned '+cstr(ageuser(thisuser.bday))+' on '+
                 copy(thisuser.bday,1,5)+copy(date,6,3)+'!!');
          sprint(#3#3+'(a little late, but it''s the thought that counts!)');
          sprint(#3#4+'-------------------------------------------------------------------');
          nl;
        end else begin
          sprint(#3#4+'-------------------------------------------------------------------');
          sprint(#3#3+'Happy Birthday, '+caps(thisuser.name)+' !!!');
          sprint(#3#3+'You turned '+cstr(ageuser(thisuser.bday))+' today!!');
          sprint(#3#4+'-------------------------------------------------------------------');
          nl;
        end;
    end;

    if (exist('logon.bat')) then
    begin
      shelldos(FALSE,process_door('logon.bat @F @L @B @G @T @R'),rcode);
      topscr;
    end;
    nl; cl(5);
    if (sysop) then sprint(fstring.sysopin) else sprint(fstring.sysopout);
    if (systat.autominlogon) then readamsg;
    nl;
  end;

  if (not wasguestuser) then
  begin
    if (thisuser.flistopt=0) then thisuser.flistopt:=1;
    if (thisuser.bday='00/00/00') then begin
      print('Updating system records ...');
      cstuff(2,1,thisuser);
      nl;
    end;
    if (thisuser.citystate='') or (thisuser.citystate='Unknown, MI') then
      cstuff(4,1,thisuser);
    if (thisuser.clsmsg=0) then
    begin
      nl;
      print('Updating user account ... Do you prefer:');
      nl;
      print('  (1.) A clear-screen before each message');
      print('  (2.) Continuous listing of messages, with no screen clearing.');
      nl;
      prt('Enter selection: '); onek(c,'12');
      if (not hangup) then
        if (c='1') then thisuser.clsmsg:=1 else thisuser.clsmsg:=2;
    end;
    if (thisuser.avadjust=0) then
    begin
      thisuser.avadjust:=1;
      thisuser.ac:=thisuser.ac-[avatar];
    end;
  end;

  if (thisuser.computer='Unknown') then
  begin
    cstuff(5,1,thisuser); nl;
  end;
  savesystat;

  with thisuser do
  begin
    if ((not fastlogon) and (not hangup)) then begin
      if (systat.yourinfoinlogon) then begin pausescr; yourinfo; nl; end;
      cl(3); day_desc(dat); sprint(', '+nam+'.');
      nl;
      sprint(#3#3+'You are caller '+#3#4+'#'+#3#0+cstr(systat.callernum)+',');
      if (systat.todayzlog.calls<>0) then
      begin
        sprompt(#3#3+'the ');
        zz:=cstr(systat.todayzlog.calls); zz:=copy(zz,length(zz),1);
        z:=value(zz); ct:=systat.todayzlog.calls;
        if (ct in [11..13]) then z:=4;
        sprompt(#3#0+cstr(systat.todayzlog.calls)+#3#4);
        case z of
          1:sprompt('st');
          2:sprompt('nd');
          3:sprompt('rd');
        else
            sprompt('th');
        end;
        sprint(#3#3+' caller for today.');
      end;

      nl;
      lmsg:=FALSE;

      sprint('Time allowed    - '+#3#3+cstr(systat.timeallow[thisuser.sl])+' minutes');
      if (waiting<>0) then
      begin
        sprompt('Mail waiting    - '+#3#3+cstr(waiting)+' letter');
        if (waiting>1) then print('s') else nl;
      end;
      if (illegal<>0) then
        sprint(^G+#3#8+'Illegal logons  - '+cstr(illegal)+' attempts ');
      if (loggedon<>0) then
        sprint('You have called - '+#3#3+cstr(loggedon)+' times');
      if (laston<>date) then
        sprint('Last on         - '+#3#3+laston)
      else
        sprint('Calls today     - '+#3#3+cstr(ontoday)+' times');
      sprompt('Account limits  - '+#3#3+cstr(systat.callallow[thisuser.sl])+' call');
      if (systat.callallow[thisuser.sl]<>1) then sprompt('s');
      sprompt(', using a maximum of '+cstr(systat.timeallow[thisuser.sl])+' minutes, ');
      if TRUE {*****} then sprint('per day.') else sprint('per call.');
      nl;

      if (daynum(laston)<=daynum(systat.tfiledate)) and
        (daynum(laston)>0) then
      begin
        sprint(#3#5+'There may be new text files available.');
      end;

      vna:=0;
      assign(vdata,systat.gfilepath+'voting.dat');
      {$I-} reset(vdata); {$I+}
      if (ioresult=0) then begin
        for num:=1 to 20 do begin
          seek(vdata,num-1); read(vdata,vd);
          if (vd.numa<>0) then
            if (vote[num]=0) then inc(vna);
        end;
        close(vdata);
        if (vna>0) then
        begin
          sprompt(#3#5+'You have not voted on '+#3#9+cstr(vna)+#3#5+' voting question');
          if (vna>1) then sprint('s.') else sprint('.');
          if (systat.forcevoting) and (not (rvoting in thisuser.ac)) then begin
            nl;
            while (not empty) do getkey(c);
            pausescr;
            misc1.vote;
          end;
        end;
      end;

      if (forusr<>0) then
        sprint(#3#7+'Your mail is being forwarded to user #'+cstr(forusr));
      nl;
      topscr;
    end;
  end;

  findchoptime;

  with thisuser do
  begin
    if (smw in ac) then begin rsm; nl; end;
    ac:=ac-[smw];
    if ((alert in ac) and (sysop)) then chatcall:=TRUE;
    if (waiting<>0) then begin
      if pynq('Read your mail now? ') then readmail;
      nl;
    end;
  end;
  if ((not fastlogon) and (systat.bullinlogon)) then bulletins('');

  fastlogon:=FALSE;
end;

procedure logoff;
var ddt,dt:datetimerec;
    i,tt,rcode:integer;
begin
  if ((useron) and (usernum>0)) then
    if (exist('logoff.bat')) then
      shelldos(FALSE,process_door('logoff.bat @F @L @B @G @T @R'),rcode);

  term_ready(FALSE);

  if ((useron) and (usernum>0)) then
  begin
    {rcg11242000 dosisms.}
    {
    purgedir(systat.temppath+'1\');
    purgedir(systat.temppath+'2\');
    purgedir(systat.temppath+'3\');
    }
    purgedir(systat.temppath+'1/');
    purgedir(systat.temppath+'2/');
    purgedir(systat.temppath+'3/');

    slogging:=TRUE;

    if (trapping) then
    begin
      if (hungup) then
      begin
        writeln(trapfile);
        writeln(trapfile,'NO CARRIER');
      end;
      close(trapfile); trapping:=FALSE;
    end;

    getdatetime(dt); timediff(ddt,timeon,dt); tt:=trunc((dt2r(ddt)+30)/60);

    thisuser.laston:=systat.lastdate; inc(thisuser.loggedon);

    (* if not logged in, but logged on *)
    if (realsl<>-1) then thisuser.sl:=realsl;
    if (realdsl<>-1) then thisuser.dsl:=realdsl;

    thisuser.illegal:=0; thisuser.ttimeon:=thisuser.ttimeon+tt;
    if (choptime<>0.0) then inc(thisuser.tltoday,trunc(choptime/60.0));
    thisuser.tltoday:=trunc(nsl/60.0);
    thisuser.lastmsg:=board; thisuser.lastfil:=fileboard;

    reset(uf);
    if ((usernum>=1) and (usernum<=filesize(uf)-1)) then
      begin seek(uf,usernum); write(uf,thisuser); end;
    close(uf);

    if (spd<>'KB') then inc(systat.todayzlog.active,tt);
    inc(systat.todayzlog.fback,ftoday);
    inc(systat.todayzlog.privpost,etoday);
    savesystat;

    for i:=1 to hiubatchv do release(ubatchv[i]); {* release dynamic memory *}
    window(1,1,80,25); clrscr;
    if (hungup) then sl1(#3#7+'>>*>*>*> Hung Up <*<*<*<<');
    sl1(#3#4+'Read: '+#3#3+cstr(mread)+#3#4+' / Time on: '+#3#3+cstr(tt));
  end;
end;

procedure endday;
var d,i,tu,fu:integer;
begin
  useron:=FALSE;
  d:=daynum(date);
  if (d<>ldate) then
    if (d-ldate)=1 then
      inc(ldate)
    else begin
      writeln('Date corrupted.');
      halt(1);
    end;

(*****
  reset(mailfile);
  for i:=0 to filesize(mailfile)-1 do begin
    seek(mailfile,i); read(mailfile,mr);
    if (old(mr.date,mr.mage) and (mr.destin<>-1)) then begin
      fu:=abs(mr.from);
      is:=rmail(i);
      ssm(fu,is+' never got your letter.');
    end;
  end;
  close(mailfile);
  reset(uf);
  for board:=1 to numboards do begin
    iscan;
    cn:=1;
    while (cn<=tnum) do begin
      if (old(mary[cn].date,mary[cn].mage)) or
         (mary[cn].messagestat=deleted) then
        deletem(cn)
      else
        inc(cn);
    end;
    savebase;
  end;
  close(uf);
 *****)
end;

procedure pver;
var abort,next,aa:boolean;
begin
  abort:=FALSE; next:=FALSE;
  aa:=allowabort; allowabort:=FALSE;

  nl;
  printacr(verline(1),abort,next);
  printacr(verline(2),abort,next);
  nl;

  allowabort:=aa;
end;

end.
