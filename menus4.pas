(*****************************************************************************)
(*>                                                                         <*)
(*>  MENUS4  .PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  Menu command execution routines.                                       <*)
(*>                                                                         <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit menus4;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common;

procedure autovalidationcmd(pw:astr);

implementation

procedure autovalidationcmd(pw:astr);
var s:astr;
    ok:boolean;
begin
  nl;
  if (pw='') then begin
    sysoplog('[> Auto-Validation command executed - No PW specified!  Nothing done.');
    print('Sorry; this function is not available at this time.');
    exit;
  end;
  if (thisuser.sl=systat.autosl) and (thisuser.dsl=systat.autodsl) and
     (thisuser.ar=systat.autoar) then begin
    sysoplog('[> Already validated user executed Auto-Validation command');
    print('You''ve already been validated!  You do not need to use this command.');
    exit;
  end;

  print('Note (or warning, if you prefer):');
  print('The SysOp Log records ALL usage of this command.');
  print('Press <Enter> to abort.');
  nl;
  prt('Password: '); input(s,50);
  if (s='') then sprint(#3#7+'Function aborted.'^G)
  else begin
    ok:=(s=allcaps(pw));
    if (not ok) then begin
      sysoplog('[> User entered wrong password for Auto-Validation: "'+s+'"');
      sprint(#3#7+'Wrong!'^G);
    end else begin
      sysoplog('[> User correctly entered Auto-Validation password.');
      autovalidate(thisuser,usernum);
      topscr; commandline('User Validated.');
      printf('autoval');
      if (nofile) then begin
        nl;
        print('Correct.  You are now validated.');
      end;
    end;
  end;
end;

end.
