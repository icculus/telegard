{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit file5;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common,
  sysop4,
  file0, file1, file2, file4, file8, file9, file11,
  execbat;

procedure minidos;
procedure browse;
procedure uploadall;

implementation

uses archive1;

var
  xword:array[1..9] of astr;

procedure parse(s:astr);
var i,j,k:integer;
begin
  for i:=1 to 9 do xword[i]:='';
  i:=1; j:=1; k:=1;
  if (length(s)=1) then xword[1]:=s;
  while (i<length(s)) do begin
    inc(i);
    if ((s[i]=' ') or (length(s)=i)) then begin
      if (length(s)=i) then inc(i);
      xword[k]:=copy(s,j,(i-j));
      j:=i+1;
      inc(k);
    end;
  end;
end;

procedure minidos;
var curdir,s,s1:astr;
    abort,next,done,restr,nocmd,nospace:boolean;

  procedure versioninfo;
  begin
    nl;
    print('Telegard(R) Mini-DOS(R)  Version '+ver);
    print('            (C)Copyright 1988,89,90 The Telegard Team');
    nl;
  end;

  procedure docmd(cmd:astr);
  var fi:file of byte;
      f:file;
      ps,ns,es,op,np:astr;
      s1,s2,s3:astr;
      numfiles,tsiz:longint;
      retlevel,i,j:integer;
      b,ok,wasrestr:boolean;

    function restr1:boolean;
    begin
      restr1:=restr;
      if (restr) then wasrestr:=TRUE;
    end;

  begin
    wasrestr:=FALSE;
    abort:=FALSE; next:=FALSE; nocmd:=FALSE;
    for i:=1 to 9 do xword[i]:=allcaps(xword[i]);
    s:=xword[1];
    {rcg11242000 DOSism.}
    {if ((pos('\',xword[2])<>0) or (pos('..',xword[2])<>0)) and}
    if ((pos('/',xword[2])<>0) or (pos('..',xword[2])<>0)) and
       (restr) then exit;

    if (s='DIR/W') then s:='DIR *.* /W';
    if (s='?') or (s='HELP') then printf('minidos')
    else
    if (s='EDIT') or (s='EDLIN') then begin
      if ((exist(xword[2])) and (xword[2]<>'')) then tedit(xword[2])
      else
        if (xword[2]='') then tedit1 else tedit(xword[2]);
    end
    else
    if (s='EXIT') or (s='QUIT') then done:=TRUE
    else
    if ((s='DEL') or (s='DELETE')) and (not restr1) then begin
      if ((not exist(xword[2])) and (not iswildcard(xword[2]))) or
         (xword[2]='') then
        print('File not found.')
      else begin
        xword[2]:=fexpand(xword[2]);
        ffile(xword[2]);
        repeat
          if not ((dirinfo.attr and VolumeID=VolumeID) or
                  (dirinfo.attr and Directory=Directory)) then begin
            assign(f,dirinfo.name);
            {$I-} erase(f); {$I+}
            if (ioresult<>0) then
              print('"'+dirinfo.name+'": Could not delete!');
          end;
          nfile;
        until (not found) or (hangup);
      end;
    end
    else
    if (s='TYPE') then begin
      printf(fexpand(xword[2]));
      if (nofile) then print('File not found.');
    end
    else
    if ((s='REN') or (s='RENAME')) then begin
      if ((not exist(xword[2])) and (xword[2]<>'')) then
        print('File not found.')
      else begin
        xword[2]:=fexpand(xword[2]);
        assign(f,xword[2]);
        {$I-} rename(f,xword[3]); {$I+}
        if (ioresult<>0) then print('File not found.');
      end
    end
    else
    if (s='DIR') then begin
      b:=TRUE;
      for i:=2 to 9 do if (xword[i]='/W') then begin
        b:=FALSE;
        xword[i]:='';
      end;
      if (xword[2]='') then xword[2]:='*.*';
      s1:=curdir;
      xword[2]:=fexpand(xword[2]);
      fsplit(xword[2],ps,ns,es);
      s1:=ps; s2:=ns+es;
      if (s2='') then s2:='*.*';
      if (not iswildcard(xword[2])) then begin
        ffile(xword[2]);
        {rcg11242000 DOSism.}
        (*if ((found) and (dirinfo.attr=directory)) or
           ((length(s1)=3) and (s1[3]='\')) then begin   {* root directory *}*)
        if (((found) and (dirinfo.attr=directory)) or
           (s1[1]='/')) then begin   {* root directory *}
          s1:=bslash(TRUE,xword[2]);
          s2:='*.*';
        end;
      end;
      nl; dir(s1,s2,b); nl;
    end
    else
    if ((s='CD') or (s='CHDIR')) and (xword[2]<>'') and (not restr1) then begin
      xword[2]:=fexpand(xword[2]);
      {$I-} chdir(xword[2]); {$I+}
      if (ioresult<>0) then print('Invalid pathname.');
    end
    else
    if ((s='MD') or (s='MKDIR')) and (xword[2]<>'') and (not restr1) then begin
      {$I-} mkdir(xword[2]); {$I+}
      if (ioresult<>0) then print('Unable to create directory.');
    end
    else
    if ((s='RD') or (s='RMDIR')) and (xword[2]<>'') and (not restr1) then begin
      {$I-} rmdir(xword[2]); {$I+}
      if (ioresult<>0) then print('Unable to remove directory.');
    end
    else
    if (s='COPY') and (not restr1) then begin
      if (xword[2]<>'') then begin
        if (iswildcard(xword[3])) then
          print('Wildcards not allowed in destination parameter!')
        else begin
          if (xword[3]='') then xword[3]:=curdir;
          xword[2]:=bslash(FALSE,fexpand(xword[2]));
          xword[3]:=fexpand(xword[3]);
          ffile(xword[3]);
          b:=((found) and (dirinfo.attr and directory=directory));

{rcg11242000 !!! Look at this. }
          if ((not b) and (copy(xword[3],2,2)=':\') and
              (length(xword[3])=3)) then b:=TRUE;

          fsplit(xword[2],op,ns,es);
          op:=bslash(TRUE,op);

          if (b) then
            np:=bslash(TRUE,xword[3])
          else begin
            fsplit(xword[3],np,ns,es);
            np:=bslash(TRUE,np);
          end;

          j:=0;
          abort:=FALSE; next:=FALSE;
          ffile(xword[2]);
          while (found) and (not abort) and (not hangup) do begin
            if (not ((dirinfo.attr=directory) or (dirinfo.attr=volumeid))) then
            begin
              s1:=op+dirinfo.name;
              if (b) then s2:=np+dirinfo.name else s2:=np+ns+es;
              prompt(s1+' -> '+s2+' :');
              copyfile(ok,nospace,TRUE,s1,s2);
              if (ok) then begin
                inc(j);
                nl;
              end else
                if (nospace) then sprompt(#3#7+' - *Insufficient space*')
                else sprompt(#3#7+' - *Copy failed*');
              nl;
            end;
            if (not empty) then wkey(abort,next);
            nfile;
          end;
          if (j<>0) then begin
            prompt('  '+cstr(j)+' file');
            if (j<>1) then prompt('s');
            print(' copied.');
          end;
        end;
      end;
    end
    else
    if (s='MOVE') and (not restr1) then begin
      if (xword[2]<>'') then begin
        if (iswildcard(xword[3])) then
          print('Wildcards not allowed in destination parameter!')
        else begin
          if (xword[3]='') then xword[3]:=curdir;
          xword[2]:=bslash(FALSE,fexpand(xword[2]));
          xword[3]:=fexpand(xword[3]);
          ffile(xword[3]);
          b:=((found) and (dirinfo.attr and directory=directory));

{rcg11242000 !!! Look at this. }
          if ((not b) and (copy(xword[3],2,2)=':\') and
              (length(xword[3])=3)) then b:=TRUE;

          fsplit(xword[2],op,ns,es);
          op:=bslash(TRUE,op);

          if (b) then
            np:=bslash(TRUE,xword[3])
          else begin
            fsplit(xword[3],np,ns,es);
            np:=bslash(TRUE,np);
          end;

          j:=0;
          abort:=FALSE; next:=FALSE;
          ffile(xword[2]);
          while (found) and (not abort) and (not hangup) do begin
            if (not ((dirinfo.attr=directory) or (dirinfo.attr=volumeid))) then
            begin
              s1:=op+dirinfo.name;
              if (b) then s2:=np+dirinfo.name else s2:=np+ns+es;
              prompt(s1+' -> '+s2+' :');
              movefile(ok,nospace,TRUE,s1,s2);
              if (ok) then begin
                inc(j);
                nl;
              end else
                if (nospace) then sprompt(#3#7+' - *Insufficient space*')
                else sprompt(#3#7+' - *Move failed*');
              nl;
            end;
            if (not empty) then wkey(abort,next);
            nfile;
          end;
          if (j<>0) then begin
            prompt('  '+cstr(j)+' file');
            if (j<>1) then prompt('s');
            print(' moved.');
          end;
        end;
      end;
    end
    else
    if (s='CLS') then cls
    else
    if (length(s)=2) and (s[1]>='A') and (s[1]<='Z') and
       (s[2]=':') and (not restr1) then begin
      {$I-} getdir(ord(s[1])-64,s1); {$I+}
      if (ioresult<>0) then print('Invalid drive.')
      else begin
        {$I-} chdir(s1); {$I+}
        if (ioresult<>0) then begin
          print('Invalid drive.');
          chdir(curdir);
        end;
      end;
    end
    else
    if (s='IFL') then begin
      if (xword[2]='') then begin
(*
        nl;
        print('IFL v1.30 - May 09 1989 - Interior File Listing Utility');
        print('Copyright 1989 by Martin Pollard.  All rights reserved!');
        print('Licensed for internal usage in Telegard v'+ver);
*)
        nl;
        print('Syntax is:   "IFL filename"');
        nl;
(*
        print('IFL produces a listing of files contained in an archive file.');
        print('Archive formats currently supported include:');
        nl;
        print('   ARC - Developed by System Enhancement Associates');
        print('            and enhanced by PKware (PKARC & PKPAK)');
        print('            and NoGate Consulting (PAK)');
        print('   LZH - Developed by Haruyasu Yoshizaki');
        print('   ZIP - Developed by PKware');
        print('   ZOO - Developed by Rahul Dhesi');
        nl;
        print('Support for other formats may be included in the future.');
        nl;
*)
      end else begin
        s1:=xword[2];
        if (pos('.',s1)=0) then s1:=s1+'*.*';
        lfi(s1,abort,next);
      end;
    end
    else
    if (s='SEND') and (xword[2]<>'') then begin
      if exist(xword[2]) then unlisted_download(fexpand(xword[2]))
        else print('File not found.');
    end
    else
    if (s='VER') then versioninfo
    else
    if (s='FORMAT') then begin
      nl;
      print('HA HA HA - Very funny - You must be dumber than you look.');
      nl;
    end else
    if (s='DIRSIZE') then begin
      nl;
      if (xword[2]='') then print('Needs a parameter.')
      else begin
        numfiles:=0; tsiz:=0;
        ffile(xword[2]);
        while (found) do begin
          inc(tsiz,dirinfo.size);
          inc(numfiles);
          nfile;
        end;
        if (numfiles=0) then print('No files found!')
          else print('"'+allcaps(xword[2])+'": '+cstrl(numfiles)+' files, '+
                     cstrl(tsiz)+' bytes.');
      end;
      nl;
    end
    else
    if (s='DISKFREE') then begin
      if (xword[2]='') then j:=exdrv(curdir) else j:=exdrv(xword[2]);
      nl;
      print(cstrl(freek(j)*1024)+' bytes free on '+chr(j+64)+':');
      nl;
    end
    else
    if (s='EXT') and (not restr1) then begin
      s1:=cmd;
      j:=pos('EXT',allcaps(s1))+3; s1:=copy(s1,j,length(s1)-(j-1));
      while (copy(s1,1,1)=' ') do s1:=copy(s1,2,length(s1)-1);
      if ((incom) or (outcom)) then
        s1:=s1+' >'+systat.remdevice+' <'+systat.remdevice;
      if (length(s1)>127) then begin nl; print('Command too long!'); nl; end
      else
        shelldos(TRUE,s1,retlevel);
    end
    else
    if ((s='CONVERT') or (s='CVT')) and (not restr1) then begin
      if (xword[2]='') then begin
        nl;
        print(s+' - Telegard archive conversion command.');
        nl;
        print('Syntax is:   "'+s+' <Old Archive-name> <New Archive-extension>"');
        nl;
        print('Telegard will convert from the one archive format to the other.');
        print('You only need to specify the 3-letter extension of the new format.');
        nl;
      end else begin
        if (not exist(xword[2])) or (xword[2]='') then print('File not found.')
        else begin
          i:=arctype(xword[2]);
          if (i=0) then invarc
          else begin
            s3:=xword[3]; s3:=copy(s3,length(s3)-2,3);
            j:=arctype('FILENAME.'+s3);
            fsplit(xword[2],ps,ns,es);
            if (length(xword[3])<=3) and (j<>0) then
              s3:=ps+ns+'.'+systat.filearcinfo[j].ext
            else
              s3:=xword[3];
            if (j=0) then invarc
            else begin
              ok:=TRUE;
              {rcg11242000 DOSism.}
              {
	      conva(ok,i,j,systat.temppath+'1\',sqoutsp(fexpand(xword[2])),
                    sqoutsp(fexpand(s3)));
              }
              conva(ok,i,j,systat.temppath+'1/',sqoutsp(fexpand(xword[2])),
                    sqoutsp(fexpand(s3)));
              if (ok) then begin
                assign(fi,sqoutsp(fexpand(xword[2])));
                {$I-} erase(fi); {$I+}
                if (ioresult<>0) then
                  star('Unable to delete original: "'+
                       sqoutsp(fexpand(xword[2]))+'"');
              end else
                star('Conversion unsuccessful.');
            end;
          end;
        end;
      end;
    end else
    if ((s='UNARC') or (s='UNZIP') or
       (s='PKXARC') or (s='PKUNPAK') or (s='PKUNZIP')) and (not restr1) then begin
      if (xword[2]='') then begin
        nl;
        print(s+' - Telegard archive de-compression command.');
        nl;
        print('Syntax is:   "'+s+' <Archive-name> Archive filespecs..."');
        nl;
        print('The archive type can be ANY archive format which has been');
        print('configured into Telegard via System Configuration.');
        nl;
      end else begin
        i:=arctype(xword[2]);
        if (not exist(xword[2])) then print('File not found.') else
          if (i=0) then invarc
          else begin
            s3:='';
            if (xword[3]='') then s3:=' *.*'
            else
              for j:=3 to 9 do
                if (xword[j]<>'') then s3:=s3+' '+fexpand(xword[j]);
            s3:=copy(s3,2,length(s3)-1);
            shel1;
            pexecbatch(TRUE,'tgtemp1.bat','',bslash(TRUE,curdir),
                       arcmci(systat.filearcinfo[i].unarcline,fexpand(xword[2]),s3),
                       retlevel);
            shel2;
          end;
      end;
    end
    else
    if ((s='ARC') or (s='ZIP') or
       (s='PKARC') or (s='PKPAK') or (s='PKZIP')) and (not restr1) then begin
      if (xword[2]='') then begin
        nl;
        print(s+' - Telegard archive compression command.');
        nl;
        print('Syntax is:   "'+s+' <Archive-name> Archive filespecs..."');
        nl;
        print('The archive type can be ANY archive format which has been');
        print('configured into Telegard via System Configuration.');
        nl;
      end else begin
        i:=arctype(xword[2]);
        if (i=0) then invarc
        else begin
          s3:='';
          if (xword[3]='') then s3:=' *.*'
          else
            for j:=3 to 9 do
              if (xword[j]<>'') then s3:=s3+' '+fexpand(xword[j]);
          s3:=copy(s3,2,length(s3)-1);
          shel1;
          pexecbatch(TRUE,'tgtemp1.bat','',bslash(TRUE,curdir),
                     arcmci(systat.filearcinfo[i].arcline,fexpand(xword[2]),s3),
                     retlevel);
          shel2;
        end;
      end;
    end else begin
      nocmd:=TRUE;
      if (s<>'') then
        if (not wasrestr) then print('Bad command or file name')
        else print('Restricted command.');
    end;
  end;

begin
  chdir(bslash(FALSE,systat.afilepath));
  restr:=(not cso);
  done:=FALSE;
  nl;
  print('Type "EXIT" to return to Telegard.');
  nl;
  versioninfo;
  if (restr) then begin
    print('Only *.MSG, *.ANS, *.40C and *.TXT files may be modified.');
    print('Activity restricted to "'+systat.afilepath+'" path only.');
    nl;
  end;
  repeat
    getdir(0,curdir);
    prompt('<'+curdir+'> '); inputl(s1,128); parse(s1);
    docmd(s1);
    if (not nocmd) then sysoplog('> '+s1);
  until (done) or (hangup);
  chdir(start_dir);
end;

procedure browse;
const perpage=15;
var f:ulfrec;
    filenum:array[1..20] of integer;
    s:astr;
    i,a1,a2,numadd,pl,topp,otopp,savflistopt:integer;
    c:char;
    abort,next,done,done1,showlist:boolean;

  procedure listpage;
  begin
    abort:=FALSE; next:=FALSE;
    if (topp>pl) then topp:=otopp;
    otopp:=topp;
    bnp:=FALSE;
    while (topp-otopp<perpage) and (topp<=pl) and
          (not abort) and (not hangup) do begin
      if (topp<=pl) then begin
        seek(ulff,topp); read(ulff,f);
        pbn(abort,next);
        pfn(topp,f,abort,next);
      end;
      inc(topp);
    end;
  end;

begin
  fiscan(pl);  { loads memuboard }
  nl;
  sprint(#3#5+memuboard.name+#3#4+' - '+cstr(pl)+' files');
  if (pl=0) then exit;
  nl;
  prt('Start at (1-'+cstr(pl)+',Q=Quit) : '); inu(topp);
  if (badini) then topp:=1;
  if ((topp<1) or (topp>pl)) then exit;

  done:=FALSE; showlist:=TRUE; otopp:=topp;
  savflistopt:=thisuser.flistopt; thisuser.flistopt:=30;
  repeat
    if (showlist) then listpage;
    showlist:=FALSE; abort:=FALSE; next:=FALSE;
    nl;
    prt(#3#5+'['+cstr(topp)+']'+#3#4+' Browse files (1-'+cstr(pl)+',?=help) : ');
    input(s,4);
    if ((value(s)>=1) and (value(s)<=pl)) then begin
      nl;
      seek(ulff,value(s)); read(ulff,f);
      fileinfo(f,FALSE,abort,next);
      s:='xxxx';
    end;
    if (length(s)>=1) then c:=s[1] else c:=^M;
    i:=value(copy(s,2,length(s)-1));
    case c of
      '?':begin
            nl;
            print('###:File description');
            lcmds(9,3,'Download','-Back up a page');
            lcmds(9,3,'Jump','List or <CR> for next page');
            lcmds(9,3,'Upload','Numbered download');
            lcmds(9,3,'Quit','View interior');
          end;
   'L',^M:showlist:=TRUE;  {* do nothing *}
      'B','-':begin
            dec(topp,perpage*2);
            if (topp<1) then topp:=1;
            showlist:=TRUE;
          end;
      'D':if ((i>=1) and (i<=pl)) then begin
            seek(ulff,i); read(ulff,f);
            abort:=FALSE;
            dlx(f,i,abort);
          end else begin
            idl;
            fiscan(pl);
          end;
      'J':begin
            if ((i<1) or (i>pl)) then begin
              i:=0;
              nl; prt('Goto which file? (1-'+cstr(pl)+') : '); inu(i);
              if (badini) then i:=0;
            end;
            if (i>=1) and (i<=pl) then topp:=i;
            showlist:=TRUE;
          end;
      'N':begin
            if (i>=1) and (i<=pl) then begin
              filenum[1]:=i;
              numadd:=1;
            end else begin
              nl;
              print('Numbered download.');
              print('Enter single file number, or multiple file numbers');
              print('seperated by commas, max 20.');
              prt(':'); input(s,78);
              done1:=FALSE; numadd:=0;
              if (s<>'') then
                repeat
                  if ((value(s)>=1) and (value(s)<=filesize(ulff)-1)) then begin
                    inc(numadd); filenum[numadd]:=value(s);
                  end;
                  if (pos(',',s)=0) then done1:=TRUE
                    else s:=copy(s,pos(',',s)+1,length(s)-pos(',',s));
                until (done1) or (numadd=20);
            end;
            done1:=FALSE;
            if (numadd=1) then begin
              seek(ulff,filenum[1]); read(ulff,f);
              nl;
              if (okdl(f)) then
                if (pynq('Download immediately? ')) then begin
                  seek(ulff,filenum[1]); read(ulff,f);
                  abort:=FALSE;
                  dlx(f,filenum[1],abort);
                  done1:=TRUE;
                end;
            end;
            if (not done1) then begin
              nl;
              print('File list:');
              for i:=1 to numadd do begin
                seek(ulff,filenum[i]); read(ulff,f);
                print('  '+sqoutsp(f.filename));
              end;
              nl;
              if pynq('Add these files to your batch queue? ') then begin
                a2:=0;
                for i:=1 to numadd do begin
                  seek(ulff,filenum[i]); read(ulff,f);
                  a1:=numbatchfiles;
                  if (okdl(f)) then ymbadd(memuboard.dlpath+f.filename);
                  if (numbatchfiles<>a1) then inc(a2);
                end;
                nl;
                print(cstr(a2)+' files added to batch queue.');
              end;
            end;
          end;
      'U':begin
            iul;
            fiscan(pl);
          end;
      'V':begin
            if (i>=1) and (i<=pl) then begin
              abort:=FALSE; next:=FALSE;
              lfin(i,abort,next);
            end
            else lfii;
            fiscan(pl);
          end;
      'Q':done:=TRUE;
    end;
  until (done) or (hangup);
  close(ulff);
  thisuser.flistopt:=savflistopt;
end;

procedure uploadall;
var bn,savflistopt:integer;
    abort,next,sall:boolean;

  procedure uploadfiles(b:integer; var abort,next:boolean);
  var fi:file of byte;
      f:ulfrec;
      v:verbrec;
      fn:astr;
      convtime:real;
      oldboard,pl,rn,gotpts,i:integer;
      c:char;
      ok,convt,firstone:boolean;
  begin
    oldboard:=fileboard;
    firstone:=TRUE;
    if (fileboard<>b) then changefileboard(b);
    if (fileboard=b) then begin
      loaduboard(fileboard);
      nl;
      sprint('Scanning '+#3#5+memuboard.name+#3#1+' ('+memuboard.dlpath+')');
      ffile(memuboard.dlpath+'*.*');
      while (found) do begin
        if not ((dirinfo.attr and VolumeID=VolumeID) or
                (dirinfo.attr and Directory=Directory)) then begin
          fn:=align(dirinfo.name);
          recno(fn,pl,rn); { loads memuboard again .. }
          if (rn=0) then begin
            assign(fi,memuboard.dlpath+fn);
            {$I-} reset(fi); {$I+}
            if (ioresult=0) then begin
              f.blocks:=trunc((filesize(fi)+127.0)/128.0);
              close(fi);
              if (firstone) then pbn(abort,next);
              firstone:=FALSE;
              sprompt(' '+#3#3+fn+' '+#3#4+mln(cstr(f.blocks div 8),3)+' New:');
              cl(5); inputl(f.description,60);
              ok:=TRUE;
              if (copy(f.description,1,1)='.') then begin
                if (length(f.description)=1) then begin
                  abort:=TRUE;
                  exit;
                end;
                c:=upcase(f.description[2]);
                case c of
                  'D':begin
                        {$I-} erase(fi); {$I+} i:=ioresult;
                        ok:=FALSE;
                      end;
                  'N':begin
                        next:=TRUE;
                        exit;
                      end;
                  'S':ok:=FALSE;
                end;
              end;
              if (ok) then begin
                v.descr[1]:='';
                if (copy(f.description,1,1)='\') then begin
                  f.description:=copy(f.description,2,length(f.description)-1);
                  nl;
                  print('You may use up to four lines of 50 characters each.');
                  print('Enter a blank line to end.');
                  nl;
                  i:=1;
                  repeat
                    prt(cstr(i)+':');
                    mpl(50);
                    inputl(v.descr[i],50);
                    if (v.descr[i]='') then i:=4;
                    inc(i);
                  until ((i=5) or (hangup));
                  if (v.descr[1]<>'') then f.vpointer:=nfvpointer
                  else begin
                    nl; print('No verbose description saved.');
                  end;
                  nl;
                end;
                if (v.descr[1]='') then f.vpointer:=-1;
(*                arcstuff(ok,convt,f.blocks,convtime,FALSE,uboards[fileboard]^.dlpath,fn);*)
                doffstuff(f,fn,gotpts);
                if (ok) then begin
                  newff(f,v);
                  sysoplog(#3#3+'Upload "'+sqoutsp(fn)+'" on '+memuboard.name);
                end;
              end;
            end;
          end;
        end;
        nfile;
      end;
    end;
    fileboard:=oldboard;
  end;

begin
  savflistopt:=thisuser.flistopt; thisuser.flistopt:=1;
  nl; print('Upload files into directories -'); nl;
  abort:=FALSE; next:=FALSE;
  sall:=pynq('Search all directories? ');
  nl;
  print('Enter a single "\" in front of description to enter a verbose');
  print('description too.  Enter "." to stop uploading, ".S" to skip this file,');
  print('".N" to skip to the next directory, and ".D" to delete this file.');
  if (sall) then begin
    bn:=0;
    while (not abort) and (bn<=maxulb) and (not hangup) do begin
      if (fbaseac(bn)) then uploadfiles(bn,abort,next);
      inc(bn);
      wkey(abort,next);
      if (next) then abort:=FALSE;
    end;
  end else
    uploadfiles(fileboard,abort,next);
  thisuser.flistopt:=savflistopt;
end;

end.
