(*****************************************************************************)
(*>                                                                         <*)
(*>  SYSOP10 .PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  SysOp functions: Voting question editor, voting results output.        <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit sysop11;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  misc1, miscx,
  menus2,
  common;

procedure chuser;
procedure zlog;
procedure showlogs;
procedure showmenucmds;

implementation

procedure chuser;
var macrf:file of macrorec;
    s:astr;
    i:integer;
begin
  prt('Which user? ');
  finduser(s,i);
  if (i>=1) then begin
    thisuser.sl:=realsl; thisuser.dsl:=realdsl;

    reset(uf);
    seek(uf,usernum); write(uf,thisuser);
    seek(uf,i); read(uf,thisuser);
    close(uf);

    realsl:=thisuser.sl; realdsl:=thisuser.dsl;
    usernum:=i;
    choptime:=0.0; extratime:=0.0; freetime:=0.0;

    readinmacros; readinzscan;

    if (spd<>'KB') then sysoplog(#3#8+'#*#*#*# '+#3#7+'Changed to '+#3#5+nam);
    topscr;
    newcomptables;
  end;
end;

procedure zlog;
var zf:file of zlogrec;
    d1:zlogrec;
    s,dd:astr;
    i:integer;
    abort,next:boolean;

  function mrnn(i,l:integer):astr;
  begin
    mrnn:=mrn(cstr(i),l);
  end;

begin
  nl;
  assign(zf,systat.gfilepath+'zlog.dat');
  {$I-} reset(zf); {$I+}
  if (ioresult<>0) then print('ZLOG.DAT not found.')
  else begin
    abort:=FALSE;
    read(zf,d1);

    printacr(#3#3+'        '+sepr2+'Mins '+sepr2+'    '+sepr2+'      '+
             sepr2+'#New'+sepr2+'Tim/'+sepr2+'Pub '+sepr2+'Priv'+
             sepr2+'Feed'+sepr2+'    '+sepr2+'    '+sepr2+'     '+
             sepr2+'    '+sepr2+'',abort,next);
    printacr(#3#3+'  Date  '+sepr2+'Activ'+sepr2+'Call'+sepr2+'%Activ'+
             sepr2+'User'+sepr2+'User'+sepr2+'Post'+sepr2+'Post'+
             sepr2+'Back'+sepr2+'Errs'+sepr2+'#ULs'+sepr2+'UL-k '+
             sepr2+'#DLs'+sepr2+'DL-k',abort,next);
    printacr(#3#4+'========:=====:====:======:====:====:====:====:====:====:====:=====:====:=====',abort,next);
    i:=-1;
    seek(zf,0);
    while ((i<=filesize(zf)-1) and (not abort) and (d1.date<>'')) do begin
      if (i>=0) then begin
        read(zf,d1);
        dd:=d1.date;
      end else begin
        d1:=systat.todayzlog;
        dd:=#3#5+'Today''s ';
      end;
      if (d1.calls>0) then s:=mrnn(d1.active div d1.calls,4) else s:='    ';
      printacr(dd+' '+mrnn(d1.active,5)+' '+mrnn(d1.calls,4)+' '+
               ctp(d1.active,1440)+' '+mrnn(d1.newusers,4)+' '+
               s+' '+mrnn(d1.pubpost,4)+' '+mrnn(d1.privpost,4)+' '+
               mrnn(d1.fback,4)+' '+mrnn(d1.criterr,4)+' '+
               mrnn(d1.uploads,4)+' '+mrnn(d1.uk,5)+' '+
               mrnn(d1.downloads,4)+' '+mrnn(d1.dk,5),abort,next);
      inc(i);
    end;
    close(zf);
  end;
end;

procedure showlogs;
var s:astr;
    day:integer;
begin
  nl;
  print('SysOp Logs available for up to '+cstr(systat.backsysoplogs)+' days ago.');
  prt('Date (MM/DD/YY) or # days ago (0-'+cstr(systat.backsysoplogs)+') [0] : ');
  input(s,8);
  if (length(s)=8) and (daynum(s)>0) then day:=daynum(date)-daynum(s)
    else day:=value(s);

  if (day=0) then close(sysopf);
  if (day=0) then printf(systat.trappath+'sysop.log')
    else printf(systat.trappath+'sysop'+cstr(day)+'.log');
  if (nofile) then begin nl; print('SysOp Log not found.'); end;
  if (day=0) then append(sysopf);

  if (useron) then begin
    s:='*> Viewed SysOp Log - ';
    if (day=0) then s:=s+'Today''s' else s:=s+cstr(day)+' days ago';
    sysoplog(s);
  end;
end;

procedure showmenucmds;
var i:integer;
    abort,next:boolean;

  function sfl(b:boolean; c:char):char;
  begin
    if (b) then sfl:=c else sfl:='-';
  end;

begin
  nl;
  sprint('Current menu  :'+#3#3+curmenu);
  sprint('# of commands :'+#3#3+cstr(noc));
  sprompt('Prev. menus  :'+#3#3);
  if (menustackptr=0) then prompt('None.')
  else
    for i:=1 to menustackptr do begin
      prompt(menustack[i]);
      if (i<menustackptr) then prompt(',');
    end;
  nl; nl;
  with menur do begin
    i:=1;
    abort:=FALSE; next:=FALSE;
    while ((i<=10) and (not abort) and (not hangup)) do begin
      case i of
        1:begin
            sprint('1. Menu titles   :'+menuname[1]);
            if (menuname[2]<>'') then
              sprint('   Menu title #2 :'+menuname[2]);
            if (menuname[3]<>'') then
              sprint('   Menu title #3 :'+menuname[3]);
          end;
        2:print('2. Help files    :'+
                aonoff((directive=''),'*Generic*',directive)+' / '+
                aonoff((tutorial=''),'*Generic*',tutorial));
        3:print('3. Prompt        :'+menuprompt);
        4:sprint(#3#3+'('+#3#1+menuprompt+#3#3+')');
        5:print('4. ACS required  :"'+acs+'"');
        6:print('5. Password      :'+
                aonoff((password=''),'*None*',password));
        7:print('6. Fallback menu :'+
                aonoff((fallback=''),'*None*',fallback));
        8:print('7. Forced ?-level:'+
                aonoff((forcehelplevel=0),'None',cstr(forcehelplevel)));
        9:print('8. Generic info  :'+cstr(gencols)+' cols - '+
                cstr(gcol[1])+'/'+cstr(gcol[2])+'/'+cstr(gcol[3]));
        10:print('9. Flags         :'+
                 sfl((clrscrbefore in menuflags),'C')+
                 sfl((dontcenter in menuflags),'D')+
                 sfl((nomenuprompt in menuflags),'N')+
                 sfl((forcepause in menuflags),'P')+
                 sfl((autotime in menuflags),'T'));
      end;
      if (not empty) then wkey(abort,next);
      inc(i);
    end;
  end;
  if (not abort) then begin
    nl;
    showcmds(0);
  end;
  lastcommandgood:=TRUE;
end;

end.
