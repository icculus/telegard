{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit mail2;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common, timejunk, mail0, mail1;

procedure ssmail(mstr:astr);
procedure smail(massmail:boolean);
procedure email1(x:integer; ftit:string);
procedure email(x:integer);
procedure imail(x:integer);
function maxage(x:integer):integer;

implementation

uses misc3, miscx;

procedure ssmail(mstr:astr);
begin
  if (mstr='') then smail(FALSE)
  else begin
    if (pos(';',mstr)=0) then irt:='Feedback' else
      irt:=copy(mstr,pos(';',mstr)+1,length(mstr));
    imail(value(mstr));
  end;
end;

procedure smail(massmail:boolean);
var u,u2:userrec;
    mheader:mheaderrec;
    mixr:msgindexrec;
    na:array[1..20] of word;
    massacs,s:string;
    i,nac,x:integer;
    stype:byte;
    abort,next,ok:boolean;

  procedure checkitout(var x:integer; showit:boolean);
  var i,ox:integer;
      b:boolean;

    procedure unote(s:string);
    begin
      if (showit) then
        print('[> '+caps(u.name)+' #'+cstr(x)+': '+s);
    end;

  begin
    {x:=value(s);} ox:=x;
    if ((x<1) or (x>filesize(uf)-1)) then begin x:=0; exit; end;
    seek(uf,x); read(uf,u);

    i:=0; b:=TRUE;
    while ((i<4) and (b)) do begin
      inc(i); b:=moremail(u,x,i);
      if (not b) then
        case i of
          1:unote('Mailbox is full.');
          2:unote('Mailbox is closed.');
          3:x:=0;
          4:unote('Can''t send mail to yourself!');
        end;
    end;

    if (not b) then begin x:=0; exit; end;
    i:=u.forusr; if ((i<1) or (i>filesize(uf)-1)) then i:=0;
    if (i<>0) then begin
      seek(uf,i); read(uf,u2);
      unote('Mail forwarded to '+caps(u2.name)+' #'+cstr(i)+'.');
      x:=i;
    end;
    if (showit) then
      for i:=1 to 20 do
        if (na[i]=x) then begin
          unote('Can''t send more than once.');
          x:=0; exit;
        end;
    if (ox<>x) then
      if ((ox>=1) and (ox<=filesize(uf)-1)) then begin
        seek(uf,ox); read(uf,u);
      end;
  end;

  procedure sendit(x:integer);
  begin
    checkitout(x,FALSE);
    if (x=0) then exit;

    if ((x>=1) and (x<=filesize(uf)-1)) then begin
      seek(uf,x); read(uf,u);
      if (x=1) then begin
        inc(thisuser.feedback);
        inc(ftoday);
      end else begin
        inc(thisuser.emailsent);
        inc(etoday);
      end;
      inc(u.waiting);
      seek(uf,x); write(uf,u);
      if (x=usernum) then inc(thisuser.waiting);
    end;

    with mheader.toi do begin
      anon:=0;
      usernum:=x;
      as:=allcaps(u.name)+' #'+cstr(x);
      real:=allcaps(u.realname);
      alias:=allcaps(u.name);
    end;
    with mixr do begin
      messagenum:=x;
      msgid:=0;
      hdrptr:=filesize(brdf);
      msgindexstat:=msgindexstat+[mimassmail];
    end;

    seek(brdf,mixr.hdrptr);
    savemhead(mheader);
    newmix(mixr);
  end;

  procedure doit;
  var s:string;
      i,x:integer;
  begin
    initbrd(-1);
    if (not inmsg(FALSE,FALSE,'',mixr,mheader)) then exit;
    case stype of
      0:begin
          nl; print('Sending mass-mail to:');
          sysoplog('Mass-mail sent to:');
          for i:=1 to nac do begin
            sendit(na[i]); s:='   '+caps(u.name)+' #'+cstr(na[i]);
            sysoplog(s); print(s);
          end;
        end;
      1:begin
          nl; print('Sending mass-mail to:');
          sysoplog('Mass-mail sent to: (by ACS "'+massacs+'")');
          seek(uf,1);
          for i:=1 to filesize(uf)-1 do begin
            read(uf,u);
            if (aacs1(u,i,massacs)) then begin
              sendit(i); s:='   '+caps(u.name)+' #'+cstr(i);
              sysoplog(s); print(s);
            end;
          end;
        end;
      2:begin
          print('Sending mass-mail to ALL USERS.');
          sysoplog('Mass-mail sent to ALL USERS.');
          for i:=1 to filesize(uf)-1 do sendit(i);
        end;
    end;
  end;

begin
  nl;
  if ((remail in thisuser.ac) or (not (aacs(systat.normprivpost)))) then begin
    print('Your access privledges do not include sending mail.');
    exit;
  end else
    if ((etoday>=systat.maxprivpost) and (not mso)) then begin
      print('Too much mail send today already.');
      exit;
    end;
  if (not massmail) then begin
    print('Enter user number, user name, or partial search string:');
    prt(':'); finduserws(x);
    if (x>0) then imail(x);
  end else begin
    print('Mass mail: send mail to more than one user.');
    print('Enter a max of 20 user NUMBERS, seperated by commas.');
    if (cso) then begin
      print('CoSysOps:');
      print('  ALL: Send to every user.');
      print('  ACS: Send to an ACS group of users.');
    end;
    prt(':'); input(s,78); if (s='') then exit;
    reset(uf);
    ok:=FALSE; nac:=0; stype:=0;
    for i:=1 to 20 do na[i]:=0;
    nl;
    if (cso) then
      if (s='ACS') then begin
        ok:=TRUE;
        stype:=1;
        prt('Enter ACS: '); inputl(massacs,160);
        if (massacs='') then begin close(uf); exit; end;
        seek(uf,1); i:=1;
        nl;
        print('Users marked by ACS "'+massacs+'":');
        abort:=FALSE; next:=FALSE;
        while ((i<=filesize(uf)-1) and (not abort)) do begin
          read(uf,u);
          if (aacs1(u,i,massacs)) then
            print('   '+caps(u.name)+' #'+cstr(i));
          inc(i); wkey(abort,next);
        end;
      end else
        if (s='ALL') then begin
          ok:=FALSE;
          print('ALL USERS marked for mass-mail.');
          stype:=2;
        end;
    if (not ok) then begin
      print('Users marked:');
      while ((s<>'') and (nac<20)) do begin
        x:=value(s); checkitout(x,TRUE);
        if (x<>0) then begin
          inc(nac); na[nac]:=x;
          print('   '+caps(u.name)+' #'+cstr(x));
        end;
        i:=pos(',',s); if (i=0) then s:='';
        if (s<>'') then s:=copy(s,i+1,length(s)-i);
      end;
    end;
    nl;
    if pynq('Is this OK? ') then begin doit; closebrd; end;
    close(uf);
  end;
end;

procedure email1(x:integer; ftit:string);
var u:userrec;
    pinfo:pinforec;
    mheader:mheaderrec;
    mixr:msgindexrec;
    fto:string;
    i,t,e,cp:integer;
    a:anontyp;
    s,tousers:astr;
    us:userrec;
    bb:byte;
    b,ok,wasanon:boolean;

  procedure nope(s:astr);
  begin
    if ok then begin nl; print(s); end;
    ok:=FALSE;
  end;

begin
  ok:=TRUE;
  reset(uf);
  if ((x<0) or (x>filesize(uf)-1)) then begin close(uf); exit; end;
  if (copy(ftit,1,1)<>'\') then begin
    seek(uf,x); read(uf,u); close(uf);
    nl;
    if ((remail in thisuser.ac) or (not aacs(systat.normprivpost))) and
       (not mso) then
      nope('Your access privledges do not include sending mail.');
    if (etoday>=systat.maxprivpost) and (not mso) then
      nope('Too much mail sent today.');
    if ((x=1) and (ftoday>=systat.maxfback) and (not mso)) then
      nope('Too much feedback sent today.');

    i:=0; b:=TRUE;
    while ((i<4) and (b)) do begin
      inc(i); b:=moremail(u,x,i);
      if (not b) then
        case i of
          1:nope('That user''s mailbox is full.');
          2:nope('That user''s mailbox is closed.');
          3:nope('That user has been deleted.');
          4:nope('Why do you want to send mail to yourself!??!');
        end;
    end;

    if ((cso) and (not b) and (i<>3)) then ok:=TRUE;
    if (not ok) then exit;
  end;

  savepinfo(pinfo);
  initbrd(-1);

  if (inmsg(FALSE,FALSE,ftit,mixr,mheader)) then begin
    reset(uf);
    if ((x>=1) and (x<=filesize(uf)-1)) then begin
      seek(uf,x); read(uf,u);
      if (x=1) then begin
        inc(thisuser.feedback);
        inc(ftoday);
      end else begin
        inc(thisuser.emailsent);
        inc(etoday);
      end;
      inc(u.waiting);
      seek(uf,x); write(uf,u);
      if (x=usernum) then inc(thisuser.waiting);
    end;
    close(uf);

    with mheader.toi do begin
      anon:=0;
      usernum:=x;
      as:=allcaps(u.name)+' #'+cstr(x);
      real:=allcaps(u.realname);
      alias:=allcaps(u.name);
    end;
    mixr.msgid:=0;
    mixr.messagenum:=x;

    seek(brdf,mixr.hdrptr);
    savemhead(mheader);
    newmix(mixr);

    s:=caps(u.name)+' #'+cstr(x);
    if (useron) then sysoplog('Mail sent to '+s);
    print('Mail sent to '+s);
    topscr;
  end;

  loadpinfo(pinfo);
end;

procedure email(x:integer);
  begin email1(x,''); end;

procedure imail(x:integer);
var u:userrec;
    i:integer;
    b,xx:boolean;

  procedure nope(s:string);
  begin
    if (not xx) then begin
      print(s);
      xx:=TRUE;
    end;
  end;

begin
  xx:=FALSE;
  reset(uf);
  if ((x<1) or (x>filesize(uf)-1)) then begin close(uf); exit; end;
  seek(uf,x); read(uf,u);
  nl;

  i:=0; b:=TRUE;
  while ((i<4) and (b)) do begin
    inc(i); b:=moremail(u,x,i);
    if (not b) then
      case i of
        1:nope('That user''s mailbox is full.');
        2:nope('That user''s mailbox is closed.');
        3:nope('That user has been deleted.');
        4:nope('Why do you want to send mail to yourself!??!');
      end;
  end;

  if (xx) then begin close(uf); exit; end;
  if (u.forusr<>0) then begin
    x:=forwardm(x);
    if ((x<1) or (x>filesize(uf)-1)) then x:=0;
    if (x>0) then begin
      seek(uf,x); read(uf,u); close(uf);
      print('That user is forwarding his mail to '+caps(u.name)+'.');
      if pynq('Send mail to ['+caps(u.name)+' #'+cstr(x)+'] ? ') then email(x);
    end else begin
      print('Can''t send mail to that user.');
      close(uf);
    end;
  end else begin
    close(uf);
    if pynq('Send mail to ['+caps(u.name)+' #'+cstr(x)+']? ') then email(x);
  end;
end;

function maxage(x:integer):integer;
begin
  case x of
     0..19:maxage:=5;
    20..29:maxage:=14;
    30..39:maxage:=90;
    40..59:maxage:=120;
  else
           maxage:=255;
  end;
end;

end.
end.
