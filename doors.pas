(*****************************************************************************)
(*>                                                                         <*)
(*>  DOORS   .PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  Online door procedures.                                                <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit doors;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  execbat,
  common;

function process_door(s:astr):astr;
procedure write_dorinfo1_def(rname:boolean);     { RBBS-PC DORINFO1.DEF }
procedure write_door_sys(rname:boolean);         { GAP DOOR.SYS }
procedure write_chain_txt;                       { WWIV CHAIN.TXT }
procedure write_callinfo_bbs(rname:boolean);     { Wildcat! CALLINFO.BBS }
procedure write_sfdoors_dat(rname:boolean);      { Spitfire SFDOORS.DAT }
procedure dodoorfunc(kind:char; cline:astr);

implementation

function timestr:astr;
var i:astr;
begin
  {str(nsl/60,i);}
  {i:=copy(i,2,length(i));}
  {i:=copy(i,1,pos('.',i)-1);}
  i:=cstrr(nsl/60,10);
  timestr:=i;
end;

function process_door(s:astr):astr;
var i:integer;
    sda,namm:astr;
    sdoor:string[255];
begin
  namm:=caps(thisuser.realname);
  sdoor:='';
  for i:=1 to length(s) do begin
    if copy(s,i,1)='@' then begin
      sda:='';
      case upcase(s[i+1]) of
        'B':if spd<>'KB' then sda:=spd else sda:='0';
        'D':begin
              loaduboard(fileboard);
              sda:=memuboard.dlpath;
            end;
        'F':sda:=copy(namm,1,pos(' ',namm)-1);
        'G':if okansi then sda:='1' else sda:='0';
        'I':begin
              loaduboard(fileboard);
              sda:=systat.gfilepath;
              if (copy(sda,length(sda),1)<>'\') then sda:=sda+'\';
              sda:=sda+memuboard.filename+'.DIR';
            end;
        'L':begin
              if (pos(' ',namm)=0) then sda:=namm else
                sda:=copy(namm,pos(' ',namm)+1,length(namm));
            end;
        'N':sda:=caps(thisuser.name);
        'T':sda:=timestr;
        'R':sda:=(copy(nam,pos('#',nam)+1,length(nam)));
      end;
      sdoor:=sdoor+sda;
      inc(i);
    end
    else sdoor:=sdoor+copy(s,i,1);
  end;
  process_door:=sdoor;
end;

procedure write_dorinfo1_def(rname:boolean);  (* RBBS-PC's DORINFO1.DEF *)
var fp:text;
    first,last:astr;
    s:astr;
begin
  assign(fp,'dorinfo1.def');
	rewrite(fp);
	writeln(fp,stripcolor(systat.bbsname));
	first:=copy(systat.sysopname,1,pos(' ',systat.sysopname)-1);
	last:=copy(systat.sysopname,length(first)+2,length(systat.sysopname));
  writeln(fp,first);
  writeln(fp,last);
  if spd='KB' then writeln(fp,'COM0') else writeln(fp,'COM'+cstr(modemr.comport));
  if spd='KB' then s:='0' else s:=spd;
  writeln(fp,s+' BAUD,N,8,1');
  writeln(fp,'0');
  if (rname) then begin
    if pos(' ',thisuser.realname)=0 then begin
      first:=thisuser.realname;
      last:='';
    end else begin
      first:=copy(thisuser.realname,1,pos(' ',thisuser.realname)-1);
      last:=copy(thisuser.realname,length(first)+2,length(thisuser.realname));
    end;
    first:=allcaps(first);
    last:=allcaps(last);
  end else begin
    if pos(' ',thisuser.name)=0 then begin
      first:=thisuser.name;
      last:='';
    end else begin
      first:=copy(thisuser.name,1,pos(' ',thisuser.name)-1);
      last:=copy(thisuser.name,length(first)+2,length(thisuser.name));
    end;
  end;
  writeln(fp,caps(first));
  writeln(fp,caps(last));
  writeln(fp,thisuser.citystate);
  if (ansi in thisuser.ac) then writeln(fp,'1') else writeln(fp,'0');
  writeln(fp,thisuser.sl);
  s:=timestr;
  if length(s)>3 then s:='999';
  writeln(fp,s);
  writeln(fp,'0');
  close(fp);
end;

procedure write_door_sys(rname:boolean);    (* GAP's DOOR.SYS *)
var fp:text;
    i:integer;
    s:astr;
begin
  assign(fp,'door.sys');
  rewrite(fp);
  if spd<>'KB' then writeln(fp,'COM'+cstr(modemr.comport)+':') else writeln(fp,'COM0:');
  if spd<>'KB' then writeln(fp,spd) else writeln(fp,cstr(modemr.waitbaud));
	writeln(fp,' 8');
	writeln(fp,' 1');
	writeln(fp,' N');
	if wantout then writeln(fp,' Y') else writeln(fp,' N');
	writeln(fp,' Y');
	if sysop then writeln(fp,' Y') else writeln(fp,' N');
	if alert in thisuser.ac then writeln(fp,' Y') else writeln(fp,' N');
  if (rname) then writeln(fp,thisuser.realname) else writeln(fp,thisuser.name);
  writeln(fp,thisuser.citystate);
  writeln(fp,copy(thisuser.ph,1,3)+' '+copy(thisuser.ph,5,8));
  writeln(fp,copy(thisuser.ph,1,3)+' '+copy(thisuser.ph,5,8));
  writeln(fp,thisuser.pw);
  writeln(fp,cstr(thisuser.sl));
  writeln(fp,cstr(thisuser.loggedon));
  writeln(fp,thisuser.laston);
  writeln(fp,cstrl(trunc(nsl)));
  writeln(fp,cstr(trunc(nsl) div 60));
  if okansi then writeln(fp,'GR') else writeln(fp,'NG');
  writeln(fp,cstr(thisuser.pagelen));
	if novice in thisuser.ac then writeln(fp,' N') else writeln(fp,' Y');
  s:='';
  for i:=1 to 7 do
    if chr(i+64) in thisuser.ar then s:=s+cstr(i);
  writeln(fp,s);
  writeln(fp,'7');
	writeln(fp,'12/31/99');
	writeln(fp,' '+cstr(usernum));
	writeln(fp,' X');
	writeln(fp,' '+cstr(thisuser.uploads));
	writeln(fp,' '+cstr(thisuser.downloads));
	writeln(fp,' '+cstr(trunc(thisuser.dk)));
	writeln(fp,' 999999');
  close(fp);
end;

procedure write_chain_txt;
var fp:text;
    ton,tused:real;
    s:string[20];

  function bo(b:boolean):astr;
  begin
    if b then bo:='1' else bo:='0';
  end;

begin
  assign(fp,'chain.txt');
  rewrite(fp);
  with thisuser do begin
    writeln(fp,usernum);                      { user number        }
    writeln(fp,name);                         { user name          }
    writeln(fp,realname);                     { real name          }
    writeln(fp,'');                           { "call sign" ?      }
    writeln(fp,ageuser(bday));                { age                }
    writeln(fp,sex);                          { sex                }
    str(credit:7,s); writeln(fp,s+'.00');     { credit             }
    writeln(fp,laston);                       { laston date        }
    writeln(fp,linelen);                      { # screen columns   }
    writeln(fp,pagelen);                      { # screen rows      }
    writeln(fp,sl);                           { SL                 }
    writeln(fp,bo(so));                       { is he a SysOp?     }
    writeln(fp,bo(cso));                      { is he a CoSysOp?   }
    writeln(fp,bo(okansi));                   { is graphics on?    }
    writeln(fp,bo(incom));                    { is remote?         }
    str(nsl:10:2,s); writeln(fp,s);           { time left (sec)    }
    writeln(fp,systat.gfilepath);             { gfiles path        }
    writeln(fp,systat.gfilepath);             { data path          }
    writeln(fp,'SYSOP.LOG');                  { SysOp log filespec }
    s:=spd; if (s='KB') then s:='0';          { baud rate          }
    writeln(fp,s);
    writeln(fp,modemr.comport);               { COM port           }
    writeln(fp,stripcolor(systat.bbsname));   { system name        }
    writeln(fp,systat.sysopname);             { SysOp's name       }
    with timeon do begin
      ton:=hour*3600.0+min*60.0+sec;
      tused:=timer-ton;
      if (tused<0) then tused:=tused+3600.0*24.0;
    end;
    writeln(fp,trunc(ton));                   { secs on f/midnight }
    writeln(fp,trunc(tused));                 { time used (sec)    }
    writeln(fp,uk);                           { upload K           }
    writeln(fp,uploads);                      { uploads            }
    writeln(fp,dk);                           { download K         }
    writeln(fp,downloads);                    { downloads          }
    writeln(fp,'8N1');                        { COM parameters     }
  end;
  close(fp);
end;

procedure write_callinfo_bbs(rname:boolean);
var fp:text;
		s:astr;

  function bo(b:boolean):astr;
  begin
    if b then bo:='1' else bo:='0';
  end;

begin
  assign(fp,'callinfo.bbs');
  rewrite(fp);
  with thisuser do begin
    if (rname) then writeln(fp,allcaps(thisuser.realname)) else writeln(fp,allcaps(thisuser.name));
    if spd='300' then s:='1' else
      if spd='1200' then s:='2' else
      if spd='2400' then s:='0' else
      if spd='9600' then s:='3' else
      if spd='KB' then s:='5' else
      s:='4';
    writeln(fp,s);
    writeln(fp,allcaps(thisuser.citystate));
    writeln(fp,cstr(thisuser.sl));
    writeln(fp,timestr);
    if okansi then writeln(fp,'COLOR') else writeln(fp,'MONO');
    writeln(fp,thisuser.pw);
    writeln(fp,cstr(usernum));
    writeln(fp,'0');
    writeln(fp,copy(time,1,5));
    writeln(fp,copy(time,1,5)+' '+date);
    writeln(fp,'A');
    writeln(fp,'0');
    writeln(fp,'999999');
    writeln(fp,'0');
    writeln(fp,'999999');
    writeln(fp,thisuser.ph);
    writeln(fp,thisuser.laston+' 00:00');
    if (novice in thisuser.ac) then writeln(fp,'NOVICE') else writeln(fp,'EXPERT');
    writeln(fp,'All');
    writeln(fp,'01/01/80');
    writeln(fp,cstr(thisuser.loggedon));
    writeln(fp,cstr(thisuser.pagelen));
    writeln(fp,'0');
    writeln(fp,cstr(thisuser.uploads));
    writeln(fp,cstr(thisuser.downloads));
    writeln(fp,'8  { Databits }');
    if ((incom) or (outcom)) then writeln(fp,'REMOTE') else writeln(fp,'LOCAL');
    if ((incom) or (outcom)) then writeln(fp,'COM'+cstr(modemr.comport)) else writeln(fp,'COM0');
    writeln(fp,thisuser.bday);
    if spd='KB' then writeln(fp,cstr(modemr.waitbaud)) else writeln(fp,spd);
    if ((incom) or (outcom)) then writeln(fp,'TRUE') else writeln(fp,'FALSE');
    if (spdarq) then write(fp,'MNP/ARQ') else write(fp,'Normal');
    writeln(fp,' Connection');
    writeln(fp,'12/31/99 23:59');
    writeln(fp,'1');
    writeln(fp,'1');
  end;
  close(fp);
end;

procedure write_sfdoors_dat(rname:boolean);   { Spitfire SFDOORS.DAT }
var fp:text;
    s:astr;
begin
  assign(fp,'SFDOORS.DAT');
  rewrite(fp);
  writeln(fp,cstr(usernum));
  if (rname) then writeln(fp,allcaps(thisuser.realname)) else writeln(fp,allcaps(thisuser.name));
  writeln(fp,thisuser.pw);
  if (rname) then begin
    if (pos(' ',thisuser.realname)=0) then s:=thisuser.realname
    else s:=copy(thisuser.realname,1,pos(' ',thisuser.realname)-1);
  end else begin
    if (pos(' ',thisuser.name)=0) then s:=thisuser.name
    else s:=copy(thisuser.name,1,pos(' ',thisuser.name)-1);
  end;
  writeln(fp,s);
  if (spd='KB') then writeln(fp,'0') else writeln(fp,cstr(modemr.comport));
  writeln(fp,timestr);
  writeln(fp,'0');   { seconds since midnight }
  writeln(fp,start_dir);
  if okansi then writeln(fp,'TRUE') else writeln(fp,'FALSE');
  writeln(fp,cstr(thisuser.sl));
  writeln(fp,cstr(thisuser.uploads));
  writeln(fp,cstr(thisuser.downloads));
  writeln(fp,cstr(systat.timeallow[thisuser.sl]));
  writeln(fp,'0');   { time on (seconds) }
  writeln(fp,'0');   { extra time (seconds) }
  writeln(fp,'FALSE');
  writeln(fp,'FALSE');
  writeln(fp,'FALSE');
  if (spd='KB') then writeln(fp,'0') else writeln(fp,spd);
  close(fp);
end;

procedure dodoorfunc(kind:char; cline:astr);
var doorstart,doorend,doortime:datetimerec;
    s,cline2:astr;
    retcode,savsl,savdsl:integer;
    realname:boolean;
begin
  realname:=FALSE;
  if ((sqoutsp(cline)='') and (incom)) then begin
    print('This command is inoperative!');
    if (cso) then print('(An MString of "" will shell to DOS LOCALLY!)');
    exit;
  end;

  if ((realsl<>-1) and (realdsl<>-1)) then begin
    savsl:=thisuser.sl; savdsl:=thisuser.dsl;
    thisuser.sl:=realsl; thisuser.dsl:=realdsl;
    saveuf;
  end;

(*  sprint(#3#3+'[> '+#3#0+'Opening door on '+
         #3#5+date+' '+time+#3#0+' ...  Please wait.');*)
  cline2:=cline;
  if copy(allcaps(cline2),1,2)='R;' then begin
    realname:=TRUE;
    cline2:=copy(cline2,3,length(cline2)-2);
  end;
  s:=process_door(cline2);
  case kind of
    'C':begin
          commandline('Outputting CHAIN.TXT (WWIV) ...');
          write_chain_txt;
        end;
    'D':begin
          commandline('Outputting DORINFO1.DEF (RBBS-PC) ...');
          write_dorinfo1_def(realname);
        end;
    'G':begin
          commandline('Outputting DOOR.SYS (GAP) ...');
          write_door_sys(realname);
        end;
    'S':begin
          commandline('Outputting SFDOORS.DAT (Spitfire) ...');
          write_sfdoors_dat(realname);
        end;
    'W':begin
          commandline('Outputting CALLINFO.BBS (Wildcat!) ...');
          write_callinfo_bbs(realname);
        end;
  end;
  commandline('Now running "'+s+'"');
  sysoplog('>> '+date+' '+time+'- Door "'+s+'"');
  close(sysopf);

  getdatetime(doorstart);
  shel1; shelldos(FALSE,s,retcode); shel2;
  getdatetime(doorend);
  timediff(doortime,doorstart,doorend);

  chdir(start_dir);
  append(sysopf);

  if ((realsl<>-1) and (realdsl<>-1)) then begin
    reset(uf); seek(uf,usernum); read(uf,thisuser); close(uf);
    thisuser.sl:=savsl; thisuser.dsl:=savdsl;
  end;

  com_flush_rx;
  getdatetime(tim);

  sysoplog('>> '+date+' '+time+'- Returned (spent '+longtim(doortime)+')');
end;

end.
