(*****************************************************************************)
(*>                                                                         <*)
(*>  SYSOP3  .PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  SysOp functions: User Editor.                                          <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit sysop3;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common;

procedure restric_list;
procedure uedit1;
procedure autoval(var u:userrec; un:integer);
procedure showuserinfo(typ,usern:integer; user1:userrec);
procedure uedit(usern:integer);

implementation

uses
  mail0,
  misc3, misc4, miscx,
  cuser;

procedure uedit1;
begin
  uedit(usernum);
end;

procedure restric_list;
begin
  begin
    nl;
    sprint(#3#3+'Restrictions:');
    nl;
    lcmds(27,3,'LCan logon ONLY once/day','CCan''t page SysOp');
    lcmds(27,3,'VPosts marked unvalidated','Back/downspacing restricted');
    lcmds(27,3,'ACan''t add to BBS list','*Can''t post/send anon.');
    lcmds(27,3,'PCan''t post at all','ECan''t send email');
    lcmds(27,3,'KCan''t vote','MAutomatic mail deletion');
    nl;
    sprint(#3#3+'Special:');
    nl;
    lcmds(27,3,'1No UL/DL ratio check','2No post/call ratio check');
    lcmds(27,3,'3No file points check','4Protection from deletion');
    nl;
  end;
end;

function spflags(u:userrec):astr;
var r:uflags;
    s:astr;
begin
  s:='';
  for r:=rlogon to rmsg do
    if r in u.ac then
      s:=s+copy('LCVBA*PEKM',ord(r)+1,1)
    else s:=s+'-';
  s:=s+'/';
  for r:=fnodlratio to fnodeletion do
    if r in u.ac then
      s:=s+copy('1234',ord(r)-19,1)
    else s:=s+'-';
  spflags:=s;
end;

procedure autoval(var u:userrec; un:integer);
begin
  autovalidate(u,un);
  print('User Validated.');
end;

procedure showuserinfo(typ,usern:integer; user1:userrec);
var ii:array[1..12] of astr;
    i:integer;
    abort,next:boolean;

  procedure shi1(var i:integer);
  var c:char;
      r:uflags;
      a,b:integer;
  begin
    with user1 do
      case i of
        1:begin
            ii[1]:=#3#5+mln('User #'+cstr(usern)+' of '+cstr(filesize(uf)-1),19)+#3#1+'Status:';
            if (deleted) then ii[1]:=ii[1]+#3#8+'Deleted' else
              if (trapactivity) and ((usern<>usernum) or (usernum=1)) then
                if (trapseperate) then ii[1]:=ii[1]+#3#8+'Trapping (seperate)'
                else ii[1]:=ii[1]+#3#8+'Trapping (common)'
              else
                if (lockedout) then ii[1]:=ii[1]+#3#8+'Locked out' else
                  if (alert in ac) then ii[1]:=ii[1]+#3#8+'Alert!' else
                    ii[1]:=ii[1]+#3#3+'Normal';
            ii[1]:=mln(ii[1],49)+#3#1+'SL:'+#3#3+mn(sl,3)+#3#1+'  DSL:'+#3#3+mn(dsl,3);
          end;
        2:begin
            ii[2]:='User name:'+#3#3+mln(name,36)+#3#1+'   AR:'+#3#3;
            for c:='A' to 'Z' do
              if c in ar then ii[2]:=ii[2]+c else ii[2]:=ii[2]+'-';
          end;
        3:ii[3]:='Real name:'+#3#3+mln(realname,36)+#3#1+'   AC:'+#3#3+spflags(user1);
        4:ii[4]:='Address      :'+#3#3+mln(street,30)+#3#1+'     Sex/Age :'+
                 #3#3+sex+cstr(ageuser(bday))+' ('+bday+')';
        5:ii[5]:='City / State :'+#3#3+mln(citystate,30)+#3#1+'     Zip-code:'+#3#3+zipcode;
        6:ii[6]:='Computer type:'+#3#3+mln(computer,30)+#3#1+'     Phone # :'+#3#3+ph;
        7:ii[7]:='SysOp note   :'+#3#3+mln(note,35)+#3#1+'Last/1st:'+#3#3+laston+' ('+firston+')';
        8:begin
            ii[8]:='Occupation   :'+#3#3+mln(occupation,35)+#3#1+'Lockfile:';
            if lockedout then ii[8]:=ii[8]+#3#7+lockedfile+'.MSG' else
              ii[8]:=ii[8]+'inactive.';
          end;
        9:begin
            ii[9]:='BBS reference:'+#3#3+mln(wherebbs,35)+#3#1+'Password:'+#3#3;
            if (realsl=255) or ((spd='KB') and (so)) then ii[9]:=ii[9]+mln(pw,20)
                                       else ii[9]:=ii[9]+#3#7+'xxxxxxxxxxxxxxxxxxxx';
          end;
       10:ii[10]:='Call records- TC:'+#3#3+mn(loggedon,7)+#3#1+
                               ' TT:'+#3#3+mln(cstrl(ttimeon),8)+#3#1+
                               ' CT:'+#3#3+mn(ontoday,9)+#3#1+
                               ' TL:'+#3#3+mn(tltoday,6)+#3#1+
                               ' Tbank:'+#3#3+mn(timebank,6);
       11:ii[11]:='Mail records- Pub:'+#3#3+mn(msgpost,6)+#3#1+
                               ' Priv:'+#3#3+mn(emailsent,6)+#3#1+
                               ' Fback:'+#3#3+mn(feedback,6)+#3#1+
                               ' Wait:'+#3#3+mn(waiting,6);
       12:ii[12]:='File records- DL:'+#3#3+mln(cstr(downloads)+'-'+cstrl(dk)+'k',19)+#3#1+
                               ' UL:'+#3#3+mln(cstr(uploads)+'-'+cstrl(uk)+'k',19)+#3#1+
                               ' Pts:'+#3#3+mn(filepoints,6);
      end;
    printacr(ii[i],abort,next);
    inc(i);
  end;

  procedure shi2(var i:integer);
  begin
    shi1(i);
  end;

begin
  abort:=FALSE;
  i:=1;
  case typ of
    1:while (i<=12) and (not abort) do shi1(i);
    2:while (i<=3) and (not abort) do shi2(i);
  end;
end;
(*
                        [ Locked out ]
                        [ Alert      ]
                        [ Deleted    ]
                        [ Normal     ]
User #1 of 105     Status:Locked out             SL:255  DSL:255
User name:123456789012345678901234567890123456   AR:ABCDEFG
Real name:123456789012345678901234567890123456   AC:LEKMC*KDJF/1234
Address      :123456789012345678901234567890     Sex/Age :Female / xxx
City / State :123456789012345678901234567890     Zip-code:xxxxx-xxxx
Computer type:123456789012345678901234567890     Phone # :xxx-xxx-xxxx
SysOp note   :123456789012345678901234567890     Last on :xx/xx/xx
Occupation   :1234567890123456789012345678901234 Lockfile:xxxxxxxx.MSG
BBS reference:1234567890123456789012345678901234 Password:12345678901234567890
Call records> TC:xxxxx   TT:xxxxx    CT:xxxxx     TL:xxxxx  Tbank:xxxxx
Mail records> Pub:xxxxx  Priv:xxxxx  Fback:xxxxx  Wait:xxxxx
File records> DL:xxxxx-xxxxxxxxxxxk  UL:xxxxx-xxxxxxxxxxxk  Pts:xxxxx

User #1 of 105     Status:Locked out             SL:255  DSL:255
User name:123456789012345678901234567890123456   AR:ABCDEFGHIJKLMNOPQRSTUVWXYZ
Real name:123456789012345678901234567890123456   AC:LEKMC*KDJF--------------
*)

procedure uedit(usern:integer);
type f_statusflagsrec=(fs_deleted,fs_trapping,fs_chatbuffer,
                       fs_lockedout,fs_alert,fs_slogging);
const autolist:boolean=TRUE;
      userinfotyp:byte=1;
      f_state:array[0..14] of boolean=
        (FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,
         FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE);
      f_gentext:string[30]='';
      f_acs:string[50]='';
      f_sl1:word=0; f_sl2:word=255;
      f_dsl1:word=0; f_dsl2:word=255;
      f_ar:set of acrq=[];
      f_ac:set of uflags=[];
      f_status:set of f_statusflagsrec=[];
      f_laston1:word=0; f_laston2:word=65535;
      f_firston1:word=0; f_firston2:word=65535;
      f_numcalls1:word=0; f_numcalls2:word=65535;
      f_age1:word=0; f_age2:word=65535;
      f_gender:char='M';
      f_postratio1:word=0; f_postratio2:word=65535;
      f_dlkratio1:word=0; f_dlkratio2:word=65535;
      f_dlratio1:word=0; f_dlratio2:word=65535;
var user,user1:userrec;
    r:uflags;
    f:file;
    ii,is,s:astr;
    i,i1,x,oldusern:integer;
    byt:byte;
    c:char;
    save,save1,abort,next:boolean;

  function unam:astr;
  begin
    unam:=caps(user.name)+' #'+cstr(usern);
  end;

  function searchtype(i:integer):string;
  var s:string;
  begin
    case i of
      0:s:='General text';           1:s:='Search ACS';
      2:s:='User SL';                3:s:='User DSL';
      4:s:='User AR flags';          5:s:='User AC flags';
      6:s:='User status';            7:s:='Days since last on';
      8:s:='Days since first on';    9:s:='Number of calls';
     10:s:='User age';               11:s:='User gender';
     12:s:='# 1/10''s call/post';    13:s:='#k DL/1k UL';
     14:s:='# DLs/1 UL';
    end;
    searchtype:=s;
  end;

  function find_fs:string;
  var fsf:f_statusflagsrec;
      s:string;
  begin
    s:='';
    for fsf:=fs_deleted to fs_slogging do
      if (fsf in f_status) then
        case fsf of
          fs_deleted   :s:=s+'deleted,';
          fs_trapping  :s:=s+'trapping,';
          fs_chatbuffer:s:=s+'chat buffering,';
          fs_lockedout :s:=s+'locked out,';
          fs_alert     :s:=s+'alert,';
          fs_slogging  :s:=s+'sep. SysOp Log,';
        end;
    if (s<>'') then s:=copy(s,1,length(s)-1) else s:='None.';
    find_fs:=s;
  end;

  procedure pcuropt;
  var r:uflags;
      s:string;
      i:integer;
      c:char;
      abort,next:boolean;
  begin
    nl;
    sprint(#3#5+'--(< Search limiting options >)--');
    i:=-1;
    abort:=FALSE; next:=FALSE;
    while ((i<14) and (not abort) and (not hangup)) do begin
      inc(i);
      if (i in [0..9]) then c:=chr(i+48) else
        case i of 10:c:='A'; 11:c:='G'; 12:c:='P'; 13:c:='K'; 14:c:='N'; end;
      if (i=1) then cl(3);
      sprompt(c+'. '+#3#1+mln(searchtype(i),19)+': '); s:='';
      if (not f_state[i]) then
        s:='Inactive!'
      else begin
        case i of
          0:s:='"'+f_gentext+'"';
          1:s:='"'+f_acs+'"';
          2:s:=cstr(f_sl1)+' SL ... '+cstr(f_sl2)+' SL';
          3:s:=cstr(f_dsl1)+' DSL ... '+cstr(f_dsl2)+' DSL';
          4:for c:='A' to 'Z' do
              if (c in f_ar) then s:=s+c else s:=s+'-';
          5:begin
              for r:=rlogon to rmsg do
                if (r in f_ac) then s:=s+copy('LCVBA*PEKM',ord(r)+1,1)
                else s:=s+'-';
              s:=s+'/';
              for r:=fnodlratio to fnodeletion do begin
                if (r in f_ac) then s:=s+copy('1234',ord(r)-19,1)
                else s:=s+'-';
              end;
            end;
          6:s:=find_fs;
          7:s:=cstr(f_laston1)+' days ... '+cstr(f_laston2)+' days';
          8:s:=cstr(f_firston1)+' days ... '+cstr(f_firston2)+' days';
          9:s:=cstr(f_numcalls1)+' calls ... '+cstr(f_numcalls2)+' calls';
         10:s:=cstr(f_age1)+' years ... '+cstr(f_age2)+' years';
         11:s:=aonoff(f_gender='M','Male','Female');
         12:s:=cstr(f_postratio1)+' ... '+cstr(f_postratio2);
         13:s:=cstr(f_dlkratio1)+' ... '+cstr(f_dlkratio2);
         14:s:=cstr(f_dlratio1)+' ... '+cstr(f_dlratio2);
        end;
        cl(3);
      end;
      sprint(s);
      wkey(abort,next);
    end;
    nl;
  end;

  function okusr(x:integer):boolean;
  var fsf:f_statusflagsrec;
      u:userrec;
      i,j:longint;
      ok:boolean;

    function nofindit(s:string):boolean;
    begin
      nofindit:=(pos(allcaps(f_gentext),allcaps(s))=0);
    end;

  begin
    with u do begin
      seek(uf,x); read(uf,u); ok:=TRUE;
      i:=-1;
      while ((ok) and (i<14)) do begin
        inc(i);
        if (f_state[i]) then
          case i of
            0:if ((nofindit(name)) and (nofindit(realname)) and
                  (nofindit(street)) and (nofindit(citystate)) and
                  (nofindit(zipcode)) and (nofindit(computer)) and
                  (nofindit(ph)) and (nofindit(note)) and
                  (nofindit(occupation)) and (nofindit(wherebbs))) then
                ok:=FALSE;
            1:if (not aacs1(u,x,f_acs)) then ok:=FALSE;
            2:if ((sl<f_sl1) or (sl>f_sl2)) then ok:=FALSE;
            3:if ((dsl<f_dsl1) or (dsl>f_dsl2)) then ok:=FALSE;
            4:if (not (ar>=f_ar)) then ok:=FALSE;
            5:if (not (ac>=f_ac)) then ok:=FALSE;
            6:for fsf:=fs_deleted to fs_slogging do
                if (fsf in f_status) then
                  case fsf of
                    fs_deleted   :if (not deleted) then ok:=FALSE;
                    fs_trapping  :if (not trapactivity) then ok:=FALSE;
                    fs_chatbuffer:if (not chatauto) then ok:=FALSE;
                    fs_lockedout :if (not lockedout) then ok:=FALSE;
                    fs_alert     :if (not (alert in ac)) then ok:=FALSE;
                    fs_slogging  :if (not slogseperate) then ok:=FALSE;
                  end;
            7:if ((daynum(laston)>daynum(date)-f_laston1) or
                  (daynum(laston)<daynum(date)-f_laston2)) then ok:=FALSE;
            8:if ((daynum(firston)>daynum(date)-f_firston1) or
                  (daynum(firston)<daynum(date)-f_firston2)) then ok:=FALSE;
            9:if ((loggedon<f_numcalls1) or (loggedon>f_numcalls2)) then ok:=FALSE;
           10:if (((ageuser(bday)<f_age1) or (ageuser(bday)>f_age2)) and
                  (ageuser(bday)<>0)) then
                ok:=FALSE;
           11:if (sex<>f_gender) then ok:=FALSE;
           12:begin
                j:=msgpost; if (j=0) then j:=1; j:=loggedon div j;
                if ((j<f_postratio1) or (j>f_postratio2)) then ok:=FALSE;
              end;
           13:begin
                j:=uk; if (j=0) then j:=1; j:=dk div j;
                if ((j<f_dlkratio1) or (j>f_dlkratio2)) then ok:=FALSE;
              end;
           14:begin
                j:=uploads; if (j=0) then j:=1; j:=downloads div j;
                if ((j<f_dlratio1) or (j>f_dlratio2)) then ok:=FALSE;
              end;
          end;
      end;
    end;
    okusr:=ok;
  end;

  procedure search(i:integer);
  var u:userrec;
      n:integer;
      c:char;
  begin
    n:=usern;
    repeat
      inc(usern,i);
      if (usern<=0) then usern:=filesize(uf)-1;
      if (usern>=filesize(uf)) then usern:=1;
    until ((okusr(usern)) or (usern=n));
  end;

  procedure clear_f;
  var i:integer;
  begin
    for i:=0 to 14 do f_state[i]:=FALSE;

    f_gentext:=''; f_acs:='';
    f_sl1:=0; f_sl2:=255; f_dsl1:=0; f_dsl2:=255;
    f_ar:=[]; f_ac:=[]; f_status:=[];
    f_laston1:=0; f_laston2:=65535; f_firston1:=0; f_firston2:=65535;
    f_numcalls1:=0; f_numcalls2:=65535; f_age1:=0; f_age2:=65535;
    f_gender:='M';
    f_postratio1:=0; f_postratio2:=65535; f_dlkratio1:=0; f_dlkratio2:=65535;
    f_dlratio1:=0; f_dlratio2:=65535;
  end;

  procedure stopt;
  var fsf:f_statusflagsrec;
      i,usercount:integer;
      c,ch:char;
      done:boolean;
      s:astr;

    procedure chbyte(var x:integer);
    var s:astr;
        i:integer;
    begin
      input(s,3); i:=x;
      if (s<>'') then i:=value(s);
      if ((i>=0) and (i<=255)) then x:=i;
    end;

    procedure chword(var x:word);
    var s:astr;
        w:word;
    begin
      input(s,5);
      if (s<>'') then begin
        w:=value(s);
        if ((w>=0) and (w<=65535)) then x:=w;
      end;
    end;

    procedure inp_range(var w1,w2:word; r1,r2:word);
    begin
      print('Range: '+cstr(r1)+'..'+cstr(r2));
      prt('Lower limit ['+cstr(w1)+'] : '); chword(w1);
      prt('Upper limit ['+cstr(w2)+'] : '); chword(w2);
    end;
  
    function get_f_ac:string;
    var r:uflags;
        s:string;
    begin
      for r:=rlogon to rmsg do
        if (r in f_ac) then s:=s+copy('LCVBA*PEKM',ord(r)+1,1)
        else s:=s+'-';
      s:=s+'/';
      for r:=fnodlratio to fnodeletion do begin
        if (r in f_ac) then s:=s+copy('1234',ord(r)-19,1)
        else s:=s+'-';
      end;
      get_f_ac:=s;
    end;

  begin
    done:=FALSE;
    pcuropt;
    repeat
      prt('Change (?=help) : '); onek(c,'Q0123456789AGPKN?CLTU'^M);
      nl;
      case c of
        '0'..'9':i:=ord(c)-48;
        'A':i:=10; 'G':i:=11; 'P':i:=12; 'K':i:=13; 'N':i:=14;
      else
            i:=-1;
      end;
      if (i<>-1) then begin
        sprompt(#3#5+'[> '+#3#0);
        if (f_state[i]) then
          sprint(searchtype(i))
        else begin
          f_state[i]:=TRUE;
          sprint(searchtype(i)+' is now *ON*');
        end;
{        nl;}
      end;

      case c of
        '0':begin
              print('General text ["'+f_gentext+'"]');
              prt(':'); input(s,30);
              if (s<>'') then f_gentext:=s;
            end;
        '1':begin
              prt('Search ACS ["'+f_acs+'"]');
              prt(':'); inputl(s,50);
              if (s<>'') then f_acs:=s;
            end;
        '2':begin
              prt('Lower limit ['+cstr(f_sl1)+'] : ');
              chword(f_sl1);
              prt('Upper limit ['+cstr(f_sl2)+'] : ');
              chword(f_sl2);
            end;
        '3':inp_range(f_dsl1,f_dsl2,0,255);
        '4':repeat
              prt('Which AR flag? <CR>=Quit : ');
              onek(ch,^M'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
              if (ch<>^M) then
                if (ch in ['A'..'Z']) then
                  if (ch in f_ar) then f_ar:=f_ar-[ch] else f_ar:=f_ar+[ch];
            until ((ch=^M) or (hangup));
        '5':begin
              repeat
                prt('Restrictions ['+get_f_ac+'] [?]Help [Q]uit :');
                onek(c,'Q LCVBA*PEKM1234?'^M);
                case c of
                  ^M,' ','Q': ;
                  '?':restric_list;
                else
                      if (tacch(c) in f_ac) then f_ac:=f_ac-[tacch(c)]
                      else f_ac:=f_ac+[tacch(c)];
                end;
              until ((c in [^M,' ','Q']) or (hangup));
            end;
        '6':repeat
              s:=find_fs;
              sprint(#3#4+'Current flags: '+#3#3+s);
              prt('Toggle (?=help) : '); onek(ch,'QACDLST? '^M);
              if (pos(ch,'ACDLST')<>0) then begin
                case ch of
                  'A':fsf:=fs_alert;
                  'C':fsf:=fs_chatbuffer;
                  'D':fsf:=fs_deleted;
                  'L':fsf:=fs_lockedout;
                  'S':fsf:=fs_slogging;
                  'T':fsf:=fs_trapping;
                end;
                if (fsf in f_status) then f_status:=f_status-[fsf]
                  else f_status:=f_status+[fsf];
              end else
                if (ch='?') then begin
                  nl;
                  lcmds(15,3,'Alert','Chat-buffering');
                  lcmds(15,3,'Deleted','Locked-out');
                  lcmds(15,3,'Seperate SysOp logging','Trapping');
                  nl;
                end;
            until ((ch in ['Q',' ',^M]) or (hangup));
        '7':inp_range(f_laston1,f_laston2,0,65535);
        '8':inp_range(f_firston1,f_firston2,0,65535);
        '9':inp_range(f_numcalls1,f_numcalls2,0,65535);
        'A':inp_range(f_age1,f_age2,0,65535);
        'G':begin
              prt('Gender ['+f_gender+'] : ');
              onek(c,'QMF'^M); nl;
              if (c in ['F','M']) then f_gender:=c;
            end;
        'P':inp_range(f_postratio1,f_postratio2,0,65535);
        'K':inp_range(f_dlkratio1,f_dlkratio2,0,65535);
        'N':inp_range(f_dlratio1,f_dlratio2,0,65535);
        'C':if pynq('Are you sure? ') then clear_f;
        ^M,'L':pcuropt;
        'T':begin
              prt('Which? '); onek(ch,'Q0123456789AGPKN'^M);
              case ch of
                '0'..'9':i:=ord(ch)-48;
                'A':i:=10; 'G':i:=11; 'P':i:=12; 'K':i:=13; 'N':i:=14;
              else
                    i:=-1;
              end;
              if (i<>-1) then begin
                f_state[i]:=not f_state[i];
                sprompt(#3#5+'[> '+#3#0+searchtype(i)+' is now *');
                if (f_state[i]) then print('ON*') else print('OFF*');
              end;
              nl;
            end;
        'U':begin
              abort:=FALSE; usercount:=0;
              for i:=1 to filesize(uf)-1 do begin
                if (okusr(i)) then begin
                  seek(uf,i); read(uf,user1);
                  printacr(#3#3+caps(user1.name)+' #'+cstr(i),abort,next);
                  inc(usercount);
                end;
                if (abort) then i:=filesize(uf)-1;
              end;
              if (not abort) then
                sprint('@M^7 ** '+#3#5+cstr(usercount)+' Users.@M');
            end;
        'Q':done:=TRUE;
        '?':begin
              sprint(#3#3+'0-9,AGPKN'+#3#1+': Change option');
              lcmds(14,3,'List options','Toggle options on/off');
              lcmds(14,3,'Clear options','User''s who match');
              lcmds(14,3,'Quit','');
              nl;
            end;
      end;
      if (pos(c,'C0123456789AGPKN')<>0) then nl;
    until ((done) or (hangup));
  end;

  procedure killusermail;
  var u:userrec;
      pinfo:pinforec;
      mixr:msgindexrec;
      i,j:longint;
  begin
    savepinfo(pinfo);
    initbrd(-1);
    for i:=0 to himsg do begin
      seek(mixf,i); blockread(mixf,mixr,1);
      j:=mixr.messagenum;
      if ((miexist in mixr.msgindexstat) and (j=usern)) then s:=rmail(i);
(*      begin
        mixr.msgindexstat:=mixr.msgindexstat-[miexist];
        seek(mixf,filepos(mixf)-1); write(mixf,mixr);
        if ((j>=1) and (j<=filesize(uf)-1)) then begin
          seek(uf,j); read(uf,u);
          dec(u.waiting);
          seek(uf,j); write(uf,u);
        end;
      end;*)
    end;
    loadpinfo(pinfo);
  end;

  procedure killuservotes;
  var vdata:file of vdatar;
      vd:vdatar;
      i:integer;
  begin
    assign(vdata,systat.gfilepath+'voting.dat');
    {$I-} reset(vdata); {$I+}
    if (ioresult=0) then begin
      for i:=1 to filesize(vdata) do
        if (user.vote[i]>0) then begin
          seek(vdata,i-1); read(vdata,vd);
          dec(vd.answ[user.vote[i]].numres);
          seek(vdata,i-1); write(vdata,vd);
          user.vote[i]:=0;
        end;
      close(vdata);
    end;
  end;

  procedure delusr;
  var i:integer;
  begin
    if (not user.deleted) then begin
      save:=TRUE; user.deleted:=TRUE;
      dsr(user.name);
      sysoplog('* Deleted user: '+caps(user.name)+' #'+cstr(usern));
      i:=usernum; usernum:=usern;
      rsm;
      usernum:=i;
      user.waiting:=0;

      killusermail;
      killuservotes;
    end;
  end;

  procedure renusr;
  begin
    if (user.deleted) then print('Can''t rename deleted users.')
    else begin
      nl; prt('Enter new name: '); input(ii,36);
      if (ii<>'') and (ii[1] in ['A'..'Z','?']) then begin
        dsr(user.name); isr(ii,usern);
        user.name:=ii; save:=TRUE;
        if (usern=usernum) then thisuser.name:=ii;
      end;
    end;
  end;

  procedure chhflags;
  var done:boolean;
      c:char;
  begin
    nl;
    done:=FALSE;
    repeat
      prt('Restrictions ['+spflags(user)+'] [?]Help [Q]uit :');
      onek(c,'Q LCVBA*PEKM1234?'^M);
      case c of
        ^M,' ','Q':done:=TRUE;
        '?':restric_list;
      else
            begin
              if (c='4') and (not so) then print('You can''t change that!')
              else begin
                acch(c,user);
                save:=TRUE;
              end;
            end;
      end;
    until (done) or (hangup);
    save:=TRUE;
  end;

  procedure chhsl;
  begin
    prt('Enter new SL: '); ini(byt);
    if (not badini) then begin
      save:=TRUE;
      if (byt<thisuser.sl) or (usernum=1) then begin
        if (usernum=usern) and (byt<thisuser.sl) then
          if not pynq('Lower your own SL level? ') then exit;
        user.sl:=byt;
      end else begin
        sysoplog('UEDIT: Illegal SL change- '+caps(user.name)+' #'+cstr(usern)+
                 ' to '+cstr(byt));
        print('Access denied.'^G);
      end;
    end;
  end;

  procedure chhdsl;
  begin
    prt('Enter new DSL: '); ini(byt);
    if (not badini) then begin
      save:=TRUE;
      if (byt<thisuser.dsl) or (usernum=1) then begin
        if (usernum=usern) and (byt<thisuser.sl) then
          if not pynq('Lower your own DSL level? ') then exit;
        user.dsl:=byt;
      end else begin
        sysoplog('UEDIT: Illegal DSL change- '+caps(user.name)+' #'+cstr(usern)+
                 ' to '+cstr(byt));
        print('Access denied.'^G);
      end;
    end;
  end;

  procedure chrecords(beg:byte);
  var on:byte;
      done:boolean;
      c:char;
      i:integer;
  begin
    on:=beg;
    done:=FALSE;
    with user do
      repeat
        nl;
        case on of
          1:begin
              sprint(#3#5+'Call records:');
              print('(0)Total calls: '+mn(loggedon,5)+' (1)Total time on:   '+mn(trunc(ttimeon),8));
              print('(2)Calls today: '+mn(ontoday,5)+ ' (3)Time left today: '+mn(tltoday,5));
              print('(4)Illegal logon attempts: '+mn(illegal,5));
              nl;
              prt('Select: (0-4) [M]ail [F]ile [Q]uit :');
              onek(c,'Q01234MF'^M);
            end;
          2:begin
              sprint(#3#5+'Mail records:');
              print('(0)Pub. posts: '+mn(msgpost,5)+' (1)Priv. posts:  '+mn(emailsent,5));
              print('(2)Fback sent: '+mn(feedback,5)+' (3)Mail waiting: '+mn(waiting,5));
              nl;
              prt('Select: (0-3) [C]all [F]ile [Q]uit :');
              onek(c,'Q0123CF'^M);
            end;
          3:begin
              sprint(#3#5+'File records:');
              print('(0)# of DLs: '+mn(downloads,5)+' (1)DL k: '+cstr(trunc(dk)));
              print('(2)# of ULs: '+mn(uploads,5)+' (3)UL k: '+cstr(trunc(uk)));
              nl;
              prt('Select: (0-3) [C]all [M]ail [Q]uit :');
              onek(c,'Q0123CM'^M);
            end;
        end;
        case c of
          'Q',^M:done:=TRUE;
          'C':on:=1;
          'M':on:=2;
          'F':on:=3;
          '0'..'4':begin
            nl; prt('New value: '); inu(i);
            if not badini then
              case on of
                1:case value(c) of
                    0:loggedon:=i; 1:ttimeon:=i; 2:ontoday:=i; 3:tltoday:=i;
                    4:illegal:=i;
                  end;
                2:case value(c) of
                    0:msgpost:=i; 1:emailsent:=i; 2:feedback:=i; 3:waiting:=i;
                  end;
                3:case value(c) of
                    0:downloads:=i; 1:dk:=i; 2:uploads:=i; 3:uk:=i;
                  end;
              end;
          end;
        end;
      until (done) or (hangup);
  end;

  function onoff(b:boolean; s1,s2:astr):astr;
  begin
    if b then onoff:=s1 else onoff:=s2;
  end;

  procedure lcmds3(len,c:byte; c1,c2,c3:astr);
  var s:astr;
  begin
    s:='';
    s:=s+#3#1+'('+#3+chr(c)+c1[1]+#3#1+')'+mln(copy(c1,2,lenn(c1)-1),len-1);
    if (c2<>'') then
      s:=s+#3#1+'('+#3+chr(c)+c2[1]+#3#1+')'+mln(copy(c2,2,lenn(c2)-1),len-1);
    if (c3<>'') then
      s:=s+#3#1+'('+#3+chr(c)+c3[1]+#3#1+')'+copy(c3,2,lenn(c3)-1);
    printacr(s,abort,next);
  end;

begin
  reset(uf);
  if ((usern<1) or (usern>filesize(uf)-1)) then begin close(uf); exit; end;
  if (usern=usernum) then begin
    user:=thisuser;
    seek(uf,usern); write(uf,user);
  end;
  seek(uf,usern); read(uf,user);

  clear_f;

  oldusern:=0;
  save:=FALSE;
  repeat
    abort:=FALSE;
    if (autolist) or (usern<>oldusern) or (c=^M) then begin
      nl; nl;
      showuserinfo(userinfotyp,usern,user);
      oldusern:=usern;
    end;
    nl;
    sprompt(#3#5+'Option :'+#3#9);
    onek(c,'Q?[]={}*^@!ACDEFGIKLMNOPRSTUWYZ$123''#&-_;:\~'^M);
    case c of
      '?':begin
            nl; sprint(#3#5+'User-list command help'); nl;
            print('<CR>Redisplay user');
            lcmds3(21,3,';New list mode',':Autolist mode toggle','');
            lcmds3(21,3,'[Back one user',']Forward one user','=Ooops (reload old data)');
            lcmds3(21,3,'{Search backward','}Search forward','*Auto-validate user');
            lcmds3(21,3,'~Trap/chat logging','@Lockout/Unlockout','!Toggle alert status');
            lcmds3(21,3,'Address','City and state','DSL');
            lcmds3(21,3,'ERestrictions','FAR flags','GSex/Age');
            lcmds3(21,3,'IOccupation','KSysOp comments','Laston date');
            lcmds3(21,3,'Mailbox','Name or handle','OSearch options');
            lcmds3(21,3,'Phone number','Real user name','SL');
            lcmds3(21,3,'Type of computer','UGoto user name/#','WBBS reference');
            lcmds3(21,3,'YMessage SysOp bases','Zip code','$Password');
            lcmds3(21,3,'1Call records','2Mail records','3File records');
            lcmds3(21,3,'''User colors','#File points','&Time bank');
            lcmds3(21,3,'^Delete/Restore user','-New user answers','_Other Q. answers');
            lcmds3(21,3,'\Show SysOp Log','','');
            lcmds3(21,3,'Quit editor','','');
            pausescr;
            save:=FALSE;
          end;
      '[',']','{','}','U','Q':begin
            if save then begin
              seek(uf,usern); write(uf,user);
              if usern=usernum then thisuser:=user;
              save:=FALSE;
            end;
            case c of
              '[':begin
                    dec(usern);
                    if (usern<=0) then usern:=filesize(uf)-1;
                  end;
              ']':begin
                    inc(usern);
                    if (usern>=filesize(uf)) then usern:=1;
                  end;
              '{':begin
                    nl; prompt('Searching ... ');
                    search(-1); nl;
                  end;
              '}':begin
                    nl; prompt('Searching ... ');
                    search(1);  nl;
                  end;
              'U':begin
                    prt('Enter user name, #, or partial search string: ');
                    finduserws(i);
                    if (i>0) then begin
                      seek(uf,i); read(uf,user);
                      usern:=i;
                    end;
                  end;
            end;
            seek(uf,usern); read(uf,user);
            if (usern=usernum) then thisuser:=user;
          end;
      '=':if pynq('@M'+#3#7+'Reload old user data? ') then begin
            seek(uf,usern); read(uf,user);
            if (usern=usernum) then thisuser:=user;
            save:=FALSE;
            sprint(#3#7+'Old data reloaded.');
          end;
      'O','-','_',';',':','\':
          begin
            case c of
              'O':stopt;
              '-':begin
                    readasw(usern,systat.afilepath+'newuser');
                    pausescr;
                  end;
              '_':begin
                    nl;
                    prt('Print questionairre file: '); mpl(8); input(s,8); nl;
                    readasw(usern,systat.afilepath+s);
                    pausescr;
                  end;
              ';':begin
                    nl;
                    prt('(L)ong or (S)hort list mode : ');
                    onek(c,'QSL '^M);
                    case c of
                      'S':userinfotyp:=2;
                      'L':userinfotyp:=1;
                    end;
                  end;
              ':':autolist:=not autolist;
              '\':begin
                    s:=systat.trappath+'slog'+cstr(usern)+'.log';
                    printf(s);
                    if (nofile) then print('"'+s+'": file not found.');
                    pausescr;
                  end;
            end;
          end;
      '*','^','@','!','A','C','D','E','F','G','I','K','L','M',
      'N','P','R','S','T','W','Y','Z','$','1','2','3','''','#','&','~':
          begin
            if ((thisuser.sl<=user.sl) or (thisuser.dsl<=user.dsl)) and
               (usernum<>1) and (usernum<>usern) then begin
              sysoplog('UEDIT: Tried to modify '+
                       caps(user.name)+' #'+cstr(usern));
              print('Access denied.');
            end else begin
              save1:=save; save:=TRUE;
              case c of
                '*':begin
                      autoval(user,usern);
                      ssm(abs(usern),^G'You were validated on '+date+' '+time+'.'^G);
                    end;
                '^':if (user.deleted) then begin
                      print('User is currently deleted.');
                      nl;
                      if pynq('Restore this user? ') then begin
                        isr(user.name,usern);
                        user.deleted:=FALSE;
                      end else
                        save:=save1;
                    end else
                      if (fnodeletion in user.ac) then begin
                        print('Access denied - This user is protected from deletion.');
                        sysoplog('* Attempt to delete user: '+caps(user.name)+
                                 ' #'+cstr(usern));
                        nl; pausescr;
                        save:=save1;
                      end else begin
                        print('User is not currently deleted.');
                        nl;
                        print('NOTE: If this user is deleted, ALL VOTING RECORDS,');
                        print('AND ANY EMAIL TO OR FROM THIS USER WILL BE DELETED.');
                        nl;
                        if pynq('*DELETE* this user? ') then delusr
                        else save:=save1;
                      end;
                '@':begin
                      nl;
                      user.lockedout:=not user.lockedout;
                      if (user.lockedout) then begin
                        print('User is now LOCKED out.');
                        nl;
                        print('Each time the user logs on from now on, a text file will');
                        print('be displayed before connection is terminated.');
                        nl;
                        prt('Enter lockout filename: ');
                        mpl(8); input(ii,8);
                        if (ii='') then user.lockedout:=FALSE
                        else begin
                          user.lockedfile:=ii;
                          sysoplog('UEDIT: Locked '+unam+' out: Lockfile "'+ii+'"');
                        end;
                      end;
                      if (not user.lockedout) then
                        print('User is no longer locked out of system.');
                      nl;
                      pausescr;
                    end;
                '!':if (alert in user.ac) then user.ac:=user.ac-[alert]
                                else user.ac:=user.ac+[alert];
                'A':cstuff(1,3,user);
                'C':cstuff(4,3,user);
                'D':chhdsl;
                'E':chhflags;
                'F':begin
                      nl;
                      repeat
                        prt('Which AR flag? <CR>=Quit : ');
                        onek(c,'ABCDEFGHIJKLMNOPQRSTUVWXYZ'^M);
                        if (c<>^M) then
                          if (not (c in thisuser.ar)) and (usernum<>1) then begin
                            sysoplog('UEDIT: Tried to give '+caps(user.name)+
                                     ' #'+cstr(usern)+' AR flag "'+c+'"');
                            print('Access denied.'^G)
                          end else
                            if (c in ['A'..'Z']) then
                              if (c in user.ar) then user.ar:=user.ar-[c]
                                                else user.ar:=user.ar+[c];
                      until (c=^M) or (hangup);
                      c:=#0;
                    end;
                'G':begin
                      cstuff(2,3,user);
                      cstuff(12,3,user);
                    end;
                'I':cstuff(6,3,user);
                'K':begin
                      nl;
                      print('New SysOp Note: ');
                      prt(':'); mpl(39); inputl(s,39);
                      if (s<>'') then user.note:=s;
                    end;
                'L':begin
                      nl;
                      print('New Laston date, in the form MM/DD/YY:');
                      prt(':'); mpl(8); inputl(s,8);
                      if (s<>'') and (daynum(s)<>0) then user.laston:=s;
                    end;
                'M':cstuff(15,3,user);
                'N':renusr;
                'P':cstuff(8,3,user);
                'R':cstuff(10,3,user);
                'S':chhsl;
                'T':cstuff(5,3,user);
                'W':cstuff(13,3,user);
                'Y':begin
                      nl;
                      prt('Message base SysOp:'); nl;
                      nl;
                      for i:=1 to 5 do prompt(cstr(i)+') '+cstr(user.boardsysop[i])+'  ');
                      nl; print('(-1 is inactive)');
                      nl;
                      prt('Which number? (1-5) :'); ini(byt); i:=byt;
                      if (not badini) then begin
                        prt('Which message base? (1-'+cstr(numboards)+') :'); ini(byt);
                        if (not badini) then
                          if ((byt>=1) and (byt<=numboards)) or (byt=-1) then
                            user.boardsysop[i]:=byt;
                      end;
                    end;
                'Z':cstuff(14,3,user);
                '$':cstuff(9,3,user);
                '1'..'3':chrecords(value(c));
                '''':cstuff(21,3,user);
                '#':begin
                      nl;
                      prt('Enter new amount of file points.'); nl;
                      prt(':'); mpl(5); inu(i);
                      if (not badini) then user.filepoints:=i;
                    end;
                '&':begin
                      nl;
                      prt('Enter new amount of time in time bank.'); nl;
                      prt(':'); mpl(5); inu(i);
                      if (not badini) then user.timebank:=i;
                    end;
                '~':begin
                      repeat
                        nl;
                        sprint('1. Trapping status: '+
                          onoff(user.trapactivity,
                          #3#7+onoff(user.trapseperate,
                          'Trapping to TRAP'+cstr(usern)+'.MSG',
                          'Trapping to TRAP.MSG'),
                          'Off')+onoff(systat.globaltrap,#3#8+' <GLOBAL>',''));
                        sprint('2. Auto-chat state: '+onoff(user.chatauto,
                          onoff(user.chatseperate,
                          #3#7+'Output to CHAT'+cstr(usern)+'.MSG',
                          #3#7+'Output to CHAT.MSG'),'Off')+
                          onoff(systat.autochatopen,#3#8+' <GLOBAL>',''));
                        sprint('3. SysOp Log state: '+onoff(user.slogseperate,
                          #3#7+'Logging to SLOG'+cstr(usern)+'.LOG',
                          #3#3+'Normal output'));
                        nl;
                        prt('Select (1-3,Q=Quit) : '); onek(c,'Q123'^M);
                        if (c in ['1'..'3']) then begin
                          nl;
                          case c of
                            '1':begin
                                  dyny:=user.trapactivity;
                                  user.trapactivity:=
                                    pynq('Trap user activity? ['+
                                    syn(user.trapactivity)+'] : ');
                                  if (user.trapactivity) then begin
                                    dyny:=user.trapseperate;
                                    user.trapseperate:=
                                      pynq('Log to seperate file? ['+
                                      syn(user.trapseperate)+'] : ');
                                  end else
                                    user.trapseperate:=FALSE;
                                end;
                            '2':begin
                                  dyny:=user.chatauto;
                                  user.chatauto:=
                                    pynq('Auto-chat buffer open? ['+
                                    syn(user.chatauto)+'] : ');
                                  if (user.chatauto) then begin
                                    dyny:=user.chatseperate;
                                    user.chatseperate:=
                                      pynq('Seperate buffer file? ['+
                                      syn(user.chatseperate)+'] : ');
                                  end else
                                    user.chatseperate:=FALSE;
                                end;
                            '3':begin
                                  dyny:=user.slogseperate;
                                  user.slogseperate:=
                                    pynq('Output SysOp Log seperately? ['+
                                    syn(user.slogseperate)+'] : ');
                                end;
                          end;
                        end;
                      until ((not (c in ['1'..'3'])) or (hangup));
                      c:=#0;
                    end;
                else
                      save:=save1;
              end;
            end;
          end;
    end;
    if (usern=usernum) then thisuser:=user;
  until (c='Q') or hangup;
  close(uf);
  topscr;
end;

end.
