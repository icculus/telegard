(*****************************************************************************)
(*>                                                                         <*)
(*>  SYSOP2Z .PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  SysOp functions: System Configuration Editor -- "Z" command.           <*)
(*>                                                                         <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit sysop2z;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  cuser,
  common;

procedure pocolors;

implementation

procedure pocolors;
var u:userrec;
    c:char;
    done,col:boolean;
begin
  reset(uf); seek(uf,0); read(uf,u); close(uf);
  col:=color in u.ac;
  done:=FALSE;
  repeat
    cls;
    sprint(#3#5+'Default color editor:');
    nl;
    print('A. Edit Multiple colors');
    print('B. Edit B&W colors');
    nl;
    prt('Enter selection (A-B) : ');
    onek(c,'QAB');
    if c='Q' then done:=TRUE
    else begin
      if c='A' then u.ac:=u.ac+[color] else u.ac:=u.ac-[color];
      cstuff(21,3,u);
    end;
  until (done) or (hangup);
  if col then u.ac:=u.ac+[color] else u.ac:=u.ac-[color];
  reset(uf); seek(uf,0); write(uf,u); close(uf);
end;

end.
