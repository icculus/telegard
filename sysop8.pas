(*****************************************************************************)
(*>                                                                         <*)
(*>  SYSOP8  .PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  SysOp functions: Message base editor                                   <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit sysop8;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common,
  file0,
  sysop1;

type zscanfuncr=procedure(var zscanr1:zscanrec; x,y:integer);

procedure dozscanfunc(zscanfunc:zscanfuncr; x,y:integer);
procedure boardedit;

implementation

procedure mmm(var zscanr1:zscanrec; x,y:integer);
var i:integer;
begin
  for i:=1 to 6 do zscanr1.mhiread[y][i]:=zscanr1.mhiread[x][i];
end;

procedure mbase_del(var zscanr1:zscanrec; x,y:integer);
var i,j:integer;
begin
  for j:=x to numboards-1 do begin
    mmm(zscanr1,j+1,j);
    if (j+1 in zscanr1.mzscan) then zscanr1.mzscan:=zscanr1.mzscan+[j]
                               else zscanr1.mzscan:=zscanr1.mzscan-[j];
  end;
  for i:=1 to 6 do zscanr1.mhiread[numboards][i]:=0;
  zscanr1.mzscan:=zscanr1.mzscan+[numboards];
end;

procedure mbase_ins(var zscanr1:zscanrec; x,y:integer);
var i,j:integer;
begin
  for j:=numboards downto x+1 do begin
    mmm(zscanr1,j-1,j);
    if (j-1 in zscanr1.mzscan) then zscanr1.mzscan:=zscanr1.mzscan+[j]
                               else zscanr1.mzscan:=zscanr1.mzscan-[j];
  end;
  for i:=1 to 6 do zscanr1.mhiread[x][i]:=0;
  zscanr1.mzscan:=zscanr1.mzscan+[x];
end;

procedure mbase_pos(var zscanr1:zscanrec; x,y:integer);
var s_mhiread:array[1..6] of byte;
    s_mzscan:boolean;
    i,j,k:integer;
begin
  for i:=1 to 6 do s_mhiread[i]:=zscanr1.mhiread[x][i];
  s_mzscan:=(x in zscanr1.mzscan);
  i:=x; if (x>y) then j:=-1 else j:=1;
  while (i<>y) do begin
    if (i+j in zscanr1.mzscan) then zscanr1.mzscan:=zscanr1.mzscan+[i]
                               else zscanr1.mzscan:=zscanr1.mzscan-[i];
    mmm(zscanr1,i+j,i);
    inc(i,j);
  end;
  if (s_mzscan) then zscanr1.mzscan:=zscanr1.mzscan+[y]
                else zscanr1.mzscan:=zscanr1.mzscan-[y];
  for i:=1 to 6 do zscanr1.mhiread[y][i]:=s_mhiread[i];
end;

procedure dozscanfunc(zscanfunc:zscanfuncr; x,y:integer);
var zscanf:file;
    zscanr1:zscanrec;
    i,lz:integer;
begin
  assign(zscanf,systat.gfilepath+'zscan.dat');
  {$I-} reset(zscanf,sizeof(zscanrec)); {$I+}
  if (ioresult<>0) then
    rewrite(zscanf)
  else begin
    if (filesize(zscanf)=1) then exit;
    sprompt(#3#5+'Progress: ');
    cl(7); for i:=1 to 20 do prompt('.'); for i:=1 to 20 do prompt(^H);
    cl(5); lz:=0;
    for i:=0 to filesize(zscanf)-1 do begin
      seek(zscanf,i); blockread(zscanf,zscanr1,1);
      if (usernum=i) then zscanr1:=zscanr;
      zscanfunc(zscanr1,x,y);
      seek(zscanf,i); blockwrite(zscanf,zscanr1,1);
      if (usernum=i) then zscanr:=zscanr1;
      while (20*i/(filesize(zscanf)-1)>lz) do begin inc(lz); prompt('o'); end;
    end;
    if (lz<>20) then
      for i:=1 to 20-lz do prompt('o');
    for i:=1 to 20 do prompt(^H); for i:=1 to 20 do prompt(' ');
    for i:=1 to 20 do prompt(^H); sprint('^7*^5DONE^7*');
  end;
  close(zscanf);
end;

procedure boardedit;
const ltype:integer=1;
var f1:file;
    s:string;
    i1,i2,ii:integer;
    c:char;
    abort,next:boolean;

  function newindexno:longint;
  var brd:boardrec;
      i,j:integer;
  begin
    reset(bf);
    j:=-1;
    for i:=1 to filesize(bf) do begin
      read(bf,brd);
      if (brd.permindx>j) then j:=brd.permindx;
    end;
    inc(j);
    newindexno:=j;
  end;

  procedure bed(x:integer);
  var i,j:integer;
  begin
    if ((x>0) and (x<=numboards)) then begin
      i:=x-1;
      if (i>=0) and (i<=filesize(bf)-2) then
        for j:=i to filesize(bf)-2 do begin
          seek(bf,j+1); read(bf,memboard);
          seek(bf,j); write(bf,memboard);
        end;
      seek(bf,filesize(bf)-1); truncate(bf);

      dozscanfunc(mbase_del,x,0);
      dec(numboards);
    end;
  end;

  procedure bei(x:integer);
  var i,j:integer;
  begin
    i:=x-1;
    if ((i>=0) and (i<=filesize(bf)) and (numboards<maxboards)) then begin
      for j:=filesize(bf)-1 downto i do begin
        seek(bf,j); read(bf,memboard);
        write(bf,memboard); { ...to next record }
      end;
      with memboard do begin
        name:='<< Not used >>';
        filename:='NEWBOARD';
        lastmsgid:=0;
        mbtype:=0;
        msgpath:='';
        acs:='s30';
        postacs:='s30';
        maxmsgs:=50;
        anonymous:=atno;
        password:='';
        permindx:=newindexno;
        zone:=0;
        net:=0;
        node:=0;
        point:=0;
        if (fidor.origin<>'') then origin:=fidor.origin
          else origin:=copy(stripcolor(systat.bbsname),1,50);
        text_color:=fidor.text_color;
        quote_color:=fidor.quote_color;
        tear_color:=fidor.tear_color;
        origin_color:=fidor.origin_color;
        mbstat:=[];
        if (fidor.skludge) then mbstat:=mbstat+[mbskludge];
        if (fidor.sseenby) then mbstat:=mbstat+[mbsseenby];
        if (fidor.sorigin) then mbstat:=mbstat+[mbsorigin];
        if (fidor.scenter) then mbstat:=mbstat+[mbscenter];
        if (fidor.sbox) then mbstat:=mbstat+[mbsbox];
        if (fidor.mcenter) then mbstat:=mbstat+[mbmcenter];
        if (fidor.addtear) then mbstat:=mbstat+[mbaddtear];
        for j:=1 to 3 do res[j]:=0;
      end;
      seek(bf,i); write(bf,memboard);
      inc(numboards);

      dozscanfunc(mbase_ins,x,0);
    end;
  end;

  procedure bep(x,y:integer);
  var tempboard:boardrec;
      i,j,k:integer;
  begin
(*
            y   x
          012345678901234567890
   (k) 1> xxxxxxOxxx...........
   (j) 2> xxOxxxxxxx...........

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

    k:=y; if (y>x) then dec(y);
    dec(x); dec(y);
    seek(bf,x); read(bf,tempboard);
    i:=x; if (x>y) then j:=-1 else j:=1;
    while (i<>y) do begin
      if (i+j<filesize(bf)) then begin
        seek(bf,i+j); read(bf,memboard);
        seek(bf,i); write(bf,memboard);
      end;
      inc(i,j);
    end;
    seek(bf,y); write(bf,tempboard);
    inc(x); inc(y); {y:=k;}

    dozscanfunc(mbase_pos,x,y);
  end;

  function flagstate(mb:boardrec):string;
  var s:string;
  begin
    s:='';
    with mb do begin
      if (mbrealname in mbstat) then s:=s+'R' else s:=s+'-';
      if (mbunhidden in mbstat) then s:=s+'U' else s:=s+'-';
      if (mbfilter in mbstat) then s:=s+'A' else s:=s+'-';
    end;
    flagstate:=s;
  end;

  function fidoflags(mb:boardrec):string;
  var s:string[8];
  begin
    s:='';
    with mb do begin
      if (mbskludge in mbstat) then s:=s+'K' else s:=s+'-';
      if (mbsseenby in mbstat) then s:=s+'S' else s:=s+'-';
      if (mbsorigin in mbstat) then s:=s+'O' else s:=s+'-';
      s:=s+'/';
      if (mbscenter in mbstat) then s:=s+'C' else s:=s+'-';
      if (mbsbox in mbstat) then s:=s+'B' else s:=s+'-';
      if (mbmcenter in mbstat) then s:=s+'M' else s:=s+'-';
      if (mbaddtear in mbstat) then s:=s+'T' else s:=s+'-';
    end;
    fidoflags:=s;
  end;

  procedure incolor(msg:string; var i:byte);
  begin
    prompt('Enter new '+msg+' color (0-9) : ');
    mpl(1);
    input(s,1);
    if ((s<>'') and (s[1] in ['0'..'9'])) then i:=ord(s[1])-48;
  end;

  function getaddr(zone,net,node,point:integer):string;
  begin
    if (zone=0) then getaddr:='Default' else
      getaddr:=cstr(zone)+':'+cstr(net)+'/'+cstr(node)+'.'+cstr(point);
  end;

  procedure getbrdspec(var s:string);
  begin
    with memboard do
(*      if (mbmsgpath in mbstat) then
        s:=fexpand(msgpath+filename+'.BRD')
      else*)
      s:=fexpand(systat.msgpath+filename+'.BRD');
  end;

  procedure bem;
  var f:file;
      dirinfo:searchrec;
      anontemp:anontyp;
      s,s1,s2,s3:string;
      i,i1,i2,ii,xloaded:integer;
      c,c1:char;
      b:byte;
      changed,err:boolean;
  begin
    prt('Begin editing at which? (1-'+cstr(numboards)+') : '); inu(ii);
    c:=' '; xloaded:=-1;
    if ((ii>0) and (ii<=numboards)) then begin
      while (c<>'Q') and (not hangup) do begin
        if (xloaded<>ii) then begin
          seek(bf,ii-1); read(bf,memboard);
          xloaded:=ii; changed:=FALSE;
        end;
        with memboard do
          repeat
            if (c<>'?') then begin
              cls;
              print('Message base #'+cstr(ii)+' of '+cstr(numboards));
              nl;
              sprint('1. Name        : '+#3#5+name);
              print('2. Filename    : '+filename);
              prompt('3. Base type   : ');
              case mbtype of
                0:print('Local');
                1:print('EchoMail');
                2:begin
                    prompt('GroupMail');
                    if (mbtopstar in mbstat) then print(' Top Star') else nl;
                  end;
              end;
              prompt('   Message path: ');
              if (mbtype=0) then print('Unused') else print(msgpath);
              print('4. ACS req.    : "'+acs+'"');
              print('5. Post/MCI ACS: "'+postacs+'" / "'+mciacs+'"');
              print('6. Max Mess    : '+cstrl(maxmsgs));
              prompt('7. Anonymous   : ');
              case anonymous of
              atyes:print('Yes');
               atno:print('No');
           atforced:print('Forced');
         atdearabby:print('Dear Abby');
          atanyname:print('Any Name');
              end;
              print('8. Password    : "'+password+'"');
              prompt('9. Address     : ');
              if (mbtype=0) then s:='Unused'
                else s:=getaddr(zone,net,node,point);
              print(s);
              prompt('C. Colors      : ');
              if (mbtype=0) then print('Unused') else
                print('Text='+cstr(text_color)+
                  ', Quote='+cstr(quote_color)+
                  ', Tear='+cstr(tear_color)+
                  ', Origin='+cstr(origin_color));
              prompt('M. Mail flags  : ');
              if (mbtype=0) then print('Unused') else print(fidoflags(memboard));
              prompt('O. Origin line : ');
              if (mbtype=0) then print('Unused') else print('"'+origin+'"');
              print('   Flags       : '+flagstate(memboard));
              print('   P-Index     : '+cstrl(permindx));
              print('Q. Quit');
            end;
            nl; prt('Edit menu (?=help) : ');
            onek(c,^M'?[]FJLQ123456789CMORUA'); nl;
            case c of
              '1':begin
                    prt('New name: ');
                    cl(5); inputwnwc(name,40,changed);
                  end;
              '2':begin
                    getbrdspec(s1);
                    prt('New filename: '); mpl(8); input(s,8); s:=sqoutsp(s);
                    if (pos('.',s)>0) then filename:=copy(s,1,pos('.',s)-1);
                    if (s<>'') then begin
                      if (s<>filename) then changed:=TRUE;
                      filename:=s;
                      getbrdspec(s2);
                      if ((exist(s1)) and (not exist(s2))) then begin
                        nl;
                        print('Old BRD/MIX/TRE filenames: "'+copy(s1,1,pos('.',s1)-1)+'.*"');
                        print('New BRD/MIX/TRE filenames: "'+copy(s2,1,pos('.',s2)-1)+'.*"');
                        nl;
                        if pynq('Rename old filenames to new filenames? ') then begin
                          s3:=s1;
                          err:=FALSE;
                          assign(f,s1);
                          {$I-} rename(f,s2); {$I+}
                          if (ioresult<>0) then begin
                            print('Error renaming *.BRD filename.');
                            err:=TRUE;
                          end;
                          s1:=copy(s3,1,pos('.',s3)-1)+'.MIX';
                          s2:=copy(s2,1,pos('.',s2)-1)+'.MIX';
                          assign(f,s1);
                          {$I-} rename(f,s2); {$I+}
                          if (ioresult<>0) then begin
                            print('Error renaming *.MIX filename.');
                            err:=TRUE;
                          end;
                          s1:=copy(s3,1,pos('.',s3)-1)+'.TRE';
                          s2:=copy(s2,1,pos('.',s2)-1)+'.TRE';
                          assign(f,s1);
                          {$I-} rename (f,s2); {$I+}
                          if (ioresult<>0) then begin
                            print('Error renaming *.TRE filename.');
                            err:=TRUE;
                          end;
                          if err then pausescr;
                        end;
                      end;
                    end;
                  end;
              '3':begin
                    changed:=TRUE;
                    prt('[L]ocal [E]choMail [G]roupMail : ');
                    onek(c,'LEG'^M);
                    case c of
                      'L':mbtype:=0;
                      'E':mbtype:=1;
                      'G':mbtype:=2;
                    end;
                    if (mbtype<>0) then begin
                      if (mbtype=2) then begin
                        if pynq('Are you the Top Star for this conference? ')
                          then mbstat:=mbstat+[mbtopstar]
                          else mbstat:=mbstat-[mbtopstar];
                      end;
                      nl; prompt('Current message path: ');
                      if (msgpath<>'') then print(msgpath) else print('*NONE*');
                      {rcg11242000 DOSism.}
                      {nl; print('Press <CR> to use default path "'+systat.msgpath+filename+'\"');}
                      nl; print('Press <CR> to use default path "'+systat.msgpath+filename+'/"');
                      nl; print('Enter new message path:');
                      prt(':'); mpl(40); input(s,40); s:=sqoutsp(s);
                      if (s<>'') then begin
                        {rcg11242000 DOSisms.}
                        {
			while (copy(s,length(s)-1,2)='\\') do s:=copy(s,1,length(s)-1);
                        if (copy(s,length(s),1)<>'\') then s:=s+'\';
                        }
                        while (copy(s,length(s)-1,2)='//') do s:=copy(s,1,length(s)-1);
                        if (copy(s,length(s),1)<>'/') then s:=s+'/';
                        msgpath:=s;
                      end;
                      {rcg11242000 DOSism.}
                      {if ((s='') and (msgpath='')) then msgpath:=systat.msgpath+filename+'\';}
                      if ((s='') and (msgpath='')) then msgpath:=systat.msgpath+filename+'/';
                      if (not existdir(msgpath)) then begin
                        nl; print('"'+msgpath+'" does not exist.');
                        if (pynq('Create message directory now? ')) then begin
                          {$I-} mkdir(bslash(FALSE,msgpath)); {$I+}
                          if (ioresult<>0) then begin
                            print('Errors creating directory.');
                            pausescr;
                          end;
                        end;
                      end else begin
                        nl; print('"'+msgpath+'" ALREADY EXISTS!'); nl;
                        print('Make SURE that this path is the one you REALLY want');
                        print('to use, or messages may be inadvertantly mixed!');
                        nl; pausescr;
                      end;
                    end;
                  end;
              '4':begin
                    prt('New ACS: '); mpl(20);
                    inputwn(acs,20,changed);
                  end;
              '5':begin
                    prt('New Post ACS: '); mpl(20);
                    inputwn(postacs,20,changed);
                    prt('New MCI ACS: '); mpl(20);
                    inputwn(mciacs,20,changed);
                  end;
              '6':begin
                    prt('Max messages: '); mpl(5); inu(i);
                    if (not badini) then begin
                      if (i<>maxmsgs) then changed:=TRUE;
                      maxmsgs:=i;
                    end;
                    if (maxmsgs<10) then maxmsgs:=10;
                    if (maxmsgs>30000) then maxmsgs:=30000;
                  end;
              '7':begin
                    prt('Anonymous types:');
                    nl; nl;
                    lcmds(40,3,'Yes, anonymous allowed, selectively','');
                    lcmds(40,3,'No, anonymous not allowed','');
                    lcmds(40,3,'Forced anonymous','');
                    lcmds(40,3,'Dear Abby','');
                    lcmds(40,3,'Any Name','');
                    nl; prt('New Anon. type (YNFDA) : ');
                    onek(c,'QYNFDA'^M);
                    if (pos(c,'YNFDA')<>0) then begin
                      case c of
                        'Y':anontemp:=atyes;
                        'N':anontemp:=atno;
                        'F':anontemp:=atforced;
                        'D':anontemp:=atdearabby;
                        'A':anontemp:=atanyname;
                      end;
                      if (anontemp<>anonymous) then changed:=TRUE;
                      anonymous:=anontemp;
                    end;
                  end;
              '8':begin
                    prt('New PW: ');
                    mpl(20); inputwn1(password,20,'u',changed);
                  end;
              '9':if (mbtype<>0) then begin
                    s:=getaddr(fidor.zone,fidor.net,fidor.node,fidor.point);
                    if pynq('Use default address ('+s+')? ') then begin
                      zone:=0; net:=0; node:=0; point:=0;
                    end else begin
                      prt('Enter new zone number  : '); inu(i);
                      if (not badini) then zone:=i;
                      prt('Enter new net number   : '); inu(i);
                      if (not badini) then net:=i;
                      prt('Enter new node number  : '); inu(i);
                      if (not badini) then node:=i;
                      prt('Enter new point number : '); inu(i);
                      if (not badini) then point:=i;
                    end;
                    changed:=TRUE;
                  end;
              'C':if (mbtype<>0) then begin
                    incolor('standard text',text_color);
                    incolor('quoted text',quote_color);
                    incolor('tear line',tear_color);
                    incolor('origin line',origin_color);
                  end;
              'M':begin
                    if (mbtype<>0) then repeat
                      prt('Flags ['+fidoflags(memboard)+'] [?]Help [Q]uit :');
                      onek(c1,'KSOCBMT?Q'^M);
                      case c1 of
                        ^M,'Q': ;
                        '?':begin
                              nl;
                              lcmds(22,3,'Kludge line strip','Box code strip');
                              lcmds(22,3,'SEEN-BY line strip','Make lines centered');
                              lcmds(22,3,'Origin line strip','Tear/origin line add');
                              lcmds(22,3,'Centering code strip','');
                              nl;
                            end;
                        'K':if (mbskludge in mbstat) then
                              mbstat:=mbstat-[mbskludge]
                              else mbstat:=mbstat+[mbskludge];
                        'S':if (mbsseenby in mbstat) then
                              mbstat:=mbstat-[mbsseenby]
                              else mbstat:=mbstat+[mbsseenby];
                        'O':if (mbsorigin in mbstat) then
                              mbstat:=mbstat-[mbsorigin]
                              else mbstat:=mbstat+[mbsorigin];
                        'C':if (mbscenter in mbstat) then
                              mbstat:=mbstat-[mbscenter]
                              else mbstat:=mbstat+[mbscenter];
                        'B':if (mbsbox in mbstat) then
                              mbstat:=mbstat-[mbsbox]
                              else mbstat:=mbstat+[mbsbox];
                        'M':if (mbmcenter in mbstat) then
                              mbstat:=mbstat-[mbmcenter]
                              else mbstat:=mbstat+[mbmcenter];
                        'T':if (mbaddtear in mbstat) then
                              mbstat:=mbstat-[mbaddtear]
                              else mbstat:=mbstat+[mbaddtear];
                      end;
                    until ((c1 in [^M,'Q']) or (hangup));
                    if (mbtype<>0) then changed:=TRUE;
                  end;
              'O':if (mbtype<>0) then begin
                    print('Enter new origin line');
                    prt(':'); mpl(50); inputwn1(origin,50,'',changed);
                  end;
              'R':begin
                    changed:=TRUE;
                    if (mbrealname in mbstat) then mbstat:=mbstat-[mbrealname]
                      else mbstat:=mbstat+[mbrealname];
                  end;
              'U':begin
                    changed:=TRUE;
                    if (mbunhidden in mbstat) then mbstat:=mbstat-[mbunhidden]
                      else mbstat:=mbstat+[mbunhidden];
                  end;
              'A':begin
                    changed:=TRUE;
                    if (mbfilter in mbstat) then mbstat:=mbstat-[mbfilter]
                      else mbstat:=mbstat+[mbfilter];
                  end;
              '[':if (ii>1) then dec(ii) else c:=' ';
              ']':if (ii<numboards) then inc(ii) else c:=' ';
              'F':if (ii<>1) then ii:=1 else c:=' ';
              'J':begin
                    prt('Jump to entry: ');
                    input(s,3);
                    if (value(s)>=1) and (value(s)<=numboards) then ii:=value(s) else c:=' ';
                  end;
              'L':if (ii<>numboards) then ii:=numboards else c:=' ';
              '?':begin
                    sprint(' #:Modify item   <CR>Redisplay screen');
                    lcmds(15,3,'[Back entry',']Forward entry');
                    lcmds(15,3,'Jump to entry','First entry in list');
                    lcmds(15,3,'Quit and save','Last entry in list');
                    nl;
                    sprint('Toggles:');
                    lcmds(15,3,'Real names','AFilter ANSI/8-bit ASCII');
                    lcmds(15,3,'Unhidden','');
                  end;
            end;
          until (pos(c,'Q[]FJL')<>0) or (hangup);
        if (changed) then begin
          seek(bf,xloaded-1); write(bf,memboard);
          changed:=FALSE;
        end;
      end;
    end;
  end;

  procedure bepi;
  var i,j:integer;
  begin
    prt('Move which message base? (1-'+cstr(numboards)+') : '); inu(i);
    if ((not badini) and (i>=1) and (i<=numboards)) then begin
      prt('Move before which message base? (1-'+cstr(numboards+1)+') : ');
      inu(j);
      if ((not badini) and (j>=1) and (j<=numboards+1) and
          (j<>i) and (j<>i+1)) then begin
        nl;
        bep(i,j);
      end;
    end;
  end;

  function anont(a:anontyp):string;
  begin
    case a of
      atyes     :anont:='Y';
      atno      :anont:='N';
      atforced  :anont:='F';
      atdearabby:anont:='DA';
      atanyname :anont:='AN';
    end;
  end;

begin
  c:=#0;
  reset(bf);
  repeat
    if (c<>'?') then begin
      cls; abort:=FALSE; next:=FALSE;
      s:=#3#0+'NNN'+sepr2+'Base name                    '+sepr2;
      case ltype of
        1:begin
            printacr(s+'Flag'+sepr2+'ACS       '+sepr2+'Post ACS  '+
              sepr2+'MCI ACS   '+sepr2+'MaxM'+sepr2+'An',abort,next);
            s:='====:==========:==========:==========:====:==';
          end;
        2:begin
            printacr(s+'Filename'+sepr2+'Password',abort,next);
            s:='========:====================';
          end;
        3:begin
            printacr(s+'Flags   '+sepr2+'Colors '+sepr2+'Message path',abort,next);
            s:='========:=======:============================';
          end;
        4:begin
            printacr(s+'Address    '+sepr2+'Origin line',abort,next);
            s:='===========:=================================';
          end;
      end;
      printacr(#3#4+'===:=============================:'+s,abort,next);
(*
NNN:Base name                    :Flag:ACS       :Post ACS  :MCI ACS   :MaxM:An
===:=============================:====:==========:==========:==========:====:==

NNN:Base name                    :Filename:Password
===:=============================:========:====================

NNN:Base name                    :Flags   :Colors :Message path
===:=============================:========:=======:============================

NNN:Base name                    :Address    :Origin line
===:=============================:===========:=================================
*)
      ii:=1;
      while (ii<=numboards) and (not abort) and (not hangup) do begin
        seek(bf,ii-1); read(bf,memboard);
        s:=#3#0+mn(ii,3)+' '+#3#5+mln(memboard.name,29)+' '+#3#3;
        with memboard do begin
          case ltype of
            1:s:=s+copy('LEG',mbtype+1,1)+flagstate(memboard)+' '+#3#9+
                mln(acs,10)+' '+mln(postacs,10)+' '+mln(mciacs,10)+' '+#3#3+
                mn(maxmsgs,4)+' '+anont(anonymous);
            2:s:=s+mln(filename,8)+' '+password;
            3:if (mbtype=0) then s:=s+#3#5+'<< Not used >>' else
                s:=s+fidoflags(memboard)+' '+cstr(text_color)+','+
                cstr(quote_color)+','+cstr(tear_color)+','+cstr(origin_color)+
                ' '+mln(msgpath,28);
            4:if (mbtype=0) then s:=s+#3#5+'<< Not used >>' else
                s:=s+mln(getaddr(zone,net,node,point),11)+' '+mln(origin,33);
          end;
          printacr(s,abort,next);
          inc(ii);
        end;
      end;
      readboard:=-1; loadboard(1);
    end;
    nl;
    prt('Message base editor (?=help) : ');
    onek(c,'QDIMPT?'^M);
    case c of
      '?':begin
            nl;
            print('<CR>Redisplay screen');
            lcmds(12,3,'Delete base','Insert base');
            lcmds(12,3,'Modify base','Position base');
            lcmds(12,3,'Quit','Toggle display format');
          end;
      'D':begin
            prt('Board number to delete? (1-'+cstr(numboards)+') : '); inu(ii);
            if ((not badini) and (ii>=1) and (ii<=numboards)) then begin
              readboard:=-1; loadboard(ii);
              s:=systat.msgpath+memboard.filename;
              nl; sprint('Message base: '+#3#5+memboard.name);
              if pynq('Delete this? ') then begin
                sysoplog('* Deleted message base: '+memboard.name);
                bed(ii);
                if (pynq('Delete message files? ')) then begin
                  writeln;
                  writeln('Deleting: '+s+'.BRD');
                  {$I-} assign(f1,s+'.BRD'); reset(f1); close(f1); {$I+}
                  if (ioresult=0) then erase(f1);
                  writeln('Deleting: '+s+'.MIX');
                  {$I-} assign(f1,s+'.MIX'); reset(f1); close(f1); {$I+}
                  if (ioresult=0) then erase(f1);
                  writeln('Deleting: '+s+'.TRE');
                  {$I-} assign(f1,s+'.TRE'); reset(f1); close(f1); {$I+}
                  if (ioresult=0) then erase(f1);
                  pausescr;
                end;
              end;
            end;
          end;
      'I':begin
            prt('Board number to insert before? (1-'+cstr(numboards+1)+') : '); inu(ii);
            if ((not badini) and (ii>0) and (ii<=numboards+1) and
                (numboards<maxboards)) then begin
              sysoplog('* Inserted new message base');
              bei(ii);
            end;
          end;
      'M':bem;
      'P':bepi;
      'T':ltype:=ltype mod 4+1;  { toggle between 1, 2, 3 & 4 }
    end;
  until ((c='Q') or (hangup));
  close(bf);
  if ((systat.compressbases) and (useron)) then newcomptables;

  if ((board<1) or (board>numboards)) then board:=1;
  readboard:=-1; loadboard(board);
end;

end.

