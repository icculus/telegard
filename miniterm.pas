(*****************************************************************************)
(*>                                                                         <*)
(*>  MINITERM.PAS - Telegard Communications Program                         <*)
(*>                 Copyright 1988,89,90 by Eric Oman, Martin Pollard,      <*)
(*>                 and Todd Bolitho - All Rights Reserved.                 <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,D-,E+,F+,I+,L+,N-,O-,R-,S+,V-}
{$M $4000,0,0}

program miniterm;

uses
  crt, dos, myio, file0, file1, common, tmpcom;

procedure clearscr;
begin
  tc(7);
  clrscr;
end;

procedure term;
const
  delay_time = 25000;

type pnrec=record
             name:string[40];
             number:string[14];
             hs:byte;
           end;
     minirec=record
               dpath:string[40];
             end;

var c,bl,bl2:char;
    done,bac,eco,LFEEDS,macedited:boolean;
    ns:array[1..50] of pnrec;
    fil:file of pnrec;
    cfgfil:file of minirec;
    mini:minirec;

    lnd,i:integer;
    rl:real;
    r:registers;
    sx,sy:integer;
    chkcom:boolean;
    pagnum,pages,hientrynum:integer;
    hs,maxs:byte;
    wind:windowrec;

    mtcfilter:cfilterrec;
    mtcfiltertype,mtcfilternum,mtcfiltercount:integer;
    mtcfilteron:boolean;

    tchkpart:integer;
    timerison:boolean;
    timerstart,timerstop,tooktime:real;

  procedure tell(s:astr);
  var st:integer;
  begin
    cursoron(FALSE);
    st:=40-(length(s) div 2)-3;
    setwindow(wind,st,10,st+length(s)+5,14,9,1,1);
    gotoxy(3,2); tc(15); writeln(s); tc(7);
  end;

  procedure sendmpcode(s:string);
  var outc:string;
      i:integer;
  begin
    outc:=^A^B^A+mln(s,6)+#253+#254+#255;
    for i:=1 to length(outc) do sendcom1(outc[i]);
  end;

(*  procedure timertog;
  var s:string;
      c:char;
  begin
    timerison:=not timerison;
    if (timerison) then begin
      timerstart:=timer;
      tell('Timer started');
      delay(100);
      removewindow(wind);
    end else begin
      timerstop:=timer;
      tooktime:=timerstop-timerstart;
      str(tooktime:2:4,s);
      tell('Time: '+s);
      c:=readkey;
      removewindow(wind);
      cursoron(TRUE);
    end;
  end;*)

  procedure tab(x:integer);
  begin
    while wherex<x do write(' ');
  end;

  procedure savepos(var x,y:integer);
  begin
    x:=wherex; y:=wherey;
  end;

  procedure wait;
  var i:integer;
      c:char;
  begin
    for i:=1 to delay_time do
      if keypressed then begin
        i:=delay_time-1;
        c:=readkey;
      end;
  end;

  procedure tellak(s:astr);
  var x,y:integer;
  begin
    savepos(x,y); tell(s);

    wait;

    removewindow(wind);
    gotoxy(x,y);
    cursoron(TRUE);
    tc(7);
  end;

  procedure om(ch:char);
  begin
    if ((mtcfilteron) and (mtcfiltertype=0) and
        (textattr<>mtcfilter[ord(ch)])) then textattr:=mtcfilter[ord(ch)];
    outkey(ch);
  end;

(*  procedure docchk(c:char);
  begin
    if ((c=#224) and (tchkpart=0)) then begin tchkpart:=1; exit; end;
    if ((c=#225) and (tchkpart=1)) then begin tchkpart:=2; exit; end;
    if ((c=#226) and (tchkpart=2)) then begin tchkpart:=0; timertog; end;
    tchkpart:=0;
  end;*)

  procedure handlemtcode;
  var f:file of char;
      rl:real;
      s:string;
      i,nzz:integer;
      c,cft:char;

    function getnextc:char;
    begin
      while (com_rx_empty) do ;
      getnextc:=ccinkey1;
    end;

  begin
    rl:=timer;
    repeat until (not com_rx_empty);
    c:=ccinkey1;
    if (ord(c) and $70=$70) then
      textattr:=ord(c) and $8F
    else
      case c of
        'C':textattr:=ord(getnextc);
        'c':case getnextc of
              '=':begin
                    for i:=0 to 255 do mtcfilter[i]:=ord(getnextc);
                    if (getnextc=';') then begin
                      mtcfilteron:=TRUE;
                      mtcfiltertype:=0;
                    end else
                      mtcfilteron:=FALSE;
                  end;
              '*':;
              '-':mtcfilteron:=FALSE;
            end;
        'f':begin
              rl:=timer; s:='';
              repeat s:=s+getnextc
              until ((s[ord(s[0])]=';') or (timer-rl>5.0));
              if (copy(s,length(s),1)=';') then begin
                s:=allcaps(copy(s,1,length(s)-1));
                setwindow(wind,3,10,77,17,9,1,1);
                clearscr; tc(15);
                writeln;
                writeln(' BBS wants to send you "'+s+'"');
                writeln(' Enter filename to accept download as.');
                write(' '); for i:=1 to 70 do write('_'); writeln;
                s:=allcaps(mini.dpath)+s;
                tc(9); write(''); tc(11); infield1(wherex,wherey,s,70);
                removewindow(wind);
                if (s='') then exit;
                assign(f,s);
                {$I-} reset(f); {$I+}
                if (ioresult=0) then begin
                  close(f);
                  tellak('"'+s+'": File already exists.');
                  com_tx(#21); { NAK }
                end else begin
                  rewrite(f); nzz:=0;
                  com_tx(#6); { ACK }
                  repeat
                    c:=getnextc;
                    write(f,c); write(c);
                    if (c=^Z) then inc(nzz) else nzz:=0;
                  until (nzz>=3);
                  close(f);
                end;
              end else
                com_tx(#21); { NAK }
            end;
      end;
    dosansion:=FALSE;
  end;

(*
ferr.log;
c*R1,2,3,4;
c*C1,2,3,4;
c=   (0..255 color codes)   ;
c-;                                        { turn off color filter }
*)

  procedure in1(c:char);
  begin
(*    if ((c>=#224) and (c<=#226)) then docchk(c);*)
    if (c=^T) then begin handlemtcode; exit; end;
    if ((c=^M) and (lfeeds)) then writeln;
    if (c=^L) then clrscr else
      if (c=^H) then begin
        om(c);
        if (bac) then begin om(' '); om(^H); end;
      end
    else
      if (c<>#0) then om(c);
  end;

  procedure gkey(var c:char);
  begin
    repeat until keypressed;
    c:=readkey;
  end;

  function lyn:boolean;
  var c:char;
  begin
    repeat gkey(c);
    until upcase(c) in ['Y','N',#13];

    if (upcase(c)='Y') then begin
      lyn:=TRUE;
      writeln('Yes');
    end else begin
      lyn:=FALSE;
      writeln('No');
    end;
  end;

  procedure ss(hs:byte);
  var s:astr;
  begin
    writeln; writeln;
    tc(1); write('--- '); tc(3);
    case hs of
      0:s:='300';     1:s:='1200';
      2:s:='2400';    3:s:='4800';
      4:s:='9600';
    end;
    write(s+' BAUD '); tc(1); writeln('---');
    writeln;
    tc(7);
  end;

  procedure cs(hs:byte);
  var s:astr;
  begin
    case hs of
      0:s:='300';     1:s:='1200';
      2:s:='2400';    3:s:='4800';
      4:s:='9600';
    end;
    com_set_speed(value(s));
    spd:=s;
  end;

  procedure hang;
  var rl:real;
      try:integer;

    procedure dely(r:real);
    var r1:real;
    begin
      r1:=timer;
      while abs(timer-r1)<r do;
    end;

  begin
    try:=0;
    term_ready(FALSE);
    if (com_carrier) then while (try<2) do begin
      dely(2.0);
      pr1('+++');
      rl:=timer;
      while (cinkey1<>'0') and (abs(timer-rl)<2.0) do;
      dely(0.8);
      pr1('ATH0'+#13);
      try:=try+1;
      dely(0.3);
    end;
  end;

  procedure beep;
  var a,b,c,i,j:integer;
  begin
    for j:=1 to 3 do begin
      for i:=1 to 3 do begin
        a:=i*500;
        b:=a;
        while b>a-300 do begin
          sound(b);
          b:=b-50;
          c:=a+1000;
          while c>a+700 do begin
            sound(c);
            delay(2);
            c:=c-50;
          end;
        end;
      end;
      delay(50);
      nosound;
    end;
  end;

  function filepath(fn:astr):astr;
  var a,b:integer;
      s:astr;
  begin
    b:=0;
    for a:=1 to length(fn) do if fn[a]='\' then b:=a;
    if b<>0 then filepath:=copy(fn,1,b)
    else begin
      getdir(0,s);
      filepath:=s+'\';
    end;
  end;

  procedure ul;
  var dok,abort,kabort:boolean;
      i,pa:astr;
      f:text;
      c:char;
      j,sxx,syy,termprotocol:integer;
      st:real;
      suboard:astr;
      pnumber:integer;
  begin
    savepos(sxx,syy);
    setwindow(wind,3,5,38,21,9,1,1);
    tc(15); textbackground(0); clearscr;
    window(4,5,37,20); textbackground(1);
    gotoxy(2,1); write('Upload');
    window(4,6,37,20); textbackground(0);
    gotoxy(1,15);

    termprotocol:=1;
    dok:=FALSE;
    removewindow(wind);
    if termprotocol<>-1 then begin
      i:='';
      setwindow(wind,3,10,77,16,9,1,1);
      clearscr; tc(15);
      writeln;
      if (termprotocol=1) then
        writeln(' Enter file to ASCII send, <CR> to abort.')
      else
        writeln(' Enter file(s) to upload, <CR> to abort.');
      write(' '); for j:=1 to 70 do write('_'); writeln;
      tc(9); write('');
      tc(11); i:=''; infield1(wherex,wherey,i,70);
      removewindow(wind);
      if (i<>'') then begin
        assign(f,i);
        {$I-} reset(f); {$I+}
        if (ioresult=0) then begin
          close(f);
          outcom:=FALSE; incom:=FALSE;
          fileboard:=1;
          loaduboard(1);
          suboard:=memuboard.dlpath; memuboard.dlpath:=filepath(i);
          if (termprotocol=1) then begin
            dok:=TRUE;
            gotoxy(sxx,syy);
            reset(f);
            while (not eof(f)) and (dok) do begin
              if keypressed then
                if readkey=#27 then dok:=FALSE;
              read(f,c);
              sendcom1(c);
              if (eco) then om(c);
              if (not com_rx_empty) then begin
                c:=cinkey1;
                in1(c);
              end;
            end;
            close(f);
            sxx:=wherex; syy:=wherey;
          end;
          memuboard.dlpath:=suboard;
          term_ready(TRUE);
          cs(hs);
        end else begin
          tellak('File not found');
          cursoron(TRUE);
        end;
      end;
    end;
    hangup:=FALSE;
    incom:=FALSE;
    outcom:=FALSE;
    gotoxy(sxx,syy);
    tc(7);
  end;

  procedure dl;
  var dok,kabort,addbatch:boolean;
      i:astr;
      f:file;
      j,sxx,syy,sxx2,syy2:integer;
      st:real;
      suboard:astr;
      pnumber:integer;
      wind1:windowrec;
  begin
(*
    savepos(sxx,syy);
    setwindow(wind,3,9,77,16,9,1,1);
    clearscr;
    tc(9); writeln(mrn(cstr(freek(exdrv(mini.dpath)))+'k of free space in '+mini.dpath,72));

    savepos(sxx2,syy2);
    setwindow(wind1,3,5,38,21,9,1,1);
    tc(15); textbackground(0); clearscr;
    window(4,5,37,20); textbackground(1);
    gotoxy(2,1); write('Download');
    window(4,6,37,20); textbackground(0);
    gotoxy(1,15);

    termprotocol:=gtp(TRUE,FALSE);
    pnumber:=protocols[termprotocol]^.ptype;
    dok:=FALSE;
    removewindow(wind1);
    window(4,10,76,15); gotoxy(sxx2,syy2); textbackground(1);
    if termprotocol=-1 then
      removewindow(wind)
    else begin
      if pnumber=4 then begin
        dok:=TRUE;
        i:=mini.dpath;
      end else begin
        tc(15); writeln; writeln(' Enter file to download to, <CR> to abort.');
        write(' '); for j:=1 to 70 do write('_'); writeln;
        ft:=255;
        tc(9); write('');
        tc(11); infield(i,70);
        removewindow(wind);
        if i<>'' then begin
          assign(f,i);
          {$I-} reset(f); {$I+}
          if ioresult<>0 then begin
            {$I-} rewrite(f); {$I+}
            if ioresult=0 then begin
              close(f);
              erase(f);
              dok:=TRUE;
            end else begin
              dok:=FALSE;
              removewindow(wind);
              tellak('Illegal filename');
              cursoron(TRUE);
            end;
          end else begin
            close(f);
            setwindow(wind,27,10,52,16,9,1,1);
            clearscr; tc(15);
            writeln;
            writeln(#7+'  File already exists.');
            writeln;
            write('  Overwrite? '); tc(3);
            dok:=lyn;
            removewindow(wind);
          end;
        end;
      end;
      if dok then begin
        outcom:=FALSE; incom:=FALSE;
        fileboard:=1;
        suboard:=uboards[1]^.dlpath; uboards[1]^.dlpath:=mini.dpath;
        receive1(i,FALSE,dok,kabort,addbatch);
        uboards[1]^.dlpath:=suboard;
        term_ready(TRUE);
        cs(hs);
      end;
      removewindow(wind);
    end;
    hangup:=FALSE;
    incom:=FALSE;
    outcom:=FALSE;
    gotoxy(sxx,syy);
    tc(7);
*)
  end;

  procedure pc(s:astr);
  var i:integer;
  begin
    s:=s+#13;
    for i:=1 to length(s) do sendcom1(s[i]);
  end;

  procedure initmodem;
  begin
    com_flush_rx;
    delay(500); pc('AT');
    delay(500); pc('ATQ0V1E1S2=43M0S11=50');
    delay(200);
    com_flush_rx;
  end;

  procedure savedialer;
  var i:integer;
  begin
    reset(fil);
    rewrite(fil);
    for i:=1 to hientrynum do begin
      seek(fil,i-1);
      write(fil,ns[i]);
    end;
    close(fil);
  end;

  procedure redial;
  const loco=9;
        hico=15;
        ttspend=30;
  var c,kk:char;
      done,done1,gotonext,checking:boolean;
      try:integer;
      rl,rl1,rl2:real;
      int:integer;
      i,i1,rs,rc:astr;
      sxx,syy:integer;
      cl:integer;
      slpos:integer;

    procedure getresultcode(rs:astr);
    var i,j:integer;
    begin
      with systat do
        for i:=1 to 2 do
          for j:=0 to 4 do
            if (modemr.resultcode[i][j]<>0) and
               (rs=cstr(modemr.resultcode[i][j])) then begin
              case j of
                0:spd:='300'; 1:spd:='1200'; 2:spd:='2400';
                3:spd:='4800'; 4:spd:='9600';
              end;
              chkcom:=TRUE;
              exit;
            end;
    end;
      
  begin
    cursoron(FALSE);
    savepos(sxx,syy);
    setwindow(wind,1,1,51,9,9,1,1);
    clearscr; try:=0;
    hs:=ns[lnd].hs; cs(hs); rl:=timer;
    chkcom:=FALSE; done:=FALSE; checking:=FALSE; rc:=''; spd:='N.A.';
    pc('ATX4M0Q0V0E0S7=16');
    tc(loco);
    writeln('Redial started at 00:00:00');
    writeln('Attempt #0        00:00:00');
    write('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
    writeln('Dialing');
    writeln('     at');
    write('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
    write('Last result: None.');
    gotoxy(31,1);
    tc(14); write('Hit '); textbackground(4); write('<ESC>');
    textbackground(1); write(' to abort');

    tc(hico);
    gotoxy(19,1); write(ctim(timer));

    gotoxy(9,4); write(ns[lnd].name);
    gotoxy(9,5); write(ns[lnd].number);
    tc(loco); write(' ... '); slpos:=wherex;
    gotoxy(10,2);
    tc(hico); write('0');
    delay(500); com_flush_rx;

    repeat
      pc('ATDT'+ns[lnd].number);
      inc(try);
      tc(hico);
      gotoxy(10,2); write(try);
      gotoxy(19,2); write(ctim(timer));
      com_flush_rx;
      kk:=#0;
      rl:=timer;
      done1:=FALSE;
      while ((not done) and (not done1) and (com_rx_empty)) do begin
        gotonext:=FALSE;
        rl1:=timer;
        if rl1<rl then rl1:=rl1+24.0*3600.0;
        rl2:=(ttspend-abs(rl1-rl))+1;
        gotoxy(slpos,5);
        tc(hico); write(trunc(rl2));
        tc(loco); write(' seconds   ');
        if trunc(rl2)<=0 then done1:=TRUE;
        if keypressed then begin
          kk:=readkey;
          if kk in [#27,#32] then done:=TRUE;
          if kk=#32 then gotonext:=TRUE;
          if upcase(kk)='C' then checking:=not checking;
        end;
        if ((done1) or (done)) then sendcom1('A');
      end;
      delay(100); rc:='';
      if ((not com_rx_empty) or (done1) or (gotonext)) then begin
        if (not com_rx_empty) then begin
          rs:='';
          rl1:=timer;
          while tchk(rl1,0.4) do begin
            c:=cinkey;
            if c in [#32..#255] then rs:=rs+c;
          end;
          if checking then begin
            gotoxy(1,6); tc(loco);
            for int:=1 to 20 do write('Ä');
            gotoxy(1,6); tc(hico); write('"'+rs+'"');
          end;
        end;
        rs:=cstr(value(copy(rs,1,3)));
        with systat do begin
          if (modemr.busy<>0) then
            if rs=cstr(modemr.busy) then begin rc:='BUSY'; cl:=14; end;
          if (modemr.nocarrier<>0) or (done1) then
            if (rs=cstr(modemr.nocarrier)) or (done1) then begin rc:='NO CARRIER'; cl:=12; end;
          if (modemr.nodialtone<>0) then
            if rs=cstr(modemr.nodialtone) then begin rc:='NO DIALTONE'; cl:=28; end;
          getresultcode(rs);
        end;
        if (chkcom) then begin rc:='CONNECT '+spd+'!'; cl:=30; end;
      end;

      if kk=#27 then begin rc:='User abort!'; cl:=15; end;
      if kk=#32 then begin rc:='Skipped to next.'; cl:=15; end;

      if rc<>'' then begin
        gotoxy(14,7); tc(15); clreol;
        gotoxy(14,7); tc(cl); write(rc); tc(7);
      end;

      if chkcom then done:=TRUE;
      if rc='NO DIALTONE' then done:=TRUE;
      if gotonext then done:=FALSE;
    until done;

    if (rc='NO DIALTONE') and (kk<>#27) then begin
      clearscr;
      tc(28); writeln(' NO DIALTONE ');
      writeln;
      tc(12); writeln('Dial tone is NOT detected.');
      gotoxy(1,7); textbackground(4); tc(14); clreol;
      gotoxy(2,7); write('Hit any key to return to terminal mode');
      textbackground(1);
      repeat
        sound(800); delay(100);
        nosound; delay(50);
      until keypressed;
      c:=readkey;
    end;

    if (not chkcom) or (spd='N.A.') then initmodem
    else begin
      removewindow(wind);
      tell('Connection Established at '+spd+' baud');
      repeat
        sound(1200); delay(30); sound(1300); delay(60);
        sound(1500); delay(90); sound(2000); delay(120);
        nosound; delay(100);
      until (try=30) or (keypressed);
      if keypressed then c:=readkey;
    end;

    removewindow(wind);
    gotoxy(sxx,syy);
    textbackground(0); tc(7);
    cursoron(TRUE);
  end;

  procedure dial;
  var sxx,syy,i,j,k:integer;
      changed,done:boolean;
      qd,c:char;
      s:astr;
      savp:pnrec;

    procedure updatelist;
    var i:integer;
    begin
      tc(15); gotoxy(67,1); write('Page '+cstr(pagnum)+' of '+cstr(pages));
      writeln;
      for i:=(pagnum-1)*10+1 to (pagnum-1)*10+10 do begin
        gotoxy(1,(i-(pagnum-1)*10)+2);
        if i<=hientrynum then begin
          tc(9); write(i);
          tc(15); tab(4); write(ns[i].name);
          tc(14); tab(46); write(ns[i].number);
          tc(11); tab(61);
          case ns[i].hs of
            0:writeln(' 300');
            1:writeln('1200');
            2:writeln('2400');
            3:writeln('4800');
            4:writeln('9600');
          end;
        end
        else clreol;
      end;
    end;

    procedure showlist;
    var i:integer;
    begin
      clearscr;
      tc(15); writeln('N  NAME                                      NUMBER         SPD');
      tc(9); writeln('ÄÄ ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ  ÄÄÄÄÄÄÄÄÄÄÄÄÄ  ÄÄÄÄ');
    end;

    procedure resetpages;
    begin
      pages:=((hientrynum-1) div 10)+1;
    end;

    procedure dcmds(i:integer);
    var x,y:integer;
    begin
      cursoron(TRUE);
      savepos(x,y);
      gotoxy(1,15); clreol;
      gotoxy(1,16); clreol;
      if i<>0 then begin
        gotoxy(1,15); tc(15); write('Dial: '); tc(9);
        writeln('(PgUp PgDn) [A]dd [C]lear [D]ial [I]nsert [K]ill [M]odify');
        tab(19); write('[Q]uit');
        cursoron(FALSE);
      end;
      gotoxy(x,y);
    end;

  begin
    changed:=FALSE;
    cursoron(FALSE);
    savepos(sxx,syy);
    setwindow(wind,1,5,79,22,9,1,1);
    showlist;
    done:=FALSE;
    repeat
      updatelist;
      dcmds(1);
      repeat c:=upcase(readkey);
      until pos(c,#27+'Q0123456789ACDIKM'+#0)>0;
      if c in ['0'..'9'] then begin qd:=c; c:='D'; end else qd:=#0;
      gotoxy(1,15);
      case c of
        #0:if keypressed then
             case readkey of
               #73:if pagnum>1 then dec(pagnum);
               #81:if pagnum<pages then inc(pagnum);
             end;
        'Q',
        #27:begin
              done:=TRUE;
              removewindow(wind);
              gotoxy(sxx,syy);
            end;
        'A':begin
              if hientrynum<>50 then begin
                inc(hientrynum);
                with ns[hientrynum] do begin
                  name:='';
                  number:='';
                  hs:=maxs;
                end;
                resetpages;
                changed:=TRUE;
              end
              else write(^G);
            end;
        'C':begin
              dcmds(0);
              tc(15); write('Clear which? :');
              infield(s,2);
              i:=value(s);
              if (i>=1) and (i<=hientrynum) then begin
                with ns[i] do begin
                  name:='';
                  number:='';
                  hs:=maxs;
                end;
                resetpages;
                changed:=TRUE;
              end;
            end;
        'D':begin
              dcmds(0);
              tc(15); write('Dial which? :');
              if qd<>#0 then s:=qd else s:='';
              infield1(wherex,wherey,s,2);
              i:=value(s);
              if (i>=1) and (i<=hientrynum) then begin
                removewindow(wind);
                lnd:=i;
                if changed then savedialer;
                changed:=FALSE;
                redial;
                done:=TRUE;
              end;
            end;
        'I':begin
              if hientrynum<>50 then begin
                dcmds(0);
                tc(15); write('Insert before which? :');
                infield(s,2);
                i:=value(s);
                if (i>=1) and (i<=hientrynum+1) then begin
                  if i<>hientrynum+1 then
                    for j:=hientrynum+1 downto i+1 do
                      ns[j]:=ns[j-1];
                  with ns[i] do begin
                    name:='';
                    number:='';
                    hs:=maxs;
                  end;
                  inc(hientrynum);
                  resetpages;
                  changed:=TRUE;
                end;
              end
              else write(^G);
            end;
        'K':begin
              if hientrynum>1 then begin
                dcmds(0);
                tc(15); write('Kill which? :');
                infield(s,2);
                i:=value(s);
                if (i>=1) and (i<=hientrynum) then begin
                  if i<>hientrynum then
                    for j:=i to hientrynum-1 do
                      ns[j]:=ns[j+1];
                  dec(hientrynum);
                  resetpages;
                  changed:=TRUE;
                end;
              end;
            end;
        'M':begin
              dcmds(0);
              tc(15); write('Modify which? :');
              infield(s,2);
              i:=value(s);
              if (i>=1) and (i<=hientrynum) then begin
                clearscr;
                writeln('Entry number: ',i);
                writeln('Enter <CR> alone at any prompt for no change.');
                writeln;
                tc(14); write('Name:   '); tc(15); writeln(ns[i].name);
                tc(14); write('Number: '); tc(15); writeln(ns[i].number);
                tc(14); write('Speed:  '); tc(15);
                case ns[i].hs of
                  0:write('300');
                  1:write('1200');
                  2:write('2400');
                  3:write('4800');
                  4:write('9600');
                end;
                writeln(' baud');
                s:=ns[i].name; infield1(9,4,s,40);
                if s<>ns[i].name then begin
                  ns[i].name:=s;
                  changed:=TRUE;
                end;
                s:=ns[i].number; infield1(9,5,s,14);
                if s<>ns[i].number then begin
                  ns[i].number:=s;
                  changed:=TRUE;
                end;
                writeln;
                tc(11); write('[3]00  ');
                if maxs>0 then write('[1]200  ');
                if maxs>1 then write('[2]400  ');
                if maxs>2 then write('[4]800  ');
                if maxs>3 then write('[9]600  ');
                writeln;
                writeln;
                tc(9); write('New speed? ');
                c:=readkey; tc(11);
                if c in ['3','1','2','4','9'] then begin
                  writeln(c);
                  changed:=TRUE;
                end
                else writeln('No change.');
                with ns[i] do
                  case c of
                    '3':hs:=0;
                    '1':hs:=1;
                    '2':hs:=2;
                    '4':hs:=3;
                    '5':hs:=4;
                  end;
                c:=' ';
                showlist;
              end;
            end;
      end;
      cursoron(FALSE);
    until (done);
    if changed then savedialer;
    textbackground(0); tc(15);
    gotoxy(sxx,syy);
    cursoron(TRUE);
  end;

  procedure pp(s:astr);
  var i:integer; c:char;
  begin
    for i:=1 to length(s) do
    begin
      c:=s[i];
      if c='{' then c:=#13;
      if eco then om(c);
      sendcom1(c);
    end;
  end;

  procedure wcenter(s:string; color,row:integer);
  var col:integer;
  begin
    col:=((80-length(s)) div 2); gotoxy(col,row);
    tc(color); write(s);
  end;

  procedure logo;
  begin
    clearscr; tc(1); box(1,11,1,68,5); window(1,1,80,25);
    wcenter('Telegard MiniTerm - Version '+ver,15,2);
    wcenter('Copyright 1988,89,90 by Eric Oman, Martin Pollard,',11,3);
    wcenter('and Todd Bolitho - All Rights Reserved.',11,4);
    wcenter('To get help, press "Alt-Z".',14,6);
    tc(7);
  end;

  procedure help;
  var x,y:integer;
        c:char;
  begin
    cursoron(FALSE);
    savepos(x,y);

    setwindow(wind,43,1,80,18,4,0,1);
    tc(15);
    writeln('Alt-B = backspacing toggle');
    writeln('Alt-C = clear screen');
    writeln('Alt-D = dialer');
    writeln('Alt-E = echo toggle');
    writeln('Alt-H = hang up');
    writeln('Alt-I = initialize modem');
    writeln('Alt-J = jump to DOS');
    writeln('Alt-L = line feeds toggle');
    writeln('Alt-M = turbo screen mode toggle');
    writeln('Alt-R = redial last number');
    writeln('Alt-S = speed toggle');
    writeln('Alt-X = exit');
    writeln('PgUp  = send file from dloads');
    writeln('PgDn  = receive file into dloads');
    writeln;

    tc(9); write('Press any key....');
    repeat until keypressed;
    c:=readkey;

    removewindow(wind);
    gotoxy(x,y);
    cursoron(TRUE);
  end;

  procedure init;
  var x,y:integer;

    procedure loading(s:astr);
    begin
      tc(9); write('þ ');
      tc(11); writeln('Loading "'+s+'"');
    end;

  begin
    trm:=TRUE;

    tchkpart:=0; timerison:=FALSE;

    lfeeds:=FALSE; nopfile:=FALSE; eco:=FALSE; wantout:=TRUE; checkit:=FALSE;
    wantfilename:=FALSE; enddayf:=FALSE; mailread:=FALSE; smread:=FALSE;
    beepend:=FALSE; useron:=FALSE; chatcall:=FALSE;
    outcom:=FALSE; incom:=FALSE; hangup:=FALSE; hungup:=FALSE;
    lnd:=0;
    ll:=''; chatr:=''; usernum:=1;
    curco:=7; sdc;
    delay(50); com_flush_rx; term_ready(TRUE);
{    iport;}
    com_flush_rx;

    infield_out_fgrd:=15;
    infield_out_bkgd:=1;
    infield_inp_fgrd:=0;
    infield_inp_bkgd:=7;
    infield_arrow_exit:=FALSE;

    getdir(0,start_dir);
    window(1,1,80,25);
    logo;

    savepos(x,y);
    setwindow(wind,1,1,50,8,9,1,1);

    with modemr do begin
      if (waitbaud=300) then maxs:=0;
      if (waitbaud=1200) then maxs:=1;
      if (waitbaud=2400) then maxs:=2;
      if (waitbaud=4800) then maxs:=3;
      if (waitbaud=9600) then maxs:=4;
    end;

    loading(start_dir+'\miniterm.fon');
    if not exist(start_dir+'\miniterm.fon') then begin
      assign(fil,start_dir+'\miniterm.fon');
      rewrite(fil);
      with ns[1] do begin
        name:='Grosse Pointe Centrale';
        number:='1-313-885-1779';
        hs:=2;
      end;
      write(fil,ns[1]);
      close(fil);
    end;

    assign(fil,start_dir+'\miniterm.fon');
    reset(fil);
    hientrynum:=0;
    repeat
      hientrynum:=hientrynum+1;
      seek(fil,hientrynum-1);
      read(fil,ns[hientrynum]);
    until hientrynum=filesize(fil);
    close(fil);
    pages:=((hientrynum-1) div 10)+1;
    pagnum:=1;

    loading(start_dir+'\miniterm.cfg');
    if not exist(start_dir+'\miniterm.cfg') then begin
      assign(cfgfil,start_dir+'\miniterm.cfg');
      rewrite(cfgfil);
      with mini do begin
        dpath:=start_dir+'\';
      end;
      write(cfgfil,mini);
      close(cfgfil);
    end;
    assign(cfgfil,start_dir+'\miniterm.cfg');
    reset(cfgfil); read(cfgfil,mini); close(cfgfil);

    removewindow(wind);
    gotoxy(x,y);
    cursoron(TRUE);

    hs:=maxs; cs(hs); ss(hs); bac:=FALSE;
    done:=FALSE;

    initmodem;
  end;

var mtcolors,showascii:boolean;
    rcode:integer;

begin
  mtcolors:=FALSE; showascii:=FALSE;
  init;

  rl:=timer;
  repeat
    if (not com_rx_empty) then begin
      c:=cinkey1;
      in1(c);
      if (showascii) then write('(',ord(c),')');
    end else begin
      if (timer<rl) then rl:=rl-24.0*3600.0;
      if (timer-rl>10.0*60.0) then done:=TRUE;
    end;
    if (keypressed) then begin
      c:=readkey;
      if (c=#0) then
        if (keypressed) then begin
          c:=readkey;
          case ord(c) of
            18:begin
                 eco:=not eco;
                 if eco then tellak('Echo ON') else tellak('Echo OFF');
                 cursoron(TRUE);
               end;
            19:if lnd in [1..50] then redial;
            23:begin
                 savepos(sx,sy);
                 tell('Initializing modem....');
                 initmodem;
                 removewindow(wind);
                 gotoxy(sx,sy);
                 cursoron(TRUE);
                 tc(7);
               end;
            27:pp(#27);
            31:begin
                 hs:=hs+1;
                 if hs>maxs then hs:=0;
                 cs(hs);
                 ss(hs);
               end;
            32:begin
                 dial;
                 tc(7);
               end;
            35:begin
                 savepos(sx,sy);
                 tell('Hanging up....');
                 hang;
                 removewindow(wind);
                 gotoxy(sx,sy);
                 cursoron(TRUE);
                 tc(7);
               end;
            36:begin
                 i:=textattr;
                 savepos(sx,sy);
                 setwindow(wind,1,1,80,25,7,0,0);
                 writeln('Type "EXIT" to return to MiniTerm.');
                 shelldos(FALSE,'',rcode);
                 cs(hs);
                 removewindow(wind);
                 gotoxy(sx,sy);
                 textattr:=i;
                 if (doserror<>0) then
                   tellak('Could not execute COMMAND.COM');
               end;
            38:begin
                 lfeeds:=not lfeeds;
                 if lfeeds then tellak('Line feeds ON')
                           else tellak('Line feeds OFF');
                 cursoron(TRUE);
               end;
            44:help;
            45:begin
                 cursoron(FALSE);
                 savepos(sx,sy);
                 returna:=FALSE;
                 done:=TRUE;
                 com_flush_rx;
                 removewindow(wind);
                 gotoxy(sx,sy);
                 cursoron(TRUE);
                 clearscr;
                 chdir(start_dir);
               end;
            46:clearscr;
            48:begin
                 bac:=not bac;
                 if bac then tellak('Backspace: Destructive')
                        else tellak('Backspace: Non-Destructive');
                 cursoron(TRUE);
               end;
            50:begin
                 mtcolors:=not mtcolors;
                 if (mtcolors) then sendmpcode('rmt1')
                   else sendmpcode('rmt0');
                 if mtcolors then tellak('Turbo screen mode ON')
                             else tellak('Turbo screen mode OFF');
               end;
            130:showascii:=not showascii;
            73:ul;
            75:if (okansi) then pp(#27+'[D');
            77:if (okansi) then pp(#27+'[C');
            72:if (okansi) then pp(#27+'[A');
            80:if (okansi) then pp(#27+'[B');
            81:dl;
          end;
        end else
          om(c)
      else begin
        sendcom1(c);
        if (eco) then om(c);
      end;
      rl:=timer;
    end;
  until (done);
  trm:=FALSE;
end;

function loadfiles:boolean;
var errs:boolean;
    systatf:file of systatrec;
    modemrf:file of modemrec;
begin
  errs:=FALSE;
  assign(systatf,'status.dat');
  {$I-} reset(systatf); {$I+}
  errs:=(ioresult<>0);
  if (not errs) then begin
    {$I-} read(systatf,systat); {$I+}
    errs:=(ioresult<>0);
  end;
  close(systatf);
  if (not errs) then begin
    assign(modemrf,systat.gfilepath+'modem.dat');
    {$I-} reset(modemrf); {$I+}
    errs:=(ioresult<>0);
    if (not errs) then read(modemrf,modemr);
    close(modemrf);
  end;
  if (not errs) then begin
    assign(uf,systat.gfilepath+'user.lst');
    {$I-} reset(uf); {$I+}
    errs:=(ioresult<>0);
    if (not errs) then begin
      seek(uf,1);
      read(uf,thisuser);
      with thisuser do begin
        linelen:=80; pagelen:=25;
        ac:=[ansi,color]; ac:=ac-[onekey,pause,novice,avatar];
      end;
    end;
    close(uf);
  end;
  loadfiles:=errs;
end;

begin
  if (loadfiles) then halt(1);
  iport;
  term;
  remove_port;
  halt(0);
end.
