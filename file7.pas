{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit file7;

interface

uses
  crt,dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  file0,
  common;

procedure recvascii(fn:astr; var dok:boolean; tpb:real);
procedure sendascii(fn:astr);

implementation

procedure recvascii(fn:astr; var dok:boolean; tpb:real);
var f:file;
    r1:array[0..1023] of byte;
    byte_count,start_time:longint;
    bytes_this_line,kbyte_count,line_count:integer;
    b:byte;
    start,abort,error,done,timeo,kba,prompti:boolean;
    c:char;

(*    procedure onec(var b:byte);
    var r:real;
        i:byte;
        c:char;
        bb:boolean;
    begin
      if (inhead[modemr.comport]<>intail[modemr.comport]) then begin
        bb:=recom1(c);
        b:=ord(c);
      end else begin
        r:=timer;
        while (not async_buffer_check) and (tchk(r,90.0)) do checkhangup;
        if (async_buffer_check) then b:=ord(ccinkey1)
        else begin
          timeo:=TRUE;
          b:=0;
        end;
        if (timeo) then error:=TRUE;
        if (hangup) then begin
          error:=TRUE; done:=TRUE;
          abort:=TRUE;
        end;
      end;
    end;*)

    procedure checkkb;
    var c:char;
    begin
      if (keypressed) then begin
        c:=readkey;
        if (c=#27) then begin
          abort:=TRUE; done:=TRUE; kba:=TRUE;
          nl; star('Aborted.');
        end;
      end;
    end;

begin
  abort:=FALSE; done:=FALSE; timeo:=FALSE; kba:=FALSE;
  line_count:=0; start:=FALSE;
  start_time:=trunc(timer); byte_count:=0;
  assign(f,fn);
  {$I-} rewrite(f,1); {$I+}
  if (ioresult<>0) then begin
    if (useron) then star('Disk error -  sorry, unable to upload it.');
    done:=TRUE; abort:=TRUE;
  end;
  prompti:=pynq('Do you want prompted input?');
  if (useron) then star('Upload Ascii text.  Press Ctrl-Z (^Z) when done');
  while (not done) and (not hangup) do begin
    error:=TRUE;
    checkkb;
    if (kba) then begin
      done:=TRUE;
      abort:=TRUE;
    end;
    if (not kba) then
      if (prompti) then begin
        com_flush_rx;
        sendcom1('>');
      end;
    if (not done) and (not abort) and (not hangup) then begin
      start:=FALSE;
      error:=FALSE;
      checkkb;
      if (not done) then begin
        bytes_this_line:=0;
        repeat
          getkey(c); b:=ord(c);
          if (b=26) then begin
            start:=TRUE; done:=TRUE;
            nl;
            if (useron) then star('End Of File Received');
          end else begin
            if (b<>10) then begin         (* ignore LF *)
              r1[bytes_this_line]:=b;
              bytes_this_line:=bytes_this_line+1;
            end;
          end;
        until (bytes_this_line>250) or (b=13) or (timeo) or (done);
        if (b<>13) then begin
          r1[bytes_this_line]:=13;
          bytes_this_line:=bytes_this_line+1;
        end;
        r1[bytes_this_line]:=10;
        bytes_this_line:=bytes_this_line+1;
        seek(f,byte_count);
        {$I-} blockwrite(f,r1,bytes_this_line); {$I+}
        if (ioresult<>0) then begin
          nl;
          if (useron) then star('Disk error');
          done:=TRUE; abort:=TRUE;
        end;
        inc(line_count);
        byte_count:=byte_count+bytes_this_line;
      end;
    end;
  end;
  close(f);
  kbyte_count:=0;
  while (byte_count>1024) do begin
    inc(kbyte_count);
    byte_count:=byte_count-1024;
  end;
  if (byte_count>512) then inc(kbyte_count,1);
  if (hangup) then abort:=TRUE;
  if (abort) then erase(f)
  else begin
    star(cstr(line_count)+' lines, '+cstr(kbyte_count)+'k uploaded');
    if (timer<start_time) then start_time:=start_time-24*60*60;
  end;
  dok:=not abort;
end;

procedure sendascii(fn:astr);
var f:file of char;
    i:integer;
    c,c1:char;
    abort:boolean;

  procedure ckey;
  begin
    checkhangup;
    while (not empty) and (not abort) and (not hangup) do begin
      if (hangup) then abort:=TRUE;
      c1:=inkey;
      if (c1=^X) or (c1=#27) or (c1=' ') then abort:=TRUE;
      if (c1=^S) then getkey(c1);
    end;
  end;

begin
  assign(f,fn);
  {$I-} reset(f); {$I+}
  if (ioresult<>0) then print('File not found.') else begin
    abort:=FALSE;
    print('^X = Abort  --  ^S = Pause');
    print('Press <CR> to start ... '); nl;
    repeat getkey(c) until (c=^M) or (hangup);
    while (not hangup) and (not abort) and (not eof(f)) do begin
      read(f,c); if (outcom) then sendcom1(c);
      if (c<>^G) then write(c);
      ckey;
    end;
    close(f);
    prompt(^Z);
    nl; nl;
    star('File transmission complete.');
  end;
end;

end.
