(*****************************************************************************)
(*>                                                                         <*)
(*>  SYSOP9  .PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  SysOp functions: File base editor                                      <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit sysop9;

interface

procedure dlboardedit;

implementation

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common,
  file0, file2,
  sysop1, sysop8;

var zc:integer;

procedure fbase_del(var zscanr1:zscanrec; x,y:integer);
begin
  for zc:=x to maxulb-1 do
    if (zc+1 in zscanr1.fzscan) then zscanr1.fzscan:=zscanr1.fzscan+[zc]
                                else zscanr1.fzscan:=zscanr1.fzscan-[zc];
  zscanr1.mzscan:=zscanr1.mzscan+[maxulb];
end;

procedure fbase_ins(var zscanr1:zscanrec; x,y:integer);
begin
  for zc:=numboards downto x+1 do
    if (zc-1 in zscanr1.fzscan) then zscanr1.fzscan:=zscanr1.fzscan+[zc]
                                else zscanr1.fzscan:=zscanr1.fzscan-[zc];
  zscanr1.fzscan:=zscanr1.fzscan+[x];
end;

procedure fbase_pos(var zscanr1:zscanrec; x,y:integer);
var s_fzscan:boolean;
    i,j,k:integer;
begin
  s_fzscan:=(x in zscanr1.fzscan);
  i:=x; if (x>y) then j:=-1 else j:=1;
  while (i<>y) do begin
    if (i+j in zscanr1.fzscan) then zscanr1.fzscan:=zscanr1.fzscan+[i]
                               else zscanr1.fzscan:=zscanr1.fzscan-[i];
    inc(i,j);
  end;
  if (s_fzscan) then zscanr1.fzscan:=zscanr1.fzscan+[y]
                else zscanr1.fzscan:=zscanr1.fzscan-[y];
(*
            y   x
          012345678901234567890
   (k) 1> xx*==*Oxxx...........
          xx.*==*xxx...........
   (j) 2> xxO*==*xxx...........

            x   y
          012345678901234567890
   (k) 1> xxOxxxxxxx...........
   (j) 2> xxxxxxOxxx...........

           y  x         x  y
          0123456      0123456
          XxxxOXX      XOxxxXX
          X.xxxXX      Xxxx.XX
          XOxxxXX      XxxxOXX
          0312456      0231456

*)
end;

procedure dlboardedit;
const ltype:integer=1;
var i1,ii,culb,i2:integer;
    c:char;
    s0:astr;
    f:file;
    abort,next,done:boolean;

  function newindexno:longint;
  var ubrd:ulrec;
      i,j:integer;
  begin
    reset(ulf);
    j:=-1;
    for i:=0 to filesize(ulf)-1 do begin
      read(ulf,ubrd);
      if (ubrd.permindx>j) then j:=ubrd.permindx;
    end;
    inc(j);
    newindexno:=j;
  end;

  procedure dlbed(x:integer);
  var i,j:integer;
  begin
    if ((x>=0) and (x<=maxulb)) then begin
      i:=x; {-1;}
      if (i>=0) and (i<=filesize(ulf)-2) then
        for j:=i to filesize(ulf)-2 do begin
          seek(ulf,j+1); read(ulf,memuboard);
          seek(ulf,j); write(ulf,memuboard);
        end;
      seek(ulf,filesize(ulf)-1); truncate(ulf);
      dec(maxulb);
      dozscanfunc(fbase_del,x,0);
    end;
  end;

  procedure dlbei(x:integer);
  var s:string;
      i,j,k:integer;
  begin
    i:=x; {-1;}
    if ((i>=0) and (i<=filesize(ulf)) and (maxulb<maxuboards)) then begin
      for j:=filesize(ulf)-1 downto i do begin
        seek(ulf,j); read(ulf,memuboard);
        write(ulf,memuboard); { ...to next record }
      end;
      with memuboard do begin
        getdir(0,s);
        name:='<< Not Used >>';
        filename:='NEWDIR';
        dlpath:=s[1]+':DLOADS\';
        ulpath:=dlpath;
        maxfiles:=2000;
        password:='';
        arctype:=1; cmttype:=1;
        fbdepth:=0;
        fbstat:=[];
        acs:='';
        ulacs:='';
        nameacs:='';
        permindx:=newindexno;
        for k:=1 to 6 do res[k]:=0;
      end;
      seek(ulf,i); write(ulf,memuboard);
      inc(maxulb);

      dozscanfunc(fbase_ins,x,0);
    end;
  end;

  procedure dlbep(x,y:integer);
  var tempuboard:ulrec;
      i,j,k:integer;
  begin
    k:=y; if (y>x) then dec(y);
{    dec(x); dec(y);}
    seek(ulf,x); read(ulf,tempuboard);
    i:=x; if (x>y) then j:=-1 else j:=1;
    while (i<>y) do begin
      if (i+j<filesize(ulf)) then begin
        seek(ulf,i+j); read(ulf,memuboard);
        seek(ulf,i); write(ulf,memuboard);
      end;
      inc(i,j);
    end;
    seek(ulf,y); write(ulf,tempuboard);
{    inc(x); inc(y);} {y:=k;}

    dozscanfunc(fbase_pos,x,y);
  end;

  function samulpath(dl,ul:astr):astr;
  begin
    if (dl<>ul) then samulpath:=ul else samulpath:='Same';
  end;

  function flagstate(fb:ulrec):astr;
  var s:astr;
  begin
    s:='';
    with fb do begin
      if (fbisdir in fbstat) then s:=s+'D' else s:=s+'-';
      if (fbusegifspecs in fbstat) then s:=s+'G' else s:=s+'-';
      if (fbdirdlpath in fbstat) then s:=s+'I' else s:=s+'-';
      if (fbnoratio in fbstat) then s:=s+'N' else s:=s+'-';
      if (fbunhidden in fbstat) then s:=s+'U' else s:=s+'-';
    end;
    flagstate:=s;
  end;

  procedure getdirspec(var s:string);
  begin
    with memuboard do
      if (fbdirdlpath in fbstat) then
        s:=fexpand(dlpath+filename+'.DIR')
      else
        s:=fexpand(systat.gfilepath+filename+'.DIR');
  end;

  procedure dlbem;
  var f:file;
      dirinfo:searchrec;
      xloaded,i,ii:integer;
      c:char;
      s,s1,s2:astr;
{      d:dlnscan;}
      b:byte;
      changed,nospace,ok:boolean;
  begin
    xloaded:=-1;
    prt('Begin editing at which? (0-'+cstr(maxulb)+') : '); inu(ii);
    c:=' ';
    if (ii>=0) and (ii<=maxulb) and (not badini) then begin
      while (c<>'Q') and (not hangup) do begin
        if (xloaded<>ii) then begin
          seek(ulf,ii); read(ulf,memuboard);
          xloaded:=ii; changed:=FALSE;
        end;
        with memuboard do
          repeat
            if (c<>'?') then begin
              cls;
              sprint(#3#1+'File base #'+cstr(ii)+' of '+cstr(maxulb)); nl;
              sprint('1. Name        : '+#3#5+name);
              print('2. Filename    : '+filename);
              print('3. DL/UL path  : '+dlpath+' / '+samulpath(dlpath,ulpath));
              print('4. ACS req.    : "'+acs+'"');
              print('5. UL/Name ACS : "'+ulacs+'" / "'+nameacs+'"');
              print('6. Max files   : '+cstr(maxfiles));
              print('7. Password    : "'+password+'"');
              if arctype=0 then s:='None' else s:=systat.filearcinfo[arctype].ext;
              s:=s+'/'; if cmttype=0 then s:=s+'None' else s:=s+cstr(cmttype);
              print('8. Arc/cmt type: '+s);
              print('9. Dir depth   : '+cstr(fbdepth));
              print('   Flags       : '+flagstate(memuboard));
              print('   P-Index     : '+cstrl(permindx));
              print('Q. Quit');
            end;
            nl;
            prt('Edit menu (?=help) : '); onek(c,'Q123456789DGINU[]FJL?'^M);
            nl;
            case c of
              '?':begin
                    sprint('<CR>Redisplay screen');
                    sprint('1-8:Modify item');
                    lcmds(15,3,'[Back entry',']Forward entry');
                    lcmds(15,3,'Jump to entry','First entry in list');
                    lcmds(15,3,'Quit and save','Last entry in list');
                    nl;
                    sprint('Toggles:');
                    lcmds(15,3,'NoRatio','Unhidden');
                    lcmds(15,3,'Dir-header','I*.DIR file in DLPATH');
                    lcmds(15,3,'GifSpecs','');
                  end;
              '1':begin
                    prt('New name: '); cl(5);
                    inputwnwc(name,40,changed);
                  end;
              '2':begin
                    getdirspec(s1);
                    prt('New filename: '); mpl(8); input(s,8); s:=sqoutsp(s);
                    if (pos('.',s)>0) then
                      filename:=copy(s,1,pos('.',s)-1);
                    if (s<>'') then begin
                      if (s<>filename) then changed:=TRUE;
                      filename:=s;
                      getdirspec(s2);
                      if ((exist(s1)) and (not exist(s2))) then begin
                        nl;
                        print('Old DIR filename: "'+s1+'"');
                        print('New DIR filename: "'+s2+'"');
                        nl;
                        if pynq('Rename old filename to new filename? ') then begin
                          assign(f,s1);
                          {$I-} rename(f,s2); {$I+}
                          if (ioresult<>0) then begin
                            print('Errors renaming directory filename.');
                            pausescr;
                          end;
                        end;
                      end;
                    end;
                  end;
              '3':begin
                    print('Enter new download path:');
                    prt(':'); mpl(40); input(s,40); s:=sqoutsp(s);
                    if (s<>'') then begin
                      while (copy(s,length(s)-1,2)='\\') do s:=copy(s,1,length(s)-1);
                      if (copy(s,length(s),1)<>'\') then s:=s+'\';
                      if (s<>dlpath) then changed:=TRUE;
                      dlpath:=s;
                      if (not existdir(s)) then begin
                        nl;
                        print('"'+s+'" does not exist.');
                        if (pynq('Create file directory now? ')) then begin
                          {$I-} mkdir(bslash(FALSE,s)); {$I+}
                          if (ioresult<>0) then begin
                            print('Errors creating directory.');
                            pausescr;
                          end;
                        end;
                      end;
                    end;
                    nl;
                    print('Enter new upload path: ("D"=Same as DL path)');
                    prt(':'); mpl(40); input(s,40); s:=sqoutsp(s);
                    if ((s='D') or (s='d')) then s:=dlpath;
                    if (s<>'') then begin
                      while (copy(s,length(s)-1,2)='\\') do s:=copy(s,1,length(s)-1);
                      if (copy(s,length(s),1)<>'\') then s:=s+'\';
                      if (s<>ulpath) then changed:=TRUE;
                      ulpath:=s;
                      if (not existdir(s)) then begin
                        nl;
                        print('"'+s+'" does not exist.');
                        if (pynq('Create file directory now? ')) then begin
                          {$I-} mkdir(bslash(FALSE,s)); {$I+}
                          if (ioresult<>0) then begin
                            print('Errors creating directory.');
                            pausescr;
                          end;
                        end;
                      end;
                    end;
                  end;
              '4':begin
                    prt('New ACS: '); mpl(20);
                    inputwn(acs,20,changed);
                  end;
              '5':begin
                    prt('New UL ACS: '); mpl(20);
                    inputwn(ulacs,20,changed);
                    prt('New See-Names ACS: '); mpl(20);
                    inputwn(nameacs,20,changed);
                  end;
              '6':begin
                    prt('New max files: '); mpl(4); inu(i);
                    if (not badini) then begin
                      if (maxfiles<>i) then changed:=TRUE;
                      if (i>2000) then i:=2000;
                      maxfiles:=i;
                    end;
                  end;
              '7':begin
                    prt('New PW: ');
                    mpl(10); inputwn1(password,10,'u',changed);
                  end;
              '8':begin
                    if (arctype=0) then s:='None'
                      else s:=systat.filearcinfo[arctype].ext;
                    prt('New archive type ("0" for none) ['+s+'] : ');
                    input(s,3);
                    if (s<>'') then begin
                      b:=arctype;
                      if (value(s) in [1..maxarcs]) then b:=value(s)
                      else
                        for i:=1 to maxarcs do
                          if s=systat.filearcinfo[i].ext then b:=i;
                      if (value(s)=0) and (copy(s,1,1)='0') then b:=0;
                      if (arctype<>b) then changed:=TRUE;
                      arctype:=b;
                    end;
                    prt('New comment type ['+cstr(cmttype)+'] : '); ini(b);
                    if (not badini) and (b in [0..3]) then begin
                      if (cmttype<>b) then changed:=TRUE;
                      cmttype:=b;
                    end;
                  end;
              '9':begin
                    prt('New file base depth: '); mpl(3); ini(b);
                    if (not badini) then begin
                      if (fbdepth<>b) then changed:=TRUE;
                      fbdepth:=b;
                    end;
                  end;
              'D','G','I','N','U':
                  begin
                    changed:=TRUE;
                    case c of
                      'D':if (fbisdir in fbstat) then
                            fbstat:=fbstat-[fbisdir]
                          else fbstat:=fbstat+[fbisdir];
                      'G':if (fbusegifspecs in fbstat) then
                            fbstat:=fbstat-[fbusegifspecs]
                          else fbstat:=fbstat+[fbusegifspecs];
                      'I':begin
                            getdirspec(s1);
                            if (fbdirdlpath in fbstat) then
                              fbstat:=fbstat-[fbdirdlpath]
                            else fbstat:=fbstat+[fbdirdlpath];
                            getdirspec(s2);
                            if ((exist(s1)) and (not exist(s2))) then begin
                              print('Old DIR filename: '+s1);
                              print('New DIR filename: '+s2);
                              nl;
                              if pynq('Move old DIR file to new directory? ') then begin
                                nl;
                                sprompt(#3#5+'Progress: ');
                                movefile(ok,nospace,TRUE,s1,s2);
                                if (nospace) then
                                if (ok) then nl;
                                if (not ok) then begin
                                  sprompt(#3#7+'Move failed');
                                  if (not nospace) then nl else
                                    sprompt(' - Insuffient space on drive '+
                                            chr(exdrv(s2)+64)+':');
                                  sprint('!');
                                end;
                              end;
                            end;
                          end;
                      'N':if (fbnoratio in fbstat) then
                            fbstat:=fbstat-[fbnoratio]
                          else fbstat:=fbstat+[fbnoratio];
                      'U':if (fbunhidden in fbstat) then
                            fbstat:=fbstat-[fbunhidden]
                          else fbstat:=fbstat+[fbunhidden];
                    end;
                  end;
              '[':if (ii>0) then dec(ii) else c:=' ';
              ']':if (ii<maxulb) then inc(ii) else c:=' ';
              'F':if (ii<>0) then ii:=0 else c:=' ';
              'J':begin
                    prt('Jump to entry: ');
                    input(s,3);
                    if (value(s)>=0) and (value(s)<=maxulb) then ii:=value(s) else c:=' ';
                  end;
              'L':if (ii<>maxulb) then ii:=maxulb else c:=' ';
            end;
          until (pos(c,'Q[]FJL')<>0) or (hangup);
        if (changed) then begin
          seek(ulf,xloaded); write(ulf,memuboard);
          changed:=FALSE;
        end;
      end;
    end;
  end;

  procedure dlbepi;
  var i,j:integer;
  begin
    prt('Move which file base? (0-'+cstr(maxulb)+') : '); inu(i);
    if ((not badini) and (i>=0) and (i<=maxulb)) then begin
      prt('Move before which file base? (0-'+cstr(maxulb+1)+') : ');
      inu(j);
      if ((not badini) and (j>=0) and (j<=maxulb+1) and
          (j<>i) and (j<>i+1)) then begin
        nl;
        dlbep(i,j);
      end;
    end;
  end;

  function rnr(b:boolean):astr;
  begin
    if b then rnr:='Active' else rnr:='';
  end;

  function atyp(i:integer):astr;
  begin
    if i in [1..6] then atyp:=mln(cstr(i)+'-'+systat.filearcinfo[i].ext,5)
      else atyp:='None ';
  end;

begin
  c:=#0;
  reset(ulf);
  repeat
    if (c<>'?') then begin
      cls; done:=FALSE; abort:=FALSE;
      case ltype of

(*
                                                                            :
NNN:File base name           :Flags:ACS       :UL ACS    :Name ACS  :Maxf:Dep
===:=========================:=====:==========:==========:==========:====:===

NNN:File base name  :Filename:Download path          :Upload path
===:================:========:=======================:=======================

NNN:File base name                     :Arc/Cmt-type:P-Index:Password
===:===================================:===:========:=======:================
*)
        1:begin
            printacr(#3#0+'NNN'+sepr2+'File base name           '+sepr2+
                     'Flags'+sepr2+'ACS       '+sepr2+'UL ACS    '+sepr2+
                     'Name ACS  '+sepr2+'Maxf'+sepr2+'Dep',abort,next);
            printacr(#3#4+'===:=========================:=====:==========:==========:==========:====:===',abort,next);
          end;
        2:begin
            printacr(#3#0+'NNN'+sepr2+'File base name  '+sepr2+'Filename'+
                     sepr2+'Download path           '+sepr2+'Upload path',abort,next);
            printacr(#3#4+'===:================:========:========================:=======================',abort,next);
          end;
        3:begin
            printacr(#3#0+'NNN'+sepr2+'File base name                      '+
                     sepr2+'Arc/Cmt-type'+sepr2+'P-Index'+sepr2+'Password',abort,next);
            printacr(#3#4+'===:====================================:===:========:=======:================',abort,next);
          end;
      end;
      ii:=0;
      while (ii<=maxulb) and (not abort) and (not hangup) do begin
        seek(ulf,ii); read(ulf,memuboard);
        with memuboard do
          case ltype of
            1:printacr(#3#0+mn(ii,3)+' '+#3#5+mln(name,25)+' '+
                       #3#3+flagstate(memuboard)+#3#9+' '+mln(acs,10)+' '+
                       mln(ulacs,10)+' '+mln(nameacs,10)+' '+
                       #3#3+mn(maxfiles,4)+' '+mn(fbdepth,3),abort,next);
            2:printacr(#3#0+mn(ii,3)+' '+#3#5+mln(name,16)+' '+
                       #3#3+mln(filename,8)+' '+mln(dlpath,24)+' '+
                       mln(ulpath,23),abort,next);
            3:printacr(#3#0+mn(ii,3)+' '+#3#5+mln(name,36)+' '+
                       #3#9+mn(arctype,3)+' '+mn(cmttype,3)+'      '+
                       mn(permindx,7)+' '+password,abort,next);
          end;
        inc(ii);
      end;
      readuboard:=-1; loaduboard(0);
    end;
    nl;
    prt('File base editor (?=help) : ');
    onek(c,'QDIMPT?'^M);
    case c of
      '?':begin
            nl;
            print('<CR>Redisplay screen');
            lcmds(12,3,'Delete base','Insert base');
            lcmds(12,3,'Modify base','Position base');
            lcmds(12,3,'Quit','Toggle display format');
          end;
      'Q':done:=TRUE;
      'D':begin
            prt('File base to delete? (0-'+cstr(maxulb)+') : '); inu(ii);
            if ((ii>=0) and (ii<=maxulb) and (not badini)) then begin
              readuboard:=-1; loaduboard(ii);
              if (fbdirdlpath in memuboard.fbstat) then s0:=memuboard.dlpath
                else s0:=systat.gfilepath;
              s0:=s0+memuboard.filename+'.DIR';
              nl; sprint('File base: '+#3#5+memuboard.name);
              if pynq('Delete this? ') then begin
                sysoplog('* Deleted file base: '+memuboard.name);
                dlbed(ii);
                if pynq('Delete directory file? ') then begin
                  writeln; writeln('Deleting: '+s0);
                  {$I-} assign(f,s0); reset(f); close(f); {$I+}
                  if (ioresult=0) then erase(f);
                  pausescr;
                end;
              end;
            end;
          end;
      'I':begin
            prt('File base to insert before? (0-'+cstr(maxulb+1)+') : '); inu(ii);
            if ((ii>=0) and (ii<=maxulb+1)) then begin
              sysoplog('* Inserted new file base');
              dlbei(ii);
            end;
          end;
      'M':dlbem;
      'P':dlbepi;
      'T':ltype:=ltype mod 3+1;   { toggle between 1, 2 & 3 }
    end;
  until (done) or (hangup);
  close(ulf);
  if ((systat.compressbases) and (useron)) then newcomptables;

  if ((fileboard<0) or (fileboard>maxulb)) then fileboard:=1;
  readuboard:=-1; loaduboard(fileboard);
end;

end.
