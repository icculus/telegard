(*****************************************************************************)
(*>                                                                         <*)
(*>  MISC2   .PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  Various miscellaneous functions used by the BBS.                       <*)
(*>                                                                         <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit misc2;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common,
  file2;

procedure pstat;
procedure bulletins(par:astr);
procedure abbs;
procedure ansig(x,y:integer);
procedure yourinfo;
procedure tfiles;
procedure ulist;

implementation

procedure pstat;
var c:char;
begin
  outkey(^L);
  with systat do begin
    print('New User Pass   : '+newuserpw);
    prompt('Board is        : '); if (closedsystem) then print('Closed') else print('Open');
    print('Number Users    : '+cstr(numusers));
    print('Number calls    : '+cstr(callernum));
    print('Date & Time     : '+dat);
    print('Active today    : '+cstr(systat.todayzlog.active));
    print('Calls today     : '+cstr(systat.todayzlog.calls));
    print('Messages today  : '+cstr(systat.todayzlog.pubpost));
    print('Email sent today: '+cstr(systat.todayzlog.privpost));
    print('Feed back today : '+cstr(systat.todayzlog.fback));
    print('Uploads today   : '+cstr(systat.todayzlog.uploads));
    prompt('Sysop           : '+aonoff(sysop,fstring.sysopin,fstring.sysopout));
    print('Disk free space : '+cstrl(freek(0))+'k');
    prompt('Sysop hours     : ');
    if (lowtime=hitime) then print('None')
    else
      print(tch(cstr(lowtime div 60))+':'+tch(cstr(lowtime mod 60))+' to '+
                tch(cstr(hitime div 60))+':'+tch(cstr(hitime mod 60)));

  end;
  if (not useron) then begin
    nl; nl; print('Hit any key');
    getkey(c);
  end;
end;

procedure bulletins(par:astr);
var filv:text;
    main,subs,s:astr;
    i:integer;
begin
  nl;
  if (par='') then
    if (systat.bulletprefix='') then
      par:='bulletin;bullet'
    else
      par:='bulletin;'+systat.bulletprefix;
  if (pos(';',par)<>0) then begin
    main:=copy(par,1,pos(';',par)-1);
    subs:=copy(par,pos(';',par)+1,length(par)-pos(';',par));
  end else begin
    main:=par;
    subs:=par;
  end;
  printf(main);
  if (not nofile) then
    repeat
      i:=8-length(subs); if (i<1) then i:=1;
      prt(fstring.bulletinline);
      input(s,i); s:=sqoutsp(s);
      if (not hangup) then begin
        if (s='') then s:='Q';
        if (s='?') then printf(main);
        if ((s<>'Q') and (s<>'?') and (s<>'')) then printf(subs+s);
      end;
    until ((s='Q') or (hangup));
end;

procedure abbs;
var filvar:text;
    s,i1,i2:astr;
    c:char;
    tf:text;
    there,abort,next:boolean;
begin
  abort:=FALSE; next:=FALSE;
  if (not (ramsg in thisuser.ac)) then begin
    nl;
    if pynq('Do you want to add to the BBS list? ') then begin
      repeat
        nl;
        print('Enter the phone number in the form:');
        sprint(#3#3+' '+systat.bbsphone);
        print(' ###-###-####');
        prt(':'); mpl(12); input(i1,12);
      until (length(i1)=12) or (i1='') or hangup;
      assign(tf,systat.afilepath+'bbslist.msg');
      {$I-} reset(tf); {$I+}
      nofile:=(ioresult<>0);
      there:=FALSE;
      if (not nofile) then begin
        while not eof(tf) do begin
          readln(tf,s);
          if (copy(s,1,12)=i1) then there:=TRUE;
        end;
        close(tf);
      end;
      if (there) then begin
        nl;
        if (i1<>'') then sprint(#3#5+'It''s already in there.');
        i1:='';
      end;
      s:=i1;
      if (s<>'') then begin
        nl;
        print('Enter the name of the BBS:');
        prt(':'); mpl(41); inputl(i1,41);
        s:=mln(s+'  '+#3#0+i1,56);

        nl;
        print('Enter max speed of system (ie, 300,1200,2400).');
        prt(':'); mpl(4); input(i2,4);
        if (i2='') then s:=s+'        '
        else
          s:=s+#3#4+'  ['+#3#3+i2+#3#4+']';
        if (i1<>'') then begin
          nl;
          print('Enter a 4-8 character BBS type.');
          prt(':');
          mpl(8);
          input(i1,8);
          if (i1<>'') then
            if copy(i1,1,3)<>'TAG' then s:=s+#3#7+' ('+#3#3+i1+#3#7+')'
                                   else s:=s+#3#7+' ('+#3#9+i1+#3#7+')';
          nl;
          printacr(s,abort,next);
          nl;
          if pynq('Is this correct? ') then begin
            assign(filvar,systat.afilepath+'bbslist.msg');
            {$I-} append(filvar); {$I+}
            if (ioresult<>0) then begin
              assign(filvar,systat.afilepath+'bbslist.msg');
              rewrite(filvar);
            end;
            writeln(filvar,s);
            close(filvar);
            sysoplog('Added to BBS list:');
            sl1(s);
          end;
        end;
      end;
    end;
  end
  else sprint(#3#7+'You are restricted from adding to the BBS list.');
end;

procedure ansig(x,y:integer);
begin
  if (spd<>'KB') then pr1(#27+'['+cstr(y)+';'+cstr(x)+'H');
  if (wantout) then gotoxy(x,y);
  pap:=0;
end;


procedure yourinfo;
var ddt,dt:datetimerec;
    i:integer;

  function istr(i:integer):astr;
  var s:astr;
  begin
    with thisuser do
      case i of
        1:s:=caps(name);
        2:s:=ph;
        3:s:=cstr(sl)+' SL';
        4:s:=cstr(dsl)+' DSL';
        5:s:=cstr(1+loggedon)+' calls';
        6:s:=cstr(ontoday)+' calls';
        7:s:=cstr(msgpost)+' posts';
        8:s:=cstr(emailsent+feedback)+' letters';
        9:begin
            s:=cstr(waiting)+' letter';
            if (waiting>1) then s:=s+'s';
          end;
       10:begin
            getdatetime(dt);
            timediff(ddt,timeon,dt);
            s:=ctim(dt2r(ddt));
          end;
       11:begin
            getdatetime(dt);
            timediff(ddt,timeon,dt);
            s:=cstrl(trunc(ttimeon+dt2r(ddt)))+' min.';
          end;
       12:s:=laston;
      end;
    istr:=s;
  end;

begin
  cls;
  if (okansi) then begin
    sprompt('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ'+#3#4+'['+#3#6+' User Statistics '+#3#4+']');
      sprint(#3#1'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
    print('³ Your name    :                   ³ Public posts    :                ³');
    print('³ Phone number :                   ³ E-mail sent     :                ³');
    prompt('³ Sec Level    :                   ³ ');
    if (thisuser.waiting>0) then cl(5);
    prompt('Mail waiting');
      sprint(#3#1+'    :                ³');
    print('³ DL Sec Level :                   ³ Time on today   :                ³');
    print('³ # times on   :                   ³ Total time ever :                ³');
    print('³ On today     :                   ³ Last called     :                ³');
    print('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
    cl(3);
    for i:=1 to 12 do begin
      if i in [1..6] then ansig(17,i+1);
      if i in [7..12] then ansig(55,i-5);
      if (i<>9) or (thisuser.waiting=0) then prompt(istr(i))
      else sprompt(#3#5+istr(i)+#3#3);
    end;
    ansig(1,9);
    cl(1);
  end else begin
    with thisuser do begin
      print('Your name      : '+name);
      print('Phone number   : '+ph);
      print('Sec Level      : '+cstr(sl)+' SL');
      print('DL Sec Level   : '+cstr(dsl)+' DSL');
      print('# times on     : '+cstr(1+thisuser.loggedon));
      print('On today       : '+cstr(thisuser.ontoday));
      nl;
      print('Public posts   : '+cstr(thisuser.msgpost));
      print('E-mail sent    : '+cstr(thisuser.emailsent+thisuser.feedback));
      print('Mail waiting   : '+istr(9));
      print('Time on today  : '+istr(10));
      print('Total time ever: '+istr(11));
      print('Last called    : '+istr(12));
    end;
  end;
end;

(*
procedure yourinfo;
var s:string[90];
    c:char;
    abort,next:boolean;
    r:uflags;

  function mlnn(i,l:integer):string;
  begin
    mlnn:=mln(cstr(i),l);
  end;

  function mrnn(i,l:integer):string;
  begin
    mrnn:=mrn(cstr(i),l);
  end;

  function yesno(x:boolean):string;
  var s:string[8];
  begin
    s:=#3#3+' ';
    if (x) then s:=s+'Y' else s:=s+'N';
    s:=s+'  '+#3#1;
    yesno:=s;
  end;

begin
  cls;
	abort:=FALSE; next:=FALSE;
  printacr(#3#5+'Your user information (visible only to you):',abort,next);
  printacr('',abort,next);
  with thisuser do begin
    printacr(#3#1+' User Name: '+#3#3+mln(name,38)+#3#1+'SL: '+#3#3+mlnn(sl,3)+
      #3#1+'  DSL: '+#3#3+cstr(dsl),abort,next);
    printacr(#3#1+' Real Name: '+#3#3+mln(realname,38)+#3#1+'Phone: '+#3#3+
      ph,abort,next);
    printacr(#3#1+'   Address: '+#3#3+mln(street,38)+#3#1+'  Age: '+#3#3+sex+
      cstr(ageuser(bday))+' ('+bday+')',abort,next);
    printacr(#3#1+'City/State: '+#3#3+mln(citystate,35)+#3#1+'First on: '+
      #3#3+firston,abort,next);
    printacr(#3#1+'  Zip Code: '+#3#3+mln(zipcode,35)+#3#1+' Last on: '+#3#3+
      laston,abort,next);
    printacr('',abort,next);
    s:=mrnn(linelen,2)+'x'+mrnn(pagelen,2)+' (';
    if (avatar in ac) then s:=s+'AVATAR)'
      else if (ansi in ac) then s:=s+'ANSI)'
        else s:=s+'TTY)';
    printacr(#3#1+'Pause:'+yesno(pause in ac)+'OneKey:'+yesno(onekey in ac)+
      'ClrScr:'+yesno((clsmsg=1))+'Novice:'+yesno(novice in ac)+'Color:'+
      yesno(color in ac)+'Screen: '+#3#3+s,abort,next);
    s:=#3#1+'Mailbox Status: '+#3#3;
    if (nomail in ac) then s:=s+'Closed                ' else begin
      if (forusr=0) then s:=s+'Open                  '
        else s:=s+'Fowarded to user '+mlnn(forusr,4);
    end;
    s:=s+#3#1+'      File List Type: '+#3#3+cstr(flistopt);
    printacr(s,abort,next);
    printacr('',abort,next);
    printacr(#3#1+'Calls Today: '+#3#3+mlnn(ontoday,5)+#3#1+
      '      Public Sent: '+#3#3+mlnn(msgpost,5)+#3#1+'      Total ULs: '+#3#3+
      cstr(uploads)+#3#1+'/'+#3#3+cstrl(uk)+'K',abort,next);
    str(nsl/60.0:5:0,s);
    s:=mln(sqoutsp(s),5);
    printacr(#3#1+'  Time Left: '+#3#3+s+#3#1+'       Email Sent: '+#3#3+
      mlnn(emailsent,5)+#3#1+'      Total DLs: '+#3#3+cstr(downloads)+#3#1+
      '/'+#3#3+cstrl(dk)+'K',abort,next);
    printacr(#3#1+'Total Calls: '+#3#3+mlnn(loggedon,5)+#3#1+'    Feedback '+
      'Sent: '+#3#3+mlnn(feedback,5)+#3#1+'    File Points: '+#3#3+
      cstr(filepoints),abort,next);
    s:=#3#1+' Total Time: '+#3#3+mlnn(ttimeon,5)+#3#1+'    ';
    if (waiting<>0) then s:=s+#3#5;
    s:=s+'Email Waiting: ';
    if (waiting<>0) then s:=s+#3#8 else s:=s+#3#3;
    s:=s+mlnn(waiting,5)+#3#1+'      Time Bank: '+#3#3+cstr(timebank);
    printacr(s,abort,next);
  end;
  pausescr;
end;
*)
procedure tfiles;
var gfil:file of tfilerec;
    b:tfilerec;
    gftit:array[1..150] of record
      tit:string[40];
      arn:integer;
      gfile:boolean;
      acs:acstring;
{      arreq:acrq;}
      gdaten:integer;
    end;
(*
    gftit:array[1..150] of record
      tit:string[40];
      filen:string[12];
      arn:integer;
      gfile:boolean;
      acs,ulacs:acstring;
      gdate:string[8];
    end;
*)
    titl,s:astr;
    t,c,lgftn,lgftnt,numgft:integer;
    abort,next,deep,xexit:boolean;

  procedure gettit(n:integer);
  var b:tfilerec;
      r:integer;
  begin
    numgft:=0;
    if n>0 then begin
      seek(gfil,n); read(gfil,b); titl:=b.title;
    end else titl:='[ Main Section ]';
    r:=n+1;
    if r<=t then begin
      seek(gfil,r); read(gfil,b);
      while (r<=t) and (b.filen[1]<>#1) do begin
        if (aacs(b.acs)) then begin
          inc(numgft);
          with gftit[numgft] do begin
            tit:=b.title;
            arn:=r;
            gfile:=TRUE;
            gdaten:=b.gdaten;
          end;
        end;
        inc(r);
        if (r<=t) then begin seek(gfil,r); read(gfil,b); end;
      end;
    end;
    if n=0 then
      while (r<=t) do begin
        seek(gfil,r); read(gfil,b);
        if ((b.filen[1]=#1) and (aacs(b.acs))) then begin
          inc(numgft);
          with gftit[numgft] do begin
            tit:=b.title;
            arn:=r;
            gfile:=FALSE;
            gdaten:=b.gdaten;
          end;
        end;
        inc(r);
      end;
  end;

  procedure lgft;
  var abort,next:boolean; c:integer;
  begin
    nl; sprint(#3#3+titl); nl;
    if numgft=0 then print('No Tfiles.') else begin
      abort:=FALSE; next:=FALSE; c:=1;
      while (c<=numgft) and (not abort) do begin
        s:=#3#5+cstr(c)+#3#7+': '+#3#3+gftit[c].tit;
        if (gftit[c].gdaten>=daynum(thisuser.laston)) then s:=#3#8+'*'+s
          else s:=' '+s;
        printacr(s,abort,next);
        inc(c);
      end;
    end;
  end;

  procedure scaninput(var s:string; allowed:string);
  var os:string;
      i:integer;
      c:char;
      gotcmd:boolean;
  begin
    gotcmd:=FALSE; s:='';
    repeat
      getkey(c); c:=upcase(c);
      os:=s;
      if ((pos(c,allowed)<>0) and (s='')) then begin gotcmd:=TRUE; s:=c; end
      else
      if (pos(c,'0123456789')<>0) then begin
        if (length(s)<5) then s:=s+c;
      end
      else
      if ((s<>'') and (c=^H)) then s:=copy(s,1,length(s)-1)
      else
      if (c=^X) then begin
        for i:=1 to length(s) do prompt(^H' '^H);
        s:=''; os:='';
      end
      else
      if (c=#13) then gotcmd:=TRUE;

      if (length(s)<length(os)) then prompt(^H' '^H);
      if (length(s)>length(os)) then prompt(copy(s,length(s),1));
    until ((gotcmd) or (hangup));
    nl;
  end;

  procedure extracttfile;
  var dirinfo:searchrec;
      s,s2:string;
      lng,numfiles,tsiz:longint;
      i:integer;
      found,nospace,ok:boolean;
  begin
    nl;
    print('Extract text-file to temporary directory -');
    nl;
    prompt('Already in TEMP: ');
    numfiles:=0; tsiz:=0;
    findfirst(systat.temppath+'3\*.*',anyfile-dos.directory,dirinfo);
    found:=(doserror=0);
    while (found) do begin
      inc(tsiz,dirinfo.size);
      inc(numfiles);
      findnext(dirinfo);
      found:=(doserror=0);
    end;
    if (numfiles=0) then print('Nothing.')
      else print(cstrl(numfiles)+' files totalling '+cstrl(tsiz)+' bytes.');

    if (not fso) then begin
      print('The limit is '+cstrl(systat.maxintemp)+'k bytes.');
      lng:=systat.maxintemp; lng:=lng*1024;
      if (tsiz>lng) then begin
        nl;
        print('You have exceeded this limit.');
        nl;
        print('Please remove some files from the TEMP directory using');
        print('the user-archive command to free up some space.');
        exit;
      end;
    end;

    nl;
    prt('T-file #: ');
    scaninput(s,'');
    if ((hangup) or (s='')) then exit;
    i:=value(s);
    if ((i>=1) and (i<=numgft)) then
      if (gftit[i].gfile) then begin
        seek(gfil,gftit[i].arn); read(gfil,b);
        s:=systat.tfilepath+b.filen;
        s2:=systat.temppath+'3\'+b.filen;
        sprompt(#3#5+'Progress: ');
        copyfile(ok,nospace,TRUE,s,s2);
        if (ok) then
          sprint(#3#5+' - Copy successful.')
        else
          if (nospace) then
            sprint(#3#7+'Copy unsuccessful - insufficient space!')
          else
            sprint(#3#7+'Copy unsuccessful!');
        sysoplog('User copied t-file "'+b.filen+'" into TEMP directory.');
(*        if (ok) then didsomething:=TRUE;*)
      end;
  end;

begin
  nl;
  assign(gfil,systat.gfilepath+'gfiles.dat');
  {$I-} reset(gfil); {$I+}
  if ioresult<>0 then begin
    rewrite(gfil);
    b.gdaten:=0;
    write(gfil,b);
  end;
  seek(gfil,0); read(gfil,b); t:=b.gdaten;
  abort:=FALSE; next:=FALSE;
  if (t=0) then print('No Tfiles available today.')
  else begin
    gettit(0); xexit:=FALSE;
    lgft; lgftn:=0; deep:=FALSE; lgftnt:=0;
    repeat
      nl;
      if (next) then begin
        next:=FALSE; s:='';
        sprint(#3#5+'==Skipped to next==');
        nl;
      end else begin
        sprompt(#3#5+'['+cstr(lgftn)+'] '+#3#3+'Tfiles: (1-'+cstr(numgft)+',?,Q) : ');
        cl(5); scaninput(s,'QX?');
        nl;
      end;
      if (s='') then
        if (lgftn=numgft) then s:='Q' else s:=cstr(lgftn+1);
      if (s='?') then lgft;
      if (s='Q') then
        if (deep) then begin
          deep:=FALSE;
          gettit(0);
          lgft;
          lgftn:=lgftnt;
        end else
          xexit:=TRUE;
      if (s='X') then extracttfile;

      c:=value(s);
      if ((c>0) and (c<=numgft)) then begin
        if (gftit[c].gfile) then begin
          seek(gfil,gftit[c].arn);
          read(gfil,b);
          if (pos('.',b.filen)<>0) then
            pfl(systat.tfilepath+b.filen,abort,next,TRUE)
          else printf(systat.tfilepath+b.filen);
          lgftn:=c;
        end else begin
          gettit(gftit[c].arn);
          lgftn:=c;
          if (numgft>0) then begin
            lgft;
            lgftnt:=c; lgftn:=0;
            deep:=TRUE;
          end else begin
            gettit(0);
            nl; print('No Tfiles there.');
          end;
        end;
      end;
    until ((xexit) or (hangup));
  end;
  close(gfil);
end;

procedure ulist;
const sepr2=#3#4+':'+#3#3;
var u:userrec;
    sr:smalrec;
    s:astr;
    i,j:integer;
    abort,next,sfo:boolean;
begin
  sfo:=(filerec(sf).mode<>fmclosed);
  if (not sfo) then reset(sf);
  nl;
  loadboard(board);
  sprint(#3#9+'Users with access to "'+#3#5+memboard.name+#3#9+'"');
  nl;
  sprint(#3#3+'User Name                 '+sepr2+
         'Computer Type                '+sepr2+'Sex'+sepr2+'Last on');
  sprint(#3#4+'==========================:==============================:=:=========');
  reset(uf);
  i:=0; j:=0;
  abort:=FALSE;
  while (not abort) and (i<filesize(sf)-1) do begin
    inc(i);
    seek(sf,i); read(sf,sr); seek(uf,sr.number); read(uf,u);
    if (aacs1(u,sr.number,memboard.acs)) then begin
      printacr(#3#3+mln(caps(sr.name)+' #'+cstr(sr.number),26)+' '+
               mln(u.computer,30)+#3#3+' '+u.sex+'  '+u.laston,abort,next);
      inc(j);
    end;
  end;
  if (not abort) then begin
    nl;
    s:=' User';
    if (j<>1) then s:=s+'s';
    s:=s+'.';
    printacr(#3#7+' ** '+#3#5+cstr(j)+s,abort,next);
  end;
  close(uf);
  if (not sfo) then close(sf);
end;

end.
