(*****************************************************************************)
(*>                                                                         <*)
(*>  SYSOP2H .PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  SysOp functions: System Configuration Editor -- "H" command.           <*)
(*>                                                                         <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit sysop2h;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common;

procedure pomisc1;

implementation

procedure pomisc1;
var c:char;
    abort,next,done,changed:boolean;
begin
  done:=FALSE;
  repeat
    with systat do begin
      cls;
      sprint(#3#5+'Miscellaneous configuration');
      nl;
      abort:=FALSE;
      printacr('A. System start-out menu       :'+allstartmenu,abort,next);
      printacr('B. SysOp chat color-filter     :'+chatcfilter1,abort,next);
      printacr('C. User chat color-filter      :'+chatcfilter2,abort,next);
      printacr('D. Default bulletin prefix file:'+bulletprefix,abort,next);
      nl;
      prt('Enter selection (A-D) [Q]uit : '); onek(c,'QABCD'^M);
      nl;
      case c of
        'Q':done:=TRUE;
        'A'..'D':begin
                   print('Enter new:');
                   case c of
                     'A':inputwn(allstartmenu,8,changed);
                     'B':inputwn(chatcfilter1,12,changed);
                     'C':inputwn(chatcfilter2,12,changed);
                     'D':inputwn(bulletprefix,8,changed);
                   end;
                 end;
      end;
    end;
  until ((done) or (hangup));
end;

end.
