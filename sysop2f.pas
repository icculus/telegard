(*****************************************************************************)
(*>                                                                         <*)
(*>  SYSOP2F .PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  SysOp functions: System Configuration Editor -- "F" command.           <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit sysop2f;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  sysop2fa,
  common;

procedure pofilesconfig;

implementation

procedure pofilesconfig;
var s:string[80];
    i:integer;
    c:char;
    b:byte;
    abort,next,done,changed:boolean;
begin
  done:=FALSE;
  repeat
    with systat do begin
      cls;
      sprint(#3#5+'File section configuration');
      nl;
      abort:=FALSE;
      printacr(#3#3+'A. '+#3#1+'Archive configuration',abort,next);
      printacr('B. Upload/download ratio          :'+aonoff(uldlratio,'Active','In-active'),abort,next);
      printacr('C. Auto file point compensation   :'+aonoff(fileptratio,'Active','In-active'),abort,next);
      printacr('D. File point compensation ratio  :'+cstr(fileptcomp)+' to 1',abort,next);
      printacr('E. Base file size per 1 file point:'+cstr(fileptcompbasesize)+'k',abort,next);
      printacr('F. Upload time refund percent     :'+cstr(ulrefund)+'%',abort,next);
      s:='G. "To-SysOp" file base           :';
      if (tosysopdir=255) then s:=s+'*None*' else s:=s+cstr(tosysopdir);
      printacr(s,abort,next);
      printacr('H. Auto-validate ALL files ULed?  :'+syn(validateallfiles),abort,next);
      printacr('I. Remote DOS re-direction device :'+systat.remdevice,abort,next);
      {rcg11242000 DOSism.}
      {printacr('J. Max k-bytes allowed in TEMP\3\ :'+cstr(systat.maxintemp),abort,next);}
      printacr('J. Max k-bytes allowed in TEMP/3/ :'+cstr(systat.maxintemp),abort,next);
      printacr('K. Min k-bytes to save for resume :'+cstr(systat.minresume),abort,next);
      nl;
      prt('Enter selection (A-K) [Q]uit : '); onek(c,'QABCDEFGHIJK'^M);
      nl;
      case c of
        'Q':done:=TRUE;
        'A':poarcconfig;
        'B':uldlratio:=not uldlratio;
        'C':fileptratio:=not fileptratio;
        'D'..'G':begin
              if (c<>'G') then prt('Range (0-255)') else
                prt('Range (0-'+cstr(maxulb)+')  (255 to disable)');
              nl; prt('New value: '); mpl(3); ini(b);
              if (not badini) then
                case c of
                  'D':fileptcomp:=b;
                  'E':fileptcompbasesize:=b;
                  'F':ulrefund:=b;
                  'G':if ((b>=0) and (b<=maxulb)) or (b=255) then
                        tosysopdir:=b;
                end;
            end;
        'H':validateallfiles:=not validateallfiles;
        'I':begin
              sprint(#3#5+'This should be "GATE1" (or "GATE2", etc) if you have it.');
              sprint(#3#5+'OTHERWISE, it should be "COM1" (or "COM2", etc).');
              nl;
              prt('New device: '); mpl(10);
              inputwn(remdevice,10,changed);
            end;
        'J':begin
              prt('New max k-bytes: '); inu(i);
              if (not badini) then systat.maxintemp:=i;
            end;
        'K':begin
              prt('New min resume k-bytes: '); inu(i);
              if (not badini) then systat.minresume:=i;
            end;
      end;
    end;
  until (done) or (hangup);
end;

end.
