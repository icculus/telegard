(*****************************************************************************)
(*>                                                                         <*)
(*>  SYSOP2G .PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  SysOp functions: System Configuration Editor -- "G" command.           <*)
(*>                                                                         <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit sysop2g;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  sysop3,
  common;

procedure ponewauto;

implementation

function show_arflags(ss:integer):string;
var c:char;
    s:string[26];
begin
  s:='';
  for c:='A' to 'Z' do
    case ss of
      1:if c in systat.newar then s:=s+c else s:=s+'-';
      2:if c in systat.autoar then s:=s+c else s:=s+'-';
    end;
  show_arflags:=s;
end;

function show_restric(ss:integer):string;
var r:uflags;
    s:string[15];
begin
  s:='';
  for r:=rlogon to rmsg do
    case ss of
      1:if r in systat.newac then
          s:=s+copy('LCVBA*PEKM',ord(r)+1,1)
        else s:=s+'-';
      2:if r in systat.autoac then
          s:=s+copy('LCVBA*PEKM',ord(r)+1,1)
        else s:=s+'-';
    end;
  s:=s+'/';
  for r:=fnodlratio to fnodeletion do
    case ss of
      1:if r in systat.newac then
          s:=s+copy('1234',ord(r)-19,1)
        else s:=s+'-';
      2:if r in systat.autoac then
          s:=s+copy('1234',ord(r)-19,1)
        else s:=s+'-';
    end;
  show_restric:=s;
end;

procedure autoswac(var u:systatrec; r:uflags);
begin
  if r in u.autoac then u.autoac:=u.autoac-[r] else u.autoac:=u.autoac+[r];
end;

procedure autoacch(c:char; var u:systatrec);
begin
  case c of
    'L':autoswac(u,rlogon);
    'C':autoswac(u,rchat);
    'V':autoswac(u,rvalidate);
    'B':autoswac(u,rbackspace);
    'A':autoswac(u,ramsg);
    '*':autoswac(u,rpostan);
    'P':autoswac(u,rpost);
    'E':autoswac(u,remail);
    'K':autoswac(u,rvoting);
    'M':autoswac(u,rmsg);
    '1':autoswac(u,fnodlratio);
    '2':autoswac(u,fnopostratio);
    '3':autoswac(u,fnofilepts);
    '4':autoswac(u,fnodeletion);
  end;
end;

procedure zswac(var u:systatrec; r:uflags);
begin
  if (r in u.newac) then u.newac:=u.newac-[r] else u.newac:=u.newac+[r];
end;

procedure zacch(c:char; var u:systatrec);
begin
  case c of
    'L':zswac(u,rlogon);
    'C':zswac(u,rchat);
    'V':zswac(u,rvalidate);
    'B':zswac(u,rbackspace);
    'A':zswac(u,ramsg);
    '*':zswac(u,rpostan);
    'P':zswac(u,rpost);
    'E':zswac(u,remail);
    'K':zswac(u,rvoting);
    'M':zswac(u,rmsg);
    '1':zswac(u,fnodlratio);
    '2':zswac(u,fnopostratio);
    '3':zswac(u,fnofilepts);
    '4':zswac(u,fnodeletion);
  end;
end;

procedure ponewauto;
var done:boolean;
    c:char;
    b:byte;
    i:integer;
begin
  done:=FALSE;
  repeat
    cls;
    sprint(#3#5+'New user configuration              Auto-validation command');
    nl;
    print('A. SL : '+mln(cstr(systat.newsl),28)+'F. SL :'+cstr(systat.autosl));
    print('B. DSL: '+mln(cstr(systat.newdsl),28)+'G. DSL:'+cstr(systat.autodsl));
    print('C. AR : '+mln(show_arflags(1),28)+'H. AR :'+show_arflags(2));
    print('D. AC : '+mln(show_restric(1),28)+'I. AC :'+show_restric(2));
    print('E. #FP: '+cstr(systat.newfp));
    nl;
    prt('Enter selection (A-I) [Q]uit : ');
    onek(c,'QABCDEFGHI'); nl;
    case c of
      'A':begin
            prt('Enter new user SL: '); mpl(3); ini(b);
            if not badini then systat.newsl:=b;
          end;
      'B':begin
            prt('Enter new user DSL: '); mpl(3); ini(b);
            if not badini then systat.newdsl:=b;
          end;
      'C':repeat
            prt('Toggle AR Flag? (A-Z) <CR>=Quit ['+show_arflags(1)+'] : ');
            onek(c,'ABCDEFGHIJKLMNOPQRSTUVWXYZ'^M);
            if c in ['A'..'Z'] then
              if c in systat.newar then systat.newar:=systat.newar-[c]
              else systat.newar:=systat.newar+[c];
          until (c=^M) or (hangup);
      'D':repeat
            prt('Restrictions [?]Help <CR>=Quit ['+show_restric(1)+'] : ');
            onek(c,'Q?LCVBA*PEKM1234'^M);
            case c of
              'Q',^M:c:='Q';
              '?':restric_list;
            else
                  zacch(c,systat);
            end;
          until (c='Q') or (hangup);
      'E':begin
            prt('Enter new user file points: '); mpl(5); inu(i);
            if not badini then systat.newfp:=i;
          end;
      'F':begin
            prt('Enter auto validation SL: '); ini(b);
            if not badini then systat.autosl:=b;
          end;
      'G':begin
            prt('Enter auto validation DSL: '); ini(b);
            if not badini then systat.autodsl:=b;
          end;
      'H':repeat
            prt('Toggle AR Flag? (A-Z) <CR>=Quit ['+show_arflags(2)+'] : ');
            onek(c,'ABCDEFGHIJKLMNOPQRSTUVWXYZ'^M);
            if c in ['A'..'Z'] then
              if c in systat.autoar then systat.autoar:=systat.autoar-[c]
              else systat.autoar:=systat.autoar+[c];
          until (c=^M) or (hangup);
      'I':begin
            repeat
              prt('Restrictions ['+show_restric(2)+'] [?]Help [Q]uit : ');
              onek(c,'Q?LCVBA*PEKM1234'^M);
              case c of
                'Q',^M:c:='Q';
                '?':restric_list;
              else
                    autoacch(c,systat);
              end;
            until (c='Q') or (hangup);
          end;
      'Q':done:=TRUE;
    end;
  until (done) or (hangup);
end;

end.
