{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
UNIT tmpcom;

{Version 3.0}

{This unit is the communications port interrupt driver for the IBM-PC.
It handles handles all low-level i/o through the serial port.  It is
installed by calling com_install.  It deinstalls itself automatically
when the program exits, or you can deinstall it by calling com_deinstall.

Donated to the public domain by Wayne E. Conrad, January, 1989.
If you have any problems or suggestions, please contact me at my BBS:

    Pascalaholics Anonymous
    (602) 484-9356
    2400 bps
    The home of WBBS
    Lots of source code
}


INTERFACE

USES
  Dos;


TYPE
  com_parity = (com_none, com_even, com_odd, com_zero, com_one);

{This variable is TRUE if the interrupt driver has been installed, or FALSE
if it hasn't.  It's used to prevent installing twice or deinstalling when not
installed.}

CONST
  com_installed: Boolean = FALSE;
  usefossil:boolean = FALSE;

var
  mpcoder:boolean;
  mpcode:array[1..6] of byte;
  fosport:byte;
  regs:registers;

procedure com_flush_rx;
procedure com_flush_tx;
procedure com_purge_tx;
function com_carrier:boolean;
function com_rx:char;
function com_tx_ready:boolean;
function com_tx_empty:boolean;
function com_rx_empty:boolean;
procedure com_tx (ch: Char);
procedure com_tx_string (st: String);
procedure com_lower_dtr;
procedure com_raise_dtr;
procedure com_set_speed(speed:word);
procedure com_set_parity(parity:com_parity; stop_bits:byte);
procedure com_install(portnum:word; var error:word; dofossil:boolean);
procedure com_deinstall;


implementation


{Summary of IBM-PC Asynchronous Adapter Registers.  From:
  Compute!'s Mapping the IBM PC and PCjr, by Russ Davis
  (Greensboro, North Carolina, 1985: COMPUTE! Publications, Inc.),
  pp. 290-292.

Addresses given are for COM1 and COM2, respectively.  The names given
in parentheses are the names used in this module.


3F8/2F8 (uart_data) Read: transmit buffer.  Write: receive buffer, or baud
rate divisor LSB if port 3FB, bit 7 = 1.

3F9/2F9 (uart_ier) Write: Interrupt enable register or baud rate divisor
MSB if port 3FB, bit 7 = 1.
PCjr baud rate divisor is different from other models;
clock input is 1.7895 megahertz rather than 1.8432 megahertz.
Interrupt enable register:
    bits 7-4  forced to 0
    bit 3     1=enable change-in-modem-status interrupt
    bit 2     1=enable line-status interrupt
    bit 1     1=enable transmit-register-empty interrupt
    bit 0     1=data-available interrupt

3FA/2FA (uart_iir) Interrupt identification register (prioritized)
     bits 7-3  forced to 0
     bits 2-1  00=change-in-modem-status (lowest)
     bits 2-1  01=transmit-register-empty (low)
     bits 2-1  10=data-available (high)
     bits 2-1  11=line status (highest)
     bit 0     1=no interrupt pending
     bit 0     0=interrupt pending

3FB/2FB (uart_lcr) Line control register
     bit 7  0=normal, 1=address baud rate divisor registers
     bit 6  0=break disabled, 1=enabled
     bit 5  0=don't force parity
            1=if bit 4-3=01 parity always 1
              if bit 4-3=11 parity always 0
              if bit 3=0 no parity
     bit 4  0=odd parity,1=even
     bit 3  0=no parity,1=parity
     bit 2  0=1 stop bit
            1=1.5 stop bits if 5 bits/character or
              2 stop bits if 6-8 bits/character
     bits 1-0  00=5 bits/character
               01=6 bits/character
               10=7 bits/character
               11=8 bits/character

     bits 5..3: 000 No parity
                001 Odd parity
                010 No parity
                011 Even parity
                100 No parity
                101 Parity always 1
                110 No parity
                111 Parity always 0


3FC/2FC (uart_mcr) Modem control register
     bits 7-5  forced to zero
     bit 4     0=normal, 1=loop back test
     bits 3-2  all PCs except PCjr
     bit 3     1=interrupts to system bus, user-designated output: OUT2
     bit 2     user-designated output, OUT1
     bit 1     1=activate rts
     bit 0     1=activate dtr

3FD/2FD (uart_lsr) Line status register
     bit 7  forced to 0
     bit 6  1=transmit shift register is empty
     bit 5  1=transmit hold register is empty
     bit 4  1=break received
     bit 3  1=framing error received
     bit 2  1=parity error received
     bit 1  1=overrun error received
     bit 0  1=data received

3FE/2FE (uart_msr) Modem status register
     bit 7  1=receive line signal detect
     bit 6  1=ring indicator (all PCs except PCjr)
     bit 5  1=dsr
     bit 4  1=cts
     bit 3  1=receive line signal detect has changed state
     bit 2  1=ring indicator has changed state (all PCs except PCjr)
     bit 1  1=dsr has changed state
     bit 0  1=cts has changed state

3FF/2FF (uart_spr) Scratch pad register.}


{Maximum port number (minimum is 1) }

const
  max_port = 4;


{Base i/o address for each COM port}

const
  uart_base: ARRAY [1..max_port] OF Integer = ($3F8, $2F8, $3E8, $2E8);


{Interrupt numbers for each COM port}

const
  intnums: ARRAY [1..max_port] OF Byte = ($0C, $0B, $0C, $0B);


{i8259 interrupt levels for each port}

const
  i8259levels: ARRAY [1..max_port] OF Byte = (4, 3, 4, 3);

{UART i/o addresses.  Values depend upon which COMM port is selected.}

var
  uart_data:word;             {Data register}
  uart_ier:word;             {Interrupt enable register}
  uart_iir:word;             {Interrupt identification register}
  uart_lcr:word;             {Line control register}
  uart_mcr:word;             {Modem control register}
  uart_lsr:word;             {Line status register}
  uart_msr:word;             {Modem status register}
  uart_spr:word;             {Scratch pad register}


{Original contents of IER and MCR registers.  Used to restore UART
to whatever state it was in before this driver was loaded.}

var
  old_ier:byte;
  old_mcr:byte;


{Original contents of interrupt vector.  Used to restore the vector when
the interrupt driver is deinstalled.}

var
  old_vector:pointer;


{Original contents of interrupt controller mask.  Used to restore the
bit pertaining to the comm controller we're using.}

var
  old_i8259_mask:byte;


{Bit mask for i8259 interrupt controller}

var
  i8259bit:byte;


{Interrupt vector number}

var
  intnum:byte;


{ Receive queue.  Received characters are held here
  until retrieved by com_rx. }

const
  rx_queue_size=5120;   {Change to suit}
var
  rx_queue:array[1..rx_queue_size] of byte;
  rx_in:word;           {Index of where to store next character}
  rx_out:word;          {Index of where to retrieve next character}
  rx_chars:word;        {Number of chars in queue}


{ Transmit queue.  Characters to be transmitted are held here
  until the UART is ready to transmit them. }

const
  tx_queue_size=16;    {Change to suit}
var
  tx_queue:array[1..tx_queue_size] of byte;
  tx_in:integer;        {Index of where to store next character}
  tx_out:integer;       {Index of where to retrieve next character}
  tx_chars:integer;     {Number of chars in queue}


{This variable is used to save the next link in the "exit procedure" chain.}

var
  exit_save:pointer;


{Macro to disable interrupts.}

Procedure disable_interrupts;
Begin
{rcg11172000 not needed under Linux.}
(*
  Inline($FA);  {CLI}
*)
End;


{Macro to enable interrupts.}

Procedure enable_interrupts;
Begin
{rcg11172000 not needed under Linux.}
(*
  Inline($FB);  {STI}
*)
End;


{Interrupt driver.  The UART is programmed to cause an interrupt whenever
a character has been received or when the UART is ready to transmit another
character.}

{rcg11172000 not needed under Linux.}
{$S-}
(*
procedure com_interrupt_driver; interrupt;
var ch:char;
    dummy,iir:byte;
begin
  if (usefossil) then exit;
    { while bit 0 of the interrupt identification register is 0,
      there is an interrupt to process }
  iir:=port[uart_iir];

  while (not odd(iir)) do begin
    case (iir shr 1) of
        { IIR = 100b: Received data available.  Get the character,
          and if the buffer isn't full, then save it.
          If the buffer is full, then ignore it. }
      2:begin
          ch:=char(port[uart_data]);
          if (rx_chars<=rx_queue_size) then begin
            rx_queue[rx_in]:=ord(ch);
            inc(rx_in);
            if (rx_in>rx_queue_size) then rx_in:=1;
            rx_chars:=succ(rx_chars);
          end;
        end;

        { IIR = 010b: Transmit register empty.  If the transmit buffer
          is empty, then disable the transmitter to prevent any more
          transmit interrupts.  Otherwise, send the character.

          The test of the line-status-register is to see if the transmit
          holding register is truly empty.  Some UARTS seem to cause
          transmit interrupts when the holding register isn't empty,
          causing transmitted characters to be lost. }
      1:if (tx_chars<=0) then
          port[uart_ier]:=port[uart_ier] and not 2
        else
          if (odd(port[uart_lsr] shr 5)) then begin
            port[uart_data]:=tx_queue[tx_out];
            inc(tx_out);
            if (tx_out>tx_queue_size) then tx_out:=1;
            dec(tx_chars);
          end;

        { IIR = 001b: Change in modem status.  We don't expect
          this interrupt, but if one ever occurs we need to read
          the line status to reset it and prevent an endless loop. }
      0:dummy:=Port [uart_msr];

        { IIR = 111b: Change in line status.  We don't expect
          this interrupt, but if one ever occurs we need to read the
          line status to reset it and prevent an endless loop. }
      3:dummy:=port[uart_lsr];

    end;

    iir:=port[uart_iir];
  end;

    { tell the interrupt controller that we're done with this interrupt }
  port[$20]:=$20;
end;
*)
{$S+}


  { flush (empty) the receive buffer. }
procedure com_flush_rx;
var ch:char;
begin
{rcg11172000 not needed under Linux.}
{
  if (usefossil) then begin
    regs.dx:=fosport;
    regs.ah:=$0A;
    intr($14,regs);
    exit;
  end;
  disable_interrupts;
}
  rx_chars:=0; rx_in:=1; rx_out:=1;
{
enable_interrupts;
}
end;

  { flush (empty) transmit buffer. }
procedure com_flush_tx;
begin
{rcg11172000 not needed under Linux.}
{
  if (usefossil) then begin
    regs.dx:=fosport;
    regs.ah:=$08;
    intr($14,regs);
    exit;
  end;
  disable_interrupts;
}

  tx_chars:=0; tx_in:=1; tx_out:=1;

{
enable_interrupts;
}
end;

  { purge (empty) transmit buffer. }
procedure com_purge_tx;
begin
{rcg11172000 not needed under Linux.}
{
  if (not usefossil) then com_flush_tx else begin
    regs.dx:=fosport;
    regs.ah:=$09;
    intr($14,regs);
  end;
}
end;

  { this function returns TRUE if a carrier is present. }
function com_carrier:boolean;
begin
{rcg11172000 not needed under Linux.}
{
  if (usefossil) then begin
    regs.dx:=fosport;
    regs.ah:=$03;
    intr($14,regs);
    if (regs.ax and $0080) = 0 then
      com_carrier:=FALSE
    else
      com_carrier:=TRUE;
    exit;
  end;
  com_carrier:=((com_installed) and (odd (port[uart_msr] shr 7)));
}

  {rcg11172000 temp return:} com_carrier := false;
end;

  { get a character from the receive buffer.
    If the buffer is empty, return NULL (#0). }
function com_rx:char;
begin
{rcg11172000 not needed under Linux.}
{
  if (usefossil) then begin
    if (com_rx_empty) then com_rx:=#0
    else begin
      regs.dx:=fosport;
      regs.ah:=$02;
      intr($14,regs);
      com_rx:=chr(regs.al);
    end;
    exit;
  end;
  if ((not com_installed) or (rx_chars=0)) then
    com_rx:=#0
  else begin
    disable_interrupts;
    com_rx:=chr(rx_queue[rx_out]);
    inc(rx_out);
    if (rx_out>rx_queue_size) then rx_out:=1;
    dec(rx_chars);
    enable_interrupts;
  end;
}
  {rcg11172000 temp return:} com_rx := #0;
end;

  { this function returns TRUE if com_tx can accept a character. }
function com_tx_ready: Boolean;
begin
{rcg11172000 not needed under Linux.}
{
  if (usefossil) then begin
    com_tx_ready:=TRUE;
    exit;
  end;
  com_tx_ready:=((tx_chars<tx_queue_size) or (not com_installed));
}

  {rcg11172000 temp return:} com_tx_ready := TRUE;
end;

  { this function returns TRUE if the transmit buffer is empty. }
function com_tx_empty:boolean;
begin
{rcg11172000 not needed under Linux.}
{
  if (usefossil) then begin
    regs.dx:=fosport;
    regs.ah:=$03;
    intr($14,regs);
    com_tx_empty:=((regs.ax and $4000) <> 0);
    exit;
  end;
  com_tx_empty:=((tx_chars=0) or (not com_installed));
}

  {rcg11172000 temp return:} com_tx_empty := TRUE;
end;

  { this function returns TRUE if the receive buffer is empty. }
function com_rx_empty:boolean;
begin
{rcg11172000 not needed under Linux.}
{
  if (usefossil) then begin
    regs.dx:=fosport;
    regs.ah:=$0C;
    intr($14,regs);
    com_rx_empty:=(regs.ax = $FFFF);
    exit;
  end;
  com_rx_empty:=((rx_chars=0) or (not com_installed));
}
  {rcg11172000 temp return:} com_rx_empty := TRUE;
end;

  { send a character.  Waits until the transmit buffer isn't full,
    then puts the character into it.  The interrupt driver will
    send the character once the character is at the head of the
    transmit queue and a transmit interrupt occurs. }
procedure com_tx(ch:char);
var result:word;
begin
{rcg11172000 not needed under Linux.}
{
  if (usefossil) then begin
    regs.dx:=fosport;
    regs.al:=ord(ch);
    regs.ah:=$01;
    intr($14,regs);
    exit;
  end;
  if (com_installed) then begin
    repeat until (com_tx_ready);
    disable_interrupts;
    tx_queue[tx_in]:=ord(ch);
    if (tx_in<tx_queue_size) then inc(tx_in) else tx_in:=1;
    inc(tx_chars);
    port[uart_ier]:=port[uart_ier] or 2;
    enable_interrupts;
  end;
}
end;

  { send a whole string }
procedure com_tx_string(st:string);
var i:byte;
    result:word;
begin
{rcg11172000 not needed under Linux.}
{
  for i:=1 to length(st) do com_tx(st[i]);
}
end;

  { lower (deactivate) the DTR line.  Causes most modems to hang up. }
procedure com_lower_dtr;
begin
{rcg11172000 not needed under Linux.}
{
  if (usefossil) then begin
    regs.dx:=fosport;
    regs.al:=$00;
    regs.ah:=$06;
    intr($14,regs);
    exit;
  end;
  if (com_installed) then begin
    disable_interrupts;
    port[uart_mcr]:=port[uart_mcr] and not 1;
    enable_interrupts;
  end;
}
end;

  { raise (activate) the DTR line. }
procedure com_raise_dtr;
begin
{rcg11172000 not needed under Linux.}
{
  if (usefossil) then begin
    regs.dx:=fosport;
    regs.al:=$01;
    regs.ah:=$06;
    intr($14,regs);
    exit;
  end;
  if (com_installed) then begin
    disable_interrupts;
    port[uart_mcr]:=port[uart_mcr] or 1;
    enable_interrupts;
  end;
}
end;

  { set the baud rate.  Accepts any speed between 2 and 65535.  However,
    I am not sure that extremely high speeds (those above 19200) will
    always work, since the baud rate divisor will be six or less, where a
    difference of one can represent a difference in baud rate of
    3840 bits per second or more. }
procedure com_set_speed (speed: Word);
var divisor:word;
begin
{rcg11172000 not needed under Linux.}
{
  if (usefossil) then begin
    regs.dx:=fosport;
    case speed of
      300:regs.al:=(2 shl 5)+3;
      600:regs.al:=(3 shl 5)+3;
      1200:regs.al:=(4 shl 5)+3;
      2400:regs.al:=(5 shl 5)+3;
      4800:regs.al:=(6 shl 5)+3;
      9600:regs.al:=(7 shl 5)+3;
      19200:regs.al:=(0 shl 5)+3;
      38400:regs.al:=(1 shl 5)+3;
    end;
    regs.ah:=$00;
    intr($14,regs);
    exit;
  end;
  if (com_installed) then begin
    if (speed<2) then speed:=2;
    divisor:=115200 div speed;
    disable_interrupts;
    port[uart_lcr]:=port[uart_lcr] or $80;
    portw[uart_data]:=divisor;
    port[uart_lcr]:=port[uart_lcr] and not $80;
    enable_interrupts;
  end;
}
end;

  { Set the parity and stop bits as follows:

     com_none    8 data bits, no parity
     com_even    7 data bits, even parity
     com_odd     7 data bits, odd parity
     com_zero    7 data bits, parity always zero
     com_one     7 data bits, parity always one }
procedure com_set_parity(parity:com_parity; stop_bits:byte);
var lcr:byte;
begin
{rcg11172000 not needed under Linux.}
{
  if (usefossil) then exit;
  case parity of
    com_none:lcr:=$00 or $03;
    com_even:lcr:=$18 or $02;
    com_odd:lcr:=$08 or $02;
    com_zero:lcr:=$38 or $02;
    com_one:lcr:=$28 or $02;
  end;
  if (stop_bits=2) then lcr:=lcr or $04;
  disable_interrupts;
  port[uart_lcr]:=port[uart_lcr] and $40 or lcr;
  enable_interrupts;
}
end;

  { Install the communications driver.  Portnum should be 1..max_port.
    Error codes returned are:

      0 - No error
      1 - Invalid port number
      2 - UART for that port is not present
      3 - Already installed, new installation ignored }

procedure com_install(portnum:word; var error:word; dofossil:boolean);
var ier:byte;
begin
{rcg11172000 not needed under Linux.}
(*
  if ((dofossil) and (not usefossil)) then begin
    usefossil:=FALSE;
    fosport:=portnum-1;
    regs.dx:=fosport;
    regs.ah:=$04;
    intr($14,regs);
    if (regs.ax = $1954) then begin
      usefossil:=TRUE;
      regs.dx:=fosport;
      regs.al:=$F0;
      regs.ah:=$0F;
      intr($14,regs);
    end;
  end;
  if (usefossil) then exit;
  if (com_installed) then error:=3
  else
    if ((portnum<1) or (portnum>max_port)) then error:=1
    else begin
        { set i/o addresses and other hardware specifics for selected port}
      uart_data:=uart_base [portnum];
      uart_ier:=uart_data+1;
      uart_iir:=uart_data+2;
      uart_lcr:=uart_data+3;
      uart_mcr:=uart_data+4;
      uart_lsr:=uart_data+5;
      uart_msr:=uart_data+6;
      uart_spr:=uart_data+7;
      intnum:=intnums[portnum];
      i8259bit:=1 shl i8259levels[portnum];

        { return error if hardware not installed }

      old_ier:=port[uart_ier];
      port[uart_ier]:=0;
      if (port[uart_ier]<>0) then error:=2
      else begin
        error:=0;

          { save original interrupt controller mask, then disable the
            interrupt controller for this interrupt. }
        disable_interrupts;
        old_i8259_mask:=port[$21];
        port[$21]:=old_i8259_mask or i8259bit;
        enable_interrupts;

          { clear the transmit and receive queues}
        com_flush_tx;
        com_flush_rx;

          { Save current interrupt vector, then set the interrupt
            vector to the address of our interrupt driver. }

        getintvec(intnum,old_vector);
        setintvec(intnum,@com_interrupt_driver);
        com_installed:=TRUE;

          { set parity to none, turn off BREAK signal, and make sure
            we're not addressing the baud rate registers. }
        port[uart_lcr]:=3;

          { save original contents of modem control register, then enable
            interrupts to system bus and activate RTS.  Leave DTR the way
            it was. }
        disable_interrupts;
        old_mcr:=port[uart_mcr];
        port[uart_mcr]:=$A or (old_mcr and 1);
        enable_interrupts;

          { enable interrupt on data-available.  The interrupt for
            transmit-ready is enabled when a character is put into the
            transmit queue, and disabled when the transmit queue is empty. }
        port[uart_ier]:=1;

          { enable the interrupt controller for this interrupt. }
        disable_interrupts;
        port[$21]:=port[$21] and not i8259bit;
        enable_interrupts;

      end;
    end;
*)
end;


  { Deinstall the interrupt driver completely.  It doesn't change
    the baud rate or mess with DTR; it tries to leave the interrupt
    vectors and enables and everything else as it was when the driver
    was installed.

    This procedure MUST be called by the exit procedure of this
    module before the program exits to DOS, or the interrupt driver
    will still be attached to its vector -- the next communications
    interrupt that came along would jump to the interrupt driver which
    is no longer protected and may have been written over. }
procedure com_deinstall;
begin
{rcg11172000 not needed under Linux.}
(*
  if (usefossil) then begin
    usefossil:=FALSE;
    regs.dx:=fosport;
    regs.ah:=$05;
    intr($14,regs);
    exit;
  end;
  if (com_installed) then begin
    com_installed:=FALSE;

      { restore Modem-Control-Register and Interrupt-Enable-Register. }
    port[uart_mcr]:=old_mcr;
    port[uart_ier]:=old_ier;

      { restore appropriate bit of interrupt controller's mask }
    disable_interrupts;
    port[$21]:=port[$21] and not i8259bit or old_i8259_mask and i8259bit;
    enable_interrupts;

      { reset the interrupt vector }
    setintvec(intnum,old_vector);
  end;
*)
end;

  { This procedure is called when the program exits for any reason.  It
    deinstalls the interrupt driver.}
{$F+} procedure exit_procedure; {$F-}
begin
{rcg11172000 not needed under Linux.}
{
  com_deinstall;
  exitproc:=exit_save;
}
end;

  { This installs the exit procedure. }
begin
{rcg11172000 not needed under Linux.}
{
  exit_save:=exitproc;
  exitproc:=@exit_procedure;
}
end.

