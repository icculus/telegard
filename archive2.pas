{$A+,B+,D-,E+,F+,I+,L-,N-,O+,R-,S+,V-}
unit archive2;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  myio,
  archive1, file0, file1, file4, file9, file11,
  execbat,
  common;

procedure doarccommand(cc:char);

implementation

const
  maxdoschrline=127;

procedure doarccommand(cc:char);
const maxfiles=100;
var fl:array[1..maxfiles] of astr;
    fn,s,s1,s2,os1:astr;
    atype,numfl,rn,pl,savflistopt:integer;
    i,j,x:integer;
    c:char;
    abort,next,done,ok,ok1:boolean;
    fnx:boolean;    {* whether fn points to file out of Telegard .DIR list *}
    fil1,fil2:boolean;    {* whether listed/unlisted files in list *}
    wenttosysop,delbad,savpause:boolean;
    f,f1:ulfrec;
    rfpts:real;
    fi:file of byte;
    v:verbrec;
    dstr,nstr,estr:astr;
    bb:byte;
    c_files,c_oldsiz,c_newsiz,oldsiz,newsiz:longint;

  function stripname(i:astr):astr;
  var i1:astr; n:integer;

    function nextn:integer;
    var n:integer;
    begin
      n:=pos(':',i1);
      if (n=0) then n:=pos('\',i1);
      if (n=0) then n:=pos('/',i1);
      nextn:=n;
    end;

  begin
    i1:=i;
    while nextn<>0 do i1:=copy(i1,nextn+1,80);
    stripname:=i1;
  end;

  procedure addfl(fn:astr; b:boolean);
  var pl,rn,oldnumfl:integer;
      f:ulfrec;
      s,dstr,nstr,estr:astr;
      dirinfo:searchrec;
  begin
    if (not b) then begin
      oldnumfl:=numfl;
      recno(fn,pl,rn);
      if (fn<>'') and (pos('.',fn)<>0) and (rn<>0) then
        while (fn<>'') and (rn<>0) and (numfl<maxfiles) do begin
          seek(ulff,rn); read(ulff,f);
          inc(numfl);
          fl[numfl]:=f.filename;
          nrecno(fn,pl,rn);
        end;
      if (numfl=oldnumfl) then print('No matching files.');
      if (numfl>=maxfiles) then print('File records filled.');
    end else begin
      oldnumfl:=numfl;
      fsplit(fn,dstr,nstr,estr); s:=dstr;
      while (copy(s,length(s),1)='\') do s:=copy(s,1,length(s)-1);
      {$I-} chdir(s); {$I+}
      if ioresult<>0 then print('Path not found.')
      else begin
        findfirst(fn,AnyFile-Directory-VolumeID,dirinfo);
        while (doserror=0) and (numfl<maxfiles) do begin
          inc(numfl);
          fl[numfl]:=fexpand(dstr+dirinfo.name);
          findnext(dirinfo);
        end;
        if (numfl>=maxfiles) then print('File records filled.');
        if (numfl=oldnumfl) then print('No matching files.');
      end;
      chdir(start_dir);
    end;
  end;

  procedure testfiles(b:integer; fn:astr; delbad:boolean; var abort,next:boolean);
  var fi:file of byte;
      f:ulfrec;
      oldboard,pl,rn,atype:integer;
      ok:boolean;
  begin
    oldboard:=fileboard;
    if (fileboard<>b) then changefileboard(b);
    if (fileboard=b) then begin
      recno(fn,pl,rn); { loads in memuboard }
      abort:=FALSE; next:=FALSE;
      while (fn<>'') and (rn<>0) and (not abort) and (not hangup) do begin
        seek(ulff,rn); read(ulff,f);
        fn:=memuboard.dlpath+f.filename;
        atype:=arctype(fn);
        if (atype<>0) then begin
          pbn(abort,next); nl;
          star('Testing "'+sqoutsp(fn)+'"');
          ok:=TRUE;
          if (not exist(fn)) then begin
            star('File "'+sqoutsp(fn)+'" doesn''t exist.');
            ok:=FALSE;
          end else begin
            arcintegritytest(ok,atype,sqoutsp(fn));
            if (not ok) then begin
              star('File "'+sqoutsp(fn)+'" didn''t pass integrity test.');
              if (delbad) then begin
                deleteff(rn,pl,TRUE);
                assign(fi,fn);
                {$I-} erase(fi); {$I+}
                if (ioresult<>0) then star('Error erasing "'+sqoutsp(fn)+'"!');
              end;
            end;
          end;
        end;
        nrecno(fn,pl,rn);
        wkey(abort,next);
      end;
      close(ulff);
    end;
    fileboard:=oldboard;
  end;

  procedure cmtfiles(b:integer; fn:astr; var abort,next:boolean);
  var fi:file of byte;
      f:ulfrec;
      oldboard,pl,rn,atype:integer;
      ok:boolean;
  begin
    oldboard:=fileboard;
    if (fileboard<>b) then changefileboard(b);
    if (fileboard=b) then begin
      recno(fn,pl,rn); { loads in memuboard }
      abort:=FALSE; next:=FALSE;
      while (fn<>'') and (rn<>0) and (not abort) and (not hangup) do begin
        seek(ulff,rn); read(ulff,f);
        fn:=memuboard.dlpath+f.filename;
        atype:=arctype(fn);
        if (atype<>0) then begin
          pbn(abort,next); nl;
          star('Commenting "'+sqoutsp(fn)+'"');
          ok:=TRUE;
          if (not exist(fn)) then begin
            star('File "'+sqoutsp(fn)+'" doesn''t exist.');
            ok:=FALSE;
          end
          else arccomment(ok,atype,memuboard.cmttype,sqoutsp(fn));
        end;
        nrecno(fn,pl,rn);
        wkey(abort,next);
      end;
      close(ulff);
    end;
    fileboard:=oldboard;
  end;

  procedure cvtfiles(b:integer; fn:astr; toa:integer;
                     var c_files,c_oldsiz,c_newsiz:longint;
                     var abort,next:boolean);
  var fi:file of byte;
      f:ulfrec;
      s:astr;
      oldboard,pl,rn,atype:integer;
      ok:boolean;
  begin
    oldboard:=fileboard;
    if (fileboard<>b) then changefileboard(b);
    if (fileboard=b) then begin
      recno(fn,pl,rn); { loads in memuboard }
      abort:=FALSE; next:=FALSE;
      while (fn<>'') and (rn<>0) and (not abort) and (not hangup) do begin
        seek(ulff,rn); read(ulff,f);
        fn:=memuboard.dlpath+f.filename;
        atype:=arctype(fn);
        if (atype<>0) and (atype<>toa) then begin
          pbn(abort,next); nl;
          star('Converting "'+sqoutsp(fn)+'"');
          ok:=FALSE;
          if (not exist(fn)) then
            star('File "'+sqoutsp(fn)+'" doesn''t exist.')
          else begin
            ok:=TRUE;
            s:=copy(fn,1,pos('.',fn))+systat.filearcinfo[toa].ext;
            conva(ok,atype,bb,systat.temppath+'1\',sqoutsp(fn),sqoutsp(s));
            if (ok) then begin
              assign(fi,sqoutsp(fn));
              {$I-} reset(fi); {$I+}
              ok:=(ioresult=0);
              if (ok) then begin
                oldsiz:=trunc(filesize(fi));
                close(fi);
              end else
                star('Unable to access "'+sqoutsp(fn)+'"');
              if (ok) then
                if (not exist(sqoutsp(s))) then begin
                  star('Unable to access "'+sqoutsp(s)+'"');
                  sysoplog('Unable to access "'+sqoutsp(s)+'"');
                  ok:=FALSE;
                end;
            end;
            if (ok) then begin
              f.filename:=align(stripname(sqoutsp(s)));
              seek(ulff,rn); write(ulff,f);
              {$I-} erase(fi); {$I+}
              if (ioresult<>0) then begin
                star('Unable to erase "'+sqoutsp(fn)+'"');
                sysoplog('Unable to erase "'+sqoutsp(fn)+'"');
              end;

              assign(fi,sqoutsp(s));
              {$I-} reset(fi); {$I+}
              ok:=(ioresult=0);
              if (not ok) then begin
                star('Unable to access "'+sqoutsp(s)+'"');
                sysoplog('Unable to access "'+sqoutsp(s)+'"');
              end else begin
                newsiz:=trunc(filesize(fi));
                f.blocks:=trunc((filesize(fi)+127.0)/128.0);
                close(fi);
                seek(ulff,rn); write(ulff,f);
              end;

              if (ok) then begin
                inc(c_oldsiz,oldsiz);
                inc(c_newsiz,newsiz);
                inc(c_files);
                star('Old total space took up  : '+cstrl(oldsiz)+' bytes');
                star('New total space taken up : '+cstrl(newsiz)+' bytes');
                if (oldsiz-newsiz>0) then
                  star('Space saved              : '+cstrl(oldsiz-newsiz)+' bytes')
                else
                  star('Space wasted             : '+cstrl(newsiz-oldsiz)+' bytes');
              end;
            end else begin
              sysoplog('Unable to convert "'+sqoutsp(fn)+'"');
              star('Unable to convert "'+sqoutsp(fn)+'"');
            end;
          end;
        end;
        nrecno(fn,pl,rn);
        wkey(abort,next);
      end;
      close(ulff);
    end;
    fileboard:=oldboard;
  end;

begin
  savpause:=(pause in thisuser.ac);
  if (savpause) then thisuser.ac:=thisuser.ac-[pause];
  savflistopt:=thisuser.flistopt; thisuser.flistopt:=0;
  numfl:=0;
  fiscan(pl); { loads in memuboard }
  case cc of
    'A':begin
          nl;
          print('Add file(s) to archive (up to '+cstr(maxfiles)+') -');
          nl;
          print('Archive filename: ');
          prt(':'); mpl(78); input(fn,78);
          if (fn<>'') then begin
            if (pos('.',fn)=0) and (memuboard.arctype<>0) then
              fn:=fn+'.'+systat.filearcinfo[memuboard.arctype].ext;
            fnx:=isul(fn);
            if (not fnx) then fn:=memuboard.dlpath+fn;
            fn:=fexpand(fn); atype:=arctype(fn);
            if (atype=0) then begin
              print('Archive format not supported.');
              listarctypes;
            end else begin
              done:=FALSE; c:='A';
              repeat
                if (c='A') then
                  repeat
                    nl;
                    print('Add files to list - <CR> to end');
                    prt(cstr(numfl)+':'); mpl(70); input(s,70);
                    if s<>'' then begin
                      if pos('.',s)=0 then s:=s+'*.*';
                      addfl(s,isul(s));
                    end;
                  until (s='') or (numfl>=maxfiles) or (hangup);
                nl;
                prt('Add files to list (?=help) : '); onek(c,'QADLR?');
                nl;
                case c of
                  '?':begin
                        lcmds(19,3,'Add more to list','Do it!');
                        lcmds(19,3,'List files in list','Remove files from list');
                        lcmds(19,3,'Quit','');
                      end;
                  'D':begin
                        i:=0;
                        repeat
                          inc(i); j:=1;
                          s2:=sqoutsp(fl[i]);
                          if not isul(s2) then
                            s2:=memuboard.dlpath+s2;
                          s1:=arcmci(systat.filearcinfo[atype].arcline,fn,s2);
                          os1:=s1;
                          while (length(s1)<=maxdoschrline) and (i<numfl) do begin
                            inc(i); inc(j);
                            s2:=sqoutsp(fl[i]);
                            if (not isul(s2)) then
                              s2:=memuboard.dlpath+s2;
                            os1:=s1;
                            s1:=s1+' '+s2;
                          end;
                          if (length(s1)>maxdoschrline) then begin
                            dec(i); dec(j);
                            s1:=os1;
                          end;
                          ok:=TRUE;
                          star('Adding '+cstr(j)+' files to archive...');
                          shel1;
                          execbatch(ok,TRUE,'tgtemp1.bat','tgtemp1.$$$',
                                    systat.temppath+'1\',s1,
                                    systat.filearcinfo[atype].succlevel);
                          shel2;
                          if (not ok) then begin
                            star('Errors in adding files');
                            ok:=pynq('Continue anyway? ');
                            if (hangup) then ok:=FALSE;
                          end;
                        until (i>=numfl) or (not ok);
                        arccomment(ok,atype,memuboard.cmttype,fn);
                        nl;
                        if (not fnx) then begin
                          s2:=stripname(fn);
                          recno(s2,pl,rn);
                          if (rn<>0) then
                            sprint(#3#5+'NOTE: File already exists in listing!');
                          if pynq('Add archive to listing? ') then begin
                            assign(fi,fn);
                            {$I-} reset(fi); {$I+}
                            if ioresult=0 then begin
                              f.blocks:=trunc((filesize(fi)+127.0)/128.0);
                              close(fi);
                            end;
                            f.filename:=s2;
                            ok1:=TRUE;
                            if pynq('Use stats of file in directory? ') then begin
                              repeat
                                nl;
                                prt('Enter filename: '); mpl(12); input(s2,12);
                                recno(s2,pl,rn);
                                if rn=0 then print('File not found!');
                                if s2='' then print('Aborted!');
                              until (rn<>0) or (s2='') or (hangup);
                              if s2<>'' then begin
                                seek(ulff,rn); read(ulff,f1);
                                with f do begin
                                  description:=f1.description;
                                  vpointer:=f1.vpointer;
                                  nacc:=f1.nacc;
                                  ft:=f1.ft;
                                  owner:=f1.owner;
                                  stowner:=f1.stowner;
                                  date:=f1.date;
                                  daten:=f1.daten;
                                end;
                                f1.vpointer:=-1;
                                seek(ulff,rn); write(ulff,f1);
                              end else
                                ok1:=FALSE;
                            end else
                              ok1:=FALSE;

                            if (not ok1) then begin
                              wenttosysop:=FALSE;
                              dodescrs(f,v,pl,wenttosysop);
                              f.nacc:=0;
                              f.ft:=255;
                              f.owner:=usernum;
                              f.stowner:=allcaps(thisuser.name);
                              f.date:=date;
                              f.daten:=daynum(date);
                            end;

                            f.filestat:=[];
                            if (not fso) and (not systat.validateallfiles) then
                              f.filestat:=f.filestat+[notval];

                            if (not systat.fileptratio) then f.filepoints:=0
                            else begin
                              rfpts:=(f.blocks/8)/systat.fileptcompbasesize;
                              f.filepoints:=round(rfpts);
                            end;

                            if (rn=0) then newff(f,v) else writefv(rn,f,v);
                          end;
                        end;
                        if pynq('Delete original files? ') then
                          for i:=1 to numfl do begin
                            s2:=sqoutsp(fl[i]);
                            if not isul(fl[i]) then begin
                              recno(s2,pl,rn);
                              if rn<>0 then deleteff(rn,pl,TRUE);
                              s2:=memuboard.dlpath+s2;
                            end;
                            assign(fi,s2);
                            {$I-} erase(fi); {$I+}
                            if (ioresult<>0) then
                              print('"'+s2+'": Could not delete');
                          end;
                        if ok then done:=TRUE;
                      end;
                  'L':if (numfl=0) then print('No files in list!')
                      else begin
                        abort:=FALSE; next:=FALSE;
                        s:=''; j:=0;
                        i:=0;
                        repeat
                          inc(i);
                          if isul(fl[i]) then s:=s+#3#3 else s:=s+#3#1;
                          s:=s+align(stripname(fl[i]));
                          inc(j);
                          if j<5 then s:=s+'    '
                          else begin
                            printacr(s,abort,next);
                            s:=''; j:=0;
                          end;
                        until (i=numfl) or (abort) or (hangup);
                        if (j in [1..4]) and (not abort) then
                          printacr(s,abort,next);
                      end;
                  'R':begin
                        prt('Remove filename: '); mpl(12); input(s,12);
                        i:=0;
                        repeat
                          inc(i);
                          if align(stripname(fl[i]))=align(s) then begin
                            s1:=sqoutsp(fl[i]); sprompt(#3#3+s1);
                            if pynq('   Remove it? ') then begin
                              for j:=i to numfl-1 do fl[j]:=fl[j+1];
                              dec(numfl); dec(i);
                            end;
                          end;
                        until (i>=numfl);
                      end;
                  'Q':done:=TRUE;
                end;
              until (done) or (hangup);

            end;
          end;
        end;
    'C':begin
          nl;
          print('Convert archive formats -');
          nl;
          print('Filespec:');
          prt(':'); mpl(78); input(fn,78);
          c_files:=0; c_oldsiz:=0; c_newsiz:=0;
          if (fn<>'') then begin
            nl;
            abort:=FALSE; next:=FALSE;
            repeat
              prt('Archive type to use? (?=List) : '); input(s,3);
              if (s='?') then begin nl; listarctypes; nl; end;
            until (s<>'?');
            if (value(s)<>0) then bb:=value(s)
              else bb:=arctype(s+'FILENAME.'+s);
            if (bb<>0) then begin
              sysoplog('Conversion process began at '+date+' '+time+'.');
              if (isul(fn)) then begin
                fsplit(fn,dstr,nstr,estr); s:=dstr;
                findfirst(fn,AnyFile-Directory-VolumeID,dirinfo);
                abort:=FALSE; next:=FALSE;
                while (doserror=0) and (not abort) and (not hangup) do begin
                  fn:=fexpand(sqoutsp(dstr+dirinfo.name));
                  atype:=arctype(fn);
                  if (atype<>0) and (atype<>bb) then begin
                    star('Converting "'+fn+'"');
                    ok:=TRUE;
                    s:=copy(fn,1,pos('.',s))+systat.filearcinfo[bb].ext;
                    conva(ok,atype,bb,systat.temppath+'1\',fn,s);
                    if (ok) then begin
                      assign(fi,sqoutsp(fn));
                      {$I-} reset(fi); {$I+}
                      ok:=(ioresult=0);
                      if (ok) then begin
                        oldsiz:=trunc(filesize(fi));
                        close(fi);
                      end else
                        star('Unable to access "'+sqoutsp(fn)+'"');
                      if (ok) then
                        if (not exist(sqoutsp(s))) then begin
                          star('Unable to access "'+sqoutsp(s)+'"');
                          sysoplog('Unable to access "'+sqoutsp(s)+'"');
                          ok:=FALSE;
                        end;
                    end;
                    if (ok) then begin
                      {$I-} erase(fi); {$I+}
                      if (ioresult<>0) then
                        star('Unable to erase "'+sqoutsp(fn)+'"');

                      assign(fi,sqoutsp(s));
                      {$I-} reset(fi); {$I+}
                      ok:=(ioresult=0);
                      if (ok) then begin
                        newsiz:=trunc(filesize(fi));
                        close(fi);
                      end else
                        star('Unable to access "'+sqoutsp(s)+'"');

                      if (ok) then begin
                        inc(c_oldsiz,oldsiz);
                        inc(c_newsiz,newsiz);
                        inc(c_files);
                        star('Old total space took up  : '+cstrl(oldsiz)+' bytes');
                        star('New total space taken up : '+cstrl(newsiz)+' bytes');
                        if (oldsiz-newsiz>0) then
                          star('Space saved              : '+cstrl(oldsiz-newsiz)+' bytes')
                        else
                          star('Space wasted             : '+cstrl(newsiz-oldsiz)+' bytes');
                      end;
                    end else begin
                      sysoplog('Unable to convert "'+sqoutsp(fn)+'"');
                      star('Unable to convert "'+sqoutsp(fn)+'"');
                    end;
                  end;
                  findnext(dirinfo);
                  wkey(abort,next);
                end;
{                if (abort) then sprint('@M'+#3#7+'Conversion aborted.');}
              end else begin
                ok1:=pynq('Search all directories? ');
                nl;
                if (ok1) then begin
                  i:=0; abort:=FALSE; next:=FALSE;
                  while (not abort) and (i<=maxulb) and (not hangup) do begin
                    if (fbaseac(i)) then
                      cvtfiles(i,fn,bb,c_files,c_oldsiz,c_newsiz,abort,next);
                    inc(i);
                    wkey(abort,next);
                    if (next) then abort:=FALSE;
                  end;
                end else
                  cvtfiles(fileboard,fn,bb,c_files,c_oldsiz,c_newsiz,
                           abort,next);
                reset(ulff);
              end;
              sysoplog('Conversion process ended at '+date+' '+time+'.');
              nl;
              nl;
              star('Total archives converted : '+cstr(c_files));
              star('Old total space took up  : '+cstrl(c_oldsiz)+' bytes');
              star('New total space taken up : '+cstrl(c_newsiz)+' bytes');
              if (c_oldsiz-c_newsiz>0) then
                star('Space saved              : '+cstrl(c_oldsiz-c_newsiz)+' bytes')
              else
                star('Space wasted             : '+cstrl(c_newsiz-c_oldsiz)+' bytes');
              sysoplog('Converted '+cstr(c_files)+' archives; old size='+
                       cstrl(c_oldsiz)+' bytes, new size='+cstrl(c_newsiz)+' bytes');
            end;
          end;
        end;
    'M':begin
          nl;
          print('Comment field update -');
          nl;
          print('Filespec:');
          prt(':'); mpl(78); input(fn,78);
          if (fn<>'') then begin
            nl;
            abort:=FALSE; next:=FALSE;
            if (isul(fn)) then begin
              prt('Comment type to use? (1-3,0=None) [1] : ');
              ini(bb);
              if (badini) then bb:=1;
              if (bb<0) or (bb>3) then bb:=1;
              fsplit(fn,dstr,nstr,estr); s:=dstr;
              findfirst(fn,AnyFile-Directory-VolumeID,dirinfo);
              abort:=FALSE; next:=FALSE;
              while (doserror=0) and (not abort) and (not hangup) do begin
                fn:=fexpand(sqoutsp(dstr+dirinfo.name));
                atype:=arctype(fn);
                if (atype<>0) then begin
                  star('Commenting "'+fn+'"');
                  ok:=TRUE;
                  arccomment(ok,atype,bb,fn);
                end;
                findnext(dirinfo);
                wkey(abort,next);
              end;
{              if (abort) then sprint('@M'+#3#7+'Comment update aborted.');}
            end else begin
              ok1:=pynq('Search all directories? ');
              nl;
              if (ok1) then begin
                i:=0; abort:=FALSE; next:=FALSE;
                while (not abort) and (i<=maxulb) and (not hangup) do begin
                  if (fbaseac(i)) then cmtfiles(i,fn,abort,next);
                  inc(i);
                  wkey(abort,next);
                  if (next) then abort:=FALSE;
                end;
              end else
                cmtfiles(fileboard,fn,abort,next);
              reset(ulff);
            end;
          end;
        end;
    'T':begin
          nl;
          print('File integrity testing -');
          nl;
          print('Filespec:');
          prt(':'); mpl(78); input(fn,78);
          if (fn<>'') then begin
            nl;
            delbad:=pynq('Delete files that don''t pass the test? ');
            nl;
            abort:=FALSE; next:=FALSE;
            if (isul(fn)) then begin
              fsplit(fn,dstr,nstr,estr); s:=dstr;
              findfirst(fn,AnyFile-Directory-VolumeID,dirinfo);
              abort:=FALSE; next:=FALSE;
              while (doserror=0) and (not abort) and (not hangup) do begin
                fn:=fexpand(sqoutsp(dstr+dirinfo.name));
                atype:=arctype(fn);
                if (atype<>0) then begin
                  star('Testing "'+fn+'"');
                  ok:=TRUE;
                  arcintegritytest(ok,atype,fn);
                  if (not ok) then begin
                    star('File "'+fn+'" didn''t pass integrity test.');
                    if (delbad) then begin
                      assign(fi,fn);
                      {$I-} erase(fi); {$I+}
                      if (ioresult<>0) then star('Error erasing "'+fn+'"!');
                    end;
                  end;
                end;
                findnext(dirinfo);
                wkey(abort,next);
              end;
{              if (abort) then sprint('@M'+#3#7+'Integrity testing aborted.');}
            end else begin
              ok1:=pynq('Search all directories? ');
              nl;
              if (ok1) then begin
                i:=0; abort:=FALSE; next:=FALSE;
                while (not abort) and (i<=maxulb) and (not hangup) do begin
                  if (fbaseac(i)) then testfiles(i,fn,delbad,abort,next);
                  inc(i);
                  wkey(abort,next);
                  if (next) then abort:=FALSE;
                end;
              end else
                testfiles(fileboard,fn,delbad,abort,next);
              reset(ulff);
            end;
          end;
        end;
    'X':begin {* extract *}
        end;
  end;
  close(ulff);
  thisuser.flistopt:=savflistopt;
  if (savpause) then thisuser.ac:=thisuser.ac+[pause];
end;

end.
