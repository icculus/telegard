unit newcom;
                                                                                { which will be used to tell }
{ Written by:  Kevin R. Bulgrien           Version 1.00 completed 11/11/88    } { what the program is doing  }
{                                                                             } { where its not self-evident }
{ Contact at:  LeTourneau College          LeTourneau College BBS             } {                            }
{              Microcomputer Services      2400/1200/300 Baud                 } { Yes, it is wider than 80   }
{              P.O. Box 7001               (214) 237-2742                     } { columns so you will need   }
{              Longview, TX  75607                                            } { to use compressed print to }
{                                                                             } { print it out.              }
{ This program works with Turbo Pascal 4.0 and 5.0.  See Comm_TP4.DOC for the } {                            }
{ instructions.  Comm_TP3, by the same author, works under Turbo Pascal 3.0.  } { Don't complain too much as }
                                                                                { code documentation is far  }
interface

USES DOS, CRT;                                                                  { easier to read when it is  }
                                                                                { done like this...          }
CONST                                                                           {                            }
(*  MaxSize = 511;                                                                {-Maximum input buffer size  }*)
  maxsize = 5120;
                                                                                {                            }
TYPE                                                                            {-8250 Communications Chip   }
  INS8250 = RECORD                                                              { -------------------------- }
              THR : INTEGER;                                                    { Transmit Holding Register  }
              RHR : INTEGER;                                                    { Receive Holding Register   }
              DLL : INTEGER;                                                    { Divisor Latch Register LSB }
              IER : INTEGER;                                                    { Interrupt Enable Register  }
              DLM : INTEGER;                                                    { Divisor Latch Register MSB }
              IIR : INTEGER;                                                    { Interrupt ID Register      }
              LCR : INTEGER;                                                    { Line Control Register      }
              MCR : INTEGER;                                                    { Modem Control Register     }
              LSR : INTEGER;                                                    { Line Status Register       }
              MSR : INTEGER;                                                    { Modem Status Register      }
            END;                                                                {                            }
                                                                                {                            }
  ComSettingsRecord = RECORD                                                    {-Used to hold the current   }
                       Baud : BYTE;                                             { settings of COM1 or COM2   }
                       Parity : BYTE;                                           {                            }
                       Stop : BYTE;                                             {                            }
                       Bits : BYTE;                                             {                            }
                     END;                                                       {                            }
                                                                                {                            }
  ComSettingsType = ARRAY [1..2] OF ComSettingsRecord;                          {-COM1 & COM2 Settings       }
                                                                                {                            }
  BaudType = (B110,B150,B300,B600,B1200,B2400,B4800,B9600,B19200,B38400);       {-Baud rates supported       }
                                                                                {                            }
  ParityType = (None, Odd, Null, Even, MarkOff, Mark, SpaceOff, Space);         {-Parity types supported     }
                                                                                {                            }
  ComBuffersType = ARRAY [1..2, 0..MaxSize] OF BYTE;                            {-The input buffers for COM1 }
                                                                                { and COM2                   }
  outbuffer=string[255];

const
  RS232 : ARRAY [1..2] OF INS8250 = ( ( THR:$3F8; RHR:$3F8; DLL:$3F8;           {-COM1 addresses of the 8250 }
                                        IER:$3F9; DLM:$3F9; IIR:$3FA;           { registers so that they may }
                                        LCR:$3FB; MCR:$3FC; LSR:$3FD;           { be accessed by name.       }
                                        MSR:$3FE ),                             {                            }
                                      ( THR:$2F8; RHR:$2F8; DLL:$2F8;           {-COM2 addresses of the 8250 }
                                        IER:$2F9; DLM:$2F9; IIR:$2FA;           { registers so that they may }
                                        LCR:$2FB; MCR:$2FC; LSR:$2FD;           { be accessed by name        }
                                        MSR:$2FE ) );                           {                            }
                                                                                {                            }
var                                                                             {                            }
  intinstalled:array[1..2] of boolean;                                          {-TRUE if interrupt in place }
  oldintvector:array[1..2] of pointer;                                          {-Original COMx int. vectors }
  inhead,intail:array[1..2] of word;                                            {-Input buffer pointers      }
  carrier:array[1..2] of boolean;                                               {-TRUE if Carrier Detected   }
  comsettings:comsettingstype;                                                  {-COM1 & COM2 line settings  }
  inbuffer:combufferstype;                                                      {-Input circular queue buffer}
  exitsave:pointer;                                                             {-Saves original ExitProc    }
  maxports:word;                                                                {-Number of usable COM ports }
  regs:registers;                                                               {-8088 CPU Registers         }
  currentcom:byte;                                                              {-COM port currently logged  }
  mpcoder:boolean;
  mpcode:array[1..6] of byte;
                                                                                {                            }
procedure setuprs232(com,baud,parity,databits,stopbits:byte);
procedure installint(com:byte);
procedure removeint(com:byte);
procedure comsend1(com:byte; c:char);
procedure writecom(com:byte; data:outbuffer);
function readcom(com:byte):char;
procedure tty(localecho:boolean);

implementation

{rch11172000 not under Linux...}
(*
PROCEDURE DisableInts; INLINE ($FA);                                            {-Disable hardware interrupts}
PROCEDURE EnableInts; INLINE ($FB);                                             {-Enable hardware interrupts }
*)

PROCEDURE DisableInts;
begin
end;

PROCEDURE EnableInts;
begin
end;


{                            }
{ This procedure sets up the selected COM port to the specified parameters.  The Com parameter specifies the }
{ port to set up.  It must be in the range 1 to 2, and is checked for errors.  The Baud parameter is must be }
{ in the range 0 to 9, and is not range checked.  The TYPE BaudTable is included only to document the baud   }
{ rates supported in BaudTable.  I.E. BaudTable [1] refers to 150 Baud.  It is unneccessary for any other    }
{ purpose.  In the same manner, ParityType is provide to document the parity settings allowed.  Use ORD() to }
{ get the correct BYTE value to pass:  ORD(B110) returns the BYTE that selects 110 baud and ORD(None) gives  }
{ the BYTE that selects no parity. (Use global declarations of these TYPEs for these examples to work.)  1.5 }
{ stop bits are used when StopBits = 2 AND DataBits = 5, but otherwise StopBits will set the correct number  }
{ of stop bits in the range 1 to 2.  DataBits may be set with 5 to 8 for the number of data bits to use.     }
{                                                                                                            }
{ Mark parity means that parity is enabled and the parity bit is always set to 0.  Space parity means that   }
{ parity is enabled and the parrity bit is always set to 1.  MarkOff and SpaceOff indicate that Mark or Space}
{ parity is chosen but parity is disabled.  Functionally they are equivalent to NONE - as is NULL.           }
                                                                                {                            }
procedure setuprs232(com,baud,parity,databits,stopbits:byte);                   {                            }
const                                                                           {-These values set the baud  }
  baudtable:array[0..9] of word=($0417,$0300,$0180,$00C0,$0060,                 { rate of the 8250 when they }
                                 $0030,$0018,$000C,$0006,$0003);                { are written to DLL & DMM.  }
type                                                                            {                            }
  baudtype=(b110,b150,b300,b600,b1200,b2400,b4800,b9600,b19200,b38400);         {-Baud rates supported       }
  paritytype=(pnone,podd,pnull,peven,pmarkoff,pmark,pspaceoff,pspace);                  {-Parity settings supported  }
var parameters:byte;                                                            {-Temporary variable to hold }
                                                                                { correct LCR register value }
begin
  disableInts;                                                                {-Always when writing to 8250}
  port[rs232[com].MCR]:=$00;                                                  {-DTR & RTS off while setting}
  port[rs232[com].LCR]:=port[rs232[com].LCR] or $80;                          {-Allow access to DLL & DLM  }
  port[rs232[com].DLL]:=lo(baudtable[baud]);                                  {-Set the baud rate          }
  port[rs232[com].DLM]:=hi(baudtable[baud]);                                  {                            }
  parameters:=(databits-5) and $03;                                           {-Build the value to write   }
  parameters:=parameters or (((stopbits-1) shl 2) and $04);                   { to Line Control Register.  }
  parameters:=parameters or ((parity shl 3) and $38);                         {                            }
  port[rs232[com].LCR]:=parameters;                                           {-Set parity, data/stop bits }
  port[rs232[com].MCR]:=$0B;                                                  {-DTR & RTS back on          }
  EnableInts;                                                                 {-Done writing to 8250 regs. }
end;                                                                            {                            }
                                                                                {                            }
{ This procedure handles all interrupts from the 8250 communications chip.  All interrupt types are provided }
{ for even though I only implemented the receive data interrupt and crudely used the modem status interrupt. }
{ The skeleton is there though, so you can write your own implementations for the interrupts.  Incoming data }
{ is stored in InBuffer if the buffer is not full - otherwise it is ignored. The buffer is full when (InTail }
{ + 1) MOD (MaxSize + 1) = InHead.  The buffer is empty when InTail = InHead.  InTail is incremented so that }
{ it always points to where the next item will be put.  Modem (port) status is monitored for Carrier Detect. }
{ The global BOOLEAN variable 'Carrier' always shows the status of each COM port if its interrupt handler is }
{ active.  TRUE = Carrier Detected and FALSE = No Carrier Detected.  This is done for programs that will use }
{ a modem for input.                                                                                         }
                                                                                {                            }
function iii(intcom:byte; i:integer):byte;
var j:integer;
begin
  j:=intail[intcom]-i;
  if (j<0) then inc(j,maxsize+1);
  iii:=inbuffer[intcom,j];
end;

procedure checkitout(intcom:integer);
var i:integer;
begin
  if ((iii(intcom,1)=254) and (iii(intcom,2)=253)) then
    if ((iii(intcom,9)=1) and (iii(intcom,10)=2) and
        (iii(intcom,11)=1)) then begin
      mpcoder:=TRUE;
      for i:=1 to 6 do mpcode[7-i]:=iii(intcom,i+2);
      inhead[intcom]:=intail[intcom];
    end;
end;

{$F+}                                                                           {-Interrupt handlers MUST be }
procedure inthandler; interrupt;                                                { FAR calls.                 }
{$F-}                                                                           {                            }
var                                                                             {-The COMx port which is to  }
  intcom:byte;                                                                  { be used.                   }
begin                                                                           {                            }
  PORT [$20] := $0B;                                                            {-Allow access to 8259 ISR   }
  intcom:=3-((port[$20] and $18) shr 3);                                        {-Detect interrupting port   }
  CASE PORT [RS232 [IntCom].IIR] AND $06 OF                                     {                            }
    0 : begin                                                                   {-Modem Status Change Int.   }
          carrier[intcom]:=($80 and port[rs232[intcom].MSR]=$80);               {-Save status of Carrier     }
        end;
    2 : begin                                                                   {-Transmit Register Empty    }
        end;
    4 : begin
          disableints;
          port[rs232[intcom].LCR]:=port[rs232[intcom].LCR] and $7F;             {-Allow THR,RBR & IER access }
          if (intail[intcom]+1) mod (maxsize+1)<>inhead[intcom] then begin      {-If the buffer is not full, }
            inbuffer[intcom,intail[intcom]]:=port[rs232[intcom].RHR];           { add the character and set  }
(*            if ((iii(intcom,0)=255) and (not mpcoder)) then checkitout(intcom);*)
            intail[intcom]:=(intail[intcom]+1) mod (maxsize+1);                 { the queue buffer pointer   }
          end else                                                              {-If the buffer is full, the }
            if (port[rs232[intcom].RHR]=$00) then { DO Nothing };               { data is read & not stored  }
          enableints;
        end;
    6 : begin                                                                   {-Line Status change & Error }
        end;
  END;
  PORT [$20] := $20;                                                            {-Notify 8259 that interrupt }
END;                                                                            { has been completed.        }

{ This procedure installs and enables the specified serial port interrupt.  It also forces the appropriate   }
{ input buffer to the empty state.  Carrier is initialized to the current state of the Carrier Detect line   }
{ on the port.  The old serial port interrupt vector is saved so that it can be reinstalled when we remove   }
{ our serial port interrupt.  DTR and RTS are forced to the ready state and the 8250 interrupts are enabled  }
{ by writing $0B to the MCR.  To enable all four types of 8250 interrupts, write $0F to the IER.  (I enabled }
{ the Modem Status Change and Receive Buffer Full interrupts by writing $09 to the IER). ORing $EF with PORT }
{ [$21] enables IRQ4 (COM1), while ORing $F7 enables IRQ3 (COM2).  Hardware interrupts should be disabled    }
{ during the installation process since the 8250 & 8259 ports are being accessed. }

procedure installint(com:byte);
begin
  if (intinstalled[com]) then removeint(com);

  disableints;
  InTail [com]:=0;                                                     {-Set input buffer to empty  }
  InHead [com]:=0;
  Carrier [Com] := ($80 AND PORT [RS232 [Com].MSR] = $80);             {-Read Carrier Detect status }
  PORT [RS232 [Com].LCR] := PORT [RS232 [Com].LCR] AND $7F;            {-Allow THR,RBR & IER access }
  PORT [RS232 [Com].IER] := $00;                                       {-Disable 8250 interrupts    }
  IF PORT [RS232 [Com].LSR] <> 0 THEN { Nothing };                     {-Reset interrupts that were }
  IF PORT [RS232 [Com].RHR] <> 0 THEN { Nothing };                     { waiting to be processed    }
  GETINTVEC ($0D - Com, OldIntVector [Com]);                           {-Save old interrupt vector  }
  SETINTVEC ($0D - Com, @IntHandler);                                  {-Load new interrupt vector  }
  IntInstalled [Com] := TRUE;                                          {-The interrupt is installed }
  CASE Com OF
    1 : PORT [$21] := PORT [$21] AND $EF;                              {-Enable 8259 IRQ4 handling  }
    2 : PORT [$21] := PORT [$21] AND $F7;                              {-Enable 8259 IRQ3 handling  }
  END;
  PORT [RS232 [Com].LCR] := PORT [RS232 [Com].LCR] AND $7F;            {-Allow THR,RBR & IER access }
  PORT [RS232 [Com].IER] := $01;                                       {-Enable 8250 interrupts     }
  PORT [RS232 [Com].MCR] := $0B;                                       {-Set DTR & RTS so the other }
  EnableInts;                                                          { device knows we are ready  }
END;

{ This procedure removes the specified serial port interrupt and reinstalls the original interrupt vectors.  }
{ DTR & RTS are set OFF and 8250 interrupts are disabled by writing $00 to the MCR. All 8250 interrupt types }
{ are disabled by writing $00 to the IER.  ANDing $10 with PORT [$21] disables IRQ4 (COM1), while ANDing $08 }
{ disables IRQ3 (COM2).  Hardware interrupts must be disabled during this process.                           }
PROCEDURE RemoveInt (Com : BYTE);
BEGIN
           DisableInts;
           CASE Com OF
             1 : PORT [$21] := PORT [$21] AND $10;                              {-Disable 8259 IRQ4 handling }
             2 : PORT [$21] := PORT [$21] AND $08;                              {-Disable 8259 IRQ3 handling }
           END;
           PORT [RS232 [Com].LCR] := PORT [RS232 [Com].LCR] AND $7F;            {-Allow THR,RBR & IER access }
           PORT [RS232 [Com].IER] := $00;                                       {-Disable 8250 interrupts    }
           PORT [RS232 [Com].MCR] := $00;                                       {-Set DTR & RTS off          }
           SETINTVEC ($0D - Com, OldIntVector [Com]);                           {-Load old interrupt vector  }
           IntInstalled [Com] := FALSE;                                         {-The interrupt is removed   }
           EnableInts;
(*         END
    ELSE BEGIN                                                                  {-Mostly here for debugging  }
           WRITE (#13, #10, 'Error!  COM', Com, ' ');                           { purposes.  Remove in your  }
           WRITELN ('interrupt is not installed', #10);                         { program if you wish.       }
         END;*)
END;

{ This procedure writes character or string data to the serial port.  It does this by directly reading and   }
{ writing to the 8250 communications chip.  This is an example that may be modified to suit your purposes.   }
{ As is, it pauses the program while it sends the data.  If it cannot send a character after 65535 tries, it }
{ aborts the sending process.  This could easily be converted to a FUNCTION that returns the BOOLEAN value   }
{ TimeOut.  The statement: (PORT [RS232 [Com].LSR] AND $20) <> $20 indicates when the THR is ready for a new }
{ character to send.  CTS and DSR are not checked, but if you want to check for them (PORT [RS232 [Com].MSR] }
{ AND $30) must equal $30.  Interrupts must be disabled while using the 8250 port registers.                 }

procedure writecom(com:byte; data:outbuffer);
var
 LoopVar,                                                                       {-Pointer to output char     }
 TimeLoop : WORD;                                                               {-Timeout counter variable   }
 TimeOut : BOOLEAN;                                                             {-True if unable to send     }
BEGIN
  LoopVar := 0;
  TimeOut := FALSE;
  WHILE (LoopVar < LENGTH (Data)) AND NOT TimeOut DO                            {-Send the data one char at  }
    BEGIN                                                                       { a time unless the port was }
      TimeLoop := 0;                                                            { timed out.                 }
      inc(loopvar);
      WHILE (TimeLoop < 65535) AND ((PORT [RS232 [Com].LSR] AND $20) <> $20) DO {-Do not try to send data if }
        inc(timeloop);                                                          { the THR is not empty yet.  }
      IF TimeLoop <> 65535
        THEN BEGIN
               DisableInts;
               PORT [RS232 [Com].LCR] := PORT [RS232 [Com].LCR] AND $7F;        {-Allow THR,RBR & IER access }
               PORT [RS232 [Com].THR] := ORD (Data [LoopVar]);                  {-Put the data to send in    }
               EnableInts;                                                      { the THR                    }
             END
        ELSE BEGIN
               TimeOut := TRUE;                                                 {-WriteCOM aborts if the THR }
               WRITELN (#13,#10, 'Timeout on COM', Com);                        { takes too long to become   }
             END;                                                               { empty so you can send more }
    END;                                                                        { data                       }
END;

procedure comsend1(com:byte; c:char);
var timeloop:word;
begin
  timeloop:=0;
  while ((timeloop<65535) and ((port[rs232[com].LSR] and $20)<>$20)) do
    inc(timeloop);
  if (timeloop<>65535) then begin
{    disableints;}
{    port[rs232[com].LCR]:=port[rs232[com].LCR] and $7F;}
    port[rs232[com].THR]:=ord(c);
{    enableints;}
  end; {else
    writeln(^M^J+'Timeout on COM',com);}
end;

{ This function is an example of how to get a character from the serial port. As is, if the buffer is empty, }
{ it waits until a character arrives, so this will not work for the TTY emulation. The interrupts are always }
{ disabled when the buffer pointers are checked or modified.  Beware!  Do not completely disable interrupts  }
{ in the wait loop or else you never will get a character if there is not one there already.                 }
                                                                                {                            }
FUNCTION ReadCOM (Com : BYTE) : CHAR;                                           {                            }
VAR                                                                             {                            }
  CharReady : BOOLEAN;                                                          {-TRUE if there is data in   }
BEGIN                                                                           { the input buffer           }
  CharReady := FALSE;                                                           {                            }
  REPEAT                                                                        {-Wait for data to arrive    }
    DisableInts;                                                                {                            }
    CharReady := InTail [Com] <> InHead [Com];                                  {-Check to see if buffer is  }
    EnableInts;                                                                 { empty                      }
  UNTIL CharReady;                                                              {                            }
  DisableInts;                                                                  {                            }
  ReadCOM := CHR(InBuffer [Com, InHead [Com]]);                                 {-Read a character of data   }
  InHead [Com] := (InHead [Com] + 1) MOD (MaxSize + 1);                         {-Update the buffer pointer  }
  EnableInts;                                                                   {                            }
END;                                                                            {                            }
                                                                                {                            }
{ End of RS-232 handler routines ----------- Start of TTY emulation routines }  { Example TTY program starts }
                                                                                {                            }



{ A crude but effective procedure to allow the user to change settings of a COM port in use.  CurrentCom and }
{ ComSettings determine how the port is currently set up. As the parameters are changed, ComSettings is also }
{ updated.  Once again, keep in mind that the object of this program is not to provide a glamorous terminal  }
{ program.  Rather it serves as a simple model for those wanting to incorporate serial routines in their own }
{ programs.                                                                                                  }
                                                                                {                            }
PROCEDURE SetUpPort (Com : BYTE);                                               {                            }
VAR                                                                             {                            }
  ResetPort : BOOLEAN;                                                          {-TRUE when settings changed }
  InkeyChr : CHAR;                                                              {-Keyboard input variable    }
BEGIN                                                                           {                            }
  WRITELN;                                                                      {                            }
  ResetPort := FALSE;                                                           {                            }
  WRITELN ('COM', Com, ' Setup', #10);                                          {-Select a baud rate         }
  WRITELN ('0)  110           5)  2400');                                       {                            }
  WRITELN ('1)  150           6)  4800');                                       {-Note that defaults are     }
  WRITELN ('2)  300           7)  9600');                                       { allowed if you press <CR>  }
  WRITELN ('3)  600           8) 19200');                                       { at any of the prompts. The }
  WRITELN ('4) 1200           9) 38400', #10);                                  { port is not reset unless   }
  WRITE ('Select a baud rate [', ComSettings [Com] . Baud, ']: ');              { the defaults are changed.  }
  REPEAT                                                                        {                            }
    InkeyChr := READKEY;                                                        {                            }
  UNTIL (InkeyChr IN ['0'..'9', #13]);                                          {                            }
  WRITELN (InkeyChr, #10);                                                      {                            }
  IF (InkeyChr <> #13)                                                          {                            }
    THEN BEGIN                                                                  {                            }
           ComSettings [Com] . Baud := ORD (InkeyChr) - 48;                     {                            }
           ResetPort := TRUE;                                                   {                            }
         END;                                                                   {                            }
  WRITELN ('0) None           2) None');                                        {-Select a parity setting    }
  WRITELN ('1) Odd            3) Even', #10);                                   {                            }
  WRITE ('Select a parity type [', ComSettings [Com] . Parity, ']: ');          {                            }
  REPEAT                                                                        {                            }
    InkeyChr := READKEY;                                                        {                            }
  UNTIL (InkeyChr IN ['0'..'3', #13]);                                          {                            }
  WRITELN (InkeyChr, #10);                                                      {                            }
  IF (InkeyChr <> #13)                                                          {                            }
    THEN BEGIN                                                                  {                            }
           ComSettings [Com] . Parity := ORD(InkeyChr) - 48;                    {                            }
           ResetPort := TRUE;                                                   {                            }
         END;                                                                   {                            }
  WRITE ('Select number of stop bits [', ComSettings [Com] . Stop, ']: ');      {-Select number of stop bits }
  REPEAT                                                                        {                            }
    InkeyChr := READKEY;                                                        {                            }
  UNTIL (InkeyChr IN ['1'..'2', #13]);                                          {                            }
  WRITELN (InkeyChr, #10);                                                      {                            }
  IF (InkeyChr <> #13)                                                          {                            }
    THEN BEGIN                                                                  {                            }
           ComSettings [Com] . Stop := ORD(InkeyChr) - 48;                      {                            }
           ResetPort := TRUE;                                                   {                            }
         END;                                                                   {                            }
  WRITE ('Select number of data bits [', ComSettings [Com] . Bits, ']: ');      {-Select number of data bits }
  REPEAT                                                                        {                            }
    InkeyChr := READKEY;                                                        {                            }
  UNTIL (InkeyChr IN ['5'..'8', #13]);                                          {                            }
  WRITELN (InkeyChr, #10);                                                      {                            }
  IF (InkeyChr <> #13)                                                          {                            }
    THEN BEGIN                                                                  {                            }
           ComSettings [Com] . Bits := ORD(InkeyChr) - 48;                      {                            }
           ResetPort := TRUE;                                                   {                            }
         END;                                                                   {                            }
  IF ResetPort                                                                  {-If the settings changed,   }
    THEN SetupRS232 (Com, ComSettings [Com] . Baud,                             { reset the port             }
                          ComSettings [Com] . Parity,                           {                            }
                          ComSettings [Com] . Stop,                             {                            }
                          ComSettings [Com] . Bits);                            {                            }
END;                                                                            {                            }
                                                                                {                            }
{ This provides a simple terminal emulation that might be used to prove that these routines really work, and }
{ that they are not hard to use.  I got to playing, and perhaps it got a bit more complex than necessary...  }
{ but then again, who said it had to be quick and dirty.  The LocalEcho parameter determines if characters   }
{ typed on the keyboard should be echoed to the screen.                                                      }
                                                                                {                            }
PROCEDURE TTY (LocalEcho : BOOLEAN);                                            {                            }
VAR                                                                             {                            }
  ExitTTY,                                                                      {-TRUE when ready to quit    }
  DataReady : BOOLEAN;                                                          {-TRUE if buffer not empty   }
  OldCarrier : ARRAY [1..2] OF BOOLEAN;                                         {-Helps detect carrier change}
  Buffer : CHAR;                                                                {-A character buffer         }
  i:integer;
BEGIN                                                                           {                            }
  OldCarrier [1] := NOT Carrier [1];                                            {-Make Carrier Detect Status }
  OldCarrier [2] := NOT Carrier [2];                                            { so it will be displayed    }
  DataReady := FALSE;                                                           {-Initialize everything      }
  ExitTTY := FALSE;                                                             {                            }
  Buffer := #0;                                                                 {                            }
  CLRSCR;                                                                       {                            }
  WRITELN ('Terminal emulator commands', #10);                                  {-Brief summary of command   }
  WRITELN ('<ALT C>  Toggle Port in use COM1/COM2');                            { keys that can be used      }
  WRITELN ('<Alt E>  Toggle Local Echo On/Off');                                {                            }
  WRITELN ('<Alt P>  Change Port Parameters');                                  {                            }
  WRITELN ('<Alt X>  Exit');                                                    {                            }
  REPEAT                                                                        {-Terminal emulation starts  }
    DisableInts;                                                                {                            }
    DataReady := (InTail [CurrentCom] <> InHead [CurrentCom]);                  {-If data has been received, }
    EnableInts;                                                                 { print one character        }
    IF DataReady                                                                {                            }
      THEN BEGIN                                                                { CHR(12) is interpreted as  }
             DisableInts;                                                       { a FormFeed, and so clears  }
             Buffer := CHR(InBuffer [CurrentCom, InHead [CurrentCom]]);         { the screen                 }
             InHead [CurrentCom] := (InHead [CurrentCom] + 1) MOD (MaxSize + 1);{                            }
             EnableInts;                                                        { Input buffer is updated    }
             CASE Buffer OF                                                     {                            }
               #12 : CLRSCR;                                                    {                            }
               ELSE  WRITE (Buffer);                                            {                            }
             END;                                                               {                            }
           END;                                                                 {                            }
    IF (OldCarrier [CurrentCom] <> Carrier [CurrentCom])                        {-If a change in carrier     }
      THEN BEGIN                                                                { detect occurs, notify the  }
             WRITELN;                                                           { user of the new status     }
             IF Carrier [CurrentCom]                                            {                            }
               THEN WRITELN ('CARRIER DETECTED (COM', CurrentCom, ')')          {                            }
               ELSE WRITELN ('NO CARRIER (COM', CurrentCom, ')');               {                            }
             OldCarrier [CurrentCom] := Carrier [CurrentCom];                   {                            }
           END;                                                                 {-If a key has been pressed, }
    IF KEYPRESSED                                                               { process it                 }
      THEN BEGIN                                                                {                            }
             Buffer := READKEY;                                                 {                            }
             IF (Buffer = #00) AND KEYPRESSED                                   {-Extended key codes require }
               THEN BEGIN                                                       { another read               }
                      Buffer := READKEY;                                        {                            }
                      CASE Buffer OF                                            {                            }
                        #46 : IF (1 + ORD (CurrentCom = 1)) <= MaxPorts         {-<ALT C> lets you toggle    }
                                THEN BEGIN                                      { between ports if the new   }
                                       CurrentCom := 1 + ORD (CurrentCom = 1);  { port exists                }
                                       WRITELN (#13,#10, 'COM', CurrentCom);    {                            }
                                     END                                        {                            }
                                ELSE BEGIN                                      {                            }
                                       WRITE (#13,#10, 'COM');                  {                            }
                                       WRITE (1 + ORD (CurrentCom = 1));        {                            }
                                       WRITELN (' not available');              {                            }
                                     END;                                       {                            }
                        #18 : LocalEcho := NOT LocalEcho;                       {-<ALT E> toggles Local Echo }
                        #25 : SetupPort (CurrentCom);                           {-<ALT P> allows port setup  }
                        #45 : ExitTTY := TRUE;                                  {-<ALT X> exits the program  }
                        ELSE  WriteCOM (CurrentCom, CHR(27) + Buffer);          {-Other extended key codes   }
                      END;                                                      { are sent to the port       }
                    END                                                         {                            }
               ELSE BEGIN                                                       {-Normal key codes are sent  }
                      CASE Buffer OF                                            { or translated and sent     }
                        #12 : BEGIN                                             {                            }
                                WriteCOM (CurrentCom, Buffer);                  {-FormFeed clears screen if  }
                                IF LocalEcho THEN CLRSCR;                       { local echo is on           }
                              END;                                              {                            }
                        #13 : BEGIN                                             {-A carriage return also     }
                                WriteCOM (CurrentCom, Buffer + CHR(10));        { sends a line feed          }
                                IF LocalEcho THEN WRITELN;                      {                            }
                              END;                                              {                            }
                        ELSE  BEGIN                                             {-All other characters are   }
                                WriteCOM (CurrentCom, Buffer);                  { sent as typed              }
                                IF LocalEcho THEN WRITE (Buffer);               {                            }
                              END;                                              {                            }
                      END;                                                      {                            }
                    END;                                                        {                            }
           END;                                                                 {                            }
  UNTIL ExitTTY;                                                                {-Continue emulation until   }
END;                                                                            { <ALT X> is pressed.        }
                                                                                {                            }
FUNCTION Equipment : WORD;                                                      {-This function returns what }
BEGIN                                                                           { equipment is present on    }
  INTR ($11, Regs);                                                             { the machine it is running  }
  Equipment := Regs.AX;                                                         { on.                        }
END;                                                                            {                            }
                                                                                {                            }
{$F+}                                                                           {-VERY IMPORTANT!  When the  }
PROCEDURE RemoveIntOnExit;                                                      { program quits normally or  }
{$F-}                                                                           { abnormally, the interrupt  }
BEGIN                                                                           { handlers are uninstalled   }
  IF IntInstalled [1]                                                           { if they are still set up.  }
    THEN RemoveInt (1);                                                         {                            }
  IF IntInstalled [2]                                                           {                            }
    THEN RemoveInt (2);                                                         {                            }
  ExitProc := ExitSave;                                                         {-Return control to the      }
END;                                                                            { original exit procedure    }
                                                                                {                            }
begin
  mpcoder:=FALSE;

(*
  ExitSave := ExitProc;                                                         {-VERY IMPORTANT!  This lets }
  ExitProc := @RemoveIntOnExit;                                                 { the program halt safely.   }
  MaxPorts := (Equipment AND $0E00) SHR 9;                                      {-Find # of system COM ports }
  IntInstalled [1] := FALSE;                                                    {-No interrupt handlers are  }
  IntInstalled [2] := FALSE;                                                    { installed on start up      }
  ComSettings [1] . Baud := ORD (B9600);                                        {-Define COM1 default setup  }
  ComSettings [1] . Parity := ORD (pNone);                                      {                            }
  ComSettings [1] . Stop := 1;                                                  {                            }
  ComSettings [1] . Bits := 8;                                                  {                            }
  ComSettings [2] . Baud := ORD (B2400);                                        {-Define COM2 default setup  }
  ComSettings [2] . Parity := ORD (pNone);                                      {                            }
  ComSettings [2] . Stop := 1;                                                  {                            }
  ComSettings [2] . Bits := 8;                                                  {                            }
  IF (MaxPorts >= 1)                                                            {                            }
    THEN BEGIN                                                                  {                            }
           SetupRS232 (1, ComSettings [1] . Baud,                               {-Initialize COM1 to the     }
                          ComSettings [1] . Parity,                             { default setup              }
                          ComSettings [1] . Stop,                               {                            }
                          ComSettings [1] . Bits);                              {                            }
           InstallInt (1);                                                      {-Set up the COM1 interrupt  }
         END                                                                    { if the computer has a port }
    ELSE WRITELN ('Error!  No serial ports installed in this computer');        {                            }
  IF (MaxPorts >= 2)                                                            {                            }
    THEN BEGIN                                                                  {                            }
           SetupRS232 (2, ComSettings [2] . Baud,                               {                            }
                          ComSettings [2] . Parity,                             {-Initialize COM2 to the     }
                          ComSettings [2] . Stop,                               { default setup              }
                          ComSettings [2] . Bits);                              {                            }
           InstallInt (2);                                                      {-Set up the COM2 interrupt  }
         END;                                                                   {                            }
  CurrentCom := 1;                                                              {-Set COM1 as logged port    }
  TTY (FALSE);                                                                  {-TTY with local echo off    }
                                                                                {                            }
  { IMPORTANT:  RemoveIntOnExit is always called when the program terminates! } {-RemoveIntOnExit invoked by }
      { Turbo.  Don't quit without }
*)
END.                                                                            { removing interrupts!       }
