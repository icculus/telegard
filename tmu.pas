program TelegardMasterUtility;

{$M 35000,0,1000}

uses myio,
     {rcg11172000 no turbo3 under linux.}
     {crt, dos, turbo3;}
     crt, dos;

{$I rcc17a.pas}
{$I rec17b.pas}

type
  menu_string_record=array[0..20] of string;

const
  tmu_ver='1.0';
  menu_main:
  menu_string_record=
    ('Main Menu',
     'Fix utilities',
     'Color-filter editor',
     'Initialization / Partial re-initalization',
     '','','','','','','','','','',
     '','','','','','','');

var doswindow:windowrec;
    dosx,dosy:integer;
    nummenusel:integer;

procedure init1;
begin
  infield_out_fgrd:=15;
  infield_out_bkgd:=1;
  infield_inp_fgrd:=0;
  infield_inp_bkgd:=7;
  infield_arrow_exit:=FALSE;

  dosx:=wherex; dosy:=wherey;
  checkvidseg;
  cursoron(FALSE);
  savescreen(doswindow,1,1,80,25);
  clrscr;
end;

procedure exite(i:integer);
begin
  clrscr;
  removewindow(doswindow);
  gotoxy(dosx,dosy);
  cursoron(TRUE);
  halt(i);
end;

procedure drawtl;
begin
  cwritecentered(1,#3#15+'T'+#3#14+'elegard '+
                   #3#15+'M'+#3#14+'aster '+
                   #3#15+'U'+#3#14+'tility '+
                   #3#11+'v'+tmu_ver+' '+
                   #3#14+'for Telegard '+
                   #3#11+'v'+s_ver);
end;

procedure mtitle(s:string);
begin
  cwritecentered(3,#3#9+'-------®®®®®<'+
                   #3#15+#2#1+' '+s+' '+
                   #3#9+#2#0+'>¯¯¯¯¯-------');
end;

procedure mfunc(y:integer; c:char; s:string);
begin
  cwriteat(20,y,#3#15+c+#3#9+' - '+#3#11+s);
end;

procedure show_menu(m:menu_string_record);
begin
  clrscr;
  drawtl;
  mtitle(m[0]);

  nummenusel:=1;
  repeat
    cwriteat(20,6+nummenusel,#3#14+m[nummenusel]);
    inc(nummenusel);
  until ((nummenusel>20) or (m[nummenusel]=''));
  dec(nummenusel);
end;

var c:char;
begin
  init1;

  menu_current:=main_menu;

  show_menu(menu_main);



  c:=readkey;

  exite(0);
end.
