(*****************************************************************************)
(*>                                                                         <*)
(*>  SYSOP2B .PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  SysOp functions: System Configuration Editor -- "B" command.           <*)
(*>                                                                         <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit sysop2b;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  sysop3,
  common;

procedure pofile;

implementation

const
  aresure='Are you sure this is what you want? ';

function wantit:boolean;
begin
  nl; wantit:=pynq(aresure);
end;

procedure noch;
begin
  print('No change.');
end;

function phours(s:astr; lotime,hitime:integer):astr;
begin
  if (lotime<>hitime) then
    phours:=tch(cstr(lotime div 60))+':'+tch(cstr(lotime mod 60))+'...'+
            tch(cstr(hitime div 60))+':'+tch(cstr(hitime mod 60))
  else
    phours:=s;
end;

procedure gettimerange(s:astr; var st1,st2:integer);
var t1,t2,t1h,t1m,t2h,t2m:integer;
begin
  if pynq(s) then begin
    nl; nl;
    print('All entries in 24 hour time.  Hour: (0-23), Minute: (0-59)');
    nl;
    prompt('Starting time:');
    prt('  Hour   : '); mpl(5); inu(t1h);
    if (t1h<0) or (t1h>23) then t1h:=0;
    prt('                Minute : '); mpl(5); inu(t1m);
    if (t1m<0) or (t1m>59) then t1m:=0;
    nl;
    prompt('Ending time:  ');
    prt('  Hour   : '); mpl(5); inu(t2h);
    if (t2h<0) or (t2h>23) then t2h:=0;
    prt('                Minute : '); mpl(5); inu(t2m);
    if (t2m<0) or (t2m>59) then t2m:=0;
    t1:=t1h*60+t1m; t2:=t2h*60+t2m;
  end
  else begin t1:=0; t2:=0; end;
  nl;
  prompt('Hours: '+phours('Undeclared',t1,t2));
  if (wantit) then begin
    st1:=t1;
    st2:=t2;
  end;
end;

procedure pofile;
var s:string[80];
    i:integer;
    c:char;
    abort,next,done:boolean;
begin
  done:=FALSE;
  repeat
    with systat do begin
      cls;
      sprint(#3#5+'BBS configuration and file paths');
      nl;
      abort:=FALSE;
      printacr('A. BBS name & number  :'+bbsname+#3#3+' ('+bbsphone+')',abort,next);
      printacr('B. SysOp''s name/alias :<'+sysopname+'>',abort,next);
      printacr('C. SysOp chat hours   :'+mln(phours('*None*',lowtime,hitime),16)+
               'G. 300 baud hours     :'+phours('Always allowed',b300lowtime,b300hitime),abort,next);
      printacr('D. Regular DL hours   :'+mln(phours('Always allowed',dllowtime,dlhitime),16)+
               'H. 300 baud DL hours  :'+phours('Always allowed',b300dllowtime,b300dlhitime),abort,next);
      printacr('E. Shuttle Logon is   :'+mln(aonoff(shuttlelog,'Active','In-active'),16)+
               'I. New users are      :'+aonoff(closedsystem,'Rejected','Accepted'),abort,next);
      printacr('!. LOCKOUT 300 BAUD   :'+syn(lock300)+'             '+
               'J. Swap shell function:'+aonoff(swapshell,'Active','In-active'),abort,next);
      printacr('F. BBS Passwords                       '+
               'K. Pre-event warning  :'+cstr(eventwarningtime)+' seconds',abort,next);
      nl;
      printacr(' 0. Swap shell directory    :"'+swappath+'"',abort,next);
      printacr(' 1. Main data files dir.    :"'+gfilepath+'"',abort,next);
      printacr(' 2. Alternate text file dir.:"'+afilepath+'"',abort,next);
      printacr(' 3. Priv/pub msgs directory :"'+msgpath+'"',abort,next);
      printacr(' 4. Menu file directory     :"'+menupath+'"',abort,next);
      printacr(' 5. Text-file section dir.  :"'+tfilepath+'"',abort,next);
      printacr(' 6. Trap/log/chat directory :"'+trappath+'"',abort,next);
      printacr(' 7. Temporary directory     :"'+temppath+'"',abort,next);
      printacr(' 8. Last text-file edit date:'+tfiledate,abort,next);
(*      printacr(' 9. High message pointer: (A):'+hmsg.ltr+' (B):'+cstr(hmsg.number)+' (C):'+cstr(hmsg.ext),abort,next);*)
      nl;
      prt('Enter selection (A-J,!,1-8) [Q]uit : ');
      onek(c,'QABCDEFGHIJK!012345678'); nl;
      case c of
        'Q':done:=TRUE;
        'A':begin
              print('New BBS name:');
              prt(':'); inputwc(s,80);
              if (s<>'') then bbsname:=s else noch;
              nl;
              print('New BBS phone number, entered in the following format:');
              print(' ###-###-####');
              prt(':'); mpl(12); input(s,12);
              if (s<>'') then bbsphone:=s else noch;
            end;
        'B':begin
              prt('New SysOp name: '); mpl(30); inputl(s,30);
              if (s<>'') then sysopname:=s else noch;
            end;
        'C':if (incom) then
              sprint(#3#7+'This can only be changed locally.')
            else
              gettimerange('Do you want to declare sysop hours? ',
                            lowtime,hitime);
        'D':gettimerange('Do you want to declare download hours? ',
                          dllowtime,dlhitime);
        'E':shuttlelog:=pynq('Should Shuttle Logon be activated? ');
        '!':begin
              sprint(#3#5+'If 300 baud callers are locked out, "NO300.MSG"');
              sprint(#3#5+'will be printed each time a 300 baud caller connects,');
              sprint(#3#5+'and the user will be hung up.');
              nl;
              lock300:=pynq('Should 300 baud callers be LOCKED OUT? ');
            end;
        'F':begin
              print('System Passwords:');
              print('  A. SysOp password        :'+sysoppw);
              print('  B. New user password     :'+newuserpw);
              print('  C. Shuttle Logon password:'+shuttlepw);
              nl;
              prt('Change (A-C) : '); onek(c,'QABC'^M);
              if (c in ['A'..'C']) then begin
                case c of
                  'A':prt('New SysOp password: ');
                  'B':prt('New new-user password: ');
                  'C':prt('New Shuttle Logon password: ');
                end;
                mpl(20); input(s,20);
                nl; print('New password: "'+s+'"');
                if (wantit) then
                  case c of
                    'A':sysoppw:=s;
                    'B':newuserpw:=s;
                    'C':shuttlepw:=s;
                  end;
              end;
            end;
        'G':gettimerange('Do you want to declare 300 baud hours? ',
                          b300lowtime,b300hitime);
        'H':gettimerange('Do you want to declare 300 baud download hours? ',
                          b300dllowtime,b300dlhitime);
        'I':closedsystem:=pynq('Should new users be REJECTED? ');
        'J':swapshell:=pynq('Should the swap shell function be used? ');
        'K':begin
              prt('New pre-event warning time ['+cstr(eventwarningtime)+'] : ');
              inu(i);
              if (not badini) then eventwarningtime:=i;
            end;
        '0'..'7':begin
              prt('Enter new ');
              case c of
                '1':prt('GFILES');   '2':prt('AFILES');
                '3':prt('EMAIL');    '4':prt('MENUS');
                '5':prt('TFILES');   '6':prt('TRAP');
                '7':prt('TEMP');     '0':prt('SWAP');
              end;
              prt(' path:');
              nl; mpl(79); input(s,79);
              if (s<>'') then begin
                if (copy(s,length(s),1)<>'\') then s:=s+'\';
                if (wantit) then
                  case c of
                    '1':gfilepath:=s;     '2':afilepath:=s;
                    '3':msgpath:=s;       '4':menupath:=s;
                    '5':tfilepath:=s;     '6':trappath:=s;
                    '7':temppath:=s;      '0':swappath:=s;
                  end;
              end
              else noch;
            end;
        '8':begin
              prt('Enter new date in the form "MM/DD/YY":');
              nl; mpl(10); input(s,10);
              if (s='') or (copy(s,3,1)<>'/') or (copy(s,6,1)<>'/') then
                noch
              else
                tfiledate:=s;
            end;
(*        '9':begin
              sprint(#3#7+'!!!WARNING!!!'+#3#1);
              sprint(#3#5+'Do NOT use this command unless you know EXACTLY '+
                     'what you''re doing!!!');
              nl;
              prt('Change (A-C) [Q]uit :');
              onek(c,'QABC'^M);
              case c of
                'A':begin
                      prt('New letter (A-Z) :');
                      getkey(c); c:=upcase(c);
                      if (c in ['A'..'Z']) then hmsg.ltr:=c
                        else noch;
                    end;
                'B':begin
                      prt('New number (-32767-32768) :');
                      input(s,6); i:=value(s);
                      if ((i>=-32767) and (i<=32768)) then hmsg.number:=i
                        else noch;
                    end;
                'C':begin
                      prt('New extension (1-128) :');
                      inu(i);
                      if ((i>=1) and (i<=128)) then hmsg.ext:=i
                        else noch;
                    end;
                end;
            end;*)
      end;
    end;
  until (done) or (hangup);
end;

end.
