{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit mail6;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common,
  mail0, mail3, mail9, msgpack;

procedure movemsg(x:integer);
procedure mailr;
procedure dopurgepub(cms:string);
procedure purgepriv;
procedure doshowpackbases;
procedure packmessagebases;
procedure chbds;

implementation

procedure movemsg(x:integer);
var f:file;
    pinfo:pinforec;
    mheader:mheaderrec;
    mixr:msgindexrec;
    s:string;
    brdsig,totload:longint;
    i,oldboard:integer;
    done:boolean;
begin
  nl;
  if ((x>=0) and (x<=himsg)) then begin
    i:=0; done:=FALSE;
    repeat
      prt('Enter board #, (?)List, or (Q)uit : '); input(s,3);
      if ((s='') or (s='Q')) then done:=TRUE
      else
      if (s='?') then begin mbaselist; nl; end
      else begin
        i:=ccboards[0][value(s)];
        if ((i>=1) and (i<>board) and (i<=numboards)) then done:=TRUE;
        if (not done) then print('Can''t move it there.');
      end;
    until ((done) or (hangup));
    if ((i>=1) and (i<=numboards)) then begin
      oldboard:=board;
      changeboard(i);
      if (board=i) then begin
        board:=oldboard;
        ensureloaded(x); mixr:=mintab[getmixnum(x)];
        loadmhead(x,mheader);

        savepinfo(pinfo);
        assign(f,systat.msgpath+brdfnopen+'.BRD'); reset(f,1);
        initbrd(i);

        seek(f,mixr.hdrptr);
        blockread(f,mheader,sizeof(mheaderrec));

        mixr.hdrptr:=filesize(brdf);
        mheader.msgptr:=mixr.hdrptr+sizeof(mheaderrec);
        seek(brdf,mixr.hdrptr);
        blockwrite(brdf,mheader,sizeof(mheaderrec));

        totload:=0;
        repeat
          blockreadstr2(f,s);
          blockwritestr2(brdf,s);
          inc(totload,length(s)+2);
        until (totload>=mheader.msglength);

        savemhead(mheader);
        newmix(mixr);

        loadpinfo(pinfo);
        changeboard(oldboard);
        delmail(x);

        print('Move successful.');
        nl;
      end;
    end;
  end;
end;

procedure mailr;
var mixr:msgindexrec;
    i,j:integer;
    c:char;
    abort,next,gonext,contlist:boolean;
begin
  readingmail:=TRUE;
  contlist:=FALSE; gonext:=FALSE;
  initbrd(-1);
  i:=himsg; c:=#0;
  if ((thisuser.clsmsg<>1) and (i>=0)) then nl;
  while ((i>=0) and (c<>'Q') and (not hangup)) do begin
    ensureloaded(i); mixr:=mintab[getmixnum(i)];
    gonext:=FALSE;
    repeat
      if (c<>'?') then begin
        if ((thisuser.clsmsg=1) and (not contlist)) then cls;
        readmsg(3,i,i,himsg,abort,next);
      end;
      if (not contlist) or ((abort) and (not next)) then begin
        if (contlist) then begin
          print('Continuous message listing off.'); nl;
          contlist:=FALSE;
        end;
        prt('Mail read (?=help) : '); onek(c,'Q-CDGILNR?'^M^N);
      end else
        c:='I';
      case c of
        '?':begin
              nl;
              sprint('<^3CR^1>Next message');
              lcmds(20,3,'Ignore message','-Previous message');
              lcmds(20,3,'Goto message','Continuous listing');
              lcmds(20,3,'Re-read message','Delete message');
              lcmds(20,3,'Quit','');
              nl;
            end;
        '-':if (i<himsg) then inc(i);
        'C':begin
              nl;
              print('Continuous message listing on.');
              contlist:=TRUE;
            end;
        'D':if (miexist in mixr.msgindexstat) then begin
              sysoplog('* Deleted mail to '+rmail(i));
              print('Mail deleted.');
            end else begin
              sysoplog('* Undeleted mail to '+rmail(i));
              print('Mail undeleted.');
            end;
        'G':begin
              prt('Goto which message? (1-'+cstr(himsg)+') : ');
              inu(j);
              if (not badini) then
                if ((j>=0) and (j<=himsg)) then i:=j;
            end;
        'R':;
      else
            gonext:=TRUE;
      end;
    until ((pos(c,'?LR')=0) or (gonext) or (hangup));
    if (gonext) then dec(i);
    gonext:=FALSE;
  end;
  closebrd;
  readingmail:=FALSE;
end;

procedure purgepub(global:boolean);
var oldboard:integer;
    abort,next:boolean;

  procedure purgeit;
  var mheader:mheaderrec;
      mixr:msgindexrec;
      pc:string;
      cn:integer;
      c:char;
  begin
    abort:=FALSE; next:=FALSE;
    nl;
    initbrd(board);
    sprint(#3#3+'[--> Purge '+#3#5+memboard.name+#3#3' <--]');
    cn:=0; c:=#0;
    while ((cn<=himsg) and (not abort) and (not hangup)) do begin
      ensureloaded(cn); mixr:=mintab[getmixnum(cn)]; loadmhead(cn,mheader);
      if (mheader.fromi.usernum<>usernum) then
        inc(cn)
      else begin
        if (c<>'?') then readmsg(4,cn,cn+1,himsg+1,abort,next);
        if (not next) then begin
          pc:='QDIR?'^M^N;
          if (global) then pc:=pc+'B';
          prt('Purge posts (?=help) : '); onek(c,pc);
        end else
          c:='I';
        case c of
          '?':begin
                nl;
                sprint('<'+#3#3+'CR'+#3#1+'>Next msg');
                lcmds(12,3,'Re-read msg','Ignore (next msg)');
                if (global) then
                  lcmds(12,3,'Delete msg','BNext board in purge')
                else
                  lcmds(12,3,'Delete msg','');
                lcmds(12,3,'Quit','');
                nl;
              end;
          'D':if (mipermanent in mixr.msgindexstat) then
                print('This is a permanent message.')
              else begin
                if (miexist in mixr.msgindexstat) then
                  sysoplog('- "'+mheader.title+'" purged off '+
                           #3#5+memboard.name)
                else
                  sysoplog('+ "'+mheader.title+'" unpurged on '+
                           #3#5+memboard.name);
                delmail(cn);
              end;
    ^M,^N,'I':inc(cn);
      'B','Q':begin
                abort:=TRUE; cn:=himsg+1;
                if (c='B') then next:=TRUE;
              end;
        end;
      end;
    end;
    nl;
    sprint(#3#4+'[--> '+#3#5+memboard.name+#3#4+' Purge DONE <--]');
    closebrd;
  end;

  procedure globalpurge;
  var i:integer;
  begin
    nl;
    sprint(#3#7+')>=- Global Purge -=<(');
    i:=1; changeboard(i);
    repeat
      if ((mbaseac(board)) and (board=i)) then purgeit;
      inc(i); changeboard(i);
      if (next) then abort:=FALSE;
    until ((i>numboards) or (abort) or (hangup));
    nl;
    sprint(#3#7+'[> Global Purge COMPLETE <]');
  end;

begin
  oldboard:=board;
  if (global) then globalpurge else purgeit;
  board:=oldboard;
end;

procedure dopurgepub(cms:string);
var i:integer;
begin
  if (cms='C') then purgepub(FALSE)
  else if (cms='G') then purgepub(TRUE)
  else if (value(cms)<>0) then begin
    i:=board;
    changeboard(value(cms));
    if (board=value(cms)) then purgepub(FALSE);
    changeboard(i);
  end else begin
    nl;
    purgepub(pynq('Global purge? '));
  end;
end;

procedure purgepriv;
var mheader:mheaderrec;
    mixr:msgindexrec;
    i:integer;
    c:char;
    abort,done,next:boolean;
begin
  readingmail:=TRUE; done:=FALSE;
  nl;
  initbrd(-1);
  i:=0; c:=#0;
  while ((i<=himsg) and (not done) and (not hangup)) do begin
    ensureloaded(i); mixr:=mintab[getmixnum(i)]; loadmhead(i,mheader);
    if (mheader.fromi.usernum<>usernum) then
      inc(i)
    else begin
      if (c<>'?') then begin
        if ((thisuser.clsmsg=1) and (not contlist)) then cls;
        readmsg(4,i,i+1,himsg+1,abort,next);
      end;
      prt('Delete mail (?=help) : '); onek(c,'QDINR?'^M^N);
      case c of
        '?':begin
              nl;
              sprint('<^3CR^1>Next message');
              lcmds(20,3,'Re-read message','Ignore (next message)');
              lcmds(20,3,'Delete message','Quit');
              nl;
            end;
        'Q':done:=TRUE;
        'D':if (miexist in mixr.msgindexstat) then begin
              sysoplog('* Deleted mail to '+rmail(i));
              print('Mail deleted.');
            end else begin
              sysoplog('* Undeleted mail to '+rmail(i));
              print('Mail undeleted.');
            end;
      else
            inc(i);
      end;
    end;
  end;
  closebrd; topscr;
  readingmail:=FALSE;
end;

procedure doshowpackbases;
var tempboard:boardrec;
    i:integer;
    b:boolean;
begin
  b:=(pause in thisuser.ac);
  thisuser.ac:=thisuser.ac-[pause];
  nl;
  sysoplog('Packed all message bases');
  sprint(#3#4+'þþ '+#3#3+'Packing all message bases '+#3#4+'þþ');
  nl;
  sprint(#3#1+'Packing '+#3#5+'Private Mail'); packbase('email',0);
  reset(bf);
  for i:=0 to filesize(bf)-1 do begin
    reset(bf); seek(bf,i); read(bf,tempboard);
    sprint(#3#1+'Packing '+#3#5+tempboard.name+#3#5+' #'+cstr(i+1));
    packbase(tempboard.filename,tempboard.maxmsgs);
  end;
  reset(bf); close(bf);
	lil:=0;
	if (b) then thisuser.ac:=thisuser.ac+[pause];
end;

procedure packmessagebases;
begin
  nl;
  if pynq('Pack all message bases? ') then doshowpackbases else begin
    with memboard do begin
      sysoplog('Packed message base '+#3#5+memboard.name);
      nl; sprint(#3#1+'Packing '+#3#5+name+#3#5+' #'+cstr(ccboards[1][board]));
      packbase(filename,maxmsgs);
    end;
  end;
end;

procedure chbds;
var s:astr;
    i:integer;
    done:boolean;
begin
  nl;
  if (novice in thisuser.ac) then begin mbaselist; nl; end;
  done:=FALSE;
  repeat
    prt('Set NewScan message bases (Q=Quit,?=List,#=Toggle base) : '); input(s,3);
    if (s='Q') then done:=TRUE;
    if (s='?') then begin mbaselist; nl; end;
    i:=ccboards[0][value(s)];
    if (mbaseac(i)) then { loads memboard }
      if (i>=1) and (i<=numboards) and
         (length(s)>0) and (s[1] in ['0'..'9']) then begin
        nl;
        sprompt(#3#5+memboard.name+#3#3);
        if (i in zscanr.mzscan) then begin
          sprint(' will NOT be scanned.');
          zscanr.mzscan:=zscanr.mzscan-[i];
        end else begin
          sprint(' WILL be scanned.');
          zscanr.mzscan:=zscanr.mzscan+[i];
        end;
        nl;
      end;
  until (done) or (hangup);
  lastcommandovr:=TRUE;
  savezscanr;
end;

end.
