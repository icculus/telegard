{$A+,B+,D-,E+,F+,I+,L+,N-,O-,R-,S+,V-}
unit tmpcom;

interface

uses crt,dos;

var
  tmpcom_BIOS_port_table:array[1..2] of integer absolute $0040:0000;

const
  I8088_IMR=$21;
  tmpcom_buffer_max=5120;

type
  tmpcom_portrec=
  record
    RTB,          { receive / transmit buffers }
    IER,          { interrupt enable register }
    IIR,          { interrupt identification register }
    LCR,          { line control register }
    MCR,          { modem control register }
    LSR,          { line status register }
    MSR:integer;  { modem status register }
  end;

var
  tmpcom_saveoldvec:pointer;
  tmpcom_ports:tmpcom_portrec;
  tmpcom_base:integer;
  tmpcom_irq,
  tmpcom_port:byte;
  tmpcom_open_flag:boolean;

  tmpcom_buffer:array[0..tmpcom_buffer_max] of byte;
  tmpcom_buffer_head,
  tmpcom_buffer_tail,
  tmpcom_buffer_used:integer;

  tmpcom_outcharacter:char;
  tmpcom_outgoingnow:boolean;

  mpcoder:boolean;
  mpcode:array[1..6] of byte;

procedure tmpcom_clear_errors;
procedure tmpcom_setdtr(b:boolean);
procedure tmpcom_closeport(ddtr:boolean);
procedure tmpcom_resetport(comport:byte; baudrate:longint; parity:char;
                           wordsize,stopbits:byte);
procedure tmpcom_openport(comport:byte; baudrate:longint; parity:char;
                          wordsize,stopbits:byte);
procedure tmpcom_initvars;
function tmpcom_receive(var c:char):boolean;
procedure tmpcom_sendno(c:char);
procedure tmpcom_send(c:char);

implementation

procedure tmpcom_clear_errors;
var i,j:integer;
begin
  inline($FA);  { cli }

    { disable baud rate bs... }
  i:=port[tmpcom_ports.LCR] and $7F;
  port[tmpcom_ports.LCR]:=i;

  i:=port[tmpcom_ports.LSR];  { read LSR to reset errors }
  i:=port[tmpcom_ports.RTB];  { read RTB in case it contains a chr }

    { enable the IRQ line (3/4) on the 8259 controller }
  i:=((port[I8088_IMR]) and ((1 shl tmpcom_irq) xor $00FF));
  port[I8088_IMR]:=i;

    { enable data-available interrupt --
      transmit-register-empty interrupt is set by tmpcom_send(. }
  port[tmpcom_ports.IER]:=$01;

    { enable OUT2, RTS, and DTR }
  port[tmpcom_ports.MCR]:=$0B;

  inline($FB);  { sti }
end;

procedure tmpcom_setdtr(b:boolean);
var bb:byte;
begin
  bb:=port[tmpcom_ports.MCR] and $FE;
  if (b) then inc(bb);
  port[tmpcom_ports.MCR]:=bb;
end;

procedure tmpcom_closeport(ddtr:boolean);
var i,j:integer;
begin
  if (tmpcom_open_flag) then begin
    inline($FA);  { cli }

      { disable the IRQ line (3/4) on the 8259 controller }
    i:=((port[I8088_IMR]) or (1 shl tmpcom_irq));
    port[I8088_IMR]:=i;

      { disable data-available interrupt (along with all other interrupts) }
    port[tmpcom_ports.IER]:=$00;

      { disable OUT2, and DTR if ddtr=TRUE }
    i:=((port[tmpcom_ports.MCR]) and ($F7));
    port[tmpcom_ports.MCR]:=i;

    inline($FB);  { sti }

      { reset interrupt vector to original setting }
    setintvec(tmpcom_irq+8,tmpcom_saveoldvec);

    tmpcom_open_flag:=FALSE;
  end;
end;

function iii(i:integer):byte;
var j:integer;
begin
  j:=tmpcom_buffer_tail-i;
  if (j<0) then inc(j,tmpcom_buffer_max+1);
  iii:=tmpcom_buffer[j];
end;

procedure checkmpcode;
var i:integer;
begin
  inline($FA);
  if ((iii(1)=254) and (iii(2)=253)) then
    if ((iii(9)=1) and (iii(10)=2) and (iii(11)=1)) then begin
      mpcoder:=TRUE;
      for i:=1 to 6 do mpcode[7-i]:=iii(i+2);
      tmpcom_buffer_head:=0;
      tmpcom_buffer_tail:=tmpcom_buffer_head;
    end;
  inline($FB);
end;

procedure tmpcom_isr(flags,cs,ip,ax,bx,cx,dx,si,di,ds,es,bp:word); interrupt;
var dxx,i:integer;
    bb:byte;
    label iisr1,iisr2;
begin
  inline($FB);

  iisr1:
  dxx:=port[tmpcom_ports.IIR];
  if (dxx and $01<>$00) then goto iisr2;
  case (dxx and $06) of
    0:;
    2:begin
        if (tmpcom_outgoingnow) then begin
          i:=port[tmpcom_ports.MSR];
          port[tmpcom_ports.RTB]:=ord(tmpcom_outcharacter);
          tmpcom_outgoingnow:=FALSE;
        end;
        port[tmpcom_ports.IER]:=port[tmpcom_ports.IER] and $FD;{ turn off TRE }
      end;
    4:begin
        bb:=port[tmpcom_ports.RTB];
        tmpcom_buffer[tmpcom_buffer_head]:=bb;
        inc(tmpcom_buffer_head);
        if (tmpcom_buffer_head>tmpcom_buffer_max) then
          tmpcom_buffer_head:=0;
        if (bb=255) then checkmpcode;
      end;
    6:;
  end;
  goto iisr1;

  iisr2:
  port[$20]:=$20;
end;

procedure tmpcom_resetport(comport:byte; baudrate:longint; parity:char;
                           wordsize,stopbits:byte);
const
  tmpcom_num_bauds=10;
  tmpcom_baud_table:
    array[1..tmpcom_num_bauds] of record baud,bits:word; end
    = ((baud:110; bits:$00), (baud:150; bits:$20),
       (baud:300; bits:$40), (baud:600; bits:$60),
       (baud:1200; bits:$80), (baud:2400; bits:$A0),
       (baud:4800; bits:$C0), (baud:9600; bits:$E0),
       (baud:19200; bits:$E0), (baud:38400; bits:$E0));
var regs:registers;
    comparm,i:integer;
begin
  tmpcom_buffer_head:=0;
  tmpcom_buffer_tail:=0;

    { set up baud rate bits }
  i:=0;
  repeat inc(i)
  until ((tmpcom_baud_table[i].baud=baudrate) or (i=tmpcom_num_bauds));
  comparm:=tmpcom_baud_table[i].bits;

  case upcase(parity) of
    'E':comparm:=comparm or $18;
    'O':comparm:=comparm or $08;
  end;

  if (wordsize=7) then comparm:=comparm or $02 else comparm:=comparm or $03;
  if (stopbits=2) then comparm:=comparm or $04;

  regs.ax:=comparm and $00FF;
  regs.dx:=tmpcom_port-1;  { comport }
  intr($14,regs);
end;

procedure tmpcom_openport(comport:byte; baudrate:longint; parity:char;
                          wordsize,stopbits:byte);
begin
  if (tmpcom_open_flag) then tmpcom_closeport(FALSE);

  if ((comport=2) and (tmpcom_BIOS_port_table[2]<>0)) then begin
    tmpcom_base:=$2f8;
    tmpcom_port:=2; tmpcom_irq:=3;
  end else begin
    tmpcom_base:=$3f8;
    tmpcom_port:=1; tmpcom_irq:=4;
  end;

  with tmpcom_ports do begin
    RTB:=tmpcom_base;
    IER:=tmpcom_base+$01;
    IIR:=tmpcom_base+$02;
    LCR:=tmpcom_base+$03;
    MCR:=tmpcom_base+$04;
    LSR:=tmpcom_base+$05;
    MSR:=tmpcom_base+$06;
  end;

(*    { if the impossible has happened, get the heck outta here... }
  if (port[tmpcom_ports.IIR] and $F8<>0) then exit;*)

  tmpcom_resetport(comport,baudrate,parity,wordsize,stopbits);

  getintvec(tmpcom_irq+8,tmpcom_saveoldvec);
  setintvec(tmpcom_irq+8,@tmpcom_isr);

  tmpcom_resetport(comport,baudrate,parity,wordsize,stopbits);
  tmpcom_clear_errors;

  tmpcom_open_flag:=TRUE;
end;

procedure tmpcom_initvars;
begin
  tmpcom_base:=$3f8;
  tmpcom_irq:=4;
  tmpcom_port:=1;
  tmpcom_open_flag:=FALSE;

  tmpcom_buffer_head:=0;
  tmpcom_buffer_tail:=0;
  tmpcom_buffer_used:=0;

  tmpcom_outcharacter:=#0;
  tmpcom_outgoingnow:=FALSE;
end;

function tmpcom_receive(var c:char):boolean;
begin
  c:=#0;
  if (tmpcom_buffer_head<>tmpcom_buffer_tail) then begin
    inline($FA);
    c:=chr(tmpcom_buffer[tmpcom_buffer_tail]);
    tmpcom_buffer_tail:=(tmpcom_buffer_tail+1) mod (tmpcom_buffer_max+1);
    inline($FB);
    tmpcom_receive:=TRUE;
  end else
    tmpcom_receive:=FALSE;
end;

procedure tmpcom_sendno(c:char);
var i:integer;
begin
  i:=port[tmpcom_ports.MSR];
  while (port[tmpcom_ports.LSR] and $20=0) do ;
  port[tmpcom_ports.RTB]:=ord(c);
end;

procedure tmpcom_send(c:char);
var lng:longint;
    i:integer;
begin
  inline($FB);
  lng:=0; while ((tmpcom_outgoingnow) and (lng<500000)) do inc(lng);
  if (lng>=500000) then begin
    inline($FA); tmpcom_outgoingnow:=FALSE;
{    tmpcom_clear_errors;}
    inline($FA); delay(100); inline($FB);
  end;
    { enable transmit-register-empty interrupt }
  inline($FA);
  tmpcom_outcharacter:=c;
  tmpcom_outgoingnow:=TRUE;
  i:=port[tmpcom_ports.IER];
  if (i and $02<>$02) then begin
    i:=i or $02;
    port[tmpcom_ports.IER]:=i;
  end;
  inline($FB);

(*  inline($FA);
  tmpcom_obuffer[tmpcom_obuffer_tail]:=c;
  tmpcom_obuffer_tail:=(tmpcom_obuffer_tail+1) mod (tmpcom_obuffer_max+1);
  inline($FB);*)
end;

begin
  mpcoder:=FALSE;
  tmpcom_open_flag:=FALSE;
end.
