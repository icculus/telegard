(*    IFL - Interior File Listing Utility
 *    Copyright 1989 by Martin Pollard.  All rights reserved.
 *
 *    IFL produces a listing of files contained in an archive file.
 *    Archive formats supported by IFL include:
 *
 *      ARC - Developed by System Enhancement Associates
 *           and enhanced by PKWARE (PKARC & PKPAK)
 *           and NoGate Consulting (PAK)
 *      LZH - Developed by Haruyasu Yoshizaki
 *      ZIP - Developed by PKWARE
 *      ZOO - Developed by Rahul Dhesi
 *
 *    Version history:
 *
 *    1.00 02/11/89 Initial release.
 *    1.10 02/24/89 1.  Added support for archives created with SEA's
 *              ARC 6.x, which uses new header codes to support
 *              subdirectory archiving.
 *            2.  Restructured much of the code, which made no
 *              operational difference but resulted in a much
 *              "cleaner" source file.
 *            3.  Added automatic extension support.  IFL will now
 *              cycle through all supported extensions until it
 *              finds the desired file.
 *    1.20 03/15/89 1.  Added ZOO archive support.
 *            2.  The message line above the headings was changed
 *              to "Archive <filename> contains the following
 *              files:".  The drive and pathname is no longer
 *              displayed before the filename.
 *            3.  Fixed a minor bug in which a non-archive file
 *              may be mistaken for a ZIP archive file when the
 *              the first byte is "P" (0x50) but the second is
 *              not "K" (0x4B).
 *    1.30 05/09/89 Added support for archive files created by LHARC
 *            (LZH format).
 *    1.40 07/15/89 1.  Made minor code changes to improve performance,
 *              particularly during automatic extension
 *              searching.
 *            2.  Added support for the Imploding compression
 *              method used in PKZIP v1.00.
 *            3.  Corrected errors in and updated documentation.
 *)

{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit file4;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  file0, file14,
  common;


{rcg11172000 had to change this to get it compiling under Free Pascal...}
{function substall(src,old,new:astr):astr;}
function substall(src,old,_new:astr):astr;

function getbyte(var fp:file):char;
procedure abend(var abort,next:boolean; message:string);
procedure details(var abort,next:boolean);
procedure lfi(fn:astr; var abort,next:boolean);
procedure lfin(rn:integer; var abort,next:boolean);
procedure lfii;

const
  L_SIG=$04034b50;   {* ZIP local file header signature *}
  C_SIG=$02014b50;   {* ZIP central dir file header signature *}
  E_SIG=$06054b50;   {* ZIP end of central dir signature *}
  Z_TAG=$fdc4a7dc;   {* ZOO entry identifier *}

  EXTS=6;     {* number of default extensions *}

  filext:array[0..EXTS-1] of string[4] = (
    '.ZIP',   {* ZIP format archive *}
    '.ARC',   {* ARC format archive *}
    '.PAK',   {* ARC format archive (PAK.EXE) *}
    '.ZOO',   {* ZOO format archive *}
    '.LZH',   {* LZH format archive *}
    '.ARK');  {* ARC format archive (CP/M ARK.COM) *}

  errmsg:array[0..5] of string[49] = (
    'Unable to access specified file',
    'Unexpected end of file',
    'Unexpected read error',
    'Invalid header ID encountered',
    'Can''t find next entry in archive',
    'File is not in ZIP/ZOO/PAK/LZH/ARC archive format');

  method:array[0..15] of string[9] = (
    'Directory',  {* Directory marker *}
    'Unknown! ',  {* Unknown compression type *}
    'Stored   ',  {* No compression *}
    'Packed   ',  {* Repeat-byte compression *}
    'Squeezed ',  {* Huffman with repeat-byte compression *}
    'crunched ',  {* Obsolete LZW compression *}
    'Crunched ',  {* LZW 9-12 bit with repeat-byte compression *}
    'Squashed ',  {* LZW 9-13 bit compression *}
    'Crushed  ',  {* LZW 2-13 bit compression *}
    'Shrunk   ',  {* LZW 9-13 bit compression *}
    'Reduced 1',  {* Probabilistic factor 1 compression *}
    'Reduced 2',  {* Probabilistic factor 2 compression *}
    'Reduced 3',  {* Probabilistic factor 3 compression *}
    'Reduced 4',  {* Probabilistic factor 4 compression *}
    'Frozen   ',  {* Modified LZW/Huffman compression *}
    'Imploded '); {* Shannon-Fano tree compression *}

type
  arcfilerec=record   {* structure of ARC archive file header *}
               filename:array[0..12] of char; {* filename *}
               c_size:longint;     {* compressed size *}
               mod_date:integer;   {* last mod file date *}
               mod_time:integer;   {* last mod file time *}
               crc:integer;        {* CRC *}
               u_size:longint;     {* uncompressed size *}
             end;

  zipfilerec=record   {* structure of ZIP archive file header *}
               version:integer;    {* version needed to extract *}
               bit_flag:integer;   {* general purpose bit flag *}
               method:integer;     {* compression method *}
               mod_time:integer;   {* last mod file time *}
               mod_date:integer;   {* last mod file date *}
               crc:longint;        {* CRC-32 *}
               c_size:longint;     {* compressed size *}
               u_size:longint;     {* uncompressed size *}
               f_length:integer;   {* filename length *}
               e_length:integer;   {* extra field length *}
             end;

  zoofilerec=record   {* structure of ZOO archive file header *}
               tag:longint;     {* tag -- redundancy check *}
               typ:byte;        {* type of directory entry (always 1 for now) *}
               method:byte;     {* 0 = Stored, 1 = Crunched *}
               next:longint;    {* position of next directory entry *}
               offset:longint;  {* position of this file *}
               mod_date:word;   {* modification date (DOS format) *}
               mod_time:word;   {* modification time (DOS format) *}
               crc:word;        {* CRC *}
               u_size:longint;  {* uncompressed size *}
               c_size:longint;  {* compressed size *}
               major_v:char;    {* major version number *}
               minor_v:char;    {* minor version number *}
               deleted:byte;    {* 0 = active, 1 = deleted *}
               struc:char;      {* file structure if any *}
               comment:longint; {* location of file comment (0 = none) *}
               cmt_size:word;   {* length of comment (0 = none) *}
               fname:array[0..12] of char; {* filename *}
               var_dirlen:integer; {* length of variable part of dir entry *}
               tz:char;         {* timezone where file was archived *}
               dir_crc:word;    {* CRC of directory entry *}
             end;
  lzhfilerec=record   {* structure of LZH archive file header *}
               h_length:byte;   {* length of header *}
               h_cksum:byte;    {* checksum of header bytes *}
               method:array[1..5] of char; {* compression type "-lh#-" *}
               c_size:longint;  {* compressed size *}
               u_size:longint;  {* uncompressed size *}
               mod_time:integer;{* last mod file time *}
               mod_date:integer;{* last mod file date *}
               attrib:integer;  {* file attributes *}
               f_length:byte;   {* length of filename *}
               crc:integer;     {* crc *}
             end;

  outrec=record   {* output information structure *}
           filename:string[255];             {* output filename *}
           date:integer;                     {* output date *}
           time:integer;                     {* output time *}
           typ:integer;                      {* output storage type *}
           csize:longint;                    {* output compressed size *}
           usize:longint;                    {* output uncompressed size *}
         end;

var
  accum_csize:longint;    {* compressed size accumulator *}
  accum_usize:longint;    {* uncompressed size accumulator *}
  files:integer;          {* number of files *}
  level:integer;          {* output directory level *}
  filetype:integer;       {* file type (1=ARC,2=ZIP,3=ZOO,4=LZH) *}
  out:outrec;
  aborted:boolean;

implementation

uses file3;

{rcg11172000 had to change this to get it compiling under Free Pascal...}
{function substall(src,old,new:astr):astr;}
function substall(src,old,_new:astr):astr;
var p:integer;
begin
  p:=1;
  while p>0 do begin
    p:=pos(old,src);
    if p>0 then begin
      insert(_new,src,p+length(old));
      delete(src,p,length(old));
    end;
  end;
  substall:=src;
end;

procedure lbrl(fn:astr; var abort,next:boolean);
var f:file;
    c,n,n1:integer;
    x:record
        st:byte;
        name:array[1..8] of char;
        ext:array[1..3] of char;
        index,len:integer;
        fil:array[1..16] of byte;
      end;
    i:astr;
begin
  nl;
  assign(f,fn);
  reset(f,32);
  blockread(f,x,1);
  c:=x.len*4-1;
  for n:=1 to c do begin
    blockread(f,x,1); i:='';
    if (x.st=0) and not abort then begin
      for n1:=1 to 8 do i:=i+x.name[n1];
      i:=i+'.';
      for n1:=1 to 3 do i:=i+x.ext[n1];
      i:=align(i)+' '+mrn(cstrr(x.len*128.0,10),7);
      printacr(i,abort,next);
    end;
  end;
  close(f);
end;

function mnz(l:longint; w:integer):astr;
var s:astr;
begin
  s:=cstrl(l);
  while length(s)<w do s:='0'+s;
  mnz:=s;
end;

function mnr(l:longint; w:integer):astr;
begin
  mnr:=mrn(cstrl(l),w);
end;

{*------------------------------------------------------------------------*}

procedure abend(var abort,next:boolean; message:string);
begin
  {*  abend - Display error message
   *}

  nl;
  sprompt(#3#7+'** '+#3#5+message+#3#7+' **');
  nl;
  aborted:=TRUE;
  abort:=TRUE;
  next:=TRUE;
end;

{*------------------------------------------------------------------------*}

procedure details(var abort,next:boolean);
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

  if (month>12) then dec(month,12);     {* adjust for month > 12 *}
  if (year>99) then dec(year,100);      {* adjust for year > 1999 *}
  if (hour>23) then dec(hour,24);       {* adjust for hour > 23 *}
  if (minute>59) then dec(minute,60);   {* adjust for minute > 59 *}

  if (hour<12) then ampm:='a' else ampm:='p';  {* determine AM/PM *}
  if (hour=0) then hour:=12;                   {* convert 24-hour to 12-hour *}
  if (hour>12) then dec(hour,12);

  if (out.usize=0) then ratio:=0 else   {* ratio is 0% for null-length file *}
    ratio:=100-((out.csize*100) div out.usize);
  if ratio>99 then ratio:=99;

  outp:=#3#4+mnr(out.usize,8)+' '+mnr(out.csize,8)+' '+mnr(ratio,2)+'% '+
        #3#9+mrn(method[typ],9)+' '+#3#7+mnr(month,2)+'-'+mnz(day,2)+'-'+
        mnz(year,2)+' '+mnr(hour,2)+':'+mnz(minute,2)+ampm+' '+#3#5;

  if (level>0) then outp:=outp+mrn('',level); {* spaces for dirs (ARC only)*}

  outp:=outp+out.filename;
  printacr(outp,abort,next);

  if (typ=0) then inc(level)    {* bump dir level (ARC only) *}
  else begin
    inc(accum_csize,out.csize);  {* adjust accumulators and counter *}
    inc(accum_usize,out.usize);
    inc(files);
  end;
end;

{*------------------------------------------------------------------------*}

procedure final(var abort,next:boolean);
var outp:string;
    ratio:longint;
begin
  {*  final - Display final totals and information.
   *}

  if accum_usize=0 then ratio:=0    {* ratio is 0% if null total length *}
  else
    ratio:=100-((accum_csize*100) div accum_usize);
  if ratio>99 then ratio:=99;

  outp:=#3#4+mnr(accum_usize,8)+' '+mnr(accum_csize,8)+' '+mnr(ratio,2)+
        '%                           '+#3#5+cstr(files)+' file';
  if files<>1 then outp:=outp+'s';
  printacr(#3#4+'-------- -------- ---                           ------------',abort,next);
  printacr(outp,abort,next);
end;

{*------------------------------------------------------------------------*}

function getbyte(var fp:file):char;
var buf:array[0..0] of char;
    numread:word;
    c:char;
    abort,next:boolean;
begin
  {*  getbyte - Obtains character from file pointed to by fp.
   *            Aborts to DOS on error.
   *}

  if (not aborted) then begin
    blockread(fp,c,1,numread);
    if numread=0 then begin
      close(fp);
      abend(abort,next,errmsg[1]);
    end;
    getbyte:=c;
  end;
end;

{*------------------------------------------------------------------------*}

procedure zip_proc(var fp:file; var abort,next:boolean);
var zip:zipfilerec;
    buf:array[0..25] of byte;
    signature:longint;
    numread:word;
    i,stat:integer;
    c:char;
begin
  {* zip_proc - Process entry in ZIP archive.
  *}

  while (not aborted) do begin {* set up infinite loop (exit is within loop) *}
    blockread(fp,signature,4,numread); if numread<>4 then abend(abort,next,errmsg[2]);
    if abort then exit;
    if (signature=C_SIG) or (signature=E_SIG) or (aborted) then
      exit;
    if signature<>L_SIG then
      abend(abort,next,errmsg[3]);
    if abort then exit;
    blockread(fp,zip,26,numread); if numread<>26 then abend(abort,next,errmsg[2]);
    if abort then exit;
    out.filename:='';
    for i:=1 to zip.f_length do    {* get filename *}
      out.filename[i]:=getbyte(fp);
    out.filename[0]:=chr(zip.f_length);
    if (zip.e_length>0) then         {* skip comment if present *}
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
      6:out.typ:=15;   {* Imploded *}
    else
        out.typ:=1;    {* Unknown! *}
    end;
    details(abort,next); if abort then exit;
    {$I-} seek(fp,filepos(fp)+zip.c_size); {$I+}  {* seek to next entry *}
    if (ioresult<>0) then abend(abort,next,errmsg[4]);
    if (abort) then exit;
  end;
end;

{*------------------------------------------------------------------------*}

procedure lfi(fn:astr; var abort,next:boolean);
var fp:file;
    dirinfo1:searchrec;
    lzh:lzhfilerec;
    i1,i2,temp,infile,filename,showfn:astr;
    zoo_temp,zoo_tag:longint;
    numread:word;
    i,p,arctype,rcode:integer;
    c:char;
begin
  fn:=sqoutsp(fn);
  if (pos('*',fn)<>0) or (pos('?',fn)<>0) then begin
    findfirst(fn,anyfile-directory-volumeid,dirinfo1);
    if (doserror=0) then fn:=dirinfo1.name;
  end;
  if ((exist(fn)) and (not abort)) then begin
    arctype:=1;
    while (systat.filearcinfo[arctype].ext<>'') and
          (systat.filearcinfo[arctype].ext<>copy(fn,length(fn)-2,3)) and
          (arctype<7) do
      inc(arctype);
    if not ((systat.filearcinfo[arctype].ext='') or (arctype=7)) then begin
      temp:=systat.filearcinfo[arctype].listline;
      if (temp[1]='/') and (temp[2] in ['1'..'4']) and (length(temp)=2) then begin
        aborted:=FALSE;
        nl;
{        if (not fso) then showfn:=stripname(fn) else showfn:=fn;}
        showfn:=stripname(fn);
        printacr(#3#3+showfn+':',abort,next);
        nl;
        if (not abort) then begin
          infile:=fn;
          assign(fp,infile);
          reset(fp,1);

          c:=getbyte(fp);  {* determine type of archive *}
          case c of
            #$1a:filetype:=1;
            'P':begin
                  if getbyte(fp)<>'K' then abend(abort,next,errmsg[5]);
                  filetype:=2;
                end;
            'Z':begin
                  for i:=0 to 1 do
                    if getbyte(fp)<>'O' then abend(abort,next,errmsg[5]);
                  filetype:=3;
                end;
          else
                begin       {* assume LZH format *}
                  lzh.h_length:=ord(c);
                  c:=getbyte(fp);
                  for i:=1 to 5 do lzh.method[i]:=getbyte(fp);
                  if ((lzh.method[1]='-') and
                      (lzh.method[2]='l') and
                      (lzh.method[3]='h')) then
                    filetype:=4
                  else
                    abend(abort,next,errmsg[5]);
                end;
          end;

          reset(fp,1);                      {* back to start of file *}

          p:=0;                             {* drop drive and pathname *}
          for i:=1 to length(infile) do
            if infile[i] in [':','\'] then p:=i;
          filename:=copy(infile,p+1,length(infile)-p);

          accum_csize:=0; accum_usize:=0;   {* set accumulators to 0 *}
          level:=0; files:=0;               {* ditto with counters *}

          if filetype=3 then begin    {* process initial ZOO file header *}
            for i:=0 to 19 do      {* skip header text *}
              c:=getbyte(fp);
             {* get tag value *}
            blockread(fp,zoo_tag,4,numread);
            if numread<>4 then abend(abort,next,errmsg[2]);
            if zoo_tag<>Z_TAG then abend(abort,next,errmsg[5]);
             {* get data start *}
            blockread(fp,zoo_temp,4,numread); if numread<>4 then abend(abort,next,errmsg[2]);
            {$I-} seek(fp,zoo_temp); {$I+}
            if ioresult<>0 then abend(abort,next,errmsg[4]);
          end;

           {* print headings *}
          printacr(#3#3+' Length  Size Now  %   Method     Date    Time  Filename',abort,next);
          printacr(#3#4+'-------- -------- --- --------- -------- ------ ------------',abort,next);
          case filetype of
            1:arc_proc(fp,abort,next);  {* process ARC entry *}
            2:zip_proc(fp,abort,next);  {* process ZIP entry *}
            3:zoo_proc(fp,abort,next);  {* process ZOO entry *}
            4:lzh_proc(fp,abort,next);  {* process LZH entry *}
          end;
          final(abort,next);      {* clean things up *}
          close(fp);              {* close file *}
        end;
        nl;
      end else begin
        nl;
        sprompt(#3#3+'Archive '+fn+':  '+#3#4+'Please wait....');
        temp:=substall(systat.filearcinfo[arctype].listline,'@F',fn);
        shelldos(FALSE,temp+' >shell.$$$',rcode);
        for i:=1 to 15 do prompt(^H' '^H);
        nl;
        pfl('shell.$$$',abort,next,TRUE);
        assign(fp,'shell.$$$');
        {$I-} erase(fp); {$I+}
        if (ioresult<>0) then print('Unable to show contents via external viewer.');
      end;
    end;
  end;
end;

procedure lfin(rn:integer; var abort,next:boolean);
var f:ulfrec;
begin
  seek(ulff,rn); read(ulff,f);
  lfi(memuboard.dlpath+f.filename,abort,next);
end;

procedure lfii;
var f:ulfrec;
    fn:astr;
    pl,rn:integer;
    abort,next,lastarc,lastgif,isgif:boolean;
begin
  nl;
  sprint(fstring.viewline);
{  sprint(fstring.pninfo);}
  nl;
  gfn(fn); abort:=FALSE; next:=FALSE;
  nl;
  recno(fn,pl,rn);
  if (baddlpath) then exit;
  abort:=FALSE; next:=FALSE; lastarc:=fALSE; lastgif:=FALSE;
  while ((rn<>0) and (not abort)) do begin
    seek(ulff,rn); read(ulff,f);
    isgif:=isgifext(f.filename);
    if (isgif) then begin
      lastarc:=FALSE;
      if (not lastgif) then begin
        lastgif:=TRUE;
        nl; nl;
        printacr(#3#3+'Filename.Ext '+sepr2+' Resolution '+sepr2+
                 ' Num Colors '+sepr2+' Signat.',abort,next);
        printacr(#3#4+'=============:============:============:=========',abort,next);
      end;
      dogifspecs(sqoutsp(memuboard.dlpath+f.filename),abort,next);
    end else begin
      lastgif:=FALSE;
      if (not lastarc) then begin
        lastarc:=TRUE;
        nl;
(*        nl; nl;
        printacr(#3#5+'IFL v1.30 '+#3#1+'-'+#3#3+' By Martin Pollard '+
                 #3#1+'--',abort,next);*)
      end;
      lfin(rn,abort,next);
    end;
    nrecno(fn,pl,rn);
    if (next) then abort:=FALSE;
    next:=FALSE;
  end;
  close(ulff);
end;

end.
