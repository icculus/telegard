{Include file INTS.INC.  INLINE macros to disable and enable interrupts.}

PROCEDURE disable_interrupts;
INLINE
  (
  $FA    {CLI}
  );

PROCEDURE enable_interrupts;
INLINE
  (
  $FB    {STI}
  );


