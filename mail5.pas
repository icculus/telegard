{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit mail5;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common, timejunk,
  sysop4,
  mail0, mail1, mail2, mail3, mail4, mail6;

procedure post(replyto:longint; ttoi:fromtoinfo);
procedure scanmessages;
procedure qscan(b:integer; var quit:boolean);
procedure gnscan;
procedure nscan(mstr:string);

implementation

procedure post(replyto:longint; ttoi:fromtoinfo);
var pinfo:pinforec;
    mheader:mheaderrec;
    mixr,mixr2:msgindexrec;
    saveit:string;
    itreepos,lng,otreepos:longint;
    i:integer;
    numread:word;
    savilevel:byte;
    ok:boolean;

  procedure nope(s:string);
  begin
    if (ok) then begin nl; print(s); end;
    ok:=FALSE;
  end;

begin
  ok:=TRUE;
  loadboard(board);
  if (not aacs(memboard.postacs)) then
    nope('Your access does not allow you to post on this board.');
  if ((rpost in thisuser.ac) or (not aacs(systat.normpubpost))) then
    nope('Your access privledges do not include posting.');
  if ((ptoday>=systat.maxpubpost) and (not mso)) then
    nope('Too many messages posted today.');
  if (ok) then begin
    savepinfo(pinfo);
    initbrd(board);

    saveit:='';
    if (replyto<>-1) then begin
      mheader.toi:=ttoi;
      if (mheader.toi.anon<>0) then begin
        saveit:=mheader.toi.as;
        mheader.toi.as:=what00(mheader.toi.anon,mheader.toi.as);
      end;
    end else
      mheader.toi.as:='';

    if (inmsg(TRUE,(replyto<>-1),'',mixr,mheader)) then begin
      if (saveit<>'') then mheader.toi.as:=saveit;
      seek(brdf,mixr.hdrptr);
      savemhead(mheader);

      if (replyto<>-1) then begin
        mixr.isreplyto:=replyto;
        mixr.numreplys:=0;
        mixr.msgindexstat:=mixr.msgindexstat+[mithreads];
        ensureloaded(replyto);
        mixr2:=mintab[getmixnum(replyto)];
        mixr.isreplytoid:=mixr2.msgid;
        inc(mixr2.numreplys);
        mixr2.msgindexstat:=mixr2.msgindexstat+[mithreads];
        ensureloaded(replyto);
        savemix(mixr2,replyto);
        ensureloaded(replyto);
      end;

      newmix(mixr);
      ensureloaded(himsg);

      sysoplog('+ "'+mheader.title+'" posted on '+#3#5+memboard.name);
      if (mheader.toi.as<>'') then sysoplog('  To: "'+mheader.toi.as+'"');

      topscr;
      sprint(#3#9+'Message posted on '+#3#5+memboard.name+#3#9+'.');

      inc(thisuser.msgpost);
      inc(ptoday);
      inc(systat.todayzlog.pubpost);
    end;
    loadpinfo(pinfo);
  end;
end;

function isnew1(msgdatepp:packdatetimepp):boolean;
var msgdate:packdatetime;
    l1,l2,l3:longint;

  function zzzb(xx,yy:longint):longint;
    begin xx:=xx shl yy; zzzb:=xx; end;

begin
  msgdate:=msgdatepp^;
  isnew1:=FALSE;
  with zscanr do begin
    l1:=zzzb(msgdate[1],16);
    inc(l1,zzzb(msgdate[2],8));
    inc(l1,msgdate[3]);
    l2:=zzzb(mhiread[board][1],16);
    inc(l2,zzzb(mhiread[board][2],8));
    inc(l2,mhiread[board][3]);
    if (l1<l2) then exit;
    if (l1=l2) then begin
      l1:=zzzb(msgdate[4],16);
      inc(l1,zzzb(msgdate[5],8));
      inc(l1,msgdate[6]);
      l2:=zzzb(mhiread[board][4],16);
      inc(l2,zzzb(mhiread[board][5],8));
      inc(l2,mhiread[board][6]);
      if (l1<=l2) then exit;
    end;
    isnew1:=TRUE;
  end;
end;

function isnew(cn:integer):boolean;
var mixr:msgindexrec;
begin
  ensureloaded(cn);
  mixr:=mintab[getmixnum(cn)];
  isnew:=isnew1(@mixr.msgdate);
end;

procedure updateptr(x:word; var zup:boolean);
var mixr:msgindexrec;
    l1,l2:longint;
    i:integer;
begin
  if (isnew(x)) then begin
    ensureloaded(x);
    mixr:=mintab[getmixnum(x)];
    for i:=1 to 6 do zscanr.mhiread[board][i]:=mixr.msgdate[i];
    zup:=TRUE;
  end;
end;

procedure editmessage(i:integer);
var t:text;
    f:file;
    g:text;
    mheader:mheaderrec;
    mixr:msgindexrec;
    s:string;
    brdsig,dfdt1,dfdt2,newmsgptr,totload:longint;
begin

  loadmhead(i,mheader);
  assign(t,'tgtempx.msg'); rewrite(t);
  totload:=0;
  repeat
    blockreadstr2(brdf,s);
    inc(totload,length(s)+2);
    writeln(t,s);
  until (totload>=mheader.msglength);
  close(t);

  tedit(allcaps('tgtempx.msg'));
  begin
    assign(t,'tgtempx.msg');
    reset(t);
    mheader.msglength:=0;
    repeat
      readln(t,s);
      inc(mheader.msglength,length(s)+2);
    until (eof(t));
    close(t);
    newmsgptr:=filesize(brdf);
    seek(brdf,newmsgptr);
    outmessagetext('tgtempx.msg',mheader,TRUE);
    ensureloaded(i);
    mixr:=mintab[getmixnum(i)];
    mixr.hdrptr:=newmsgptr;
    savemix(mixr,i);
    ensureloaded(i);
  end;
end;

procedure pubreply(cn:word);
var t:text;
    mheader:mheaderrec;
    s:string;
    brdsig,dfdt1,dfdt2,newmsgptr,totload:longint;
begin
  if (gotlastmheader) then begin
    loadmhead(cn,mheader);

    assign(t,'msgtmp'); rewrite(t);
    totload:=0;
    repeat
      blockreadstr2(brdf,s);
      inc(totload,length(s)+2);
      writeln(t,s);
    until (totload+1>=mheader.msglength);
    close(t);

    post(cn,lastmheader.fromi);

    assign(t,'msgtmp');
    {$I-} reset(t); {$I+}
    if (ioresult=0) then begin close(t); erase(t); end;
  end else begin
    nl; print('Can''t reply YET.'); nl;
  end;
end;

type
  mstype =
    (msreadp,       { read prompt }
     msshowt,       { show titles }
     msreadm);      { read message }

  sttype =
    (stnewscan,     { NewScan mode }
     stscan);       { normal Scan mode }

procedure doscan(var quit:boolean; cn:word; st:sttype; ms:mstype);
var t:text;
    u:userrec;
    mheader:mheaderrec;
    mixr:msgindexrec;
    lastdate:packdatetime;
    inp,s:string;
    brdsig,getm,totload:longint;
    i,j,k:integer;
    cmd:char;
    abort,askpost,b,contlist,donescan,hadunval,next,ufo,wasout,zup:boolean;

  procedure cbounds;
  begin
    wasout:=((cn<0) or (cn>himsg));
    if (not wasout) then exit;
    if (cn>himsg) then cn:=himsg
      else if (cn<0) then cn:=0;
  end;

  function tch(c:char; i:integer):string; (* duplicate.... MARTIN HANDLE THIS!*)
  var s:string;
  begin
    s:=cstr(i); if (i<10) then s:=c+s;
    tch:=s;
  end;

  procedure stitles;
  var mheader:mheaderrec;
      dt:ldatetimerec;
      pdt:packdatetime;
      s,real,alias:string;
      i,j,numdone:word;
      abort,ndone,next:boolean;
  begin
    nl;
    ndone:=TRUE;
    abort:=FALSE; numdone:=0;
    cbounds; if (wasout) then exit;
    while ((not hangup) and (not abort) and (numdone<10) and (ndone)) do begin
      cbounds; if (wasout) then ndone:=FALSE;
      if (ndone) then begin
        loadmhead(cn,mheader); ensureloaded(cn);
        i:=cn;
        with mheader do begin
          real:=allcaps(thisuser.realname);
          alias:=allcaps(thisuser.name);
          if ((fromi.usernum=usernum) or
            (allcaps(copy(fromi.as,1,length(real)))=real) or
            (allcaps(copy(fromi.alias,1,length(alias)))=alias)) then
            s:=#3#9+'['+#3#5+cstr(i+1)+#3#9+']'
          else if ((toi.usernum=usernum) or
            (allcaps(copy(toi.as,1,length(real)))=real) or
            (allcaps(copy(toi.alias,1,length(alias)))=alias)) then
            s:=#3#9+'<'+#3#5+cstr(i+1)+#3#9+'>'
          else
            s:=#3#7+'('+#3#5+cstr(i+1)+#3#7+')';
        end;

        for j:=1 to 6 do pdt[j]:=mintab[getmixnum(cn)].msgdate[j];
        pdt2dt(pdt,dt);
        s:=#3#1+mrn(s,8)+#3#3+' '+mrn(cstr(dt.month),2)+'/'+
           tch('0',dt.day)+'/'+copy(tch('0',dt.year),3,2)+' - ';

        if (isnew(cn)) then begin
          delete(s,1,3);
          s:=#3#8+'*'+s;
        end;
        if (miunvalidated in mintab[getmixnum(cn)].msgindexstat) then begin
          if (mso) then begin
            delete(s,1,4);
            s:=#3#8+'NV'+s;
          end else
            s:=s+#3#8+'<<Unvalidated>>';
        end;
        if ((not (miunvalidated in mintab[getmixnum(cn)].msgindexstat)) or
            (mso)) then s:=s+mheader.title;

        if (miallowmci in mintab[getmixnum(cn)].msgindexstat) then sprint(s)
          else printacr(s,abort,next);

        wkey(abort,next);
        inc(numdone);
        inc(cn);
      end;
    end;
    dec(cn);
    nl;
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

begin
  askpost:=FALSE; contlist:=FALSE; donescan:=FALSE; hadunval:=FALSE;
  zup:=FALSE;

  while ((not donescan) and (not hangup)) do begin
    getm:=-1;
    if (ms=msshowt) then begin stitles; ms:=msreadp; end;
    if (ms=msreadp) then begin
      msg_on:=cn+1;
      cbounds;
      ensureloaded(cn);

      if ((contlist) and (not abort)) then
        if (cn=himsg) then abort:=TRUE;

      if ((not contlist) or (abort)) then begin
        if (contlist) then begin
          contlist:=FALSE;
          nl; print('Continuous message listing Off'); nl;
        end;
        sprompt(fstring.scanmessage);
        scaninput(inp,'ABCDEHMPQRTVWXZ-*!&?');
      end else
        inp:='';

      getm:=-1; cmd:=#0;

      if (inp='') then getm:=cn+1 else begin
        getm:=value(inp)-1;
        if (getm>-1) then
          if (st=stnewscan) then st:=stscan;
      end;

      if ((getm=-1) and (inp<>'')) then cmd:=inp[1];

      case cmd of
        'R':getm:=cn;
        '-':begin
              getm:=cn-1;
              if (getm=-1) then begin
                nl; sprint('Already at the first message.'); nl;
              end;
              if (st=stnewscan) then st:=stscan;
            end;
      end;
      if ((getm=-1) and (cmd<>#0)) then
        case cmd of
          '?':begin
                nl;
                sprint('<^3CR^1>Next message            ^3#^1:Message to read');
                sprint('(^3-^1)Prev. message            (^3C^1)ontinuous listing');
                nl;
                sprint('(^3A^1)uto-reply (pub/priv)     (^3B^1)Next board in NewScan');
                sprint('(^3P^1)ost public               (^3H^1)igh message pointer');
                sprint('(^3R^1)e-read                   (^3T^1)itles');
                sprint('(^3W^1)rite public reply        (^3Z^1)Toggle NewScan of this base');
                nl;
                s:='(^5E^1)dit message (owner only)';
                if (mso) then
                  s:=s+' (^5D^1)elete message (SysOp only)';
                sprint(s);
                if (mso) then begin
                  sprint('(^5V^1)alidation toggle         (^5M^1)ove msg to other base');
                  sprint('(^5X^1)tract message to file    (^5!^1)Toggle permanence');
                  if (cso) then begin
                    s:='(^7*^1)Toggle anonymous';
                    if (memboard.mbtype<>0) then s:=s+'         (^7&^1)Toggle scanned/outbound';
                    sprint(s);
                  end;
                  nl;
                end;
                sprint('(^3Q^1)uit');
                nl;
              end;
          'A':begin
                nl;
                if pynq('Is this to be a private reply? ') then autoreply
                  else pubreply(cn);
              end;
          'B':donescan:=TRUE;
          'C':begin
                contlist:=TRUE; abort:=FALSE;
                nl; print('Continuous message listing On'); nl;
              end;
          'D':if (mipermanent in mintab[getmixnum(cn)].msgindexstat) then begin
                nl; print('This is a permanent message.'); nl;
              end else begin
                loadmhead(cn,mheader);
                if ((mso) and (cn>=0) and (cn<=himsg)) then begin
                  delmail(cn);
                  nl;
                  if (miexist in mintab[getmixnum(cn)].msgindexstat) then begin
                    print('Undeleted message.');
                    sysoplog('* Undeleted "'+mheader.title+'"');
                  end else begin
                    print('Deleted message.');
                    sysoplog('* Deleted "'+mheader.title+'"');
                  end;
                  nl;
                end else begin
                  nl; print('Sorry... can''t delete that!'); nl;
                end;

                if (cn>himsg) then cn:=himsg;
                if (himsg<=0) then begin donescan:=TRUE; askpost:=TRUE; end;
              end;
          'E':if ((mso) and (lastname<>'')) then
                editmessage(cn)
              else begin
                loadmhead(cn,mheader);
                if ((mheader.fromi.usernum=usernum) and
                  (allcaps(mheader.fromi.real)=
                  allcaps(thisuser.realname))) then
                  editmessage(cn)
                else begin
                  nl;
                  print('You didn''t post this message!');
                  nl;
                end;
              end;
          'H':begin
                nl;
                i:=cn;
                print('Highest-read pointer for this base set to message #'+
                      cstr(i+1)+'.');
                nl;
                for i:=1 to 6 do
                  zscanr.mhiread[board][i]:=mintab[getmixnum(cn)].msgdate[i];
                savezscanr;
              end;
          'M':if (mso) then movemsg(cn);
          'P':begin post(-1,mheader.fromi); nl; end;
          'Q':begin quit:=TRUE; donescan:=TRUE; end;
          'T':ms:=msshowt;
          'V':if (mso) then begin
                loadmhead(cn,mheader); mixr:=mintab[getmixnum(cn)];
                if (miunvalidated in mixr.msgindexstat) then begin
                  nl; print('Message validated.'); nl;
                  mixr.msgindexstat:=mixr.msgindexstat-[miunvalidated];
                  sysoplog('* Validated "'+mheader.title+'"');
                end else begin
                  nl; print('Message unvalidated.'); nl;
                  mixr.msgindexstat:=mixr.msgindexstat+[miunvalidated];
                  sysoplog('* Unvalidated "'+mheader.title+'"');
                end;
                savemix(mixr,cn);
              end;
          'W':pubreply(cn);
          'X':if (mso) then begin
                nl;
                prt('Extract filename? (default="EXT.TXT") : ');
                input(s,40);
                if (s='') then s:='EXT.TXT';
                if pynq('Are you sure? ') then begin
                  b:=pynq('Strip color codes from output? ');

                  loadmhead(cn,mheader);

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
          'Z':begin
                nl;
                sprompt(#3#5+memboard.name+#3#3);
                if (board in zscanr.mzscan) then begin
                  zscanr.mzscan:=zscanr.mzscan-[board];
                  sprint(' will NOT be scanned in future NewScans.');
                  sysoplog('* Took "'+#3#5+memboard.name+#3#1+'" out of NewScan');
                end else begin
                  zscanr.mzscan:=zscanr.mzscan+[board];
                  sprint(' WILL be scanned in future NewScans.');
                  sysoplog('* Put "'+#3#5+memboard.name+#3#1+'" back in NewScan');
                end;
                nl;
                savezscanr;
              end;
          '!':if (mso) then begin
                nl;
                loadmhead(cn,mheader); mixr:=mintab[getmixnum(cn)];
                if (mipermanent in mixr.msgindexstat) then begin
                  mixr.msgindexstat:=mixr.msgindexstat-[mipermanent];
                  print('Message is no longer permanent.');
                  sysoplog('* "'+mheader.title+'" made unpermanent');
                end else begin
                  mixr.msgindexstat:=mixr.msgindexstat+[mipermanent];
                  print('Message is now permanent.');
                  sysoplog('* "'+mheader.title+'" made permanent');
                end;
                savemix(mixr,cn);
                nl;
              end;
          '*':if (cso) then begin
                nl;
                j:=getmixnum(cn); loadmhead(j,mheader);
                if (mheader.fromi.anon in [1,2]) then
                  mheader.fromi.anon:=0
                else begin
                  i:=mheader.fromi.usernum;
                  ufo:=(filerec(uf).mode<>fmclosed);
                  if (not ufo) then reset(uf);
                  if ((i>=1) and (i<=filesize(uf)-1)) then begin
                    seek(uf,i); read(uf,u);
                    b:=aacs1(u,i,systat.csop);
                  end else
                    b:=FALSE;
                  if (not ufo) then close(uf);
                  if (b) then mheader.fromi.anon:=2 else mheader.fromi.anon:=1;
                end;
                seek(brdf,mintab[j].hdrptr);
                savemhead(mheader);
                if (mheader.fromi.anon=0) then begin
                  print('Message is no longer anonymous.');
                  sysoplog('* "'+mheader.title+'" made non-anonymous');
                end else begin
                  print('Message is now anonymous.');
                  sysoplog('* "'+mheader.title+'" made anonymous');
                end;
                nl;
              end;
          '&':if ((cso) and (memboard.mbtype<>0)) then begin
                nl;
                loadmhead(cn,mheader); mixr:=mintab[getmixnum(cn)];
                if (miscanned in mixr.msgindexstat) then begin
                  mixr.msgindexstat:=mixr.msgindexstat-[miscanned];
                  print('Message is no longer marked as scanned.');
                  sysoplog('* "'+mheader.title+'" not marked as scanned');
                end else begin
                  mixr.msgindexstat:=mixr.msgindexstat+[miscanned];
                  print('Message is now marked as "sent".');
                  sysoplog('* "'+mheader.title+'" marked as scanned');
                end;
                savemix(mixr,cn);
                nl;
              end;
        end;
    end;

    if (getm<>-1) then cn:=getm;
    cbounds;
    if (wasout) then
      if (not contlist) then begin
        donescan:=TRUE;
        if (ms=msreadp) then askpost:=TRUE;
      end else
        contlist:=FALSE;

    if (not donescan) then begin
      if (getm<>-1) then ms:=msreadm;
      if (ms=msreadm) then begin
        if (contlist) then next:=TRUE;
        if ((thisuser.clsmsg=1) and (not contlist)) then cls;
        if (miunvalidated in mintab[getmixnum(cn)].msgindexstat) then
          hadunval:=TRUE;
        readmsg(1,cn,cn+1,himsg+1,abort,next);
        updateptr(cn,zup);
        for i:=1 to 6 do lastdate[i]:=mintab[getmixnum(cn)].msgdate[i];
        if (not next) then ms:=msreadp else inc(cn);
        inc(mread);
      end;
    end;
  end;

  if ((hadunval) and (mso)) then begin
    nl;
    if pynq(^G'Validate messages here? ') then
      for i:=0 to himsg do begin
        ensureloaded(i); mixr:=mintab[getmixnum(i)];
        if (miunvalidated in mixr.msgindexstat) then begin
          mixr.msgindexstat:=mixr.msgindexstat-[miunvalidated];
          savemix(mixr,i);
        end;
      end;
  end;
  if ((askpost) and (aacs(memboard.postacs)) and
     (not (rpost in thisuser.ac)) and (ptoday<systat.maxpubpost)) then begin
    nl;
    if pynq('Post on '+#3#5+memboard.name+#3#7+'? ') then
      post(-1,mheader.fromi);
  end;
  if (zup) then savezscanr;
end;

procedure scanmessages;
var cn:word;
    s:string;
    i:integer;
    c:char;
    quit:boolean;
begin
  initbrd(board);  { loads memboard }
  nl;
  if (himsg<>-1) then begin
    sprint(cstr(himsg+1)+' msgs on '+#3#5+memboard.name+#3#1+'.');
    prt('Start listing at (Q=Quit)? '); input(s,20);
    i:=value(s)-1; cn:=0;
    if (i<0) then i:=0 else
      if (i<=himsg) then cn:=i;
    if (s<>'') then c:=s[1] else c:=^M;
    if (c<>'Q') then doscan(quit,cn,stscan,msshowt);
  end else
    sprint('No messages on '+#3#5+memboard.name+#3#1+'.');
  closebrd;
end;

procedure qscan(b:integer; var quit:boolean);
var cn:word;
    oldboard,savlil,i:integer;
    abort,next:boolean;
begin
  oldboard:=board;
  if (not quit) then begin
    if (board<>b) then changeboard(b);
    if (board=b) then begin
      nl;
      initbrd(board);
      lil:=0; sprompt(#3#3+fstring.newscan1);
      if (himsg<>-1) then begin
        cn:=0;
        while ((not isnew(cn)) and (cn<=himsg)) do inc(cn);
        if ((cn<=himsg) and (isnew(cn))) then doscan(quit,cn,stnewscan,msreadm)
          else quit:=FALSE;
      end;
      closebrd;
      if (not quit) then begin
        lil:=0;
        sprompt(fstring.newscan2);
      end;
    end;
    wkey(quit,next);
  end;
  board:=oldboard;
end;

procedure gnscan;
var bb,oldboard:integer;
    quit:boolean;
begin
  sysoplog('NewScan of message bases');
  oldboard:=board;
  nl; sprint(#3#5+')[ NewScan All ](');
  bb:=1; quit:=FALSE;
  repeat
    if (bb in zscanr.mzscan) then qscan(bb,quit);
    inc(bb);
  until ((bb>numboards) or (quit) or (hangup));
  nl; sprint(#3#5+')[ NewScan Done ](');
  board:=oldboard;
  initbrd(board);
end;

procedure nscan(mstr:string);
var abort,next:boolean;
begin
  abort:=FALSE; next:=FALSE;
  if (mstr='C') then qscan(board,next)
  else if (mstr='G') then gnscan
  else if (value(mstr)<>0) then qscan(value(mstr),next)
  else begin
    nl;
    if pynq('Global NewScan? ') then gnscan else qscan(board,next);
  end;
end;

end.
