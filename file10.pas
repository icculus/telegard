{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit file10;

interface

uses
  crt,dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  myio,
  file0, file1, file2, file4, file9,
  common;

procedure move;
procedure editfiles;
procedure validatefiles;

implementation

uses
  miscx;

procedure move;
var ff:file;
    f,f1:ulfrec;
    v:verbrec;
    s,s1,s2,fl,fn:astr;
    x,i:longint;
    pl,rn,dbn,oldfileboard:integer;
    c:char;
    espace,nospace,done,abort,next,ok:boolean;
begin
  nl;
  print('Move files.');
  gfn(fn); abort:=FALSE; next:=FALSE;
  nl;
  recno(fn,pl,rn);
  if (baddlpath) then exit;
  if (fn='') or (pos('.',fn)=0) or (rn=0) then
    print('No matching files.')
  else begin
    lastcommandovr:=TRUE;
    c:=#0;
    while (rn<>0) and (pl<>0) and (rn<=pl) and
          (not abort) and (not hangup) do begin
      if (rn<>0) and (pl<>0) then begin
        seek(ulff,rn); read(ulff,f);
        if (c<>'?') then begin
          nl;
          fileinfo(f,FALSE,abort,next);
          nl;
        end;
        if (next) then c:='N' else begin
          prt('Move files (?=help) : '); onek(c,'QMN?'^M);
        end;
        case c of
          ^M:c:=#0;  {* do nothing *}
          '?':begin
                nl;
                print('<CR>Redisplay entry');
                lcmds(10,3,'Move file','Next file');
                lcmds(10,3,'Quit','');
                nl;
              end;
          'M':begin
                done:=FALSE;
                nl;
                repeat
                  prt('Move file (Q=Quit,?=List,#=Move-to base) : ');
                  input(s,3); dbn:=ccuboards[0][value(s)];
                  if (s='?') then begin fbaselist; nl; end else
                  if (s='Q') or ((dbn=0) and (s<>'0')) then done:=TRUE else
                  if (dbn<0) or (dbn>maxulb) then print('Can''t move it there.')
                  else begin
                    oldfileboard:=fileboard;
                    changefileboard(dbn);
                    if (fileboard=oldfileboard) then print('Can''t move it there.')
                    else begin
                      fileboard:=oldfileboard;
                      done:=TRUE;
                      nl;
                      loaduboard(fileboard);
                      fl:=memuboard.dlpath+f.filename;
                      s1:=fexpand(bslash(FALSE,memuboard.dlpath));
                      loaduboard(dbn);
                      sprint(#3#5+'Moving file ... to '+memuboard.name+#3#5);
                      s2:=fexpand(bslash(FALSE,memuboard.dlpath));
                      ok:=TRUE;

                      sprint(#3#5+'Orig-path : "'+s1+'" ('+cstrl(freek(exdrv(s1)))+'k free)');
                      sprint(#3#5+'Dest-path : "'+s2+'" ('+cstrl(freek(exdrv(s2)))+'k free)');

                      if (s1=s2) then begin
                        sprint(#3#7+'No move: directory paths are the same.');
                        espace:=TRUE;
                        ok:=TRUE;
                      end else
                        if (exist(fl)) then begin
                          espace:=TRUE;
                          assign(ff,fl);
                          {$I-}
                          reset(ff,1); i:=trunc(filesize(ff)/1024.0)+1;
                          close(ff);
                          {$I+}
                          x:=exdrv(memuboard.dlpath);  (* uboards[dbn] *)
                          sprompt(#3#5+'Progress: ');
                          movefile(ok,nospace,TRUE,fl,
                                   memuboard.dlpath+f.filename);
                                (* ^^^^^^^^^ uboards[dbn] *)
                          if (ok) then nl;
                          if (not ok) then begin
                            sprompt(#3#7+'Move failed');
                            if (not nospace) then nl else
                              sprompt(' - Insuffient space on drive '+chr(x+64)+':');
                            sprint('!');
                          end;
                        end else
                          print('File does not actually exist.');
                      if ((espace) and (ok)) or (not exist(fl)) then begin
                        sprompt(#3#5+'Moving file record ...');
                        deleteff(rn,pl,FALSE);
                        oldfileboard:=fileboard; fileboard:=dbn;

                        close(ulff); fiscan(pl);
                        if (baddlpath) then exit;
                        v.descr[1]:=#1#1#0#1#1;
                        newff(f,v); close(ulff);

                        fileboard:=oldfileboard;
                        fiscan(pl);
                        if (baddlpath) then exit;
                        sysoplog('Moved "'+sqoutsp(f.filename)+'" from Dir#'+
                                 cstr(fileboard)+' to Dir#'+cstr(dbn));
                      end;
                      nl;
                      c:='N';
                      dec(rn); dec(lrn);
                    end;
                  end;
                until ((done) or (hangup));
              end;
        end;
        if (c<>'?') then nrecno(fn,pl,rn);
        abort:=FALSE; next:=FALSE;
        if (c='Q') then abort:=TRUE;
      end;
    end;
    close(ulff);
  end;
end;

procedure creditfile(var u:userrec; un:integer; var f:ulfrec; credit:boolean);
var rfpts:real;
    gotpts:longint;
begin
  if (not systat.fileptratio) then
    gotpts:=0
  else begin
    rfpts:=(f.blocks/8)/systat.fileptcompbasesize;
    gotpts:=round(rfpts*systat.fileptcomp);
    if (gotpts<1) then gotpts:=1;
  end;
  if (credit) then
    sprompt(#3#5+'Awarding upload credits: ')
  else
    sprompt(#3#5+'Taking away upload credits: ');
  prompt('1 file, '+cstrl(f.blocks div 8)+'k');
  if (credit) then begin
    inc(u.uploads);
    inc(u.uk,f.blocks div 8);
  end else begin
    dec(u.uploads);
    dec(u.uk,f.blocks div 8);
  end;
  if (systat.fileptratio) then begin
    prompt(', '+cstrl(gotpts)+' file points');
    if (credit) then
      inc(u.filepoints,gotpts)
    else
      dec(u.filepoints,gotpts);
  end;
  print('.');
  saveurec(u,un);
  if (un=usernum) then showudstats;
end;

procedure editfiles;
var ff:file;
    u:userrec;
    f,f1:ulfrec;
    v:verbrec;
    fn,fd,s,sel:astr;
    fsize:longint;
    pl,rn,i,x:integer;
    c,c1:char;
    dontshowlist,done,done2,abort,next:boolean;
begin
  nl;
  print('Edit files.');
  gfn(fn); abort:=FALSE; next:=FALSE;
  nl;
  dontshowlist:=FALSE;
  recno(fn,pl,rn);
  if (baddlpath) then exit;
  if (fn='') or (pos('.',fn)=0) or (rn=0) then
    print('No matching files.')
  else begin
    lastcommandovr:=TRUE;
    while (rn<>0) and (not abort) and (not hangup) do begin
      if rn<>0 then begin
        repeat
          seek(ulff,rn); read(ulff,f);
          abort:=FALSE; next:=FALSE;
          if not dontshowlist then begin
            nl;
            fileinfo(f,TRUE,abort,next);
          end else
            dontshowlist:=FALSE;
          nl;
          abort:=FALSE;
          if (next) then c:='N' else begin
            prt('Edit files (?=help) : ');
            onek(c,'Q?1234567CMRTVWN'^M); nl;
          end;
          case c of
            '?':begin
                  sprint('1-7:Edit file record');
                  lcmds(16,3,'Next record','Change Uploader''s file points');
                  lcmds(16,3,'Verbose edit','Make request file');
                  lcmds(16,3,'Resume toggle','Toggle validation');
                  lcmds(16,3,'Withdraw credit','Quit');
                  dontshowlist:=TRUE;
                end;
            '1':begin
                  prt('New filename: '); mpl(12); input(fn,12);
                  if (fn<>'') then begin
                    if ((exist(memuboard.dlpath+fn)) and
                        (exist(memuboard.dlpath+sqoutsp(f.filename)))) then
                      print('Can''t use that filename.')
                    else begin
                      assign(ff,memuboard.dlpath+f.filename);
                      {$I-} rename(ff,memuboard.dlpath+fn); {$I+}
                      x:=ioresult;
                      f.filename:=align(fn);
                    end;
                  end;
                end;
            '2':begin
                  print('Enter new description');
                  prt(':'); mpl(60); inputl(s,60);
                  if s<>'' then f.description:=s;
                end;
            '3':begin
                  print('Change file size');
                  nl;
                  prt('Use which: [B]ytes [K]Bytes [X]modem-blocks :');
                  onek(c,'QBKX'^M);

                  if (c in ['B','K','X']) then begin
                    prt('New file size in ');
                    case c of
                      'B':prt('bytes: ');
                      'K':prt('Kbytes: ');
                      'X':prt('Xmodem blocks: ');
                    end;
                    mpl(8); input(s,8);
                    if (s<>'') then begin
                      val(s,fsize,x);
                      case c of
                        'B':f.blocks:=fsize div 128;
                        'K':f.blocks:=fsize*8;
                        'X':f.blocks:=fsize;
                      end;
                    end;
                  end;
                end;
            '4':begin
                  prt('New user name/# who uploaded it: '); finduser(s,x);
                  if (x=0) then print('This user does not exist.');
                  if (x<>0) then begin
                    f.owner:=x;
                    loadurec(u,x);
                    f.stowner:=allcaps(u.name);
                  end;
                end;
            '5':begin
                  prt('New upload file date: '); mpl(8); input(s,8);
                  if (s<>'') then begin f.date:=s; f.daten:=daynum(s); end;
                end;
            '6':begin
                  prt('New number of downloads: '); mpl(5); input(s,5);
                  if (s<>'') then f.nacc:=value(s);
                end;
            '7':begin
                  prt('Enter new amount of file points: '); mpl(5); input(s,5);
                  if (s<>'') then f.filepoints:=value(s);
                end;
            'C':begin
                  loadurec(u,f.owner);
                  print('Add/Subtract from Uploader''s file points.');
                  print('Current file points: '+cstr(u.filepoints));
                  nl;
                  prt('Change value: '); mpl(6); input(s,6);
                  if (s<>'') then begin
                    inc(u.filepoints,value(s));
                    saveurec(u,f.owner);
                  end;
                end;
            'M':with f do
                  if (isrequest in filestat) then filestat:=filestat-[isrequest]
                    else filestat:=filestat+[isrequest];
            'R':with f do
                  if (resumelater in filestat) then filestat:=filestat-[resumelater]
                    else filestat:=filestat+[resumelater];
            'T':begin
                  with f do
                    if (notval in filestat) then filestat:=filestat-[notval]
                      else filestat:=filestat+[notval];

                  loadurec(u,f.owner);

                  if (not aacs1(u,f.owner,systat.ulvalreq)) then
                    creditfile(u,f.owner,f,not (notval in f.filestat));
                end;
            'V':begin
                  if (f.vpointer=-1) then begin
                    print('There is no verbose entry for this file.');
                    if pynq('Create verbose entry? ') then begin
                      v.descr[1]:='';
                      f.vpointer:=nfvpointer;
                      assign(verbf,systat.gfilepath+'verbose.dat');
                      reset(verbf); seek(verbf,f.vpointer); write(verbf,v);
                      reset(verbf);
                    end;
                  end;
                  if (f.vpointer<>-1) then begin
                    dontshowlist:=FALSE;
                    repeat
                      if (not dontshowlist) then begin
                        nl;
                        verbfileinfo(f.vpointer,TRUE,abort,next);
                        reset(verbf); seek(verbf,f.vpointer); read(verbf,v);
                        nl;
                      end;
                      dontshowlist:=FALSE;
                      sel:=^M'Q?DP';
                      for x:=1 to 4 do begin
                        sel:=sel+chr(x+48);
                        if v.descr[x]='' then x:=4;
                      end;
                      prt('Verbose edit: (1-'+sel[length(sel)]+',D,P,?,Q) :');
                      onek(c1,sel); nl;
                      case c1 of
                        '?':begin
                              print('1-'+sel[length(sel)]+':Edit verbose line');
                              lcmds(20,3,'Delete this entry','Pointer value change');
                              lcmds(20,3,'Quit','');
                              nl;
                              dontshowlist:=TRUE;
                            end;
                        '1'..'4':
                            begin
                              prt('Enter new line:'); nl;
                              prt(':'); mpl(50); inputl(s,50);
                              if (s<>'') then begin
                                if (s=' ') then
                                  if pynq('Set to NULL string? ') then s:='';
                                v.descr[ord(c1)-48]:=s;
                                if (c1=sel[length(sel)]) and (c1<>'4') then
                                  v.descr[ord(c1)-47]:='';
                                {$I-} seek(verbf,f.vpointer); {$I+}
                                if (ioresult=0) then write(verbf,v);
                              end;
                            end;
                        'D':if pynq('Are you sure? ') then begin
                              v.descr[1]:='';
                              {$I-} seek(verbf,f.vpointer); {$I+}
                              if (ioresult=0) then write(verbf,v);
                              f.vpointer:=-1;
                              c1:='Q';
                            end;
                        'P':begin
                              print('Change pointer value.');
                              print('Pointer range: 0-'+cstr(filesize(verbf)-1));
                              print('(-1 makes inactive for this file without deleting any entries)');
                              nl;
                              prt('New pointer value: ');
                              mpl(5); input(s,10);
                              if (s<>'') then begin
                                val(s,i,x);
                                if ((i>=-1) and (i<=filesize(verbf)-1)) then
                                  f.vpointer:=i;
                              end;
                            end;
                      end;
                    until (c1 in ['Q',' ',^M]) or (hangup) or (f.vpointer=-1);
                    {$I-} close(verbf); {$I+}
                    if (ioresult<>0) then print('Errors closing VERBOSE.DAT');
                    dontshowlist:=FALSE;
                  end;
                end;
            'W':begin
                  loadurec(u,f.owner);
                  sprint(#3#0+'WARNING: '+#3#5+'If you have already withdrawn credit');
                  sprint(#3#5+'from this user (or he never got it to begin with),');
                  sprint(#3#5+'the user will lose even MORE upload credit than');
                  sprint(#3#5+'they started out with!');
                  nl;
                  if pynq('Withdraw credit?? ') then
                    creditfile(u,f.owner,f,FALSE);
                end;
          else
                next:=TRUE;
          end;
          seek(ulff,rn); write(ulff,f);
        until (c in ['Q',' ']) or (hangup) or (next);
        if (c='Q') then abort:=TRUE;
      end;
      nrecno(fn,pl,rn);
    end;
    close(ulff);
  end;
end;

procedure validatefiles;
var i:integer;
    c:char;
    abort,next,isglobal,ispoints,isprompt:boolean;

  procedure valfiles(b:integer; var abort,next:boolean);
  var u:userrec;
      f:ulfrec;
      s:astr;
      lng:longint;
      oldboard,pl,rn:integer;
      shownalready:boolean;
  begin
    oldboard:=fileboard;
    if (fileboard<>b) then changefileboard(b);
    if (fileboard=b) then begin
      recno('*.*',pl,rn);
      shownalready:=FALSE; abort:=FALSE; next:=FALSE;
      while (rn<>0) and (not abort) and (not hangup) do begin
        seek(ulff,rn); read(ulff,f);
        if (notval in f.filestat) and
           (not (resumelater in f.filestat)) then begin
          if (not shownalready) then begin
            nl;
            sprint('Validating '+#3#5+memuboard.name+#3#5+' #'+
                   cstr(fileboard)); (*+#3#1+' ('+memuboard.dlpath+')');*)
            nl;
            shownalready:=TRUE;
          end;

          lng:=f.blocks; lng:=lng*128;
          sprint('Filename   : '+#3#3+'"'+f.filename+'"');
          sprint('Description: '+#3#3+f.description);
          sprint('Size/points: '+#3#5+cstrl(lng)+' bytes / '+
                 cstr(f.filepoints)+' pts');
          sprint('UL''d by    : '+#3#9+caps(f.stowner)+' #'+cstr(f.owner));
          nl;
          loadurec(u,f.owner);
          if (isprompt) then begin
            if (ispoints) then begin
              prt('Points for file (<CR>=Skip,Q=Quit) : '); input(s,5);
              if (s='Q') then abort:=TRUE;
              if ((s<>'') and (s<>'Q')) then begin
                f.filepoints:=value(s);
                f.filestat:=f.filestat-[notval];
                seek(ulff,rn); write(ulff,f);
                if (not aacs1(u,f.owner,systat.ulvalreq)) then
                  creditfile(u,f.owner,f,TRUE);
                prt('Points for '+#3#5+caps(f.stowner)+' #'+
                    cstr(f.owner)+#3#4+' (-999..999) : ');
                input(s,5);
                if (s<>'') then
                  if (f.owner=usernum) then
                    inc(thisuser.filepoints,value(s))
                  else begin
                    inc(u.filepoints,value(s));
                    saveurec(u,f.owner);
                  end;
              end;
              nl;
            end else begin
              repeat
                ynq('Validate? (Y/N,V=View,Q=Quit) : '); onek(c,'QNVY');
                case c of
                  'Q':abort:=TRUE;
                  'V':begin
                        abort:=FALSE; next:=FALSE;
                        lfi(sqoutsp(memuboard.dlpath+f.filename),abort,next);
                        abort:=FALSE; next:=FALSE;
                      end;
                  'Y':begin
                        f.filestat:=f.filestat-[notval];
                        seek(ulff,rn); write(ulff,f);
                        if (not aacs1(u,f.owner,systat.ulvalreq)) then
                          creditfile(u,f.owner,f,TRUE);
                      end;
                end;
              until ((c<>'V') or (hangup));
              nl;
            end;
          end else begin
            f.filestat:=f.filestat-[notval];
            seek(ulff,rn); write(ulff,f);
            if (not aacs1(u,f.owner,systat.ulvalreq)) then
              creditfile(u,f.owner,f,TRUE);
          end;
        end;

        nrecno('*.*',pl,rn);
        wkey(abort,next);
      end;
      close(ulff);
    end;
    fileboard:=oldboard;
  end;

begin
  nl;
  print('Validate files -');
  nl;
  ynq('Prompt for validation? (Y)es, (N)o, (P)oints validation : ');
  onek(c,'QNPY');
  if (c='Q') then exit;

  ispoints:=(c='P');
  isprompt:=(c<>'N');
  isglobal:=pynq('Search all directories? ');
  nl;

  abort:=FALSE; next:=FALSE;
  if (isglobal) then begin
    i:=0;
    while (i<=maxulb) and (not abort) and (not hangup) do begin
      if (fbaseac(i)) then valfiles(i,abort,next);
      inc(i);
      wkey(abort,next);
      if (next) then abort:=FALSE;
    end;
  end else
    valfiles(fileboard,abort,next);
end;

end.
