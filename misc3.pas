(*****************************************************************************)
(*>                                                                         <*)
(*>  MISC3   .PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  Various miscellaneous functions used by the BBS.                       <*)
(*>                                                                         <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit misc3;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common;

procedure mmacro;
procedure finduserws(var usernum:integer);

implementation

procedure mmacro;
var macrf:file of macrorec;
    c,mc:char;
    mcn,n,n1,mn:integer;
    done,macchanged:boolean;

  procedure doctrl(c:char);
  begin
    cl(3); prompt('^'+c); cl(1);
  end;

  procedure listmac(s:string);
  var i:integer;
  begin
    sprompt(#3#5+'"'+#3#1);
    for i:=1 to length(s) do
      if (s[i]>=' ') then prompt(s[i]) else doctrl(chr(ord(s[i])+64));
    sprint(#3#5+'"');
  end;

  procedure listmacs;
  var i:integer;
  begin
    nl;
    sprint(#3#3+'Current Macros:');
    for i:=1 to 4 do begin
      nl; cl(5);
      case i of
        1:prompt('Ctrl-D: ');
        2:prompt('Ctrl-E: ');
        3:prompt('Ctrl-F: ');
        4:prompt('Ctrl-R: ');
      end;
      listmac(macros.macro[i]);
    end;
  end;

  procedure mmacroo(c:char);
  var mc:char;
      n1,n,mcn,mn:integer;
      s:string[255];
  begin
    nl;
    mc:=c;
    cl(5); print('Enter new ^'+mc+' macro now.');
    cl(5); print('Enter ^'+mc+' to end recording.  240 character limit.');
    nl; mcn:=ord(mc)-64;
    n:=1; s:=''; macok:=FALSE;
    mn:=pos(mc,'DEFR');
    repeat
      getkey(c);
{      if ((n<=240) and (c=chr(mcn))) then c:=#0;}

      if (c=^H) then begin
        c:=#0;
        if (n>=2) then begin
          prompt(^H' '^H); dec(n);
          if (s[n]<#32) then prompt(^H' '^H);
        end;
      end;

      if ((n<=240) and (c<>#0) and (c<>chr(mcn))) then begin
        if (c in [#32..#255]) then begin
          outkey(c);
          s[n]:=c; inc(n);
        end else
          if (c in [^A,^B,^C,^G,^I,^J,^K,^L,^M,^N,^P,^Q,^S,^T,
                    ^U,^V,^W,^X,^Y,^Z,#27,#28,#29,#30,#31]) then begin
            if (c=^M) then nl
              else doctrl(chr(ord(c)+64));
            s[n]:=c; inc(n);
          end;
      end;
    until ((c=chr(mcn)) or (hangup));
    s[0]:=chr(n-1);
    nl; nl;
    cl(3); print('Your ^'+mc+' macro is now:');
    nl; listmac(s); nl;
    com_flush_rx;
    if pynq('Is this what you want? ') then begin
      macros.macro[mn]:=s;
      print('Macro saved.');
      macchanged:=TRUE;
    end else
      print('Macro not saved.');
    macok:=TRUE;
  end;

begin
  macchanged:=FALSE;
  done:=FALSE;
  listmacs;
  repeat
    nl;
    prt('Macro modification (DEFR,?=help) : ');
    onek(c,'QLDEFR?');
    case c of
      '?':begin
            nl;
            print('D,E,F,R:Modify macro');
            lcmds(12,3,'List macros','Quit');
          end;
      'D','E','F','R':mmacroo(c);
      'L':listmacs;
      'Q':done:=TRUE;
    end;
  until (done) or (hangup);
  if (macchanged) then
    with thisuser do begin
      assign(macrf,systat.gfilepath+'macro.lst');
      {$I-} reset(macrf); {$I+}
      if (ioresult<>0) then begin
        sysoplog('!!! "MACRO.LST" file not found.  Created.');
        rewrite(macrf); close(macrf); reset(macrf);
      end;
      if (mpointer=-1) then mpointer:=filesize(macrf);
      seek(macrf,mpointer); write(macrf,macros); close(macrf);
    end;
end;

procedure finduserws(var usernum:integer);
var user:userrec;
    sr:smalrec;
    nn,duh:astr;
    t,i,i1,gg:integer;
    c:char;
    sfo,ufo,done,asked:boolean;
begin
  ufo:=(filerec(uf).mode<>fmclosed);
  if (not ufo) then reset(uf);
  input(nn,36);
  usernum:=value(nn);
  if (nn='SYSOP') then nn:='1';
  if (usernum>0) then begin
    if (usernum>filesize(uf)-1) then begin
      print('Unknown User.');
      usernum:=0;
    end else begin
      seek(uf,usernum);
      read(uf,user);
    end;
  end else
    if (nn<>'') then begin
      sfo:=(filerec(sf).mode<>fmclosed);
      if (not sfo) then reset(sf);
      done:=FALSE; asked:=FALSE;
      gg:=0;
      while ((gg<filesize(sf)-1) and (not done)) do begin
        inc(gg);
        seek(sf,gg); read(sf,sr);
        if (pos(nn,sr.name)<>0) then
          if (sr.name=nn) then
            usernum:=sr.number
          else begin
            if (not asked) then begin nl; asked:=TRUE; end;
            sprint(#3#1+'Incomplete match --> '+#3#3+caps(sr.name)+' #'+
                   cstr(sr.number));
            sprompt(#3#7+'Is this correct? (Y/N,Q=Quit) : ');
            onek(c,'QYN'^M);
            done:=TRUE;
            case c of
              'Q':usernum:=0;
              'Y':usernum:=sr.number;
            else
                  done:=FALSE;
            end;
          end;
      end;
      if (usernum=0) then print('User not found.');
      if (not sfo) then close(sf);
    end;
  if (not ufo) then close(uf);
end;

end.
