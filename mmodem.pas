{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit mmodem;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common,
  tmpcom,
  myio;

var
  p:array[1..2] of integer;
  ps:array[1..2] of astr;

procedure cwr(i:integer);
procedure wr(i:integer; c:char);
procedure wrs(i:integer; s:astr);
procedure outmodemstring1(s:astr);
procedure outmodemstring000(s:astr; showit:boolean);
procedure outmodemstring(s:astr);
procedure dophonehangup(showit:boolean);
procedure dophoneoffhook(showit:boolean);

implementation

procedure cwr(i:integer);
begin
  tc(12);
  ps[i]:=''; p[i]:=0;
  case i of
    1:begin
        cwriteat(2,25,'Telegard:'+#3#14);
        for i:=1 to 39 do write(' ');
        gotoxy(11,25);
      end;
    2:begin
        cwriteat(50,25,'Modem:'+#3#14);
        for i:=1 to 14 do write(' ');
        gotoxy(56,25);
      end;
  end;
end;

procedure wr(i:integer; c:char);
var j:integer;
begin
  tc(14);
  case i of
    1:begin
        if (p[i]>37) then begin
          for j:=1 to 37 do ps[i][j]:=ps[i][j+1];
          ps[i][0]:=chr(37); p[i]:=37;
        end;
        gotoxy(11,25); write(ps[i]);
      end;
    2:begin
        if (p[i]>14) then begin
          for j:=1 to 14 do ps[i][j]:=ps[i][j+1];
          ps[i][0]:=chr(14); p[i]:=14;
        end;
        gotoxy(56,25); write(ps[i]);
      end;
  end;
  ps[i]:=ps[i]+c; inc(p[i]);
  write(c);
end;

procedure wrs(i:integer; s:astr);
var j:integer;
begin
  for j:=1 to length(s) do wr(i,s[j]);
end;

procedure outmodemstring1(s:astr);
var i:integer;
begin
  for i:=1 to length(s) do begin
    com_tx(s[i]); wr(1,s[i]);
    delay(2);
  end;
  if (s<>'') then com_tx(^M);
end;

procedure outmodemstring000(s:astr; showit:boolean);
var i:integer;
begin
  for i:=1 to length(s) do
    case s[i] of
      '~':delay(500);
    else
          begin
            com_tx(s[i]);
            if (showit) then wr(1,s[i]);
            delay(2);
          end;
    end;
  com_tx(^M);
end;

procedure outmodemstring(s:astr);
begin
  outmodemstring000(s,TRUE);
end;

procedure dophonehangup(showit:boolean);
var rl:real;
    try,rcode:integer;
    c:char;

  procedure dely(r:real);
  var r1:real;
  begin
    r1:=timer;
    while abs(timer-r1)<r do;
  end;

begin
  if (spd<>'KB') then begin
    if (showit) then begin
      gotoxy(1,24); tc(12); clreol; write('Hanging up phone...');
      cwr(1); cwr(2);
    end;
    try:=0;
    while ((try<6) and (com_carrier) and (not keypressed)) do begin
      term_ready(FALSE); dely(2.0); term_ready(TRUE);
      if (showit) then begin cwr(1); cwr(2); end;
      com_flush_rx;
      outmodemstring000(modemr.hangup,showit);
      rl:=timer;
      while (c<>'0') and (abs(timer-rl)<2.0) do begin
        c:=ccinkey1;
        if (c<>#0) then
          if (c in [#32..#255]) then
            if (showit) then wr(2,c);
      end;
      inc(try);
    end;
    term_ready(TRUE);
    if (keypressed) then c:=readkey;
  end;

  if (showit) then
    if (exist('plogoff.bat')) then
      shelldos(FALSE,'plogoff.bat',rcode);
end;

procedure dophoneoffhook(showit:boolean);
var rl1:real;
    c:char;
    done:boolean;
begin
  if (showit) then begin
    gotoxy(1,24); tc(12); clreol; write('Taking phone off hook...');
  end;
  delay(300); com_flush_rx;
  if (showit) then begin cwr(1); cwr(2); end;
  com_flush_rx; outmodemstring000(modemr.offhook,showit); com_flush_rx;
  rl1:=timer; done:=FALSE; c:=#0;
  repeat
    c:=ccinkey1;
    if (c<>#0) then begin
      if (c=^M) then done:=TRUE;
      if (c in [#32..#255]) then wr(2,c);
    end;
  until ((abs(timer-rl1)>1.0) or (done)) or (keypressed);
  delay(50); com_flush_rx;
  tc(11);
  if (showit) then begin
    gotoxy(1,24); clreol;
    gotoxy(1,25); clreol;
  end;
end;

end.
