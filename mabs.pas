uses dos,
     mdek,timejunk;

(*
    Execution method:
    MABS [site type] [[site info file] [serial number]]
*)

type infoheaderrec=array[1..6] of byte;

const infoheader:infoheaderrec=($FA,$CD,$20,$EF,$02,$AA);

var siteinfof:text;
    f:file;
    pdt:packdatetime;
    pstr:array[1..20] of string;
    s,siteinfofile,siteinfos,oversiteinfo:string;
    r:array[1..144] of byte;
    lng,serialnumber:longint;
    chk,chk1,chk2:word;
    res,i,pcount,wanttype:integer;
    c:char;
    vertypes:byte;
    b,notcoded:boolean;

function stripcolor(o:string):string;
var s:string;
    i:integer;
    lc:boolean;
begin
  s:=''; lc:=FALSE;
  for i:=1 to length(o) do
    if (lc) then lc:=FALSE
      else if ((o[i]=#3) or (o[i]='^')) then lc:=TRUE else s:=s+o[i];
  stripcolor:=s;
end;

procedure decryptinfo;
var s:string;
    i:integer;
begin
  for i:=13 to 142 do s[i-12]:=chr(r[i]); s[0]:=chr(132);
  s:=decrypt(s,r[7],r[8],r[9],r[10],r[11],r[12]);
  for i:=13 to 142 do r[i]:=ord(s[i-12]);
end;

procedure encryptinfo;
var s:string;
    i:integer;
begin
  for i:=13 to 142 do s[i-12]:=chr(r[i]); s[0]:=chr(132);
  s:=encrypt(s,r[7],r[8],r[9],r[10],r[11],r[12]);
  for i:=13 to 142 do r[i]:=ord(s[i-12]);
end;

procedure maketruerandom;
var dt:ldatetimerec;
    ll,ll2:longint;
begin
  getdatetime(dt);
  with dt do
    ll:=(year-1980)+month+day*hour*min*sec*sec100;
  randseed:=ll;
end;

function aonoff(b:boolean; s1,s2:string):string;
begin
  if (b) then aonoff:=s1 else aonoff:=s2;
end;

begin
  maketruerandom;

  siteinfofile:=''; oversiteinfo:='';
  wanttype:=-1; serialnumber:=0;

  pcount:=paramcount;
  for i:=1 to pcount do pstr[i]:=paramstr(i);

  {$IFDEF AS1}
    pstr[1]:='9'; pstr[2]:='***'; pstr[3]:='1'; pcount:=3;
    oversiteinfo:='Eric Oman'+^J+#3#7+'Grosse '+#3#0+'Pointe '+#3#4+'Centrale'+
                  ^J+#3#7+'313-'+#3#0+'885-'+#3#4+'1779'+^J;
  {$ELSE}
    {$IFDEF AS2}
      pstr[1]:='1'; pstr[2]:='***'; pstr[3]:='2'; pcount:=3;
      oversiteinfo:='Todd Bolitho'+^J+'Warp Speed BBS'+^J+'313-544-0405'+^J;
    {$ELSE}
      {$IFDEF AS3}
		pstr[1]:='1'; pstr[2]:='***'; pstr[3]:='3'; pcount:=3;
        oversiteinfo:='Martin Pollard'+^J+'The I/O Bus'+^J+'313-755-7786'+^J;
      {$ELSE}
        {$IFDEF AS4}
		  pstr[1]:='1'; pstr[2]:='***'; pstr[3]:='4'; pcount:=3;
          oversiteinfo:='John Dixon (Nikademus)'+^J+'The Ozone BBS'+^J+
                        '313-689-2876'+^J;
        {ELSE}
          {$IFDEF AS5}
            pstr[1]:='1'; pstr[2]:='***'; pstr[3]:='5'; pcount:=3;
            oversiteinfo:='Bill Schwartz'+^J+'Electric Eye II BBS'+^J+
                          '313-776-8928'+^J;
          {$ENDIF}
        {$ENDIF}
      {$ENDIF}
    {$ENDIF}
  {$ENDIF}

  if (pcount>=1) then begin
    val(pstr[1],wanttype,i);
    if (pcount>=2) then
      if (pstr[2]='***') then
        siteinfofile:='***'
      else begin
        siteinfofile:=pstr[2];
        assign(f,siteinfofile);
        {$I-} reset(f); {$I+}
        if (ioresult<>0) then begin
          writeln;
          writeln(siteinfofile+': File not found.');
          halt(1);
        end else
          close(f);
      end;
    if (pcount>=3) then val(pstr[3],serialnumber,i);
  end;

  assign(f,'bbs.ovr');
  {$I-} reset(f,1); {$I+}
  if (ioresult<>0) then begin
    writeln;
    writeln('BBS files not found.');
    halt(1);
  end;
  seek(f,filesize(f)-144);
  blockread(f,r,144,res);
  close(f);
  if (res<>144) then writeln('Errors reading in current data');

  notcoded:=FALSE;
  for i:=1 to 6 do
    if (r[i]<>infoheader[i]) then notcoded:=TRUE;

  if (not notcoded) then decryptinfo;

  if (wanttype=-1) then begin
    serialnumber:=r[20]+r[21] shl 8+r[22] shl 16+r[23] shl 24;
    vertypes:=r[19];
    c:=#0;
    repeat
      if (c<>'?') then begin
        writeln;
        write('Version type = ');
        case (vertypes and $07) of
          $00:writeln('Standard');
          $01:writeln('Alpha'); $02:writeln('Beta');
          $03:writeln('Gamma'); $04:writeln('Special');
        else  writeln('Unknown! (',vertypes,')');
        end;
        writeln('Serial number = ',serialnumber);
        writeln('Registration = '+aonoff((vertypes and $08=$08),'Yes','No'));
        writeln('Node membership = '+aonoff((vertypes and $10=$10),'Yes','No'));
        writeln;
      end;
      write('[>'); readln(s); c:=upcase(s[1]);
      if (s<>'') then
        case c of
          '0'..'4':
              begin
                vertypes:=vertypes and ($FF-$07);
                case c of
                  '1':vertypes:=vertypes or $01;
                  '2':vertypes:=vertypes or $02;
                  '3':vertypes:=vertypes or $03;
                  '4':vertypes:=vertypes or $04;
                  '5':vertypes:=vertypes or $05;
                end;
              end;
          '#':if (length(s)<>1) then begin
                s:=copy(s,2,length(s)-1); val(s,lng,i);
                serialnumber:=lng;
              end;
          '$':begin
                b:=vertypes and $08=$08;
                if (b) then vertypes:=vertypes and ($FF-$08)
                       else vertypes:=vertypes or $08;
              end;
          '@':begin
                b:=vertypes and $10=$10;
                if (b) then vertypes:=vertypes and ($FF-$10)
                       else vertypes:=vertypes or $10;
              end;
          '?':begin
                writeln;
                writeln('0:Standard');
                writeln('1:Alpha - "à"');
                writeln('2:Beta - "á"');
                writeln('3:Gamma - "â"');
                writeln('4:Special - "ä"');
                writeln('#xxxxx:Change serial number');
                writeln('$:Toggle registration');
                writeln('@:Toggle node membership');
                writeln;
                writeln('R:elist');
                writeln;
              end;
        end;
    until ((s='') or (c='Q'));
  end else
    vertypes:=wanttype;

  for i:=1 to 6 do r[i]:=infoheader[i];
  r[19]:=vertypes;

  reset(f,1);
  if (notcoded) then seek(f,filesize(f))
                else seek(f,filesize(f)-144);

  getpackdatetime(@pdt);
  r[13]:=pdt[1]; r[14]:=pdt[2]; r[15]:=pdt[3];
  r[16]:=pdt[4]; r[17]:=pdt[5]; r[18]:=pdt[6];

  r[20]:=(serialnumber and $FF);
  r[21]:=((serialnumber and $FF00) shr 8);
  r[22]:=((serialnumber and $FF0000) shr 16);
  r[23]:=((serialnumber and $FF000000) shr 24);

  siteinfos:='';
  if (siteinfofile<>'') then
    if (oversiteinfo<>'') then begin
      siteinfos:=oversiteinfo;
      s:='';
      for i:=1 to length(oversiteinfo) do
        if (oversiteinfo[i]=^J) then s:=s+^M^J
        else s:=s+oversiteinfo[i];
      writeln;
      writeln('This Alpha version is licensed to:');
      write(stripcolor(s));
      writeln;
      writeln('WARNING: Giving out this EXE file, or your BBS.EXE or BBS.OVR');
      writeln('files automatically terminates your status as an Alpha site.');
    end else begin
      assign(siteinfof,siteinfofile);
      reset(siteinfof);
      repeat
        readln(siteinfof,s);
        siteinfos:=siteinfos+s+^J;
      until ((eof(siteinfof)) or (length(siteinfos)>118));
      close(siteinfof);
    end;
  if (length(siteinfos)>118) then siteinfos:=copy(siteinfos,1,118);
  r[24]:=length(siteinfos);
  for i:=1 to 118 do r[i+24]:=random(256);
  for i:=1 to length(siteinfos) do r[i+24]:=ord(siteinfos[i]);

  for i:=1 to 6 do r[i+6]:=random(256); { new encryption indices }

  chk:=0;
  for i:=13 to 142 do inc(chk,r[i]);
  chk1:=(chk div 6)*5;
  chk2:=(chk div 19)*25;
  r[143]:=chk1 mod 256;
  r[144]:=chk2 mod 256;

  encryptinfo;
  blockwrite(f,r,144,res);
  if (res<>144) then writeln('Error writing data.');
  close(f);
end.
