(*---------------------------------------------------------------------**
**                                                                     **
**                  COMMUNICATIONS HARDWARE ADDRESSES                  **
**                                                                     **
**        These are specific to IBM PCs and close compatibles.         **
**                                                                     **
**---------------------------------------------------------------------*)

const
  UART_THR = $00;        { offset from base of UART Registers for IBM PC }
  UART_RBR = $00;
  UART_IER = $01;
  UART_IIR = $02;
  UART_LCR = $03;
  UART_MCR = $04;
  UART_LSR = $05;
  UART_MSR = $06;

  I8088_IMR = $21;       { port address of the Interrupt Mask Register }

  COM1_Base = $03F8;     { port addresses for the UART }
  COM2_Base = $02F8;
  COM3_Base = $03E8;
  COM4_Base = $02E8;

  COM1_Irq = 4;          { Interrupt line for the UART }
  COM2_Irq = 3;
  COM3_Irq = 4;
  COM4_Irq = 3;

  RS232_Base = $0400;    { Address of RS 232 com port pointer }

  MaxComPorts = 4;       { Four ports allowed by this code    }

const
          { Port addresses of each com port }
  default_com_base:array[1..maxcomports] of word =
    ( COM1_Base, COM2_Base, COM3_Base, COM4_Base );

          { IRQ line for each port }
  default_com_irq:array[1..maxcomports] of integer =
    ( COM1_Irq, COM2_Irq, COM3_Irq, COM4_Irq );

 {----------------------------------------------------------------------}
 {                                                                      }
 {                   COMMUNICATIONS BUFFER VARIABLES                    }
 {                                                                      }
 {     The communications buffers are implemented as circular (ring)    }
 {     buffers, or double-ended queues.  The asynchronous I/O routines  }
 {     enter characters in the receive buffer as they arrive at the     }
 {     serial port.  Higher-level routines may extract characters from  }
 {     the receive buffer at leisure.  Higher-level routines insert     }
 {     characters into the send buffer.  The asynchronous I/O routines  }
 {     then send characters out the serial port when possible.          }
 {                                                                      }
 {----------------------------------------------------------------------}

const
  timeout    = 256;                         { TimeOut value                   }
  async_xon  = ^Q;                          { XON character                   }
  async_xoff = ^S;                          { XOFF character                  }

  async_overrun_error = 2;                  {   overrun                       }
  async_parity_error  = 4;                  {   parity error                  }
  async_framing_error = 8;                  {   framing error                 }
  async_break_found   = 16;                 {   break interrupt               }

  async_cts = $10;                          {   Clear to send                 }
  async_dsr = $20;                          {   Data set ready                }

type
  async_buffer_type = array[0..1] of char;  { I/O buffer type for serial port }
  async_ptr = ^async_buffer_type;

var
  com_base:array[1..maxcomports] of word;   { Port addresses for serial ports }
  com_irq:array[1..maxcomports] of integer; { IRQ line for each serial port   }

const async_buffer_max=5120;

var
  async_buffer:array[0..async_buffer_max] of char;

  async_buffer_ptr       : async_ptr;     { Input buffer address  }
  async_obuffer_ptr      : async_ptr;     { Output buffer address }

  async_open_flag        : boolean;       { true if port opened               }
  async_port,                             { current open port number (1 -- 4) }
  async_base,                             { base for current open port        }
  async_irq,                              { IRQ for current open port         }
  async_rs232            : integer;       { RS232 address for current port    }

  async_buffer_overflow  : boolean;    { True if buffer overflow has happened }
  async_buffer_used,                   { Amount of input buffer used so far   }
  async_maxbufferused    : integer;    { Maximum amount of input buffer used  }

                                       { Async_Buffer empty if Head = Tail    }
  async_buffer_head,                   { Loc in Async_Buffer to put next char }
  async_buffer_tail,                   { Loc in Async_Buffer to get next char }
  async_buffer_newtail   : integer;    { For updating tail value              }

  async_obuffer_overflow : boolean;    { True if buffer overflow has happened }
  async_obuffer_used,                  { Amount of output buffer used         }
  async_maxobufferused   : integer;    { Max amount of output buffer used     }

                                       { Async_OBuffer empty if Head = Tail    }
  async_obuffer_head,                  { Loc in Async_OBuffer to put next char }
  async_obuffer_tail,                  { Loc in Async_OBuffer to get next char }
  async_obuffer_newtail  : integer;    { For updating tail value              }

  async_buffer_low,                    { Low point in receive buffer for XON  }
  async_buffer_high,                   { High point in receive buffer for XOFF}
  async_buffer_high_2    : integer;    { Emergency point for XOFF             }

  async_xoff_sent,                        { If XOFF sent                      }
  async_send_xoff,                        { TRUE to send XOFF ASAP            }
  async_xoff_received,                    { If XOFF received                  }
  async_xoff_rec_display,                 { If XOFF received                  }
  async_xon_rec_display  : boolean;       { If XOFF received                  }
  async_baud_rate        : word;          { Current baud rate                 }

  async_save_iaddr       : pointer;    { Save previous serial interrupt status}
  async_do_cts,                        { TRUE to do clear-to-send checking    }
  async_do_dsr,                        { TRUE to do data-set-ready checking   }
  async_do_xonxoff,                    { TRUE to do XON/XOFF flow checking    }
  async_hard_wired_on    : boolean;    { TRUE if hard-wired connection        }
  async_break_length     : integer;    { Length of break in 1/10 seconds      }
  async_line_status,                   { Line Status Reg at interrupt         }
  async_modem_status,                  { Modem Status Reg at interrupt        }
  async_line_error_flags : byte;       { Line status bits accumulated         }
  async_buffer_size,                   { Stores input buffer size             }
  async_obuffer_size,                  { Stores output buffer size            }
  async_uart_IER,                      { Interrupt enable register address    }
  async_uart_IIR,                      { Interrupt ID register address        }
  async_uart_MSR,                      { Modem status register address        }
  async_uart_LSR,                      { Line status register address         }
  async_output_delay,                  { Delay in ms when output buffer full  }
  async_onemsdelay       : integer;    { Loop count value to effect 1 ms delay}

  async_send_addr        : async_ptr;  { pointer to Async_Send routine        }

