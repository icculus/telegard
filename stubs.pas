{rcg11172000 stub functions.}

{$A+,B+,D-,E+,F+,I+,L-,N-,O-,R-,S+,V-}
unit stubs;

interface

uses
  crt,dos;


procedure DeallocateEmsHandle(Handle : Word);
begin
end;

function EmsInstalled : Boolean;
begin
  EmsInstalled := false;
end;

function EmsPageFrame : Word;
begin
  EmsPageFrame := 0;
end;

function AllocateEmsPages(NumPages : Word) : Word;
begin
  AllocateEmsPages := 0;
end;

procedure DeallocateEmsHandle(Handle : Word);
begin
end;

function DefaultDrive : Char;
begin
  DefaultDrive := #103;  { 'C' }
end;

function DiskFree(Drive : Byte) : LongInt;
begin
   DiskFree := 10000000;
end;

end.

{end of stubs.pas ... }

