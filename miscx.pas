{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit miscx;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common,
  doors,
  misc1;

procedure finduser(var s:astr; var usernum:integer);
procedure dsr(uname:astr);
procedure ssm(dest:integer; s:astr);
procedure isr(uname:astr;usernum:integer);
procedure logon1st;

implementation

uses
  archive1;

procedure finduser(var s:astr; var usernum:integer);
var user:userrec;
    sr:smalrec;
    nn:astr;
    i,ii,t:integer;
    sfo,ufo:boolean;
begin
  s:=''; usernum:=0;
  input(nn,36);
  if (nn='?') then begin

    exit;
  end;
  while (copy(nn,1,1)=' ') do nn:=copy(nn,2,length(nn)-1);
  while (copy(nn,length(nn),1)=' ') do nn:=copy(nn,1,length(nn)-1);
  while (pos('  ',nn)<>0) do delete(nn,pos('  ',nn),1);
  if ((hangup) or (nn='')) then exit;
  s:=nn;
  usernum:=value(nn);
  if (usernum<>0) then begin
    if (usernum<0) then
      usernum:=-3             (* illegal negative number entry *)
    else begin
      ufo:=(filerec(uf).mode<>fmclosed);
      if (not ufo) then reset(uf);
      if (usernum>filesize(uf)-1) then begin
        print('Unknown User.');
        usernum:=0;
      end else begin
        seek(uf,usernum); read(uf,user);
        if (user.deleted) then begin
          print('Unknown User.');
          usernum:=0;
        end;
      end;
      if (not ufo) then close(uf);
    end;
  end else begin
    if (nn<>'') then begin
      sfo:=(filerec(sf).mode<>fmclosed);
      if (not sfo) then reset(sf);
      ii:=0; t:=1;
      while ((t<=filesize(sf)-1) and (ii=0)) do begin
        seek(sf,t); read(sf,sr);
        if (nn=sr.name) then ii:=sr.number;
        inc(t);
      end;
      if (ii<>0) then usernum:=ii;
    end;
    if (nn='NEW') then usernum:=-1;
    if (nn='GUEST') then
      if (systat.guestuser=-1) then
        print('No guest user account available.')
      else
        usernum:=-2;
    if (usernum=0) then print('Unknown User.');
    if (not sfo) then close(sf);
  end;
end;

procedure ssm(dest:integer; s:astr);
var u:userrec;
    x:smr;
    ufo:boolean;
begin
  {$I-} reset(smf); {$I+}
  if (ioresult<>0) then rewrite(smf);
  seek(smf,filesize(smf));
  x.msg:=s; x.destin:=dest;
  write(smf,x);
  close(smf);

  ufo:=(filerec(uf).mode<>fmclosed);
  if (not ufo) then reset(uf);
  if ((dest>=1) and (dest<=filesize(uf))) then begin
    seek(uf,dest); read(uf,u);
    if (not (smw in u.ac)) then begin
      u.ac:=u.ac+[smw];
      seek(uf,dest); write(uf,u);
    end;
  end;
  if (not ufo) then close(uf);
  if (dest=usernum) then thisuser.ac:=thisuser.ac+[smw];
end;

procedure dsr(uname:astr);
var t,ii:integer;
    sr:smalrec;
    sfo:boolean;
begin
  sfo:=(filerec(sf).mode<>fmclosed);
  if (not sfo) then reset(sf);

  ii:=0; t:=1;
  while ((t<=filesize(sf)-1) and (ii=0)) do begin
    seek(sf,t); read(sf,sr);
    if (sr.name=uname) then ii:=t;
    inc(t);
  end;

  if (ii<>0) then begin
    if (ii<>filesize(sf)-1) then
      for t:=ii to filesize(sf)-2 do begin
        seek(sf,t+1); read(sf,sr);
        seek(sf,t); write(sf,sr);
      end;
    seek(sf,filesize(sf)-1); truncate(sf);
    dec(systat.numusers); savesystat;
  end
  else sl1('*** Couldn''t delete "'+uname+'"');
  if (not sfo) then close(sf);
end;

procedure isr(uname:astr; usernum:integer);
var t,i,ii:integer;
    sr:smalrec;
    sfo:boolean;
begin
  sfo:=(filerec(sf).mode<>fmclosed);
  if (not sfo) then reset(sf);

  if (filesize(sf)=1) then ii:=0
  else begin
    ii:=0; t:=1;
    while ((t<=filesize(sf)-1) and (ii=0)) do begin
      seek(sf,t); read(sf,sr);
      if (uname<sr.name) then ii:=t;
      inc(t);
    end;
    for i:=filesize(sf)-1 downto ii+1 do begin
      seek(sf,i); read(sf,sr);
      seek(sf,i+1); write(sf,sr);
    end;
  end;
  with sr do begin name:=uname; number:=usernum; end;
  seek(sf,ii+1); write(sf,sr);
  inc(systat.numusers); savesystat;
  if (not sfo) then close(sf);
end;

procedure logon1st;
var ul:text;
    u:userrec;
    zf:file of zlogrec;
    fil:file of astr;
    d1,d2:zlogrec;
    s,s1:astr;
    n,z,c1,num,rcode:integer;
    c:char;
    abort:boolean;
begin
  if (spd<>'KB') then begin
    inc(systat.callernum);
    inc(systat.todayzlog.calls);
  end;

  realsl:=thisuser.sl; realdsl:=thisuser.dsl;
  commandline('Purging files in TEMP directories 1, 2, and 3 ...');
  purgedir(systat.temppath+'1\');
  purgedir(systat.temppath+'2\');
  purgedir(systat.temppath+'3\');

  if (systat.lastdate<>date) then begin
    prompt('Please wait ....');
    commandline('Updating user time left ...');
    reset(uf);
    for n:=1 to filesize(uf)-1 do begin
      seek(uf,n); read(uf,u);
      with u do begin
        tltoday:=systat.timeallow[sl];
        timebankadd:=0; ontoday:=0;
      end;
      seek(uf,n); write(uf,u);
    end;
    close(uf);

    commandline('Updating ZLOG.DAT ...');
    assign(zf,systat.gfilepath+'zlog.dat');
    {$I-} reset(zf); {$I+}
    if (ioresult<>0) then begin
      rewrite(zf);
      d1.date:='';
      for n:=1 to 2 do write(zf,d1);
    end;

    d1:=systat.todayzlog;
    d1.date:=systat.lastdate;

    for n:=filesize(zf)-1 downto 0 do begin
      seek(zf,n); read(zf,d2);
      seek(zf,n+1); write(zf,d2);
    end;
    seek(zf,0);
    write(zf,d1);
    close(zf);
    systat.lastdate:=date;

    commandline('Updating SysOp Log files ...');

    assign(ul,systat.trappath+'sysop'+cstr(systat.backsysoplogs)+'.log');
    {$I-} erase(ul); {$I+} num:=ioresult;

    for n:=systat.backsysoplogs-1 downto 1 do
      if (exist(systat.trappath+'sysop'+cstr(n)+'.log')) then begin
        assign(ul,systat.trappath+'sysop'+cstr(n)+'.log');
        rename(ul,systat.trappath+'sysop'+cstr(n+1)+'.log');
      end;

    d1:=systat.todayzlog;
    sl1('');
    sl1('Total time on........: '+cstr(d1.active));
    sl1('Percent of activity..: '+sqoutsp(ctp(d1.active,1440))+' ('+
                                  cstr(d1.calls)+' calls)');
    sl1('New users............: '+cstr(d1.newusers));
    sl1('Public posts.........: '+cstr(d1.pubpost));
    sl1('Private mail sent....: '+cstr(d1.privpost));
    sl1('Feedback sent........: '+cstr(d1.fback));
    sl1('Critical Errors......: '+cstr(d1.criterr));
    sl1('Downloads today......: '+cstr(d1.downloads)+'-'+cstrl(d1.dk)+'k');
    sl1('Uploads today........: '+cstr(d1.uploads)+'-'+cstrl(d1.uk)+'k');

    close(sysopf);
    rename(sysopf,systat.trappath+'sysop1.log');

    assign(sysopf,systat.trappath+'sysop.log');
    rewrite(sysopf); close(sysopf); append(sysopf);
    sl1('');
    sl1(' ____________________________________');
    sl1('/                                    \');
    sl1('\  Coyote BBS log For     '+date+':  /');
    sl1(' \__________________________________/');
    sl1('');
    sl1('');

    assign(ul,systat.gfilepath+'user.log');
    rewrite(ul);
    writeln(ul);
    writeln(ul,'Log of callers for '+date+':');
    writeln(ul);
    close(ul);

    systat.todayzlog.date:=date;
    with systat.todayzlog do begin
      for n:=0 to 4 do userbaud[n]:=0;
      active:=0; calls:=0; newusers:=0; pubpost:=0; privpost:=0;
      fback:=0; criterr:=0; uploads:=0; downloads:=0; uk:=0; dk:=0;
    end;

    if (exist('daystart.bat')) then
      shelldos(FALSE,process_door('daystart.bat @F @L @B @G @T @R'),rcode);

    print(' thank you.'); nl;
    enddayf:=TRUE;
  end;

  if (thisuser.slogseperate) then begin
    assign(sysopf1,systat.trappath+'slog'+cstr(usernum)+'.log');
    {$I-} append(sysopf1); {$I+}
    if (ioresult<>0) then begin
      rewrite(sysopf1);
      append(sysopf1);
      s:=''; s1:='';
      for n:=1 to 26+length(nam) do begin s:=s+'_'; s1:=s1+' '; end;
      writeln(sysopf1,'');
      writeln(sysopf1,'  '+s);
      writeln(sysopf1,'>>'+s1+'<<');
      writeln(sysopf1,'>> Coyote BBS Log FOr     '+nam+': <<');
      writeln(sysopf1,'>>'+s+'<<');
      writeln(sysopf1,'');
    end;
    writeln(sysopf1);
    s:=#3#3+'Logon '+#3#5+'['+dat+']'+#3#4+' (';
    if (spd<>'KB') then s:=s+spd+' baud)' else s:=s+'Keyboard)';
    if (systat.stripclog) then s:=stripcolor(s);
    writeln(sysopf1,s);
  end;

  s:=#3#3+cstr(systat.callernum)+#3#4+' -- '+#3#0+nam+#3#4+' -- '+
     #3#3+'Today '+cstr(thisuser.ontoday+1);
  if (trapping) then s:=s+#3#0+'*';
  sl1(s);

  if (spd<>'KB') then begin
    assign(ul,systat.gfilepath+'user.log');
    {$I-} append(ul); {$I+}
    if (ioresult<>0) then begin
      rewrite(ul);
      append(ul);
    end;
    s:=#3#5+mln(cstr(systat.callernum),6)+#3#9+'- '+
       #3#0+mln(nam,26)+#3#9+' - '+#3#3+time+#3#9+' -'+#3#3+mrn(spd,5);
    if (wasnewuser) then s:=s+#3#5+' <New User>';
    if (wasguestuser) then s:=s+#3#5+' <Guest User>';
    writeln(ul,s); close(ul);
  end;
end;

end.
