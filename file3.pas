{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit file3;

interface

uses
  crt,dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  file0,
  common;

procedure arc_proc(var fp:file; var abort,next:boolean);
procedure zoo_proc(var fp:file; var abort,next:boolean);
procedure lzh_proc(var fp:file; var abort,next:boolean);

implementation

uses file4;

{*------------------------------------------------------------------------*}

procedure arc_proc(var fp:file; var abort,next:boolean);
var arc:arcfilerec;
    numread:word;
    i,typ,stat:integer;
    c:char;
begin
  {*  arc_proc - Process entry in ARC archive.
  *}

  repeat
    c:=getbyte(fp);
    typ:=ord(getbyte(fp));   {* get storage method *}
    case typ of
      0:exit;                {* end of archive file *}
      1,2:out.typ:=2;        {* Stored *}
      3,4:out.typ:=typ;      {* Packed & Squeezed *}
      5,6,7:out.typ:=typ;    {* crunched *}
      8,9,10:out.typ:=typ-2; {* Crunched, Squashed & Crushed *}
      30:out.typ:=0;         {* Directory *}
      31:dec(level);         {* end of dir (not displayed) *}
    else
         out.typ:=1;         {* Unknown! *}
    end;
    if typ<>31 then begin    {* get data from header *}
      blockread(fp,arc,23,numread); if numread<>23 then abend(abort,next,errmsg[2]);
      if abort then exit;
      if typ=1 then          {* type 1 didn't have c_size field *}
        arc.u_size:=arc.c_size
      else begin
        blockread(fp,arc.u_size,4,numread);
        if numread<>4 then abend(abort,next,errmsg[2]);
        if abort then exit;
      end;
      i:=0;
      repeat
        inc(i);
        out.filename[i]:=arc.filename[i-1];
      until (arc.filename[i]=#0) or (i=13);
      out.filename[0]:=chr(i);
      out.date:=arc.mod_date;
      out.time:=arc.mod_time;
      if typ=30 then begin
        arc.c_size:=0;            {* set file size entries *}
        arc.u_size:=0;            {* to 0 for directories *}
      end;
      out.csize:=arc.c_size;   {* set file size entries *}
      out.usize:=arc.u_size;   {* for normal files *}
      details(abort,next); if abort then exit;
      if typ<>30 then begin
        {$I-} seek(fp,filepos(fp)+arc.c_size); {$I+} {* seek to next entry *}
        if ioresult<>0 then abend(abort,next,errmsg[4]);
        if abort then exit;
      end;
    end;
  until (c<>#$1a) or (aborted);
  if not aborted then abend(abort,next,errmsg[3]);
end;

{*------------------------------------------------------------------------*}

procedure zoo_proc(var fp:file; var abort,next:boolean);
var zoo:zoofilerec;
    zoo_longname,zoo_dirname:string[255];
    numread:word;
    i,method:integer;
    namlen,dirlen:byte;
begin
  {*  zoo_proc - Process entry in ZOO archive.
   *}

  while (not aborted) do begin {* set up infinite loop (exit is within loop) *}
    blockread(fp,zoo,56,numread); if numread<>56 then abend(abort,next,errmsg[2]);
    if abort then exit;
    if zoo.tag<>Z_TAG then abend(abort,next,errmsg[3]);   {* abort if invalid tag *}
    if (abort) or (zoo.next=0) then exit;

    namlen:=ord(getbyte(fp)); dirlen:=ord(getbyte(fp));
    zoo_longname:=''; zoo_dirname:='';
    if namlen>0 then
      for i:=1 to namlen do   {* get long filename *}
        zoo_longname:=zoo_longname+getbyte(fp);
    if dirlen>0 then begin
      for i:=1 to dirlen do   {* get directory name *}
        zoo_dirname:=zoo_dirname+getbyte(fp);
      if copy(zoo_dirname,length(zoo_dirname),1)<>'/' then
        zoo_dirname:=zoo_dirname+'/';
    end;
    if zoo_longname<>'' then out.filename:=zoo_longname
    else begin
      i:=0;
      repeat
        inc(i);
        out.filename[i]:=zoo.fname[i-1];
      until (zoo.fname[i]=#0) or (i=13);
      out.filename[0]:=chr(i);
      out.filename:=zoo_dirname+out.filename;
    end;
    out.date:=zoo.mod_date;  {* set up fields *}
    out.time:=zoo.mod_time;
    out.csize:=zoo.c_size;
    out.usize:=zoo.u_size;
    method:=zoo.method;
    case method of
      0:out.typ:=2;      {* Stored *}
      1:out.typ:=6;      {* Crunched *}
    else
        out.typ:=1;      {* Unknown! *}
    end;
    if not (zoo.deleted=1) then details(abort,next);
    if abort then exit;

    {$I-} seek(fp,zoo.next); {$I+}  {* seek to next entry *}
    if ioresult<>0 then abend(abort,next,errmsg[4]);
    if abort then exit;
  end;
end;

{*------------------------------------------------------------------------*}

procedure lzh_proc(var fp:file; var abort,next:boolean);
var lzh:lzhfilerec;
    numread:word;
    i:integer;
    c:char;
begin
  {*  lzh_proc - Process entry in LZH archive.
   *}

  while (not aborted) do begin {* set up infinite loop (exit is within loop) *}
    c:=getbyte(fp);
    if (c=#0) then exit else lzh.h_length:=ord(c);
    c:=getbyte(fp);
    lzh.h_cksum:=ord(c);
    blockread(fp,lzh.method,5,numread); if (numread<>5) then abend(abort,next,errmsg[2]);
    if (abort) then exit;
    if ((lzh.method[1]<>'-') or
        (lzh.method[2]<>'l') or
        (lzh.method[3]<>'h')) then abend(abort,next,errmsg[3]);
    if (abort) then exit;
    blockread(fp,lzh.c_size,15,numread); if (numread<>15) then abend(abort,next,errmsg[2]);
    if (abort) then exit;
    for i:=1 to lzh.f_length do out.filename[i]:=getbyte(fp);
    out.filename[0]:=chr(lzh.f_length);
    if (lzh.h_length-lzh.f_length=22) then begin
      blockread(fp,lzh.crc,2,numread); if (numread<>2) then abend(abort,next,errmsg[2]);
      if (abort) then exit;
    end;
    out.date:=lzh.mod_date;  {* set up fields *}
    out.time:=lzh.mod_time;
    out.csize:=lzh.c_size;
    out.usize:=lzh.u_size;
    c:=lzh.method[4];
    case c of
      '0':out.typ:=2;      {* Stored *}
      '1':out.typ:=14;     {* Frozen *}
    else
          out.typ:=1;      {* Unknown! *}
    end;
    details(abort,next);

    {$I-} seek(fp,filepos(fp)+lzh.c_size); {$I+}  {* seek to next entry *}
    if (ioresult<>0) then abend(abort,next,errmsg[4]);
    if (abort) then exit;
  end;
end;

end.
