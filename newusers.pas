(*****************************************************************************)
(*>                                                                         <*)
(*>  NEWUSERS.PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  Logon functions -- New users.                                          <*)
(*>                                                                         <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit newusers;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  mail0, mail1, mail2, mail3,
  misc2, misc3, misc4, miscx,
  cuser,
  doors,
  archive1,
  menus,
  common;

procedure newuser;
procedure newuserinit(nam:astr);

implementation

var
  newusername:astr;

procedure p1;
var c:char;
    tries,i,ii,t:integer;
    s,s1,s2:astr;
    atype,pw:astr;
    done,abort,next,choseansi,chosecolor:boolean;

  procedure showstuff;
  begin
    nl; nl; printf('system');
    nl; nl; printf('newuser');
    if (systat.newuserpw<>'') then begin
      tries:=0; pw:='';
      while ((pw<>systat.newuserpw) and
            (tries<systat.maxlogontries) and (not hangup)) do begin
        prt('Newuser password : '); echo:=FALSE; input(pw,20); echo:=TRUE;
        if ((systat.newuserpw<>pw) and (pw<>'')) then begin
          sl1(#3#8+'>>'+#3#1+' Illegal newuser password: "'+pw+'"');
          inc(tries);
        end;
      end;
      if (tries>=systat.maxlogontries) then begin
        printf('nonewusr');
        hangup:=TRUE;
      end;
    end;
  end;

  procedure doitall;
  type neworderrec=array[1..17] of integer;
  const neworder:neworderrec=(7,10,23,1,4,14,8,12,2,5,6,13,3,11,24,9,-1);
  var i:integer;
      c:char;
  begin
    showstuff;
    if (newusername<>'') then begin
      thisuser.name:=newusername;
      newusername:='';
      i:=2;
    end else
      i:=1;
    repeat
      cstuff(neworder[i],1,thisuser);
      inc(i);
    until ((neworder[i]=-1) or (hangup));
  end;

  procedure dc(var abort:boolean; c:char; n,v:astr);
  begin
    printacr(#3#1+'['+#3#3+c+#3#1+'] '+
             #3#4+mln(n,11)+#3#2+' - '+#3#5+v,abort,next);
  end;

begin
  t:=0;
  doitall;
  if (not hangup) then
    repeat
      done:=FALSE;
      cls;
      abort:=FALSE; next:=FALSE;
      printacr(#3#5+'User Information Change',abort,next);
      nl;
      if (ansi in thisuser.ac) then begin
        atype:='Enabled';
        if (color in thisuser.ac) then atype:=atype+' w/ color'
        else atype:=atype+' w/o color';
      end else
        atype:='Disabled';
      with thisuser do begin
        dc(abort,'A','System name',name);
        dc(abort,'B','Real name',  realname);
        dc(abort,'C','Phone #',    ph);
        dc(abort,'D','Computer',   computer);
        dc(abort,'E','Sex',        sex);
        dc(abort,'F','Birthdate',  bday+' ('+cstr(ageuser(bday))+' years old)');
        dc(abort,'G','City, State',citystate);
        dc(abort,'H','Address',    street);
        dc(abort,'I','Zip code',   zipcode);
        dc(abort,'J','Occupation', occupation);
        dc(abort,'K','Heard from', wherebbs);
        dc(abort,'L','ANSI',       atype);
        dc(abort,'M','Screen size',cstr(linelen)+'x'+cstr(pagelen));
        dc(abort,'N','Password',   pw);
      end;
      nl;
      prt('Selection (A-N) to change, Y when finished :');
      onek(c,'YABCDEFGHIJKLMN');
      if (c<>'Y') then cstuff(pos(c,'HFLGDJACNBMEKI'),1,thisuser) else done:=TRUE;
    until ((done) or (hangup));
end;

procedure p2;
var user:userrec;
    pw:string;
    tries,i,j:integer;
    c:char;
begin
  if (not hangup) then begin
    nl; prompt('Please wait while I save your record ... ');

    reset(uf);
    j:=0;
    for i:=1 to filesize(uf)-1 do begin
      seek(uf,i); read(uf,user);
      if ((user.deleted) and (j=0)) then j:=i;
    end;
    if (j<>0) then usernum:=j else usernum:=filesize(uf);

    with thisuser do begin
      deleted:=FALSE; waiting:=0; firston:=date; laston:=date;
      loggedon:=0; msgpost:=0; emailsent:=0; feedback:=0; ontoday:=0;
      illegal:=0; forusr:=0;
      downloads:=0; uploads:=0; dk:=0; uk:=0;
      linelen:=80; pagelen:=25; ttimeon:=0; note:='';

      for i:=1 to 5 do boardsysop[i]:=255;
      lastmsg:=1; lastfil:=1; credit:=0; timebank:=0;

      for i:=1 to 70 do res[i]:=0;
      for i:=1 to 20 do vote[i]:=0;

      readinzscan; { load old / create new zscan.dat record }
      with zscanr do begin
        for i:=1 to maxboards do
          for j:=1 to 6 do mhiread[i][j]:=0;
        mzscan:=[]; fzscan:=[];
        for i:=1 to maxboards do mzscan:=mzscan+[i];
        for i:=0 to maxuboards do fzscan:=fzscan+[i];
      end;
      savezscanr;

      trapactivity:=FALSE; trapseperate:=FALSE;
      timebankadd:=0;
      mpointer:=-1;
      chatauto:=FALSE; chatseperate:=FALSE;
      slogseperate:=FALSE;

      flistopt:=1;
      avadjust:=0;

      reset(uf); seek(uf,0); read(uf,user); close(uf);
      cols:=user.cols;
      sl:=systat.newsl; dsl:=systat.newdsl; realsl:=sl; realdsl:=dsl;
      filepoints:=systat.newfp;

      ar:=systat.newar;
      tltoday:=systat.timeallow[sl];
    end;

    reset(uf);
    seek(uf,usernum); write(uf,thisuser);
    close(uf);

    isr(thisuser.name,usernum);
    sprint(#3#3+'Saved.');
    repeat
      nl; nl;
      sprint('Your user name is "'+#3#3+allcaps(thisuser.name)+#3#1+
             '", and your user number is '+#3#3+cstr(usernum)+#3#1+'.');
      sprint('Your password is "'+#3#3+thisuser.pw+#3#1+'".');
      nl;
      print('Please remember these.  You will need your password to log on');
      print('again in the future, and your user number helps to log on faster.');
      nl;
      print('Re-enter your password now for verification.');
      prompt('Password: '); echo:=FALSE; input(pw,20); echo:=TRUE;
      if (pw<>thisuser.pw) then print(^G'WRONG!!'^G);
    until ((pw=thisuser.pw) or (hangup));
    nl; nl; nl;

    useron:=TRUE;
    window(1,1,80,25);
    clrscr;
    schangewindow(not cwindowon,systat.curwindow);
    cls;

    if ((exist(systat.afilepath+'newuser.inf')) or
        (exist(systat.gfilepath+'newuser.inf'))) then
      readq('newuser',0);
    topscr;
    if (systat.newapp<>-1) then begin
      printf('newapp');
      irt:='New User Application';
    end;
    nl;
  end;
end;

procedure newuser;
var i:integer;
begin
  sl1(#3#8+' ***'+#3#3+' NewUser'+#3#8+' ***');
  if (systat.numusers>=9999) then begin
    sl1(#3#7+' [*] Maximum user count has been reached.');
    printf('maximum');
    hangup:=TRUE;
  end else begin
    p1; p2;
    if (systat.newapp<>-1) then begin
      reset(uf); i:=forwardm(systat.newapp); close(uf);
      if (i=0) then i:=systat.newapp;
      email1(i,'\NewUser Application');
    end;
    inc(systat.todayzlog.newusers);
    wasnewuser:=TRUE;
  end;
  useron:=TRUE;
end;

procedure newuserinit(nam:astr);
var s:astr;
begin
  newusername:=nam;
  clrscr;
  window(1,1,80,25); gotoxy(1,1);
  tc(14); textbackground(1); clreol;
  if (spd<>'KB') then s:=' New user on at '+spd+' baud '
    else s:=' New user on locally ';
  gotoxy(40-length(s) div 2,1); textbackground(4); write(s);
  tc(3); textbackground(0);
  window(1,2,80,25); gotoxy(1,1);
  if (systat.closedsystem) then begin
    printf('system');
    printf('nonewusr');
    hangup:=TRUE;
  end else begin
    with thisuser do begin
      name:='NEW USER';
      trapactivity:=FALSE;
      trapseperate:=FALSE;
    end;
    inittrapfile;
  end;
end;

end.
