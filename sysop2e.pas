(*****************************************************************************)
(*>                                                                         <*)
(*>  SYSOP2E .PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  SysOp functions: System Configuration Editor -- "E" command.           <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit sysop2e;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common;

procedure poflagfunc;

implementation

function sltype(i:integer):string;
begin
  case i of
    0:sltype:='File only';
    1:sltype:='Printer & File';
    2:sltype:='Printer only';
  end;
end;

procedure poflagfunc;
var s:string[80];
    c,cc:char;
    nuu,i:integer;
    abort,next,done:boolean;
    bbb:byte;
begin
  done:=FALSE;
  repeat
    with systat do begin
      cls;
      sprint(#3#5+'System flagged functions');
      nl;
      abort:=FALSE; next:=FALSE;
      printacr('A. Special effects          :'+onoff(specialfx)+
             '  B. Use FOSSIL comm driver    :'+onoff(fossil),abort,next);
      printacr('C. Handles allowed on system:'+onoff(allowalias)+
             '  D. Phone number in logon     :'+onoff(phonepw),abort,next);
      printacr('E. Local security protection:'+onoff(localsec)+
             '  F. Local screen security     :'+onoff(localscreensec),abort,next);
      printacr('G. Global activity trapping :'+onoff(globaltrap)+
             '  H. Auto chat buffer open     :'+onoff(autochatopen),abort,next);
      printacr('I. AutoMessage in logon     :'+onoff(autominlogon)+
             '  J. Bulletins in logon        :'+onoff(bullinlogon),abort,next);
      printacr('K. Last few callers in logon:'+onoff(lcallinlogon)+
             '  L. "Your info" in logon      :'+onoff(yourinfoinlogon),abort,next);
      printacr('M. BBS is multi-tasking     :'+onoff(multitask)+
             '  N. Offhook in local logon    :'+onoff(offhooklocallogon),abort,next);
      printacr('O. Mandatory voting         :'+onoff(forcevoting)+
             '  P. Compress file/msg numbers :'+onoff(compressbases),abort,next);
      printacr('R. UL duplicate file search :'+onoff(searchdup)+
             '  S. SysOp Log type            :'+sltype(slogtype),abort,next);
      printacr('T. Strip color off SysOp log:'+onoff(stripclog)+
             '  U. Use WFC menu logo         :'+onoff(usewfclogo),abort,next);
      printacr('V. Use BIOS for video output:'+onoff(usebios)+
             '  W. Suppress snow on CGA      :'+onoff(cgasnow),abort,next);
      printacr('X. Use EMS for overlay file :'+onoff(useems),abort,next);
      printacr('',abort,next);
      s:='1. New user message sent to :';
      if (newapp=-1) then s:=s+'Off' else s:=s+mn(newapp,3);
      s:=s+'  2. Guest user number         :';
      if (guestuser=-1) then s:=s+'Off' else s:=s+mn(guestuser,3);
      printacr(s,abort,next);
      s:='3. Mins before timeout bell :';
      if (timeoutbell=-1) then s:=s+'Off' else s:=s+mn(timeoutbell,3);
      s:=s+'  4. Mins before timeout       :';
      if (timeout=-1) then s:=s+'Off' else s:=s+mn(timeout,3);
      printacr(s,abort,next);
      nl;
      prt('Enter selection (A-X,1-4) [Q]uit : ');
      onek(c,'QABCDEFGHIJKLMNOPRSTUVWX1234'^M); nl;

      case c of
        'Q':done:=TRUE;
        'A':specialfx:=not specialfx;
        'B':begin
              remove_port;
              fossil:=not fossil;
              iport;
            end;
        'C':allowalias:=not allowalias;
        'D':phonepw:=not phonepw;
        'E':localsec:=not localsec;
        'F':localscreensec:=not localscreensec;
        'G':globaltrap:=not globaltrap;
        'H':autochatopen:=not autochatopen;
        'I':autominlogon:=not autominlogon;
        'J':bullinlogon:=not bullinlogon;
        'K':lcallinlogon:=not lcallinlogon;
        'L':yourinfoinlogon:=not yourinfoinlogon;
        'M':multitask:=not multitask;
        'N':offhooklocallogon:=not offhooklocallogon;
        'O':forcevoting:=not forcevoting;
        'P':begin
              compressbases:=not compressbases;
              nl;
              if (compressbases) then print('Compressing bases...')
                else print('De-compressing bases...');
              newcomptables;
            end;
        'R':searchdup:=not searchdup;
        'S':begin
              print('Current SysOp Log type: '+sltype(slogtype));
              nl;
              for i:=0 to 2 do print(cstr(i)+': '+sltype(i));
              nl;
              prt('New type: '); ini(bbb);
              if ((not badini) and (bbb in [0..2])) then slogtype:=bbb;
            end;
        'T':stripclog:=not stripclog;
        'U':usewfclogo:=not usewfclogo;
        'V':begin
              usebios:=not usebios;
              directvideo:=not usebios;
            end;
        'W':begin
              cgasnow:=not cgasnow;
              checksnow:=cgasnow;
            end;
        'X':useems:=not useems;
        '1'..'4':
          begin
            prt('[E]nable [D]isable this function: ');
            onek(cc,'Q ED'^M);
            if cc in ['E','D'] then begin
              badini:=FALSE;
              case cc of
                'D':i:=-1;
                'E':begin
                      prt('Range ');
                      case c of
                        '1','2':begin
                             reset(uf); nuu:=filesize(uf)-1; close(uf);
                             prt('(1-'+cstr(nuu)+')');
                           end;
                        '3','4':prt('(1-20)');
                      else
                           prt('(0-32767)');
                      end;
                      nl; prt('Enter value for this function: ');
                      inu(i);
                    end;
              end;
              if (not badini) then
                case c of
                  '1':if ((i>=1) and (i<=nuu)) or (cc='D') then newapp:=i;
                  '2':if ((i>=1) and (i<=nuu)) or (cc='D') then guestuser:=i;
                  '3':if ((i>=1) and (i<=20)) or (cc='D') then timeoutbell:=i;
                  '4':if ((i>=1) and (i<=20)) or (cc='D') then timeout:=i;
                end;
            end
            else print('No change.');
          end;
      end;
    end;
  until (done) or (hangup);
end;

end.
