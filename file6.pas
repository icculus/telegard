{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit file6;

interface

uses
  crt,dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  file0, file1, file2, file4, file9,
  execbat,
  common;

procedure delbatch(n:integer);
procedure mpkey(var s:astr);
function bproline1(cline:astr):astr;
procedure bproline(var cline:astr; filespec:astr);
function okprot(prot:protrec; ul,dl,batch,resume:boolean):boolean;
procedure showprots(ul,dl,batch,resume:boolean);
function findprot(cs:astr; ul,dl,batch,resume:boolean):integer;
procedure batchdl;
procedure listbatchfiles;
procedure removebatchfiles;
procedure clearbatch;

implementation

procedure delbatch(n:integer);
var c:integer;
begin
  if ((n>=1) and (n<=numbatchfiles)) then begin
    batchtime:=batchtime-batch[n].tt;
    if (n<>numbatchfiles) then
      for c:=n to numbatchfiles-1 do batch[c]:=batch[c+1];
    dec(numbatchfiles);
  end;
end;

procedure mpkey(var s:astr);
var sfqarea,smqarea:boolean;
begin
  sfqarea:=fqarea; smqarea:=mqarea;
  fqarea:=FALSE; mqarea:=FALSE;

  mmkey(s);

  fqarea:=sfqarea; mqarea:=smqarea;
end;

function bproline2(cline:astr):astr;
var s:astr;
begin
  s:=substall(cline,'%C',start_dir);
  s:=substall(s,'%G',copy(systat.gfilepath,1,length(systat.gfilepath)-1));
  bproline2:=s;
end;

function bproline1(cline:astr):astr;
var s,s1:astr;
begin
  if ((not incom) and (not outcom)) then s1:=cstrl(modemr.waitbaud) else s1:=spd;
  s:=substall(cline,'%B',s1);
  s:=substall(s,'%L',bproline2(protocol.dlflist));
  s:=substall(s,'%P',cstr(modemr.comport));
  s:=substall(s,'%T',bproline2(protocol.templog));
  bproline1:=bproline2(s);
end;

procedure bproline(var cline:astr; filespec:astr);
const lastpos:integer=-1;
begin
  if (pos('%F',cline)<>0) then begin
    lastpos:=pos('%F',cline)+length(filespec);
    cline:=substall(cline,'%F',filespec);
  end else begin
    insert(' '+filespec,cline,lastpos);
    inc(lastpos,length(filespec)+1);
  end;
end;

function okprot(prot:protrec; ul,dl,batch,resume:boolean):boolean;
var s:astr;
begin
  okprot:=FALSE;
  with prot do begin
    if (ul) then s:=ulcmd else if (dl) then s:=dlcmd else s:='';
    if (s='NEXT') and ((ul) or (batch) or (resume)) then exit;
    if (s='BATCH') and ((batch) or (resume)) then exit;
    if (batch<>(xbisbatch in xbstat)) then exit;
    if (resume<>(xbisresume in xbstat)) then exit;
    if (not (xbactive in xbstat)) then exit;
    if (not aacs(acs)) then exit;
    if (s='') then exit;
  end;
  okprot:=TRUE;
end;

procedure showprots(ul,dl,batch,resume:boolean);
var s:astr;
    i:integer;
    abort,next:boolean;
begin
  nofile:=TRUE;
  if (resume) then printf('protres')
  else begin
    if (batch) and (ul) then printf('protbul');
    if (batch) and (dl) then printf('protbdl');
    if (not batch) and (ul) then printf('protsul');
    if (not batch) and (dl) then printf('protsdl');
  end;
  if (nofile) then begin
    seek(xf,0);
    abort:=FALSE; next:=FALSE; i:=0;
    while ((i<=filesize(xf)-1) and (not abort)) do begin
      read(xf,protocol);
      if (okprot(protocol,ul,dl,batch,resume)) then sprint(protocol.descr);
      if (not empty) then wkey(abort,next);
      inc(i);
    end;
  end;
end;

(* XF should be OPEN  --
   returns:
     (-1):Ascii   (xx):Xmodem   (xx):Xmodem-CRC   (xx):Ymodem
     (-10):Quit   (-11):Next    (-12):Batch       (-99):Invalid (or no access)
   else, the protocol #
*)
function findprot(cs:astr; ul,dl,batch,resume:boolean):integer;
var s:astr;
    i:integer;
    done:boolean;
begin
  findprot:=-99;
  if (cs='') then exit;
  seek(xf,0);
  done:=FALSE; i:=0;
  while ((i<=filesize(xf)-1) and (not done)) do begin
    read(xf,protocol);
    with protocol do
      if (cs=ckeys) then
        if (okprot(protocol,ul,dl,batch,resume)) then begin
          if (ul) then s:=ulcmd else if (dl) then s:=dlcmd else s:='';
          if (s='ASCII') then begin done:=TRUE; findprot:=-1; end
          else if (s='QUIT') then begin done:=TRUE; findprot:=-10; end
          else if (s='NEXT') then begin done:=TRUE; findprot:=-11; end
          else if (s='BATCH') then begin done:=TRUE; findprot:=-12; end
          else if (s<>'') then begin done:=TRUE; findprot:=i; end;
        end;
    inc(i);
  end;
end;

procedure batchdl;
var batfile,tfil:text;  {@4 file list file}
    xferstart,xferend,tooktime,batchtime1:datetimerec;
    nfn,snfn,s,s1,s2,i,logfile:astr;
    st,tott,tooktime1:real;
    tblks,tblks1,cps,lng:longint;
    tpts,tpts1,tnfils,tnfils1:integer;
    sx,sy,hua,n,p,toxfer,rcode:integer;
    c:char;
    swap,done1,dok,kabort,nomore,readlog:boolean;

  function tempfile(i:integer):astr;
  begin
    tempfile:='temp'+cstr(i)+'.$$$';
  end;

  procedure sprtcl(c:char; s:astr);
  var wnl:boolean;
  begin
    if copy(s,length(s),1)<>#0 then wnl:=TRUE else wnl:=FALSE;
    if not wnl then s:=copy(s,1,length(s)-1);
    sprompt('^3'+c+'^1) ^4'+s);
    if wnl then nl;
  end;

  procedure addnacc(i:integer; s:astr);
  var f:ulfrec;
      oldboard,pl,rn:integer;
  begin
    if (i<>-1) then begin
      oldboard:=fileboard; fileboard:=i;
      s:=sqoutsp(stripname(s));
      recno(s,pl,rn); {* opens ulff *}
      if rn<>0 then begin
        seek(ulff,rn); read(ulff,f);
        inc(f.nacc);
        seek(ulff,rn); write(ulff,f);
      end;
      fileboard:=oldboard;
      close(ulff);
    end;
  end;

  procedure chopoffspace(var s:astr);
  begin
    if (pos(' ',s)<>0) then s:=copy(s,1,pos(' ',s)-1);
  end;

  procedure figuresucc;
  var filestr,statstr:astr;
      foundit:boolean;

    function wasok:boolean;
    var i:integer;
        foundcode:boolean;
    begin
      foundcode:=FALSE;
      for i:=1 to 6 do
        if (protocol.dlcode[i]<>'') and
           (protocol.dlcode[i]=copy(statstr,1,length(protocol.dlcode[i]))) then
          foundcode:=TRUE;
      wasok:=FALSE;
      if ((foundcode) and (not (xbxferokcode in protocol.xbstat))) then exit;
      if ((not foundcode) and (xbxferokcode in protocol.xbstat)) then exit;
      wasok:=TRUE;
    end;

  begin
    readlog:=FALSE;
    if (protocol.templog<>'') then begin
      assign(batfile,bproline1(protocol.templog));
      {$I-} reset(batfile); {$I+}
      if (ioresult=0) then begin
        assign(tfil,bproline1(protocol.dloadlog));
        {$I-} append(tfil); {$I+}
        if (ioresult<>0) then rewrite(tfil);
        readlog:=TRUE;
        while (not eof(batfile)) do begin
          readln(batfile,s); writeln(tfil,s);
          filestr:=copy(s,protocol.logpf,length(s)-(protocol.logpf-1));
          statstr:=copy(s,protocol.logps,length(s)-(protocol.logps-1));
          chopoffspace(filestr);
          foundit:=FALSE; n:=0;
          while ((n<numbatchfiles) and (not foundit)) do begin
            inc(n);
            if (allcaps(batch[n].fn)=allcaps(filestr)) then foundit:=TRUE;
          end;
          if (foundit) then begin
            if (wasok) then begin
              sysoplog(#3#5+'Batch downloaded "'+stripname(batch[n].fn)+'"');
              inc(tnfils);
              inc(tblks,batch[n].blks);
              inc(tpts,batch[n].pts);
              loaduboard(batch[n].section);
              if (not (fbnoratio in memuboard.fbstat)) then begin
                inc(tnfils1);
                inc(tblks1,batch[n].blks);
                inc(tpts1,batch[n].pts);
              end;
              addnacc(batch[n].section,batch[n].fn);
              delbatch(n);
            end else
              sysoplog(#3#7+'Tried batch download "'+stripname(batch[n].fn)+'"');
          end else
            sysoplog(#3#7+'*Batch downloaded unauthorized file? "'+filestr+'"');
        end;
        close(batfile);
        close(tfil);
      end;
    end;
    if (not readlog) then begin
      while (toxfer>0) do begin
        sysoplog(#3#5+'Batch download "'+stripname(batch[1].fn)+'"');
        inc(tnfils);
        inc(tblks,batch[1].blks);
        inc(tpts,batch[1].pts);
        loaduboard(batch[1].section);
        if (not (fbnoratio in memuboard.fbstat)) then begin
          inc(tnfils1);
          inc(tblks,batch[1].blks);
          inc(tpts1,batch[1].pts);
        end;
        addnacc(batch[1].section,batch[1].fn);
        delbatch(1); dec(toxfer);
      end;
    end;
  end;

begin
  if (numbatchfiles=0) then begin
    nl; print('Batch queue empty.');
  end else begin
    nl;
    print('Checking batch download request...');

    tott:=0.0;
    for n:=1 to numbatchfiles do
      tott:=tott+batch[n].tt;

    nl;
    print('Number files in batch .. : '+cstr(numbatchfiles));
    print('Batch download time .... : '+ctim(tott));
    print('Time left online ....... : '+ctim(nsl));

    if (tott>nsl) then begin
      nl;
      print('Insufficient time for download!!');
      print('You must remove some files from your batch queue.');
      exit;
    end;

    reset(xf);
    done1:=FALSE;
    repeat
      nl;
      sprompt('^4Batch Protocol (^0?^4=^0list^4) : ^3'); mpkey(i);
      if (i='?') then begin
        nl;
        showprots(FALSE,TRUE,TRUE,FALSE);
      end else begin
        p:=findprot(i,FALSE,TRUE,TRUE,FALSE);
        if (p=-99) then print('Invalid entry.') else done1:=TRUE;
      end;
    until (done1) or (hangup);
    if (p<>-10) then begin
      seek(xf,p); read(xf,protocol); close(xf);
      nl; sprint(#3#7+'Hangup after transfer?');
      prt('(A)bort (N)o (Y)es (M)aybe : '); onek(c,'ANYM'^M);
      if (c=^M) then c:='N';
      hua:=pos(c,'ANYM');
      dok:=TRUE;
      if (hua<>1) then begin
        tblks:=0; tpts:=0; tnfils:=0;
        tblks1:=0; tpts1:=0; tnfils1:=0;
        nl; nl;

        nfn:=bproline1(protocol.dlcmd);
        toxfer:=0; tott:=0.0;
        if (pos('%F',protocol.dlcmd)<>0) then begin
          done1:=FALSE;
          while ((not done1) and (toxfer<numbatchfiles)) do begin
            inc(toxfer); snfn:=nfn;
            bproline(nfn,batch[toxfer].fn);
            if (length(nfn)>protocol.maxchrs) then done1:=TRUE
              else tott:=tott+batch[toxfer].tt;
          end;
        end;

        if (protocol.dlflist<>'') then begin
          tott:=0.0;
          assign(batfile,bproline1(protocol.dlflist));
          rewrite(batfile);
          for n:=1 to numbatchfiles do begin
            writeln(batfile,batch[n].fn);
            inc(toxfer); tott:=tott+batch[n].tt;
          end;
          close(batfile);
        end;

        (* output x-fer batch file *)
        assign(batfile,'tgtemp1.bat'); rewrite(batfile);
        if (protocol.envcmd<>'') then
          writeln(batfile,bproline1(protocol.envcmd));
        writeln(batfile,nfn);
        writeln(batfile,'exit');
        close(batfile);

        (* delete old log file *)
        if (exist(bproline1(protocol.templog))) then begin
          assign(batfile,bproline1(protocol.templog));
          {$I-} erase(batfile); {$I+}
        end;

        r2dt(batchtime,batchtime1);
        if (useron) then
          print('Transmitting batch  -  Time: '+longtim(batchtime1));

        if (useron) then shel(caps(thisuser.name)+' is batch downloading!')
                    else shel('Sending file(s)...');

        getdatetime(xferstart);
        swap:=systat.swapshell;
        systat.swapshell:=FALSE;
        shelldos(FALSE,'tgtemp1',rcode);
        systat.swapshell:=swap;
        shel2;
        getdatetime(xferend);
        timediff(tooktime,xferstart,xferend);

        (* delete TGTEMP1.BAT batch file *)
        assign(batfile,'tgtemp1.bat');
        {$I-} erase(batfile); {$I+}

        figuresucc;

        tooktime1:=dt2r(tooktime);
        if (tooktime1>=1.0) then begin
          cps:=tblks; cps:=cps*128;
          cps:=trunc(cps/tooktime1);
        end else
          cps:=0;

        showuserfileinfo;
        commandline('');
        nl; nl;

        s:='Download totals:  ';
        if (tnfils=0) then s:=s+'No' else s:=s+cstr(tnfils);
        s:=s+' file'; if (tnfils<>1) then s:=s+'s';
        lng:=tblks; lng:=lng*128;
        s:=s+', '+cstrl(lng)+' bytes';
        if (tpts<>0) then begin
          s:=s+', '+cstr(tpts)+' file point';
          if (tpts<>1) then s:=s+'s';
        end;
        s:=s+'.';
        star(s);

        if (tnfils1<>tnfils) then begin
          if (tnfils<tnfils1) then tnfils1:=tnfils;

          s:='Download charges: ';
          if (tnfils1=0) then s:=s+'No' else s:=s+cstr(tnfils1);
          s:=s+' file'; if (tnfils1<>1) then s:=s+'s';
          lng:=tblks1; lng:=lng*128;
          s:=s+', '+cstrl(lng)+' bytes';
          if (tpts1<>0) then begin
            s:=s+', '+cstr(tpts1)+' file point';
            if (tpts1<>1) then s:=s+'s';
          end;
          s:=s+'.';
          star(s);
        end;

        star('Download time:    '+longtim(tooktime));
        star('Transfer rate:    '+cstr(cps)+' cps');

        thisuser.dk:=thisuser.dk+(tblks1 div 8);
        inc(thisuser.downloads,tnfils1);
        dec(thisuser.filepoints,tpts1);

        inc(systat.todayzlog.downloads,tnfils);
        inc(systat.todayzlog.dk,tblks div 8);

        if (numbatchfiles<>0) then begin
          tblks:=0; tpts:=0;
          for n:=1 to numbatchfiles do begin
            inc(tblks,batch[n].blks);
            inc(tpts,batch[n].pts);
          end;
          lng:=tblks; lng:=lng*128;
          s:='Not transferred:  '+cstr(numbatchfiles)+' file';
          if (numbatchfiles<>1) then s:=s+'s';
          s:=s+', '+cstrl(lng)+' bytes';
          if (tpts<>0) then begin
            s:=s+', '+cstr(tpts)+' file point';
            if (tpts<>1) then s:=s+'s';
          end;
          s:=s+'.';
          star(s);
        end;

        case hua of
          3:hangup:=TRUE;
          4:begin
              nl;
              nl;
              print('System will automatically hang up in 30 seconds.');
              print('Hit [H] to hang up now, any other key to abort.');
              st:=timer;
              while (tcheck(st,30)) and (empty) do;
              if (empty) then hangup:=TRUE;
              if (not empty) then
                if upcase(inkey)='H' then
                  hangup:=TRUE;
            end;
        end;
      end;
    end;
  end;
end;

procedure listbatchfiles;
var tot:record
          pts:integer;
          blks:longint;
          tt:real;
        end;
    s:astr;
    i:integer;
    abort,next:boolean;
begin
  if (numbatchfiles=0) then begin
    nl; print('Batch queue empty.');
  end else begin
    abort:=FALSE; next:=FALSE;
    with tot do begin
      pts:=0; blks:=0; tt:=0.0;
    end;

    nl;
    printacr(#3#4+'##:Filename.Ext Area Pts   Bytes   hh:mm:ss',abort,next);
    printacr(#3#4+'--------------- ---- ----- ------- --------',abort,next);

    i:=1;
    while (not abort) and (not hangup) and (i<=numbatchfiles) do begin
      with batch[i] do begin
        if section=-1 then s:=#3#7+'Unli' else s:=#3#5+mrn(cstr(section),4);
        s:=#3#3+mn(i,2)+#3#4+':'+#3#5+align(stripname(fn))+' '+
           s+' '+#3#4+mrn(cstr(pts),5)+' '+
           #3#4+mrn(cstrl(blks*128),7)+' '+#3#7+ctim(tt);
        if (section<>-1) then begin
          loaduboard(section);
          if (fbnoratio in memuboard.fbstat) then s:=s+#3#5+' <No-Ratio>';
        end;
        printacr(s,abort,next);
        tot.pts:=tot.pts+pts;
        tot.blks:=tot.blks+blks;
        tot.tt:=tot.tt+tt;
      end;
      inc(i);
    end;

    printacr(#3#4+'--------------- ---- ----- ------- --------',abort,next);
    with tot do
      s:=#3#3+mln('Totals:',20)+' '+#3#4+mrn(cstr(pts),5)+' '+
         #3#4+mrn(cstrl(blks*128),7)+' '+#3#7+ctim(tt);
    printacr(s,abort,next);
  end;
end;

procedure removebatchfiles;
var s:astr;
    i:integer;
begin
  if numbatchfiles=0 then begin
    nl; print('Batch queue empty.');
  end else
    repeat
      nl;
      prt('File # to remove (1-'+cstr(numbatchfiles)+') (?=list) : ');
      input(s,2); i:=value(s);
      if (s='?') then listbatchfiles;
      if (i>0) and (i<=numbatchfiles) then begin
        print('"'+stripname(batch[i].fn)+'" deleted out of queue.');
        delbatch(i);
      end;
      if (numbatchfiles=0) then print('Queue now empty.');
    until (s<>'?');
end;

procedure clearbatch;
begin
  nl;
  if pynq('Clear queue? ') then begin
    numbatchfiles:=0;
    batchtime:=0.0;
    print('Queue now empty.');
  end;
end;

end.
