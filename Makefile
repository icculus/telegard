#---------------------------------------------------------------------------
# Makefile by Ryan C. Gordon (icculus@lokigames.com)
#---------------------------------------------------------------------------

# should be 386, mmx, 686, or other.
#
#  386 and 486 chips use "386"
#  Pentiums, Celerons, PentiumMMX should use "mmx"
#  PentiumPro, PII, PIII, K6, Cyrix686/MII, Athlon, etc. should use "686"
#  PowerPC and other non-x86 chips should use "other"
cpu=686

# Are you debugging?  Specify "true". Release binaries?  "false".
debug=true

# want to see more verbose compiles? Set this to "true".
verbose=true

# You probably don't need to touch this one. This is the location of
#  your copy of PPC386, if it's not in the path.
#  Get this from http://www.freepascal.org/ ...
PPC386=ppc386

#---------------------------------------------------------------------------
# don't touch anything below this line.

# This is the name of the produced binary. "bbs" should suffice.
MAINEXE=bbs

ifeq ($(strip $(verbose)),true)
    PPC386FLAGS += -vwnh
endif

ifeq ($(strip $(debug)),true)
    BUILDDIR := $(cpu)/Debug
    PPC386FLAGS += -g    # include debug symbols.
    PPC386FLAGS += -gc   # generate checks for pointers.
    PPC386FLAGS += -Ct   # generate stack-checking code.
    PPC386FLAGS += -Cr   # generate range-checking code.
    PPC386FLAGS += -Co   # generate overflow-checking code.
    PPC386FLAGS += -Ci   # generate I/O-checking code.
else
    BUILDDIR := $(cpu)/Release
    PPC386FLAGS += -Xs   # strip the binary.
    PPC386FLAGS += -O2   # Level 2 optimizations.
    PPC386FLAGS += -OG   # Optimize for speed, not size.

    ifeq ($(strip $(cpu)),386)
        PPC386FLAGS += -OP1
    else
        ifeq ($(strip $(cpu)),mmx)
            PPC386FLAGS += -OP2
        else
            ifeq ($(strip $(cpu)),686)
                PPC386FLAGS += -OP3
            endif
        endif
    endif
endif

# Borland TP7.0 compatibility flag.
PPC386FLAGS += -So

# Support C-style macros.
#PPC386FLAGS += -Sm

# Assembly statements are Intel-like (instead of AT&T-like).
PPC386FLAGS += -Rintel

# Dynamic linkage.
PPC386FLAGS += -XD

# Output target Linux.  !!! FIXME: Want win32 compiles?
PPC386FLAGS += -TLINUX

# Smartlink the binary, removing unused code.
PPC386FLAGS += -CX

# Pipe output to assembler, rather than to temp file. This is a little faster.
PPC386FLAGS += -P

# Write bins to this directory...
PPC386FLAGS += -FE$(BUILDDIR)

#---------------------------------------------------------------------------
# Build rules...don't touch this, either.

include sources

OBJSx := $(SRCS:.pas=.o)
OBJS := $(foreach feh,$(OBJSx),$(BUILDDIR)/$(feh))

$(BUILDDIR)/%.o : %.pas
	$(PPC386) $(PPC386FLAGS) $<

all: $(MAINEXE)

$(MAINEXE) : $(BUILDDIR) $(OBJS) bbs.pas
	$(PPC386) $(PPC386FLAGS) bbs.pas

$(BUILDDIR): $(cpu)
	mkdir $(BUILDDIR)

$(cpu):
	mkdir $(cpu)

clean:
	rm -rf $(BUILDDIR)
	rm -rf core

# end of Makefile ...

