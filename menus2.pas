(*****************************************************************************)
(*>                                                                         <*)
(*>  MENUS2  .PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  Other menu functions - generic, list, etc.                             <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit menus2;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  file4,
  common;

procedure readin;
procedure showcmds(listtype:integer);
function oksecurity(i:integer; var cmdnothid:boolean):boolean;
procedure genericmenu(t:integer);
procedure showthismenu;

implementation

procedure readin;
var filv:text;
    s,lcmdlistentry:astr;
    i,j:integer;
    b:boolean;
begin
  cmdlist:='';
  noc:=0;
  assign(filv,curmenu);
  {$I-} reset(filv); {$I-}
  if (ioresult<>0) then begin
    sysoplog('"'+curmenu+'" is MISSING.');
    print('"'+curmenu+'" is MISSING.  Please inform SysOp.');
    print('Dropping back to fallback menu...');
    curmenu:=systat.menupath+menur.fallback+'.mnu';
    assign(filv,curmenu);
    {$I-} reset(filv); {$I-}
    if (ioresult<>0) then begin
      sysoplog('"'+curmenu+'" is MISSING - Hung user up.');
      print('Fallback menu is *also* MISSING.  Please inform SysOp.');
      nl;
      print('Critical error; hanging up.');
      hangup:=TRUE;
    end;
  end;

  if (not hangup) then begin
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

    mqarea:=FALSE; fqarea:=FALSE;
    lcmdlistentry:=''; j:=0;
    for i:=1 to noc do begin
      if (cmdr[i].ckeys<>lcmdlistentry) then begin
        b:=(aacs(cmdr[i].acs));
        if (b) then inc(j);
(*
        if (b) and (j<>1) then cmdlist:=cmdlist+',';
        if (b) then cmdlist:=cmdlist+cmdr[i].ckeys;
*)
        if (b) then begin
          if ((cmdr[i].ckeys<>'FIRSTCMD') and (cmdr[i].ckeys<>'GTITLE')) then begin
            if (j<>1) then cmdlist:=cmdlist+',';
            cmdlist:=cmdlist+cmdr[i].ckeys;
          end else dec(j);
        end;
        lcmdlistentry:=cmdr[i].ckeys;
      end;
      if (cmdr[i].cmdkeys='M#') then mqarea:=TRUE;
      if (cmdr[i].cmdkeys='F#') then fqarea:=TRUE;
    end;
  end;
end;

procedure showcmds(listtype:integer);
var i,j,numrows:integer;
    s,s1:astr;
    abort,next:boolean;

  function type1(i:integer):astr;
  begin
    type1:=mn(i,3)+mlnnomci(cmdr[i].ckeys,3)+mlnnomci(cmdr[i].cmdkeys,4)+
           mlnnomci(cmdr[i].mstring,15);
  end;

  function sfl(b:boolean; c:char):char;
  begin
    if (b) then sfl:=c else sfl:='-';
  end;

begin
  abort:=FALSE; next:=FALSE;
  if (noc<>0) then begin
    case listtype of
      0:begin
          printacr(#3#0+'NN'+sepr2+'Command       '+sepr2+'Fl'+sepr2+
                   'ACS      '+sepr2+'Cmd'+sepr2+'MString',abort,next);
          printacr(#3#4+'==:==============:==:==========:==:========================================',abort,next);
          i:=1;
          while (i<=noc) and (not abort) and (not hangup) do begin
            printacr(#3#0+mn(i,2)+' '+#3#3+mlnnomci(cmdr[i].ckeys,14)+' '+
                     sfl(hidden in cmdr[i].commandflags,'H')+
                     sfl(unhidden in cmdr[i].commandflags,'U')+' '+
                     #3#9+mlnnomci(cmdr[i].acs,10)+' '+
                     #3#3+mlnnomci(cmdr[i].cmdkeys,2)+' '+
                     cmdr[i].mstring,abort,next);
            inc(i);
          end;
        end;
      1:begin
          numrows:=(noc+2) div 3;
          i:=1;
          s:=#3#3+'NN:KK-Typ-MString        ';
          s1:=#3#4+'==:======================';
          while (i<=numrows) and (i<3) do begin
            s:=s+' NN:KK-Typ-MString        ';
            s1:=s1+' ==:======================';
            inc(i);
          end;
          printacr(s,abort,next);
          printacr(s1,abort,next);
          i:=0;
          repeat
            inc(i);
            s:=type1(i);
            for j:=1 to 2 do
              if i+(j*numrows)<=noc then
                s:=s+' '+type1(i+(j*numrows));
            printacr(#3#1+s,abort,next);
          until ((i>=numrows) or (abort) or (hangup));
        end;
    end;
  end
  else print('**No Commands on this menu**');
end;

function oksecurity(i:integer; var cmdnothid:boolean):boolean;
begin
  oksecurity:=FALSE;
  if (unhidden in cmdr[i].commandflags) then cmdnothid:=TRUE;
  if (not aacs(cmdr[i].acs)) then exit;
  oksecurity:=TRUE;
end;

procedure genericmenu(t:integer);
var glin:array [1..maxmenucmds] of astr;
    s,s1:astr;
    gcolors:array [1..3] of byte;
    onlin,i,j,colsiz,numcols,numglin,maxright:integer;
    abort,next,b,cmdnothid:boolean;

  function gencolored(keys,desc:astr; acc:boolean):astr;
  begin
    s:=desc;
    j:=pos(allcaps(keys),allcaps(desc));
    if (j<>0) and (pos(#3,desc)=0) then begin
      insert(#3+chr(gcolors[3]),desc,j+length(keys)+1);
      insert(#3+chr(gcolors[1]),desc,j+length(keys));
      if (acc) then insert(#3+chr(gcolors[2]),desc,j);
      if (j<>1) then
        insert(#3+chr(gcolors[1]),desc,j-1);
    end;
    gencolored:=#3+chr(gcolors[3])+desc;
  end;

  function semicmd(s:string; x:integer):string;
  var i,p:integer;
  begin
    i:=1;
    while (i<x) and (s<>'') do begin
      p:=pos(';',s);
      if (p<>0) then s:=copy(s,p+1,length(s)-p) else s:='';
      inc(i);
    end;
    while (pos(';',s)<>0) do s:=copy(s,1,pos(';',s)-1);
    semicmd:=s;
  end;

  procedure newgcolors(s:string);
  var s1:string;
  begin
    s1:=semicmd(s,1); if (s1<>'') then gcolors[1]:=value(s1);
    s1:=semicmd(s,2); if (s1<>'') then gcolors[2]:=value(s1);
    s1:=semicmd(s,3); if (s1<>'') then gcolors[3]:=value(s1);
  end;

  procedure gen_tuto;
  var i,j:integer;
      b:boolean;
  begin
    numglin:=0; maxright:=0; glin[1]:='';
    for i:=1 to noc do begin
      b:=oksecurity(i,cmdnothid);
      if (((b) or (unhidden in cmdr[i].commandflags)) and
          (not (hidden in cmdr[i].commandflags))) then
        if (cmdr[i].ckeys='GTITLE') then begin
          inc(numglin); glin[numglin]:=cmdr[i].ldesc;
          j:=lenn(glin[numglin]); if (j>maxright) then maxright:=j;
          if (cmdr[i].mstring<>'') then newgcolors(cmdr[i].mstring);
        end else
          if (cmdr[i].ldesc<>'') then begin
            inc(numglin);
            glin[numglin]:=gencolored(cmdr[i].ckeys,cmdr[i].ldesc,b);
            j:=lenn(glin[numglin]); if (j>maxright) then maxright:=j;
          end;
    end;
  end;

  procedure stripc(var s1:astr);
  var s:astr;
      i:integer;
  begin
    s:=''; i:=1;
    while (i<=length(s1)) do begin
      if (s1[i]=#3) then inc(i) else s:=s+s1[i];
      inc(i);
    end;
    s1:=s;
  end;

  procedure fixit(var s:astr; len:integer);
  var s1:astr;
  begin
    s1:=s;
    stripc(s1);
    if (length(s1)<len) then
      s:=s+copy('                                        ',1,len-length(s1))
    else
      if (length(s1)>len) then s:=s1;
  end;

  procedure gen_norm;
  var s1:astr;
      i,j:integer;
      b:boolean;
  begin
    s1:=''; onlin:=0; numglin:=1; maxright:=0; glin[1]:='';
    for i:=1 to noc do begin
      b:=oksecurity(i,cmdnothid);
      if (((b) or (unhidden in cmdr[i].commandflags)) and
          (not (hidden in cmdr[i].commandflags))) then begin
        if (cmdr[i].ckeys='GTITLE') then begin
          if (onlin<>0) then inc(numglin);
          glin[numglin]:=#2+cmdr[i].ldesc;
          inc(numglin); glin[numglin]:='';
          onlin:=0;
          if (cmdr[i].mstring<>'') then newgcolors(cmdr[i].mstring);
        end else begin
          if (cmdr[i].sdesc<>'') then begin
            inc(onlin); s1:=gencolored(cmdr[i].ckeys,cmdr[i].sdesc,b);
            if (onlin<>numcols) then fixit(s1,colsiz);
            glin[numglin]:=glin[numglin]+s1;
          end;
          if (onlin=numcols) then begin
            j:=lenn(glin[numglin]); if (j>maxright) then maxright:=j;
            inc(numglin); glin[numglin]:=''; onlin:=0;
          end;
        end;
      end;
    end;
    if (onlin=0) then dec(numglin);
  end;

  function tcentered(c:integer; s:astr):astr;
  const spacestr='                                               ';
  begin
    c:=(c div 2)-(lenn(s) div 2);
    if (c<1) then c:=0;
    tcentered:=copy(spacestr,1,c)+s;
  end;

  procedure dotitles;
  var i:integer;
      b:boolean;
  begin
    b:=FALSE;
    if (clrscrbefore in menur.menuflags) then begin
      cls;
      nl; nl;
    end;
    for i:=1 to 3 do
      if (menur.menuname[i]<>'') then begin
        if (not b) then begin nl; b:=TRUE; end;
        if (dontcenter in menur.menuflags) then
          printacr(menur.menuname[i],abort,next)
        else
          printacr(tcentered(maxright,menur.menuname[i]),abort,next);
      end;
    nl;
  end;

begin
  for i:=1 to 3 do gcolors[i]:=menur.gcol[i];
  numcols:=menur.gencols;
  case numcols of
    2:colsiz:=39; 3:colsiz:=25; 4:colsiz:=19;
    5:colsiz:=16; 6:colsiz:=12; 7:colsiz:=11;
  end;
  if (numcols*colsiz>=thisuser.linelen) then
    numcols:=thisuser.linelen div colsiz;
  abort:=FALSE; next:=FALSE;
  if (t=2) then gen_norm else gen_tuto;
  dotitles;
  for i:=1 to numglin do
    if (glin[i]<>'') then
      if (glin[i][1]<>#2) then
        printacr(glin[i],abort,next)
      else
        printacr(tcentered(maxright,copy(glin[i],2,length(glin[i])-1)),
                 abort,next);
end;

procedure showthismenu;
var s:astr;
begin
  case chelplevel of
    2:begin
        nofile:=TRUE; s:=menur.directive;
        if (s<>'') then begin
          if (pos('@S',s)<>0) then
            printf(substall(s,'@S',cstr(thisuser.sl)));
          if (nofile) then printf(substall(s,'@S',''));
        end;
      end;
    3:begin
        nofile:=TRUE; s:=menur.tutorial;
        if (s<>'') then begin
          if (pos('.',s)=0) then s:=s+'.tut';
          if (pos('@S',s)<>0) then
            printf(substall(s,'@S',cstr(thisuser.sl)));
          if (nofile) then printf(substall(s,'@S',''));
        end;
      end;
  end;
  if ((nofile) and (chelplevel in [2,3])) then genericmenu(chelplevel);
end;

end.
