{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit file8;

interface

uses
  crt,dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  myio,
  file0, file6, file7,
  execbat,
  common;

procedure ymbadd(fname:astr);
procedure send1(fn:astr; var dok,kabort:boolean);
procedure receive1(fn:astr; resumefile:boolean; var dok,kabort,addbatch:boolean);

implementation

procedure abeep;
var a,b,c,i,j:integer;
begin
  for j:=1 to 3 do begin
    for i:=1 to 3 do begin
      a:=i*500;
      b:=a;
      while (b>a-300) do begin
        sound(b);
        dec(b,50);
        c:=a+1000;
        while (c>a+700) do begin
          sound(c); dec(c,50);
          delay(2);
        end;
      end;
    end;
    delay(50);
    nosound;
  end;
end;

function checkfileratio:integer;
var i,r,t:real;
    j:integer;
    badratio:boolean;
begin
  t:=thisuser.dk;
  if (numbatchfiles<>0) then
    for j:=1 to numbatchfiles do begin
      loaduboard(batch[j].section);
      if (not (fbnoratio in memuboard.fbstat)) then
        t:=t+(batch[j].blks div 8);
    end;
  badratio:=FALSE;
  r:=(t+0.001)/(thisuser.uk+0.001);
  if (r>systat.dlkratio[thisuser.sl]) then badratio:=TRUE;
  i:=(thisuser.downloads+numbatchfiles+0.001)/(thisuser.uploads+0.001);
  if (i>systat.dlratio[thisuser.sl]) then badratio:=TRUE;
  if ((aacs(systat.nodlratio)) or (fnodlratio in thisuser.ac)) then
    badratio:=FALSE;
  if (not systat.uldlratio) then badratio:=FALSE;
  checkfileratio:=0;
  if (badratio) then
    if (numbatchfiles=0) then checkfileratio:=1 else checkfileratio:=2;
  loaduboard(fileboard);
  if (fbnoratio in memuboard.fbstat) then checkfileratio:=0;
end;

procedure ymbadd(fname:astr);
var t1,t2:real;
    f:file of byte;
    ff:ulfrec;
    dt:datetimerec;
    sof:longint;
    ior:word;
    slrn,rn,pl,fblks:integer;
    slfn:astr;
    ffo:boolean;
begin
  ffo:=(filerec(ulff).mode<>fmclosed);
  nl;
  fname:=sqoutsp(fname);
  if (exist(fname)) then begin
    assign(f,fname); reset(f);
    sof:=filesize(f);
    fblks:=trunc((sof+127.0)/128.0);
    t1:=rte*fblks;
    close(f);
    t2:=batchtime+t1;
    if (t2>nsl) then print('Not enough time left in queue.')
    else
    if (numbatchfiles=20) then print('Batch queue full.')
    else begin
      inc(numbatchfiles);
      with batch[numbatchfiles] do begin
        if (fileboard<>-1) then begin
          slrn:=lrn; slfn:=lfn;
          if ffo then close(ulff);
          recno(stripname(fname),pl,rn);
          seek(ulff,rn); read(ulff,ff);
          close(ulff);
          if ffo then fiscan(pl);
          lrn:=slrn; lfn:=slfn;
          pts:=ff.filepoints;
          blks:=ff.blocks;
        end else begin
          pts:=unlisted_filepoints;
          blks:=fblks;
        end;

        fn:=sqoutsp(fname);
        tt:=t1;
        section:=fileboard;
        batchtime:=t2;

        sysoplog('Added '+stripname(fn)+' to batch queue.');
        sprint(fstring.batchadd);
        r2dt(batchtime,dt);
        print('Batch - Files: '+cstr(numbatchfiles)+'  Time: '+longtim(dt));
      end;
    end;
  end else
    print('File doesn''t exist');
end;

procedure addtologupdown;
var s:astr;
begin
  s:='  ULs: '+cstr(trunc(thisuser.uk))+'k in '+cstr(thisuser.uploads)+' file';
  if thisuser.uploads<>1 then s:=s+'s';
  s:=s+'  -  DLs: '+cstr(trunc(thisuser.dk))+'k in '+cstr(thisuser.downloads)+' file';
  if thisuser.downloads<>1 then s:=s+'s';
  sysoplog(s);
end;

procedure send1(fn:astr; var dok,kabort:boolean);
var f:text;
    ff:file;
    f1:ulfrec;
    nfn,cp,slfn,s:astr;
    st:real;
    filsize:longint;
    dcode:word; { dos exit code }
    p,i,sx,sy,t,pl,rn,slrn,errlevel:integer;
    g,c:char;
    b,done1,foundit:boolean;
begin
  done1:=FALSE;
  reset(xf);
    repeat
      nl;
      sprompt('^4Protocol (^0?^4=^0list^4) : ^3'); mpkey(s);
      if (s='?') then begin
        nl;
        showprots(FALSE,TRUE,FALSE,FALSE);
      end else begin
        p:=findprot(s,FALSE,TRUE,FALSE,FALSE);
        if (p=-99) then print('Invalid entry.') else done1:=TRUE;
      end;
    until (done1) or (hangup);

  dok:=TRUE; kabort:=FALSE;
  if (-p in [1,2,3,4,12]) or (p in [1..200]) then
    case checkfileratio of
      1:begin
          nl;
          sprint(fstring.unbalance);
          nl;
          prompt('You have DLed: '+cstr(trunc(thisuser.dk))+'k in '+cstr(thisuser.downloads)+' file');
          if thisuser.downloads<>1 then print('s') else nl;
          prompt('You have ULed: '+cstr(trunc(thisuser.uk))+'k in '+cstr(thisuser.uploads)+' file');
          if thisuser.uploads<>1 then print('s') else nl;
          nl;
          print('  1 upload for every '+cstr(systat.dlratio[thisuser.sl])+' downloads must be maintained.');
          print('  1k must be uploaded for every '+cstr(systat.dlkratio[thisuser.sl])+'k downloaded.');
          sysoplog('Tried to download while ratio out of balance:');
          addtologupdown;
          p:=-11;
        end;
      2:begin
          nl;
          sprint(fstring.unbalance);
          nl;
          print('Assuming you download the files already in the batch queue,');
          print('your upload/download ratio would be out of balance.');
          sysoplog('Tried to add to batch queue while ratio out of balance:');
          addtologupdown;
          p:=-11;
        end;
    end;
  if (p>=0) then begin seek(xf,p); read(xf,protocol); end;
  close(xf);
  lastprot:=p;
  case p of
   -12:ymbadd(fn);
   -11:;
   -10:begin dok:=FALSE; kabort:=TRUE; end;
(*   -4:if (incom) then send(TRUE,TRUE,fn,dok,kabort,FALSE,rte);
   -3:if (incom) then send(FALSE,TRUE,fn,dok,kabort,FALSE,rte);
   -2:if (incom) then send(FALSE,FALSE,fn,dok,kabort,FALSE,rte);*)
   -1:if (not trm) then sendascii(fn);
(*   -2:if (not trm) then begin
        assign(f,fn);
        {$I-} reset(f); {$I+}
        if (ioresult<>0) then print('File not found.')
        else begin
          kabort:=FALSE;
          clrscr;
          sx:=wherex; sy:=wherey;
          window(1,25,80,25);
          textcolor(11); textbackground(1);
          gotoxy(1,1);
          for t:=1 to 80 do write(' ');
          gotoxy(1,1);
          write('Sending ASCII File '+fn+' -- Please Wait');
          textcolor(7); textbackground(0);
          window(1,1,80,24);
          gotoxy(sx,sy);
          repeat
            read(f,g);
            o(g); write(g);
          until (eof(f)) or (kabort);
          close(f);
        end;
      end;*)
  else
      if (incom) then begin
        cp:=bproline1(protocol.dlcmd);
        bproline(cp,sqoutsp(fn));

        if (useron) then star('Send ready.');
        if (useron) then shel(caps(thisuser.name)+' is downloading!') else
                       shel('Sending file(s)...');
        b:=systat.swapshell; systat.swapshell:=FALSE;
        pexecbatch(FALSE,'tgtemp2.bat','tgtest2.$$$',start_dir,cp,errlevel);
        systat.swapshell:=b;
        shel2;

        foundit:=FALSE; i:=0;
        while ((i<6) and (not foundit)) do begin
          inc(i);
          if (value(protocol.dlcode[i])=errlevel) then foundit:=TRUE;
        end;

        dok:=TRUE;
        if ((foundit) and (not (xbxferokcode in protocol.xbstat))) then dok:=FALSE;
        if ((not foundit) and (xbxferokcode in protocol.xbstat)) then dok:=FALSE;
      end;
  end;
  if (trm) then begin incom:=FALSE; outcom:=FALSE; end;
  if (not useron) and (not kabort) then begin
    cursoron(FALSE);
    setwindow(wind,36,8,80,12,4,0,1);
    gotoxy(3,2); tc(14);
    if dok then write('Transfer successful.') else
                write('Transfer unsuccessful.');
    st:=timer;
    while (not keypressed) and (tcheck(st,5)) do abeep;
    if keypressed then c:=readkey;
    removewindow(wind);
    cursoron(TRUE);
    incom:=FALSE; outcom:=FALSE;
  end;
end;

procedure receive1(fn:astr; resumefile:boolean; var dok,kabort,addbatch:boolean);
var cp,nfn,s:astr;
    st:real;
    filsize:longint;
    p,i,t,fno,sx,sy,nof,errlevel:integer;
    c:char;
    b,done1,foundit:boolean;
begin
  done1:=FALSE;
  reset(xf);
  repeat
    nl;
    sprompt('^4Protocol (^0?^4=^0list^4) : ^3'); mpkey(s);
    if (s='?') then begin
      nl;
      showprots(TRUE,FALSE,FALSE,resumefile);
    end else begin
      p:=findprot(s,TRUE,FALSE,FALSE,resumefile);
      if (p=-99) then print('Invalid entry.') else done1:=TRUE;
    end;
  until (done1) or (hangup);

  if (not useron) then begin incom:=TRUE; outcom:=TRUE; end;
  dok:=TRUE; kabort:=FALSE;
  if (p>=0) then begin seek(xf,p); read(xf,protocol); end;
  close(xf);
  case p of
   -12:addbatch:=TRUE;
   -11,-10:begin dok:=FALSE; kabort:=TRUE; end;
   -1:if (not trm) then recvascii(fn,dok,rte);
  else
      if (incom) then begin
        cp:=bproline1(protocol.ulcmd);
        bproline(cp,sqoutsp(fn));

        if (useron) then star('Receive ready.');
        if (useron) then shel(caps(thisuser.name)+' is uploading!') else
                       shel('Receiving file(s)...');
        b:=systat.swapshell; systat.swapshell:=FALSE;
        pexecbatch(FALSE,'tgtemp2.bat','tgtest2.$$$',start_dir,cp,errlevel);
        systat.swapshell:=b;
        shel2;

        foundit:=FALSE; i:=0;
        while ((i<6) and (not foundit)) do begin
          inc(i);
          if (value(protocol.ulcode[i])=errlevel) then foundit:=TRUE;
        end;

        dok:=TRUE;
        if ((foundit) and (not (xbxferokcode in protocol.xbstat))) then dok:=FALSE;
        if ((not foundit) and (xbxferokcode in protocol.xbstat)) then dok:=FALSE;
      end;
  end;
  if (not useron) and (not kabort) then begin
    cursoron(FALSE);
    setwindow(wind,36,8,80,12,4,0,1);
    gotoxy(3,2); tc(14);
    if (dok) then write('Transfer successful.') else
      write('Transfer unsuccessful.');
    st:=timer;
    while (not keypressed) and (tcheck(st,5)) do abeep;
    if (keypressed) then c:=readkey;
    removewindow(wind);
    cursoron(TRUE);
    incom:=FALSE; outcom:=FALSE;
  end;
end;

end.
