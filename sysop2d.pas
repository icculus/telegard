(*****************************************************************************)
(*>                                                                         <*)
(*>  SYSOP2D .PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  SysOp functions: System Configuration Editor -- "D" command.           <*)
(*>                                                                         <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit sysop2d;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common;

procedure pogenvar;

implementation

procedure pogenvar;
var c:char;
    i:integer;
    bbb:byte;
    abort,next,done:boolean;
begin
  done:=FALSE;
  repeat
    with systat do begin
      cls;
      sprint(#3#5+'System variables');
      nl;
      abort:=FALSE; next:=FALSE;
      printacr('A. Max private sent per call:'+mn(maxprivpost,3)+
        '  B. Max feedback sent per call:'+mn(maxfback,3),abort,next);
      printacr('C. Max public posts per call:'+mn(maxpubpost,3)+
        '  D. Max chat attempts per call:'+mn(maxchat,3),abort,next);
      printacr('E. Normal max mail waiting  :'+mn(maxwaiting,3)+
        '  F. CoSysOp max mail waiting  :'+mn(csmaxwaiting,3),abort,next);
      printacr('G. Normal max lines/message :'+mn(maxlines,3)+
        '  H. CoSysOp max lines/message :'+mn(csmaxlines,3),abort,next);
      printacr('I. Number of logon attempts :'+mn(maxlogontries,3)+
        '  J. Backspace delay           :'+mn(bsdelay,3),abort,next);
      printacr('K. SysOp chat color         :'+mn(sysopcolor,3)+
        '  L. User chat color           :'+mn(usercolor,3),abort,next);
      printacr('M. Min. space for posts     :'+mn(minspaceforpost,4)+
        ' N. Min. space for uploads    :'+mn(minspaceforupload,4),abort,next);
      printacr('O. Back SysOp Log keep days :'+mn(backsysoplogs,3)+
        '  P. Blank WFC menu minutes    :'+mn(wfcblanktime,4),abort,next);
      printacr('R. Default video line length:'+mn(linelen,3)+
        '  S. Default video page length :'+mn(pagelen,3),abort,next);
      nl;
      prt('Enter selection (A-S) [Q]uit : ');
      onek(c,'QABCDEFGHIJKLMNOPRS'^M); nl;

      case c of
        'Q':done:=TRUE;
        'A'..'P','R'..'S':
          begin
            prt('Range ');
            case c of
              'G','H':prt('(1-160)');
              'K','L':prt('(0-9)');
              'M','N':prt('(0-32767)');
              'O':prt('(1-99)');
              'R':prt('(32-132)');
              'S':prt('(4-50)');
            else
                  prt('(0-255)');
            end;
            nl; prt('New value: ');
            case c of
              'M','N':inu(i);
            else
                 ini(bbb);
            end;
            if (not badini) then
              case c of
                'A':maxprivpost:=bbb;
                'B':maxfback:=bbb;
                'C':maxpubpost:=bbb;
                'D':maxchat:=bbb;
                'E':maxwaiting:=bbb;
                'F':csmaxwaiting:=bbb;
                'G':if (bbb in [1..160]) then maxlines:=bbb;
                'H':if (bbb in [1..160]) then csmaxlines:=bbb;
                'I':maxlogontries:=bbb;
                'J':bsdelay:=bbb;
                'K':if (bbb in [0..9]) then sysopcolor:=bbb;
                'L':if (bbb in [0..9]) then usercolor:=bbb;
                'M':if (i>0) then minspaceforpost:=i;
                'N':if (i>0) then minspaceforupload:=i;
                'O':if (bbb in [1..99]) then backsysoplogs:=bbb;
                'P':if (bbb in [0..255]) then wfcblanktime:=bbb;
                'R':if (bbb in [32..132]) then linelen:=bbb;
                'S':if (bbb in [4..50]) then pagelen:=bbb;
              end;
          end;
      end;
    end;
  until (done) or (hangup);
end;

end.
