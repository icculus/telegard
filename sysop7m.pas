(*****************************************************************************)
(*>                                                                         <*)
(*>  SYSOP7M .PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  SysOp functions: Menu editor -- "M" command (modify commands)          <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit sysop7m;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common,
  file9,
  menus2,
  sysop1;

procedure memm(scurmenu:astr; var menuchanged:boolean);

implementation

procedure memm(scurmenu:astr; var menuchanged:boolean);
var i1,i2,ii,z:integer;
    c:char;
    s:astr;
    b:byte;
    bb:boolean;
begin
  prt('Begin editing at which? (1-'+cstr(noc)+') : '); inu(ii);
  c:=' ';
  if (ii>=1) and (ii<=noc) then begin
    while (c<>'Q') and (not hangup) do begin
      repeat
        with cmdr[ii] do begin
          if (c<>'?') then begin
            cls;
            sprint(#3#3+'Menu filename: '+scurmenu);
            print('Command #'+cstr(ii)+' of '+cstr(noc));
            nl;
            with cmdr[ii] do begin
              sprint('1. Long descript :'+ldesc);
              sprint('2. Short descript:'+sdesc);
              print('3. Cmd letters   :'+ckeys);
              print('4. ACS required  :"'+acs+'"');
              print('5. Cmdkeys       :'+cmdkeys);
              print('6. MString       :'+mstring);
              s:='';
              if (hidden in commandflags) then s:='(H)idden';
              if (unhidden in commandflags) then begin
                if (s<>'') then s:=s+', ';
                s:=s+'(U)nhidden';
              end;
              if (s='') then s:='None';
              print('7. Flags         :'+s);
              print('Q. Quit');
            end;
          end;
          nl;
          prt('Edit menu (?=help) : ');
          onek(c,'Q1234567[]FJL?'^M);
          nl;
          case c of
            '1':begin
                  print('New long description:');
                  prt(':'); inputwnwc(ldesc,70,menuchanged);
                end;
            '2':begin
                  prt('New short description: ');
                  inputwnwc(sdesc,35,menuchanged);
                end;
            '3':begin
                  prt('New command letters: '); mpl(14); input(s,14);
                  if (s<>'') then begin ckeys:=s; menuchanged:=TRUE; end;
                end;
            '4':begin
                  prt('New ACS: '); mpl(20);
                  inputwn(acs,20,menuchanged);
                end;
            '5':begin
                  prt('New command type: '); mpl(2); input(s,2);
                  if (length(s)=2) then begin cmdkeys:=s; menuchanged:=TRUE; end;
                end;
            '6':begin
                  prt('New MString: '); mpl(50);
                  inputwnwc(mstring,50,menuchanged);
                end;
            '7':begin
                  print('(H)idden command  -  (U)nhidden command');
                  nl;
                  prt('Choose : '); onek(c,'QHU'^M);
                  bb:=menuchanged; menuchanged:=TRUE;
                  case c of
                    'H':if (hidden in commandflags) then
                          commandflags:=commandflags-[hidden]
                     else commandflags:=commandflags+[hidden];
                    'U':if (unhidden in commandflags) then
                          commandflags:=commandflags-[unhidden]
                     else commandflags:=commandflags+[unhidden];
                  else
                        menuchanged:=bb;
                  end;
                  c:=#0;
                end;
            '[':if (ii>1) then dec(ii) else c:=' ';
            ']':if (ii<noc) then inc(ii) else c:=' ';
            'F':if (ii<>1) then ii:=1 else c:=' ';
            'J':begin
                  prt('Jump to entry: ');
                  input(s,3);
                  if (value(s)>=1) and (value(s)<=noc) then ii:=value(s) else c:=' ';
                end;
            'L':if (ii<>noc) then ii:=noc else c:=' ';
            '?':ee_help;
          end;
        end;
      until (c in ['Q','[',']','F','J','L']) or (hangup);
    end;
  end;
end;

end.
