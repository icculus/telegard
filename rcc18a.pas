CONST
  s_ver1:string[20]='1.8b';
  ver1:string[20]='1.8b';
  verdate1='Sep 18 1989';

  maxusers1=500;
  maxboards1=64;       { 1 - x }
  maxuboards1=96;      { 0 - x }
  maxprotocols1=120;   { 0 - x }
  maxevents1=10;       { 0 - x }   { #0 is Nightly Events (if active) }
  maxarcs1=8;          { 1 - x }
  maxubatchfiles1=20;
  numvoteqs1=20;
  numvoteas1=9;
  maxmenucmds1=50;

TYPE
  astr1 = string[160];  { generic string type for parameters       }
                       { note the change from Wayne's str => astr1 }

  acstring1=string[20];                { Access Condition String }
  acrq1    ='@'..'Z';                  { AR flags }
  newtyp1  =(rp1,lt1,rm1);                { message NewScan type }
  uflags1  =(rlogon1,rchat1,rvalidate1,rbackspace1,
            ramsg1,rpostan1,rpost1,remail1,
            rvoting1,rmsg1,spcsr1,onekey1,
            wordwrap1,pause1,novice1,ansi1,
            color1,alert1,smw1,nomail1,
            fnodlratio1,fnopostratio1,fnofilepts1,fnodeletion1);
  dlnscan1 =set of 0..maxuboards1;
  emary1   =array[1..20] of integer;
  anontyp1 =(no1,yes1,forced1,dearabby1,anyname1); { anonymous types }
  clrs1    =array[FALSE..TRUE,0..9] of byte;  { color records }
  secrange1=array[0..255] of integer;         { security tables }

  messages1=                           { message file name records }
    record
      ltr:char;                       { ("A")      letter }
      number:integer;                 { ("-32767") number }
      ext:byte;                       { (".1")     extension }
    end;

  smalrec1=                            { NAMES.LST : Sorted names listing }
    record
      name:string[36];                { user name }
      number:integer;                 { user number }
    end;

  userrec1=                            { USER.LST : User account records }
    record
      name:string[36];                { user name        }
      realname:string[36];            { real name        }
      pw:string[20];                  { user password    }
      ph:string[12];                  { user phone #     }
      bday:string[8];                 { user birthdate   }
      firston:string[8];              { firston date     }
      x1xs:array[1..2] of byte;
      laston:string[8];               { laston date      }
      x2xs:array[1..2] of byte;
      street:string[30];              { mailing address  }
      citystate:string[30];           { city, state      }
      zipcode:string[10];             { zipcode          }
      computer:string[30];            { type of computer }
      occupation:string[40];          { occupation       }
      wherebbs:string[40];            { BBS reference    }
      note:string[39];                { SysOp note       }

      lockedout:boolean;              { if locked out    }
      deleted:boolean;                { if deleted       }
      lockedfile:string[8];           { lockout msg to print }

      ac:set of uflags1;               { user flags   }
      ar:set of acrq1;                 { AR flags     }

      qscan:array[1..maxboards1] of messages1; { last read msg pointers }
      qscn:array[1..maxboards1] of boolean; { scan boards flags  }
      dlnscn:dlnscan1;                 { scan uboards flags }

      vote:array[1..20] of byte;      { voting data  }

      sex:char;                       { user sex }

      ttimeon:longint;                { total mins spent on  }
      x1xx:integer;
      uk:longint;                     { UL k                 }
      x2xx:integer;
      dk:longint;                     { DL k                 }
      x3xx:integer;

      uploads,downloads,              { # of ULs / # of DLs  }
      loggedon,                       { # times logged on    }
      tltoday,                        { # min left today     }
      msgpost,                        { # public posts       }
      emailsent,                      { # email sent         }
      feedback,                       { # feedback sent      }
      forusr,                         { forward mail to user # }
      filepoints:integer;             { # of file points     }

      waiting,                        { mail waiting         }
      linelen,                        { line length (# cols) }
      pagelen,                        { page length (# rows) }
      ontoday,                        { # times on today     }
      illegal,                        { # illegal logon attempts }
      sl,dsl:byte;                    { SL / DSL }

      cols:clrs1;                      { user colors }

      lastmsg,lastfil:byte;           { last msg/file areas   }
      credit:longint;                 { $$$ credit in dollars }
      x4xx:integer;
      timebank:integer;               { # mins in Time Bank   }
      boardsysop:array[1..5] of byte; { msg board SysOp       }

      trapactivity,                   { if trapping users activity }
      trapseperate:boolean;           { if trap to seperate TRAP file }

      timebankadd:integer;            { time added to timebank TODAY }
      mpointer:longint;               { pointer to entry in MACRO.LST }
      chatauto,                       { if auto chat trapping }
      chatseperate:boolean;           { if seperate chat file to trap to }
    userstartmenu:string[8];       { menu to start user out on }
      slogseperate:boolean;           { seperate SysOp log? }
      clsmsg:byte;                    { 1 if clear-screen msg, 2 if not }

{ NEW STUFF }


{ NEW STUFF *ENDS* }

      res:array[1..57] of byte;       { RESERVED }
    end;

  msgstat1=(validated1,                 { validated }
           unvalidated1,               { unvalidated }
           deleted1,                   { deleted }
           permanentpost1,             { post is permanent }
           mciallowed1,                { owner of post has access to MCI }
           anonymouspost1,             { post is anonymous (any type) }
           sysopanonymous1);           { anonymous post made by SysOp }

  messagerec1=                         { *.BRD : Public message records }
    record
      title:string[50];               { title of message }
      messagestat:set of msgstat1;     { message status }
      message:messages1;               { message filename }
      owner,                          { from user # }
      date,                           { date of message }
      nacc:integer;                   { number of times read }
    end;

  mailrec1=                            { EMAIL.DAT : Private mail records }
    record
      title:string[30];               { title of e-mail }
      from,                           { from user # }
      destin:integer;                 { to user # }
      msg:messages1;                   { message filename }
      date:integer;                   { date of message }
      mage:byte;                      { max days message can exist }
    end;

  zlogrec1=                            { ZLOG.DAT : System log }
    record
      date:string[8];
      userbaud:array[0..4] of integer;
      active,calls,newusers,pubpost,privpost,fback,criterr:integer;
      uploads,downloads:integer;
      uk,dk:longint;
    end;

  filearcinforec1=                     { Archive configuration records }
    record
      active:boolean;                 { whether this archive format is active }
      ext:string[3];                  { 3-chr file extension }
      listline:string[25];            { /x for internal;
                                        x: 1=ZIP, 2=ARC/PAK, 3=ZOO, 4=LZH }
      arcline:string[25];             { compression cmdline }
      unarcline:string[25];           { de-compression cmdline }
      testline:string[25];            { integrity test cmdline, '' for *None* }
      cmtline:string[25];             { comment cmdline, '' for *None* }
      succlevel:integer;              { success ERRORLEVEL, -1=ignore results }
    end;

  modemrec1=
    record
      waitbaud:word;                  { wait baud }
      comport:byte;                   { comport number }
      init:string[80];                { initialization string }
      answer:string[40];              { answer string }
      hangup:string[40];              { hangup string }
      offhook:string[40];             { phone off-hook string }
      nocallinittime:integer;       { reinit modem after x mins of inactivity }
      arq9600rate:word;          { baud rate to USE when 9600 ARQ result code }
      noforcerate:boolean;            { whether to force baud rate}
      nocarrier:integer;              { no carrier result code }
      nodialtone:integer;             { no dialtone result code }
      busy:integer;                   { busy result code }
      resultcode:array[1..2,0..4] of integer; {**-Result codes-** }
      ctschecking:boolean;
      dsrchecking:boolean;
      usexonxoff:boolean;
      hardwired:boolean;
    end;

  fstringrec1=
    record
      ansiq:string[80];               { "Do you want ANSI? " string }
      note:array[1..2] of string[80]; { Logon notes (L #1-2) }
      lprompt:string[80];             { Logon prompt (L #3) }
      echoc:char;                     { Echo char for PWs }
      sysopin,                        { "SysOp In" (inside SysOp hours)}
      sysopout,                       { "SysOp Out" }
      engage,                         { "Engage Chat" }
      endchat,                        { "End Chat" }
      wait,                           { "SysOp Working" }
      pause,                          { "Pause" }
      entermsg1,                      { "Enter Message" line #1 }
      entermsg2,                      { "Enter Message" line #2 }
      newscan1,                       { "NewScan begin" }
      newscan2,                       { "NewScan done" }
      scanmessage,                    { Message scanning prompt }
      automsgt:string[80];            { Auto-Message title }
      autom:char;                     { Auto-Message border characters }

      shelldos1,                      { " >> SysOp shelling to DOS ..." }
      shelldos2,                      { " ... thank you for waiting." }
      chatcall1,                      { "Paging SysOp, please wait..." }
      chatcall2,                      { ">>><*><<<" }
      guestline,                      { "To be a guest ... " }
      namenotfound,                   { "Name NOT found in user list." }
      bulletinline,                   { Bulletin line }
      thanxvote,                      { "Thanks for voting" }

      listline,                       { "List files - P to pause" }
      newline,                        { "Search for new files -" }
      searchline,                     { "Search all dirs for file mask" }
      findline1,                      { "Search for descriptions... " }
      findline2,                      { "Enter the string to search for.." }
      downloadline,                   { "Download - " }
      uploadline,                     { "Upload - " }
      viewline,                       { "View interior files - " }
      nofilepts,                      { "Insufficient file points." }
      unbalance,                      { "Your UL/DL ratio is unbalanced" }

      pninfo,                         { "P to Pause, N for next dir" }
      gfnline1,                       { "[Enter]=All files" }
      gfnline2,                       { "File mask: " }
      batchadd:string[80];            { "File added to batch queue." }
    end;

  systatrec1=
    record
      gfilepath:string[79];           { GFILES path }
      afilepath:string[79];           { AFILES path (text files path) }
      menupath:string[79];            { MENUS path  }
      trappath:string[79];            { LOG path (traps, chats, SysOp logs) }
      pmsgpath:string[79];            { PMSGS path (private mail path) }
      tfilepath:string[79];           { TFILES path }
      temppath:string[79];            { TEMP path - "temp" directory }

      bbsname:string[80];             { BBS name }
      bbsphone:string[12];            { BBS phone number }
      sysopname:string[30];           { SysOp's full name or alias }
      maxusers,                       { max number of users system can have }
      lowtime,                        { SysOp begin minute (in minutes) }
      hitime,                         { SysOp end time }
      dllowtime,                      { normal downloading hours begin.. }
      dlhitime:integer;               { ..and end }
      shuttlelog,                     { is Shuttle Logon active? }
      lock300:boolean;                { lock out 300 baud? }
      sysoppw,                        { SysOp PW }
      newuserpw,                      { newuser PW (or NULL if none) }
      shuttlepw:string[20];           { Shuttle PW (if Shuttle active) }
      b300lowtime,                    { 300 baud calling hours begin.. }
      b300hitime,                     { ..and end }
      b300dllowtime,                  { 300 baud downloading hours begin.. }
      b300dlhitime:integer;           { ..and end }
      closedsystem:boolean;           { DON'T allow new users? }
      snowchecking:boolean;           { is snow checking on? }
      eventwarningtime:integer;       { time before event warning }
      tfiledate:string[8];            { last date text-files were inserted }
      hmsg:messages1;                  { highest message pointer }
      res1:array[1..20] of byte;      { RESERVED SPACE #1 }

      sop,                            { SysOp }
      csop,                           { Co-SysOp }
      msop,                           { Message SysOp }
      fsop,                           { File SysOp }
      spw,                            { SysOp PW at logon }
      seepw,                          { see SysOp PWs remotely  }
      normpubpost,                    { make normal public posts }
      normprivpost,                   { send normal e-mail }
      anonpubread,                    { see who posted public anon }
      anonprivread,                   { see who sent anon e-mail }
      anonpubpost,                    { make anon posts }
      anonprivpost,                   { send anon e-mail }
      seeunval,                       { see unvalidated files }
      dlunval,                        { DL unvalidated files }
      nodlratio,                      { no UL/DL ratio }
      nopostratio,                    { no post/call ratio }
      nofilepts,                      { no file points checking }
      ulvalreq:acstring1;              { uploads require validation by SysOp }
      res2:array[1..100] of byte;     { RESERVED SPACE #2 }

      maxprivpost,                    { max e-mail can send per call }
      maxfback,                       { max feedback per call }
      maxpubpost,                     { max posts per call }
      maxchat,                        { max chat-pages per call }
      maxwaiting,                     { max mail in mail-box }
      csmaxwaiting,                   { max mail in mail-box for Co-SysOp + }
      maxlines,                       { max lines in message }
      csmaxlines,                     { max lines in message for Co-SysOp + }
      maxlogontries,                  { tries allowed for PW's at logon }
      bsdelay,                        { backspacing delay }
      sysopcolor,                     { SysOp color in chat mode }
      usercolor:byte;                 { user color in chat mode }
      minspaceforpost,                { minimum K drive space left to post }
      minspaceforupload:integer;      { minimum K drive space left to upload }
      backsysoplogs,                  { days to keep SYSOP##.LOG }
      wfcblanktime:byte;              { minutes after which to blank WFC menu }
      res3:array[1..20] of byte;      { RESERVED SPACE #3 }

      specialfx,                      { WFC menu "special effects" }
      clearmsg,                       { if clear screen before message }
      allowalias,                     { allow alias's? (handles) }
      phonepw,                        { use phone number password in logon? }
      localsec,                       { is local security ON? }
      localscreensec,                 { is local screen-security ON? }
      globaltrap,                     { trap ALL USER'S activity? }
      autochatopen,                   { does chat buffer auto-open? }
      autominlogon,                   { Auto-Message in logon? }
      bullinlogon,                    { bulletins in logon? }
      lcallinlogon,                   { "Last Few Callers" list in logon? }
      yourinfoinlogon,                { "Your Info" in logon? }
      multitask,                      { is BBS multitasking? }
      offhooklocallogon,              { take phone off-hook for local logons? }
      forcevoting,                    { is manditory logon voting active? }
      compressbases,                  { "compress" file/message base numbers? }
      searchdup:boolean;              { search for dup. filenames when UL? }
      slogtype:byte;                  { SysOp log type: File/Printer/Both }
      stripclog:boolean;              { strip colors from SysOp log output? }
      newapp,                         { user# to send new user application to }
      guestuser,                      { user# of guest user account }
      timeoutbell,                    { minutes before time-out bell }
      timeout:integer;                { minutes before timeout (logoff) }
      usewfclogo:boolean;             { whether to use WFC menu logo }
      res4:array[1..19] of byte;      { RESERVED SPACE #4 }

      filearcinfo:array[1..maxarcs1] of filearcinforec1; { archive specs }
      filearccomment:array[1..3] of string[80]; { BBS comments for archives }
      uldlratio,                      { are UL/DL ratios active? }
      fileptratio:boolean;            { is auto file-pt compensation active? }
      fileptcomp,                     { file point compensation ratio }
      fileptcompbasesize,             { file point "base compensation size" }
      ulrefund,                       { percent time refund for ULs }
      tosysopdir:byte;                { "To SysOp" file base }
      validateallfiles:boolean;       { validate ALL FILES automatically? }
      remdevice:string[10];           { remote output device (GATEx,COMx,etc) }
      maxintemp,                      { max K allowed in TEMP\3\ }
      minresume:integer;              { min K to allow resume-later }
      maxdbatch,                      { max files in DL batch queue }
      maxubatch:byte;                 { max files in UL batch queue }
      res5:array[1..30] of byte;      { RESERVED SPACE #5 }

      newsl,                          { newuser SL }
      newdsl:byte;                    { newuser DSL }
      newar:set of acrq1;              { newuser AR }
      newac:set of uflags1;            { newuser AC }
      newfp:integer;                  { newuser file points }
      autosl,                         { auto-validation SL }
      autodsl:byte;                   { auto-validation DSL }
      autoar:set of acrq1;             { auto-validation AR }
      autoac:set of uflags1;           { auto-validation AC }

      allstartmenu:string[8];         { logon menu to start ALL users on }
      chatcfilter1,                   { SysOp chat color-filter }
      chatcfilter2:string[12];        { user chat color-filter }
      bulletprefix:string[8];         { default bulletins filename prefix }
      res6:array[1..15] of byte;      { RESERVED SPACE #6 }

      timeallow,                      { time allowance }
      callallow,                      { call allowance }
      dlratio,                        { # ULs/# DLs ratios }
      dlkratio,                       { DLk/ULk ratios }
      postratio:secrange1;             { post/call ratios }

      lastdate:string[8];             { last system date }
      curwindow:byte;                 { type of SysOp window currently in use }
      istopwindow:boolean;            { is SysOp window on top of screen? }
      callernum:longint;              { total number of callers }
      numusers:integer;               { number of users }

      todayzlog:zlogrec1;              { TODAY's ZLOG record }

      postcredits:integer; {file points/upload credit compensation for posts}
      rebootforevent:boolean;         { reboot before events? }
      watchdogdoor:boolean;           { Telegard WatchDog active in doors? }

      windowon:boolean;
      res:array[1..199] of byte;      {((((((>>> RESERVED <<<))))))}
    end;

{*}tbflags1=(tbunhidden1,                { whether *VISIBLE* to users w/o access }
{*}        tbnetlink1,                 { whether Net-Linked to other Telegards }
{*}        tbisdir1);                  { if a text-file base directory }

  tfilerec1=                           { GFILES.DAT : Text-file records }
    record
      title:string[40];               { title }
      filen:string[12];               { filename }
      gdate:string[8];                { date of Tfile / Tfile base }
      gdaten:integer;                 { numeric date for fast calculation }
      acs,                            { access requirement }
      ulacs:acstring1;                 { upload to base access requirement }
      tbstat:set of tbflags1;          { text-file base status vars }
      permindx:longint;               { permanent index # }
  tbdepth:integer;                { tfile base dir depth }
      res:array[1..4] of byte;        { RESERVED }
    end;

  smr1=
    record
      msg:astr1;
      destin:integer;
    end;

  vdatar1=                             { VOTING.DAT : Voting records }
    record
      question:string[79];            { Voting question }
      numa:integer;                   { Number of user's who have answered }
      answ:array[0..numvoteas1] of
        record
          ans:string[40];             { Answer description }
          numres:integer;             { # user's who picked this answer }
        end;
    end;

  mbflags1=(mbunhidden1,                { whether *VISIBLE* to users w/o access }
{*}        mbnetlink1,                 { whether Net-Linked to other Telegards }
{*}        mbisdir1,                   { if a message base directory }
{*}        mbmsgpath1);                { if *.BRD file stored in MSGPATH }

  boardrec1=                           { BOARDS.DAT : Message base records }
    record
      name:string[40];                { message base description }
      filename:string[12];            { *.BRD data filename }
      msgpath:string[40];             { messages pathname   }
      acs,                            { access requirement }
      postacs,                        { post access requirement }
      mciacs:acstring1;                { MCI usage requirement }
      maxmsgs:word;                   { max message count }
      anonymous:anontyp1;              { anonymous type }
      password:string[20];            { base password }
      mbstat:set of mbflags1;          { message base status vars }
      permindx:longint;               { permanent index # }
{*}mbdepth:integer;                { message base dir depth }
      res:array[1..4] of byte;        { RESERVED }
    end;

  fbflags1=(fbnoratio1,                 { if <No Ratio> active }
           fbunhidden1,                { whether *VISIBLE* to users w/o access }
           fbdirdlpath1,               { if *.DIR file stored in DLPATH }
{*}        fbisdir1,                   { if a file base directory }
           fbusegifspecs1,             { whether to use GifSpecs }
{*}        fbnetlink1);                { whether Net-Linked to other Telegards }

  ulrec1=                              { UPLOADS.DAT : File base records }
    record
      name:string[40];                { area description  }
      filename:string[12];            { filename + ".DIR" }
      dlpath,                         { download path     }
      ulpath:string[40];              { upload path       }
      maxfiles:integer;               { max files allowed }
      password:string[20];            { password required }
      arctype,                        { wanted archive type (1..maxarcs,0=inactive) }
      cmttype:byte;                   { wanted comment type (1..3,0=inactive) }
{*}fbdepth:integer;                { file base dir depth }
      fbstat:set of fbflags1;          { file base status vars }
      acs,                            { access requirements }
      ulacs,                          { upload requirements }
      nameacs:acstring1;               { see-names requirements }
      permindx:longint;               { permanent index # }
      res:array[1..6] of byte;        { RESERVED }
    end;

  filstat1=(notval1,                    { if file is NOT validated }
           isrequest1,                 { if file is REQUEST }
           resumelater1);              { if file is RESUME-LATER }

  ulfrec1=                             { *.DIR : File records }
    record
      filename:string[12];            { Filename }
      description:string[60];         { File description }
      filepoints:integer;             { File points }
      nacc:integer;                   { Number DLs }
      ft:byte;                        { File type (useless?) }
      blocks:integer;                 { # 128 byte blks }
      owner:integer;                  { ULer of file }
      stowner:string[36];             { ULer's name }
      date:string[8];                 { Date ULed }
      daten:integer;                  { Numeric date ULed }
      vpointer:longint;               { Pointer to verbose descr, -1 if none }
      filestat:set of filstat1;        { File status }
      res:array[1..10] of byte;       { RESERVED }
    end;

  verbrec1=                            { VERBOSE.DAT : Verbose descriptions }
    record
      descr:array[1..4] of string[50];
    end;

  lcallers1=                           { LASTON.DAT : Last few callers records }
    record
      callernum:integer;              { System caller number }
      name:string[36];                { User name of caller }
      number:integer;                 { User number of caller }
      citystate:string[30];           { City, State of caller }
    end;

  eventrec1=                           { EVENTS.DAT : Event records }
    record
      active:boolean;                 { Whether active }
      description:string[30];         { Event description (for logs) }
      etype:char;                     { A:CS, C:hat, D:os call, E:xternal }
      execdata:string[20];            { Errorlevel if "E", commandline if "D" }
      busytime:integer;               { Off-hook time before; 0 if none }
      exectime:integer;               { Time of execution }
      busyduring:boolean;             { Busy phone DURING event? }
      duration:integer;               { Length of time event takes }
      execdays:byte;                  { Bitwise execution days or day of month if monthly }
      monthly:boolean;                { Monthly event? }
    end;

  macrorec1=                           { MACROS.LST : Macro records }
    record
      macro:array [1..4] of string[240];
    end;

  mnuflags1=(clrscrbefore1,             { C: clear screen before menu display }
            dontcenter1,               { D: don't center the menu titles! }
            nomenuprompt1,             { N: no menu prompt whatsoever? }
            forcepause1,               { P: force a pause before menu display? }
            autotime1);                { T: is time displayed automatically? }

  menurec1=                            { *.MNU : Menu records }
    record
      menuname:array[1..3] of string[100]; { menu name }
      directive,                      { help file displayed }
      tutorial:string[12];            { tutorial help file }
      menuprompt:string[120];         { menu prompt }
      acs:acstring1;                   { access requirements }
      password:string[15];            { password required }
      fallback:string[8];             { fallback menu }
      forcehelplevel:byte;            { forced help level for menu }
      gencols:byte;                   { generic menus: # of columns }
      gcol:array[1..3] of byte;       { generic menus: colors }
      menuflags:set of mnuflags1;      { menu status variables }
    end;

  cmdflags1=(hidden1,                   { H: is command ALWAYS hidden? }
            unhidden1);                { U: is command ALWAYS visible? }

  commandrec1=                         { *.MNU : Command records }
    record
      ldesc:string[70];               { long command description }
      sdesc:string[35];               { short command description }
      ckeys:string[14];               { command-execution keys }
      acs:acstring1;                   { access requirements }
      cmdkeys:string[2];              { command keys: type of command }
      mstring:string[50];             { MString: command data }
      commandflags:set of cmdflags1;   { command status variables }
    end;

  xbflags1=(xbactive1,
           xbisbatch1,
           xbisresume1,
           xbxferokcode1);
  protrec1=
    record
      xbstat:set of xbflags1;                     { protocol flags }
      ckeys:string[14];                          { command keys }
      descr:string[40];                          { description }
      acs:acstring1;                              { access string }
      templog:string[25];                        { temp. log file }
      uloadlog,dloadlog:string[25];              { permanent log files }
      ulcmd,dlcmd:string[78];                    { UL/DL commandlines }
      ulcode,dlcode:array [1..6] of string[6];   { UL/DL codes }
      envcmd:string[60];                      {B}{ environment setup cmd }
      dlflist:string[25];                     {B}{ DL file lists }
      maxchrs:integer;                           { max chrs in cmdline }
      logpf,logps:integer;                    {B}{ pos in log file for data }
      permindx:longint;                          { permanent index # }
      res:array[1..11] of byte;                  { RESERVED }
    end;

  datetimerec1=
    record
      day,hour,min,sec:longint;
    end;

  cfilterrec1=array[0..255] of byte;   { color filter record }

