inline(
                                  {;}
                                  {;  Check if any characters in input comm buffer}
                                  {;}
  $A1/>ASYNC_BUFFER_TAIL/         {         MOV   AX,[>Async_Buffer_Tail]}
  $3B/$06/>ASYNC_BUFFER_HEAD/     {         CMP   AX,[>Async_Buffer_Head]}
  $75/$0B/                        {         JNE   Rec1}
                                  {;}
                                  {;  Buffer is empty -- return NUL character}
                                  {;}
  $C4/$7E/<C/                     {         LES   DI,[BP+<C]                   ;Get character address}
  $31/$C0/                        {         XOR   AX,AX                        ;Clear out unused bits}
  $26/$88/$05/                    {     ES: MOV   [DI],AL                      ;NUL character}
  $E9/$3F/$00/                    {         JMP   Return}
                                  {;}
                                  {;  Buffer not empty -- pick up next character.}
                                  {;}
  $C4/$3E/>ASYNC_BUFFER_PTR/      {Rec1:    LES   DI,[>Async_Buffer_Ptr]       ;Pick up buffer address}
  $01/$C7/                        {         ADD   DI,AX                        ;Add character offset}
  $26/$8A/$1D/                    {     ES: MOV   BL,[DI]                      ;Get character from buffer}
  $C4/$7E/<C/                     {         LES   DI,[BP+<C]                   ;Get result address}
  $26/$88/$1D/                    {     ES: MOV   [DI],BL                      ;Store character from buffer}
  $40/                            {         INC   AX                           ;Increment tail pointer}
  $3B/$06/>ASYNC_BUFFER_SIZE/     {         CMP   AX,[>Async_Buffer_Size]      ;Past end of buffer?}
  $7E/$02/                        {         JLE   Rec2                         ;No -- skip wrapping}
  $31/$C0/                        {         XOR   AX,AX                        ;Yes -- point to start of buffer}
  $A3/>ASYNC_BUFFER_TAIL/         {Rec2:    MOV   [>Async_Buffer_Tail],AX      ;Update tail pointer}
  $FF/$0E/>ASYNC_BUFFER_USED/     {         DEC   Word [>Async_Buffer_Used]    ;Update buffer use count}
                                  {;}
                                  {; If XOFF previously sent because buffer was too full, and}
                                  {; now buffer is reasonably empty, send XON to get things rolling again.}
                                  {;}
  $90/$90/$90/$90/$90/            {         NOP NOP NOP NOP NOP }
  $EB/$16/                        {         JMP   Rec3                         ;Skip.}
(*  $F6/$06/>ASYNC_XOFF_SENT/$01/   {         TEST  BYTE [<Async_XOff_Sent],1    ;Check if Xoff sent}*)
(*  $74/$16/                        {         JZ    Rec3                         ;No -- skip.}*)
                                  {;}
  $A1/>ASYNC_BUFFER_USED/         {         MOV   AX,[>Async_Buffer_Used]      ;Pick up amount of buffer used}
  $3B/$06/>ASYNC_BUFFER_LOW/      {         CMP   AX,[>Async_Buffer_Low]       ;Check if low enough}
  $7F/$0D/                        {         JG    Rec3                         ;Still too full, skip}
                                  {;}
  $B8/>XON/                       {         MOV   AX,>XON                      ;Else push XON onto stack}
  $50/                            {         PUSH  AX}
  $FF/$1E/>ASYNC_SEND_ADDR/       {         CALL  FAR [>Async_Send_Addr]       ;Call output routine}
                                  {;}
  $C6/$06/>ASYNC_XOFF_SENT/$00/   {         MOV   BYTE [>Async_XOff_Sent],0    ;Clear Xoff flag}
                                  {;}
                                  {;  Indicate character found}
                                  {;}
  $B8/$01/$00/                    {Rec3:    MOV    AX,1}
                                  {;}
  $80/$26/>ASYNC_LINE_STATUS/$FD/ {Return:  AND    Byte [>Async_Line_Status],$FD ;Remove overflow flag}
  $09/$C0/                        {         OR     AX,AX                       ;Set zero flag to indicate return status}
  $89/$EC/                        {         MOV    SP,BP}
  $5D/                            {         POP    BP}
  $CA/$04/$00);                   {         RETF   4}


