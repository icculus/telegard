{$A+,B+,D-,E+,F+,I+,L-,N-,O-,R-,S+,V-}
unit common;

interface

uses
  crt,dos,printer,
  myio,tmpcom,timejunk;

{$I func.pas}
{$I rec25.pas}

const strlen=160;
      dsaves:integer=0;
      BOXEDTITLE='`#[';
      sepr2=#3#4+':'+#3#3;

type f_initexecswap = function(p:pointer; s:string):boolean;
     f_execwithswap = function(p,c:string):word;
     p_shutdownexecswap = procedure;

var initexecswap2:f_initexecswap;
    execwithswap2:f_execwithswap;
    shutdownexecswap2:p_shutdownexecswap;

var uf:file of userrec;           { USER.LST                              }
    bf:file of boardrec;          { BOARDS.DAT                            }
    xf:file of protrec;           { PROTOCOL.DAT                          }
    ulf:file of ulrec;            { UPLOADS.DAT                           }
    ulff:file of ulfrec;          { *.DIR                                 }
    sf:file of smalrec;           { NAMES.LST                             }
    smf:file of smr;              { SHORTMSG.DAT                          }
    verbf:file of verbrec;        { VERBOSE.DAT                           }
    mixf:file;                    { *.MIX                                 }
    brdf:file;                    { *.BRD                                 }

    sysopf,                       { SYSOP.LOG                             }
    sysopf1,                      { SLOGxxxx.LOG                          }
    trapfile,                     { TRAP*.MSG                             }
    cf:text;                      { CHAT*.MSG                             }

    systat:systatrec;             { configuration information             }
    fstring:fstringrec;           { string configuration                  }
    modemr:modemrec;              { modem configuration                   }
    fidor:fidorec;                { FidoNet information                   }

    thisuser:userrec;             { user's account records                }
    macros:macrorec;              { user's macros, if any                 }
    zscanr:zscanrec;              { user's zscan records                  }

    { BRD files }
    msg_on:integer;               { current message being read            }

    { EVENTS }
    events:array[0..maxevents] of ^eventrec;
    numevents:integer;            { # of events                           }

    { PROTOCOLS }
    protocol:protrec;             { protocol in memory                    }
    numprotocols:integer;         { # of protocols                        }

    { FILE BASES }
    memuboard,tempuboard:ulrec;   { uboard in memory, temporary uboard    }
    readuboard,                   { current uboard # in memory            }
    maxulb,                       { # of file bases                       }
    fileboard:integer;            { file base user is in                  }

    { MESSAGE BASES }
    memboard:boardrec;            { board in memory                       }
    readboard,                    { current board # in memory             }
    numboards,                    { # of message bases                    }
    board:integer;                { message base user is in               }

    { FILE/MESSAGE BASE COMPRESSION TABLES }
    ccboards:array[0..1,1..maxboards] of byte;
    ccuboards:array[0..1,0..maxuboards] of byte;

    spd:string[6];                { current modem speed, "KB" for local   }
    spdarq:boolean;               { whether modem connected with ARQ      }

(*****************************************************************************)

    { message stuff }
    mintabloaded:word;            { minor table loaded }
    mintaboffset:longint;         { minor table file offset }
    mintab:array[0..99] of msgindexrec; { minor table }
    himsg:longint;                { highest message number }
    himintab:longint;             { highest minor table number }


    buf:string[255];              { macro buffer                          }

    sitedatetime:packdatetime;    { last time site compiled/changed status }

    vercs:string;
    vertypes:byte;                { Alpha/Beta/etc, Registered, Node      }

    chatr,                        { last chat reason                      }
    cmdlist,                      { list of cmds on current menu          }
    irt,                          { reason for reply                      }
    lastname,                     { author of last message displayed      }
    lastuname,                    { last name, whether anon or not        }
    licenseinfo,                  { licensing info, if present            }
    ll,                           { "last-line" string for word-wrapping  }
    start_dir:string;             { directory BBS was executed from       }

    tim,                          { time last keystroke entered           }
    timeon:datetimerec;           { time user logged on                   }

    choptime,                     { time to chop off for system events    }
    extratime,                    { extra time - given by F7/F8, etc      }
    freetime,                     { free time                             }
    oltime:real;

    answerbaud,                   { baud rate to answer the phone at      }
    exteventtime,                 { # minutes before external event       }
    maxheapspace,                 { max heap space available              }
    serialnumber:longint;         { serial number, if present             }

    chatt,                        { number chat attempts made by user     }
    etoday,                       { E-mail sent by user this call         }
    ftoday,                       { feedback sent by user this call       }
    lastprot,                     { last protocol #                       }
    ldate,                        { last daynum()                         }
    lil,                          { lines on screen since last pausescr() }
    mread,                        { # public messages has read this call  }
    pap,                          { characters on this line so far        }
    ptoday,                       { posts made by user this call          }
    realdsl,                      { real DSL level of user                }
    realsl,                       { real SL level of user (for F9)        }
    usernum:integer;              { user's user number                    }
 
    bread,                        { board loaded, or -1 for e-mail        }
    bwant:integer;

    chelplevel,                   { current help level                    }
    curco,                        { current ANSI color                    }
    elevel,                       { ERRORLEVEL to exit with               }
    tshuttlelogon:byte;           { type of special Shuttle Logon command }

const
    allowabort:boolean=TRUE;      { are aborts allowed?                   }
    echo:boolean=TRUE;            { is text being echoed? (FALSE=use echo chr)}
    flistverb:boolean=TRUE;       { list verbose descriptions?            }
    hangup:boolean=TRUE;          { is user offline now?                  }
    nofile:boolean=TRUE;          { did last pfl() file NOT exist?        }
    onekcr:boolean=TRUE;          { does ONEK prints<CR> upon exit?       }
    onekda:boolean=TRUE;          { does ONEK display the choice?         }
    slogging:boolean=TRUE;        { are we outputting to the SysOp log?   }
    sysopon:boolean=TRUE;         { is SysOp logged onto the WFC menu?    }
    wantout:boolean=TRUE;         { output text locally?                  }
    wcolor:boolean=TRUE;          { in chat: was last key pressed by SysOp? }

    badfpath:boolean=FALSE;       { is the current DL path BAD?           }
    badufpath:boolean=FALSE;      { is the current UL path BAD?           }
    badini:boolean=FALSE;         { was last call to ini/inu value()=0, s<>"0"? }
    bchanged:boolean=FALSE;       { was BRD file changed?                 }
    beepend:boolean=FALSE;        { whether to beep after caller logs off }
    bnp:boolean=FALSE;            { was file base name printed yet?       }
    cfilteron:boolean=FALSE;      { is the color filter on?               }
    cfo:boolean=FALSE;            { is chat file open?                    }
    ch:boolean=FALSE;             { are we in chat mode?                  }
    chatcall:boolean=FALSE;       { is the chat call "noise" on?          }
    checkit:boolean=FALSE;        { }
    contlist:boolean=FALSE;       { continuous message listing mode on?   }
    croff:boolean=FALSE;          { are CRs turned off?                   }
    ctrljoff:boolean=FALSE;       { turn color to #1 after ^Js??          }
    cwindowon:boolean=FALSE;      { is SysOp window ON?                   }
    doneafternext:boolean=FALSE;  { offhook and exit after next logoff?   }
    doneday:boolean=FALSE;        { are we done now? ready to drop to DOS? }
    dosansion:boolean=FALSE;      { output chrs to DOS for ANSI codes?!!? }
    dyny:boolean=FALSE;           { does YN return Yes as default?        }
    enddayf:boolean=FALSE;        { perfrom "endday" after logoff?        }
    fastlogon:boolean=FALSE;      { if a FAST LOGON is requested          }
    hungup:boolean=FALSE;         { did user drop carrier?                }
    incom:boolean=FALSE;          { accepting input from com?             }
    inmsgfileopen:boolean=FALSE;  { are we //U ULing a file into a message? }
    inwfcmenu:boolean=FALSE;      { are we in the WFC menu?               }
    lan:boolean=FALSE;            { was last post/email anonymous/other?  }
    lastcommandgood:boolean=FALSE;{ was last command a REAL command?      }
    lastcommandovr:boolean=FALSE; { override PAUSE? (NO pause?)           }
    lmsg:boolean=FALSE;           { }
    macok:boolean=FALSE;          { are macros OKay right now?            }
    mailread:boolean=FALSE;       { did user delete some e-mail?          }
(*  minitermonly:boolean=FALSE;   { load up MiniTerm ONLY?                }*)
    localioonly:boolean=FALSE;    { local I/O ONLY?                       }
    packbasesonly:boolean=FALSE;  { pack message bases ONLY?              }
    mtcfilteron:boolean=FALSE;    { Manhattan Transfer color-filter active }
    mtcolors:boolean=FALSE;       { Manhattan Transfer colors in use      }
    newmenutoload:boolean=FALSE;  { menu command returns TRUE if new menu to load }
    nightly:boolean=FALSE;        { execute hard-coded nightly event?     }
    nofeed:boolean=FALSE;         { }
    nopfile:boolean=FALSE;        { }
    overlayinems:boolean=FALSE;   { is overlay file in EMS memory?        }
    outcom:boolean=FALSE;         { outputting to com?                    }
    printingfile:boolean=FALSE;   { are we printing a file?               }
    quitafterdone:boolean=FALSE;  { quit after next user logs off?        }
    reading_a_msg:boolean=FALSE;  { is user reading a message?            }
    readingmail:boolean=FALSE;    { reading private mail?                 }
    read_with_mci:boolean=FALSE;  { read message with MCI?                }
    returna:boolean=FALSE;        { return from MiniTerm and answer phone? }
    shutupchatcall:boolean=FALSE; { was chat call "SHUT UP" for this call? }
    smread:boolean=FALSE;         { were "small messages" read? (delete them) }
    trapping:boolean=FALSE;       { are we trapping users text?           }
    trm:boolean=FALSE;            { is MiniTerm in use?                   }
    useron:boolean=FALSE;         { is there a user on right now?         }
    wantfilename:boolean=FALSE;   { display message filename in scan?     }
    wascriterr:boolean=FALSE;     { critical error during last call?      }
    wasguestuser:boolean=FALSE;   { did a GUEST USER log on?              }
    wasnewuser:boolean=FALSE;     { did a NEW USER log on?                }
    write_msg:boolean=FALSE;      { is user writing a message?            }

    telluserevent:byte=0;     { has user been told about the up-coming event? }
    exiterrors:byte=254;          { ERRORLEVEL for Critical Error exit    }
    exitnormal:byte=255;          { ERRORLEVEL for Normal exit            }

    unlisted_filepoints=5;        { file points for unlisted downloads    }

var
    first_time:boolean;           { first time loading a menu?            }
    menustack:array[1..8] of string[12]; { menu stack                     }
    menustackptr:integer;         { menu stack pointer                    }
    last_menu,                    { last menu loaded                      }
    curmenu:string;                 { current menu loaded                   }
    menur:menurec;                { menu information                      }
    cmdr:array[1..50] of commandrec; { command information                }
    noc:integer;                  { # of commands on menu                 }
    fqarea,mqarea:boolean;        { file/message quick area changes       }

    doit,doitt:boolean;
    newdate:string[8];            { NewScan pointer date                  }
    lrn:integer;                  { last record # for recno/nrecno        }
    lfn:string;                     { last filename for recno/nrecno        }

    batchtime:real;               { }
    numbatchfiles:integer;        { # files in DL batch queue             }
    batch:array[1..20] of record
      fn:string[65];
      section:integer;
      pts:integer;
      blks:longint;
      tt:real;
    end;

    numubatchfiles:integer;       { # files in UL batch queue }
    ubatch:array[1..maxubatchfiles] of record
      fn:string[12];
      section:integer;
      description:string[65];
      vr:byte;
    end;
    ubatchv:array[1..maxubatchfiles] of ^verbrec;
    hiubatchv:integer;


function lenn(s:string):integer;
function lennmci(s:string):integer;
procedure loaduboard(i:integer);
procedure loadboard(i:integer);
function smci(c:char):string;
procedure sprompt(s:string);
procedure tc(n:integer);
function mso:boolean;
function fso:boolean;
function cso:boolean;
function so:boolean;
function timer:real;
function fbaseac(b:byte):boolean;
function mbaseac(nb:integer):boolean;
procedure newcomptables;
procedure changefileboard(b:integer);
procedure changeboard(b:integer);
function freek(d:integer):longint;    (* See disk space *)
function nma:integer;
function okansi:boolean;
function okavatar:boolean;
procedure cline(var s:string; dd:string);
function nsl:real;
function ageuser(bday:string):integer;     (* returns age of user by birthdate *)
function allcaps(s:string):string;    (* returns a COMPLETELY capitalized string *)
function caps(s:string):string;                (* returns a capitalized string.. *)
procedure remove_port;
procedure iport;
{procedure initthething;}
function getwindysize(wind:integer):integer;
procedure commandline(s:string);
procedure sclearwindow;
procedure schangewindow(needcreate:boolean; newwind:integer);
function ccinkey1:char;
function cinkey1:char;
procedure gameport;
procedure sendcom1(c:char);
function recom1(var c:char):boolean;
procedure term_ready(ready_status:boolean);
procedure checkhangup;
function cinkey:char;
{procedure o(c:char);}
function intime(tim:real; tim1,tim2:integer):boolean;
                                              (* check whether in time range *)
function sysop1:boolean;
function checkpw:boolean;
function sysop:boolean;
function stripcolor(o:string):string;
procedure sl1(s:string);
procedure sysoplog(s:string);
function tch(s:string):string;
function time:string;
function date:string;
function value(s:string):longint;
function cstr(i:longint):string;
function nam:string;
procedure shelldos(bat:boolean; cl:string; var rcode:integer);
procedure sysopshell(takeuser:boolean);
procedure readinzscan;
procedure savezscanr;
procedure redrawforansi;
function leapyear(yr:integer):boolean;
function days(mo,yr:integer):integer;
function daycount(mo,yr:integer):integer;
function daynum(dt:string):integer;
function dat:string;
procedure doeventstuff;
procedure getkey(var c:char);
procedure pr1(s:string);
procedure pr(s:string);
procedure sde; {* restore curco colors (DOS and tc) loc. after local *}
procedure sdc;
procedure stsc;
procedure setc(c:byte);
procedure cl(c:integer);
(*procedure promptc(c:char);*)
procedure dosansi(c:char);
procedure prompt(s:string);
function sqoutsp(s:string):string;
function exdrv(s:string):byte;
function mln(s:string; l:integer):string;
function mlnnomci(s:string; l:integer):string;
function mlnmci(s:string; l:integer):string;
function mrn(s:string; l:integer):string;
function mn(i,l:longint):string;
procedure pausescr;
procedure print(s:string);
procedure nl;
procedure prt(s:string);
procedure ynq(s:string);
procedure mpl(c:integer);
procedure tleft;
procedure prestrict(u:userrec);
procedure topscr;
procedure readinmacros;
procedure saveuf;
procedure loadurec(var u:userrec; i:integer);
procedure saveurec(u:userrec; i:integer);
function empty:boolean;
function inkey:char;
{procedure oc(c:char);}
procedure outkey(c:char);
function checkeventday(i:integer; t:real):boolean;
function checkpreeventtime(i:integer; t:real):boolean;
function checkeventtime(i:integer; t:real):boolean;
function checkevents(t:real):integer;
procedure dm(i:string; var c:char);
procedure cls;
procedure wait(b:boolean);
procedure swac(var u:userrec; r:uflags);
function tacch(c:char):uflags;
procedure acch(c:char; var u:userrec);
procedure sprint(s:string);
procedure lcmds(len,c:byte; c1,c2:string);
procedure autovalidate(var u:userrec; un:integer);
procedure rsm;
procedure inittrapfile;
procedure sysopstatus;
procedure chatfile(b:boolean);
function aonoff(b:boolean; s1,s2:string):string;
function onoff(b:boolean):string;
function syn(b:boolean):string;
procedure pyn(b:boolean);
function yn:boolean;
function pynq(s:string):boolean;
procedure inu(var i:integer);
procedure ini(var i:byte);
procedure inputwn1(var v:string; l:integer; flags:string; var changed:boolean);
procedure inputwn(var v:string; l:integer; var changed:boolean);
procedure inputwnwc(var v:string; l:integer; var changed:boolean);
procedure inputmain(var s:string; ml:integer; flags:string);
procedure inputwc(var s:string; ml:integer);
procedure input(var s:string; ml:integer);
procedure inputl(var s:string; ml:integer);
procedure inputcaps(var s:string; ml:integer);
procedure onek(var c:char; ch:string);
procedure local_input1(var i:string; ml:integer; tf:boolean);
procedure local_input(var i:string; ml:integer);
procedure local_inputl(var i:string; ml:integer);
procedure local_onek(var c:char; ch:string);
function centre(s:string):string;
procedure wkey(var abort,next:boolean);
function ctim(rl:real):string;
function tlef:string;
procedure printa1(s:string; var abort,next:boolean);
procedure printacr(s:string; var abort,next:boolean);
function longtim(dt:datetimerec):string;
function dt2r(dt:datetimerec):real;
procedure r2dt(r:real; var dt:datetimerec);
procedure timediff(var dt:datetimerec; dt1,dt2:datetimerec);
procedure getdatetime(var dt:datetimerec);
function cstrl(li:longint):string;
function cstrr(rl:real; base:integer):string;
procedure savesystat;  (* save systat *)
procedure pfl(fn:string; var abort,next:boolean; cr:boolean);
procedure printfile(fn:string);
function exist(fn:string):boolean;
procedure printf(fn:string);
procedure mmkey(var s:string);

procedure com_flush_rx;
function com_carrier:boolean;
function com_rx_empty:boolean;
procedure com_set_speed(speed:word);

procedure chat;
procedure skey(c:char);
procedure showudstats;
procedure skey1(c:char);
function verline(i:integer):string;
function aacs1(u:userrec; un:integer; s:string):boolean;
function aacs(s:string):boolean;

procedure DisableInterrupts;
procedure EnableInterrupts;

implementation

uses common1, common2, common3;

(*****************************************************************************\
 **
 **  These routines have been placed in the overlay to decrease the
 **  in-memory size of the BBS.  Routines that are used frequently, and are
 **  HIGHLY related to the overall speed of the BBS, have been kept out
 **  of the overlay file, and remain in memory at all times.
 **
\*****************************************************************************)
function checkpw:boolean; begin checkpw:=common1.checkpw; end;
procedure newcomptables; begin common1.newcomptables; end;
procedure cline(var s:string; dd:string); begin common1.cline(s,dd); end;
procedure pausescr; begin common1.pausescr; end;
procedure wait(b:boolean); begin common1.wait(b); end;
(*procedure fix_window; begin common1.fix_window; end;*)
procedure inittrapfile; begin common1.inittrapfile; end;
procedure chatfile(b:boolean); begin common1.chatfile(b); end;
procedure local_input1(var i:string; ml:integer; tf:boolean);
          begin common1.local_input1(i,ml,tf); end;
procedure local_input(var i:string; ml:integer);
          begin common1.local_input(i,ml); end;
procedure local_inputl(var i:string; ml:integer);
          begin common1.local_inputl(i,ml); end;
procedure local_onek(var c:char; ch:string);
          begin common1.local_onek(c,ch); end;
function chinkey:char; begin chinkey:=common1.chinkey; end;
procedure inli1(var s:string); begin common1.inli1(s); end;
procedure chat; begin common1.chat; end;
procedure sysopshell(takeuser:boolean);
          begin common1.sysopshell(takeuser); end;
procedure globat(i:integer); begin common1.globat(i); end;
procedure exiterrorlevel; begin common1.exiterrorlevel; end;
procedure showsysfunc; begin common1.showsysfunc; end;
procedure readinzscan; begin common1.readinzscan; end;
procedure savezscanr; begin common1.savezscanr; end;
procedure redrawforansi; begin common1.redrawforansi; end;

procedure showudstats; begin common2.showudstats; end;
procedure skey1(c:char); begin common2.skey1(c); end;
procedure savesystat; begin common2.savesystat; end;
procedure remove_port; begin common2.remove_port; end;
procedure iport; begin common2.iport; end;
{procedure initthething; begin common2.initthething; end;}
procedure gameport; begin common2.gameport; end;
procedure sendcom1(c:char); begin common2.sendcom1(c); end;
function recom1(var c:char):boolean; begin recom1:=common2.recom1(c); end;
procedure term_ready(ready_status:boolean); begin common2.term_ready(ready_status); end;
function getwindysize(wind:integer):integer; begin getwindysize:=common2.getwindysize(wind); end;
procedure commandline(s:string); begin common2.commandline(s); end;
procedure sclearwindow; begin common2.sclearwindow; end;
procedure schangewindow(needcreate:boolean; newwind:integer);
  begin common2.schangewindow(needcreate,newwind); end;
procedure topscr; begin common2.topscr; end;
procedure tleft; begin common2.tleft; end;
procedure readinmacros; begin common2.readinmacros; end;
procedure saveuf; begin common2.saveuf; end;

procedure inu(var i:integer); begin common3.inu(i); end;
procedure ini(var i:byte); begin common3.ini(i); end;
procedure inputwn1(var v:string; l:integer; flags:string; var changed:boolean);
  begin common3.inputwn1(v,l,flags,changed); end;
procedure inputwn(var v:string; l:integer; var changed:boolean);
  begin common3.inputwn(v,l,changed); end;
procedure inputwnwc(var v:string; l:integer; var changed:boolean);
  begin common3.inputwnwc(v,l,changed); end;
procedure inputmain(var s:string; ml:integer; flags:string);
  begin common3.inputmain(s,ml,flags); end;
procedure inputwc(var s:string; ml:integer); begin common3.inputwc(s,ml); end;
procedure input(var s:string; ml:integer); begin common3.input(s,ml); end;
procedure inputl(var s:string; ml:integer); begin common3.inputl(s,ml); end;
procedure inputcaps(var s:string; ml:integer);
  begin common3.inputcaps(s,ml); end;
procedure mmkey(var s:string); begin common3.mmkey(s); end;

procedure com_flush_rx; begin tmpcom.com_flush_rx; end;
function com_carrier:boolean; begin com_carrier:=tmpcom.com_carrier; end;
function com_rx_empty:boolean; begin com_rx_empty:=tmpcom.com_rx_empty; end;
procedure com_set_speed(speed:word); begin tmpcom.com_set_speed(speed); end;
(*****************************************************************************)

var cfilter:cfilterrec;
    cfiltertype,cfilternum,cfiltercount:integer;

procedure shelldos(bat:boolean; cl:string; var rcode:integer);
var t:text;
    s:string;
    i,speed:integer;
    emsswap:boolean;
begin
  nosound;
  if (bat) then begin
    assign(t,'tgtempx.bat'); rewrite(t);
    writeln(t,cl);
    close(t);
    cl:='tgtempx.bat';
  end;
  if (cl<>'') then cl:='/c '+cl;    { if '', just a local shell to DOS }

  s:=^M^J+#27+'[0m';
  for i:=1 to length(s) do dosansi(s[i]);

  remove_port;

  emsswap:=FALSE;
  if (systat.swapshell) then
    if (initexecswap2(heapptr,systat.swappath+'TGSWAP.$$$')) then
      emsswap:=TRUE;
  swapvectors;
  if (not emsswap) then exec(getenv('COMSPEC'),cl) else begin
    textcolor(7); writeln('Swapping...');
    if (execwithswap2(getenv('COMSPEC'),cl)<>0) then begin
      writeln('Cannot swap, performing normal execution');
      exec(getenv('COMSPEC'),cl);
    end else shutdownexecswap2;
  end;
  swapvectors;

  rcode:=lo(dosexitcode);
  if (bat) then begin
    assign(t,'tgtempx.bat');
    {$I-} erase(t); {$I+}
    if (ioresult<>0) then ;
  end;
  if (spd='KB') then speed:=modemr.waitbaud else speed:=value(spd);
  iport; {  installint(modemr.comport);}
  openport(modemr.comport,speed,'N',8,1);
end;

procedure sysopstatus;
begin
	if (sysop) then begin
		nl;
		printf('SYSOPIN');
		if (nofile) then sprint(fstring.sysopin);
	end else begin
		nl;
		printf('SYSOPOUT');
		if (nofile) then sprint(fstring.sysopout);
	end;
end;


procedure DisableInterrupts;
begin
{rcg11172000 not needed under Linux.}
(*
  inline($FA);  {cli}
*)
end;

procedure EnableInterrupts;
begin
{rcg11172000 not needed under Linux.}
(*
  inline($FB);  {sti}
*)
end;

procedure autovalidate(var u:userrec; un:integer);
var settings:set of uflags;
    b:boolean;
begin
  settings:=[rlogon,rchat,rvalidate,rbackspace,ramsg,rpostan,rpost,remail,
             rvoting,rmsg,fnodlratio,fnopostratio,fnofilepts,fnodeletion];
  with u do begin
    if (un=usernum) then begin
      realsl:=sl; realdsl:=dsl;
      newcomptables;
    end;
    sl:=systat.autosl; dsl:=systat.autodsl;
    ac:=ac-settings;
    ac:=ac+(systat.autoac*settings);
      (* do NOT modify user's personal settings, such as ANSI, color, etc.. *)
    ar:=systat.autoar;
    tltoday:=systat.timeallow[sl];
  end;
end;

procedure rsm;
var x:smr;
    i:integer;
begin
  {$I-} reset(smf); {$I+}
  if ioresult=0 then begin
    i:=0; cl(1);
    repeat
      if (i<=filesize(smf)-1) then begin seek(smf,i); read(smf,x);
      end;
      while (i<filesize(smf)-1) and (x.destin<>usernum) do begin
        inc(i);
        seek(smf,i); read(smf,x);
      end;
      if (x.destin=usernum) and (i<=filesize(smf)-1) then begin
        print(x.msg);
        seek(smf,i); x.destin:=-1; write(smf,x);
        smread:=TRUE;
      end;
      inc(i);
    until (i>filesize(smf)-1) or hangup;
    close(smf);
    cl(1);
  end;
end;

function lenn(s:string):integer;
var i,len:integer;
begin
  len:=length(s); i:=1;
  while (i<=length(s)) do begin
    if (s[i] in [#3,'^']) then
      if (i<length(s)) then begin dec(len,2); inc(i); end;
    inc(i);
  end;
  lenn:=len;
end;

function lennmci(s:string):integer;
var i,len:integer;
    lastco,lastmci:boolean;
begin
  len:=length(s);
  lastco:=FALSE; lastmci:=FALSE;
  for i:=1 to length(s) do
    if (not lastco) and (not lastmci) then
      case s[i] of
        #3,'^':if (not lastco) and (i<>length(s)) then lastco:=TRUE;
        '@':if (not lastmci) and (i<>length(s)) then lastmci:=TRUE;
      end
    else begin
      if (lastco) then
        if s[i] in [#0..#9,'0'..'9'] then begin
          dec(len,2);
          lastco:=FALSE;
        end;
      if (lastmci) then begin
        dec(len,2);
        inc(len,lennmci(smci(s[i])));
        lastmci:=FALSE;
      end;
    end;
  lennmci:=len;
end;

procedure loaduboard(i:integer);
var ulfo:boolean;
begin
  if (readuboard<>i) then begin
    ulfo:=(filerec(ulf).mode<>fmclosed);
    if (not ulfo) then reset(ulf);
    if ((i>=0) and (i<=filesize(ulf)-1)) then begin
      seek(ulf,i);
      read(ulf,memuboard);
    end else
      memuboard:=tempuboard;
    readuboard:=i;
    if (not ulfo) then close(ulf);
  end;
end;

procedure loadboard(i:integer);
var bfo:boolean;
begin
  if (readboard<>i) then begin
    bfo:=(filerec(bf).mode<>fmclosed);
    if (not bfo) then reset(bf);
    if ((i-1<0) or (i-1>filesize(bf)-1)) then i:=1;
    seek(bf,i-1); read(bf,memboard);
    readboard:=i;
    if (not bfo) then close(bf);
  end;
end;

procedure lcmds(len,c:byte; c1,c2:string);
var s:string;
begin
  s:=copy(c1,2,lenn(c1)-1);
  if (c2<>'') then s:=mln(s,len-1);
  sprompt(#3#1+'('+#3+chr(c)+c1[1]+#3#1+')'+s);
  if (c2<>'') then sprompt(#3#1+'('+#3+chr(c)+c2[1]+#3#1+')'+copy(c2,2,lenn(c2)-1));
  nl;
end;

procedure tc(n:integer);
begin
  textcolor(n);
end;

function mso:boolean;
var i:byte;
    b:boolean;
begin
  b:=FALSE;
  for i:=1 to 5 do
    if (board=thisuser.boardsysop[i]) then b:=TRUE;
  mso:=((cso) or (aacs(systat.msop)) or (b));
end;

function fso:boolean;
begin
  fso:=((cso) or (aacs(systat.fsop)));
end;

function cso:boolean;
begin
  cso:=((so) or (aacs(systat.csop)));
end;

function so:boolean;
begin
  so:=(aacs(systat.sop));
end;

function timer:real;
var r:registers;
    h,m,s,t:real;
begin
  r.ax:=44*256;
  msdos(dos.registers(r));
  h:=(r.cx div 256); m:=(r.cx mod 256); s:=(r.dx div 256); t:=(r.dx mod 256);
  timer:=h*3600+m*60+s+t/100;
end;

function fbaseac(b:byte):boolean;
begin
  fbaseac:=FALSE;
  if ((b<0) or (b>maxulb)) then exit;
  loaduboard(b);
  fbaseac:=aacs(memuboard.acs);
end;

function mbaseac(nb:integer):boolean;
begin
  mbaseac:=FALSE;
  if ((nb<1) or (nb>numboards)) then exit;
  loadboard(nb);
  mbaseac:=aacs(memboard.acs);
end;

procedure changefileboard(b:integer);
var s:string[20];
    go:boolean;
begin
  go:=FALSE;
  if (b>=0) and (b<=maxulb) then
    if (fbaseac(b)) then { fbaseac loads memuboard itself ... }
      if (memuboard.password='') then go:=TRUE
      else begin
        nl; sprint('File base '+cstr(ccuboards[1][b])+': '+
                   #3#5+memuboard.name);
        prt('Password? '); mpl(20); input(s,20);
        if (s=memuboard.password) then go:=TRUE else print('Wrong.');
      end;
  if (go) then begin fileboard:=b; thisuser.lastfil:=fileboard; end;
end;

procedure changeboard(b:integer);
var s:string[20];
    go:boolean;
begin
  go:=FALSE;
  if (b>=1) and (b<=numboards) then
    if (mbaseac(b)) then { mbaseac loads memboard itself ... }
      if (memboard.password='') then go:=TRUE
      else begin
        nl; sprint('Message base '+cstr(ccboards[1][b])+': '+
                   #3#5+memboard.name);
        prt('Enter thy Password? '); mpl(20); input(s,20);
        if (s=memboard.password) then go:=TRUE else print('Wrong.');
      end;
  if (go) then begin board:=b; thisuser.lastmsg:=board; end;
end;

function freek(d:integer):longint;
var lng:longint;
begin
  lng:=diskfree(d);
  freek:=lng div 1024;
end;

function nma:integer;
begin
  nma:=thisuser.tltoday;
end;

function okansi:boolean;
begin
  okansi:=((ansi in thisuser.ac) or (avatar in thisuser.ac));
end;

function okavatar:boolean;
begin
  okavatar:=((avatar in thisuser.ac) and (not mtcolors));
end;

function nsl:real;
var ddt,dt:datetimerec;
    beenon:real;
begin
  if ((useron) or (not inwfcmenu)) then begin
    getdatetime(dt);
    timediff(ddt,timeon,dt);
    beenon:=dt2r(ddt);
    nsl:=((nma*60.0+extratime+freetime)-(beenon+choptime));
  end else
    nsl:=3600.0
end;

procedure checkhangup;
begin
  if (not com_carrier) then
    if ((outcom) and (not hangup)) then begin
      hangup:=TRUE; hungup:=TRUE;
    end;
end;

function waitackfile(s:string):boolean;
var rl:real;
begin
  pr1(^T+'f'+s+';');
  rl:=timer;
  waitackfile:=TRUE;
  repeat
    if (not com_rx_empty) then
      case com_rx of
        #6:exit;                                  { ACK }
        #21:begin waitackfile:=FALSE; exit; end;  { NAK }
      end;
  until (timer-rl>10.0);
  waitackfile:=FALSE;
end;

procedure sendfilep(s:string);
var f:file of char;
    ps:string[67];
    ns:string[8];
    es:string[4];
    c:char;
begin
  assign(f,s);
  {$I-} reset(f); {$I+}
  if (ioresult<>0) then begin
    pr('');
    pr('"'+s+'": File not found.');
    pr('');
  end else begin
    fsplit(s,ps,ns,es);
    if (waitackfile(ns+es)) then begin
      while (not eof(f)) do begin read(f,c); com_tx(c); end;
      pr1(^Z^Z^Z);
    end;
    close(f);
  end;
end;

procedure handlempcode(var ccc:char);
var tf:file of tfilerec;
    temptfilebase:tfilerec;
    tempboard:boardrec;
    s:string;
    i,j:integer;
    mc:array[1..6] of char;
    bfo,ulfo:boolean;
begin
  if (not mpcoder) then exit;
  ccc:=#0;
  for i:=1 to 6 do mc[i]:=chr(mpcode[i]);
  case chr(mpcode[1]) of
    'r':begin
          if (mc[2]+mc[3]='mt') then mtcolors:=(mc[4]='1');
        end;
    '*':begin
          if (mc[2]+mc[3]='li') then
            case mc[4] of
              'b':begin
                    pr('');
                    bfo:=(filerec(bf).mode<>fmclosed);
                    if (not bfo) then reset(bf);
                    i:=1;
                    with tempboard do
                      while (not eof(bf)) do begin
                        read(bf,tempboard);
                        s:=aonoff(aacs(acs),' ','*')+mn(i,3)+':'+
                           mln(stripcolor(name),40)+':'+acs+'/'+password;
                        pr1(s+^M^J);
                        inc(i);
                      end;
                    pr('');
                    if (not bfo) then close(bf);
                  end;
              'f':begin
                    pr('');
                    ulfo:=(filerec(ulf).mode<>fmclosed);
                    if (not ulfo) then reset(ulf);
                    i:=1;
                    with tempuboard do
                      while (not eof(ulf)) do begin
                        read(ulf,tempuboard);
                        s:=aonoff(aacs(acs),' ','*')+mn(i,3)+':'+
                           mln(stripcolor(name),40)+':'+acs+'/'+password;
                        pr1(s+^M^J);
                        inc(i);
                      end;
                    pr('');
                    if (not ulfo) then close(ulf);
                  end;
              'r':sendfilep(start_dir+'\err.log');
              't':begin
                    pr('');
                    assign(tf,systat.gfilepath+'gfiles.dat');
                    {$I-} reset(tf); {$I+}
                    i:=1;
                    read(tf,temptfilebase); j:=temptfilebase.gdaten;
                    with temptfilebase do
                      while ((not eof(tf)) and (i<j)) do begin
                        read(tf,temptfilebase);
                        s:=aonoff(aacs(acs),' ','*')+mn(i,3)+':'+
                           mln(filen,12)+':'+mln(stripcolor(title),40)+':'+
                           acs+'/'+gdate;
                        pr1(s+^M^J);
                        inc(i);
                      end;
                    pr('');
                    close(tf);
                  end;
            end;
        end;
  end;
(*  write('(<-'); for i:=1 to 6 do write(chr(mpcode[i])); write('->)');*)
  mpcoder:=FALSE;
end;

function ccinkey1:char;
var tar:array[1..20] of char;
    rl:real;
    tarc:integer;
    c:char;
begin
  if (recom1(c)) then begin
    ccinkey1:=c;
    if ((c=^A) and (not trm)) then begin
      tarc:=1; tar[1]:=^B;
      rl:=timer;
      repeat
        if (recom1(c)) then begin tar[tarc]:=c; inc(tarc); end;
      until ((timer-rl>2.0) or (tarc>11) or (tar[1]<>^B));
{      commandline('<<'+tar[3]+tar[4]+tar[5]+tar[6]+tar[7]+tar[8]+'>>');}
      if (tarc>11) then begin
        mpcoder:=(tar[1]+tar[2]+tar[9]+tar[10]+tar[11]=^B^A+#253+#254+#255);
        if (mpcoder) then begin
          for tarc:=1 to 6 do mpcode[tarc]:=ord(tar[tarc+2]);
          handlempcode(c); ccinkey1:=#0;
        end;
      end;
    end;
  end else
    ccinkey1:=#0;
end;

function cinkey1:char;
var rl:real;
    c:char;
begin
  cinkey1:=ccinkey1;
(*  if (recom1(c)) then begin
    cinkey1:=c;
    if ((c=^A) and (not trm)) then begin
      rl:=timer;
      repeat until ((timer-rl>2.0) or (mpcoder));
      if (mpcoder) then begin handlempcode(c); cinkey1:=#0; end;
    end;
  end else
    cinkey1:=#0;*)
end;

function cinkey:char;
begin
  cinkey:=cinkey1;
end;

procedure o(c:char);
begin
  if ((outcom) and (not trm) and (c<>#1)) then sendcom1(c);
end;

function intime(tim:real; tim1,tim2:integer):boolean;
(* "tim" is seconds (timer) time; tim1/tim2 are minutes time. *)
begin
  intime:=TRUE;
  while (tim>=24.0*60.0*60.0) do tim:=tim-24.0*60.0*60.0;
  if (tim1<>tim2) then
    if (tim2>tim1) then
      if (tim<=tim1*60.0) or (tim>=tim2*60.0) then
        intime:=FALSE
      else
    else
      if (tim<=tim1*60.0) and (tim>=tim2*60.0) then
        intime:=FALSE;
end;

function sysop1:boolean;
{rcg11172000 ?!}
{
var a:byte absolute $0000:$0417;
begin
  if (a and 16)=0 then sysop1:=TRUE else sysop1:=FALSE;
end;
}
begin
   writeln('STUB: common.pas; sysop1()...');
   sysop1 := FALSE;
end;


function sysop:boolean;
var s:boolean;
begin
  s:=sysop1;
{  if (systat.lowtime=systat.hitime) then s:=FALSE;}
  if (not intime(timer,systat.lowtime,systat.hitime)) then s:=FALSE;
  if (rchat in thisuser.ac) then s:=FALSE;
  sysop:=s;
end;

procedure opensysopf;
begin
  assign(sysopf,systat.trappath+'sysop.log');
  {$I-} append(sysopf); {$I+}
  if (ioresult<>0) then begin
    rewrite(sysopf);
    append(sysopf);
  end;
end;

function stripcolor(o:string):string;
var s:string;
    i:integer;
    lc:boolean;
begin
  s:=''; lc:=FALSE;
  for i:=1 to length(o) do
    if (lc) then lc:=FALSE
      else if ((o[i]=#3) or (o[i]='^')) then lc:=TRUE else s:=s+o[i];
  stripcolor:=s;
end;

procedure sl1(s:string);
begin
  if (slogging) then begin
    if (systat.stripclog) then s:=stripcolor(s);
    if (systat.slogtype in [0,1]) then begin
      if (textrec(sysopf).mode<>fmoutput) then opensysopf;
      writeln(sysopf,s);
    end;
    if ((thisuser.slogseperate) and (textrec(sysopf1).mode=fmoutput)) then
      writeln(sysopf1,s);

    if (systat.slogtype in [1,2]) then begin
      if (not systat.stripclog) then s:=stripcolor(s);
      writeln(lst,s);
    end;
  end;
end;

procedure sysoplog(s:string);
begin
  sl1('   '+s);
end;

function tch(s:string):string;
begin
  if (length(s)>2) then s:=copy(s,length(s)-1,2) else
    if (length(s)=1) then s:='0'+s;
  tch:=s;
end;

function time:string;
var h,m,s:string[3];
    hh,mm,ss,ss100:word;
begin
  gettime(hh,mm,ss,ss100);
  str(hh,h); str(mm,m); str(ss,s);
  time:=tch(h)+':'+tch(m)+':'+tch(s);
end;

function date:string;
var r:registers;
    y,m,d:string[3];
    yy,mm,dd,dow:word;
begin
  getdate(yy,mm,dd,dow);
  str(yy-1900,y); str(mm,m); str(dd,d);
  date:=tch(m)+'/'+tch(d)+'/'+tch(y);
end;

function value(s:string):longint;
var i:longint;
    j:integer;
begin
  val(s,i,j);
  if (j<>0) then begin
    s:=copy(s,1,j-1);
    val(s,i,j)
  end;
  value:=i;
  if (s='') then value:=0;
end;

function cstr(i:longint):string;
var c:string[16];
begin
  str(i,c);
  cstr:=c;
end;

function nam:string;
begin
  nam:=caps(thisuser.name)+' #'+cstr(usernum);
end;

function ageuser(bday:string):integer;
var i:integer;
begin
  i:=value(copy(date,7,2))-value(copy(bday,7,2));
  if (daynum(copy(bday,1,6)+copy(date,7,2))>daynum(date)) then dec(i);
  ageuser:=i;
end;

function allcaps(s:string):string;
var i:integer;
begin
  for i:=1 to length(s) do s[i]:=upcase(s[i]);
  allcaps:=s;
end;

function caps(s:string):string;
var i:integer;
begin
  for i:=1 to length(s) do
    if (s[i] in ['A'..'Z']) then s[i]:=chr(ord(s[i])+32);
  for i:=1 to length(s) do
    if (not (s[i] in ['A'..'Z','a'..'z'])) then
      if (s[i+1] in ['a'..'z']) then s[i+1]:=upcase(s[i+1]);
  s[1]:=upcase(s[1]);
  caps:=s;
end;

function leapyear(yr:integer):boolean;
begin
  leapyear:=(yr mod 4=0) and ((yr mod 100<>0) or (yr mod 400=0));
end;

function days(mo,yr:integer):integer;
var d:integer;
begin
  d:=value(copy('312831303130313130313031',1+(mo-1)*2,2));
  if ((mo=2) and (leapyear(yr))) then inc(d);
  days:=d;
end;

function daycount(mo,yr:integer):integer;
var m,t:integer;
begin
  t:=0;
  for m:=1 to (mo-1) do t:=t+days(m,yr);
  daycount:=t;
end;

function daynum(dt:string):integer;
var d,m,y,t,c:integer;
begin
  t:=0;
  m:=value(copy(dt,1,2));
  d:=value(copy(dt,4,2));

  {rcg11182000 hahahaha...a Y2K bug.  :) }
  y:=value(copy(dt,7,2))+1900;

  {rcg11182000 added this conditional. }
  if (y < 1977) then  { Ugh...this is so bad. }
    y := y + 100;

  for c:=1985 to y-1 do
    if (leapyear(c)) then inc(t,366) else inc(t,365);
  t:=t+daycount(m,y)+(d-1);
  daynum:=t;
  if y<1985 then daynum:=0;
end;

function dat:string;
const mon:array [1..12] of string[3] =
          ('Jan','Feb','Mar','Apr','May','Jun',
           'Jul','Aug','Sep','Oct','Nov','Dec');
var ap,x,y:string; i:integer;
    year,month,day,dayofweek,hour,minute,second,sec100:word;
begin
  getdate(year,month,day,dayofweek);
  gettime(hour,minute,second,sec100);

  if (hour<12) then ap:='am'
  else begin
    ap:='pm';
    if (hour>12) then dec(hour,12);
  end;
  if (hour=0) then hour:=12;

  dat:=cstr(hour)+':'+tch(cstr(minute))+' '+ap+'  '+
       copy('SunMonTueWedThuFriSat',dayofweek*3+1,3)+' '+
       mon[month]+' '+cstr(day)+', '+cstr(year);
(*  5:43 pm  Fri Jul 28, 1989  *)

(*
  ap:=date;
  y:=mon[value(copy(ap,1,2))];
  x:=x+' '+y+' '+copy(ap,4,2)+', '+cstr(1900+value(copy(ap,7,2)));
  y:=time; i:=value(copy(y,1,2));
  if i>11 then ap:='pm' else ap:='am';
  if i>12 then i:=i-12;
  if i=0 then i:=12;
  dat:=cstr(i)+copy(y,3,3)+' '+ap+'  '+x;
*)
end;

procedure pr1(s:string);
var i:integer;
begin
  for i:=1 to length(s) do sendcom1(s[i]);
end;

procedure pr(s:string);
begin
  pr1(s+#13);
end;

procedure scc;    {* make local textcolor( = curco *}
var f:integer;
begin
  if (okansi) then begin
    f:=curco and 7;
    if (curco and 8)<>0 then inc(f,8);
    if (curco and 128)<>0 then inc(f,16);
    tc(f);
    textbackground((curco shr 4) and 7);
  end;
end;

procedure sde; { restore curco colors (DOS and tc) loc. after local }
var c:byte;
    b:boolean;
begin
  if (okansi) then begin
    c:=curco; curco:=255-curco;
    b:=outcom; outcom:=FALSE;
    setc(c);
    outcom:=b;
  end;
end;

procedure sdc; { restore curco colors (DOS and tc) loc/rem after loc/rem }
var c:byte;
begin
  if (okansi) then begin
    c:=curco; curco:=255-curco;
    setc(c);
  end;
end;

procedure stsc;
begin
  tc(11); textbackground(0);
end;

function getc(c:byte):string;
const xclr:array[0..7] of char=('0','4','2','6','1','5','3','7');
var s:string;
    b:boolean;

  procedure adto(ss:string);
  begin
    if (s[length(s)]<>';') and (s[length(s)]<>'[') then s:=s+';';
    s:=s+ss; b:=TRUE;
  end;

begin
  b:=FALSE;
  if ((curco and (not c)) and $88)<>0 then begin
    s:=#27+'[0';
    curco:=$07;
  end else
    s:=#27+'[';
  if (c and 7<>curco and 7) then adto('3'+xclr[c and 7]);
  if (c and $70<>curco and $70) then adto('4'+xclr[(c shr 4) and 7]);
  if (c and 128<>0) then adto('5');
  if (c and 8<>0) then adto('1');
  if (not b) then adto('3'+xclr[c and 7]);
  s:=s+'m';
  getc:=s;
end;

procedure omtcolor(c:byte);
const color:array[0..15] of byte=($00,$04,$02,$06,$01,$05,$03,$07,
                                  $08,$0C,$0A,$0E,$09,$0D,$0B,$0F);
var c1:byte;
begin
  if (mtcolors) then begin
    if (c and $70=0) then pr1(^T+chr(c or $70)) else pr1(^T+'C'+chr(c));
  end else begin
    if (thisuser.avadjust=2) then begin
      c1:=color[c and $0F]+(color[(c and $70) shr 4] shl 4);
      if (c and $80<>0) then c1:=c1 or $80;
      pr1(^V^A+chr(c1));
    end else pr1(^V^A+chr(c and $7F));
    if (c and $80<>0) then pr1(^V^B);
  end;
end;

procedure setc(c:byte);
var s:string;
    i:integer;
begin
  if ((c<>curco) or (dosansion)) then begin
    s:=getc(c); curco:=c;
    if (okansi) then begin
      if (outcom) then
        if ((okavatar) or (mtcolors)) then omtcolor(c) else pr1(s);
      if (wantout) then begin
        textattr:=c;
        if (dosansion) then begin
          s:=#27+'[0;'+copy(s,3,length(s)-2);
          for i:=1 to length(s) do dosansi(s[i]);
        end;
      end;
    end;
    scc;
  end;
end;

procedure cl(c:integer);
begin
  if (c in [0..9]) then
    if (okansi) then
      setc(thisuser.cols[(color in thisuser.ac)][c]);
end;

function sqoutsp(s:string):string;
begin
  while (pos(' ',s)>0) do delete(s,pos(' ',s),1);
  sqoutsp:=s;
end;

function exdrv(s:string):byte;
begin
  s:=fexpand(s);
  exdrv:=ord(s[1])-64;
end;

function mlnnomci(s:string; l:integer):string;
begin
  while (length(s)<l) do s:=s+' ';
  if (length(s)>l) then
    repeat s:=copy(s,1,length(s)-1) until (length(s)=l) or (length(s)=0);
  mlnnomci:=s;
end;

function mlnmci(s:string; l:integer):string;
begin
  while (lennmci(s)<l) do s:=s+' ';
  if (lennmci(s)>l) then
    repeat s:=copy(s,1,length(s)-1) until (lennmci(s)=l) or (length(s)=0);
  mlnmci:=s;
end;

function mln(s:string; l:integer):string;
begin
  while (lenn(s)<l) do s:=s+' ';
  if (lenn(s)>l) then
    repeat s:=copy(s,1,length(s)-1) until (lenn(s)=l) or (length(s)=0);
  mln:=s;
end;

function mrn(s:string; l:integer):string;
begin
  while lenn(s)<l do s:=' '+s;
  if lenn(s)>l then s:=copy(s,1,l);
  mrn:=s;
end;

function mn(i,l:longint):string;
begin
  mn:=mln(cstr(i),l);
end;

(*
procedure cjp;
begin
  if ((not ch) and (not write_msg) and (not reading_a_msg)) then cl(1);
end;

procedure docc(c:char);
begin
  case c of
    ^H:if (pap>0) then dec(pap);
    ^L:begin
         lil:=0;
         clrscr;
       end;
    ^M:pap:=0;
    ^J:begin
         inc(lil);
         if (lil>=thisuser.pagelen-1) then begin
           lil:=0;
           if (pause in thisuser.ac) then pausescr;
         end;
       end;
  end;
end;

procedure promptc(c:char);
begin
  if (c=^J) then cjp;
  if (wantout) then
    if (((c<>^G) or (not incom)) and (not (c in [#1,^L]))) then
{      write(c);}
      write(c);
{  if (trapping) then if (c<>^G) then write(trapfile,c);}
  if (outcom) then sendcom1(c);
  if ((c>=#32) and (c<=#255)) then inc(pap) else docc(c);
end;
*)

procedure dosansi(c:char);
var r:registers;
begin
  with r do begin
    dx:=ord(c); ax:=$0200;
    msdos(r);
  end;
end;

procedure lpromptc(c:char);
var ss:string;
    bb:byte;
begin
  if (c=^G) then exit;
  case c of
    ^H:if (pap>0) then dec(pap);
    ^J:begin
         if ((not ch) and (not write_msg) and (not reading_a_msg)) then
           if ((not ctrljoff) and (not dosansion)) then begin
             bb:=thisuser.cols[color in thisuser.ac][1];
             if ((outcom) and (okansi)) then
               if ((okavatar) or (mtcolors)) then omtcolor(bb) else pr1(getc(bb));
             curco:=bb; textattr:=bb;
           end else
             lil:=0;
         if (wantout) then write(^J);
         inc(lil);
         if (lil>=thisuser.pagelen-1) then begin
           lil:=0;
           if (pause in thisuser.ac) then pausescr;
         end;
         exit;
       end;
    ^L:lil:=0;
    ^M:pap:=0;
    ^[:dosansion:=TRUE;
  end;
  if (wantout) then if (not dosansion) then write(c) else dosansi(c);
end;

procedure prompt(s:string);
var s1,s2:string;
    i:integer;
    bb:byte;
begin
  checkhangup;
  if (hangup) then exit;
  if (outcom) then begin
    s1:=s;
    while (pos(^J,s1)<>0) do begin
      i:=pos(^J,s1);
      s2:=copy(s,1,i-1); s1:=copy(s1,i+1,length(s1)-i);
      for i:=1 to length(s2) do sendcom1(s2[i]);
      if ((not ch) and (not write_msg) and (not reading_a_msg)) then
        if (not ctrljoff) then begin
          bb:=thisuser.cols[color in thisuser.ac][1];
          if (okansi) then
            if ((okavatar) or (mtcolors)) then omtcolor(bb) else pr1(getc(bb));
          curco:=bb;
        end else
          lil:=0;
      sendcom1(^J);
    end;
    for i:=1 to length(s1) do sendcom1(s1[i]);
  end;
  for i:=1 to length(s) do lpromptc(s[i]);
  if (trapping) then
    if (copy(s,length(s)-1,2)=^M^J) then
      writeln(trapfile,copy(s,1,length(s)-2))
    else
      write(trapfile,s);
end;

procedure print(s:string);
begin
  prompt(s+^M^J);
end;

procedure nl;
begin
  prompt(^M^J);
end;

procedure prt(s:string);
begin
  cl(4); sprompt(s); cl(3);
end;

procedure ynq(s:string);
begin
  cl(7); sprompt(s); cl(3);
end;

procedure mpl(c:integer);
var i,x:integer;
begin
  if (okansi) then begin
    cl(6);
    x:=wherex;
    if (outcom) then for i:=1 to c do sendcom1(' ');
    if (wantout) then for i:=1 to c do write(' ');
    gotoxy(x,wherey);
    if (outcom) then begin
      if (okavatar) then pr1(^Y+^H+chr(c)) else pr1(#27+'['+cstr(c)+'D');
    end;
  end;
  dec(pap,c);
end;

function smci(c:char):string;
var s,dum:string;
    i:integer;
begin
  dum:=nam;
  case upcase(c) of
    'A':s:=cstr(ccboards[1][board]);
    'B':begin
          loadboard(board);
          s:=#3#5+memboard.name;
        end;
    'C':s:=cstr(ccuboards[1][fileboard]);
    'D':begin
          loaduboard(fileboard);
          s:=#3#5+memuboard.name;
          if (fbnoratio in memuboard.fbstat) then s:=s+#3#5+' <NR>';
        end;
    'F':s:=copy(thisuser.realname,1,pos(' ',thisuser.realname)-1);
    'G':if (sysop) then begin
		nl;
		printf('SYSOPIN');
		if (nofile) then s:=(fstring.sysopin);
	end else begin
		nl;
		printf('SYSOPOUT');
		if (nofile) then s:=fstring.sysopout;
                end;
    'H':s:=copy(dum,1,pos('#',dum)-2);
    'K':begin
          loaduboard(fileboard);
          s:=cstrl(freek(exdrv(memuboard.ulpath)));
        end;
    'L':begin
          dum:=caps(thisuser.realname);
          i:=length(dum);
          while ((dum[i]<>' ') and (i>1)) do begin
            s:=copy(dum,i,(length(dum)-i)+1);
            dec(i);
          end;
        end;
    'M':s:=^M^J;
    'N':s:=dum;
    'P':s:=cstr(thisuser.filepoints);
    'R':s:=thisuser.realname;
    'T':s:=tlef;
    'U':s:=cstr(msg_on);
    'V':s:=cmdlist;
    'W':s:=cstr(himsg+1);
    'X':begin
          if (cso) then i:=systat.csmaxlines else i:=systat.maxlines;
          s:=cstr(i);
        end;
    'Y':begin
          loadboard(board);
          s:=#3#5+memboard.name+#3#5+' #'+cstr(ccboards[1][board]);
        end;
    'Z':s:=chatr;
  else
        s:='@'+c;
  end;
  smci:=s;
end;

{rcg11172000 had to change this to get it compiling under Free Pascal...}
{function substone(src,old,new:string):string;}
function substone(src,old,_new:string):string;
var p:integer;
begin
  if (old<>'') then begin
    p:=pos(old,allcaps(src));
    if (p>0) then begin
      insert(_new,src,p+length(old));
      delete(src,p,length(old));
    end;
  end;
  substone:=src;
end;

procedure sprompt(s:string);
var ss,sss:string;
    i,p1,p2,x,z:integer;
    c,mc:char;
    xx,b:boolean;
begin
  checkhangup;
  if (hangup) then exit;
  ss:=s; sss:='';
  b:=FALSE;
  if (pos('@',ss)<>0) then begin
    for c:='A' to 'Z' do
      while (pos('@'+c,allcaps(ss))<>0) do begin
        ss:=substone(ss,'@'+c,smci(c));
        b:=TRUE;
      end;
    while ((pos('@',ss)<>0) and (b)) do begin
      for c:='A' to 'Z' do
        while (pos('@'+c,allcaps(ss))<>0) do ss:=substone(ss,'@'+c,smci(c));
      for i:=1 to length(ss)-1 do
        if ((ss[i]='@') and (not (ss[i+1] in ['A'..'Z']))) then
					ss[i]:=#28;
			if (ss[length(ss)]='@') then ss[length(ss)]:=#28;
    end;
    for i:=1 to length(ss) do
			if (ss[i]=#28) then ss[i]:='@';
  end;

  if (trapping) then write(trapfile,ss);
  if (not okansi) then
    ss:=stripcolor(ss)
  else
    while (ss<>'') and ((pos(#3,ss)<>0) or (pos('^',ss)<>0)) do begin
      p1:=pos(#3,ss); if (p1=0) then p1:=500;
      p2:=pos('^',ss); if (p2=0) then p2:=500;

      if (p2<p1) then p1:=p2;

      if (p1<>500) then begin
        mc:=ss[p1+1]; sss:=copy(ss,1,p1-1);
        ss:=copy(ss,p1+2,length(ss)-(p1+1));
      end else begin
        sss:=ss; ss:='';
      end;

      if (outcom) then
        for i:=1 to length(sss) do sendcom1(sss[i]);
      for i:=1 to length(sss) do lpromptc(sss[i]);

      if ((mc>=#0) and (mc<=#9)) then cl(ord(mc)) else
        if ((mc>='0') and (mc<='9')) then cl(ord(mc)-48);
    {**** ADD @E SUPPORT *}

    end;
  if (outcom) then
    for i:=1 to length(ss) do sendcom1(ss[i]);
  for i:=1 to length(ss) do lpromptc(ss[i]);
end;

procedure sprint(s:string);
begin
  sprompt(s+'@M');
end;

procedure prestrict(u:userrec);
var r:uflags;
begin
  for r:=rlogon to rmsg do
    if (r in u.ac) then write(copy('LCVBA*PEKM',ord(r)+1,1)) else write('-');
  writeln;
end;

function empty:boolean;
var e:boolean;
begin
  e:=(not keypressed);
  if ((incom) and (e)) then e:=(com_rx_empty);
  if (hangup) then begin com_flush_rx; e:=TRUE; end;
  empty:=e;
end;

function inkey:char;
var c:char;
begin
  c:=#0; inkey:=#0;
  checkhangup;
  if (keypressed) then begin
    c:=readkey;
    if ((c=#0) and (keypressed)) then begin
      c:=readkey;
      skey1(c);
      if (c=#68) then c:=#1 else c:=#0;
      if (buf<>'') then begin
        c:=buf[1];
        buf:=copy(buf,2,length(buf)-1);
      end;
    end;
    inkey:=c;
  end else
    if (incom) then inkey:=cinkey;
{      if ((async_buffer_head<>async_buffer_tail) and (incom)) then
      inkey:=cinkey;}
end;

procedure outtrap(c:char);
begin
  if (c<>^G) then write(trapfile,c);
end;

procedure docc2(c:char);
var i:integer;
begin
  case c of
    ^G:if (outcom) then for i:=1 to 4 do sendcom1(#0);
    ^J:begin
         if (wantout) then write(^J);
         inc(pap);
       end;
    ^L:begin
         if (wantout) then clrscr;
         lil:=0;
       end;
  end;
end;

procedure outkey(c:char);
begin
  if (c=#29) then exit;
  if (not echo) then
    if ((systat.localsec) and (c in [#32..#255])) then c:=fstring.echoc;
  if (c=#27) then dosansion:=TRUE;
  if (not (c in [^J,^L])) then
    if (not ((c=^G) and (incom))) then
      if ((c<>#0) and (not nopfile) and (wantout)) then
        if (not dosansion) then write(c) else dosansi(c);
  if ((not echo) and (c in [#32..#255])) then c:=fstring.echoc;
  if (outcom) then sendcom1(c);
  if (c<#32) then docc2(c);
end;

function checkeventday(i:integer; t:real):boolean;
var s:string;
    year,month,day,dayofweek:word;
    e:integer;
begin
  checkeventday:=FALSE;
  with events[i]^ do begin
    getdate(year,month,day,dayofweek);
    e:=0;
    if (timer+t>=24.0*60.0*60.0) then begin
      inc(dayofweek); e:=1;
      if (dayofweek>6) then dayofweek:=0;
    end;
    if (monthly) then begin
      if (value(copy(date,4,2))+e=execdays) then
        checkeventday:=TRUE;
    end else begin
      if ((1 shl (6-dayofweek)) and execdays<>0) then
        checkeventday:=TRUE;
    end;
  end;
end;

function checkpreeventtime(i:integer; t:real):boolean;
begin
  with events[i]^ do
    if (busytime=0) then
      checkpreeventtime:=FALSE
    else
      checkpreeventtime:=intime(timer+t,exectime-busytime,exectime);
end;

function checkeventtime(i:integer; t:real):boolean;
begin
  with events[i]^ do
    if (duration=0) then
      checkeventtime:=FALSE
    else
      checkeventtime:=intime(timer+t,exectime,exectime+duration);
end;

function checkevents(t:real):integer;
var i:integer;
begin
  for i:=0 to numevents do
    with events[i]^ do
      if (active) then
        if (checkeventday(i,t)) then begin
          checkevents:=i;
          if (checkpreeventtime(i,t)) or (checkeventtime(i,t)) then begin
            if (etype in ['D','E','P']) then exit;
            if ((etype='A') and (not aacs(execdata)) and (useron)) then exit;
          end;
        end;
  checkevents:=0;
end;

procedure dm(i:string; var c:char);
begin
  buf:=i;
  if (buf<>'') then begin
    c:=buf[1];
    buf:=copy(buf,2,length(buf)-1);
  end;
end;

procedure doeventstuff;
var s:string;
    e,savpap:integer;
    aaa:boolean;
begin
  case telluserevent of
    0:begin
        oltime:=timer;
        e:=checkevents(systat.eventwarningtime);
        if (e<>0) then begin
          telluserevent:=1;
          nl;
          sysoplog('[> '+date+' '+time+' - Displayed "REVENT'+cstr(e)+'" in preparation for event #'+cstr(e));
          savpap:=pap;
          aaa:=allowabort; allowabort:=FALSE;
          printf('revent'+cstr(e));
          allowabort:=aaa;
          if (nofile) then begin
            nl; nl;
            sprint(#3#8+^G'Warning: '+#3#5+'System event approaching.'^G);
            sprint(#3#5+^G'System will be shut down in '+
                    copy(ctim(systat.eventwarningtime),4,5)+' minutes.'^G);
            nl; nl;
          end;
          pap:=savpap;
        end else
          if (checkevents(0)=0) then telluserevent:=0;
      end;
    1:begin
        oltime:=timer;
        e:=checkevents(0);
        if (e<>0) then begin
          telluserevent:=2;
          sysoplog('[> '+date+' '+time+' - Logged user off in preparation for '+
                   'event #'+cstr(e));
          nl; nl; sprint(#3#8+^G'Shutting down for system events'^G); nl; nl;
          hangup:=TRUE;
        end;
      end;
  end;
end;

procedure getkey(var c:char);
var dt,ddt:datetimerec;
    aphase,e:integer;
    abort,next,b,tf,t1,bufalready:boolean;
begin
  lil:=0; 
  if (buf<>'') then begin
    c:=buf[1];
    buf:=copy(buf,2,length(buf)-1);
  end else begin
    if (not empty) then begin
      if (ch) then c:=chinkey else c:=inkey;
    end else begin
      getdatetime(tim);
      t1:=FALSE; tf:=FALSE;
      c:=#0;
      if (alert in thisuser.ac) then aphase:=1 else aphase:=0;
      while ((c=#0) and (not hangup)) do begin
        if (aphase<>0) then begin
          case aphase of
            1:begin sound(1000); delay(35); end;
            2:begin sound(1500); delay(40); end;
            3:begin sound(1900); delay(45); end;
            4:begin sound(2300); delay(50); end;
            5:begin sound(3400); delay(55); end;
          end;
          aphase:=aphase mod 5+1;
        end;

        if (ch) then c:=chinkey else c:=inkey;
        getdatetime(dt);
        timediff(ddt,tim,dt);
        if (systat.timeout<>-1) and
           (dt2r(ddt)>systat.timeout*60) and (c=#0) then begin
          nl; nl;
          printf('timedout');
          if (nofile) then
            print('Time out has occurred.  Log off time was at '+time+'.');
          nl; nl;
          hangup:=TRUE;
          sysoplog(#3#7+'!*!*! Time-out at '+time+' !*!*!');
        end;
        if (systat.timeoutbell<>-1) and
           (dt2r(ddt)>systat.timeoutbell*60) and (not tf) and (c=#0) then begin
          tf:=TRUE;
          outkey(^G); delay(100); outkey(^G);
        end;
        checkhangup;
      end;
      nosound;
    end;
  end;
  if (checkit) then
    if (ord(c) and 128>0) then checkit:=FALSE;
  if (c<#32) then skey(c);
end;

procedure cls;
begin
  if (okansi) then begin
    if (outcom) then begin
      if (okavatar) then pr(^L) else pr(#27+'[2J');
    end;
    if (wantout) then clrscr;
  end else
    outkey(^L);
  if (trapping) then writeln(trapfile,^L);
  cl(1);
  lil:=0;
end;

procedure swac(var u:userrec; r:uflags);
begin
  if (r in u.ac) then
    u.ac:=u.ac-[r] else u.ac:=u.ac+[r];
end;

function tacch(c:char):uflags;
begin
  case c of
    'L':tacch:=rlogon;
    'C':tacch:=rchat;
    'V':tacch:=rvalidate;
    'B':tacch:=rbackspace;
    'A':tacch:=ramsg;
    '*':tacch:=rpostan;
    'P':tacch:=rpost;
    'E':tacch:=remail;
    'K':tacch:=rvoting;
    'M':tacch:=rmsg;
    '1':tacch:=fnodlratio;
    '2':tacch:=fnopostratio;
    '3':tacch:=fnofilepts;
    '4':tacch:=fnodeletion;
  end;
end;

procedure acch(c:char; var u:userrec);
begin
  swac(u,tacch(c));
end;

function aonoff(b:boolean; s1,s2:string):string;
begin
  if (b) then aonoff:=s1 else aonoff:=s2;
end;

function onoff(b:boolean):string;
begin
  if (b) then onoff:='On ' else onoff:='Off';
end;

function syn(b:boolean):string;
begin
  if (b) then syn:='Yes' else syn:='No ';
end;
  
procedure pyn(b:boolean);
begin
  print(syn(b));
end;

function yn:boolean;
var c:char;
begin
  if (not hangup) then begin
    cl(3);
    repeat
      getkey(c);
      c:=upcase(c);
    until (c in ['Y','N',^M,^N]) or (hangup);
    if (dyny) and (c<>'N') then c:='Y';
    if (c='Y') then begin
      print('Yes');
      yn:=TRUE;
    end else begin
      print('No');
      yn:=FALSE;
    end;
    if (hangup) then yn:=FALSE;
  end;
  dyny:=FALSE;
end;

function pynq(s:string):boolean;
begin
  ynq(s);
  pynq:=yn;
end;

procedure onek(var c:char; ch:string);
var s:string;
begin
  repeat
    if (not (onekey in thisuser.ac)) then begin
      input(s,3);
      if length(s)>=1 then c:=s[1] else
        if (s='') and (pos(^M,ch)<>0) then c:=^M else
          c:=' ';
    end else begin
      getkey(c);
      c:=upcase(c);
    end;
  until (pos(c,ch)>0) or (hangup);
  if (hangup) then c:=ch[1];
  if (onekey in thisuser.ac) then begin
    if (onekda) then
      if (c in [#13,#32..#255]) then begin
        outkey(c);
        if (trapping) then write(trapfile,c);
      end;
    if (onekcr) then nl;
  end;
  onekcr:=TRUE;
  onekda:=TRUE;
end;

function centre(s:string):string;
var i,j:integer;
begin
  if (pap<>0) then nl;
  if (s[1]=#2) then s:=copy(s,2,length(s)-1);
  i:=length(s); j:=1;
  while (j<=length(s)) do begin
    if s[j]=#3 then begin
      dec(i,2);
      inc(j);
    end;
    inc(j);
  end;
  if i<thisuser.linelen then
    s:=copy('                                               ',1,
      (thisuser.linelen-i) div 2)+s;
  centre:=s;
end;

procedure wkey(var abort,next:boolean);
var c:char;
begin
  if (empty) then exit;
  if ((abort) or (hangup)) then exit;

  getkey(c);
  case upcase(c) of
    ' ',^C,^X,^K:abort:=TRUE;
          'N',^N:begin abort:=TRUE; next:=TRUE; end;
          'P',^S:getkey(c);
  end;
  if (not allowabort) then begin abort:=FALSE; next:=FALSE; end;
  if (abort) then begin com_purge_tx; nl; sprint(#3#7+'Aborted.'); end;
end;

function ctim(rl:real):string;
var h,m,s:string;
begin
  s:=tch(cstr(trunc(rl-int(rl/60.0)*60.0)));
  m:=tch(cstr(trunc(int(rl/60.0)-int(rl/3600.0)*60.0)));
  h:=cstr(trunc(rl/3600.0));
  if (length(h)=1) then h:='0'+h;
  ctim:=h+':'+m+':'+s;
end;

function tlef:string;
begin
  tlef:=ctim(nsl);
end;

function longtim(dt:datetimerec):string;
var s:string;
    d:integer;

  procedure ads(comma:boolean; i:integer; lab:string);
  begin
    if (i<>0) then begin
      s:=s+cstrl(i)+' '+lab;
      if (i<>1) then s:=s+'s';
      if (comma) then s:=s+', ';
    end;
  end;

begin
  s:='';
  with dt do begin
    d:=day;
    if (d>=7) then begin
      ads(TRUE,d div 7,'week');
      d:=d mod 7;
    end;
    ads(TRUE,d,'day');
    ads(TRUE,hour,'hour');
    ads(TRUE,min,'minute');
    ads(FALSE,sec,'second');
  end;
  if (s='') then s:='0 seconds';
  if (copy(s,length(s)-1,2)=', ') then s:=copy(s,1,length(s)-2);
  longtim:=s;
end;

function dt2r(dt:datetimerec):real;
begin
  with dt do
    dt2r:=day*86400.0+hour*3600.0+min*60.0+sec;
end;

procedure r2dt(r:real; var dt:datetimerec);
begin
  with dt do begin
    day:=trunc(r/86400.0); r:=r-(day*86400.0);
    hour:=trunc(r/3600.0); r:=r-(hour*3600.0);
    min:=trunc(r/60.0); r:=r-(min*60.0);
    sec:=trunc(r);
  end;
end;

procedure timediff(var dt:datetimerec; dt1,dt2:datetimerec);
begin
  with dt do begin
    day:=dt2.day-dt1.day;
    hour:=dt2.hour-dt1.hour;
    min:=dt2.min-dt1.min;
    sec:=dt2.sec-dt1.sec;

    if (hour<0) then begin inc(hour,24); dec(day); end;
    if (min<0) then begin inc(min,60); dec(hour); end;
    if (sec<0) then begin inc(sec,60); dec(min); end;
  end;
end;

procedure getdatetime(var dt:datetimerec);
var w1,w2,w3,w4:word;
begin
  gettime(w1,w2,w3,w4);
  with dt do begin
    day:=daynum(date);
    hour:=w1;
    min:=w2;
    sec:=w3;
  end;
end;

function cstrl(li:longint):string;
var c:string;
begin
  str(li,c);
  cstrl:=c;
end;

function cstrr(rl:real; base:integer):string;
var i:integer;
    s:string;
    r1,r2:real;
begin
  if (rl<=0.0) then cstrr:='0'
  else begin
    r1:=ln(rl)/ln(1.0*base);
    r2:=exp(ln(1.0*base)*(trunc(r1)));
    s:='';
    while (r2>0.999) do begin
      i:=trunc(rl/r2);
      s:=s+copy('0123456789ABCDEF',i+1,1);
      rl:=rl-i*r2;
      r2:=r2/(1.0*base);
    end;
    cstrr:=s;
  end;
end;

procedure loadcfilter(s:string);
var cfilterf:file of cfilterrec;
    os,ps,ns,es:string;
    i:integer;
begin
  if ((not printingfile) or (not okansi)) then exit;
  os:=s;
  if (copy(s,1,1)<>'*') then begin
    if (not exist(s)) then begin
      fsplit(s,ps,ns,es);
      if (exist(systat.afilepath+ns+es)) then s:=systat.afilepath+ns+es
      else
      if (exist(systat.gfilepath+ns+es)) then s:=systat.gfilepath+ns+es;
    end;
    assign(cfilterf,s);
    {$I-} reset(cfilterf); {$I+}
    if (ioresult=0) then begin
      {$I-} read(cfilterf,cfilter); {$I+}
      if (ioresult=0) then begin
        if (not mtcolors) then begin
          cfilteron:=TRUE;
          cfiltertype:=0;
        end else begin
          pr1(^T+'c=');
          for i:=0 to 255 do sendcom1(chr(cfilter[i]));
          pr1(';');
          mtcfilteron:=TRUE; cfilteron:=TRUE;
          cfiltertype:=0;
        end;
      end;
      close(cfilterf);
    end else
      sysoplog('Missing color filter: '+os);
  end else begin
    if (length(s)<3) then exit;
    case upcase(s[2]) of
      'C':cfiltertype:=1;
      'R':cfiltertype:=2;
    end;
    s:=copy(s,3,length(s)-2);
    cfilternum:=0;
    while (pos(',',s)<>0) do begin
      cfilter[cfilternum]:=value(s); inc(cfilternum);
      s:=copy(s,pos(',',s)+1,length(s)-pos(',',s));
    end;
    cfilter[cfilternum]:=value(s); inc(cfilternum);
    cfilteron:=TRUE; cfiltercount:=0;
  end;
end;

procedure printa1(s:string; var abort,next:boolean);
var s1,s2,ss,sss,ssss,tcode,mcix,mcixx:string;
    i,ls,p1,p2,p3:integer;
    c,mc:char;
    savcurco:byte;
    isansi,iscolor,ismci,istcode,usetcodes:boolean;

  function nmci(s:string):string;
  begin
    nmci:='';
    case c of
      '1':nmci:=thisuser.name;
      '2':nmci:=thisuser.realname;
      '3':nmci:=thisuser.ph;
      '4':nmci:=thisuser.citystate;
      '5':nmci:=thisuser.street;
      '6':nmci:=thisuser.zipcode;
      '!':if (printingfile) then allowabort:=FALSE;
      '#':thisuser.ac:=thisuser.ac-[pause];
    end;
  end;

  procedure domci(c:char);
  begin
    case c of
      '7':cls;
      '8':delay(800);
      '9':pausescr;
    end;
  end;

  procedure dotcode(c:char; var s:string);
  var s1,s2:string;
  begin
    case mc of
      'c':if (pos(';',s)<>0) then begin
            s1:=copy(s,1,pos(';',s)-1);
            delete(s,1,length(s1)+1);
            loadcfilter(s1);
          end;
      'C':begin
            if (okansi) then setc(ord(s[1]));
            delete(s,1,1);
          end;
    end;
  end;

  procedure sends(s:string);
  var i:word;
  begin
    i:=0;
    while (i<length(s)) do begin
      inc(i);
      sendcom1(s[i]);
    end;
  end;

  procedure sendscfilter(s:string);
  var i:integer;
      bb:byte;
  begin
{    if (not (ansi in thisuser.ac)) then begin sends(s); exit; end;}
    i:=1;
    savcurco:=curco;
    while (i<=length(s)) do begin
      case cfiltertype of
        0:bb:=cfilter[ord(s[i])];
        1:begin
            cfiltercount:=cfiltercount mod cfilternum+1;
            bb:=cfilter[cfiltercount-1];
          end;
        2:bb:=cfilter[random(cfilternum)];
      end;
      if (bb<>curco) then begin
        if ((okavatar) or (mtcolors)) then omtcolor(bb) else pr1(getc(bb));
        curco:=bb;
      end;
      sendcom1(s[i]);
      inc(i);
    end;
    curco:=savcurco;
  end;

  procedure locs(s:string);
  var i:integer;
  begin
    i:=0;
    while (i<length(s)) do begin
      inc(i);
      lpromptc(s[i]);
{      if (s[i]=^H) then delay(systat.bsdelay);}
    end;
  end;

  procedure locscfilter(s:string);
  var i:integer;
      bb:byte;
  begin
{    if (not (ansi in thisuser.ac)) then begin locs(s); exit; end;}
    i:=1;
    while (i<=length(s)) do begin
      case cfiltertype of
        0:bb:=cfilter[ord(s[i])];
        1:begin
            cfiltercount:=cfiltercount mod cfilternum+1;
            bb:=cfilter[cfiltercount-1];
          end;
        2:bb:=cfilter[random(cfilternum)];
      end;
      if (bb<>curco) then begin textattr:=bb; curco:=bb; end;
      lpromptc(s[i]);
      inc(i);
    end;
  end;

  (* Forewarning to the faint of heart programmers:
     The following section of code contains "goto" statements.
     I'm VERY SORRY about this, and normally would NEVER EVER EVER
     use such pathetic coding.  ("Hey - where did this guy learn to
     program, anyway - a BASIC class!??!?")
  *)

  procedure handlecolors;
  label goto1;
  begin
      goto1:  { ack! }
    mc:=ss[p1+1]; sss:=copy(ss,1,p1-1);
    ss:=copy(ss,p1+2,length(ss)-(p1+1));

    if (outcom) then sends(sss);
    locs(sss);

    if ((mc>=#0) and (mc<=#9)) then cl(ord(mc)) else
      if ((mc>='0') and (mc<='9')) then cl(ord(mc)-48);

    p1:=pos(#3,ss);
    if (p1<>0) then goto goto1;
  end;

  procedure handletcodes;
  label goto1;  { *ACK!* }
  begin
      goto1:
    if ((p3<p2) and (p3<>0)) then begin
      istcode:=TRUE;
      p2:=p3;
    end else
      istcode:=FALSE;

    mc:=ss[p2+1]; sss:=copy(ss,1,p2-1);
    ss:=copy(ss,p2+2,length(ss)-(p2+1));

    if (outcom) then sends(sss);
    locs(sss);

    if (not istcode) then domci(mc) else
      dotcode(mc,ss);

    p2:=pos('@',ss); p3:=pos(^T,ss);
    if (p2+p3>0) then goto goto1;
  end;

  procedure handletcodesc;
  label goto1;  { **ACK!!!*!*!***** }
  begin
      goto1:
    if (p2<>500) then
      if (pos(ss[p2+1],mcixx)=0) then p2:=500;

    iscolor:=TRUE; istcode:=FALSE;
    if ((p2<p1) or (p3<p1)) then
      if ((p2<p1) and (p2<p3)) then begin p1:=p2; iscolor:=FALSE; end else
        if (p3<p1) then begin p1:=p3; iscolor:=FALSE; istcode:=TRUE; end;

    mc:=ss[p1+1]; sss:=copy(ss,1,p1-1);
    ss:=copy(ss,p1+2,length(ss)-(p1+1));

    if (outcom) then sends(sss);
    locs(sss);

    if (iscolor) then begin
      if ((mc>=#0) and (mc<=#9)) then cl(ord(mc)) else
        if ((mc>='0') and (mc<='9')) then cl(ord(mc)-48);
    end else
      if (not istcode) then domci(mc) else
        dotcode(mc,ss);

    p1:=pos(#3,ss); if (p1=0) then p1:=500;
    p2:=pos('@',ss); if (p2=0) then p2:=500;
    p3:=pos(^T,ss); if (p3=0) then p3:=500;
    if (p1+p2+p3<1500) then goto goto1;
  end;

begin
  tcode:=''; ss:='';
  if (abort) then exit;
  doit:=TRUE; isansi:=FALSE;
  if (pos(^[,s)<>0) then begin
    lil:=0;
    isansi:=TRUE;
  end else
    if (s[1]='&') then begin
      if (thisuser.sl<value(copy(s,2,4))) then doit:=FALSE;
      s:=copy(s,5,length(s)-4);
    end;
(*checkhangup;*)
  if ((hangup) or (not doit)) then begin abort:=TRUE; exit; end;
  ss:=s; sss:=''; i:=1;
  mcix:='123456!#'; mcixx:='789';
  if ((not write_msg) and ((not reading_a_msg) or (read_with_mci))) then
    if (pos('@',ss)<>0) then
      for i:=1 to 8 do begin
        c:=mcix[i];
        while (pos('@'+c,ss)<>0) do ss:=substone(ss,'@'+c,nmci(c));
      end;
  while (pos(#29,ss)<>0) do delete(ss,pos(#29,ss),1);
  if (not okansi) then ss:=stripcolor(ss);
  if (trapping) then write(trapfile,ss);

  {if ((isansi) and (okavatar)) then ss:=avatar(ss);}
  if (not cfilteron) then begin
    p1:=pos(#3,ss); if (p1=0) then p1:=500;
    p2:=pos('@',ss); if (p2=0) then p2:=500;
    p3:=pos(^T,ss); if (p3=0) then p3:=500;
    if (isansi) then begin
      p1:=500; p2:=500; p3:=500;
    end;

    if (((reading_a_msg) and (not read_with_mci)) and (p2+p3<>1000)) then
      begin p2:=500; p3:=500; end;

    if ((p2=500) and (p3=500)) then begin
      if (p1<>500) then handlecolors;
    end else
      if (p1=500) then handletcodes else handletcodesc;
    if (outcom) then sends(ss);
    locs(ss);
  end else begin
    if (outcom) then if (mtcfilteron) then sends(ss) else sendscfilter(ss);
    locscfilter(ss);
    if (cfiltertype=0) then
      if ((cfilter[32] and 112)<>0) then begin
        setc(cfilter[32]);
        if (okavatar) then pr1(^V+^G) else pr1(^['[K');
        clreol;
      end;
  end;
  wkey(abort,next);

(*
  findtcode:=FALSE; tcode:=''; ss:='';
  if (abort) then exit;
  doit:=TRUE;
  if (s[1]='&') then begin
    if (thisuser.sl<value(copy(s,2,4))) then doit:=FALSE;
    s:=copy(s,5,length(s)-4);
  end;
  if ((hangup) or (not doit)) then begin abort:=TRUE; exit; end;
  abort:=FALSE; next:=FALSE; i:=1;
  wkey(abort,next);
  ls:=length(s);
  while ((i<=ls) and (not abort) and (not hangup)) do begin
    didmci:=FALSE;
    if (findtcode) then begin
      tcode:=tcode+s[i];
      if ((copy(tcode,1,1)='c') and (s[i]=';')) then begin
        s1:=copy(tcode,2,length(tcode)-2);
        loadcfilter(s1);
        findtcode:=FALSE;
      end;
      inc(i);
    end else begin
      if ((s[i]='@') and (i<ls) and
          ((not reading_a_msg) or (read_with_mci))) then
        if (s[i+1] in ['1'..'9','!','#']) then begin
          if ((ss<>'') and (trapping)) then write(trapfile,ss);
          ss:='';
          domci(s[i+1]);
        end;
      if (not didmci) then begin
        case s[i] of
          #3:if (i<ls) then begin
               if (s[i+1] in [#0..#9]) then cl(ord(s[i+1])) else
                 if (s[i+1] in ['0'..'9']) then cl(ord(s[i+1])-48);
               inc(i);
             end;
          ^H:begin
               if (not croff) then dec(pap);
               delay(systat.bsdelay);
               outkey(s[i]);
               ss:=ss+s[i];
             end;
          ^T:findtcode:=TRUE;
        else
             begin
               outkey(s[i]);
               ss:=ss+s[i];
             end;
        end;
        wkey(abort,next);
        inc(i);
      end;
    end;
  end;
  if (trapping) then write(trapfile,ss);
*)
end;

procedure printacr(s:string; var abort,next:boolean);
var org:string;
    p,op,rp,rop,nca:integer;
    okdoit,sram,turnoff:boolean;

  procedure doboxedtitle(s:string);
  const B_UL='Ö'; B_UR='·'; B_LL='Ó'; B_LR='½';
        B_TOP='Ä'; B_BOT='Ä'; B_LFT='º'; B_RGT='º';
  var b:array[0..7] of char;
      x,numsp:integer;
      i:string;

    function ritr(c:char; l:integer):string;
    var s:string;
        i:integer;
    begin
      s:='';
      for i:=1 to l do s:=s+c;
      ritr:=s;
    end;

  begin
    i:=s;
    if (i[length(i)]=#1) then i:=copy(i,1,length(i)-1);
    if (okansi) then
      for x:=0 to 7 do
        case x of
          0:b[x]:=B_UL;   1:b[x]:=B_UR;   2:b[x]:=B_LL;  3:b[x]:=B_LR;
          4:b[x]:=B_TOP;  5:b[x]:=B_BOT;  6:b[x]:=B_LFT; 7:b[x]:=B_RGT;
        end
    else
      for x:=0 to 7 do
        case x of
          0:b[x]:='.';  1:b[x]:='.';  2:b[x]:='`';  3:b[x]:='''';
          4:b[x]:='-';  5:b[x]:='-';  6:b[x]:=':';  7:b[x]:=':';
        end;
    numsp:=(thisuser.linelen div 2)-((lenn(i)+4) div 2);
    printacr(#3#4+ritr(#32,numsp)+b[0]+ritr(b[4],lenn(i)+2)+b[1],abort,next);
    printacr(#3#4+ritr(#32,numsp)+b[6]+' '+#3#3+i+#3#4+' '+b[7],abort,next);
    printacr(#3#4+ritr(#32,numsp)+b[2]+ritr(b[5],lenn(i)+2)+b[3]+#3#1,abort,next);
  end;

begin
  if ((allowabort) and (abort)) then exit;
 
  if (s[length(s)]=#1) then
    if (copy(s,length(s)-1,1)<>#3) then s:=copy(s,1,length(s)-1);

  okdoit:=TRUE; abort:=FALSE; nopfile:=FALSE;
  turnoff:=(s[length(s)]=#29);

  if (copy(s,1,1)='&') then begin
    if (thisuser.sl<value(copy(s,2,4))) then exit;
    s:=copy(s,5,length(s)-4);
  end;
  checkhangup;


  if (pos(^[,s)>0) then begin
    printa1(s,abort,next);
    if ((not turnoff) and (not croff)) then begin
      nl;
      if (trapping) then writeln(trapfile);
    end;
    croff:=FALSE;
    exit;
  end else
  if (s[1]=#2) then begin
    printa1(centre(s),abort,next);
    if (not turnoff) then nl;
    croff:=FALSE; exit;
  end else
  if (length(s)>=3) and (copy(s,1,3)=BOXEDTITLE) then begin
    doboxedtitle(copy(s,4,length(s)-3));
    croff:=FALSE; exit;
  end else begin
{    wkey(abort,next);}
    printa1(s,abort,next);
    if (abort) then begin curco:=255-curco; cl(1); end;
    if ((not nofeed) and (doit) and (not croff) and (not turnoff)) then
      if (not abort) then nl;
    doit:=TRUE;
  end;
  croff:=FALSE;
end;

procedure pfl(fn:string; var abort,next:boolean; cr:boolean);
var fil:text;
    ofn:string;
    ls:string[255];
    ps:integer;
    c:char;
    oldpause,oaa:boolean;
begin
  cfilteron:=FALSE; cfiltertype:=0; cfilternum:=0; cfiltercount:=0;
  printingfile:=TRUE;
  oaa:=allowabort;
  allowabort:=TRUE;
  abort:=FALSE; next:=FALSE;
{  if (not allowabort) then begin
    abort:=FALSE; next:=FALSE;
  end;}
  oldpause:=(pause in thisuser.ac);
  nofile:=FALSE;
  if (not hangup) then begin
    assign(fil,sqoutsp(fn));
    {$I-} reset(fil); {$I+}
    if (ioresult<>0) then nofile:=TRUE
    else begin
      abort:=FALSE;
      while ((not eof(fil)) and (not nofile) and
             (not abort) and (not hangup)) do begin
        ps:=0;
        repeat
          inc(ps);
          read(fil,ls[ps]);
        until ((ls[ps]=^M) or (ps=255) or (eof(fil)) or (hangup));
        ls[0]:=chr(ps);
        if (ls[ps]=^M) then begin
          if (not eof(fil)) then read(fil,c);
          ls[0]:=chr(ps-1);
        end else
          croff:=TRUE;
        if (pos(^[,ls)<>0) then ctrljoff:=TRUE;
        printacr(ls,abort,next);
      end;
      close(fil);
{      if (abort) then nl;}
    end;
  end;
  if (oldpause) then thisuser.ac:=thisuser.ac+[pause];
  allowabort:=oaa;
  if (mtcfilteron) then begin pr1(^T'c-'); mtcfilteron:=FALSE; end;
  cfilteron:=FALSE; printingfile:=FALSE; ctrljoff:=FALSE;
  curco:=255-curco; cl(1);
  redrawforansi;
end;

function exist(fn:string):boolean;
var srec:searchrec;
begin
  findfirst(sqoutsp(fn),anyfile,srec);
  exist:=(doserror=0);
end;

procedure printfile(fn:string);
var s:string;
    year,month,day,dayofweek:word;
    i,j:integer;
    abort,next:boolean;
begin
  {rcg11182000 moved this allcaps into the first IF, for case-sensitive fs.}
  {fn:=allcaps(fn); s:=fn;}
  {if (copy(fn,length(fn)-3,4)='.ANS') then begin}

  {rcg11182000 lowercased rest of extentions.}
  s:=fn;
  if (allcaps(copy(fn,length(fn)-3,4))='.ANS') then begin
    if (exist(copy(fn,1,length(fn)-4)+'.an1')) then
      repeat
        i:=random(10);
        if (i=0) then
          fn:=copy(fn,1,length(fn)-4)+'.ans'
        else
          fn:=copy(fn,1,length(fn)-4)+'.an'+cstr(i);
      until (exist(fn));

    getdate(year,month,day,dayofweek);
    s:=fn; s[length(s)-1]:=chr(dayofweek+48);
    if (exist(s)) then fn:=s;
  end;
  pfl(fn,abort,next,TRUE);
end;

procedure printf(fn:string);              { see if an *.ANS file is available }
var ffn,ps,ns,es:string;                  { if you have ansi graphics invoked }
    i,j:integer;
begin
  nofile:=TRUE;
  fn:=sqoutsp(fn);
  if (fn='') then exit;
  {rcg11182000 dosism.}
  {if (pos('\',fn)<>0) then j:=1}
  if (pos('/',fn)<>0) then j:=1
  else begin
    j:=2;
    fsplit(fexpand(fn),ps,ns,es);
    if (not exist(systat.afilepath+ns+'.*')) then
      if (not exist(systat.gfilepath+ns+'.*')) then exit;
  end;
  for i:=1 to j do begin
    ffn:=fn;
    {rcg11182000 dosism.}
    {if ((pos('\',fn)=0) and (pos(':',fn)=0)) then}
    if ((pos('/',fn)=0) and (pos(':',fn)=0)) then
      case i of
        1:ffn:=systat.afilepath+ffn;
        2:ffn:=systat.gfilepath+ffn;
      end;
    ffn:=fexpand(ffn);
    if (pos('.',fn)<>0) then printfile(ffn)
    else begin
      if ((okansi) and (not okavatar)) and (exist(ffn+'.ans')) then printfile(ffn+'.ans');
      if (nofile) then
        if (thisuser.linelen<80) and (exist(ffn+'.40c')) then
          printfile(ffn+'.40c')
        else
          if (exist(ffn+'.msg')) then printfile(ffn+'.msg');
    end;
    if (not nofile) then exit;
  end;
end;

procedure skey(c:char);   (* Global user keys *)
var ddt,dt:datetimerec;
    s:string;
    savpap:integer;
    bb:byte;
begin
  case c of
   ^D,^E,^F,^R:
      if (macok) and (buf='') then dm(' '+macros.macro[pos(c,^D^E^F^R)],c);
   ^T:begin
        bb:=curco;
        savpap:=pap;
        nl;
        if (useron) then
          sprint('@M'+#3+chr(systat.sysopcolor)+systat.bbsname+
            ' ('+systat.bbsphone+')');
        nl;
        sprint(#3#0+'DateTime...: '+#3#9+dat);
        if (useron) then begin
          sprint(#3#0+'Time left..: '+#3#5+'@T');
          getdatetime(dt);
          timediff(ddt,timeon,dt);
          sprint(#3#0+'Time on....: '+#3#5+longtim(ddt));
        end;
        nl;
        pap:=savpap; curco:=bb; sdc;
      end;
 #127:c:=#8;
  end;
end;

function verline(i:integer):string;
var s:string;
begin
  case i of
    1:begin
        s:='Project Coyote 0.14 Alpha ';
      end;
    2:s:='Complied By Robert Merritt on 11-19-92';
  end;
  verline:=s;
end;

function aacs1(u:userrec; un:integer; s:string):boolean;
var s1,s2:string;
    p1,p2,i,j:integer;
    c,c1,c2:char;
    b:boolean;

  procedure getrest;
  begin
    s1:=c;
    p1:=i;
    if ((i<>1) and (s[i-1]='!')) then begin s1:='!'+s1; dec(p1); end;
    if (c in ['C','F','G','R','V','X']) then begin
      s1:=s1+s[i+1];
      inc(i);
    end else begin
      j:=i+1;
      repeat
        if (s[j] in ['0'..'9']) then begin
          s1:=s1+s[j];
          inc(j);
        end;
      until ((j>length(s)) or (not (s[j] in ['0'..'9'])));
      i:=j-1;
    end;
    p2:=i;
  end;

  function argstat(s:string):boolean;
  var vs:string;
      year,month,day,dayofweek,hour,minute,second,sec100:word;
      vsi:integer;
      boolstate,res:boolean;
  begin
    boolstate:=(s[1]<>'!');
    if (not boolstate) then s:=copy(s,2,length(s)-1);
    vs:=copy(s,2,length(s)-1); vsi:=value(vs);
    case s[1] of
      'A':res:=(ageuser(u.bday)>=vsi);
      'B':res:=((value(spd)>=value(vs+'00')) or (spd='KB'));
      'C':res:=FALSE;   { conferences - not implemented yet }
      'D':res:=(u.dsl>=vsi);
      'F':res:=(upcase(vs[1]) in u.ar);
      'G':res:=(u.sex=upcase(vs[1]));
      'H':begin
            gettime(hour,minute,second,sec100);
            res:=(hour=vsi);
          end;
      'P':res:=(u.filepoints>=vsi);
      'R':res:=(tacch(upcase(vs[1])) in u.ac);
      'S':res:=(u.sl>=vsi);
      'T':res:=(trunc(nsl) div 60>=vsi);
      'U':res:=(un=vsi);
      'V':res:=((u.sl>systat.newsl) or (u.dsl>systat.newdsl) or
           ((systat.newsl=systat.autosl) and (systat.newdsl=systat.autodsl)));
      'W':begin
            getdate(year,month,day,dayofweek);
            res:=(dayofweek=ord(s[1])-48);
          end;
      'Y':res:=(trunc(timer) div 60>=vsi);
    end;
    if (not boolstate) then res:=not res;
    argstat:=res;
  end;

begin
  s:=allcaps(s);
  i:=0;
  while (i<length(s)) do begin
    inc(i);
    c:=s[i];
    if (c in ['A'..'Z']) and (i<>length(s)) then begin
      getrest;
      b:=argstat(s1);
      delete(s,p1,length(s1));
      if (b) then s2:='^' else s2:='%';
      insert(s2,s,p1);
      dec(i,length(s1)-1);
    end;
  end;
  s:='('+s+')';
  while (pos('&',s)<>0) do delete(s,pos('&',s),1);
  while (pos('^^',s)<>0) do delete(s,pos('^^',s),1);
  while (pos('(',s)<>0) do begin
    i:=1;
    while ((s[i]<>')') and (i<=length(s))) do begin
      if (s[i]='(') then p1:=i;
      inc(i);
    end;
    p2:=i;
    s1:=copy(s,p1+1,(p2-p1)-1);
    while (pos('|',s1)<>0) do begin
      i:=pos('|',s1);
      c1:=s1[i-1]; c2:=s1[i+1];
      s2:='%';
      if ((c1 in ['%','^']) and (c2 in ['%','^'])) then begin
        if ((c1='^') or (c2='^')) then s2:='^';
        delete(s1,i-1,3);
        insert(s2,s1,i-1);
      end else
        delete(s1,i,1);
    end;
    while(pos('%%',s1)<>0) do delete(s1,pos('%%',s1),1);   {leave only "%"}
    while(pos('^^',s1)<>0) do delete(s1,pos('^^',s1),1);   {leave only "^"}
    while(pos('%^',s1)<>0) do delete(s1,pos('%^',s1)+1,1); {leave only "%"}
    while(pos('^%',s1)<>0) do delete(s1,pos('^%',s1),1);   {leave only "%"}
    delete(s,p1,(p2-p1)+1);
    insert(s1,s,p1);
  end;
  aacs1:=(not (pos('%',s)<>0));
end;

function aacs(s:string):boolean;
begin
  aacs:=aacs1(thisuser,usernum,s);
end;

{ load account "i" if i<>usernum; else use "thisuser" account }
procedure loadurec(var u:userrec; i:integer);
var ufo:boolean;
begin
  ufo:=(filerec(uf).mode<>fmclosed);
  if (not ufo) then reset(uf);
  if (i<>usernum) then begin
    seek(uf,i);
    read(uf,u);
  end else
    u:=thisuser;
  if (not ufo) then close(uf);
end;

{ save account "i" if i<>usernum; save data into "thisuser" account if same }
procedure saveurec(u:userrec; i:integer);
var ufo:boolean;
begin
  ufo:=(filerec(uf).mode<>fmclosed);
  if (not ufo) then reset(uf);
  seek(uf,i); write(uf,u);
  if (i=usernum) then thisuser:=u;
  if (not ufo) then close(uf);
end;

end.
