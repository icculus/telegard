{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit file9;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  myio,
  file0, file1, file2,
  common;

function info:astr;
procedure dir(cd,x:astr; expanded:boolean);
procedure dirf(expanded:boolean);
procedure deleteff(rn:integer; var pl:integer; killverbose:boolean);
procedure remove;
procedure setdirs;
procedure pointdate;
procedure yourfileinfo;
procedure listopts;

implementation

function align2(s:astr):astr;
begin
  if pos('.',s)=0 then s:=mln(s,12)
    else s:=mln(copy(s,1,pos('.',s)-1),8)+' '+mln(copy(s,pos('.',s)+1,3),3);
  align2:=s;
end;

function info:astr;
var pm:char;
    i:integer;
    s:astr;
    dt:datetime;

  function ti(i:integer):astr;
  var s:astr;
  begin
    ti:=tch(cstr(i));
  end;

begin
  s:=dirinfo.name;
  if (dirinfo.attr and directory)=directory then s:=mln(s,13)+'<DIR>   '
    else s:=align2(s)+'  '+mrn(cstrl(dirinfo.size),7);
  unpacktime(dirinfo.time,dt);
  with dt do begin
    if hour<13 then pm:='a' else begin pm:='p'; hour:=hour-12; end;
    {rcg11272000 Y2K-proofing.}
    {
    s:=s+'  '+mrn(cstr(month),2)+'-'+ti(day)+'-'+ti(year-1900)+
             '  '+mrn(cstr(hour),2)+':'+ti(min)+pm;
    }
    s:=s+'  '+mrn(cstr(month),2)+'-'+ti(day)+'-'+cstr(year)+
             '  '+mrn(cstr(hour),2)+':'+ti(min)+pm;
  end;
  info:=s;
end;

procedure dir(cd,x:astr; expanded:boolean);
var abort,next,nofiles:boolean;
    s:astr;
    onlin:integer;
    dfs:longint;
    numfiles:integer;
begin
  {rcg11242000 DOSism.}
  {if (copy(cd,length(cd),1)<>'\') then cd:=cd+'\';}
  if (copy(cd,length(cd),1)<>'/') then cd:=cd+'/';
  abort:=FALSE;
  cd:=cd+x;
  if (fso) then begin
    printacr(#3#5+' Directory of  '+#3#3+copy(cd,1,length(cd)),abort,next);
    nl;
  end;
  s:=''; onlin:=0; numfiles:=0; nofiles:=TRUE;
  ffile(cd);
  while (found) and (not abort) do begin
    if (not (dirinfo.attr and directory=directory)) or (fso) then
      if (not (dirinfo.attr and volumeid=volumeid)) then
        if ((not (dirinfo.attr and dos.hidden=dos.hidden)) or (usernum=1)) then
          if ((dirinfo.attr and dos.hidden=dos.hidden) and
             (not (dirinfo.attr and directory=directory))) or
             (not (dirinfo.attr and dos.hidden=dos.hidden)) then begin
            nofiles:=FALSE;
            if (expanded) then printacr(info,abort,next)
            else begin
              inc(onlin);
              s:=s+align2(dirinfo.name);
              if onlin<>5 then s:=s+'    ' else begin
                printacr(s,abort,next);
                s:=''; onlin:=0;
              end;
            end;
            inc(numfiles);
          end;
    nfile;
  end;
  if (not found) and (onlin in [1..5]) then printacr(s,abort,next);
  dfs:=freek(exdrv(cd));
  if (nofiles) then s:=#3#3+'Files not found'
    else s:=#3#3+mrn(cstr(numfiles)+#3#5+' File(s)',17);
  printacr(s+#3#3+mrn(cstrl(dfs*1024),10)+#3#5+' bytes free',abort,next);
end;

procedure dirf(expanded:boolean);
var fspec:astr;
    abort,next,all:boolean;
begin
  nl;
  print('Raw directory.');
  gfn(fspec); abort:=FALSE; next:=FALSE;
  nl;
  loaduboard(fileboard);
  dir(memuboard.dlpath,fspec,expanded);
end;

procedure deleteff(rn:integer; var pl:integer; killverbose:boolean);
var i:integer;
    f:ulfrec;
    v:verbrec;
begin
  if (rn<=pl) and (rn>0) then begin
    dec(pl);
    seek(ulff,rn); read(ulff,f);
    if (f.vpointer<>-1) and (killverbose) then begin
      assign(verbf,systat.gfilepath+'verbose.dat');
      reset(verbf);
      seek(verbf,f.vpointer); read(verbf,v);
      if (ioresult=0) then begin
        v.descr[1]:='';
        seek(verbf,f.vpointer); write(verbf,v);
      end;
      close(verbf);
    end;
    for i:=rn to pl do begin
      seek(ulff,i+1); read(ulff,f);
      seek(ulff,i); write(ulff,f);
    end;
    seek(ulff,0); f.blocks:=pl; write(ulff,f);
  end;
end;

procedure remove;
var done,abort,next,subit:boolean;
    c:char;
    pl,rn:integer;
    s,fn:astr;
    ff:file;
    f:ulfrec;
    u:userrec;
begin
  nl;
  print('Remove files.');
  gfn(fn); abort:=FALSE; next:=FALSE;
  nl;
  recno(fn,pl,rn);
  if (baddlpath) then exit;
  if (fn='') or (pos('.',fn)=0) or (rn=0) then
    print('No matching files.')
  else begin
    lastcommandovr:=TRUE;
    c:=#0;
    while (fn<>'') and (rn<>0) and (not abort) and (not hangup) do begin
      seek(ulff,rn); read(ulff,f);
      reset(uf); seek(uf,f.owner); read(uf,u);
      if (rn<>0) then begin
        done:=FALSE;
        repeat
          if (c<>'?') then begin
            nl;
            fileinfo(f,FALSE,abort,next);
            nl;
          end;
          if (next) then c:='N' else begin
            prt('Remove files (?=help) : ');
            if (f.owner<>usernum) and (not fso) then
              onek(c,'QN?'^M)
            else onek(c,'QDN?'^M);
          end;
          case c of
            ^M:c:=#0;  {* do nothing *}
            '?':begin
                  nl;
                  print('<CR>Redisplay entry');
                  if (f.owner<>usernum) and (not fso) then
                    lcmds(12,3,'Next file','Quit')
                  else begin
                    lcmds(12,3,'Delete file','Next file');
                    lcmds(12,3,'Quit','');
                  end;
                  nl;
                end;
            'D':if (f.owner<>usernum) and (not fso) then
                  sprint(#3#7+'You can''t delete this!!')
                else begin
                  deleteff(rn,pl,TRUE);
                  dec(lrn);
                  s:='Removed "'+sqoutsp(f.filename)+'" from Dir#'+cstr(fileboard);
                  nl;
                  if (not exist(memuboard.dlpath+f.filename)) then
                    sprint(#3#5+'File does not exist!')
                  else
                    if (fso) then
                      if pynq('Erase file too? ') then begin
                        assign(ff,memuboard.dlpath+f.filename);
                        {$I-} erase(ff); {$I+}
                        if (ioresult=0) then s:=s+' [FILE DELETED]'
                        else
                          s:='Tried deleting "'+sqoutsp(f.filename)+'" from Dir#'+cstr(fileboard);
                      end;

                  subit:=(allcaps(f.stowner)=allcaps(u.name));
                  if (fso) then
                    if (not subit) then begin
                      print('Uploader name does not match user name!');
                      print('Cannot remove credit from user.');
                    end else
                      subit:=pynq('Remove from '+#3#5+caps(u.name)+' #'+
                                  cstr(f.owner)+#3#7+'''s ratio? ');

                  if (subit) then begin
                    if (f.owner=usernum) then u:=thisuser;
                    with u do begin
                      uk:=uk-(f.blocks div 8);
                      dec(uploads);
                      if (uk<0) then uk:=0;
                      if (uploads<0) then uploads:=0;
                    end;
                    seek(uf,f.owner); write(uf,u);
                    if (f.owner=usernum) then thisuser:=u;
                  end;
                  sysoplog(s);
                  done:=TRUE;
                end;
          else
                  done:=TRUE;
          end;
        until ((done) or (hangup));
        abort:=FALSE; next:=FALSE;
        if (c='Q') then abort:=TRUE;
        if (c<>'?') then nrecno(fn,pl,rn);
      end;
    end;
    reset(uf); close(uf);
    close(ulff);
  end;
end;

procedure setdirs;
var s:astr;
    i:integer;
    done:boolean;
begin
  nl;
  if (novice in thisuser.ac) then begin fbaselist; nl; end;
  done:=FALSE;
  repeat
    prt('Set NewScan file bases (Q=Quit,?=List,#=Toggle base) : '); input(s,3);
    if (s='Q') then done:=TRUE;
    if (s='?') then begin fbaselist; nl; end;
    i:=ccuboards[0][value(s)];
    if (fbaseac(i)) then { loads memuboard }
      if (i>=0) and (i<=maxulb) and
         (length(s)>0) and (s[1] in ['0'..'9']) then begin
        nl;
        sprompt(#3#5+memuboard.name+#3#3);
        if (i in zscanr.fzscan) then begin
          sprint(' will NOT be scanned.');
          zscanr.fzscan:=zscanr.fzscan-[i];
        end else begin
          sprint(' WILL be scanned.');
          zscanr.fzscan:=zscanr.fzscan+[i];
        end;
        nl;
      end;
  until (done) or (hangup);
  lastcommandovr:=TRUE;
  savezscanr;
end;

procedure pointdate;
var s:astr;
begin
  nl;
  print('Enter limiting date for new files -');
  print('Date is currently set to '+newdate);
  nl;
  prt('(mm/dd/yy): '); input(s,8);
  if (daynum(s)=0) then print('Illegal date.') else newdate:=s;
  nl;
  print('Current limiting date is '+newdate);
end;

procedure yourfileinfo;
begin
  nl;
  with thisuser do begin
    sprint(#3#4+'Name.........: '+#3#5+nam);
    sprint(#3#4+'SL...........: '+#3#5+cstr(thisuser.sl));
    sprint(#3#4+'DSL..........: '+#3#5+cstr(thisuser.dsl));
    sprint(#3#4+'File points..: '+#3#5+cstr(thisuser.filepoints));
    sprompt(#3#4+'You DLed.....: '+#3#5+cstrl(thisuser.dk)+'k in '+cstr(thisuser.downloads)+' file');
    if (thisuser.downloads<>1) then sprint('s') else nl;
    sprompt(#3#4+'You ULed.....: '+#3#5+cstrl(thisuser.uk)+'k in '+cstr(thisuser.uploads)+' file');
    if (thisuser.uploads<>1) then sprint('s') else nl;
    sprint(#3#4+'File point status:');
    if (fnofilepts in thisuser.ac) then
      sprint(#3#3+'  Special flag -  No file point check!')
    else
      if (aacs(systat.nofilepts)) then
        sprint(#3#3+'  High security level -  No file point check!')
      else
        sprint(#3#5+'  Active according to setting on each file.');
    if (not systat.fileptratio) then
      sprint(#3#3+'  Auto file point compensation inactive.')
    else begin
      sprint(#3#5+'  File point compensation of '+cstr(systat.fileptcomp)+' to 1.');
      sprint(#3#5+'  Base compensation size of '+cstr(systat.fileptcompbasesize)+'k.');
    end;
    sprint(#3#4+'UL/DL ratio settings:');
    if (not systat.uldlratio) then
      sprint(#3#3+'  Inactive.')
    else
      if (fnodlratio in thisuser.ac) then
        sprint(#3#3+'  Special flag -  No ratio check!')
      else
        if (aacs(systat.nodlratio)) then
          sprint(#3#3+'  High security level -  No ratio check!')
        else begin
          sprint(#3#5+'  1 upload for every '+cstr(systat.dlratio[thisuser.sl])+' downloads');
          sprint(#3#5+'  1k upload for every '+cstr(systat.dlkratio[thisuser.sl])+' downloaded');
        end;
  end;
end;

procedure listopts;
var c:char;
begin
  nl;
  prt('List version: (1-3) ['+cstr(thisuser.flistopt)+'] : '); onek(c,'Q123 '^M);
  if (c in ['1'..'3']) then thisuser.flistopt:=ord(c)-48;
  if (thisuser.flistopt in [1,3]) then begin
    dyny:=flistverb;
    flistverb:=pynq('List verbose descriptions? ['+syn(flistverb)+'] : ');
  end;
  lastcommandovr:=TRUE;
end;

end.
