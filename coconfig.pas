program coconfig;

{$M 35000,0,1000}

uses myio,
     {rcg11172000 hhmm...what's turbo3 do?}
     {crt, dos, turbo3;}
     crt, dos;

{$I func.pas}

type cfilterrec=array[0..255] of byte;
     colorset=set of #0..#255;

var cfilterf:file of cfilterrec;
    cfilter:cfilterrec;
    cfilter_name:string;
    changed:boolean;

const CURSOR_COLOR = 15;
      default_cfilter:cfilterrec=
        (9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
         9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
         9,9,11,9,9,9,9,11,11,11,9,9,9,9,9,9,
         14,14,14,14,14,14,14,14,14,14,11,11,11,9,11,11,
         9,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,
         11,11,11,11,11,11,11,11,11,11,11,11,11,11,9,9,
         11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,
         11,11,11,11,11,11,11,11,11,11,11,11,11,11,9,9,
         9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
         9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
         9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
         9,9,9,13,13,13,13,13,13,13,13,13,13,13,13,13,
         13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,
         13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,
         9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
         9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9);


{rcg11172000 added by me.}
procedure CursorOn(flag:boolean);
begin
  writeln('STUB: bb.pas; CursorOn()...');
end;
{rcg11172000 adds end.}


procedure textset(f,b:byte);
begin
  textcolor(f);
  textbackground(b);
end;

function cstr(i:longint):string;
var c:string;
begin
  str(i,c);
  cstr:=c;
end;

function mln(s:string; len:integer):string;
begin
  while (length(s)<len) do s:=s+' ';
  mln:=s;
end;

function getscreen(x,y,z:byte):byte;
begin
  {rcg11172000 doesn't fly under Linux.}
  {getscreen:=mem[vidseg:(160*(y-1)+2*(x-1))+z];}
  writeln('STUB: coconfig.pas; getscreen()...');
  getscreen:=0;
end;

procedure putscreen(x,y,c,col:byte);
begin
  {rcg11172000 doesn't fly under Linux.}
  {
  mem[vidseg:(160*(y-1)+2*(x-1))]:=c;
  mem[vidseg:(160*(y-1)+2*(x-1))+1]:=col;
  }
  writeln('STUB: coconfig.pas; putscreen()...');
end;

procedure updateeditingline;
begin
  textset(0,7); gotoxy(34,13);
  if (cfilter_name<>'') then
    write('Editing "'+cfilter_name+'"')
  else
    write('New file');
  if (changed) then cwrite(#3#16+' * ');
  textset(7,0);
end;

procedure initchrsettings;
var i,x,y:integer;
begin
  textset(0,7); box(8,32,1,67,14); window(1,1,80,25);

  cwriteat(32,6,'Ã');
  textset(7,0); for i:=1 to 34 do write('Ä');
  textset(0,7); write('´');

  cwriteat(32,12,'Æ');
  for i:=1 to 34 do write('Í');
  write('µ');

  gotoxy(33,13); for i:=1 to 34 do write(' ');
  updateeditingline;

  cwriteat(40,1,#3#15+#2#1+' Character Settings ');

  i:=32;
  for y:=3 to 10 do begin
    if (y=6) then inc(y);
    for x:=34 to 65 do begin
      putscreen(x,y,i,7);
      inc(i);
    end;
  end;
end;

procedure updatechrsettings(uset:colorset; col:integer);
var i,x,y:integer;
begin
  i:=32;
  for y:=3 to 10 do begin
    if (y=6) then inc(y);
    for x:=34 to 65 do begin
      if (chr(i) in uset) then
        if (col=-1) then
          putscreen(x,y,i,cfilter[i])
        else
          putscreen(x,y,i,col);
      inc(i);
    end;
  end;
end;

procedure docolortable(editset:colorset; cx,cy:integer; var feedback:char);
var ctwind,undercursor:windowrec;
    curb,curf,oldb,oldf,i:integer;
    c:char;
    col,oldcol,bb:byte;
    abort,done:boolean;

  procedure putwithbg(x,y,col:byte; c:char);
  var oldattr:byte;
  begin
    putscreen(x,y,ord(c),(getscreen(x,y,1) and 240)+col);
  end;

  procedure putcursor;
  begin
    savescreen(undercursor,cx+curb*3+1,cy+curf+1,cx+curb*3+5,cy+curf+3);
    putwithbg(cx+curb*3+1, cy+curf+1, CURSOR_COLOR, 'Ú');
    putwithbg(cx+curb*3+2, cy+curf+1, CURSOR_COLOR, 'Ä');
    putwithbg(cx+curb*3+3, cy+curf+1, CURSOR_COLOR, 'Ä');
    putwithbg(cx+curb*3+4, cy+curf+1, CURSOR_COLOR, 'Ä');
    putwithbg(cx+curb*3+5, cy+curf+1, CURSOR_COLOR, '¿');
    putwithbg(cx+curb*3+1, cy+curf+2, CURSOR_COLOR, '³');
    putwithbg(cx+curb*3+5, cy+curf+2, CURSOR_COLOR, '³');
    putwithbg(cx+curb*3+1, cy+curf+3, CURSOR_COLOR, 'À');
    putwithbg(cx+curb*3+2, cy+curf+3, CURSOR_COLOR, 'Ä');
    putwithbg(cx+curb*3+3, cy+curf+3, CURSOR_COLOR, 'Ä');
    putwithbg(cx+curb*3+4, cy+curf+3, CURSOR_COLOR, 'Ä');
    putwithbg(cx+curb*3+5, cy+curf+3, CURSOR_COLOR, 'Ù');
    oldb:=curb; oldf:=curf;
  end;

  procedure delcursor;
  begin
    removewindow1(undercursor);
  end;

  procedure setupcolortable;
  var x,y:integer;
  begin
    setwindow(ctwind,cx,cy,cx+27,cy+19,0,7,8);
    window(cx+2,cy+2,cx+25,cy+18);

    gotoxy(1,1);
    for y:=0 to 15 do begin
      textcolor(y);
      for x:=0 to 7 do begin
        textbackground(x);
        write(' x ');
      end;
    end;
    window(cx,cy,cx+27,cy+19);

    cwriteat(6,1,#3#15+#2#1+' Color Selection: ');

    window(1,1,80,25);

    cwriteat(34,22,#3#14+#2#0+'Í¾: '+#3#11+'Save color selection');
    cwriteat(34,23,#3#14+#2#0+'ESC: '+#3#11+'Abort');

    curb:=(col and 112) shr 4; curf:=col and 15;
    putcursor;
  end;

begin
  i:=32;
  while (i<=255) do begin
    if (chr(i) in editset) then begin
      col:=cfilter[i];
      i:=255;
    end;
    inc(i);
  end;
  oldcol:=col;

  setupcolortable;

  abort:=FALSE; done:=FALSE;
  while (not done) do begin
    c:=upcase(readkey);
    case ord(c) of
      0:case ord(readkey) of
          ARROW_HOME :curb:=0;
          ARROW_UP   :if (curf>0) then dec(curf);
          ARROW_PGUP :curf:=0;
          ARROW_LEFT :if (curb>0) then dec(curb);
          ARROW_RIGHT:if (curb<7) then inc(curb);
          ARROW_END  :curb:=7;
          ARROW_DOWN :if (curf<15) then inc(curf);
          ARROW_PGDN :curf:=15;
        end;
     13:done:=TRUE;
     27:begin abort:=TRUE; done:=TRUE; end;
     49..56,67:begin feedback:=c; abort:=TRUE; done:=TRUE; end;
    end;
    if ((curf<>oldf) or (curb<>oldb)) then begin
      delcursor;
      putcursor;
      col:=(curb shl 4)+curf;
      updatechrsettings(editset,col);
    end;
  end;

  if (not abort) then begin
    if (not changed) then begin
      changed:=TRUE;
      updateeditingline;
    end;
    i:=32;
    while (i<=255) do begin
      if (chr(i) in editset) then cfilter[i]:=col;
      inc(i);
    end;
  end else
    updatechrsettings(editset,-1);

  gotoxy(34,22); clreol; gotoxy(34,23); clreol;
  removewindow1(ctwind);
end;

function allcaps(s:string):string;
var i:integer;
begin
  for i:=1 to length(s) do s[i]:=upcase(s[i]);
  allcaps:=s;
end;

procedure getsetchr(var sc:char; var cx,cy:byte);
var ox,oy:byte;
    c:char;
    done:boolean;

  procedure revcursor(x,y:byte);
  begin
    putscreen(x,y,getscreen(x,y,0),255-getscreen(x,y,1));
  end;

begin
  ox:=cx; oy:=cy;

  revcursor(cx,cy);

  done:=FALSE;
  while (not done) do begin
    c:=upcase(readkey);
    case ord(c) of
      0:case ord(readkey) of
          ARROW_HOME :cx:=34;
          ARROW_UP   :if (cy>3) then begin dec(cy); if (cy=6) then cy:=5; end;
          ARROW_PGUP :cy:=3;
          ARROW_LEFT :if (cx>34) then dec(cx);
          ARROW_RIGHT:if (cx<65) then inc(cx);
          ARROW_END  :cx:=65;
          ARROW_DOWN :if (cy<10) then begin inc(cy); if (cy=6) then cy:=7; end;
          ARROW_PGDN :cy:=10;
        end;
     13:begin
          sc:=chr(getscreen(cx,cy,0));
          done:=TRUE;
        end;
     27:done:=TRUE;
    end;
    if ((cx<>ox) or (cy<>oy)) then begin
      revcursor(ox,oy);
      ox:=cx; oy:=cy;
      revcursor(cx,cy);
    end;
  end;
  revcursor(cx,cy);
end;

function ritr(c:char; len:integer):string;
var s:string;
    i:integer;
begin
  s:='';
  for i:=1 to len do s:=s+c;
  ritr:=s;
end;

procedure docwindow(var wind:windowrec; y:integer; s:string);
var xx,x1,y1,x2,y2:integer;
    sx,sy,sz:byte;
begin
  sx:=wherex; sy:=wherey; sz:=textattr;
  x1:=36-(length(s) div 2); y1:=y;
  x2:=x1+length(s)+8; y2:=y+4;
  xx:=length(s);
  savescreen(wind,x1,y1,x2,y2);
  cwriteat(x1,y1,   #3#4+#2#0+'ÜÜÜÜ'+ritr('Ü',xx)+'ÜÜÜÜ');
  cwriteat(x1,y1+1,#3#14+#2#4+' Ûßß'+ritr('ß',xx)+'ßßÛ ');
  cwriteat(x1,y1+2,#3#14+#2#4+' Û  '+s+'  Û ');
  cwriteat(x1,y1+3,#3#14+#2#4+' ÛÜÜ'+ritr('Ü',xx)+'ÜÜÛ ');
  cwriteat(x1,y1+4,#3#4+#2#0+ 'ßßßß'+ritr('ß',xx)+'ßßßß');
  gotoxy(sx,sy); textattr:=sz;
end;

var newf,oldf:file;
    buff:array[1..16384] of byte;

procedure killoldcode(fname:string);
var tempwind:windowrec;
    fspecpath,s1:dirstr;
    fspecname,s2:namestr;
    s3:extstr;
    j:longint;
    numread:word;
    bb:byte;
begin
  docwindow(tempwind,10,fname+': Removing old filter.');
  fsplit(fname,s1,s2,s3);
  assign(newf,s1+s2+'.$$$');
  {$I-} rewrite(newf,1); {$I+}
  if (ioresult<>0) then begin
    removewindow1(tempwind);
    docwindow(tempwind,10,s1+s2+'.$$$: Unable to create.');
    delay(1000);
    removewindow1(tempwind);
    close(oldf);
  end else begin
    seek(oldf,0); blockread(oldf,bb,1,numread); blockread(oldf,bb,1,numread);
    repeat blockread(oldf,bb,1,numread) until ((chr(bb)=';') or (eof(oldf)));
    if (not eof(oldf)) then
      repeat
        blockread(oldf,buff,16384,numread);
        blockwrite(newf,buff,numread);
      until (numread<16384);
    close(oldf); close(newf);
    erase(oldf); rename(newf,fname);
    assign(oldf,fname); reset(oldf);
    removewindow1(tempwind);
  end;
end;

function addthefilter(fname:string; cfiltername:string):boolean;
var tempwind:windowrec;
    cfcode:string;
    fspecpath,s1:dirstr;
    fspecname,s2:namestr;
    s3:extstr;
    numread:word;
    j:integer;
begin
  addthefilter:=TRUE;
  cfcode:=^T+'c'+cfiltername+';';
  assign(oldf,fname);
  {$I-} reset(oldf,1); {$I+}
  if (ioresult<>0) then begin
    docwindow(tempwind,10,fname+': Unable to open.');
    delay(1000);
    removewindow1(tempwind);
    addthefilter:=FALSE;
  end else begin
    seek(oldf,0); blockread(oldf,buff,2,numread);
    if ((chr(buff[1])=^T) and (chr(buff[2])='c')) then killoldcode(fname);
    fsplit(fname,s1,s2,s3);
    assign(newf,s1+s2+'.$$$');
    {$I-} rewrite(newf,1); {$I+}
    if (ioresult<>0) then begin
      docwindow(tempwind,10,s1+s2+'.$$$: Unable to create.');
      delay(1000);
      removewindow1(tempwind);
      close(oldf);
      addthefilter:=FALSE;
    end else begin
      for j:=1 to length(cfcode) do buff[j]:=ord(cfcode[j]);
      blockwrite(newf,buff,length(cfcode));
      reset(oldf,1);
      repeat
        blockread(oldf,buff,16384,numread);
        blockwrite(newf,buff,numread);
      until (numread<16384);
      close(oldf); close(newf);
      erase(oldf); rename(newf,fname);
    end;
  end;
end;

procedure addfilters;
var oldf,newf:file;
    savescr,tempwind:windowrec;
    dirinfo:searchrec;
    fs:array[1..110] of string[12];
    tagstat:array[1..110] of boolean;
    fspecpath,s1:dirstr;
    fspecname,s2:namestr;
    s3:extstr;
    fspec,fname,cfname,cfcode:string;
    numread:word;
    numfs,i,cx,cy,ci,ox,oy,oi:integer;
    c:char;
    bb:byte;
    abort,done,noneyet:boolean;

  function cxp1(i:integer):byte;
  begin
    cxp1:=((i-1) mod 5)+1;
  end;

  function cxp(i:integer):byte;
  begin
    cxp:=16*(cxp1(i)-1)+2;
  end;

  function cyp(i:integer):byte;
  begin
    cyp:=((i-1) div 5)+1;
  end;

  procedure putcursor;
  var i,x,y:integer;
  begin
    x:=cxp(oi); y:=cyp(oi);
    for i:=x to x+13 do putscreen(i,y,getscreen(i,y,0),30);
  end;

  procedure delcursor;
  var i,x,y:integer;
  begin
    x:=cxp(oi); y:=cyp(oi);
    for i:=x to x+13 do putscreen(i,y,getscreen(i,y,0),14);
  end;

  procedure tagit(i:integer);
  begin
    tagstat[i]:=not tagstat[i];
    if (tagstat[i]) then
      putscreen(cxp(i)-1,cyp(i),ord('*'),10)
    else
      putscreen(cxp(i)-1,cyp(i),ord(' '),10);
  end;

  procedure doaddfilters;
  var j:longint;
      i,savci:integer;
  begin
    delcursor; savci:=ci;

    fsplit(cfilter_name,s1,s2,s3); cfname:=s2+s3;

    setwindow(tempwind,11,9,67,14,9,1,8); textset(9,1); clrscr;
    window(1,1,80,25);
    cwriteat(14,11,#3#11+#2#1+'Color filter filename:');
    cwriteat(14,12,#3#9+#2#1+':');
    cursoron(TRUE); infield1(15,12,cfname,50); cursoron(FALSE);
    removewindow1(tempwind);

    if (cfname<>'') then begin
      cfcode:=^T+'c'+cfname+';';
      for i:=1 to numfs do
        if (tagstat[i]) then begin
          oi:=i; putcursor;
          if (addthefilter(fspecpath+fs[i],cfname)) then tagit(i);
          delcursor;
        end;
    end;
    ci:=savci; oi:=ci;
    putcursor;
  end;

begin
  setwindow(savescr,1,1,80,25,14,0,0); clrscr;

  cursoron(TRUE);
  textcolor(11); writeln('  Enter filespec to edit:');
  textcolor(9); write('  :');
  fspec:='*.MSG';
  infield1(wherex,wherey,fspec,76); fspec:=fexpand(allcaps(fspec));
  fsplit(fspec,fspecpath,fspecname,s3);
  cursoron(FALSE);
  if (fspec='') then exit;
  clrscr;

  findfirst(fspec,anyfile-directory,dirinfo);
  if (doserror<>0) then begin
    docwindow(tempwind,10,'No files found.');
    delay(1000);
    removewindow1(tempwind);
  end else begin
    ci:=1;
    while ((ci<=110) and (doserror=0)) do begin
      fs[ci]:=dirinfo.name; tagstat[ci]:=FALSE;
      findnext(dirinfo);
      inc(ci);
    end;
    numfs:=ci-1;
    textcolor(14);
    for ci:=1 to numfs do
      cwriteat(cxp(ci),cyp(ci),mln(fs[ci],12));

    cwriteat(1,25,#3#14+'SPACE: '+#3#11+'Tag files   '+
                  #3#14+'A: '+#3#11+'Tag all   '+
                  #3#14+'Í¾: '+#3#11+'Go!   '+
                  #3#14+'ESC: '+#3#11+'Done');

    ci:=1; oi:=1; putcursor;

    abort:=FALSE; done:=FALSE;
    while (not done) do begin
      c:=upcase(readkey);
      case ord(c) of
        0:case ord(readkey) of
            ARROW_HOME :ci:=(cyp(ci)-1)*5+1;
            ARROW_UP   :dec(ci,5);
            ARROW_PGUP :ci:=cxp1(ci);
            ARROW_LEFT :dec(ci);
            ARROW_RIGHT:inc(ci);
            ARROW_END  :ci:=(cyp(ci)-1)*5+5;
            ARROW_DOWN :inc(ci,5);
            ARROW_PGDN :begin
                          ci:=(cyp(numfs)-1)*5+cxp1(ci);
                          if (ci>numfs) then dec(ci,5);
                        end;
          end;
       13:begin
            noneyet:=TRUE;
            for i:=1 to numfs do
              if (tagstat[i]) then noneyet:=FALSE;
            if (noneyet) then tagit(ci);
            doaddfilters;
          end;
       27:begin abort:=TRUE; done:=TRUE; end;
       32:begin tagit(ci); inc(ci); end;
       65:for i:=1 to numfs do tagit(i);
      end;
      if (ci<>oi) then begin
        if (ci<1) then ci:=1;
        if (ci>numfs) then ci:=numfs;
        delcursor; oi:=ci; putcursor;
      end;
    end;
    delcursor;
  end;

  removewindow1(savescr);
end;

var doswindow,askwindow:windowrec;
    allset,set1,set2,set3,set4,set5,set6,set7,set8:colorset;
    editset:colorset;
    dirinfo:searchrec;
    setname:string;
    dosx,dosy,i,j,k:integer;
    c,feedback,setc1,setc2:char;
    sx,sy:byte;
    done,isnew:boolean;

procedure definesets;
begin
  set1:=['A'..'Z'];
  set2:=['a'..'z','"','''',':',';','?','\','`','|'];
  set3:=['0'..'9'];
  set4:=[#179..#223];
  set5:=[#176..#178];
{ set6:= }
  set7:=['(',')','<','>','[',']','{','}'];
  set8:=['!','#','$','%','&','*','@','^'];

  allset:=[#0..#255];
  set6:=allset-set1-set2-set3-set4-set5-set7-set8;
end;

procedure exite(i:integer);
begin
  clrscr;
  removewindow1(doswindow);
  gotoxy(dosx,dosy);
  cursoron(TRUE);
  halt(i);
end;

procedure savecfilter;
var tempwind:windowrec;
begin
  if (cfilter_name='') then begin
    setwindow(tempwind,11,9,67,14,9,1,8); textset(9,1); clrscr;
    window(1,1,80,25);
    cwriteat(14,11,#3#11+#2#1+'Save color filter as:');
    cwriteat(14,12,#3#9+#2#1+':');
    cursoron(TRUE); infield1(15,12,cfilter_name,50); cursoron(FALSE);
    removewindow1(tempwind);
  end;
  if (cfilter_name<>'') then begin
    assign(cfilterf,cfilter_name);
    {$I-} rewrite(cfilterf); {$I+}
    if (ioresult<>0) then begin
      docwindow(tempwind,10,cfilter_name+': Unable to create.');
      delay(1000);
      removewindow1(tempwind);
    end else begin
      {$I-} write(cfilterf,cfilter); {$I+}
      if (ioresult<>0) then begin
        docwindow(tempwind,10,cfilter_name+': Unable to write color filter.');
        delay(1000);
        removewindow1(tempwind);
      end else begin
        changed:=FALSE;
        updateeditingline;
        updatechrsettings(allset,-1);
      end;
      close(cfilterf);
    end;
  end;
end;

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

  if ((paramcount>0) and (paramstr(1)<>'')) then
    cfilter_name:=paramstr(1)
  else
    cfilter_name:='';
(*  begin
    cursoron(TRUE);
    textcolor(11); writeln('Enter color configuration filename');
    textcolor(9); write(':');
    infield(cfilter_name,78); cfilter_name:=allcaps(cfilter_name);
    cursoron(FALSE);
    clrscr;
  end;*)

  if (paramcount>1) then begin
    writeln;
    cwrite(#3#9+'þ '+#3#11+'Color filter name: "'+cfilter_name+'"');
    writeln; writeln;
    j:=0;
    for i:=2 to paramcount do begin
      findfirst(paramstr(i),anyfile-directory,dirinfo);
      while (doserror=0) do begin
        cwrite(#3#9+'þ '+#3#11+dirinfo.name+#3#9+' - '+#3#11);
        if (addthefilter(dirinfo.name,cfilter_name)) then begin
          cwrite('Done.');
          inc(j);
        end else
          cwrite('Unable to add color filter!'^G^G);
        writeln;
        findnext(dirinfo);
      end;
    end;
    writeln;
    cwrite(#3#9+'þ '+#3#11+'Added color filter to '+#3#15+cstr(j)+#3#11+' file');
    if (j<>1) then cwrite('s');
    cwrite('.');
    writeln;
    delay(3000);
    exite(0);
  end;

  isnew:=FALSE;
  if (cfilter_name<>'') then begin
    assign(cfilterf,cfilter_name);
    {$I-} reset(cfilterf); {$I+}
    if (ioresult=0) then begin
      {$I-} read(cfilterf,cfilter); {$I+}
      if (ioresult<>0) then begin end;
      close(cfilterf);
    end else
      isnew:=TRUE;
  end else
    isnew:=TRUE;

  if (isnew) then begin
    cfilter:=default_cfilter;
{    cwriteat(1,1,#3#12+'ÄÄ '+#3#14+'NEW FILE'+#3#12+' ÄÄ');
    delay(1000);}
    clrscr;
  end;

  changed:=FALSE;
  definesets;
  initchrsettings;
  updatechrsettings(allset,-1);

  cwriteat(34,16,#2#0+#3#14+'1-8: '+#3#11+'Edit pre-defined set');
  cwriteat(34,17,#2#0+#3#14+'  A: '+#3#11+'Add filter to text files');
  cwriteat(34,18,#2#0+#3#14+'  C: '+#3#11+'Edit character range');
{  cwriteat(34,19,#2#0+#3#14+'  L: '+#3#11+'Load new color filter');}
  cwriteat(34,19,#2#0+#3#14+'  S: '+#3#11+'Save color filter');
  cwriteat(34,20,#2#0+#3#14+'  Q: '+#3#11+'Quit & Save');

  changed:=FALSE; done:=FALSE;
  feedback:=#0;
  while (not done) do begin
    if (feedback<>#0) then begin
      c:=feedback;
      feedback:=#0;
    end else
      c:=readkey;
    case upcase(c) of
      '1'..'8':
          begin
            case c of
              '1':begin editset:=set1; setname:='Upper-case letters'; end;
              '2':begin editset:=set2; setname:='Lower-case letters'; end;
              '3':begin editset:=set3; setname:='Number chrs'; end;
              '4':begin editset:=set4; setname:='Line-drawing chrs'; end;
              '5':begin editset:=set5; setname:='Graphic chrs'; end;
              '6':begin editset:=set6; setname:='Other chrs'; end;
              '7':begin editset:=set7; setname:='Bracket chrs'; end;
              '8':begin editset:=set8; setname:='Special chrs'; end;
            end;

            cwriteat(2,22,#3#14+'Editing pre-defined set #'+c);
            cwriteat(4,23,#3#14+'"'+setname+'"');

            docolortable(editset,1,1,feedback);

            gotoxy(1,22); clreol; gotoxy(1,23); clreol;
          end;
      'A':addfilters;
      'C':begin
            cwriteat(34,22,#3#14+'Select set starting character, and hit Í¾.');
            setc1:=#0; sx:=34; sy:=3;
            getsetchr(setc1,sx,sy);
            gotoxy(34,22); clreol;
            if (setc1<>#0) then begin
              cwriteat(34,22,#3#14+'Select set ending character, and hit Í¾.');
              setc2:=#0;
              getsetchr(setc2,sx,sy);
              gotoxy(34,22); clreol;
              if (setc2<>#0) then begin
                editset:=[];
                for c:=setc1 to setc2 do editset:=editset+[c];
                cwriteat(2,22,#3#14+'Editing user-defined set,');
                cwriteat(2,23,#3#14+'Chrs "'+setc1+'".."'+setc2+
                        '" ('+cstr(ord(setc1))+'..'+cstr(ord(setc2))+')');

                docolortable(editset,1,1,feedback);

                gotoxy(1,22); clreol; gotoxy(1,23); clreol;
              end;
            end;
          end;
      'S':savecfilter;
      'Q':done:=TRUE;
    end;
  end;

  gotoxy(34,16); clreol; gotoxy(34,17); clreol; gotoxy(34,18); clreol;
  gotoxy(34,19); clreol; gotoxy(34,20); clreol;

  if (changed) then begin
    docwindow(askwindow,15,'Save? (Y/n)');
    repeat c:=upcase(readkey) until (c in ['Y','N',^M]);
    removewindow1(askwindow);
    changed:=(c<>'N');
    if (changed) then savecfilter;
  end;

  exite(0);
end.
