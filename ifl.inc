{*    IFL - Interior File Listing Utility
 *    Copyright 1989 by Martin Pollard.  Turbo Pascal version by Eric Oman.
 *
 *		This header file contains constants and definitions used in
 *		the main program.
 *
 *		Version 1.00 - 02/11/89
 *		Version 1.10 - 02/24/89
 *		Version 1.11 - 03/01/89
 *		Version 1.20 - 03/15/89
 *
 *    Version 1.21 - 03/17/89
 *}

const
  L_SIG=$04034b50;   {* ZIP local file header signature *}
  C_SIG=$02014b50;   {* ZIP central dir file header signature *}
  E_SIG=$06054b50;   {* ZIP end of central dir signature *}
  Z_TAG=$fdc4a7dc;   {* ZOO entry identifier *}

  HEADER_1= ' Length  Size Now  %   Method     Date    Time  Filename';
  HEADER_2= '-------- -------- --- --------- -------- ------ ------------';
  FOOTER_1= '-------- -------- ---                           ------------';

  EXTS=5;     {* number of default extensions *}

  filext:array[0..EXTS-1] of string = (
    '.ZIP',   {* ZIP format archive *}
    '.ARC',   {* ARC format archive *}
    '.PAK',   {* ARC format archive (PAK.EXE) *}
    '.ZOO',   {* ZOO format archive *}
    '.ARK');  {* ARC format archive (CP/M ARK.COM) *}

  errmsg:array[0..5] of string = (
    'Unable to access specified file',
    'Unexpected end of file',
    'Unexpected read error',
    'Invalid header ID encountered',
    'Can''t find next entry in archive',
    'File is not in ARC/ZIP/ZOO archive format');

  method:array[0..13] of string = (
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
    'Reduced 4'); {* Probabilistic factor 4 compression *}

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
  filetype:integer;       {* file type (1=ARC, 2=ZIP, 3=ZOO) *}

