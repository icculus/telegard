;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;+                                                                + 
;+          This asm file contains 2 pascal procedures for        +  
;+          linking with TTT version 5.0. The procedures are:     +
;+                                                                +
;+           scrolllistup;                                        +
;+           scrolllistdown;                                      +
;+                                                                + 
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


data      segment   byte      public
          extrn     snowcheck:byte
          extrn     usebios:byte
          extrn     vidseg:word
          extrn     windmin,windmax:word
          xpos      db        ?
          ypos      db        ?
data      ends


code      segment   byte      public

          assume    cs:code,ds:data
          public    fastchr

;++++++++++++++++++++++++++++++++++++
;+     C A L M E M P O I N T E R    +
;++++++++++++++++++++++++++++++++++++

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;+                                                                +
;+    CALCMEMPOINTER is a local procedure that is called by       +
;+    Fastwrite, PlainWrite and Attribute. It places the segment  +
;+    and offset of the first attribute, in ES:DI ready for an    +
;+    LDS. Vseg and Vofs point to the first attribute of the      +
;+    screen, the final location is computed by adding Row*160    +
;+    (80 attribs and 80 chars per row) and then adding 2*Col.    +
;+    The passed Row and Column are decremented by one to fit     +
;+    with DOS's 0..79, 0..24 coordinate system.                  + 
;+                                                                +
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

calcmempointer      proc near

          xor       ax,ax                         ;AX=0
          mov       cl,al                         ;CL=0
          mov       bh,al                         ;BH=0
          shr       cx,1                          ;CX=Y*128
          mov       di,cx                         ;store in DI
          shr       di,1                          ;DI=y*64
          shr       di,1                          ;DI=y*32
          add       di,cx                         ;DI=y*160
          shl       bx,1                          ;account for attribute bytes
          add       di,bx                         ;DI=(y*160)+(x*2)
          mov       es,vidseg           ;ES:DI points to color attribute
          ret

calcmempointer      endp

;+++++++++++++++++++++++++++++++++++++++
;+     F A S T C H R                   +
;+++++++++++++++++++++++++++++++++++++++

wattr     equ       byte ptr [bp+6]               ;write attribute
wchr      equ       byte ptr [bp+8]               ;write character

fastchr   proc      far

          push      bp                            ;Save BP
          mov       bp,sp                         ;Set up stack frame

          mov       ax,40h
          mov       es,ax
          mov       bx,es:word ptr [0050h]        ;X position [0040:0050]
          mov       cx,es:word ptr [0051h]        ;Y position [0040:0051]

          mov       xpos,bl
          mov       ypos,cl

          cmp       usebios,1                     ;check whether to use BIOS
          je        FCusebios1

FCdirectscr1:
          mov       ch,cl
          mov       cl,0
          mov       bh,cl
          call      calcmempointer
          mov       bh,wattr                      ;attribute
          mov       bl,wchr                       ;character

          cmp       snowcheck,1                   ;check whether to check snow
          jne       FCdoch5
          push      ax
          mov       dx,03DAh
FCdoch1:
          cli                                     ;interrupts OFF
FCdoch2:
          in        al,dx                         ;get 6845 status
          test      al,8                          ;check for vertical retrace
          jnz       FCdoch4                       ;in progress? go..
          rcr       al,1                          ;wait for end of horizontal
          jc        FCdoch2                       ; retrace
FCdoch3:
          in        al,dx                         ;get 6845 status again
          rcr       al,1                          ;wait for horizontal
          jnc       FCdoch3                       ; retrace
FCdoch4:
          mov       ax,bx
          stosw                                   ;store video word into ES:DI
          sti                                     ;interrupts ON
          jmp       FCdoch6                       ;ALL DONE!
FCdoch5:
          mov       ax,bx
          stosw                                   ;no waiting!!!!!
FCdoch6:
          jmp       FCmovecursor

FCusebios1:
;assumes that cursor is already positioned to the correct place on the screen
          mov       ah,9                ;service=write attr & chr at cursor
          mov       al,wchr                       ;write character
          mov       bh,0                          ;page 0
          mov       bl,wattr                      ;write attribute
          mov       cx,1                          ;write 1x
          int       10h

FCmovecursor:
          mov       ax,windmin
          mov       bx,windmax

          mov       dl,xpos                       ;X pos in DL
          mov       dh,ypos                       ;Y pos in DH

          inc       dl                            ;increment X

          cmp       dl,bl                         ;is X>79 ??
          jg        FCmc1
          jmp       FCnoscroll
FCmc1:
          mov       dl,al                         ;X:=0
          inc       dh                            ;increment Y
          cmp       dh,bh                         ;is Y>25 ??
          jg        FCmc2
          jmp       FCnoscroll
FCmc2:

;scrolling stuff

          cmp       usebios,1                     ;check whether to use BIOS
          jne       FCdirectscr2
          jmp       FCusebios2

FCdirectscr2:
          push      ds                            ;save DS ...
          mov       al,snowcheck                  ;grab before changing DS
          push      ax

          mov       dx,windmax
          mov       cx,windmin
          sub       dh,ch                         ;difference in DH (Y)
          mov       dl,0
          shr       dx,1                          ;DX=Y*128
          shr       dx,1                          ;DX=Y*64
          mov       cx,dx                         ;store in CX
          shr       cx,1                          ;CX=Y*32
          shr       cx,1                          ;CX=Y*16
          add       cx,dx                         ;CX=Y*80
          push      cx

          mov       cx,0
          mov       bx,windmin                    ;BL=X position
          mov       ch,bh                         ;CH=Y position
          mov       bh,0
          inc       ch                            ;2nd line of window
          call      calcmempointer
          mov       ds,vidseg
          mov       si,di                         ;DS:SI

          mov       dx,ds
          mov       es,dx                         ;ES:DI
          sub       di,0A0h

          pop       cx

          cld                                     ;set direction to FORWARD
          pop       ax
          cmp       al,1                          ;check whether to check snow
          jne       FCdscr5
          mov       dx,03DAh
FCdscr1:
          cli                                     ;interrupts OFF
FCdscr2:
          in        al,dx                         ;get 6845 status
          test      al,8                          ;check for vertical retrace
          jnz       FCdscr4                       ;in progress? go..
          rcr       al,1                          ;wait for end of horizontal
          jc        FCdscr2                       ; retrace
FCdscr3:
          in        al,dx                         ;get 6845 status again
          rcr       al,1                          ;wait for horizontal
          jnc       FCdscr3                       ; retrace
FCdscr4:
          movsw                                   ;move it out...
          sti                                     ;interrupts ON
          loop      FCdscr1                       ;get next video word
          jmp       FCdscr6                       ;ALL DONE!
FCdscr5:
          rep       movsw                         ;no waiting!!!!!
FCdscr6:
          pop       ds
          mov       cx,windmin
          mov       dx,windmax
          mov       dl,cl
          jmp       FCnoscroll

FCusebios2:
          mov       cx,ax                         ;windmin
          mov       dx,bx                         ;windmax
          mov       ax,0601h                      ;func=scroll up, 1 line
          mov       bh,wattr
          int       10h

          mov       dl,cl                         ;X=windmin's X position (1)

FCnoscroll:
          mov       ah,2
          mov       bh,0
          int       10h

          mov       sp,bp                         ;Restore SP
          pop       bp                            ;Restore BP
          ret                                     ;Remove parameters and return

fastchr   endp

code      ends

          end

