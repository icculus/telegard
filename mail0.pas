{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit mail0;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common, timejunk;

const
  _brd_opened:boolean=FALSE;  { has brdf been opened yet? }
  oldnummsgs:integer=0;       { old number of messages }
  gotlastmheader:boolean=FALSE;

type
  pinforec=record
    xbrdfnopen:string[160];
    xbread,xmintabloaded:longint;
    xopen:boolean;
  end;

var
  brdfnopen:string;           { what *.BRD filename is open }
  lastmheader:mheaderrec;
  wasyourmsg:boolean;

procedure blockwritestr2(var f:file; s:string);
procedure blockreadstr2(var f:file; var s:string);
function getmixnum(x:word):word;
function getmintab(x:word):word;
procedure loadmintab(x:word);
procedure ensureloaded(x:word);
procedure loadmhead1(var brdf:file; x:word; var mhead:mheaderrec);
procedure savemhead1(var brdf:file; mhead:mheaderrec);
procedure loadmhead(x:word; var mhead:mheaderrec);
procedure savemhead(mhead:mheaderrec);
procedure savemix(mixr:msgindexrec; x:word);
procedure newmix(mixr:msgindexrec);
procedure outmessagetext(fn:string; var mhead:mheaderrec; eraseit:boolean);
procedure findhimsg;
procedure initbrd(x:integer);
procedure closebrd;
function forwardm(n:integer):integer;
function moremail(u:userrec; un,what:word):boolean;
procedure savepinfo(var x:pinforec);
procedure loadpinfo(x:pinforec);
procedure delmail(x:integer);
function rmail(x:integer):string;   { bread must = -1 }

implementation

procedure blockwritestr2(var f:file; s:string);
var bb:byte;
begin
  bb:=$FF;
  blockwrite(f,bb,1);
  blockwrite(f,s[0],1);
  blockwrite(f,s[1],ord(s[0]));
end;

procedure blockreadstr2(var f:file; var s:string);
begin
  blockread(f,s[0],1);    { filler-chr }
  if (ord(s[0])<>$FF) then exit;
  blockread(f,s[0],1);
  blockread(f,s[1],ord(s[0]));
end;

function getmixnum(x:word):word;
begin
  getmixnum:=x mod 100;
end;

function getmintab(x:word):word;
begin
  getmintab:=x div 100;
end;

procedure loadmintab(x:word);
var lng:longint;
    numread:word;
    i,j:integer;
begin
  lng:=x*100;   (* stupid *#@$(@($#*($ TP typecasting... *)
  while ((lng>=filesize(mixf)) and (x>0)) do begin
    dec(x);
    lng:=x*100;
  end;

  mintaboffset:=x*100;
  seek(mixf,mintaboffset);
  blockread(mixf,mintab,100,numread);
  if (numread<>100) then begin
    for i:=numread to 99 do begin
      mintab[i].messagenum:=0;
      mintab[i].hdrptr:=-1;
      mintab[i].msgid:=memboard.lastmsgid;
      mintab[i].isreplytoid:=0;
      for j:=1 to 6 do mintab[i].msgdate[i]:=0;
      mintab[i].msgdowk:=0;
      mintab[i].msgindexstat:=[];
      mintab[i].isreplyto:=65535;
      mintab[i].numreplys:=0;
    end;
    seek(mixf,mintaboffset);
    blockwrite(mixf,mintab,100);  { fill remainder with garbage .. }
  end;
  mintabloaded:=x;
end;

procedure ensureloaded(x:word);
var i:word;
begin
  i:=getmintab(x);
  if (i<>mintabloaded) then loadmintab(i);
end;

procedure loadmhead1(var brdf:file; x:word; var mhead:mheaderrec);
begin
  blockread(brdf,mhead,sizeof(mheaderrec));
end;

{ caller must postition to correct place in brdf .... }
procedure savemhead1(var brdf:file; mhead:mheaderrec);
begin
  blockwrite(brdf,mhead,sizeof(mheaderrec));
end;

procedure loadmhead(x:word; var mhead:mheaderrec);
begin
  ensureloaded(x);
  seek(brdf,mintab[getmixnum(x)].hdrptr);
  loadmhead1(brdf,x,mhead);
end;

procedure savemhead(mhead:mheaderrec);
begin
  savemhead1(brdf,mhead);
end;

procedure savemix(mixr:msgindexrec; x:word);
begin
  loadmintab(getmintab(x));
  seek(mixf,mintaboffset+getmixnum(x));
  blockwrite(mixf,mixr,1);
  loadmintab(getmintab(x));
end;

procedure newmix(mixr:msgindexrec);
var lng:longint;
    i,j:integer;
begin
  if ((getmixnum(himsg+1)=0) and (himsg>-1)) then begin
    for i:=0 to 99 do begin
      mintab[i].messagenum:=0;
      mintab[i].hdrptr:=-1;
      mintab[i].msgid:=memboard.lastmsgid;
      mintab[i].isreplytoid:=0;
      for j:=1 to 6 do mintab[i].msgdate[i]:=0;
      mintab[i].msgdowk:=0;
      mintab[i].msgindexstat:=[];
      mintab[i].isreplyto:=65535;
      mintab[i].numreplys:=0;
    end;
    inc(himintab);
    seek(mixf,himintab*100); blockwrite(mixf,mintab[0],100);
  end;
  inc(himsg); savemix(mixr,himsg);
end;

procedure outmessagetext(fn:string; var mhead:mheaderrec; eraseit:boolean);
var t:text;
    f:file;
    s:string;
    lng:longint;
begin
  assign(t,fn);
  {$I-} reset(t); {$I+}
  if (ioresult<>0) then exit;
  lng:=filesize(brdf);
  seek(brdf,lng);
  mhead.msgptr:=lng+sizeof(mheaderrec);
  savemhead(mhead);

  while (not eof(t)) do begin
    readln(t,s);
    blockwritestr2(brdf,s);
  end;
  close(t);
  if (eraseit) then erase(t);
end;

procedure findhimsg;
var mixr:msgindexrec;
    lng:longint;
    numread:word;
begin
  himintab:=(filesize(mixf)-1) div 100;
  himsg:=himintab*100-1;
  seek(mixf,himsg+1);
  repeat
    lng:=himsg;
    blockread(mixf,mixr,1,numread);
    if ((numread=1) and (mixr.hdrptr<>-1)) then inc(himsg);
  until (lng=himsg);
end;

procedure initbrd(x:integer);    { x=-1 = e-mail }
var mixr:msgindexrec;
    fn:string;
    lng:longint;
    numread:word;
    i,j:integer;
begin
  closebrd;

  bread:=x;
  if (x=-1) then fn:='EMAIL' else begin
    loadboard(x);
    fn:=memboard.filename;
  end;
  fn:=allcaps(fn);
  brdfnopen:=fn;
  assign(mixf,systat.msgpath+fn+'.MIX');
  {$I-} reset(mixf,sizeof(mixr)); {$I+}
  if (ioresult<>0) then begin
    rewrite(mixf,sizeof(mixr));
    for i:=0 to 99 do begin
      mintab[i].messagenum:=0;
      mintab[i].hdrptr:=-1;
      mintab[i].msgid:=memboard.lastmsgid;
      mintab[i].isreplytoid:=0;
      for j:=1 to 6 do mintab[i].msgdate[i]:=0;
      mintab[i].msgdowk:=0;
      mintab[i].msgindexstat:=[];
      mintab[i].isreplyto:=65535;
      mintab[i].numreplys:=0;
    end;
    blockwrite(mixf,mintab[0],100);
  end;

  assign(brdf,systat.msgpath+fn+'.BRD');
  {$I-} reset(brdf,1); {$I+}
  if (ioresult<>0) then rewrite(brdf,1);

  findhimsg;
  loadmintab(himintab);

  _brd_opened:=TRUE;
  gotlastmheader:=FALSE;

end;

procedure closebrd;
begin
  if (_brd_opened) then begin
    if (filerec(brdf).mode<>fmclosed) then close(brdf);
    if (filerec(mixf).mode<>fmclosed) then close(mixf);
  end;
  filerec(brdf).mode:=fmclosed;
  filerec(mixf).mode:=fmclosed;
end;

{ this routine will find the user that user n is forwarding their mail to.
  it will also check to get around "circular forwarding", such as:
  5 -> 10 -> 15 -> 5 ... }
function forwardm(n:integer):integer;
var chk:array[1..1250] of byte;   { 1250 * 8 = 10000 users max }
    cur:integer;
    u:userrec;
    done:boolean;

  function chkval(i:integer):boolean;
  begin
    dec(i);
    chkval:=((chk[i div 8] and (1 shl (i mod 8)))<>0);
  end;

  procedure chkset(i:integer);
  var bb,bc:byte;
  begin
    dec(i);
    bb:=chk[i div 8]; bc:=(1 shl(i mod 8));
    if ((bb and bc)=0) then chk[i div 8]:=chk[i div 8]+bc;
  end;

begin
  for cur:=1 to 1250 do
    chk[cur]:=0;
  cur:=n;
  done:=FALSE;
  while not done do
    if (chkval(cur)) then begin
      done:=TRUE;
      cur:=0;
    end else
      if (cur<filesize(uf)) and (cur>0) then begin
        seek(uf,cur); read(uf,u);
        if (u.deleted) then begin
          done:=TRUE;
          cur:=0;
        end else begin
          if (u.forusr=0) then begin
            done:=TRUE;
          end else begin
            chkset(cur);
            cur:=u.forusr;
          end;
        end;
      end else begin
        done:=TRUE;
        cur:=0;
      end;
  forwardm:=cur;
end;

{
  1: user has too much mail waiting already
  2: user mailbox is closed
  3: user is deleted
  4: can't send mail to yourself! <idiot!>
}
function moremail(u:userrec; un,what:word):boolean;
begin
  moremail:=TRUE;
  case what of
    1:moremail:=(not (((aacs1(u,un,systat.csop)) and
        (u.waiting>=systat.csmaxwaiting)) or
        ((not aacs1(u,un,systat.csop)) and (u.waiting>=systat.maxwaiting))));
    2:moremail:=(not (nomail in u.ac));
    3:moremail:=(not (u.deleted));
    4:moremail:=(not ((un=usernum) and (not cso)));
  end;
end;

procedure savepinfo(var x:pinforec);
begin
  with x do begin
    xbread:=bread;
    xbrdfnopen:=brdfnopen;
    xopen:=FALSE;
    if (not _brd_opened) then xopen:=FALSE
      else if (filerec(mixf).mode<>fmclosed) then xopen:=TRUE;
  end;
end;

procedure loadpinfo(x:pinforec);
begin
  closebrd;
  with x do begin
    brdfnopen:=xbrdfnopen;
    if (xopen) then begin
      initbrd(xbread);
      loadmintab(0);
    end;
  end;
end;

{ toggles "existance" flag.  If normal, deletes it -- otherwise, undeletes }
procedure delmail(x:integer);
var mixr:msgindexrec;
begin
  ensureloaded(x);
  mixr:=mintab[getmixnum(x)];
  if (miexist in mixr.msgindexstat) then
    mixr.msgindexstat:=mixr.msgindexstat-[miexist]
  else
    mixr.msgindexstat:=mixr.msgindexstat+[miexist];
  savemix(mixr,x);
  ensureloaded(x);
end;

function rmail(x:integer):string;  { bread must = -1 }
var u:userrec;
    mheader:mheaderrec;
    i:integer;
    ufo:boolean;
begin
  loadmhead(x,mheader);
  with mheader do begin
    rmail:=caps(fromi.alias)+' #'+cstr(fromi.usernum);
    ufo:=(filerec(uf).mode<>fmclosed);
    if (not ufo) then reset(uf);
    if ((toi.usernum>=1) and (toi.usernum<=filesize(uf)-1)) then begin
      if (toi.usernum=usernum) then dec(thisuser.waiting);
      seek(uf,toi.usernum);
      read(uf,u);
      dec(u.waiting);
      seek(uf,toi.usernum);
      write(uf,u);
    end;
    if (not ufo) then close(uf);
  end;

  delmail(x);
  mailread:=TRUE;
end;

end.
