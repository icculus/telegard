(*****************************************************************************)
(*>                                                                         <*)
(*>  SYSOP2C .PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  SysOp functions: System Configuration Editor -- "C" command.           <*)
(*>                                                                         <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit sysop2c;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common;

procedure poslsettings;

implementation

function qq(s:string):string;
var ss:string[22];
begin
  ss:='"'+s+'"';
  if (length(ss)<16) then ss:=mln(ss,16);
  qq:=ss;
end;

procedure poslsettings;
var s:acstring;
    c:char;
    abort,next,done:boolean;
begin
  done:=FALSE;
  repeat
    with systat do begin
      cls;
      sprint(#3#5+'System ACS settings');
      nl;
      abort:=FALSE; next:=FALSE;
      printacr('A. Full SysOp         :'+qq(sop)+
               'B. Full Co-SysOp      :'+qq(csop),abort,next);
      printacr('C. Message base SysOp :'+qq(msop)+
               'D. File base SysOp    :'+qq(fsop),abort,next);
      printacr('E. SysOp PW at logon  :'+qq(spw)+
               'F. See PW''s remotely  :'+qq(seepw),abort,next);
      printacr('G. Post public        :'+qq(normpubpost)+
               'H. Send e-mail        :'+qq(normprivpost),abort,next);
      printacr('I. See anon pub post  :'+qq(anonpubread)+
               'J. See anon E-mail    :'+qq(anonprivread),abort,next);
      printacr('K. Post anon ANY base :'+qq(anonpubpost)+
               'L. E-mail anon        :'+qq(anonprivpost),abort,next);
      printacr('M. See unval. files   :'+qq(seeunval)+
               'N. DL unval. files    :'+qq(dlunval),abort,next);
      printacr('O. No UL/DL ratio     :'+qq(nodlratio)+
               'P. No post/call ratio :'+qq(nopostratio),abort,next);
      printacr('R. No file pt checking:'+qq(nofilepts)+
               'S. ULs auto-credited  :'+qq(ulvalreq),abort,next);
      nl;
      prt('Enter selection (A-S) [Q]uit : ');
      onek(c,'QABCDEFGHIJKLMNOPRS'^M);

      if (c='Q') then done:=TRUE;

      nl;
      if (not done) then
        if (c in ['A'..'P','R'..'S']) then begin
          prt('New ACS: '); inputl(s,20);
          if (s<>'') then
            case c of
              'A':sop:=s;           'B':csop:=s;
              'C':msop:=s;          'D':fsop:=s;
              'E':spw:=s;           'F':seepw:=s;
              'G':normpubpost:=s;   'H':normprivpost:=s;
              'I':anonpubread:=s;   'J':anonprivread:=s;
              'K':anonpubpost:=s;   'L':anonprivpost:=s;
              'M':seeunval:=s;      'N':dlunval:=s;
              'O':nodlratio:=s;     'P':nopostratio:=s;
              'R':nofilepts:=s;     'S':ulvalreq:=s;
            end;
        end;
    end;
  until (done) or (hangup);
end;

end.
