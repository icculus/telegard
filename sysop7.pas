(*****************************************************************************)
(*>                                                                         <*)
(*>  SYSOP7  .PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  SysOp functions: Menu editor                                           <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit sysop7;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common,
  sysop7m,
  file9,
  menus2,
  sysop1;

procedure menu_edit;

implementation

var menuchanged:boolean;
    x:integer;
    filv:text;

function readin:boolean;                    (* read in the menu file curmenu *)
var s:astr;
    i:integer;
begin
  noc:=0;
  assign(filv,curmenu);
  {$I-} reset(filv); {$I+}
  if ioresult<>0 then begin
    print('"'+curmenu+'" does not exist.');
    readin:=FALSE;
  end else begin
    menuchanged:=FALSE;

    with menur do begin
      readln(filv,menuname[1]);
      readln(filv,menuname[2]);
      readln(filv,menuname[3]);
      readln(filv,directive);
      readln(filv,tutorial);
      readln(filv,menuprompt);
      readln(filv,acs);
      readln(filv,password);
      readln(filv,fallback);
      readln(filv,forcehelplevel);
      readln(filv,gencols);
      for i:=1 to 3 do readln(filv,gcol[i]);
      readln(filv,s);
      s:=allcaps(s); menuflags:=[];
      if (pos('C',s)<>0) then menuflags:=menuflags+[clrscrbefore];
      if (pos('D',s)<>0) then menuflags:=menuflags+[dontcenter];
      if (pos('N',s)<>0) then menuflags:=menuflags+[nomenuprompt];
      if (pos('P',s)<>0) then menuflags:=menuflags+[forcepause];
      if (pos('T',s)<>0) then menuflags:=menuflags+[autotime];
    end;
    repeat
      inc(noc);
      with cmdr[noc] do begin
        readln(filv,ldesc);
        readln(filv,sdesc);
        readln(filv,ckeys);
        readln(filv,acs);
        readln(filv,cmdkeys);
        readln(filv,mstring);
        readln(filv,s);
        s:=allcaps(s); commandflags:=[];
        if (pos('H',s)<>0) then commandflags:=commandflags+[hidden];
        if (pos('U',s)<>0) then commandflags:=commandflags+[unhidden];
      end;
    until (eof(filv));
    close(filv);

    readin:=TRUE;
  end;
end;

procedure menu_edit;
const showcmdtype:integer=1;
      menudata:boolean=FALSE;
var nocsave,i,i1,i2,ii:integer;
    c:char;
    abort,next:boolean;
    s,scurmenu:astr;

  procedure makenewfile(fn:astr);                 (* make a new command list *)
  var f:text;
  begin
    assign(f,fn);
    {$I-} rewrite(f); {$I+}
    if (ioresult=0) then begin
      writeln(f,'New TeleGard-X Menu');
      writeln(f,'');
      writeln(f,'');

      writeln(f,'');
      writeln(f,'');
      writeln(f,'Command? ');
      writeln(f,'');
      writeln(f,'');
      writeln(f,'MAIN');
      writeln(f,'0');
      writeln(f,'4');
      writeln(f,'4');
      writeln(f,'3');
      writeln(f,'5');
      writeln(f,'T');

      writeln(f,'(Q)uit back to the main menu');
      writeln(f,'(Q)uit to main');
      writeln(f,'Q');
      writeln(f,'');
      writeln(f,'-^');
      writeln(f,'main');
      writeln(f,'');
      close(f);
    end;
  end;

  procedure newcmd(n:integer);                          { new command stuff }
  begin
    with cmdr[n] do begin
      ldesc:='(XXX)New TeleGard-X Command';
      sdesc:='(XXX)New Cmd';
      ckeys:='XXX';
      acs:='';
      cmdkeys:='-L';
      mstring:='';
      commandflags:=[];
    end;
  end;

  procedure moveinto(i1,i2:integer);
  begin
    cmdr[i1]:=cmdr[i2];
  end;

  procedure mes;
  var s:astr;
      i:integer;
  begin
    rewrite(filv);
    with menur do begin
      writeln(filv,menuname[1]);
      writeln(filv,menuname[2]);
      writeln(filv,menuname[3]);
      writeln(filv,directive);
      writeln(filv,tutorial);
      writeln(filv,menuprompt);
      writeln(filv,acs);
      writeln(filv,password);
      writeln(filv,fallback);
      writeln(filv,forcehelplevel);
      writeln(filv,gencols);
      for i:=1 to 3 do writeln(filv,gcol[i]);
      s:='';
      if (clrscrbefore in menuflags) then s:=s+'C';
      if (dontcenter in menuflags) then s:=s+'D';
      if (nomenuprompt in menuflags) then s:=s+'N';
      if (forcepause in menuflags) then s:=s+'P';
      if (autotime in menuflags) then s:=s+'T';
      writeln(filv,s);
    end;
    for i:=1 to noc do begin
      with cmdr[i] do begin
        writeln(filv,ldesc);
        writeln(filv,sdesc);
        writeln(filv,ckeys);
        writeln(filv,acs);
        writeln(filv,cmdkeys);
        writeln(filv,mstring);
        s:='';
        if (hidden in commandflags) then s:=s+'H';
        if (unhidden in commandflags) then s:=s+'U';
        writeln(filv,s);
      end;
    end;
    close(filv);
    sysoplog('* Saved menu file: '+scurmenu);
  end;

  procedure med;
  begin
    prt('Delete menu file: '); mpl(8); input(s,8);
    s:=systat.menupath+allcaps(s)+'.MNU';
    assign(filv,s);
    {$I-} reset(filv); {$I+}
    if (ioresult=0) then begin
      close(filv);
      nl;
      sprint('Menu file: '+#3#4+'"'+s+'"');
      if pynq('Delete it? ') then begin
        sysoplog('* Deleted menu file: "'+s+'"');
        erase(filv);
      end;
    end;
  end;

  procedure mei;
  begin
    prt('Insert menu file: '); mpl(8); input(s,8);
    s:=systat.menupath+allcaps(s)+'.MNU';
    assign(filv,s);
    {$I-} reset(filv); {$I+}
    if (ioresult=0) then close(filv)
    else begin
      sysoplog('* Inserted new menu file: "'+s+'"');
      makenewfile(s);
    end;
  end;

  procedure mem;
  var i,j,k:integer;
      c:char;
      b:byte;
      bb:boolean;

    procedure memd(i:integer);                   (* delete command from list *)
    var x:integer;
    begin
      if (i>=1) and (i<=noc) then begin
        for x:=i+1 to noc do cmdr[x-1]:=cmdr[x];
        dec(noc);
      end;
    end;

    procedure memi(i:integer);             (* insert a command into the list *)
    var x:integer;
        s:astr;
    begin
      if (i>=1) and (i<=noc+1) and (noc<50) then begin
        inc(noc);
        if (i<>noc) then
          for x:=noc downto i do cmdr[x]:=cmdr[x-1];
        newcmd(i);
      end;
    end;

    procedure memp;
    var i,j,k:integer;
    begin
      prt('Move which command? (1-'+cstr(noc)+') : '); inu(i);
      if ((not badini) and (i>=1) and (i<=noc)) then begin
        prt('Move before which command? (1-'+cstr(noc+1)+') : '); inu(j);
        if ((not badini) and (j>=1) and (j<=noc+1) and
            (j<>i) and (j<>i+1)) then begin
          memi(j);
          if j>i then k:=i else k:=i+1;
          cmdr[j]:=cmdr[k];
          if j>i then memd(i) else memd(i+1);
          menuchanged:=TRUE;
        end;
      end;
    end;

    function sfl(b:boolean; c:char):char;
    begin
      if (b) then sfl:=c else sfl:='-';
    end;

  begin
    prt('Modify menu file: '); mpl(8); input(s,8);
    assign(filv,systat.menupath+s+'.MNU');
    {$I-} reset(filv); {$I+}
    if ioresult=0 then begin
      close(filv);
      scurmenu:=s;
      curmenu:=systat.menupath+scurmenu+'.MNU';
      if readin then begin
        menuchanged:=FALSE;
        repeat
          if (c<>'?') then begin
            cls;
            abort:=FALSE; next:=FALSE;
            if (menudata) then begin
              printacr(#3#3+'Menu filename: '+scurmenu,abort,next);
              if (not abort) then begin
                with menur do begin
                  sprint('1. Menu titles   :'+menuname[1]);
                  if (menuname[2]<>'') then
                    sprint('   Menu title #2 :'+menuname[2]);
                  if (menuname[3]<>'') then
                    sprint('   Menu title #3 :'+menuname[3]);
                  print('2. Help files    :'+
                        aonoff((directive=''),'*Generic*',directive)+' / '+
                        aonoff((tutorial=''),'*Generic*',tutorial));
                  print('3. Prompt        :'+menuprompt);
                  sprint(#3#3+'('+#3#1+menuprompt+#3#3+')');
                  print('4. ACS required  :"'+acs+'"');
                  print('5. Password      :'+
                        aonoff((password=''),'*None*',password));
                  print('6. Fallback menu :'+
                        aonoff((fallback=''),'*None*',fallback));
                  print('7. Forced ?-level:'+
                        aonoff((forcehelplevel=0),'None',cstr(forcehelplevel)));
                  print('8. Generic info  :'+cstr(gencols)+' cols - '+
                        cstr(gcol[1])+'/'+cstr(gcol[2])+'/'+cstr(gcol[3]));
                  print('9. Flags         :'+
                        sfl((clrscrbefore in menuflags),'C')+
                        sfl((dontcenter in menuflags),'D')+
                        sfl((nomenuprompt in menuflags),'N')+
                        sfl((forcepause in menuflags),'P')+
                        sfl((autotime in menuflags),'T'));
                  print('Q. Quit');
                end;
              end;
            end else
              showcmds(showcmdtype);
          end;
          nl;
          prt('Menu editor (?=help) : ');
          onek(c,'QDILMPSTX123456789?'^M);
          case c of
            '?':begin
                  nl;
                  print('<CR>Redisplay screen');
                  lcmds(20,3,'Delete command','PMove commands');
                  lcmds(20,3,'Insert command','Toggle display type');
                  lcmds(20,3,'Modify commands','XMenu data/command data');
                  lcmds(20,3,'Short generic menu','Long generic menu');
                  lcmds(20,3,'Quit and save','');
                end;
            'D':begin
                  prt('Delete which command? (1-'+cstr(noc)+') : '); ini(b);
                  if (not badini) and (b>=1) and (b<=noc) then begin
                    memd(b);
                    menuchanged:=TRUE;
                  end;
                end;
            'I':if (noc<50) then begin
                  prt('Insert before which command? (1-'+cstr(noc+1)+') : ');
                  inu(i);
                  if (not badini) and (i>=1) and (i<=noc+1) then begin
                    prt('Insert how many commands? (1-'+cstr(50-noc)+') [1] : ');
                    inu(j);
                    if (badini) then j:=1;
                    if (j>=1) and (j<=50-noc) then begin
                      for k:=1 to j do memi(i);
                      menuchanged:=TRUE;
                    end;
                  end;
                end else begin
                  sprint(#3#7+'You already have 50 commands, delete some to make room.');
                  nl; pausescr;
                end;
            'L':begin
                  genericmenu(3);
                  pausescr;
                end;
            'M':memm(scurmenu,menuchanged);
            'P':memp;
            'S':begin
                  genericmenu(2);
                  pausescr;
                end;
            'T':showcmdtype:=1-showcmdtype;  {* toggle between 0 and 1 *}
            'X':menudata:=not menudata;
            '1':begin
                  nl;
                  sprint(#3#5+'Up to THREE menu titles are allowed.');
                  sprint(#3#5+'Just leave unwanted titles set to NULL.');
                  for i:=1 to 3 do begin
                    nl; prt('New menu title #'+cstr(i)+': ');
                    inputwnwc(menur.menuname[i],100,menuchanged);
                  end;
                end;
            '2':begin
                  nl;
                  cl(5); print('Use @S IPL for SL sensitive menus.');
                  sprint(#3#5+'Set to NULL (with " ") to use generic menus.');
                  sprint(#3#5+'You can turn Tutorials completely off by using "*OFF*"');
                  sprint(#3#5+'as the tutorial filename.');
                  nl;
                  prt('New file displayed for help: '); mpl(12);
                  inputwn(menur.directive,12,menuchanged);
                  menur.directive:=allcaps(menur.directive);
                  nl;
                  prt('New tutorial file? [default ext=".TUT"] : '); mpl(12);
                  inputwn(menur.tutorial,12,menuchanged);
                  menur.tutorial:=allcaps(menur.tutorial);
                  nl;
                end;
            '3':begin
                  nl; prt('New menu prompt: ');
                  inputwnwc(menur.menuprompt,120,menuchanged);
                end;
            '4':begin
                  nl; prt('New menu ACS: '); mpl(20);
                  inputwn(menur.acs,20,menuchanged);
                end;
            '5':begin
                  nl; prt('New password: '); mpl(15);
                  inputwn1(menur.password,15,'u',menuchanged);
                end;
            '6':begin
                  nl; prt('New fallback menu: '); mpl(8);
                  inputwn1(menur.fallback,8,'u',menuchanged);
                end;
            '7':begin
                  nl; prt('New forced menu help-level (1-3,0=None) ['+
                    cstr(menur.forcehelplevel)+'] : ');
                  ini(b);
                  if ((not badini) and (b in [0..3])) then begin
                    menuchanged:=TRUE;
                    menur.forcehelplevel:=b;
                  end;
                end;
            '8':begin
                  repeat
                    nl;
                    print('C. Generic columns  :'+cstr(menur.gencols));
                    print('1. Bracket color    :'+cstr(menur.gcol[1]));
                    print('2. Command color    :'+cstr(menur.gcol[2]));
                    print('3. Description color:'+cstr(menur.gcol[3]));
                    print('S. Show menu');
                    nl;
                    prt('Select (CS,1-3,Q=Quit) : '); onek(c,'QCS123'^M);
                    nl;
                    if (c='S') then genericmenu(2);
                    if (c in ['C','1'..'3']) then begin
                      case c of
                        'C':prt('New number of generic columns (2-7) ['+
                                cstr(menur.gencols)+'] : ');
                      else
                            prt('New generic menu color '+c+' (0-9) ['+
                                cstr(menur.gcol[ord(c)-48])+'] : ');
                      end;
                      ini(b);
                      if (not badini) then
                        case c of
                          'C':if (b in [2..7]) then begin
                                menuchanged:=TRUE;
                                menur.gencols:=b;
                              end;
                        else
                              if (b in [0..9]) then begin
                                menuchanged:=TRUE;
                                menur.gcol[ord(c)-48]:=b;
                              end;
                        end;
                    end;
                  until ((not (c in ['C','S','1'..'3'])) or (hangup));
                  c:=#0;
                end;
            '9':begin
                  nl;
                  print('(C)lear screen before menu  -  (D)on''t center the menu titles');
                  print('(N)o menu prompt displayed  -  (P)Force pause before menu display');
                  print('(T)Auto-time display');
                  nl;
                  prt('Choose : '); onek(c,'QCDNPT'^M);
                  bb:=menuchanged; menuchanged:=TRUE;
                  with menur do
                    case c of
                      'C':if (clrscrbefore in menuflags) then
                            menuflags:=menuflags-[clrscrbefore]
                       else menuflags:=menuflags+[clrscrbefore];
                      'D':if (dontcenter in menuflags) then
                            menuflags:=menuflags-[dontcenter]
                       else menuflags:=menuflags+[dontcenter];
                      'N':if (nomenuprompt in menuflags) then
                            menuflags:=menuflags-[nomenuprompt]
                       else menuflags:=menuflags+[nomenuprompt];
                      'P':if (forcepause in menuflags) then
                            menuflags:=menuflags-[forcepause]
                       else menuflags:=menuflags+[forcepause];
                      'T':if (autotime in menuflags) then
                            menuflags:=menuflags-[autotime]
                       else menuflags:=menuflags+[autotime];
                    else
                          menuchanged:=bb;
                    end;
                  c:=#0;
                end;
          end;
        until ((c='Q') or (hangup));
        if (menuchanged) then begin
          sprint('Saving menu.......');
          mes;
        end;
      end;
    end;
  end;

begin
  nocsave:=noc;
  noc:=0;

  repeat
    abort:=FALSE;
    if (c<>'?') then begin
      cls;
      sprint(#3#3+'TeleGard-X Menu Editor');
      nl;
      dir(systat.menupath,'*.mnu',FALSE);
    end;
    nl;
    prt('Menu editor (?=help) : ');
    onek(c,'QDIM?'^M);
    case c of
      '?':begin
            nl;
            print('<CR>Redisplay screen');
            lcmds(17,3,'Delete menu file','Insert menu file');
            lcmds(17,3,'Modify menu file','Quit and save');
          end;
      'D':med;
      'I':mei;
      'M':mem;
    end;
  until (c='Q') or (hangup);

  noc:=nocsave;
end;

end.
