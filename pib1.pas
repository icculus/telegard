INLINE(
  $FB/                                 {         STI                                ;Allow interrupts}
                                       {;}
                                       {;  Begin major polling loop over pending interrupts.}
                                       {;}
                                       {;  The polling loop is needed because the 8259 cannot handle another 8250}
                                       {;  interrupt while we service this interrupt.  We keep polling here as long}
                                       {;  as an interrupt is received.}
                                       {;}
  $8B/$16/>ASYNC_UART_IIR/             {Poll:    MOV     DX,[>Async_Uart_IIR]       ;Get Interrupt ident register}
  $EC/                                 {         IN      AL,DX                      ;Pick up interrupt type}
                                       {;}
  $A8/$01/                             {         TEST    AL,1                       ;See if any interrupt signalled.}
  $74/$03/                             {         JZ      Polla                      ;Yes --- continue}
  $E9/$7F/$01/                         {         JMP     NEAR Back                  ;No  ---  return to invoker}
                                       {;}
                                       {;  Determine type of interrupt.}
                                       {;  Possibilities:}
                                       {;}
                                       {;     0 = Modem status changed}
                                       {;     2 = Transmit hold register empty (write char)}
                                       {;     4 = Character received from port}
                                       {;     6 = Line status changed}
                                       {;}
  $24/$06/                             {Polla:   AND     AL,6                       ;Strip unwanted bits from interrupt type}
  $3C/$04/                             {         CMP     AL,4                       ;Check if interrupt >= 4}
  $74/$03/                             {         JE      Pollb                      ;}
  $E9/$A1/$00/                         {         JMP     NEAR Int2}
                                       {;}
                                       {;  Write interrupts must be turned on if a higher-priority interrupt}
                                       {;  has been received, else the characters may not be sent (and a lockup}
                                       {;  may occur).}
                                       {;}
  $50/                                 {Pollb:   PUSH    AX                         ;Save interrupt type}
  $E8/$65/$01/                         {         CALL    EnabWI                     ;Enable write interrupts}
  $58/                                 {         POP     AX                         ;Restore interrupt type}
                                       {;}
                                       {;  --- Received a character ----}
                                       {;}
  $3C/$04/                             {Int4:    CMP     AL,4                       ;Check for received char interrupt}
  $74/$03/                             {         JE      Int4a                      ;Yes -- process it.}
  $E9/$95/$00/                         {         JMP     NEAR Int2                  ;No -- skip.}
                                       {;}
                                       {;  Read the character from the serial port.}
                                       {;}
  $8B/$16/>ASYNC_BASE/                 {Int4a:   MOV     DX,[>Async_Base]           ;Read character from port}
  $EC/                                 {         IN      AL,DX}
                                       {;}
                                       {;  Check if XON/XOFF honored.  If so, check if incoming character is}
                                       {;  an XON or an XOFF.}
                                       {;}
  $90/$90/$90/$90/$90/                 {         NOP NOP NOP NOP NOP }
  $EB/$25/                             {         JMP     Int4d                      ;No -- skip XON/XOFF checks}
(*  $F6/$06/>ASYNC_DO_XONXOFF/$01/       {         TEST    BYTE [<Async_Do_XonXoff],1 ;See if we honor XON/XOFF}*)
(*  $74/$25/                             {         JZ      Int4d                      ;No -- skip XON/XOFF checks}*)
                                       {;}
  $3C/<XON/                            {         CMP     AL,<XON                    ;See if XON found}
  $74/$11/                             {         JE      Int4b                      ;Skip if XON found}
  $3C/<XOFF/                           {         CMP     AL,<XOFF                   ;See if XOFF found}
  $75/$1D/                             {         JNE     Int4d                      ;Skip if XOFF not found}
                                       {;}
                                       {;  XOFF received -- set flag indicating sending of chars isn't possible}
                                       {;}
  $C6/$06/>ASYNC_XOFF_RECEIVED/$01/    {         MOV     BYTE [<Async_XOFF_Received],1    ;Turn on received XOFF flag}
  $C6/$06/>ASYNC_XOFF_REC_DISPLAY/$01/ {         MOV     BYTE [<Async_XOFF_Rec_Display],1 ;Turn on display flag}
  $E9/$BE/$FF/                         {         JMP     NEAR Poll}
                                       {;}
                                       {;  XON received -- allow more characters to be sent.}
                                       {;}
  $C6/$06/>ASYNC_XOFF_RECEIVED/$00/    {Int4b:   MOV     BYTE [<Async_XOFF_Received],0   ;Turn off received XOFF flag}
  $C6/$06/>ASYNC_XON_REC_DISPLAY/$01/  {         MOV     BYTE [<Async_XON_Rec_Display],1 ;Turn on display flag}
                                       {;}
  $E8/$2F/$01/                         {         CALL    EnabWI                     ;Enable write interrupts}
  $E9/$61/$00/                         {         JMP     NEAR Int4z}
                                       {;}
                                       {;  Not XON/XOFF -- handle other character.}
                                       {;}
  $90/$90/$90/$90/$90/                 {Int4d:   NOP NOP NOP NOP NOP }
  $90/$90/                             {         NOP NOP }
(*  $F6/$06/>ASYNC_LINE_STATUS/$02/      {Int4d:   TEST    BYTE [>Async_Line_Status],2 ;Check for buffer overrun}*)
(*  $75/$5A/                             {         JNZ     Int4z                      ;Yes --- don't store anything}*)
(* Commented out to prevent lockups. Needs better coding. *)
                                       {;}
  $8B/$1E/>ASYNC_BUFFER_HEAD/          {         MOV     BX,[>Async_Buffer_Head]    ;Current position in input buffer}
  $C4/$3E/>ASYNC_BUFFER_PTR/           {         LES     DI,[>Async_Buffer_Ptr]     ;Pick up buffer address}
  $01/$DF/                             {         ADD     DI,BX                      ;Update position}
  $26/$88/$05/                         {     ES: MOV     [DI],AL                    ;Store received character in buffer}
  $FF/$06/>ASYNC_BUFFER_USED/          {         INC     WORD [>Async_Buffer_Used]  ;Increment count of chars in buffer}
                                       {;}
  $A1/>ASYNC_BUFFER_USED/              {         MOV     AX,[>Async_Buffer_Used]    ;Pick up buffer usage count}
  $3B/$06/>ASYNC_MAXBUFFERUSED/        {         CMP     AX,[>Async_MaxBufferUsed]  ;See if greater usage than ever before}
  $7E/$03/                             {         JLE     Int4f                      ;Skip if not}
  $A3/>ASYNC_MAXBUFFERUSED/            {         MOV     [>Async_MaxBufferUsed],AX  ;This is greatest use thus far}
                                       {;}
  $43/                                 {Int4f:   INC     BX                         ;Increment buffer pointer}
  $3B/$1E/>ASYNC_BUFFER_SIZE/          {         CMP     BX,[>Async_Buffer_Size]    ;Check if past end of buffer}
  $7E/$02/                             {         JLE     Int4h}
  $31/$DB/                             {         XOR     BX,BX                      ;If so, wrap around to front}
                                       {;}
  $39/$1E/>ASYNC_BUFFER_TAIL/          {Int4h:   CMP     WORD [>Async_Buffer_Tail],BX ;Check for overflow}
  $74/$29/                             {         JE      Int4s                      ;Jump if head ran into tail}
                                       {;}
  $89/$1E/>ASYNC_BUFFER_HEAD/          {         MOV     [>Async_Buffer_Head],BX    ;Update head pointer}
                                       {;}
                                       {;  If XON/XOFF available, and buffer getting full, set up to send}
                                       {;  XOFF to remote system.}
                                       {;}
                                       {;  This happens in two possible stages:}
                                       {;}
                                       {;     (1)  An XOFF is sent right when the buffer becomes 'Async_Buffer_High'}
                                       {;          characters full.}
                                       {;}
                                       {;     (2)  A second XOFF is sent right when the buffer becomes}
                                       {;          'Async_Buffer_High_2' characters full;  this case is likely the}
                                       {;          result of the remote not having seen our XOFF because it was}
                                       {;          lost in transmission.}
                                       {;}
  $90/$90/$90/$90/$90/                 {         NOP NOP NOP NOP NOP }
  $EB/$23/                             {         JMP     Int4z                      ;No -- skip XON/XOFF checks}
(*  $F6/$06/>ASYNC_DO_XONXOFF/$01/       {         TEST    BYTE [<Async_Do_XonXoff],1 ;See if we honor XON/XOFF}*)
(*  $74/$23/                             {         JZ      Int4z                      ;No -- skip XON/XOFF checks}*)
                                       {;}
                                       {;  Check against first high-water mark.}
                                       {;}
  $3B/$06/>ASYNC_BUFFER_HIGH/          {         CMP     AX,[>Async_Buffer_High]    ;AX still has Async_Buffer_Used}
  $7C/$1D/                             {         JL      Int4z                      ;Not very full, so keep going.}
                                       {;}
                                       {;  Check if we've already sent XOFF.}
                                       {;}
  $F6/$06/>ASYNC_XOFF_SENT/$01/        {         TEST    BYTE [<Async_XOFF_Sent],1  ;Remember if we sent XOFF or not}
  $74/$06/                             {         JZ      Int4j                      ;No -- go send it now.}
                                       {;}
                                       {;  Check against second high-water mark.}
                                       {;  If we are right at it, send an XOFF regardless of whether we've}
                                       {;  already sent one or not.  (Perhaps the first got lost.)}
                                       {;}
  $3B/$06/>ASYNC_BUFFER_HIGH_2/        {         CMP     AX,[>Async_Buffer_High_2]}
  $75/$10/                             {         JNE     Int4z                      ;Not at 2nd mark -- skip}
                                       {;}
  $C6/$06/>ASYNC_SEND_XOFF/$01/        {Int4j:   MOV     BYTE [<Async_Send_XOFF],1  ;Indicate we need to send XOFF}
  $E8/$D3/$00/                         {         CALL    EnabWI                     ;Ensure write interrupts enabled}
  $E9/$52/$FF/                         {         JMP     NEAR Poll                  ;}
                                       {;}
                                       {;  If we come here, then the input buffer has overflowed.}
                                       {;  Characters will be thrown away until the buffer empties at least one slot.}
                                       {;}
  $80/$0E/>ASYNC_LINE_STATUS/$02/      {Int4s:   OR      BYTE PTR [>Async_Line_Status],2 ;Flag overrun}
                                       {;}
  $E9/$4A/$FF/                         {Int4z:   JMP     NEAR Poll}
                                       {;}
                                       {;  --- Write a character ---}
                                       {;}
  $3C/$02/                             {Int2:    CMP     AL,2                       ;Check for THRE interrupt}
  $74/$03/                             {         JE      Int2a                      ;Yes -- process it.}
  $E9/$97/$00/                         {         JMP     NEAR Int6                  ;No -- skip.}
                                       {;}
                                       {;  Check first if we need to send an XOFF to remote system.}
                                       {;}
  $F6/$06/>ASYNC_SEND_XOFF/$01/        {Int2a:   TEST    BYTE [<Async_Send_Xoff],1  ;See if we are sending XOFF}
  $74/$34/                             {         JZ      Int2d                      ;No -- skip it}
                                       {;}
                                       {;  Yes, we are to send XOFF to remote.}
                                       {;}
                                       {;  First, check DSR and CTS as requested.}
                                       {;  If those status lines aren't ready, turn off write interrupts and}
                                       {;  try later, after a line status change.}
                                       {;}
  $F6/$06/>ASYNC_DO_DSR/$01/           {         TEST    BYTE [<Async_Do_DSR],1     ;See if DSR checking required}
  $74/$09/                             {         JZ      Int2b                      ;No -- skip it}
                                       {;}
  $8B/$16/>ASYNC_UART_MSR/             {         MOV     DX,[>Async_Uart_MSR]       ;Get modem status register}
  $EC/                                 {         IN      AL,DX}
  $A8/<ASYNC_DSR/                      {         TEST    AL,<Async_DSR              ;Check for Data Set Ready}
  $74/$2E/                             {         JZ      Int2e                      ;If not DSR, turn off write interrupts}
                                       {;}
  $F6/$06/>ASYNC_DO_CTS/$01/           {Int2b:   TEST    BYTE [<Async_Do_CTS],1     ;See if CTS checking required}
  $74/$09/                             {         JZ      Int2c                      ;No -- skip it}
                                       {;}
  $8B/$16/>ASYNC_UART_MSR/             {         MOV     DX,[>Async_Uart_MSR]       ;Get modem status register}
  $EC/                                 {         IN      AL,DX}
  $A8/<ASYNC_CTS/                      {         TEST    AL,<Async_CTS              ;Check for Clear To Send}
  $74/$1E/                             {         JZ      Int2e                      ;If not CTS, turn off write ints}
                                       {;}
                                       {;  All status lines look OK.}
                                       {;  Send the XOFF.}
                                       {;}
  $B0/<XOFF/                           {Int2c:   MOV     AL,<XOFF                   ;Get XOFF Character}
  $8B/$16/>ASYNC_BASE/                 {         MOV     DX,[>Async_Base]           ;Get transmit hold register address}
  $EE/                                 {         OUT     DX,AL                      ;Output the XOFF}
  $C6/$06/>ASYNC_SEND_XOFF/$00/        {         MOV     BYTE [<Async_Send_XOFF],0  ;Turn off send XOFF flag}
  $C6/$06/>ASYNC_XOFF_SENT/$01/        {         MOV     BYTE [<Async_XOFF_Sent],1  ;Turn on sent XOFF flag}
  $E9/$08/$FF/                         {         JMP     NEAR Poll                  ;Return}
                                       {;}
                                       {;  Not sending XOFF -- see if any character in buffer to be sent.}
                                       {;}
  $8B/$1E/>ASYNC_OBUFFER_TAIL/         {Int2d:   MOV     BX,[>Async_OBuffer_Tail]   ;Pick up output buffer pointers}
  $3B/$1E/>ASYNC_OBUFFER_HEAD/         {         CMP     BX,[>Async_OBuffer_Head]}
  $75/$0B/                             {         JNE     Int2m                      ;Skip if not equal --> something to send}
                                       {;}
                                       {;  If nothing to send, turn off write interrupts to avoid unnecessary}
                                       {;  time spent handling useless THRE interrupts.}
                                       {;}
  $8B/$16/>ASYNC_UART_IER/             {Int2e:   MOV     DX,[>Async_Uart_IER]       ;If nothing -- or can't -- send ...}
  $EC/                                 {         IN      AL,DX                      ;}
  $24/$FD/                             {         AND     AL,$FD                     ;}
  $EE/                                 {         OUT     DX,AL                      ;... disable write interrupts}
  $E9/$F3/$FE/                         {         JMP     NEAR Poll                  ;}
                                       {;}
                                       {;  If something to send, ensure that remote system didn't send us XOFF.}
                                       {;  If it did, we can't send anything, so turn off write interrupts and}
                                       {;  wait for later (after an XON has been received).}
                                       {;}
  $F6/$06/>ASYNC_XOFF_RECEIVED/$01/    {Int2m:   TEST    BYTE [<Async_XOFF_Received],1 ;See if we received XOFF}
  $75/$EE/                             {         JNZ     Int2e                      ;Yes -- can't send anything now}
                                       {;}
                                       {;  If we can send character, check DSR and CTS as requested.}
                                       {;  If those status lines aren't ready, turn off write interrupts and}
                                       {;  try later, after a line status change.}
                                       {;}
  $8B/$16/>ASYNC_UART_MSR/             {         MOV     DX,[>Async_Uart_MSR]       ;Otherwise get modem status}
  $EC/                                 {         IN      AL,DX}
  $A2/>ASYNC_MODEM_STATUS/             {         MOV     [>Async_Modem_Status],AL   ;and save modem status for later}
                                       {;}
  $F6/$06/>ASYNC_DO_DSR/$01/           {         TEST    BYTE [<Async_Do_DSR],1     ;See if DSR checking required}
  $74/$04/                             {         JZ      Int2n                      ;No -- skip it}
                                       {;}
  $A8/<ASYNC_DSR/                      {         TEST    AL,<Async_DSR              ;Check for Data Set Ready}
  $74/$DB/                             {         JZ      Int2e                      ;If not DSR, turn off write ints}
                                       {;}
  $F6/$06/>ASYNC_DO_CTS/$01/           {Int2n:   TEST    BYTE [<Async_Do_CTS],1     ;See if CTS checking required}
  $74/$04/                             {         JZ      Int2o                      ;No -- skip it}
                                       {;}
  $A8/<ASYNC_CTS/                      {         TEST    AL,<Async_CTS              ;Check for Clear To Send}
  $74/$D0/                             {         JZ      Int2e                      ;If not CTS, turn off write ints}
                                       {;}
                                       {;  Everything looks OK for sending, so send the character.}
                                       {;}
  $C4/$3E/>ASYNC_OBUFFER_PTR/          {Int2o:   LES     DI,[>Async_OBuffer_Ptr]    ;Get output buffer pointer}
  $01/$DF/                             {         ADD     DI,BX                      ;Position to character to output}
  $26/$8A/$05/                         {     ES: MOV     AL,[DI]                    ;Get character to output}
  $8B/$16/>ASYNC_BASE/                 {         MOV     DX,[>Async_Base]           ;Get transmit hold register address}
  $EE/                                 {         OUT     DX,AL                      ;Output the character}
                                       {;}
  $FF/$0E/>ASYNC_OBUFFER_USED/         {         DEC     WORD [>Async_OBuffer_Used] ;Decrement count of chars in buffer}
  $43/                                 {         INC     BX                         ;Increment tail pointer}
  $3B/$1E/>ASYNC_OBUFFER_SIZE/         {         CMP     BX,[>Async_OBuffer_Size]   ;See if past end of buffer}
  $7E/$02/                             {         JLE     Int2z}
  $31/$DB/                             {         XOR     BX,BX                      ;If so, wrap to front}
                                       {;}
  $89/$1E/>ASYNC_OBUFFER_TAIL/         {Int2z:   MOV     [>Async_OBuffer_Tail],BX   ;Store updated buffer tail}
  $E9/$AC/$FE/                         {         JMP     NEAR Poll}
                                       {;}
                                       {;  --- Line status change ---}
                                       {;}
  $3C/$06/                             {Int6:    CMP     AL,6                       ;Check for line status interrupt}
  $75/$11/                             {         JNE     Int0                       ;No -- skip.}
                                       {;}
  $8B/$16/>ASYNC_UART_LSR/             {         MOV     DX,[>Async_Uart_LSR]       ;Yes -- pick up line status register}
  $EC/                                 {         IN      AL,DX                      ;and its contents}
  $24/$1E/                             {         AND     AL,$1E                     ;Strip unwanted bits}
  $A2/>ASYNC_LINE_STATUS/              {         MOV     [>Async_Line_Status],AL    ;Store for future reference}
  $08/$06/>ASYNC_LINE_ERROR_FLAGS/     {         OR      [>Async_Line_Error_Flags],AL ;Add to any past transgressions}
  $E9/$97/$FE/                         {         JMP     NEAR Poll}
                                       {;}
                                       {;  --- Modem status change ---}
                                       {;}
  $3C/$00/                             {Int0:    CMP     AL,0                       ;Check for modem status change}
  $74/$03/                             {         JE      Int0a                      ;Yes -- handle it}
  $E9/$90/$FE/                         {         JMP     NEAR Poll                  ;Else get next interrupt}
                                       {;}
  $8B/$16/>ASYNC_UART_MSR/             {Int0a:   MOV     DX,[>Async_Uart_MSR]       ;Pick up modem status reg. address}
  $EC/                                 {         IN      AL,DX                      ;and its contents}
  $A2/>ASYNC_MODEM_STATUS/             {         MOV     [>Async_Modem_Status],AL   ;Store for future reference}
  $E8/$03/$00/                         {         CALL    EnabWI                     ;Turn on write interrupts, in case}
                                       {;                                           ;status change resulted from CTS/DSR}
                                       {;                                           ;changing state.}
  $E9/$82/$FE/                         {         JMP     NEAR Poll}
                                       {;}
                                       {;  Internal subroutine to enable write interrupts.}
                                       {;}
                                       {EnabWI: ;PROC    NEAR}
  $8B/$16/>ASYNC_UART_IER/             {         MOV     DX,[>Async_Uart_IER]       ;Get interrupt enable register}
  $EC/                                 {         IN      AL,DX                      ;Check contents of IER}
  $A8/$02/                             {         TEST    AL,2                       ;See if write interrupt enabled}
  $75/$03/                             {         JNZ     EnabRet                    ;Skip if so}
  $0C/$02/                             {         OR      AL,2                       ;Else enable write interrupts ...}
  $EE/                                 {         OUT     DX,AL                      ;... by rewriting IER contents}
  $C3/                                 {EnabRet: RET                                ;Return to caller}
                                       {;}
                                       {;  Send non-specific EOI to 8259 controller.}
                                       {;}
  $B0/$20/                             {Back:    MOV     AL,$20                     ;EOI = $20}
  $E6/$20);                            {         OUT     $20,AL}

