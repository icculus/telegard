{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit mail3;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common, timejunk, mail0;

function what00(b:byte; s:string):string;
procedure readmsg(style:byte; anum,mnum,tnum:longint; var abort,next:boolean);

implementation

function what00(b:byte; s:string):string;
begin
  if (b=0) then
    s:=caps(s)
  else
    case b of
      0:s:=caps(s);
      1,
      2:s:='**Anonymous**';
      3:s:='"Abby"';
      4:s:='"Problemed Person"';
      5:s:=caps(s);
    else
        s:=allcaps(s);
    end;
  what00:=s;
end;

{ anum=actual, mnum=M#/t#, tnum=m#/T# }
procedure readmsg(style:byte; anum,mnum,tnum:longint; var abort,next:boolean);
var mhead:mheaderrec;
    mixr:msgindexrec;
    pdt:packdatetime;
    dt:ldatetimerec;
    s,s1:string;
    brdsig,lng,maxm,totload:longint;
    i,numread:word;
    done,pub,seeanon,usemci,usereal,isfido:boolean;

  procedure getout;
  begin
    gotlastmheader:=TRUE;
    lastmheader:=mhead;
  end;

  function tnn(lng:longint):string;
  var s:string;
  begin
    if (lng>100) then lng:=lng mod 100;  { ex: 1989 --> 89 }
    s:=cstr(lng); while (length(s)<2) do s:='0'+s;
    tnn:=s;
  end;

begin
  usereal:=(mbrealname in memboard.mbstat);
  isfido:=(memboard.mbtype<>0);

  {rcg1117 removed mixr...}
  {with mhead,mixr do begin}

  with mhead do begin

    loadmhead(anum,mhead);
    ensureloaded(anum);
    mixr:=mintab[getmixnum(anum)];
    usemci:=(miallowmci in mixr.msgindexstat);

    loadboard(board);
    wasyourmsg:=(fromi.usernum=usernum);
    pub:=(bread<>-1);
    if (pub) then seeanon:=aacs(systat.anonpubread)
      else seeanon:=aacs(systat.anonprivread);

    if (mhead.fromi.anon=2) then seeanon:=aacs(systat.csop);

    abort:=FALSE;
    next:=FALSE;
    printacr('',abort,next);

    s:='Number: '+#3#3+cstr(mnum)+'/'+cstr(tnum);
    printacr(s,abort,next);

    s:='';
    if (not (miexist in mixr.msgindexstat)) then begin
      s:='Status: '+#3#8+'Deleted';
      if ((not mso) and (not wasyourmsg)) then begin
        printacr(s,abort,next);
        getout;
        exit;
      end;
    end;

    if (miunvalidated in mixr.msgindexstat) then begin
      if (s='') then s:='Status:';
      s:=s+#3#7+' Not Validated';
      if ((not mso) and (not wasyourmsg)) then begin
        printacr(s,abort,next);
        getout;
        exit;
      end;
    end;

    {rcg1117 added mixr...}
    {if ((pub) and (mipermanent in msgindexstat)) then begin}

    if ((pub) and (mipermanent in mixr.msgindexstat)) then begin
      if (s='') then s:='Status:';
      s:=s+#3#3+' Permanent';
    end;

    if (s<>'') then printacr(s,abort,next);

    {rcg1117 added mixr...}
    {if ((fromi.anon=0) or (seeanon)) then s:=pdt2dat(@msgdate,msgdowk)}

    if ((fromi.anon=0) or (seeanon)) then s:=pdt2dat(@mixr.msgdate,mixr.msgdowk)
      else s:='***Unknown***';
    s:='Date  : '+#3#3+s;

    if (style=4) then begin
      s:=s+#3#1+'  ('+aonoff(pub,'Posted: ','Sent: ')+#3#9;
      for i:=1 to 6 do
        pdt[i]:=mixr.msgdate[i];
      pdt2dt(pdt,dt);
      s1:=tnn(dt.month)+'/'+tnn(dt.day)+'/'+tnn(dt.year);
      i:=daynum(date)-daynum(s1);
      s:=s+cstr(i)+' day'+aonoff((i=1),'','s')+' ago'+#3#1+')';
    end;

    printacr(s,abort,next);
    if (origindate<>'') then
      if ((fromi.anon=0) or (seeanon)) then
        printacr('Origin: '+#3#3+origindate,abort,next);

    s1:=fromi.as;
    if (pub) then begin
      if (usereal) then begin
        s1:=fromi.real;
        if (not isfido) then s1:=s1+' #'+cstr(fromi.usernum);
      end;
    end;
    s:='From  : '+#3#5+caps(what00(fromi.anon,s1));
    if (not abort) then sprint(s);

    if ((seeanon) and (fromi.anon<>0) and (toi.anon=0) and (not isfido)) then begin
      s1:='(Real : '+#3#5;
      if (usereal) then s1:=s1+caps(fromi.real)
        else s1:=s1+caps(fromi.alias);
      s1:=s1+' #'+cstr(fromi.usernum)+#3#1+')';
      printacr(s1,abort,next);
    end;

    if (style<>2) then begin
      s1:=toi.as;
      if (pub) then begin
        if ((toi.as='') and (isfido)) then s1:='All' else begin
          if ((usereal) and (toi.real<>'')) then begin
            s1:=allcaps(toi.real);
            if (not isfido) then s1:=s1+' #'+cstr(toi.usernum);
          end;
        end;
      end;
      if (s1<>'') then begin
        s:='To    : '+#3#5+caps(what00(toi.anon,s1));
        if (not usemci) then printacr(s,abort,next) else begin
          sprint(s);
          wkey(abort,next);
        end;
      end;
      if ((seeanon) and (toi.anon<>0) and (not isfido)) then begin
        if (fromi.anon=0) then begin
          s1:='(The user really is : '+#3#5;
          if (usereal) then s1:=s1+caps(toi.real)
            else s1:=s1+caps(toi.alias);
          s1:=s1+' #'+cstr(toi.usernum)+#3#1+')';
          printacr(s1,abort,next);
        end else begin
          s1:='(The user really is : '+#3#5;
          if (usereal) then s1:=s1+caps(fromi.real)
            else s1:=s1+caps(fromi.alias);
          s1:=s1+' --> ';
          if (usereal) then s1:=s1+caps(toi.real)
            else s1:=s1+caps(toi.alias);
          s1:=s1+#3#1+')';
          printacr(s1,abort,next);
        end;
      end;
    end;

    if (not usemci) then
      printacr('Subject : '+#3#3+title,abort,next)
    else begin
      sprint('Subject : '+#3#3+title);
      wkey(abort,next);
    end;

    if (mixr.isreplyto<>65535) then
      printacr('     >> '+#3#3+'Reply to message '+#3#5+cstr(mixr.isreplyto+1),
        abort,next);
    i:=mixr.numreplys;
    if (i<>0) then
      printacr('     >> '+#3#3+'This message has '+#3#5+cstr(i)+#3#3+' repl'+
        aonoff((i=1),'y','ies'),abort,next);
    printacr('',abort,next);

    if ((fromi.anon=0) or (seeanon)) then
      lastname:=caps(what00(fromi.anon,fromi.as))
    else
      lastname:='';

    if (not abort) then begin
      reading_a_msg:=TRUE;

      {rcg1117 added mixr...}
      {read_with_mci:=(miallowmci in msgindexstat);}
      read_with_mci:=(miallowmci in mixr.msgindexstat);

      totload:=0;
      abort:=FALSE;
      next:=FALSE;
      seek(brdf,mhead.msgptr);
      repeat
        blockreadstr2(brdf,s);
        inc(totload,length(s)+2);
        printacr(s,abort,next);
      until ((totload>=msglength) or (abort));
      read_with_mci:=FALSE;
      reading_a_msg:=FALSE;
      printacr('',abort,next);
      if (dosansion) then redrawforansi;
    end;
  end;
  getout;
end;

end.
