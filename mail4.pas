{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit mail4;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common, timejunk,
  sysop3,
  misc3, miscx,
  mail0, mail1, mail2, mail3;

procedure autoreply;
procedure readmail;

implementation

function extractusernum(s:string):integer;
var i:integer;
begin
  i:=length(s);
  while ((s[i]<>'#') and (i>1)) do dec(i);
  i:=value(copy(s,i+1,5));
  extractusernum:=i;
end;

procedure autoreply;
var i:integer; c:char;
    t:text;
    mheader:mheaderrec;
    s:string;
    brdsig,dfdt1,dfdt2,newmsgptr,totload:longint;
begin
  if (lastname='') then
    print('hmmm.. I am unable to auto-reply now.')
  else begin
     i:=extractusernum(lastname);
    if (i=0) then print('It seems I can''t do that now.') else imail(i);
  end;
end;

procedure readmail;
const hellfreezesover=FALSE;
var t:text;
    u:userrec;
    mheader:mheaderrec;
    mixr:msgindexrec;
    pdt:packdatetime;
    dt:ldatetimerec;
    cmds,s,s1:string;
    brdsig,totload:longint;
    crec,i,j,k,mnum,mw,snum:integer;
    c:char;
    bb:byte;
    abort,b,bakw,done,done1,dotitles,errs,found,hasshown1,holdit,
      justdel,next,noreshow,seeanon:boolean;

  procedure findit;
  var orec:integer;
      abort:boolean;
  begin
    orec:=crec; done1:=TRUE; found:=FALSE;
    if (bakw) then begin
      repeat
        dec(crec); abort:=(crec<0);
        if (not abort) then begin
          ensureloaded(crec);
          mixr:=mintab[getmixnum(crec)];
        end;
      until ((abort) or
             ((mixr.messagenum=usernum) and (miexist in mixr.msgindexstat)));
      found:=not abort; if (abort) then crec:=orec;
      if (crec<>orec) then dec(mnum);
      exit;
    end;
    repeat
      inc(crec); abort:=(crec>himsg);
      if (not abort) then begin
        ensureloaded(crec);
        mixr:=mintab[getmixnum(crec)];
      end;
    until ((abort) or
           ((mixr.messagenum=usernum) and (miexist in mixr.msgindexstat)));
    found:=not abort; if (abort) then crec:=orec;
    if (crec<>orec) then inc(mnum);
    if ((justdel) and (not found)) then begin done1:=FALSE; bakw:=TRUE; end;
    exit;
  end;

  function tch(c:char; i:integer):string;
  var s:string;
  begin
    s:=cstr(i); if (i<10) then s:=c+s;
    tch:=s;
  end;

  procedure getout;
  begin
    closebrd;
    thisuser.waiting:=mw;
    readingmail:=FALSE;
  end;

begin
  readingmail:=TRUE;
  abort:=FALSE; next:=FALSE;
  dotitles:=TRUE;
  mailread:=TRUE;

  repeat
    if (dotitles) then begin
      abort:=FALSE; next:=FALSE;

      nl;
      hasshown1:=FALSE;
      if (thisuser.waiting=0) then
        sprint(#3#5+'Sorry, but you have no mail waiting.')
      else begin
        if (thisuser.clsmsg=1) then cls;
        sprompt(#3#5+'You have '+#3#3+cstr(thisuser.waiting)+#3#5+' piece');
        if (thisuser.waiting<>1) then sprompt('s');
        sprint(' of mail waiting:');
        nl;
      end;

      initbrd(-1);
      i:=0; mw:=0;
      while (i<=himsg) do begin
        ensureloaded(i);
        if ((mintab[getmixnum(i)].messagenum=usernum) and
            (miexist in mintab[getmixnum(i)].msgindexstat)) then begin
          inc(mw);
          if (not abort) then begin
            loadmhead(i,mheader); ensureloaded(i);
            for j:=1 to 6 do pdt[j]:=mintab[getmixnum(i)].msgdate[j];
            pdt2dt(pdt,dt);

            with dt do begin
              j:=hour;
              if (j>12) then dec(j,12);
              if (j=0) then j:=12;
              s:=tch(' ',j)+':'+tch('0',min)+aonoff((hour>=12),'p','a');

              s:=#3#3+copy('JanFebMarAprMayJunJulAugSepOctNovDec',(month-1)*3+1,3)+
                 ' '+tch('0',day)+' '+cstr(year)+' - '+s;
            end;

            s1:=what00(mheader.fromi.anon,mheader.fromi.as);
            if (mheader.fromi.anon in [1,2]) then begin
              case mheader.fromi.anon of
                1:seeanon:=aacs(systat.anonprivread);
                2:seeanon:=aacs(systat.csop);
              end;
              if (seeanon) then
                s1:=s1+' ('+caps(mheader.fromi.alias)+' #'+
                    cstr(mheader.fromi.usernum)+')'
              else
                s:='                   ';
            end;

            if ((not hasshown1) and (thisuser.waiting=0)) then begin
              nl; sprint(#3#5+'Correction!  You do have mail waiting:'); nl;
            end;

            sprint(#3#0+tch(' ',mw)+#3#1+' - '+s+#3#1+' - '+#3#3+s1);
            hasshown1:=TRUE;
          end;
        end;
        inc(i);
        wkey(abort,next);
      end;

      if (mw<>0) then nl;

      if (thisuser.waiting<>mw) then begin
        if (mw=0) then
          sprint(#3#3+'You actually have no mail waiting!');
        sprint(#3#5+'Note: Discrepancy has been repaired.');
        sysoplog('Fixed discrepancy in number of private messages waiting.');
      end;

      thisuser.waiting:=mw;
      if (mw=0) then begin getout; exit; end;

      abort:=FALSE; done:=FALSE; next:=FALSE;
      repeat
        sprompt(#3#5+'Start out with (1-'+cstr(mw)+') or (Q)uit : '+#3#9);
        input(s,4); snum:=0; i:=value(s);
        if ((s='ZZZZ') and (thisuser.sl=255)) then begin
          nl;
          sprint(#3#3+'Super Mass Delete function selected!');
          nl;
          if (checkpw) then begin
            prompt('Enter user PW: ');
            echo:=FALSE; input(s1,20); echo:=TRUE;
            if (s1=thisuser.pw) then begin
              nl; nl;
              if pynq('Are you absolutely totally incredibly surely sure???!!? ') then begin
                nl;
                print('You have selected a very powerful command.');
                print('Pause a few moments and reflect upon exactly what you are doing.');
                nl;
                delay(2000);
                nl;
                if pynq('Now, then... do you REALLY want to do this? ') then begin
                  nl;
                  print('OK!  Don''t tell me I didn''t warn you!');
                  nl;
                  prompt('Deleting all your e-mail.... ');
                  i:=0; j:=0;
                  while (i<=himsg) do begin
                    ensureloaded(i);
                    if ((mintab[getmixnum(i)].messagenum=usernum) and
                        (miexist in mintab[getmixnum(i)].msgindexstat)) then begin
                      inc(j);
                      s1:=cstr(j)+' of '+cstr(mw);
                      prompt(s1); for k:=1 to length(s1) do prompt(^H);
                      delmail(i);
                    end;
                    inc(i);
                  end;
                  nl; nl; print('Done!');
                  thisuser.waiting:=0;
                  getout; exit;
                end;
              end;
            end;
          end;
        end;
        if ((i>=1) and (i<=mw)) then snum:=i;
        if ((s='') or (i=0)) then snum:=1;
        if (copy(s,1,1)='Q') then abort:=TRUE;
        done:=((abort) or (snum<>0));
      until ((done) or (hangup));
      if (abort) then begin getout; exit; end;
    end;

    bakw:=FALSE; done:=FALSE; dotitles:=FALSE;
    holdit:=FALSE; justdel:=FALSE; noreshow:=FALSE;

    crec:=-1; mnum:=0;

    repeat
      if (not holdit) then
        repeat
          findit;
          if (crec=-1) then begin done1:=TRUE; dotitles:=TRUE; end;
        until (done1);
      justdel:=FALSE;
      if (mnum=snum) then snum:=0;
      if ((snum=0) and (crec>=0)) then begin
        next:=FALSE;
        if (not noreshow) then begin
          if (thisuser.clsmsg=1) then cls;
          readmsg(2,crec,mnum,mw,abort,next);
        end else
          noreshow:=FALSE;
        if (not next) then begin
          prt('Read mail : ');
          cmds:='Q?-ADFGIRSTN'^N;
          if (cso) then cmds:=cmds+'EUVX';
          if (mso) then cmds:=cmds+'Z';
          onek(c,cmds);
        end else
          c:='I';
        abort:=FALSE; bakw:=FALSE; holdit:=TRUE; next:=FALSE;
        case c of
          '-':begin bakw:=TRUE; holdit:=FALSE; end;
          'E':if (cso) then begin
                thisuser.waiting:=mw;
                if (lastname<>'') then uedit(extractusernum(lastname));
                holdit:=FALSE; i:=mnum; crec:=-1; mnum:=0; snum:=i;
                mw:=thisuser.waiting;
              end;
          'F':begin
                nl;
                prt('Forward letter to which user? '); finduserws(i);
                if (i<1) then print('Unknown user.')
                else
                if (i<>usernum) then begin
                  reset(uf); seek(uf,i); read(uf,u);

                  j:=0; b:=TRUE;
                  while ((j<4) and (b)) do begin
                    inc(j); b:=moremail(u,i,j);
                    if (not b) then
                      case j of
                        1:print('Mailbox is full.');
                        2:print('Mailbox is closed.');
                        3:if (mso) then print('That user is deleted.')
                            else print('Can''t send mail to that user.');
                        4:print('Can''t send mail to yourself!');
                      end;
                  end;

                  close(uf);

                  if (b) then begin
                    mixr:=mintab[getmixnum(crec)]; mixr.messagenum:=i;
                    savemix(mixr,crec);
                    dec(thisuser.waiting);
                    reset(uf);
                    seek(uf,i); read(uf,u); inc(u.waiting);
                    seek(uf,i); write(uf,u);
                    close(uf);
                    sysoplog('Forwarded letter to '+caps(u.name)+' #'+cstr(i));
                    dec(mw); crec:=-1;
                    snum:=mnum; mnum:=0; if (snum>mw) then dec(snum);
                    holdit:=FALSE;
                  end;
                end;
              end;
          'G':begin
                prt('Goto message? (1-'+cstr(mw)+') : '); inu(i);
                if ((not badini) and (i>=1) and (i<=mw)) then
                  begin holdit:=FALSE; crec:=-1; mnum:=0; snum:=i; end;
              end;
          'I','N',^N:holdit:=FALSE;
          'Q':begin getout; exit; end;
          'R':;
          'T':dotitles:=TRUE;
          'U':if (cso) then
                if (lastname<>'') then begin
                  noreshow:=TRUE;
                  nl;
                  i:=extractusernum(lastname);
                  if (i<>0) then begin
                    reset(uf);
                    errs:=((i<1) or (i>filesize(uf)-1));
                    if (not errs) then begin
                      {$I-} seek(uf,i); read(uf,u); {$I+}
                      errs:=(ioresult<>0);
                    end;
                    if (errs) then
                      sprint(#3#7+'Unable to find "'+lastname+'" !')
                    else
                      showuserinfo(1,i,u);
                    nl;
                    close(uf);
                  end;
                end;
          'V':if (cso) then
                if (lastname<>'') then begin
                  noreshow:=TRUE;
                  nl;
                  i:=extractusernum(lastname);
                  if (i<>0) then begin
                    reset(uf);
                    errs:=((i<1) or (i>filesize(uf)-1));
                    if (not errs) then begin
                      {$I-} seek(uf,i); read(uf,u); {$I+}
                      errs:=(ioresult<>0);
                    end;
                    close(uf);
                    if (errs) then
                      sprint(#3#7+'Unable to find "'+lastname+'" !')
                    else begin
                      autoval(u,i);
                      reset(uf);
                      {$I-} seek(uf,i); write(uf,u); {$I+}
                      close(uf);
                      sysoplog('Validated '+caps(u.name)+' #'+cstr(i));
                      ssm(abs(mheader.fromi.usernum),^G+'You were validated on '+date+' '+time+'.'^G);
                      nl;
                    end;
                  end;
                end;
          'X':if (mso) then begin
                nl;
                prt('Extract filename? (default="EXT.TXT") : ');
                input(s,40);
                if (s='') then s:='EXT.TXT';
                if pynq('Are you sure? ') then begin
                  b:=pynq('Strip color codes from output? ');

                  loadmhead(crec,mheader);

                  assign(t,s);
                  {$I-} append(t); {$I+}
                  if (ioresult<>0) then rewrite(t);
                  totload:=0;
                  repeat
                    blockreadstr2(brdf,s);
                    inc(totload,length(s)+2);
                    if ((b) and (pos(#3,s)<>0)) then s:=stripcolor(s);
                    writeln(t,s);
                  until (totload>=mheader.msglength);
                  close(t);

                  nl;
                  print('Done!');
                end;
              end;
      'A','S',
      'D','Z':begin
                b:=TRUE;
                if (c in ['A','S']) then begin
                  reset(uf);
                  loadmhead(crec,mheader);
                  i:=mheader.fromi.usernum;
                  if ((i>=1) and (i<=filesize(uf)-1)) then begin
                    seek(uf,i); read(uf,u);
                  end;

                  j:=0; b:=TRUE;
                  while ((j<4) and (b)) do begin
                    inc(j); b:=moremail(u,i,j);
                    if (not b) then
                      case j of
                        1:print('That user''s mailbox is full.');
                        2:print('That user''s mailbox is closed.');
                        3:if (mso) then print('That user is deleted.')
                            else print('Can''t send mail to that user.');
                        4:print('Can''t send mail to yourself!');
                      end;
                  end;
                  close(uf);
                end;

                if (b) then begin
                  if ((c='Z') and (not mso)) then c:='D';
                  case c of
                    'D':ssm(abs(mheader.fromi.usernum),
                          nam+' read your letter on '+date+' '+time+'.');
                'A','S':ssm(abs(mheader.fromi.usernum),
                          nam+' replied to your letter on '+date+' '+time+'.');
                  end;
                  if (c<>'S') then begin
                    s:=rmail(crec);
                    dec(mw); crec:=-1;
                    snum:=mnum; mnum:=0; if (snum>mw) then dec(snum);
                    holdit:=FALSE;
                  end;
                end;
              end;
          '?':begin
                nl;
                lcmds(19,3,'Title listing','');
                lcmds(19,3,'Ignore letter','-Previous letter');
                lcmds(19,3,'Goto letter','Forward letter to other user');
                lcmds(19,3,'Delete letter','Auto-reply to author');
                lcmds(19,3,'Re-read letter','Store and reply (save original)');
                if (cso) then
                  lcmds(19,5,'User info/author','Edit author''s account');
                if (cso) then
                  lcmds(19,5,'Validate author','Zap (delete w/o receipt)')
                else
                  if (mso) then
                    lcmds(19,5,'Zap letter','');
                if (mso) then
                  lcmds(50,5,'Xtract msg to file','');
                lcmds(19,9,'Quit Mail','');
                nl;
                noreshow:=TRUE;
              end;
        end;
        if (c in ['A','S']) then begin
          i:=thisuser.waiting;
          autoreply; inc(mw,thisuser.waiting-i);
        end;
      end;
      if ((mw=0) or ((crec=-1) and (snum=0))) then done:=TRUE;
    until ((done) or (dotitles) or (hangup));
    if (done) then begin getout; exit; end;
  until (hellfreezesover);

  getout;  { just in case hell freezes over! <grin> }
end;

end.
