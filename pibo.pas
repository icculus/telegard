{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit pibo;

interface

uses
  crt,dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  pibtimer,pibasync;

procedure async_receive_with_timeout(secs:integer; var c:integer);
procedure async_stuff(ch:char);
procedure async_find_delay(var one_ms_delay:integer);
procedure async_init(async_buffer_max,async_obuffer_max,
                      async_high_lev1,async_high_lev2,
                      async_low_lev:integer);
function async_carrier_drop:boolean;
function async_line_error(var error_flags:byte):boolean;
function async_ring_detect:boolean;
procedure async_send_break;
procedure async_send_string(s:anystr);
procedure async_send_string_with_delays(s:anystr; char_delay,eos_delay:integer);
function async_percentage_used:real;
function async_peek(nchars:integer):char;
procedure async_setup_port(comport,base_address,irq_line:integer);
procedure async_drain_output_buffer(max_wait_time:integer);
function async_port_address_given(com_port:integer):boolean;
procedure async_flush_output_buffer;
procedure async_close(drop_dtr:boolean);
procedure async_clear_errors;
procedure async_reset_port(comport:integer; baudrate:word; parity:char;
                           wordsize,stopbits:integer );
procedure async_release_buffers;

implementation

{uses pibasync;}

(*----------------------------------------------------------------------*)
(*   Async_Receive_With_TimeOut --- Return char. from buffer with delay *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Receive_With_Timeout( Secs : INTEGER; VAR C : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Receive_With_Timeout                           *)
(*                                                                      *)
(*     Purpose:    Retrieve character as integer from buffer,           *)
(*                 or return TimeOut if specified delay period          *)
(*                 expires.                                             *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Async_Receive_With_Timeout( Secs: INTEGER; VAR C: INTEGER );  *)
(*                                                                      *)
(*           Secs ---  Timeout period in seconds                        *)
(*                     NOTE:  Cannot be longer than 32 seconds!         *)
(*           C     --- ORD(character) (if any) retrieved from buffer;   *)
(*                     set to TimeOut if no character found before      *)
(*                     delay period expires.                            *)
(*                                                                      *)
(*     Calls:  Async_Receive                                            *)
(*                                                                      *)
(*     WATCH OUT!  THIS ROUTINE RETURNS AN INTEGER, NOT A CHARACTER!!!  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Async_Receive_With_Timeout *)

INLINE(
                                  {;}
                                  {;  Check if a character in input comm buffer}
                                  {;}
  $A1/>ASYNC_BUFFER_TAIL/         {         MOV   AX,[>Async_Buffer_Tail]}
  $3B/$06/>ASYNC_BUFFER_HEAD/     {         CMP   AX,[>Async_Buffer_Head]}
  $75/$29/                        {         JNE   Rec1}
                                  {;}
                                  {;  Buffer empty -- begin wait loop.}
                                  {;}
  $8B/$46/<SECS/                  {         MOV   AX,[BP+<Secs]                 ;Get seconds to wait}
  $B9/$0A/$00/                    {         MOV   CX,10                         ;Shift count = 2 ** 10 = 1024}
  $D3/$E0/                        {         SHL   AX,CL                         ;Seconds * 1024 = milleseconds}
  $89/$C1/                        {         MOV   CX,AX                         ;Move to looping register}
                                  {;}
                                  {;  Delay for 1 ms.}
                                  {;}
  $51/                            {Delay:   PUSH  CX                            ;Save milleseconds to go}
  $8B/$0E/>ASYNC_ONEMSDELAY/      {         MOV   CX,[>Async_OneMSDelay]        ;Get delay loop value for 1 ms}
  $E2/$FE/                        {Delay1:  LOOP  Delay1                        ;Tight loop for 1 ms delay}
                                  {;}
                                  {;  Check if any character yet.}
                                  {;}
  $59/                            {         POP   CX                            ;Get back millesecond count}
                                  {;}
  $A1/>ASYNC_BUFFER_TAIL/         {         MOV   AX,[>Async_Buffer_Tail]}
  $3B/$06/>ASYNC_BUFFER_HEAD/     {         CMP   AX,[>Async_Buffer_Head]}
  $75/$0E/                        {         JNE   Rec1}
                                  {;}
                                  {;  Buffer still empty -- decrement elapsed time}
                                  {;}
  $E2/$ED/                        {         LOOP  Delay                         ;Decrement millesecond count and loop}
                                  {;}
                                  {;  Dropped through -- no character arrived in specified interval.}
                                  {;  Return TimeOut as result.}
                                  {;}
  $BB/>TIMEOUT/                   {         MOV   BX,>TimeOut                   ;Pick up timeout value}
  $C4/$7E/<C/                     {         LES   DI,[BP+<C]                    ;Get result character address}
  $26/$89/$1D/                    {    ES:  MOV   [DI],BX                       ;Store timeout value}
  $E9/$3E/$00/                    {         JMP   Return                        ;Return to caller}
                                  {;}
                                  {;  Buffer not empty -- pick up next character.}
                                  {;}
  $C4/$3E/>ASYNC_BUFFER_PTR/      {Rec1:    LES   DI,[>Async_Buffer_Ptr]        ;Pick up buffer address}
  $01/$C7/                        {         ADD   DI,AX                         ;Add character offset}
  $26/$8A/$1D/                    {     ES: MOV   BL,[DI]                       ;Get character from buffer}
                                  {;}
  $30/$FF/                        {         XOR   BH,BH                         ;Clear high-order bits}
  $C4/$7E/<C/                     {         LES   DI,[BP+<C]                    ;Get result address}
  $26/$89/$1D/                    {     ES: MOV   [DI],BX                       ;Store character from buffer}
                                  {;}
  $40/                            {         INC   AX                            ;Increment tail pointer}
  $3B/$06/>ASYNC_BUFFER_SIZE/     {         CMP   AX,[>Async_Buffer_Size]       ;Past end of buffer?}
  $7E/$02/                        {         JLE   Rec2                          ;No -- skip wrapping}
  $31/$C0/                        {         XOR   AX,AX                         ;Yes -- point to start of buffer}
  $A3/>ASYNC_BUFFER_TAIL/         {Rec2:    MOV   [>Async_Buffer_Tail],AX       ;Update tail pointer}
  $FF/$0E/>ASYNC_BUFFER_USED/     {         DEC   Word [>Async_Buffer_Used]     ;Update buffer usage count}
                                  {;}
                                  {; If XOFF previously sent because buffer was too full, and}
                                  {; now buffer is reasonably empty, send XON to get things rolling again.}
                                  {;}
  $F6/$06/>ASYNC_XOFF_SENT/$01/   {         TEST  BYTE [<Async_XOff_Sent],1     ;Check if Xoff sent}
  $74/$16/                        {         JZ    Return                        ;No -- skip.}
                                  {;}
  $A1/>ASYNC_BUFFER_USED/         {         MOV   AX,[>Async_Buffer_Used]       ;Pick up amount of buffer used}
  $3B/$06/>ASYNC_BUFFER_LOW/      {         CMP   AX,[>Async_Buffer_Low]        ;Check if low enough}
  $7F/$0D/                        {         JG    Return                        ;Still too full, skip}
                                  {;}
  $B8/>XON/                       {         MOV   AX,>XON                       ;Push XON onto stack}
  $50/                            {         PUSH  AX}
  $FF/$1E/>ASYNC_SEND_ADDR/       {         CALL  FAR [>Async_Send_Addr]        ;Call output routine}
                                  {;}
  $C6/$06/>ASYNC_XOFF_SENT/$00/   {         MOV   BYTE [>Async_XOff_Sent],0     ;Clear Xoff flag}
                                  {;}
  $80/$26/>ASYNC_LINE_STATUS/$FD);{Return:  AND   Byte [>Async_Line_Status],$FD ;Remove overflow flag}

END   (* Async_Receive_With_Timeout *);

(*----------------------------------------------------------------------*)
(*        Async_Stuff --- Stuff character into receive buffer           *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Stuff( Ch: CHAR );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Stuff                                          *)
(*                                                                      *)
(*     Purpose:    Stuffs a character into receive buffer               *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Async_Stuff( Ch : Char );                                     *)
(*                                                                      *)
(*           Ch --- Character to stuff                                  *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   New_Head : INTEGER;

BEGIN (* Async_Stuff *)

   Async_Buffer_Ptr^[Async_Buffer_Head] := Ch;
   New_Head                             := SUCC( Async_Buffer_Head ) MOD
                                           SUCC( Async_Buffer_Size );

   IF ( New_Head = Async_Buffer_Tail ) THEN
      Async_Buffer_Overflow := TRUE
   ELSE
      BEGIN
         Async_Buffer_Head := New_Head;
         Async_Buffer_Used := SUCC( Async_Buffer_Used );
         IF ( Async_Buffer_Used > Async_MaxBufferUsed ) THEN
            Async_MaxBufferUsed := Async_Buffer_Used
      END;

END   (* Async_Stuff *);

(*----------------------------------------------------------------------*)
(* Async_Find_Delay  --- Finds delay loop value for 1 millesecond delay *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Find_Delay( VAR One_MS_Delay : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*      Procedure: Async_Find_Delay                                     *)
(*                                                                      *)
(*      Purpose:   Finds loop count value to effect 1 ms delay          *)
(*                                                                      *)
(*      Calling Sequence:                                               *)
(*                                                                      *)
(*         Async_Find_Delay( VAR One_MS_Delay : INTEGER );              *)
(*                                                                      *)
(*            One_MS_Delay --- Resulting loop count for 1 ms delay      *)
(*                                                                      *)
(*      Using result:                                                   *)
(*                                                                      *)
(*            Use loop of form:                                         *)
(*                                                                      *)
(*                      MOV    CX,[>One_MS_Delay]                       *)
(*               Delay: LOOP   Delay                                    *)
(*                                                                      *)
(*            to delay for 1 ms.                                        *)
(*                                                                      *)
(*      Remarks:                                                        *)
(*                                                                      *)
(*         This routine watches over the CPU elapsed timer value for    *)
(*         just one timer interval (55 milleseconds).  During that time *)
(*         we run a tight loop and accumulate the ticks.  The result    *)
(*         is the number of ticks required for a 55 ms delay.  The      *)
(*         ticks for a 1 ms delay = ( ticks for 55 ms ) / 55.           *)
(*                                                                      *)
(*         To avoid overflow problems on fast machines, and to ease the *)
(*         worry about storing results at the second timer tick, we     *)
(*         break up the single long tight loop into a series of short   *)
(*         loops inside an outer loop.  We check if the timer has       *)
(*         expired at the end of each inner short loop.  Then the       *)
(*         time for the 55 ms delay is:                                 *)
(*                                                                      *)
(*            Ticks_for_55 := Inner_Ticks * Outer_Ticks;                *)
(*                                                                      *)
(*         and the corresponding 1 ms delay is:                         *)
(*                                                                      *)
(*            Ticks_For_1  := Ticks_For_55 DIV 55;                      *)
(*                                                                      *)
(*         To simplify things, we choose the inner tick value to be     *)
(*         2 x 55 = 110.  Then:                                         *)
(*                                                                      *)
(*            Ticks_For_1  := ( 110 * Outer_Ticks ) / 55;  ==>          *)
(*            Ticks_For_1  := 2 * Outer_Ticks;                          *)
(*                                                                      *)
(*         The CPU timer is located in four bytes at $0000:$46C.        *)
(*         Interrupt $1A also returns these bytes, but using the        *)
(*         interrupt results in an inaccurate loop count value.         *)
(*                                                                      *)
(*         Thanks to Brian Foley and Kim Kokonnen for help with this    *)
(*         problem.                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

(* STRUCTURED *) CONST
   Hi_Timer         : INTEGER = 0  (* Saves high portion of timer        *);
   Lo_Timer         : INTEGER = 0  (* Saves low portion of timer         *);
   OutCount         : INTEGER = 0  (* Accumulates outer loop counts      *);

BEGIN (* Async_Find_Delay *)

INLINE(
                             {;}
  $31/$C0/                   {          XOR    AX,AX                 ;Clear AX to zero}
  $8E/$C0/                   {          MOV    ES,AX                 ;Allow low-memory access}
                             {;}
  $C7/$06/>OUTCOUNT/$00/$00/ {          MOV    WORD [>OutCount],0    ;Clear outer loop counter}
                             {;}
  $FA/                       {          CLI                          ;No interrupts while reading}
  $26/$8B/$0E/>$46E/         {      ES: MOV    CX,[>$46E]            ;Hi part of CPU timer value}
  $26/$8B/$16/>$46C/         {      ES: MOV    DX,[>$46C]            ;Lo part of CPU timer value}
  $FB/                       {          STI                          ;Interrupts back on}
                             {;}
  $89/$0E/>HI_TIMER/         {          MOV    [>Hi_Timer],CX        ;Save hi part of timer}
  $89/$16/>LO_TIMER/         {          MOV    [>Lo_Timer],DX        ;Save low part of timer}
                             {;}
  $FA/                       {Loop1:    CLI                          ;No interrupts while reading}
                             {;}
  $26/$8B/$0E/>$46E/         {      ES: MOV    CX,[>$46E]            ;Hi part of CPU timer value}
  $26/$8B/$16/>$46C/         {      ES: MOV    DX,[>$46C]            ;Lo part of CPU timer value}
                             {;}
  $FB/                       {          STI                          ;Interrupts back on}
                             {;}
  $89/$C8/                   {          MOV    AX,CX                 ;Save CX and DX for later}
  $89/$D3/                   {          MOV    BX,DX}
                             {;}
  $2B/$06/>HI_TIMER/         {          SUB    AX,[>Hi_Timer]        ;Subtract low order part}
  $1B/$1E/>LO_TIMER/         {          SBB    BX,[>Lo_Timer]        ;Subtract high order part}
                             {;}
  $74/$E6/                   {          JE     Loop1                 ;Continue until non-0 tick difference}
                             {;}
  $89/$0E/>HI_TIMER/         {          MOV    [>Hi_Timer],CX        ;Save hi part}
  $89/$16/>LO_TIMER/         {          MOV    [>Lo_Timer],DX        ;Save low part}
                             {;}
  $B9/$6E/$00/               {Loop2:    MOV    CX,110                ;Run short delay loop.}
  $E2/$FE/                   {Delay:    LOOP   Delay}
                             {;}
  $FA/                       {          CLI                          ;No interrupts while reading}
                             {;}
  $26/$8B/$0E/>$46E/         {      ES: MOV    CX,[>$46E]            ;Hi part of CPU timer value}
  $26/$8B/$16/>$46C/         {      ES: MOV    DX,[>$46C]            ;Lo part of CPU timer value}
                             {;}
  $FB/                       {          STI                          ;Interrupts back on}
                             {;}
  $FF/$06/>OUTCOUNT/         {          INC    WORD [>OutCount]      ;Increment outer loop count}
                             {;}
  $2B/$0E/>HI_TIMER/         {          SUB    CX,[>Hi_Timer]        ;Subtract low order part}
  $1B/$16/>LO_TIMER/         {          SBB    DX,[>Lo_Timer]        ;Subtract high order part}
                             {;}
  $74/$E1/                   {          JE     Loop2                 ;Keep going if next tick not found}
                             {;}
  $A1/>OUTCOUNT/             {          MOV    AX,[>OutCount]        ;Pick up outer loop counter}
  $D1/$E0/                   {          SHL    AX,1                  ;* 2 = ticks for 1 ms delay}
                             {;}
  $C4/$BE/>ONE_MS_DELAY/     {          LES    DI,[BP+>One_MS_Delay] ;Get address of result}
  $26/$89/$05);              {      ES: MOV    [DI],AX               ;Store result}

END   (* Async_Find_Delay *);

(*----------------------------------------------------------------------*)
(*               Async_Init --- Initialize Asynchronous Variables       *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Init( Async_Buffer_Max  : INTEGER;
                      Async_OBuffer_Max : INTEGER;
                      Async_High_Lev1   : INTEGER;
                      Async_High_Lev2   : INTEGER;
                      Async_Low_Lev     : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Init                                           *)
(*                                                                      *)
(*     Purpose:    Initializes variables                                *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*         Async_Init( Async_Buffer_Max  : INTEGER;                     *)
(*                     Async_OBuffer_Max : INTEGER;                     *)
(*                     Async_High_Lev1   : INTEGER;                     *)
(*                     Async_High_Lev2   : INTEGER;                     *)
(*                     Async_Low_Lev     : INTEGER );                   *)
(*                                                                      *)
(*     Calls:  Async_Find_Delay                                         *)
(*             TurnOffTimeSharing                                       *)
(*             TurnOnTimeSharing                                        *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I: INTEGER;

(*----------------------------------------------------------------------*)

begin
                                   (* No port open yet. *)
  Async_Open_Flag:=FALSE;

                                   (* No XON/XOFF handling yet. *)
  Async_XOFF_Sent:=FALSE;
  Async_XOFF_Received:=FALSE;
  Async_XOFF_Rec_Display:=FALSE;
  Async_XON_Rec_Display:=FALSE;
  Async_Send_XOFF:=FALSE;

                                   (* Set up empty receive buffer *)
  Async_Buffer_Overflow:=FALSE;
  Async_Buffer_Used:=0;
  Async_MaxBufferUsed:=0;
  Async_Buffer_Head:=0;
  Async_Buffer_Tail:=0;
                                   (* Set up empty send buffer. *)
  Async_OBuffer_Overflow:=FALSE;
  Async_OBuffer_Used:=0;
  Async_MaxOBufferUsed:=0;
  Async_OBuffer_Head:=0;
  Async_OBuffer_Tail:=0;
                                   (* Set default wait time for output *)
                                   (* buffer to drain when it fills up. *)
  Async_Output_Delay:=500;

                                   (* No modem or line errors yet. *)
  Async_Line_Status:=0;
  Async_Modem_Status:=0;
  Async_Line_Error_Flags:=0;

                                   (* Get buffer sizes *)

  if (Async_Buffer_Max>0) then Async_Buffer_Size:=Async_Buffer_Max-1
    else Async_Buffer_Size:=4095;

  if (Async_OBuffer_Max>0) then Async_OBuffer_Size:=Async_OBuffer_Max-1
    else Async_OBuffer_Size:=1131;

                                   (* Get receive buffer overflow *)
                                   (* check-points. *)
  if (Async_Low_Lev>0) then Async_Buffer_Low:=Async_Low_Lev
    else Async_Buffer_Low:=Async_Buffer_Size div 4;

  if (Async_High_Lev1>0) then Async_Buffer_High:=Async_High_Lev1
    else Async_Buffer_High:=(Async_Buffer_Size div 4)*3;

  if (Async_High_Lev2>0) then Async_Buffer_High_2:=Async_High_Lev2
    else Async_Buffer_High_2:=(Async_Buffer_Size div 10)*9;

                                   (* Allocate buffers *)

(*  getmem(Async_Buffer_Ptr,Async_Buffer_Size+1);
  getmem(Async_OBuffer_Ptr,Async_OBuffer_Size+1);*)

                                   (* No UART addresses defined yet *)
(*procedure Async_Init;
begin
  Async_Open_Flag := FALSE;
  Async_Buffer_Overflow := FALSE;
  Async_Buffer_Used := 0;
  Async_MaxBufferUsed := 0;
end;*)

  Async_Uart_IER:=0;
  Async_Uart_IIR:=0;
  Async_Uart_MSR:=0;
  Async_Uart_LSR:=0;
                                   (* Set default port addresses *)
                                   (* and default IRQ lines *)
  for i:=1 to MaxComPorts do begin
    com_base[i]:=default_com_base[i];
    com_irq[i]:=default_com_irq[i];
  end;
                                   (* Get the delay loop value for 1 ms *)
                                   (* delay loops. *)

(* ---- You should turn off time sharing if running under a multitasker *)
(* ---- to get an accurate delay loop value.  If MTASK is $DEFINEd, *)
(* ---- then the calls to the PibMDos routines for interfacing with *)
(* ---- multitaskers will be generated. *)

{$IFDEF MTASK}
  if (timesharingactive) then turnofftimesharing;
{$ENDIF}

(*  Async_find_delay(Async_onemsdelay );*)

{$IFDEF MTASK}
  if (timesharingactive) then turnontimesharing;
{$ENDIF}
end;

(*----------------------------------------------------------------------*)
(*      Async_Carrier_Drop --- Check for modem carrier drop/timeout     *)
(*----------------------------------------------------------------------*)

function Async_carrier_drop:boolean;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Async_Carrier_Drop                                   *)
(*                                                                      *)
(*     Purpose:    Looks for modem carrier drop/timeout                 *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Flag := Async_Carrier_Drop : BOOLEAN;                         *)
(*                                                                      *)
(*           Flag is set TRUE if carrier dropped, else FALSE.           *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

begin
  Async_carrier_drop:=not (odd(port[UART_MSR+Async_base] shr 7) or
                           Async_hard_wired_on);
end;

(*----------------------------------------------------------------------*)
(*          Async_Line_Error --- Check if line status error occurred    *)
(*----------------------------------------------------------------------*)

function Async_line_error(var error_flags:byte):boolean;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Async_Line_Error                                     *)
(*                                                                      *)
(*     Purpose:    Check if line status error occurred                  *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Flag := Async_Line_Error(VAR Error_Flags: BYTE): BOOLEAN;   *)
(*                                                                      *)
(*           Error_Flags --- Current error flags                        *)
(*                                                                      *)
(*           Flag returned TRUE if line status error occurred,          *)
(*           Flag returned FALSE if no error.                           *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        The line status error flag is cleared here.                   *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

begin
  Async_line_error:=(Async_line_error_flags<>0);
  Error_flags:=Async_line_error_flags;
  Async_line_error_flags:=0;
end;

(*----------------------------------------------------------------------*)
(*            Async_Ring_Detect --- Check for phone ringing             *)
(*----------------------------------------------------------------------*)

function Async_ring_detect:boolean;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Async_Ring_Detect                                    *)
(*                                                                      *)
(*     Purpose:    Looks for phone ringing                              *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Flag := Async_Ring_Detect : BOOLEAN;                          *)
(*                                                                      *)
(*           Flag is set TRUE if ringing detected, else FALSE.          *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

begin
  Async_ring_detect:=odd(port[UART_MSR+Async_base] shr 6);
end;

(*----------------------------------------------------------------------*)
(*          Async_Send_Break --- Send break (attention) signal          *)
(*----------------------------------------------------------------------*)

procedure Async_send_break;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Send_Break                                     *)
(*                                                                      *)
(*     Purpose:    Sends break signal over communications port          *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Async_Send_Break;                                             *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

var break_lcr,old_lcr:byte;

begin
  Old_Lcr   := Port[ UART_LCR + Async_Base ];
  Break_Lcr := Old_Lcr;

  IF Break_Lcr >  127 THEN Break_Lcr := Break_Lcr - 128;
  IF Break_Lcr <=  63 THEN Break_Lcr := Break_Lcr +  64;

  Port[ UART_LCR + Async_Base ] := Break_Lcr;

  DELAY( Async_Break_Length * 10 );

  Port[ UART_LCR + Async_Base ] := Old_Lcr;

end;

(*----------------------------------------------------------------------*)
(*     Async_Send_String --- Send string over communications port       *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Send_String( S : AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Send_String                                    *)
(*                                                                      *)
(*     Purpose:    Sends string out over communications port            *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Async_Send_String( S : AnyStr );                              *)
(*                                                                      *)
(*           S --- String to send                                       *)
(*                                                                      *)
(*     Calls:  Async_Send                                               *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

var i:integer;
begin
  for i:=1 to length(s) do Async_send(s[i]);
end;

(*----------------------------------------------------------------------*)
(*     Async_Send_String_With_Delays --- Send string with timed delays  *)
(*----------------------------------------------------------------------*)

procedure Async_send_string_with_delays(s:anystr;
                                        char_delay:integer;
                                        eos_delay:integer);

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Send_String_With_Delays                        *)
(*                                                                      *)
(*     Purpose:    Sends string out over communications port with       *)
(*                 specified delays for each character and at the       *)
(*                 end of the string.                                   *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Async_Send_String_With_Delays( S          : AnyStr ;          *)
(*                                       Char_Delay : INTEGER;          *)
(*                                       EOS_Delay  : INTEGER );        *)
(*                                                                      *)
(*           S          --- String to send                              *)
(*           Char_Delay --- Number of milliseconds to delay after       *)
(*                          sending each character                      *)
(*           EOS_Delay  --- Number of milleseconds to delay after       *)
(*                          sending last character in string            *)
(*                                                                      *)
(*     Calls:  Async_Send                                               *)
(*             Async_Send_String                                        *)
(*             Length                                                   *)
(*             Delay                                                    *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This routine is useful when writing routines to perform       *)
(*        non-protocol uploads.  Many computer systems require delays   *)
(*        between receipt of characters for correct processing.  The    *)
(*        delay for end-of-string usually applies when the string       *)
(*        represents an entire line of a file.                          *)
(*                                                                      *)
(*        If delays are not required, Async_Send_String is faster.      *)
(*        This routine will call Async_Send_String is no character      *)
(*        delay is to be done.                                          *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

var i:integer;
begin
  if (char_delay<=0) then
    Async_send_string(s)
  else
    for i:=1 to length(s) do begin
      Async_send(s[i]);
      delay(char_delay);
    end;
  if (eos_delay>0) then delay(eos_delay);
end;

(*----------------------------------------------------------------------*)
(*      Async_Percentage_Used --- Report Percentage Buffer Filled       *)
(*----------------------------------------------------------------------*)

function Async_percentage_used:real;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Async_Percent_Used                                   *)
(*                                                                      *)
(*     Purpose:    Reports percentage of com buffer currently filled    *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Percentage := Async_Percentage_Used : Real;                   *)
(*                                                                      *)
(*           Percentage gets how much of buffer is filled;              *)
(*           value goes from 0.0 (empty) to 1.0 (totally full).         *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*       This routine is helpful when incorporating handshaking into    *)
(*       a communications program.  For example, assume that the host   *)
(*       computer uses the XON/XOFF (DC1/DC3) protocol.  Then the       *)
(*       PC program should issue an XOFF  to the host when the value    *)
(*       returned by Async_Percentage_Used > .75 or so.  When the       *)
(*       utilization percentage drops below .25 or so, the PC program   *)
(*       should transmit an XON.                                        *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

begin
  Async_percentage_used:=Async_buffer_used/(Async_buffer_size+1);
end;

(*----------------------------------------------------------------------*)
(*          Async_Peek --- Peek ahead in communications buffer          *)
(*----------------------------------------------------------------------*)

function Async_peek(nchars:integer):char;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Async_Peek                                           *)
(*                                                                      *)
(*     Purpose:    Peeks ahead in comm buffer                           *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Ch := Async_Peek( NChars: INTEGER) : CHAR;                    *)
(*                                                                      *)
(*           NChars --- # of characters to peek ahead                   *)
(*           Ch     --- returned (peeked) character                     *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

var i:integer;
begin
  i:=(Async_buffer_tail+nchars) mod Async_buffer_size;

  if (i>Async_buffer_head) then
    Async_peek := #0
  else
    Async_peek := Async_buffer_ptr^[i];
end;

(*----------------------------------------------------------------------*)
(*         Async_Setup_Port --- Setup port address and IRQ line         *)
(*----------------------------------------------------------------------*)

procedure Async_setup_port(comport,base_address:integer;
                           irq_line:integer);

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Setup_Port                                     *)
(*                                                                      *)
(*     Purpose:    Sets up port address and IRQ line                    *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Async_Setup_Port( ComPort       : INTEGER;                    *)
(*                          Base_Address  : INTEGER;                    *)
(*                          IRQ_Line      : INTEGER );                  *)
(*                                                                      *)
(*           ComPort      --- which port (1 though MaxComPorts)         *)
(*           Base_Address --- Base address of port.  If -1, then        *)
(*                            standard default address used.            *)
(*           IRQ_Line     --- IRQ line for interrupts for port.  If -1, *)
(*                            then standard default address used.       *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

var port_offset:integer;

begin
  if ((comport>0) and (comport<=maxcomports)) then begin
    if (base_address=-1) then
      base_address:=default_com_base[comport];
    if (irq_line=-1) then
      irq_line:=default_com_irq[comport];
    com_base[comport]:=base_address;
    com_irq[comport]:=irq_line;
    port_offset:=RS232_base+(pred(comport) shl 1);
    memw[$0000:port_offset]:=base_address;
  end;
end;

(*----------------------------------------------------------------------*)
(*         Async_Release_Buffers --- Release buffers for serial ports   *)
(*----------------------------------------------------------------------*)

(*----------------------------------------------------------------------*)
(*   Async_Drain_Output_Buffer --- Wait for output buffer to drain      *)
(*----------------------------------------------------------------------*)

procedure Async_drain_output_buffer(max_wait_time:integer);

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Drain_Output_Buffer;                           *)
(*                                                                      *)
(*     Purpose:    Waits for output buffer to drain.                    *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Async_Drain_Output_Buffer( Max_Wait_Time : INTEGER );         *)
(*                                                                      *)
(*           Max_Wait_Time --- Maximum # of seconds to wait for         *)
(*                             output buffer to drain.                  *)
(*                                                                      *)
(*     Calls:  TimeOfDay                                                *)
(*             TimeDiff                                                 *)
(*             GiveAwayTime                                             *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

var t1:longint;
begin
  t1:=timeofday;

  while ((Async_obuffer_head<>Async_obuffer_tail) and
         (timediff(t1,timeofday)<=max_wait_time)) do
{$IFDEF MTASK}
      giveawaytime(1);
{$ELSE}
      ;
{$ENDIF}
end;

(*----------------------------------------------------------------------*)
(*   Async_Port_Address_Given --- Check if port address in memory       *)
(*----------------------------------------------------------------------*)

FUNCTION Async_Port_Address_Given( Com_Port : INTEGER ) : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Port_Address_Given;                            *)
(*                                                                      *)
(*     Purpose:    Checks if port address in memory.                    *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        There := Async_Port_Address_Given( Com_Port : INTEGER ) :     *)
(*                                         BOOLEAN;                     *)
(*                                                                      *)
(*           Com_Port --- Port to check (1 through MaxComPorts)         *)
(*           There    --- TRUE if port address in memory.               *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Port_Offset : INTEGER;

BEGIN  (* Async_Port_Address_Given *)

   IF ( ( Com_Port > 0 ) AND ( Com_Port < MaxComPorts ) ) THEN
      BEGIN
         Port_Offset              := RS232_Base + ( PRED( Com_Port ) SHL 1 );
         Async_Port_Address_Given := ( MemW[$0:Port_Offset] <> 0 );
      END
   ELSE
      Async_Port_Address_Given := FALSE;

END    (* Async_Port_Address_Given *);

(*----------------------------------------------------------------------*)
(*   Async_Flush_Output_Buffer --- Flush output buffer for serial port  *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Flush_Output_Buffer;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Flush_Output_Buffer;                           *)
(*                                                                      *)
(*     Purpose:    Flushes output buffer for serial port.               *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Async_Flush_Output_Buffer;                                    *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN  (* Async_Flush_Output_Buffer *)

   Async_OBuffer_Head  := Async_OBuffer_Tail;
   Async_OBuffer_Used  := 0;

END    (* Async_Flush_Output_Buffer *);

procedure async_close(drop_dtr:boolean);
var i,m:integer;
begin
  if (Async_Open_Flag) then begin

      { disable the IRQ on the 8259 }
      inline($FA);
      i := Port[I8088_IMR];        { get the interrupt mask register }
      m := 1 shl Async_Irq;        { set mask to turn off interrupt }
      Port[I8088_IMR] := i or m;

      { disable the 8250 data ready interrupt }
      Port[UART_IER + async_base] := 0;

      { disable OUT2 on the 8250 }
      if (drop_dtr) then
        Port[UART_MCR + async_base] := 0
      else
        Port[UART_MCR + async_base] := 1;
      inline($FB);

      SetIntVec(Async_Irq + 8,Async_save_iaddr);

      { re-initialize our data areas so we know the port is closed }
      Async_Open_Flag := FALSE;

    end;
END    (* Async_Close *);

(*----------------------------------------------------------------------*)
(*    Async_Clear_Errors --- Reset pending errors in async port         *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Clear_Errors;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:   Async_Clear_Errors                                  *)
(*                                                                      *)
(*     Purpose:     Resets pending errors in async port                 *)
(*                                                                      *)
(*     Calling sequence:                                                *)
(*                                                                      *)
(*        Async_Clear_Errors;                                           *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

var i,m:integer;
begin
                   (* Read the RBR and reset any pending error conditions. *)
                   (* First turn off the Divisor Access Latch Bit to allow *)
                   (* access to RBR, etc.                                  *)

   inline($FA);  (* disable interrupts *)

   port[UART_LCR+Async_Base]:=port[UART_LCR+Async_Base] and $7F;

                   (* Read the Line Status Register to reset any errors *)
                   (* it indicates                                      *)

   i:=port[UART_LSR+Async_Base];

                   (* Read the Receiver Buffer Register in case it *)
                   (* contains a character                         *)

   i:=port[UART_RBR+Async_Base];

                   (* enable the irq on the 8259 controller *)

   i:=port[I8088_IMR];  (* get the interrupt mask register *)
   m:=(1 shl Async_Irq) xor $00FF;

   port[I8088_IMR]:=i and m;

                   (* enable OUT2 on 8250 *)

   i:=port[UART_MCR+Async_Base];
   port[UART_MCR+Async_Base]:=i or $0B;

                   (* enable the data ready interrupt on the 8250 *)

   port[UART_IER+Async_Base]:=$0F;

                   (* Re-enable 8259 *)

   port[$20] := $20;

   inline($FB); (* enable interrupts *)

end;

(*----------------------------------------------------------------------*)
(*    Async_Reset_Port --- Set/reset communications port parameters     *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Reset_Port( ComPort       : INTEGER;
                            BaudRate      : WORD;
                            Parity        : CHAR;
                            WordSize      : INTEGER;
                            StopBits      : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:   Async_Reset_Port                                    *)
(*                                                                      *)
(*     Purpose:     Resets communications port                          *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Async_Reset_Port(   ComPort       : INTEGER;                  *)
(*                            BaudRate      : WORD;                     *)
(*                            Parity        : CHAR;                     *)
(*                            WordSize      : INTEGER;                  *)
(*                            StopBits      : INTEGER);                 *)
(*                                                                      *)
(*           ComPort  --- which port (1, 2, 3, 4)                       *)
(*           BaudRate --- Baud rate (110 to 38400)                      *)
(*           Parity   --- "E" for even, "O" for odd, "N" for none,      *)
(*                        "M" for mark, "S" for space.
(*           WordSize --- Bits per character  (5 through 8)             *)
(*           StopBits --- How many stop bits  (1 or 2)                  *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Async_Clear_Errors --- Clear async line errors                *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

CONST   (* Baud Rate Constants *)

   Async_Num_Bauds = 10;

   Async_Baud_Table : ARRAY [1..Async_Num_Bauds] OF RECORD
                                                       Baud, Bits : WORD;
                                                    END

                    = ( ( Baud:  110;  Bits: $00 ),
                        ( Baud:  150;  Bits: $20 ),
                        ( Baud:  300;  Bits: $40 ),
                        ( Baud:  600;  Bits: $60 ),
                        ( Baud:  1200; Bits: $80 ),
                        ( Baud:  2400; Bits: $A0 ),
                        ( Baud:  4800; Bits: $C0 ),
                        ( Baud:  9600; Bits: $E0 ),
                        ( Baud: 19200; Bits: $E0 ),    
                        ( Baud: 38400; Bits: $E0 ) );

VAR
   I       : INTEGER;
   M       : INTEGER;
   ComParm : INTEGER;

BEGIN (* Async_Reset_Port *)

            (*---------------------------------------------------*)
            (*    Build the ComParm for RS232_Init               *)
            (*    See Technical Reference Manual for description *)
            (*---------------------------------------------------*)

                                   (* Set up the bits for the baud rate *)

   IF ( BaudRate > Async_Baud_Table[Async_Num_Bauds].Baud ) THEN
      BaudRate := Async_Baud_Table[Async_Num_Bauds].Baud

   ELSE IF ( BaudRate < Async_Baud_Table[1].Baud ) THEN
      BaudRate := Async_Baud_Table[1].Baud;

                                   (* Remember baud rate for purges *)
   Async_Baud_Rate := BaudRate;

   I := 0;

   REPEAT
      I := I + 1
   UNTIL ( ( I >= Async_Num_Bauds ) OR
           ( BaudRate = Async_Baud_Table[I].Baud ) );

   ComParm := Async_Baud_Table[I].Bits;

                                   (* Choose Parity.  Temporarily   *)
                                   (* consider mark, space as none. *)
   Parity := UpCase( Parity );

   CASE Parity OF
      'E' : ComParm := ComParm OR $0018;
      'O' : ComParm := ComParm OR $0008;
      ELSE ;
   END (* CASE *);
                                   (* Choose number of data bits *)

   WordSize := WordSize - 5;

   IF ( WordSize < 0 ) OR ( WordSize > 3 ) THEN
      WordSize := 3;

   ComParm := ComParm OR WordSize;

                                   (* Choose stop bits *)

   IF StopBits = 2 THEN
      ComParm := ComParm OR $0004;  (* default is 1 stop bit *)

                                   (* Use the BIOS COM port init routine *)

   BIOS_RS232_Init( ComPort - 1 , ComParm );

                                   (* If > 9600 baud, we have to screw *)
                                   (* around a bit                     *)

   IF ( ( BaudRate = 19200 ) OR ( BaudRate = 38400 ) ) THEN
      BEGIN

         I := PORT[ UART_LCR + Async_Base ];
         PORT[ UART_LCR + Async_Base ] := I OR $80;

         IF ( BaudRate = 19200 ) THEN
            PORT[ UART_THR + Async_Base ] := 6
         ELSE
            PORT[ UART_THR + Async_Base ] := 3;

         PORT[ UART_IER + Async_Base ] := 0;

         I := PORT[ UART_LCR + Async_Base ];
         PORT[ UART_LCR + Async_Base ] := I AND $7F;

      END;
                                   (* Now fix up mark, space parity *)

   IF ( ( Parity = 'M' ) OR ( Parity = 'S' ) ) THEN
      BEGIN

         I := PORT[ UART_LCR + Async_Base ];
         PORT[ UART_LCR + Async_Base ] := $80;

         ComParm := WordSize OR ( ( StopBits - 1 ) SHL 2 );

         CASE Parity OF
            'M' : ComParm := ComParm OR $0028;
            'S' : ComParm := ComParm OR $0038;
            ELSE ;
         END (* CASE *);

         PORT[ UART_LCR + Async_Base ] := ComParm;

      END;
                                   (* Clear any pending errors on *)
                                   (* async line                  *)
   Async_Clear_Errors;

end;

procedure async_release_buffers;
begin
  if (async_open_flag) then async_close(FALSE);

(*  freemem(async_buffer_ptr,async_buffer_size+1);
  freemem(async_obuffer_ptr,async_obuffer_size+1);*)
end;

end.
