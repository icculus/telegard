{*****************************************************************************
 *                                                                           *
 * Menus.Pas -                                                               *
 *      Menu Command Execution Routines.                                     *
 *                                                                           *
 * Modification History                                                      *
 * ====================                                                      *
 *   08/20/91 - 1.00 - E?O - Original Version                                *
 *                                                                           *
 *****************************************************************************}
{$A+,B+,E+,F+,I+,L+,N-,O-,R-,S+,V-}
Unit Menus;

Interface

Uses

  {rcg11172000 no overlay under Linux.}
  {Overlay,}

  Crt,      Dos,      InitP,    Sysop1,   Sysop2,   Sysop3,
  Sysop4,   Sysop5,   Sysop6,   Sysop7,   Sysop8,   Sysop9,   Sysop10,
  Sysop11,  Mail0,    Mail1,    Mail2,    Mail3,    Mail4,    Mail5,
  Mail6,    Mail9,    File0,    File1,    File2,    File3,    File4,
  File5,    File6,    File7,    File8,    File9,    File10,   File11,
  File12,   File13,   File14,   Archive1, Archive2, Archive3, Misc1,
  Misc2,    Misc3,    Misc4,    MiscX,    CUser,    Doors,    Menus2,
  Menus3,   Menus4,   MyIO,     Common;

Procedure readin2;
Procedure mainmenuhandle(var cmd:string);
Procedure fcmd(cmd:string; var i:integer; noc:integer;
               var cmdexists,cmdnothid:boolean);
Procedure domenuexec(cmd:string; var newmenucmd:string);
Procedure domenucommand(var done:boolean; cmd:string; var newmenucmd:string);

Implementation

Procedure readin2;
var s:string;
    nacc:boolean;
begin
  readin;
  nacc:=FALSE;
  with menur do begin
    if ((not aacs(acs)) or (password<>'')) then
    begin
      nacc:=TRUE;
      if (password<>'') then
      begin
        nl; prt('Password: '); input(s,15);
        if (s=password) then nacc:=FALSE;
      end;
      if (nacc) then
      begin
        nl; print('Access denied.'); pausescr;
        print('Dropping back to fallback menu...');
        curmenu:=systat.menupath+fallback+'.mnu';
        readin;
      end;
    end;
    if (not nacc) then
      if (forcehelplevel<>0) then
        chelplevel:=forcehelplevel
      else
        if (novice in thisuser.ac) then chelplevel:=2 else chelplevel:=1;
  end;
end;

procedure checkforcelevel;
begin
  if (chelplevel<menur.forcehelplevel) then chelplevel:=menur.forcehelplevel;
end;

procedure getcmd(var s:string);
var s1,ss,oss,shas0,shas1:string;
    i,newarea:integer;
    c,cc:char;
    oldco:byte;
    achange,bb,gotcmd,has0,has1,has2:boolean;
begin
  s:='';
  if (buf<>'') then
    if (copy(buf,1,1)='`') then
    begin
      buf:=copy(buf,2,length(buf)-1);
      i:=pos('`',buf);
      if (i<>0) then
      begin
        s:=allcaps(copy(buf,1,i-1)); buf:=copy(buf,i+1,length(buf)-i);
        nl; exit;
      end;
    end;

  shas0:='?|'; shas1:='';
  has0:=FALSE; has1:=FALSE; has2:=FALSE;

  { find out what kind of 0:"x", 1:"/x", and 2:"//xxxxxxxx..." commands
    are in this menu. }

  for i:=1 to noc do 
    if (aacs(cmdr[i].acs)) then
      if (cmdr[i].ckeys[0]=#1) then
      begin
        has0:=TRUE; shas0:=shas0+cmdr[i].ckeys;
      end else
        if ((cmdr[i].ckeys[1]='/') and (cmdr[i].ckeys[0]=#2)) then
        begin
          has1:=TRUE; shas1:=shas1+cmdr[i].ckeys[2];
         end else
           has2:=TRUE;

  oldco:=curco;

  gotcmd:=FALSE; ss:='';
  if (not (onekey in thisuser.ac)) then
    input(s,60)
  else begin
    repeat
      getkey(c); c:=upcase(c);
      oss:=ss;
      if (ss='') then begin
        if (c=#13) then gotcmd:=TRUE;
        if ((c='/') and ((has1) or (has2) or (thisuser.sl=255))) then ss:='/';
        if ((c='=') and (cso)) then begin gotcmd:=TRUE; ss:=c; end;
        if (((fqarea) or (mqarea)) and (c in ['0'..'9'])) then
          ss:=c
        else
          if (pos(c,shas0)<>0) then begin gotcmd:=TRUE; ss:=c; end;
      end else
        if (ss='/') then begin
          if (c=^H) then ss:='';
          if ((c='/') and ((has2) or (thisuser.sl=255))) then ss:=ss+'/';
          if ((pos(c,shas1)<>0) and (has1)) then
            begin gotcmd:=TRUE; ss:=ss+c; end;
        end else
          if (copy(ss,1,2)='//') then begin
            if (c=#13) then
              gotcmd:=TRUE
            else
              if (c=^H) then
                ss:=copy(ss,1,length(ss)-1)
              else
                if (c=^X) then begin
                  for i:=1 to length(ss)-2 do
                    prompt(^H' '^H);
                  ss:='//';
                  oss:=ss;
                end else
                  if ((length(ss)<62) and (c>=#32) and (c<=#127)) then
                    ss:=ss+c;
          end else
            if ((length(ss)>=1) and (ss[1] in ['0'..'9']) and
                ((fqarea) or (mqarea))) then begin
              if (c=^H) then ss:=copy(ss,1,length(ss)-1);
              if (c=#13) then gotcmd:=TRUE;
              if (c in ['0'..'9']) then begin
                ss:=ss+c;
                if (length(ss)=3) then gotcmd:=TRUE;
              end;
            end;

      if ((length(ss)=1) and (length(oss)=2)) then setc(oldco);
      if (oss<>ss) then begin
        if (length(ss)>length(oss)) then prompt(copy(ss,length(ss),1));
        if (length(ss)<length(oss)) then prompt(^H' '^H);
      end;
      if ((not (ss[1] in ['0'..'9'])) and
        ((length(ss)=2) and (length(oss)=1))) then cl(6);

    until ((gotcmd) or (hangup));

    if (copy(ss,1,2)='//') then ss:=copy(ss,3,length(ss)-2);

    s:=ss;
  end;

  nl;

  if (pos(';',s)<>0) then                 {* "command macros" *}
    if (copy(s,1,2)<>'\\') then begin
      if (onekey in thisuser.ac) then begin
        s1:=copy(s,2,length(s)-1);
         if (copy(s1,1,1)='/') then s:=copy(s1,1,2) else s:=copy(s1,1,1);
         s1:=copy(s1,length(s)+1,length(s1)-length(s));
      end else begin
        s1:=copy(s,pos(';',s)+1,length(s)-pos(';',s));
        s:=copy(s,1,pos(';',s)-1);
      end;
      while (pos(';',s1)<>0) do s1[pos(';',s1)]:=^M;
      dm(' '+s1,c);
    end;
end;

procedure mainmenuhandle(var cmd:string);
var newarea:integer;
    wantshow:boolean;
begin
  tleft;
  macok:=TRUE;

  checkforcelevel;

  if ((forcepause in menur.menuflags) and (chelplevel>1) and (lastcommandgood))
    then pausescr;
  lastcommandgood:=FALSE;
  showthismenu;

  if (not (nomenuprompt in menur.menuflags)) then begin
    nl;
    if (autotime in menur.menuflags) then
      sprint(#3#3+'[<Time Left - '+tlef+'>]');
    sprompt(menur.menuprompt);
  end;

  getcmd(cmd);

  if (cmd='?') then
  begin
    cmd:='';
    inc(chelplevel);
    if (chelplevel>3) then chelplevel:=3;
    if ((menur.tutorial='*OFF*') and (chelplevel>=3)) then chelplevel:=2;
  end else
    if (menur.forcehelplevel<>0) then chelplevel:=menur.forcehelplevel
    else
      if (novice in thisuser.ac) then chelplevel:=2 else chelplevel:=1;

  checkforcelevel;

  if (fqarea) or (mqarea) then begin
    newarea:=value(cmd);
    if ((newarea<>0) or (copy(cmd,1,1)='0')) then begin
      if (fqarea) then begin
        if (newarea>=0) and (newarea<=maxuboards) then
          changefileboard(ccuboards[0][newarea]);
      end else
      if (mqarea) then
        if (newarea>=0) and (newarea<=maxboards) then
          changeboard(ccboards[0][newarea]);
      cmd:='';
    end;
  end;
end;

procedure fcmd(cmd:string; var i:integer; noc:integer;
               var cmdexists,cmdnothid:boolean);
var done:boolean;
begin
  done:=FALSE;
  repeat
    inc(i);
    if (cmd=cmdr[i].ckeys) then begin
      cmdexists:=TRUE;
      if (oksecurity(i,cmdnothid)) then done:=TRUE;
    end;
  until ((i>noc) or (done));
  if (i>noc) then i:=0;
end;

procedure domenuexec(cmd:string; var newmenucmd:string);
var cmdacs,cmdnothid,cmdexists,done:boolean;
    nocsave,i:integer;
begin
  if (newmenucmd<>'') then begin cmd:=newmenucmd; newmenucmd:=''; end;
  if (cmd<>'') then begin
    cmdacs:=FALSE; cmdexists:=FALSE; cmdnothid:=FALSE; done:=FALSE;
    nocsave:=noc; i:=0;
    repeat
      fcmd(cmd,i,nocsave,cmdexists,cmdnothid);
      if (i<>0) then begin
        cmdacs:=TRUE;
        domenucommand(done,cmdr[i].cmdkeys+cmdr[i].mstring,newmenucmd);
      end;
    until ((i=0) or (done));
    if (not done) then
      if ((not cmdacs) and (cmd<>'')) then begin
        nl;
        if ((cmdnothid) and (cmdexists)) then
          print('You don''t have enough access for this command.')
        else
          print('Invalid command.');
      end;
  end;
end;

procedure domenucommand(var done:boolean; cmd:string; var newmenucmd:string);
var filvar:text;
    mheader:mheaderrec;
    cms,s,s1,s2:string;
    i:integer;
    c1,c2,c:char;
    abort,next,b,nocmd:boolean;

  function semicmd(x:integer):string;
  var s:string;
      i,p:integer;
  begin
    s:=cms; i:=1;
    while (i<x) and (s<>'') do begin
      p:=pos(';',s);
      if (p<>0) then s:=copy(s,p+1,length(s)-p) else s:='';
      inc(i);
    end;
    while (pos(';',s)<>0) do s:=copy(s,1,pos(';',s)-1);
    semicmd:=s;
  end;

begin
  newmenutoload:=FALSE;
  newmenucmd:='';
  c1:=cmd[1]; c2:=cmd[2];
  cms:=copy(cmd,3,length(cmd)-2);
  nocmd:=FALSE;
  lastcommandovr:=FALSE;
  case c1 of
    '-':case c2 of
          'C':commandline(cms);
          'F':printf(cms);
          'L':begin nl; sprint(cms); end;
          'Q':readq(systat.afilepath+cms,0);
          'R':readasw1(cms);
          'S':sysoplog(cms);
          ';':begin
                s:=cms;
                while (pos(';',s)<>0) do s[pos(';',s)]:=^M;
                dm(' '+s,c);
              end;
          '$':if (semicmd(1)<>'') then begin
                if (semicmd(2)='') then prt(':') else prt(semicmd(2));
                input(s,20);
                if (s<>semicmd(1)) then begin
                  done:=TRUE;
                  if (semicmd(3)<>'') then sprint(semicmd(3));
                end;
              end;
          '^','/','\':dochangemenu(done,newmenucmd,c2,cms);
        else  nocmd:=TRUE;
        end;
    'A':case c2 of
          'A','C','M','T','X':doarccommand(c2);
          'E':extracttotemp;
          'G':userarchive;
          'R':rezipstuff;
        else  nocmd:=TRUE;
        end;
    'B':case c2 of
          '?':batchinfo;
          'C':if (cms='U') then clearubatch else clearbatch;
          'D':batchdl;
          'L':if (cms='U') then listubatchfiles else listbatchfiles;
          'R':if (cms='U') then removeubatchfiles else removebatchfiles;
          'U':batchul;
        else  nocmd:=TRUE;
        end;
    'D':case c2 of
          'C','D','G','S','W','-':dodoorfunc(c2,cms);
        else  nocmd:=TRUE;
        end;
    'F':case c2 of
          'A':fbasechange(done,cms);
          'B':browse;
          'D':idl;
          'F':searchd;
          'I':listopts;
          'L':listfiles;
          'N':nf(cms);
          'P':pointdate;
          'R':remove;
          'S':search;
          'U':iul;
          'V':lfii;
          'Y':yourfileinfo;
          'Z':setdirs;
          '@':createtempdir;
          '#':begin
                nl;
                print('Enter the number of the file base to change to it.');
              end;
          '$':fbasestats;
        else  nocmd:=TRUE;
        end;
    'H':case c2 of
          'C':if pynq('@M@M'+cms) then begin
                cls;
                printf('logoff');
                hangup:=TRUE;
                hungup:=FALSE;
              end;
          'I':hangup:=TRUE;
          'M':begin
                nl; sprint(cms);
                hangup:=TRUE;
              end;
        else  nocmd:=TRUE;
        end;
    'M':case c2 of
          'A':mbasechange(done,cms);
          'E':ssmail(cms);
          'J':dopurgepub(cms);
          'K':purgepriv;
          'L':smail(TRUE);
          'M':readmail;
          'N':nscan(cms);
          'P':begin
                post(-1,mheader.fromi);
                closebrd;
              end;
          'S':scanmessages;
          'U':ulist;
	  'Z':chbds;
          '#':begin
                nl;
                print('Enter the number of the message base to change to it.');
              end;
          '$':mbasestats;
        else  nocmd:=TRUE;
        end;
    'O':case c2 of
          '1'..'3':tshuttlelogon:=ord(c2)-48;
          'A':autovalidationcmd(cms);
          'B':abbs;
          'C':reqchat(cms);
          'I':begin
                nl; nl; sprint(#3#3+centre(verline(1)));
                sprint(#3#3+centre(verline(2))); nl; abort:=FALSE;
                printf('logon'); printf('system');
              end;
          'M':mmacro;
          'O':sysopstatus;
          'P':cstuff(value(cms),2,thisuser);
          'S':bulletins(cms);
          'T':tfiles;
          'V':vote;
          'Y':yourinfo;
          '$':TimeBank(cms);
        else  nocmd:=TRUE;
        end;
    'U':case c2 of
          'A':replyamsg;
          'R':readamsg;
          'W':wamsg;
        else  nocmd:=TRUE;
        end;
    '*':case c2 of
          'B':if (checkpw) then begin
                sysoplog('* Message base edit');
                boardedit;
              end;
          'C':if (checkpw) then chuser;
          'D':begin
                sysoplog('* Entered MiniDos');
                minidos;
              end;
          'E':if (checkpw) then begin
                sysoplog('* Event edit');
                eventedit;
              end;
          'F':if (checkpw) then begin
                sysoplog('* File base edit');
                dlboardedit;
              end;
          'I':if (checkpw) then begin
                sysoplog('* Vote edit');
                initvotes;
              end;
          'L':showlogs;
          'N':tedit1;
          'P':if (checkpw) then begin
                sysoplog('* System configuration modification');
                changestuff;
              end;
          'T':if (checkpw) then begin
                sysoplog('* Tfile base edit');
                tfileedit;
              end;
          'U':if (checkpw) then begin
                sysoplog('* User editor');
                uedit1;
              end;
          'V':begin
                nl;
                if pynq('Do you want to re-output VOTES.TXT? ') then begin
                  sysoplog('+ Re-outputted VOTES.TXT');
                  voteprint;
                end;
                if pynq('Do you want to see VOTES.TXT? ') then begin
                  sysoplog('+ Viewed VOTES.TXT');
                  printfile(systat.afilepath+'votes.txt');
                end;
              end;
          'X':if (checkpw) then begin
                sysoplog('* Protocol editor');
                exproedit;
              end;
          'Z':begin
                sysoplog('+ Viewed ZLOG');
                zlog;
              end;
          '1':begin
                sysoplog('* Edited files'); editfiles;
              end;
          '2':begin
                sysoplog('* Sorted files'); sort;
              end;
          '3':if (checkpw) then begin
                sysoplog('* Read private mail'); mailr;
              end;
          '4':if (cms='') then do_unlisted_download
                else unlisted_download(cms);
          '5':move;
          '6':uploadall;
          '7':validatefiles;
          '8':addgifspecs;
          '9':packmessagebases;
          '#':if (checkpw) then begin
                sysoplog('* Menu edit');
                last_menu:=curmenu;
                menu_edit;
                first_time:=TRUE;
                curmenu:=last_menu;
                readin2;
              end;
          '$':dirf(TRUE);
          '%':dirf(FALSE);
        else  nocmd:=TRUE;
        end;
  else
        nocmd:=TRUE;
  end;
  lastcommandgood:=not nocmd;
  if (lastcommandovr) then lastcommandgood:=FALSE;
  if (nocmd) then
    if (cso) then
    begin
      sysoplog('Invalid command : Cmdkeys "'+cmd+'"');
      nl; print('Invalid command : Cmdkeys "'+cmd+'"');
    end;
  if (newmenutoload) then
  begin
    readin2;
    lastcommandgood:=FALSE;
    if (newmenucmd='') then begin
      i:=1;
      while ((i<=noc) and (newmenucmd='')) do
      begin
        if (cmdr[i].ckeys='FIRSTCMD') then
          if (aacs(cmdr[i].acs)) then newmenucmd:='FIRSTCMD';
        inc(i);
      end;
    end;
  end;
end;

end.
