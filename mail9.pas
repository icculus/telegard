{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit mail9;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common, timejunk, mail0, mail4;

procedure mbaselist;
procedure mbasechange(var done:boolean; mstr:astr);
procedure readamsg;
procedure wamsg;
procedure replyamsg;
procedure mbasestats;

implementation

procedure mbaselist;
var s,os:astr;
    b,b2,i,onlin,nd:integer;
    abort,next,acc,showtitles:boolean;

  procedure titles;
  var sep:astr;
  begin
    sep:=#3#4+':'+#3#3;
    if (showtitles) then begin
      sprint(#3#3+'NNN'+sep+'Flags         '+sep+'Type '+sep+'Description');
      sprint(#3#4+'อออหออออออออออออออหอออออหออออออออออออออออออออออออออออออออออออออออ=');
      showtitles:=FALSE;
    end;
  end;

  procedure longlist;
  var s1:string[5];
  begin
    nl;
    showtitles:=TRUE;
    s1:='     ';
    while ((b<=numboards) and (not abort)) do begin
      acc:=mbaseac(b);
      if ((mbunhidden in memboard.mbstat) or (acc)) then begin
        titles;
        if (acc) then begin
          s:=#3#5+cstr(ccboards[1][b]);
          while (length(s)<6) do s:=s+' ';
          if (b in zscanr.mzscan) then s:=s+#3#9+'Scan ' else s:=s+#3#9+s1;
        end else
          s:=#3#9+'         ';
        if (not (mbfilter in memboard.mbstat)) then s:=s+'ANSI ' else s:=s+s1;
        if (mbrealname in memboard.mbstat) then s:=s+'Real ' else s:=s+s1;
        case memboard.mbtype of
          0:s:=s+#3#3+'Local '+#3#5;
          1:s:=s+#3#3+'Echo  '+#3#0;
          2:s:=s+#3#3+'Group '+#3#0;
        end;
        s:=s+memboard.name;
        sprint(s);
        inc(nd);
        if (not empty) then wkey(abort,next);
      end;
      inc(b);
    end;
  end;

  procedure shortlist;
  begin
    nl;
    while ((b<=numboards) and (not abort)) do begin
      acc:=mbaseac(b);
      if ((mbunhidden in memboard.mbstat) or (acc)) then begin
        if (acc) then begin
          b2:=ccboards[1][b];
          if (memboard.mbtype=0) then s:=#3#5 else s:=#3#0;
          if (b2<10) then s:=s+' '; s:=s+cstr(b2);
          if (b in zscanr.mzscan) then s:=s+'* ' else s:=s+'  ';
        end else
          s:='    ';
        s:=s+#3#5+memboard.name;
        inc(onlin); inc(nd);
        if (onlin=1) then begin
          if (lennmci(s)<=40) then s:=mlnmci(s,40);
          sprompt(s); os:=s;
          if (lennmci(s)>40) then begin nl; onlin:=0; end;
        end else begin
          os:='';
          if (thisuser.linelen>=80) then begin
            if (lennmci(s)>40) then begin nl; os:=''; end;
          end else nl;
          sprint(os+s);
          onlin:=0;
        end;
        if (not empty) then wkey(abort,next);
      end;
      inc(b);
    end;
    if ((onlin=1) and (thisuser.linelen>=80)) then nl;
  end;

begin
  nl;
  abort:=FALSE;
  onlin:=0; s:=''; b:=1; nd:=0;
  if pynq('Display detailed area listing? ') then longlist else shortlist;
  if (nd=0) then sprompt(#3#7+'No message bases.');
end;

procedure mbasechange(var done:boolean; mstr:astr);
var s:astr;
    i:integer;
begin
  if mstr<>'' then
    case mstr[1] of
      '+':begin
            i:=board;
            if (board>=numboards) then i:=0 else
              repeat
                inc(i);
                changeboard(i);
              until (board=i) or (i>numboards);
            if (board<>i) then sprint('@MHighest accessible message base.')
              else lastcommandovr:=TRUE;
          end;
      '-':begin
            i:=board;
            if board<=0 then i:=numboards else
              repeat
                dec(i);
                changeboard(i);
              until (board=i) or (i<=0);
            if (board<>i) then sprint('@MLowest accessible message base.')
              else lastcommandovr:=TRUE;
          end;
      'L':mbaselist;
    else
          begin
            changeboard(value(mstr));
            if pos(';',mstr)>0 then begin
              s:=copy(mstr,pos(';',mstr)+1,length(mstr));
              curmenu:=systat.menupath+s+'.mnu';
              newmenutoload:=TRUE;
              done:=TRUE;
            end;
            lastcommandovr:=TRUE;
          end;
    end
  else begin
    if (novice in thisuser.ac) then mbaselist;
    nl;
    s:='?';
    repeat
      sprompt('^7Change message base (^3?^7=^3List^7) : ^3');
      input(s,3); i:=ccboards[0][value(s)];
      if s='?' then begin mbaselist; nl; end else
        if (i>=1) and (i<=numboards) and (i<>board) then
          changeboard(i);
    until (s<>'?') or (hangup);
    lastcommandovr:=TRUE;
  end;
end;

procedure readamsg;
var filv:text;
    s:astr;
    i,j:integer;
begin
  nl;
  assign(filv,systat.afilepath+'auto.msg');
  {$I-} reset(filv); {$I+}
  nofile:=(ioresult<>0);
  j:=0;
  if (nofile) then sprint(#3#0+'No AutoMessage available.')
  else begin
    readln(filv,s);
    case s[1] of
      '@':if (aacs(systat.anonpubread)) then
            s:=copy(s,2,length(s))+' (Posted Anonymously)'
            else s:='Anonymous';
      '!':if (cso) then s:=copy(s,2,length(s))+' (Posted Anonymously)'
                   else s:='Anonymous';
    end;
    sprint(fstring.automsgt+s);
    repeat
      readln(filv,s);
      if lenn(s)>j then j:=lenn(s);
    until (eof(filv));
    if (j>=thisuser.linelen) then j:=thisuser.linelen-1;
    reset(filv); readln(filv,s);
    cl(0);
    if ((not okansi) or (fstring.autom=#32)) then nl
      else for i:=1 to j do outkey(fstring.autom);
    nl;
    repeat
      readln(filv,s);
      sprint(#3#3+s);
    until eof(filv);
    cl(0);
    if ((not okansi) or (fstring.autom=#32)) then nl
      else for i:=1 to j do outkey(fstring.autom);
    nl;
    close(filv);
  end;
end;

procedure wamsg;
var filvar:text;
    i,j:integer;
    am:array[1..30] of astr;
    n:astr;
    c:char;
    abort,next:boolean;
begin
  if (ramsg in thisuser.ac) then
    print('You are restricted from writing automessages.')
  else begin
    abort:=FALSE;
    nl;
    if mso then begin
      print('Enter up to 30 lines, "." alone to end.');
      nl;
      i:=0;
      repeat
        inc(i);
        cl(3); inputwc(am[i],79);
      until ((am[i]='.') or (i=30) or (hangup));
      if (am[i]='.') then dec(i);
      j:=i;
    end else begin
      print('Enter three lines:');
      nl;
      for i:=1 to 3 do begin cl(3); inputwc(am[i],79); end;
      j:=3;
    end;
    nl;
    if (j<>0) then begin
      repeat
        abort:=FALSE;
        nl;
        for i:=1 to j do sprint(#3#3+am[i]);
        nl;
        sprompt(#3#7+'Is this alright? [R]elist (Y/N) [Y] : ');
        onekcr:=FALSE; onekda:=FALSE; onek(c,'NYR '^M); cl(3);
        case c of
          'R':print('Relist');
          'N':print('No');
        else
              print('Yes');
        end;
      until (c<>'R') or (hangup);
      if (c<>'N') then begin
        n:=nam;
        if (aacs(systat.anonpubpost)) then
          if pynq('Post Anonymously? ') then
            if (realsl=255) then n:='!'+n else n:='@'+n;

        assign(filvar,systat.afilepath+'auto.msg');
        {$I-} reset(filvar); {$I+}
        if (ioresult<>0) then assign(filvar,systat.afilepath+'auto.msg');
        rewrite(filvar);
        writeln(filvar,n);
        for i:=1 to j do writeln(filvar,am[i]);
        close(filvar);

        nl;
        print('Auto-message saved.');
        sysoplog('Changed Auto-message to:');
        for i:=1 to j do sysoplog(#3#3+am[i]);
      end else
        print('Nothing saved.');
    end else
      print('Nothing saved.');
  end;
end;

procedure replyamsg;
var autof:text;
begin
  nl;
  nofile:=FALSE;
  assign(autof,systat.afilepath+'auto.msg');
  {$I-} reset(autof); {$I+}
  if (ioresult<>0) then print('Nothing to reply to.')
  else begin
    irt:='Your auto-message';
    readln(autof,lastname);
    close(autof);
    if (lastname[1]='@') then
      if (not aacs(systat.anonprivread)) then lastname:='';
    if (lastname[1]='!') and (so) then lastname:='';
    if (lastname='') then print('Can''t reply now.') else autoreply;
  end;
end;

procedure mbasestats;
var s:astr;
    abort,next:boolean;

  procedure dd(var abort,next:boolean; s1,s2:astr; b:boolean);
  begin
    s1:=#3#3+s1+#3#5+' ';
    if (b) then printacr(s1+s2,abort,next)
      else printacr(s1+'None.',abort,next);
  end;

begin
  abort:=FALSE; next:=FALSE;
  nl;
  loadboard(board);
  with memboard do begin
    s:=#3#3+'Statistics on "'+#3#5+name+' #'+cstr(ccboards[1][board])+#3#3+'"';
    printacr(s,abort,next);
    nl;
    dd(abort,next,'Base password ........ :','"'+password+'"',(password<>''));
    dd(abort,next,'Max messages ......... :',cstr(maxmsgs),(maxmsgs<>0));
    case anonymous of
      atno      :s:='None allowed';
      atyes     :s:='Anonymous posts allowed';
      atforced  :s:='All posts forced anonymous';
      atdearabby:s:='Dear Abby base';
      atanyname :s:='Any Name Goes';
    end;
    dd(abort,next,'Anonymous type ....... :',s,TRUE);
    if (fso) then begin
      nl;
      dd(abort,next,'ACS .................. :',acs,TRUE);
      dd(abort,next,'Post ACS ............. :',postacs,TRUE);
      dd(abort,next,'MCI ACS .............. :',mciacs,TRUE);
      nl;
      dd(abort,next,'Filename ...... :','"'+filename+'.BRD"',TRUE);
      dd(abort,next,'Message path .. :','"'+msgpath+'"',(mbtype<>0));
    end;
  end;
end;

end.
