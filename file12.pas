{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit file12;

interface

uses
  crt,dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  file0, file1, file2, file4, file6, file9,
  execbat,
  mmodem,
  common;

procedure delubatch(n:integer);
procedure listubatchfiles;
procedure removeubatchfiles;
procedure clearubatch;
procedure batchul;
procedure batchinfo;

implementation

procedure delubatch(n:integer);
var c:integer;
begin
  if ((n>=1) and (n<=numubatchfiles)) then begin
    if (n<>numubatchfiles) then
      for c:=n to numubatchfiles-1 do ubatch[c]:=ubatch[c+1];
    dec(numubatchfiles);
  end;
end;

procedure listubatchfiles;
var s,s1:astr;
    i,j:integer;
    abort,next,vfo:boolean;
begin
  if (numubatchfiles=0) then begin
    nl; print('Upload batch queue empty.');
  end else begin
    abort:=FALSE; next:=FALSE;
    nl;
    printacr(#3#4+'##:Filename.Ext Area Description',abort,next);
    printacr(#3#4+'--------------- ---- -------------------------------------------------------',abort,next);

    i:=1;
    while ((not abort) and (i<=numubatchfiles) and (not hangup)) do begin
      with ubatch[i] do begin
        if (section=systat.tosysopdir) then s1:=#3#7+'Sysp'
          else s1:=mrn(cstr(section),4);
        s:=#3#3+mn(i,2)+#3#4+':'+#3#5+align(fn)+' '+s1+' '+
           #3#3+mln(description,55);
        printacr(s,abort,next);
        if (vr<>0) then
          if (ubatchv[vr]^.descr[1]<>'') then begin
            vfo:=(filerec(verbf).mode<>fmclosed);
            if (not vfo) then reset(verbf);
            if (ioresult=0) then
              for j:=1 to 4 do
                if ubatchv[vr]^.descr[j]='' then j:=4 else
                  printacr('                         '+#3#2+':'+
                           #3#4+ubatchv[vr]^.descr[j],abort,next);
            if (not vfo) then close(verbf);
          end;
      end;
      inc(i);
    end;

    printacr(#3#4+'--------------- ---- -------------------------------------------------------',abort,next);
  end;
end;

procedure removeubatchfiles;
var s:astr;
    i:integer;
begin
  if (numubatchfiles=0) then begin
    nl; print('Upload batch queue empty.');
  end else
    repeat
      nl;
      prt('File # to remove (1-'+cstr(numubatchfiles)+') (?=list) : ');
      input(s,2); i:=value(s);
      if (s='?') then listubatchfiles;
      if ((i>0) and (i<=numubatchfiles)) then begin
        print('"'+stripname(ubatch[i].fn)+'" deleted out of upload queue.');
        delubatch(i);
      end;
      if (numubatchfiles=0) then print('Upload queue now empty.');
    until (s<>'?');
end;

procedure clearubatch;
begin
  nl;
  if pynq('Clear upload queue? ') then begin
    numubatchfiles:=0;
    print('Upload queue now empty.');
  end;
end;

procedure batchul;
var fi:file of byte;
    dirinfo:searchrec;
    f:ulfrec;
    v:verbrec;
    xferstart,xferend,tooktime,takeawayulrefundgot1,ulrefundgot1:datetimerec;
    tconvtime1,st1:datetimerec;
    pc,fn,s:astr;
    st,tconvtime,convtime,ulrefundgot,takeawayulrefundgot:real;
    totb,totfils,totb1,totfils1,cps,lng,totpts:longint;
    i,p,hua,pl,dbn,blks,gotpts,ubn,filsuled,oldboard,passn:integer;
    c:char;
    abort,ahangup,next,done,dok,kabort,wenttosysop,ok,convt,
      beepafter,dothispass,fok,nospace,savpause:boolean;

  function notinubatch(fn:astr):boolean;
  var i:integer;
  begin
    notinubatch:=FALSE;
    for i:=1 to numubatchfiles do
      if (sqoutsp(fn)=sqoutsp(ubatch[i].fn)) then exit;
    notinubatch:=TRUE;
  end;

  function ubatchnum(fn:astr):integer;
  var i:integer;
  begin
    fn:=sqoutsp(fn);
    ubatchnum:=0;
    for i:=1 to numubatchfiles do
      if (fn=sqoutsp(ubatch[i].fn)) then ubatchnum:=i;
  end;

  function plural:string;
  begin
    if (totfils<>1) then plural:='s' else plural:='';
  end;

begin
  savpause:=(pause in thisuser.ac);
  if (savpause) then thisuser.ac:=thisuser.ac-[pause];

  oldboard:=fileboard;
  beepafter:=FALSE; done:=FALSE;
  nl;
  if (numubatchfiles=0) then begin
    printf('batchul0');
    if (nofile) then begin
      print('Warning!  No upload batch files specified yet.');
      print('If you continue, and batch upload files, you will have to');
      print('enter file descriptions for each file after the batch upload');
      print('is complete.');
    end;
  end else begin
    printf('batchul');
    if (nofile) then begin
      print('If you batch upload files IN ADDITION to the files already');
      print('specified in your upload batch queue, you must enter file');
      print('descriptions for them after the batch upload is complete.');
    end;
  end;
  reset(xf);
  done:=FALSE;
  repeat
    nl;
    sprompt('^4Batch Protocol (^0?^4=^0list^4) : ^3'); mpkey(s);
    if (s='?') then begin
      nl;
      showprots(TRUE,FALSE,TRUE,FALSE);
    end else begin
      p:=findprot(s,TRUE,FALSE,TRUE,FALSE);
      if (p=-99) then print('Invalid entry.') else done:=TRUE;
    end;
  until (done) or (hangup);
  if (p<>-10) then begin
    seek(xf,p); read(xf,protocol); close(xf);
    nl;
    sprint(#3#7+'Hangup after transfer?');
    prt('[A]bort [N]o [Y]es [M]aybe : ');
    if (not trm) then onek(c,'ANYM') else local_onek(c,'ANYM');
    hua:=pos(c,'ANYM');
    dok:=TRUE;
    if (hua<>1) then begin
      if (hua<>3) then begin
        nl;
        dyny:=TRUE;
        beepafter:=pynq('Beep after transfer? ');
      end;

      lil:=0;
      nl; nl;
      if (useron) then print('Ready to receive batch queue!');
      lil:=0;

      getdatetime(xferstart);
      if (useron) then shel(caps(thisuser.name)+' is batch uploading!')
                  else shel('Receiving file(s)...');
      {rcg11242000 DOSism.}
      {
      execbatch(dok,FALSE,'tgtemp1.bat','tgtest1.$$$',systat.temppath+'2\',
                bproline1(protocol.ulcmd),-1);
      }
      execbatch(dok,FALSE,'tgtemp1.bat','tgtest1.$$$',systat.temppath+'2/',
                bproline1(protocol.ulcmd),-1);
      shel2;
      getdatetime(xferend);
      timediff(tooktime,xferstart,xferend);

      showuserfileinfo;

      ulrefundgot:=(dt2r(tooktime))*(systat.ulrefund/100.0);
      freetime:=freetime+ulrefundgot;

      {*****}

      lil:=0;
      nl;
      nl;
      star('Batch upload transfer complete.');
      nl;
      lil:=0;

      tconvtime:=0.0; takeawayulrefundgot:=0.0;
      totb:=0; totfils:=0; totb1:=0; totfils1:=0; totpts:=0;

      {rcg11242000 DOSism.}
      {findfirst(systat.temppath+'2\*.*',anyfile-directory,dirinfo);}
      findfirst(systat.temppath+'2/*.*',anyfile-directory,dirinfo);
      while (doserror=0) do begin
        inc(totfils1);
        inc(totb1,dirinfo.size);
        findnext(dirinfo);
      end;
      cps:=trunc(totb1/dt2r(tooktime));

      abort:=FALSE; next:=FALSE;

      if (totfils1=0) then begin
        star('No files detected!  Transfer aborted.');
        exit;
      end;

      case hua of
        3:hangup:=TRUE;
        4:begin
            lil:=0;
            nl;
            nl;
            print('System will automatically hang up in 30 seconds.');
            print('Hit [H] to hang up now, any other key to abort.');
            st:=timer;
            while (tcheck(st,30)) and (empty) do;
            if (empty) then hangup:=TRUE;
            if (not empty) then
              if (upcase(inkey)='H') then hangup:=TRUE;
            lil:=0;
          end;
      end;

      ahangup:=FALSE;
      if (hangup) then begin
        if (spd<>'KB') then begin
          commandline('Hanging up and taking phone off hook...');
          dophonehangup(FALSE);
          dophoneoffhook(FALSE);
          spd:='KB';
        end;
        hangup:=FALSE; ahangup:=TRUE;
      end;

      r2dt(ulrefundgot,ulrefundgot1);
      if (not ahangup) then begin
        prt('Press any key for upload stats : ');
        if (beepafter) then begin
          i:=1;
          repeat
            if (s<>time) then begin prompt(^G#0#0#0^G); s:=time; inc(i); end;
          until ((i=30) or (not empty) or (hangup));
        end;
        getkey(c);
        for i:=1 to 33 do prompt(^H' '^H);

        print('Uploads detected:');
        nl;
        {rcg11242000 DOSism.}
        {dir(systat.temppath+'2\','*.*',TRUE);}
        dir(systat.temppath+'2/','*.*',TRUE);
        nl;
        star('# files uploaded:   '+cstr(totfils1)+' files.');
        star('File size uploaded: '+cstrl(totb1)+' bytes.');
        star('Batch upload time:  '+longtim(tooktime)+'.');
        star('Transfer rate:      '+cstr(cps)+' cps');
        star('Time refund:        '+longtim(ulrefundgot1)+'.');
        nl;
        pausescr;
      end;

      fiscan(pl);

      {* files not in upload batch queue are ONLY done during the first pass *}
      {* files already in the upload batch queue done during the second pass *}

      for passn:=1 to 2 do begin
        {rcg11242000 DOSism.}
        {findfirst(systat.temppath+'2\*.*',anyfile-directory,dirinfo);}
        findfirst(systat.temppath+'2/*.*',anyfile-directory,dirinfo);
        while (doserror=0) do begin
          fn:=sqoutsp(dirinfo.name);
          nl;
          dothispass:=FALSE;
          if (notinubatch(fn)) then begin
            ubn:=0;
            dothispass:=TRUE;
            star('"'+fn+'" - File not in upload batch queue.');

            close(ulff); fiscan(pl);
            wenttosysop:=TRUE;
            f.filename:=fn;
            dodescrs(f,v,pl,wenttosysop);
            if (ahangup) then begin
              f.description:='Not in upload batch queue - hungup after transfer';
              f.vpointer:=-1; v.descr[1]:='';
            end;
            if (not wenttosysop) then begin
              nl;
              done:=FALSE;
              if (ahangup) then
                dbn:=oldboard
              else
                repeat
                  prt('File base (?=List,#=File base) ['+cstr(ccuboards[1][oldboard])+'] : ');
                  input(s,3); dbn:=ccuboards[0][value(s)];
                  if (s='?') then begin fbaselist; nl; end;
                  if (s='') then dbn:=oldboard;
                  if (not fbaseac(dbn)) then begin
                    print('Can''t put it there.');
                    dbn:=-1;
                  end else
                    loaduboard(dbn);
                    if (exist(sqoutsp(memuboard.dlpath+fn))) then begin
                      print('"'+fn+'" already exists in that directory.');
                      dbn:=-1;
                    end;
                  if (dbn<>-1) and (s<>'?') then done:=TRUE;
                until ((done) or (hangup));
              fileboard:=dbn;
              nl;
            end;
          end else
            if (passn<>1) then begin
              dothispass:=TRUE;
              star('"'+fn+'" - File found.');
              ubn:=ubatchnum(fn);
              f.description:=ubatch[ubn].description;
              fileboard:=ubatch[ubn].section;
              v.descr[1]:='';
              if (ubatch[ubn].vr<>0) then v:=ubatchv[ubatch[ubn].vr]^;
              f.vpointer:=-1;
              if (v.descr[1]<>'') then f.vpointer:=nfvpointer;
              wenttosysop:=(fileboard=systat.tosysopdir);
            end;

          if (dothispass) then begin
            if (wenttosysop) then fileboard:=systat.tosysopdir;

            close(ulff); fiscan(pl);

            {rcg11242000 DOSism.}
            {
	    arcstuff(ok,convt,blks,convtime,TRUE,systat.temppath+'2\',
                     fn,f.description);
            }
            arcstuff(ok,convt,blks,convtime,TRUE,systat.temppath+'2/',
                     fn,f.description);
            tconvtime:=tconvtime+convtime; f.blocks:=blks;
            doffstuff(f,fn,gotpts);

            fok:=TRUE;
            loaduboard(fileboard);
            if (ok) then begin
              star('Moving file to '+#3#5+memuboard.name);
              sprompt(#3#5+'Progress: ');
              {rcg11242000 DOSism.}
              {movefile(fok,nospace,TRUE,systat.temppath+'2\'+fn,memuboard.dlpath+fn);}
              movefile(fok,nospace,TRUE,systat.temppath+'2/'+fn,memuboard.dlpath+fn);
              if (fok) then begin
                nl;
                newff(f,v);
                star('"'+fn+'" successfully uploaded.');
                sysoplog(#3#3+'Batch uploaded "'+sqoutsp(fn)+'" on '+
                         memuboard.name);
                inc(totfils);
                lng:=blks; lng:=lng*128;
                inc(totb,lng);
                inc(totpts,gotpts);
              end else begin
                star('Error moving file into directory - upload voided.');
                sysoplog(#3#3+'Error moving batch upload "'+sqoutsp(fn)+'" into directory');
              end;
            end else begin
              star('Upload not received.');
              if ((thisuser.sl>0 {systat.minresumelatersl} ) and
                  (f.blocks div 8>systat.minresume)) then begin
                nl;
                dyny:=TRUE;
                if pynq('Save file for a later resume? ') then begin
                  sprompt(#3#5+'Progress: ');
                  {rcg11242000 DOSism}
                  {movefile(fok,nospace,TRUE,systat.temppath+'2\'+fn,memuboard.dlpath+fn);}
                  movefile(fok,nospace,TRUE,systat.temppath+'2/'+fn,memuboard.dlpath+fn);
                  if (fok) then begin
                    nl;
                    doffstuff(f,fn,gotpts);
                    f.filestat:=f.filestat+[resumelater];
                    newff(f,v);
                    s:='file saved for later resume';
                  end else begin
                    star('Error moving file into directory - upload voided.');
                    sysoplog(#3#3+'Error moving batch upload "'+sqoutsp(fn)+'" into directory');
                  end;
                end;
              end;
              if (not (resumelater in f.filestat)) then begin
                s:='file deleted';
                {rcg11242000 DOSism.}
                {assign(fi,systat.temppath+'2\'+fn); erase(fi);}
                assign(fi,systat.temppath+'2/'+fn); erase(fi);
              end;
              sysoplog(#3#3+'Errors batch uploading "'+sqoutsp(fn)+'" - '+s);
            end;

            if (not ok) then begin
              st:=(rte*f.blocks);
              takeawayulrefundgot:=takeawayulrefundgot+st;
              r2dt(st,st1);
              star('Time refund of '+longtim(st1)+' will be taken away.');
            end else
              if (ubn<>0) then delubatch(ubn);
          end;

          findnext(dirinfo);
        end;
      end;

      close(ulff);
      fileboard:=oldboard;
      fiscan(pl); close(ulff);

      nl;
      star('# files uploaded:   '+cstr(totfils1)+' files.');
      if (totfils<>totfils1) then
        star('Files successful:   '+cstr(totfils)+' files.');
      star('File size uploaded: '+cstrl(totb1)+' bytes.');
      star('Batch upload time:  '+longtim(tooktime)+'.');
      r2dt(tconvtime,tconvtime1);
      if (tconvtime<>0.0) then
        star('Total convert time: '+longtim(tconvtime1)+' (not refunded)');
      star('Transfer rate:      '+cstr(cps)+' cps');
      nl;
      r2dt(ulrefundgot,ulrefundgot1);
      star('Time refund:        '+longtim(ulrefundgot1)+'.');

      inc(systat.todayzlog.uploads,totfils);
      inc(systat.todayzlog.uk,totb1 div 1024);
      if (aacs(systat.ulvalreq)) then begin
        if (totpts<>0) then
          star('File points:        '+cstr(totpts)+' pts.');
        star('Upload credits got: '+cstr(totfils)+' files, '+cstr(totb1 div 1024)+'k.');
        nl;
        star('Thanks for the file'+plural+', '+thisuser.name+'!');
        inc(thisuser.uploads,totfils);
        inc(thisuser.filepoints,totpts);
        thisuser.uk:=thisuser.uk+(totb1 div 1024);
      end else begin
        nl;
        sprint(#3#5+'Thanks for the upload'+plural+', '+thisuser.name+'!');
        sprompt(#3#5+'You will receive file ');
        if (systat.uldlratio) then
          sprompt('credit')
        else
          sprompt('points');
        sprint(' as soon as the SysOp validates the file'+plural+'!');
      end;
      nl;

      if (choptime<>0.0) then begin
        choptime:=choptime+ulrefundgot;
        freetime:=freetime-ulrefundgot;
        star('Sorry, no upload time refund may be given at this time.');
        star('You will get your refund after the event.');
        nl;
      end;

      if (takeawayulrefundgot<>0.0) then begin
        nl;
        r2dt(takeawayulrefundgot,takeawayulrefundgot1);
        star('Taking away time refund of '+longtim(takeawayulrefundgot1));
        freetime:=freetime-takeawayulrefundgot;
      end;

      if (ahangup) then begin
        commandline('Hanging up phone again...');
        dophonehangup(FALSE);
        hangup:=TRUE;
      end;

    end;
  end;
  if (savpause) then thisuser.ac:=thisuser.ac+[pause];
end;

procedure batchinfo;
var anyyet:boolean;

  procedure sayit(s:string);
  begin
    if (not anyyet) then begin anyyet:=TRUE; nl; end;
    sprint(s);
  end;

begin
  anyyet:=FALSE;
  if (numbatchfiles<>0) then
    sayit(#3#9+'>> '+#3#3+'You have '+#3#5+cstr(numbatchfiles)+
          #3#3+' file'+aonoff(numbatchfiles<>1,'s','')+
               ' left in your download batch queue.');
  if (numubatchfiles<>0) then
    sayit(#3#9+'>> '+#3#3+'You have '+#3#5+cstr(numubatchfiles)+
          #3#3+' file'+aonoff(numubatchfiles<>1,'s','')+
               ' left in your upload batch queue.');
end;

end.

