{*    IFL - Interior File Listing Utility
 *    Copyright 1989 by Martin Pollard.  Turbo Pascal version by Eric Oman.
 *
 *		IFL produces a listing of files contained in an archive file.
 *		Archive formats supported by IFL include:
 *
 *			ARC - Developed by System Enhancement Associates
 *            and enhanced by PKware (PKARC & PKPAK)
 *            and NoGate Consulting (PAK)
 *			ZIP - Developed by PKware
 *			ZOO - Developed by Rahul Dhesi
 *
 *		Version history:
 *
 *		1.00 02/11/89	Initial release.
 *		1.10 02/24/89	1.	Added support for archives created with SEA's
 *                      ARC 6.x, which uses new header codes to support
 *                      subdirectory archiving.
 *                  2.  Restructured much of the code, which made no
 *                      operational difference but resulted in a much
 *                      "cleaner" source file.
 *                  3.  Added automatic extension support.  IFL will now
 *                      cycle through all supported extensions until it
 *                      finds the desired file.
 *    1.11 03/01/89 Fixed a minor bug in which a non-archive file may
 *                  be mistaken for a ZIP archive when the first byte
 *                  is "P" (50h) but the second is not "K" (4Bh).
 *                  (This version was never released.)
 *		1.20 03/15/89	1.	Added ZOO archive support.
 *                  2.  The message line above the headings was changed
 *                      to "Archive <filename> contains the following
 *                      files:".  The drive and pathname is no longer
 *                      displayed before the filename.
 *
 *    1.21 03/17/89 Converted all C code into Turbo Pascal 5.0 code.
 *
 *}

uses
  dos;      {* turbo3 and crt units intentionally unused
               to allow redirection of I/O *}


{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
{$I ifl.inc}

const
  VERSION = '1.21';
  __DATE__ = 'Mar 17 1989';

var
  arc:arcfilerec;
  zip:zipfilerec;
  zoo:zoofilerec;
  out:outrec;

{*------------------------------------------------------------------------*}

  {* Miscellaneous string/numeric manipulation routines.
  *}

function cstr(l:longint):string;
var s:string;
begin
  str(l,s);
  cstr:=s;
end;

function mrn(s:string; w:integer; c:char):string;
begin
  while length(s)<w do s:=c+s;
  mrn:=s;
end;

function mnz(l:longint; w:integer):string;
begin
  mnz:=mrn(cstr(l),w,'0');
end;

function mn(l:longint; w:integer):string;
begin
  mn:=mrn(cstr(l),w,' ');
end;

{*------------------------------------------------------------------------*}

procedure abend(message:string);
begin
  {*  abend() - Display error message and abort to DOS.  Returns
	 *		ERRORLEVEL of 1.
   *}

  writeln;
  writeln('** '+message+' **');
  halt(1);
end;

{*------------------------------------------------------------------------*}

procedure details;
var i,month,day,year,hour,minute,typ:integer;
    ampm:char;
    ratio:longint;
    outp:string;
begin
  {*  details - Calculate and display details line.
   *}

  typ:=out.typ;
  for i:=1 to length(out.filename) do
    out.filename[i]:=upcase(out.filename[i]);
  day:=out.date and $1f;                {* day = bits 4-0 *}
  month:=(out.date shr 5) and $0f;      {* month = bits 8-5 *}
  year:=((out.date shr 9) and $7f)+80;  {* year = bits 15-9 *}
  minute:=(out.time shr 5) and $3f;     {* minute = bits 10-5 *}
  hour:=(out.time shr 11) and $1f;      {* hour = bits 15-11 *}

  if month>12 then dec(month,12);     {* adjust for month > 12 *}
  if year>99 then dec(year,100);      {* adjust for year > 1999 *}
  if hour>23 then dec(hour,24);       {* adjust for hour > 23 *}
  if minute>59 then dec(minute,60);   {* adjust for minute > 59 *}

  if hour<12 then ampm:='a' else ampm:='p';  {* determine AM/PM *}
  if hour=0 then hour:=12;                   {* convert 24-hour to 12-hour *}
  if hour>12 then dec(hour,12);

  if out.usize=0 then ratio:=0 else   {* ratio is 0% for null-length file *}
    ratio:=100-((out.csize*100) div out.usize);
  if ratio>99 then ratio:=99;

  outp:=mn(out.usize,8)+' '+mn(out.csize,8)+' '+mn(ratio,2)+'% '+
        mrn(method[typ],9,' ')+' '+mn(month,2)+'-'+mnz(day,2)+'-'+
        mnz(year,2)+' '+mn(hour,2)+':'+mnz(minute,2)+ampm+' ';

  if level>0 then outp:=outp+mrn('',level,' '); {* spaces for dirs (ARC only)*}

  outp:=outp+out.filename;
  writeln(outp);

  if typ=0 then inc(level)    {* bump dir level (ARC only) *}
  else begin
    inc(accum_csize,out.csize);  {* adjust accumulators and counter *}
    inc(accum_usize,out.usize);
    inc(files);
  end;
end;

{*------------------------------------------------------------------------*}

procedure final;
var ratio:longint;
    outp:string;
begin
  {*  final - Display final totals and information.
   *}

  if accum_usize=0 then ratio:=0    {* ratio is 0% if null total length *}
  else
    ratio:=100-((accum_csize*100) div accum_usize);
  if ratio>99 then ratio:=99;

  outp:=mn(accum_usize,8)+' '+mn(accum_csize,8)+' '+mn(ratio,2)+
        '%                           '+cstr(files)+' file';
  if files<>1 then outp:=outp+'s';
  writeln(FOOTER_1);
  writeln(outp);
end;

{*------------------------------------------------------------------------*}

function getbyte(var fp:file):char;
var c:char;
    buf:array[0..0] of char;
    numread:word;
begin
  {*  getbyte - Obtains character from file pointed to by fp.
   *            Aborts to DOS on error.
   *}

  blockread(fp,c,1,numread);
  if numread=0 then begin
    close(fp);
    abend(errmsg[1]);
  end;
  getbyte:=c;
end;

{*------------------------------------------------------------------------*}

procedure arc_proc(var fp:file);
var i,typ,stat:integer;
    c:char;
    numread:word;
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
      blockread(fp,arc,23,numread); if numread<>23 then abend(errmsg[2]);
      if typ=1 then          {* type 1 didn't have c_size field *}
        arc.u_size:=arc.c_size
      else begin
        blockread(fp,arc.u_size,4,numread);
        if numread<>4 then abend(errmsg[2]);
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
      details;
      if typ<>30 then begin
        {$I-} seek(fp,filepos(fp)+arc.c_size); {$I+} {* seek to next entry *}
        if ioresult<>0 then abend(errmsg[4]);
      end;
    end;
  until c<>#$1a;
  abend(errmsg[3]);
end;

{*------------------------------------------------------------------------*}

procedure zip_proc(var fp:file);
var i,stat:integer;
    signature:longint;
    c:char;
    buf:array[0..25] of byte;
    numread:word;
begin
  {* zip_proc - Process entry in ZIP archive.
  *}

  while TRUE do begin   {* set up infinite loop (exit is within loop) *}
    blockread(fp,signature,4,numread); if numread<>4 then abend(errmsg[2]);
    if (signature=C_SIG) or (signature=E_SIG) then
      exit;
    if signature<>L_SIG then
      abend(errmsg[3]);
    blockread(fp,zip,26,numread); if numread<>26 then abend(errmsg[2]);
    out.filename:='';
    for i:=1 to zip.f_length do    {* get filename *}
      out.filename[i]:=getbyte(fp);
    out.filename[0]:=chr(zip.f_length);
    if zip.e_length>0 then         {* skip comment if present *}
      for i:=1 to zip.e_length do
        c:=getbyte(fp);
    out.date:=zip.mod_date;
    out.time:=zip.mod_time;
    out.csize:=zip.c_size;
    out.usize:=zip.u_size;
    case zip.method of
      0:out.typ:=2;    {* Stored *}
      1:out.typ:=9;    {* Shrunk *}
      2,3,4,5:
        out.typ:=zip.method+8;  {* Reduced *}
    else
        out.typ:=1;    {* Unknown! *}
    end;
    details;
    {$I-} seek(fp,filepos(fp)+zip.c_size); {$I+}  {* seek to next entry *}
    if ioresult<>0 then abend(errmsg[4]);
  end;
end;

{*------------------------------------------------------------------------*}

procedure zoo_proc(var fp:file);
var i,method:integer;
    zoo_longname,zoo_dirname:string[255];
    numread:word;
    namlen,dirlen:byte;
begin
  {*  zoo_proc - Process entry in ZOO archive.
   *}

  while TRUE do begin   {* set up infinite loop (exit is within loop) *}
    blockread(fp,zoo,56,numread); if numread<>56 then abend(errmsg[2]);
    if zoo.tag<>Z_TAG then abend(errmsg[3]);   {* abort if invalid tag *}
    if zoo.next=0 then exit;

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
    if not (zoo.deleted=1) then details;

    {$I-} seek(fp,zoo.next); {$I+}  {* seek to next entry *}
    if ioresult<>0 then abend(errmsg[4]);
  end;
end;

{*------------------------------------------------------------------------*}

procedure usage;
begin
  {*  usage - Displays help screen for people who can't comprehend how to
   *          use a simple program like this!  Returns ERRORLEVEL of 2.
   *}

  writeln;
  writeln('IFL v'+VERSION+' - '+__DATE__+' - Interior File Listing Utility');
  writeln('Copyright 1989 by Martin Pollard.  Turbo Pascal version by Eric Oman');
  writeln;
  writeln('Syntax is:   "IFL filename"');
  writeln;
  writeln('IFL produces a listing of files contained in an archive file.');
  writeln('Archive formats currently supported include:');
  writeln;
  writeln('   ARC - Developed by System Enhancement Associates');
  writeln('            and enhanced by PKware (PKARC & PKPAK)');
  writeln('            and NoGate Consulting (PAK)');
  writeln('   ZIP - Developed by PKware');
  writeln('   ZOO - Developed by Rahul Dhesi');
  writeln;
  writeln('Support for other formats may be included in the future.');
  halt(2);
end;

{*------------------------------------------------------------------------*}

function exist(fn:string):boolean;
var fp:file;
begin
  assign(fp,fn);
  {$I-} reset(fp); {$I+}
  if ioresult=0 then begin
    close(fp);
    exist:=TRUE;
  end
  else
    exist:=FALSE;
end;

{*------------------------------------------------------------------------*}

var temp,infile,filename:string;
    fp:file;
    i,p:integer;
    c:char;
    zoo_temp,zoo_tag:longint;
    numread:word;
begin
  {*   The start of the program.  Everything in the program
   *   executes from here.  Returns to DOS with ERRORLEVEL of 0 on
   *   successful completion.
   *}

  if paramcount=0 then usage;  {* check if no arguments entered *}

  temp:=paramstr(1);
  for i:=1 to length(temp) do
    case temp[i] of
      '/':temp[i]:='\';
    else
          temp[i]:=upcase(temp[i]);
    end;
  infile:='';
  if pos(':',temp)=0 then begin  {* add drive to filename if not there *}
    getdir(0,infile);
    infile[0]:=#2;
  end;
  infile:=infile+temp;

  if not exist(infile) then begin
    temp:=infile;
    i:=0;
    repeat
      infile:=temp+filext[i];
      inc(i);
    until (exist(infile)) or (i=EXTS);
    if i=EXTS then abend(errmsg[0]);
  end;

  assign(fp,infile);
  reset(fp,1);

  c:=getbyte(fp);  {* determine type of archive *}
  case c of
    #$1a:filetype:=1;
    'P':begin
          if getbyte(fp)<>'K' then abend(errmsg[5]);
          filetype:=2;
        end;
    'Z':begin
          for i:=0 to 1 do
            if getbyte(fp)<>'O' then abend(errmsg[5]);
          filetype:=3;
        end;
  else
        abend(errmsg[5]);
  end;

  reset(fp,1);                      {* back to start of file *}

  p:=0;                             {* drop drive and pathname *}
  for i:=1 to length(infile) do
    if infile[i] in [':','\'] then p:=i;
  filename:=copy(infile,p+1,length(infile)-p);

  writeln;
  writeln('Archive '+infile+': (IFL TP 5.0 version by Eric Oman)');
  writeln;

  accum_csize:=0; accum_usize:=0;   {* set accumulators to 0 *}
  level:=0; files:=0;               {* ditto with counters *}

  if filetype=3 then begin    {* process initial ZOO file header *}
    for i:=0 to 19 do      {* skip header text *}
      c:=getbyte(fp);
     {* get tag value *}
    blockread(fp,zoo_tag,4,numread);
    if numread<>4 then abend(errmsg[2]);
    if zoo_tag<>Z_TAG then abend(errmsg[5]);
     {* get data start *}
    blockread(fp,zoo_temp,4,numread); if numread<>4 then abend(errmsg[2]);
    {$I-} seek(fp,zoo_temp); {$I+}
    if ioresult<>0 then abend(errmsg[4]);
  end;

  writeln(HEADER_1);      {* print headings *}
  writeln(HEADER_2);
  case filetype of
    1:arc_proc(fp);       {* process ARC entry *}
    2:zip_proc(fp);       {* process ZIP entry *}
    3:zoo_proc(fp);       {* process ZOO entry *}
  end;
  final;                  {* clean things up *}
  close(fp);              {* close file *}
  halt(0);
end.
