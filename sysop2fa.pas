(*****************************************************************************)
(*>                                                                         <*)
(*>  SYSOP2FA.PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  SysOp functions: System Configuration Editor -- "F","A" command.       <*)
(*>                                                                         <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit sysop2fa;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common;

procedure poarcconfig;

implementation

function nt(s:string):string;
begin
  if s<>'' then nt:=s else nt:='*None*';
  if copy(s,1,1)='/' then begin
    s:='"'+s+'" - ';
    case s[3] of
      '1':nt:=s+'*Internal* ZIP viewer';
      '2':nt:=s+'*Internal* ARC/PAK viewer';
      '3':nt:=s+'*Internal* ZOO viewer';
      '4':nt:=s+'*Internal* LZH viewer';
    end;
  end;
end;

function nt2(i:integer):string;
begin
  if i<>-1 then nt2:=cstr(i) else nt2:='-1 (ignores)';
end;

procedure poarcconfig;
var ii,i2,numarcs:integer;
    c:char;
    s:astr;
    bb:byte;
    abort,next,changed:boolean;
begin
  numarcs:=1;
  while (systat.filearcinfo[numarcs].ext<>'') and (numarcs<7) do
    inc(numarcs);
  dec(numarcs);
  c:=' ';
  while (c<>'Q') and (not hangup) do begin
    repeat
      if c<>'?' then begin
        cls;
        print('Archive configuration edit');
        nl;
        abort:=FALSE; next:=FALSE;
        for bb:=1 to 3 do begin
          s:=systat.filearccomment[bb]; if s='' then s:='*None*';
          printacr(cstr(bb)+'. Archive comment: '+s,abort,next);
        end;
        nl;
        printacr(#3#3+' NN'+sepr2+'Ext'+sepr2+'Compression cmdline      '+
                 sepr2+'Decompression cmdline    '+sepr2+'Success Code',abort,next);
        printacr(#3#4+' ==:===:=========================:=========================:============',abort,next);
        ii:=1;
        while (ii<=numarcs) and (not abort) and (not hangup) do begin
          with systat.filearcinfo[ii] do begin
            if (active) then s:=#3#5+'+' else s:=#3#1+'-';
            s:=s+#3#0+mn(ii,2)+' '+#3#3+mln(ext,3)+' '+
                 #3#5+mlnnomci(arcline,25)+' '+mlnnomci(unarcline,25)+' '+
                 nt2(succlevel);
            printacr(s,abort,next);
          end;
          inc(ii);
        end;
      end;
      nl;
      prt('Archive edit (Q,?=help) : ');
      onek(c,'Q?DIM123'^M);
      nl;
      case c of
        '?':begin
              print('<CR>Redisplay screen');
              print('1-3:Archive comments');
              lcmds(16,3,'Insert archive','Delete archive');
              lcmds(16,3,'Modify archives','Quit and save');
            end;
        'M':begin
              prt('Begin editing at which? '); ini(bb);
              if (not badini) and (bb>=1) and (bb<=numarcs) then begin
                i2:=bb;
                while (c<>'Q') and (not hangup) do begin
                  repeat
                    if c<>'?' then begin
                      cls;
                      print('Archive #'+cstr(i2)+' of '+cstr(numarcs));
                      nl;
                      with systat.filearcinfo[i2] do begin
                        print('1. Active                 : '+syn(active));
                        print('2. Extension name         : '+ext);
                        print('3. Interior list method   : '+nt(listline));
                        print('4. Compression cmdline    : '+nt(arcline));
                        print('5. Decompression cmdline  : '+nt(unarcline));
                        print('6. Integrity check cmdline: '+nt(testline));
                        print('7. Add comment cmdline    : '+nt(cmtline));
                        print('8. Errorlevel for success : '+nt2(succlevel));
                        print('Q. Quit');
                      end;
                    end;
                    nl;
                    prt('Edit menu: (1-8,[,],Q) : ');
                    onek(c,'Q12345678[]?'^M);
                    nl;
                    case c of
                      '?':begin
                            sprint(' #:Modify item  <CR>Redisplay screen');
                            lcmds(14,3,'[Back archive',']Forward archive');
                            lcmds(14,3,'Quit and save','');
                          end;
                      '1'..'8':
                          with systat.filearcinfo[i2] do
                            case c of
                              '1':active:=not active;
                              '2':begin
                                    prt('New extension: '); input(s,3);
                                    if s<>'' then ext:=s;
                                  end;
                              '3'..'7':
                                  begin
                                    prt('New commandline: ');
                                    inputl(s,25);
                                    if s<>'' then begin
                                      if s=' ' then
                                        if pynq('Set to NULL string? ') then
                                          s:='';
                                      if s<>' ' then
                                        case c of
                                          '3':listline:=s;
                                          '4':arcline:=s;
                                          '5':unarcline:=s;
                                          '6':testline:=s;
                                          '7':cmtline:=s;
                                        end;
                                    end;
                                  end;
                              '8':begin
                                    prt('New errorlevel: '); inu(ii);
                                    if not badini then
                                      systat.filearcinfo[i2].succlevel:=ii;
                                  end;
                            end;
                      '[':if i2>1 then dec(i2) else c:=' ';
                      ']':if i2<numarcs then inc(i2) else c:=' ';
                    end;
                  until (c in ['Q','[',']']) or (hangup);
                end;
              end;
              c:=' ';
            end;
        'D':begin
              prt('Delete which? '); ini(bb);
              if (not badini) and (bb in [1..numarcs]) then begin
                nl;
                sprompt(#3#3+systat.filearcinfo[bb].ext);
                if pynq('   Delete it? ') then begin
                  for i2:=bb to numarcs-1 do
                    systat.filearcinfo[i2]:=systat.filearcinfo[i2+1];
                  systat.filearcinfo[numarcs].ext:='';
                  dec(numarcs);
                end;
              end;
            end;
        'I':if numarcs<>maxarcs then begin
              prt('Insert before which (1-'+cstr(numarcs+1)+') : ');
              ini(bb);
              if (not badini) and (bb in [1..numarcs+1]) then begin
                if bb<>numarcs+1 then
                  for i2:=numarcs+1 downto bb+1 do
                    systat.filearcinfo[i2]:=systat.filearcinfo[i2-1];
                with systat.filearcinfo[bb] do begin
                  active:=FALSE;
                  ext:='AAA';
                  listline:=''; arcline:=''; unarcline:='';
                  testline:=''; cmtline:=''; succlevel:=-1;
                end;
                inc(numarcs);
              end;
            end;
        '1'..'3':
            begin
              bb:=ord(c)-48;
              prt('New comment #'+c+': ');
              inputwnwc(systat.filearccomment[bb],32,changed);
            end;
      end;
    until (c='Q') or (hangup);
  end;
end;

end.
