{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit cuser;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common;

procedure cstuff(which,how:byte; var user:userrec);

implementation

(******************************************************************************
 procedure: cstuff(which,how:byte; var user:userrec);
---
 purpose:   Inputs user information.
---
 variables passed:

    which- 1:Address        6:Occupation  11:Screen size
           2:Age            7:User name   12:Sex
           3:ANSI status    8:Phone #     13:BBS reference
           4:City & State   9:Password    14:Zip code
           5:Computer type 10:Real name

      how- 1:New user logon in process
           2:Menu edit command
           3:Called by the user-list editor

     user- User information to modify
******************************************************************************)

var callfromarea:integer;

procedure cstuff(which,how:byte; var user:userrec);
var done,done1:boolean;
    try:integer;
    fi:text;
    s:astr;
    i:integer;

  procedure findarea;
  var c:char;
  begin
    print('Are you calling from:');
    print('  1. United States');
    print('  2. Canada');
    print('  3. Other country');
    nl;
    prt('Select (1-3) : '); onek(c,'123');
    if (hangup) then exit;
    callfromarea:=ord(c)-48;
    done1:=TRUE;
  end;
  
  procedure doaddress;
  begin
    if (how=3) then print('Enter new mailing address.')
      else print('Enter your mailing address: <House number> <Street> [APT#]');
    prt(':');
    if (how=3) then inputl(s,30) else inputcaps(s,30);
    if (s<>'') then begin
      user.street:=s;
      done1:=TRUE;
    end;
  end;

  procedure doage;
  var b:byte;
      s:astr;

    function numsok(s:astr):boolean;
    var i:integer;
    begin
      numsok:=FALSE;
      for i:=1 to 8 do
        if not ((s[i] in ['0'..'9']) or (i=3) or (i=6)) then exit;
      numsok:=TRUE;
    end;

  begin
    if (how=3) then prompt('Enter date of birth (mm/dd/yy) : ')
    else begin
      sprint('^301^5=January   ^304^5=April  ^307^5=July       ^310^5=October');
      sprint('^302^5=February  ^305^5=May    ^308^5=August     ^311^5=November');
      sprint('^303^5=March     ^306^5=June   ^309^5=September  ^312^5=December');
      nl;
      prt('Enter your date of birth (mm/dd/yy) : ');
    end;
    cl(3); input(s,8);
    if ((length(s)=8) and (s[3]='/') and (s[6]='/')) then
      if (numsok(s)) then
        if (ageuser(s)<3) then
          sprint(#3#7+'Isn''t '+cstr(ageuser(s))+' years old a little YOUNG???')
        else begin
          user.bday:=s;
          done1:=TRUE;
        end;
    if ((not done1) and (how=1)) then sprint(#3#7+'Sorry, try again!');
  end;

  procedure doansi;
  begin
    pr(#27+'[0;1;5;33;40mANSI test'); tc(14+128); writeln('ANSI test');
    nl;
    if pynq('Do you have ANSI (are the above words blinking)? ') then begin
      user.ac:=user.ac+[ansi];
      if pynq('Do you have a color monitor? ') then user.ac:=user.ac+[color];
    end;
    done1:=TRUE;
  end;

  procedure docitystate;
  var s,s1,s2:astr;
  begin
    case how of
      2:findarea;
      3:callfromarea:=1;
    end;
    if (callfromarea<>3) then begin
      if (how=3) then begin
        print('Enter new city & state: ');
        prt(':'); inputl(s,30);
        if (s<>'') then user.citystate:=s;
        done1:=TRUE;
        exit;
      end;
      case callfromarea of
        1:print('City & State entry.');
        2:print('City & Province entry.');
      end;
      nl;
      if (callfromarea=1) then s1:='state' else s1:='province';
      print('First enter your city name (do not include '+s1+'):');
      prt(':'); inputcaps(s1,26);
      while (copy(s1,1,1)=' ') do s1:=copy(s1,2,length(s1)-1);
      while (copy(s1,length(s1),1)=' ') do s1:=copy(s1,1,length(s1)-1);
      nl;
      if (length(s1)<2) then begin
        sprint(#3#7+'Why do I find it hard to believe');
        sprint(#3#7+'that that is '+#3#5+'not'+#3#7+' a real city?');
        nl;
        if (callfromarea=1) then s2:='Detroit' else s2:='Toronto';
        sprint(#3#7+'Example: "'+s2+'" is a real city.');
        exit;
      end;
      if (pos(',',s1)<>0) then begin
        if (callfromarea=1) then s2:='state' else s2:='province';
        sprint(#3#7+'NO COMMAS!  Don''t enter your '+s2+' YET,');
        sprint(#3#7+'just enter your CITY!!!  I''ll ask for your');
        sprint(#3#7+allcaps(s2)+' as soon as I know your CITY!!!');
        nl;
        if (callfromarea=1) then s2:='Detroit' else s2:='Toronto';
        sprint(#3#7+'Example: "'+s2+'" is a city!');
        exit;
      end;
      if (callfromarea=1) then s2:='state' else s2:='province';
      prompt('Now enter your 2-letter '+s2+' abbreviation: ');
      cl(3); input(s2,2);
      nl;
      if (length(s2)<2) then begin
        sprint(#3#0+'TWO '+#3#7+'characters.  '+#3#0+'TWO '+#3#7+'characters.  Can''t you count?');
        sprint(#3#7+'(Hint: notice the word "'+#3#0+'TWO'+#3#7+'")');
        exit;
      end;
      user.citystate:=s1+', '+s2;
      done1:=TRUE;
    end else begin
      print('First enter your city name, and nothing else:');
      prt(':'); inputcaps(s1,26);
      if (length(s1)<2) then exit;
      nl;
      print('Now enter your country name:');
      prt(':'); inputcaps(s2,26);
      if (length(s2)<2) then exit;
      nl;
      s:=s1+', '+s2;
      print('Final result: "'+s+'"');
      if (length(s)>30) then begin
        print('Too long!  Max total length is 30 characters.');
        print('Find some way to abbreviate.');
        exit;
      end;
      user.citystate:=s;
      done1:=TRUE;
    end;
  end;

  procedure docomputer;
  var fp:text;
      ctyp:array[1..31] of string[30];
      i,n:integer;
      s,s1:astr;
      c:char;
      abort,next,other,cexist:boolean;
  begin
    other:=TRUE; cexist:=FALSE;
    assign(fp,systat.afilepath+'computer.txt');
    {$I-} reset(fp); {$I+}
    if (ioresult=0) then begin
      cexist:=TRUE;
      other:=FALSE; i:=0;
      repeat
        inc(i);
        readln(fp,ctyp[i]);
      until eof(fp) or (i=30);
      close(fp);
      n:=i+1; ctyp[n]:='Other'; abort:=FALSE;
      for i:=1 to n do begin
        s:=#3#1+mln(cstr(i)+'.',3)+ctyp[i];
        if (odd(i)) then s1:=s else printacr(mln(s1,33)+s,abort,next);
      end;
      if (odd(n)) then printacr(s1,abort,next);
      nl;
      if (how=3) then prt('Enter new computer type: ')
        else prt('Enter your computer type: ');
      input(s,2); i:=value(s);
      if (i>=1) and (i<n) then begin
        user.computer:=ctyp[i];
        done1:=TRUE;
      end else
        if i=n then other:=TRUE;
    end;
    if (other) then begin
      if cexist then prt('Other computer type: ')
        else prt('Enter your computer type: ');
      if (how=3) then inputl(s,30) else inputcaps(s,30);
      if (s<>'') then begin
        user.computer:=s;
        done1:=TRUE;
      end;
    end;
    s:=''; i:=1;
    while (i<=length(user.computer)) do begin
      if (user.computer[i]<>#3) then s:=s+user.computer[i] else inc(i);
      inc(i);
    end;
  end;

  procedure dojob;
  begin
    if (how=3) then print('Enter new occupation.')
      else print('Enter your occupation:');
    prt(':');
    if (how=3) then inputl(s,40) else inputcaps(s,40);
    if (s<>'') then begin
      user.occupation:=s;
      done1:=TRUE;
    end;
  end;

  procedure doname;
  var i:integer;
      s1,s2:astr;
      sfo:boolean;
      sr:smalrec;
  begin
    if (systat.allowalias) then begin
      print('Enter your handle, or your first & last');
      print('name if you don''t want to use one.')
    end else
      print('Enter your first & last name.  Handles are NOT ALLOWED!');
    prt(':'); input(s,36);
    done1:=TRUE;
    nl;
    if ((not (s[1] in ['A'..'Z','?'])) or (s='')) then done1:=FALSE;
    sfo:=(filerec(sf).mode<>fmclosed);
    if (not sfo) then reset(sf);
    for i:=1 to filesize(sf)-1 do begin
      seek(sf,i); read(sf,sr);
      if (sr.name=s) then begin
        done1:=FALSE;
        sprint(#3#7+'That name is already being used.');
      end;
    end;
    if (not sfo) then close(sf);
    assign(fi,systat.afilepath+'trashcan.txt');
    {$I-} reset(fi); {$I+}
    if (ioresult=0) then begin
      s2:=' '+s+' ';
      while not eof(fi) do begin
        readln(fi,s1);
        if s1[length(s1)]=#1 then s1[length(s1)]:=' ' else s1:=s1+' ';
        s1:=' '+s1;
        for i:=1 to length(s1) do s1[i]:=upcase(s1[i]);
        if pos(s1,s2)<>0 then begin
          sprint(#3#7+'"'+copy(s1,pos(s1,s2),length(s1))+'" may not be used!');
          done1:=FALSE;
        end;
      end;
      close(fi);
    end;
    if (not done1) and (not hangup) then begin
      sprint(#3#7+^G'Sorry, can''t use that name.');
      inc(try);
      sl1('Unacceptable name : '+s);
    end;
    if (try>=3) then hangup:=TRUE;
    if (done1) then user.name:=s;
    if ((done) and (how=1) and (not systat.allowalias)) then
      user.realname:=caps(s);
  end;

  procedure dophone;
  begin
    case how of
      2:findarea;
      3:callfromarea:=1;
    end;
    if (how=3) then print('Enter new VOICE phone number:')
      else print('Enter your VOICE phone number:');
    if (((how=1) and (callfromarea=3)) or (how=3)) then begin
      prt(':'); input(s,12);
      if (length(s)>5) then begin user.ph:=s; done1:=TRUE; end;
    end else begin
      print(' ###-###-####.');
      prt(':'); input(s,12);
      if (length(s)=12) and (s[4]='-') and (s[8]='-') then begin
        user.ph:=s;
        done1:=TRUE;
      end else
        if (how=1) then sprint(#3#7+'Please enter it correctly!');
    end;
  end;

  procedure dopw;
  var s:astr;
  begin
    case how of
      1:begin
          print('Enter a password that you will use to log on again.');
          print('It must be between 4 and 20 characters in length.');
          prt(':'); input(s,20);
          if (length(s)<4) then
            sprint(#3#7+'Must be at least 4 characters long.')
          else
          if (length(s)>20) then
            sprint(#3#7+'Must be less than 20 characters long.')
          else begin
            nl;
            sprint(#3#3+'Your password: '+#3#5+s);
            done1:=pynq('Is this correct? ');
            if (done1) then user.pw:=s;
          end;
        end;
      2:begin
          sprint(#3#5+'For security reasons, when changing passwords');
          sprint(#3#5+'you must first enter your old password.');
          nl;
          sprompt(#3#0+'User password   : '+#3#5); input(s,20);
          if (s<>user.pw) then sprint(^G+#3#7+'>> INCORRECT PASSWORD <<')
          else begin
            nl;
            print('Your new password must be 4-20 chrs in length.');
            nl;
            repeat
              prt('New password: '); mpl(20); input(s,20);
              nl;
            until (((length(s)>=4) and (length(s)<=20)) or (s='') or (hangup));
            if (s<>'') then begin
              nl; nl;
              sprint(#3#3+'New Password: "'+#3#5+s+#3#3+'"');
              if pynq('Are you SURE this is what you want? ') then begin
                if (not hangup) then user.pw:=s;
                sysoplog('Changed password.');
                done1:=TRUE;
              end else
                print('Aborted.');
            end else
              print('Aborted.');
          end;
          nl;
        end;
      3:begin
          print('Enter new password.'); prt(':'); input(s,20);
          if (s<>'') then begin
            done1:=TRUE;
            user.pw:=s;
          end;
        end;
    end;
  end;

  procedure dorealname;
  var i:integer;
  begin
    if ((how=1) and (not systat.allowalias)) then begin
      user.realname:=caps(user.name);
      done1:=TRUE;
      exit;
    end;
    if (how=3) then print('Enter new REAL first & last name, or')
      else print('Enter your REAL first & last name, or');
    print('enter "=" if same as your user name.');
    prt(':');
    if (how=3) then inputl(s,36) else inputcaps(s,36);
    if (s='=') then s:=caps(user.name);
    while copy(s,1,1)=' ' do s:=copy(s,2,length(s)-1);
    while copy(s,length(s),1)=' ' do s:=copy(s,1,length(s)-1);
    if (pos(' ',s)=0) and (how<>3) then begin
      print('Enter it correctly!  First AND last name please!');
      s:='';
    end;
    if (s<>'') then begin
      user.realname:=s;
      done1:=TRUE;
    end;
  end;

  procedure doscreen;
  var v:string;
      bb:byte;
  begin
    if (how=1) then begin
      user.linelen:=systat.linelen;
      user.pagelen:=systat.pagelen;
    end;
    prt('How many columns wide is your screen (32-132) ['+
      cstr(thisuser.linelen)+'] : ');
    ini(bb); if (not badini) then user.linelen:=bb;
    prt('Number of lines per page (4-50) ['+cstr(thisuser.pagelen)+'] : ');
    ini(bb); if (not badini) then user.pagelen:=bb;
    if (user.pagelen>50) then user.pagelen:=50;
    if (user.pagelen<4) then user.pagelen:=4;
    if (user.linelen>132) then user.linelen:=132;
    done1:=TRUE;
  end;

  procedure dosex;
  var c:char;
  begin
    if (how=3) then begin
      prt('New sex (M,F) : ');
      onek(c,'MF '^M);
      if (c in ['M','F']) then user.sex:=c;
    end else begin
      user.sex:=#0;
      repeat
        prt('Your sex (M,F) ? ');
        onek(user.sex,'MF'^M);
        if (user.sex=^M) then begin
          nl;
          sprint(#3#7+'Don''t know your own sex, eh?  Better see a doctor!');
          nl;
        end;
      until ((user.sex in ['M','F']) or (hangup));
    end;
    done1:=TRUE;
  end;

  procedure dowherebbs;
  begin
    if (how=3) then print('Enter new BBS reference.')
    else begin
      print('Where did you hear about this BBS from? (be specific;');
      print('do not say, for example, "some guy on another board")');
    end;
    prt(':');
    if (how=3) then inputl(s,40) else inputcaps(s,40);
    if (s<>'') then begin user.wherebbs:=s; done1:=TRUE; end;
  end;

  procedure dozipcode;
  begin
    case how of
      2:findarea;
      3:callfromarea:=1;
    end;
    case callfromarea of
      1:begin
          if (how=3) then
            print('Enter new postal code (##### or #####-####)')
          else begin
            print('Enter your zipcode (9 digit if available)');
            print(' ##### or #####-####');
          end;
          prt(':'); input(s,10);
          if (length(s) in [5,10]) then begin user.zipcode:=s; done1:=TRUE; end;
        end;
      2:begin
          print('Enter your zipcode (@#@#@# format -- "@"=letter "#"=number)');
          prt(':'); input(s,6);
          if ((length(s)=6) and
            (s[1] in ['A'..'Z']) and (s[2] in ['0'..'9']) and
            (s[3] in ['A'..'Z']) and (s[4] in ['0'..'9']) and
            (s[5] in ['A'..'Z']) and (s[6] in ['0'..'9'])) then
            done1:=TRUE
          else
            print('Illegal format!');
        end;
      3:begin
          print('Enter your postal code:');
          prt(':'); input(s,10);
          if (length(s)>2) then begin user.zipcode:=s; done1:=TRUE; end;
        end;
    end;
  end;

  procedure forwardmail;
  var u:userrec;
      s:astr;
      i:integer;
      b,ufo:boolean;
  begin
    nl;
    print('If you forward your mail, all mail');
    print('addressed to you will go to that person');
    print('Now enter the user''s number, or just');
    print('hit <CR> to deactivate mail forwarding.');
    prt(':'); input(s,4);
    i:=value(s);
    nl;
    if (i=0) then begin
      user.forusr:=0;
      print('Forwarding deactivated.');
    end else begin
      ufo:=(filerec(uf).mode<>fmclosed);
      if (not ufo) then reset(uf);
      b:=TRUE;
      if (i>=filesize(uf)) then b:=FALSE
      else begin
        seek(uf,i); read(uf,u);
        if (u.deleted) or (nomail in u.ac) then b:=FALSE;
      end;
      if (i=usernum) then b:=FALSE;
      if (b) then begin
        user.forusr:=i;
        print('Forwarding set to: '+caps(u.name)+' #'+cstr(i));
        sysoplog('Started forwarding mail to '+caps(u.name)+' #'+cstr(i));
      end else
        print('Sorry, can''t forward to that user.');
      if (not ufo) then close(uf);
    end;
  end;

  procedure mailbox;
  begin
    if (nomail in user.ac) then begin
      user.ac:=user.ac-[nomail];
      sprint(#3#5+'Mailbox now open.');
      sysoplog('Opened mailbox.');
    end else
      if (user.forusr<>0) then begin
        user.forusr:=0;
        print('Mail no longer forwarded.');
        sysoplog('Stopped forwarding mail.');
      end else begin
        if pynq('Do you want to close your mailbox? ') then begin
          user.ac:=user.ac+[nomail];
          sprint(#3#5+'Mailbox now closed.');
          sprint(#3#5+'You >CAN NOT< recieve mail now.');
          sysoplog('Closed mailbox.');
        end else
          if pynq('Do you want your mail forwarded? ') then forwardmail;
      end;
    done1:=TRUE;
  end;

  procedure tog_ansi;
  var c:char;
  begin
    prompt('Which emulation? (1) TTY (none), (2) ANSI, (3) AVATAR : ');
    cl(3); onek(c,'123');
    user.ac:=user.ac-[ansi];
    user.ac:=user.ac-[avatar];
    case c of
      '2':user.ac:=user.ac+[ansi];
      '3':user.ac:=user.ac+[avatar];
    end;
(*
    if (ansi in user.ac) then begin
      user.ac:=user.ac-[ansi];
      print('ANSI disabled.');
    end else begin
      user.ac:=user.ac+[ansi];
      print('ANSI activated.');
    end;
*)
    done1:=TRUE;
  end;

  procedure tog_color;
  begin
    if (color in user.ac) then begin
      user.ac:=user.ac-[color];
      print('ANSI color disabled.');
    end else begin
      user.ac:=user.ac+[color];
      print('ANSI color activated.');
    end;
    done1:=TRUE;
  end;

  procedure tog_pause;
  begin
    if (pause in user.ac) then begin
      user.ac:=user.ac-[pause];
      print('No pause on screen.');
    end else begin
      user.ac:=user.ac+[pause];
      print('Pause on screen active.');
    end;
    done1:=TRUE;
  end;

  procedure tog_input;
  begin
    if (onekey in user.ac) then begin
      user.ac:=user.ac-[onekey];
      print('Full line input.');
    end else begin
      user.ac:=user.ac+[onekey];
      print('One key input.');
    end;
    done1:=TRUE;
  end;

  procedure tog_clsmsg;
  begin
    if (user.clsmsg=1) then begin
      user.clsmsg:=2;
      print('Clear screen for messages OFF.');
    end else begin
      user.clsmsg:=1;
      print('Clear screen for messages ON.');
    end;
    done1:=TRUE;
  end;

  procedure tog_avadj;
  begin
    if (user.avadjust=2) then begin
      user.avadjust:=1;
      print('AVATAR color adjustment disabled.');
    end else begin
      user.avadjust:=2;
      print('AVATAR color adjustment enabled.');
    end;
    done1:=TRUE;
  end;

  procedure tog_expert;
  begin
    if (novice in user.ac) then begin
      user.ac:=user.ac-[novice];
      chelplevel:=1;
      print('Expert mode ON.');
    end else begin
      user.ac:=user.ac+[novice];
      chelplevel:=2;
      print('Expert mode OFF.');
    end;
    done1:=TRUE;
  end;

  procedure chcolors;
  var s:astr;
      c,c1,c2:integer;
      ch:char;
      mcol,ocol:byte;
      ctyp,done:boolean;

    function colo(n:integer):astr;
    begin
      case n of
        0:colo:='Black';
        1:colo:='Blue';
        2:colo:='Green';
        3:colo:='Cyan';
        4:colo:='Red';
        5:colo:='Magenta';
        6:colo:='Yellow';
        7:colo:='White';
      end;
    end;

    function dt(n:integer):astr;
    var s:astr;
    begin
      s:=colo(n and 7)+' on '+colo((n shr 4) and 7);
      if (n and 8)<>0 then s:=s+', High Intensity';
      if (n and 128)<>0 then s:=s+', Blinking';
      dt:=s;
    end;

    function stf(n:integer):astr;
    var s:astr;
    begin
      case n of
        0:s:='Other';
        1:s:='Default';
        2:s:='Unused';
        3:s:='Yes/No';
        4:s:='Prompts';
        5:s:='Note';
        6:s:='Input line';
        7:s:='Y/N question';
        8:s:='Blinking';
        9:s:='Other';
      end;
      stf:=cstr(n)+'. '+mln(s,20);
    end;

    procedure liststf;
    var c:integer;
    begin
      nl;
      for c:=0 to 9 do begin
        setc(7); prompt(stf(c));
        setc(user.cols[ctyp][c]); print(dt(user.cols[ctyp][c]));
      end;
    end;

  begin
    ctyp:=color in user.ac;
    setc(7);
    if (ctyp) then print('Set multiple colors.') else print('Set B&W colors.');
    ch:='?'; done:=FALSE;
    repeat
      case ch of
        'Q':done:=TRUE;
        'L':liststf;
        '0'..'9':begin
              nl; setc(7); print('Current:'); nl;
              c1:=value(ch);
              setc(7); prompt(stf(c1));
              setc(user.cols[ctyp][c1]); print(dt(user.cols[ctyp,c1]));
              nl; setc(7); print('Colors:'); nl;
              for c:=0 to 7 do begin
                setc(7); prompt(cstr(c)+'. '); setc(c); prompt(mln(colo(c),12));
                setc(7); prompt(mrn(cstr(c+8),2)+'. '); setc(c+8); print(mln(colo(c)+'!',9));
              end;
              ocol:=user.cols[ctyp][c1]; nl;
              prt('Foreground: '); input(s,2);
              if (s='') then mcol:=ocol and 7 else mcol:=value(s);
              prt('Background: '); input(s,2);
              if (s='') then
                mcol:=mcol or (ocol and 112)
              else
                mcol:=mcol or (value(s) shl 4);
              if pynq('Blinking? ') then mcol:=mcol or 128;
              nl; setc(7); prompt(stf(c1)); setc(mcol); print(dt(mcol)); nl;
              if pynq('Is this correct? ') then user.cols[ctyp][c1]:=mcol;
            end;
      end;
      if (not done) then begin
        nl; prt('Colors: (0-9) (L)ist (Q)uit :'); onek(ch,'QL0123456789');
      end;
    until done or hangup;
    done1:=TRUE;
  end;

  procedure checkwantpause;
  begin
    if pynq('Should screen pausing be active? ') then
      user.ac:=user.ac+[pause]
    else
      user.ac:=user.ac-[pause];
    done1:=TRUE;
  end;

  procedure ww(www:integer);
  begin
    nl;
    case www of
      1:doaddress;   2:doage;       3:doansi;
      4:docitystate; 5:docomputer;  6:dojob;
      7:doname;      8:dophone;     9:dopw;
     10:dorealname; 11:doscreen;   12:dosex;
     13:dowherebbs; 14:dozipcode;  15:mailbox;
     16:tog_ansi;   17:tog_color;  18:tog_pause;
     19:tog_input;  20:tog_clsmsg; 21:chcolors;
     22:tog_expert; 23:findarea;   24:checkwantpause;
     25:tog_avadj;
    end;
  end;
  
begin
  try:=0; done1:=FALSE;
  case how of
    1:repeat ww(which) until (done1) or (hangup);
    2,3:begin
        ww(which);
        if not done1 then print('Function aborted!');
      end;
  end;
end;

end.
