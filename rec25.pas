(*****************************************************************************)
(*>                                                                         <*)
(*>  Telegard Bulletin Board System - Copyright 1988,89,90 by               <*)
(*>  Eric Oman, Martin Pollard, and Todd Bolitho - All rights reserved.     <*)
(*>                                                                         <*)
(*>  Module name:       REC25.PAS                                           <*)
(*>  Module purpose:    Structures for data files                           <*)
(*>                                                                         <*)
(*****************************************************************************)

CONST
  ver:string[30]='.13';

  maxboards=254;      { 1 - x }
  maxuboards=143;     { 0 - x }
  maxprotocols=120;   { 0 - x }
  maxevents=10;       { 0 - x }   { #0 is Nightly Events (if active) }
  maxarcs=8;          { 1 - x }
  maxubatchfiles=20;
  numvoteqs=20;
  numvoteas=9;
  maxmenucmds=50;

TYPE
  astr    =string[160];

  acstring=string[20];            { Access Condition String }
  acrq    ='@'..'Z';              { AR flags }

  uflags =
   (rlogon,                       { L - Restricted to one call a day }
    rchat,                        { C - Can't page the SysOp }
    rvalidate,                    { V - Posts marked unvalidated }
    rbackspace,                   { B - Can't do ^B/^N/etc in messages }
    ramsg,                        { A - Can't change the AutoMessage }
    rpostan,                      { * - Can't post anonymously }
    rpost,                        { P - Can't post at all }
    remail,                       { E - Can't send any e-mail }
    rvoting,                      { K - Can't vote }
    rmsg,                         { M - Force e-mail deletion }
    spcsr,                        { }
    onekey,                       { onekey input mode }
    avatar,                       { user has AVATAR }
    pause,                        { pause }
    novice,                       { user is at novice help level }
    ansi,                         { user has ANSI }
    color,                        { user has color }
    alert,                        { alert SysOp when user logs on }
    smw,                          { short-message waiting for user }
    nomail,                       { user mail-box is closed }
    fnodlratio,                   { 1 - No UL/DL ratio }
    fnopostratio,                 { 2 - No post/call ratio }
    fnofilepts,                   { 3 - No file points checking }
    fnodeletion);                 { 4 - Protection from deletion }

  anontyp =
   (atno,                         { No anonymous posts allowed }
    atyes,                        { Anonymous posts are allowed }
    atforced,                     { ALL posts are forced anonymous }
    atdearabby,                   { "Dear Abby" message base }
    atanyname);                   { User's can post as ANY name they want }

  clrs = array[FALSE..TRUE,0..9] of byte; { color records }
  secrange= array[0..255] of integer; { security tables }

  cpackdatetime=array[1..6] of byte;

  mzscanr = set of 1..maxboards;
  fzscanr = set of 0..maxuboards;
  mhireadr= array[1..maxboards] of cpackdatetime;

  dlnscan =set of 0..96;

  smalrec=                            { NAMES.LST : Sorted names listing }
  record
    name:string[36];                  { user name }
    number:integer;                   { user number }
  end;

  userrec=                            { USER.LST : User account records }
  record
    name:string[36];                  { user name        }
    realname:string[36];              { real name        }
    pw:string[20];                    { user password    }
    ph:string[12];                    { user phone #     }
    {rcg11272000 Y2K limitations.}
    (*bday:string[8];                   { user birthdate   }*)
    (*firston:string[8];                { firston date     }*)
    (*laston:string[8];                 { laston date      }*)
    bday:string[10];                   { user birthdate   }
    firston:string[10];                { firston date     }
    x1xs  :array[1..2] of byte;
    laston:string[10];                 { laston date      }
    x2xs  :array[1..2] of byte;
    street:string[30];                { mailing address  }
    citystate:string[30];             { city, state      }
    zipcode:string[10];               { zipcode          }
    computer:string[30];              { type of computer }
    occupation:string[40];            { occupation       }
    wherebbs:string[40];              { BBS reference    }
    note:string[39];                  { SysOp note       }

    lockedout:boolean;                { if locked out    }
    deleted:boolean;                  { if deleted       }
    lockedfile:string[8];             { lockout msg to print }

    ac:set of uflags;                 { user flags   }
    ar:set of acrq;                   { AR flags     }

    zzqscan:array[1..64] of word;     { last read msg pointers }
    xqxxx:array[1..64] of word;
    zzqscn:array[1..64] of boolean;   { scan boards flags  }
    zzdlnscn:dlnscan;                 { scan uboards flags }

    vote:array[1..20] of byte;        { voting data  }

    sex:char;                         { user sex }

    ttimeon:longint;                  { total mins spent on  }
    x1xx:integer;
    uk:longint;                       { UL k                 }
    x2xx:integer;
    dk:longint;                       { DL k                 }
    x3xx:integer;

    uploads,downloads,                { # of ULs / # of DLs  }
    loggedon,                         { # times logged on    }
    tltoday,                          { # min left today     }
    msgpost,                          { # public posts       }
    emailsent,                        { # email sent         }
    feedback,                         { # feedback sent      }
    forusr,                           { forward mail to user # }
    filepoints:integer;               { # of file points     }

    waiting,                          { mail waiting         }
    linelen,                          { line length (# cols) }
    pagelen,                          { page length (# rows) }
    ontoday,                          { # times on today     }
    illegal,                          { # illegal logon attempts }
    sl,dsl:byte;                      { SL / DSL }

    cols:clrs;                        { user colors }

    lastmsg,lastfil:byte;             { last msg/file areas   }
    credit:longint;                   { $$$ credit in dollars }
    x4xx:integer;
    timebank:integer;                 { # mins in Time Bank   }
    boardsysop:array[1..5] of byte;   { msg board SysOp       }

    trapactivity,                     { if trapping users activity }
    trapseperate:boolean;             { if trap to seperate TRAP file }

    timebankadd:integer;              { time added to timebank TODAY }
    mpointer:longint;                 { pointer to entry in MACRO.LST }
    chatauto,                         { if auto chat trapping }
    chatseperate:boolean;             { if seperate chat file to trap to }
    userstartmenu:string[8];          { menu to start user out on }
    slogseperate:boolean;             { seperate SysOp log? }
    clsmsg:byte;                      { 1 if clear-screen msg, 2 if not }

{ NEW STUFF }

    flistopt:byte;                    { type of file list type to use }
    msgorder:byte;                    { 0:Chrono, 1:ReplyTree }
    avadjust:byte;                    { AVATAR color adjust: 1=no, 2=yes }

{ NEW STUFF *ENDS* }

    res:array[1..54] of byte;         { RESERVED }
  end;

  zscanrec=                       { ZSCAN.DAT : NewScan recs (file/msg) }
  record                          { ** b0..b3 }
    mhiread:mhireadr;             { NewScan high message pointers }
    mzscan:mzscanr;               { NewScan message bases }
    fzscan:fzscanr;               { NewScan file bases }
  end;

  msgindexstatr=
   (miexist,                      { does message actually exist? }
    miencrypted,                  { is it encrypted? }
    miunvalidated,                { is message unvalidated? }
    mipermanent,                  { is the message permanent? }
    miallowmci,                   { DID owner have access to MCI? }
    mithreads,                    { is message referenced? (threaded) }
    mimassmail,                   { is it private, mass mail? }
    miscanned);                   { is message scanned for FidoNet? }

    {rcg11182000 spliced from V20 headers...}
  msgindexrec=                         { *.MIX : Message index records }
  record
    messagenum:word;                   { message number, tonum in EMAIL.MIX }
    hdrptr:longint;                    { pointer to message header }
    msgid:longint;                     { message ID (sequential) }
    isreplytoid:longint;               { ID of replied message }
    msgdate:cpackdatetime;             { message date/time (packed) }
    msgdowk:byte;                      { message day-of-week (0=Sun ...) }
    msgindexstat:set of msgindexstatr; { status flags }
    lastdate:array[1..6] of byte;     { update: date/time }
    lastdowk:byte;                    { update: day-of-week }
    isreplyto:word;                    { reply this message is to (-1=None) }
    numreplys:word;                    { number of replies to THIS message }
  end;

  fromtoinfo=                  { from/to information for mheaderrec }
  record
    anon:byte;                 { anonymous type }
    usernum:word;              { user number }
    as:string[42];             { given name for this case }
    real:string[36];           { user real name }
    alias:string[36];          { user alias }
  end;

  {rcg11182000 cannibalized from the v20 type...}
  mheaderrec=                  { *.BRD : Message header records }
  record
    signature:longint;         { header signature - $FFFFFFFF }
    msgptr:longint;            { pointer to message text }
    isreplyto_iddate:array[1..6] of byte; { isreplyto id date - for NetMail }
    isreplyto_idrand:word;            { isreplyto id randomid }
    msglength:longint;         { length of message text }
    fromi:fromtoinfo;          { from information }
    toi:fromtoinfo;            { to information }
    title:string[60];          { title of message }
    origindate:string[19];     { Echo/Group original msg date }
    originsite:string[60];            { site of *original* origin }
  end;

  zlogrec=                        { ZLOG.DAT : System log }
  record
    {rcg11272000 Y2K bullshite.}
    {date:string[8];}
    date:string[10];
    userbaud:array[0..4] of integer;
    active,calls,newusers,pubpost,privpost,fback,criterr:integer;
    uploads,downloads:integer;
    uk,dk:longint;
  end;

  filearcinforec=                 { Archive configuration records }
  record
    active:boolean;               { whether this archive format is active }
    ext:string[3];                { 3-chr file extension }
    listline,                     { /x for internal;
                                     x: 1=ZIP, 2=ARC/PAK, 3=ZOO, 4=LZH }
    arcline,                      { compression cmdline }
    unarcline,                    { de-compression cmdline }
    testline,                     { integrity test cmdline, '' for *None* }
    cmtline:string[25];           { comment cmdline, '' for *None* }
    succlevel:integer;            { success ERRORLEVEL, -1=ignore results }
  end;

  modemrec=
  record
    waitbaud:word;               { wait baud }
    comport:byte;                { comport number }
    init:string[80];             { initialization string }
    answer:string[40];           { answer string }
    hangup:string[40];           { hangup string }
    offhook:string[40];          { phone off-hook string }
    nocallinittime:integer;      { reinit modem after x mins of inactivity }
    arq9600rate:word;            { baud rate to USE when 9600 ARQ result code }
    noforcerate:boolean;         { whether to force baud rate}
    nocarrier:integer;           { no carrier result code }
    nodialtone:integer;          { no dialtone result code }
    busy:integer;                { busy result code }
    resultcode:array[1..2,0..4] of integer; { **-Result codes-** }
    ctschecking,
    dsrchecking,
    usexonxoff,
    hardwired:boolean;
  end;

  fstringrec=
  record
    ansiq:string[80];                 { "Do you want ANSI? " string }
    note:array[1..2] of string[80];   { Logon notes (L #1-2) }
    lprompt:string[80];               { Logon prompt (L #3) }
    echoc:char;                       { Echo char for PWs }
    sysopin,                          { "SysOp In" (inside SysOp hours)}
    sysopout,                         { "SysOp Out" }
    engage,                           { "Engage Chat" }
    endchat,                          { "End Chat" }
    wait,                             { "SysOp Working" }
    pause,                            { "Pause" }
    entermsg1,                        { "Enter Message" line #1 }
    entermsg2,                        { "Enter Message" line #2 }
    newscan1,                         { "NewScan begin" }
    newscan2,                         { "NewScan done" }
    scanmessage,                      { Message scanning prompt }
    automsgt:string[80];              { Auto-Message title }
    autom:char;                       { Auto-Message border characters }

    shelldos1,                        { " >> SysOp shelling to DOS ..." }
    shelldos2,                        { " ... thank you for waiting." }
    chatcall1,                        { "Paging SysOp, please wait..." }
    chatcall2,                        { ">>><*><<<" }
    guestline,                        { "To be a guest ... " }
    namenotfound,                     { "Name NOT found in user list." }
    bulletinline,                     { Bulletin line }
    thanxvote,                        { "Thanks for voting" }

    listline,                         { "List files - P to pause" }
    newline,                          { "Search for new files -" }
    searchline,                       { "Search all dirs for file mask" }
    findline1,                        { "Search for descriptions... " }
    findline2,                        { "Enter the string to search for.." }
    downloadline,                     { "Download - " }
    uploadline,                       { "Upload - " }
    viewline,                         { "View interior files - " }
    nofilepts,                        { "Insufficient file points." }
    unbalance,                        { "Your UL/DL ratio is unbalanced" }

    pninfo,                           { "P to Pause, N for next dir" }
    gfnline1,                         { "[Enter]=All files" }
    gfnline2,                         { "File mask: " }
    batchadd:string[80];              { "File added to batch queue." }
  end;

  systatrec=
  record
    gfilepath:string[79];             { GFILES path }
    afilepath:string[79];             { AFILES path (text files path) }
    menupath:string[79];              { MENUS path  }
    trappath:string[79];              { LOG path (traps, chats, SysOp logs) }
    msgpath:string[79];               { MSG path (priv/pub mail path) }
    tfilepath:string[79];             { TFILES path }
    temppath:string[79];              { TEMP path - "temp" directory }

    bbsname:string[80];               { BBS name }
    bbsphone:string[12];              { BBS phone number }
    sysopname:string[30];             { SysOp's full name or alias }
    maxusers,                         { max number of users system can have }
    lowtime,                          { SysOp begin minute (in minutes) }
    hitime,                           { SysOp end time }
    dllowtime,                        { normal downloading hours begin.. }
    dlhitime:integer;                 { ..and end }
    shuttlelog,                       { is Shuttle Logon active? }
    lock300:boolean;                  { lock out 300 baud? }
    sysoppw,                          { SysOp PW }
    newuserpw,                        { newuser PW (or NULL if none) }
    shuttlepw:string[20];             { Shuttle PW (if Shuttle active) }
    b300lowtime,                      { 300 baud calling hours begin.. }
    b300hitime,                       { ..and end }
    b300dllowtime,                    { 300 baud downloading hours begin.. }
    b300dlhitime:integer;             { ..and end }
    closedsystem:boolean;             { DON'T allow new users? }
    swapshell:boolean;                { is swap shell function enabled? }
    eventwarningtime:integer;         { time before event warning }
    {rcg11272000 y2k stuff.}
    (*tfiledate:string[8];              { last date text-files were inserted }*)
    tfiledate:string[10];             { last date text-files were inserted }
    lastmsgid:longint;                { last-used message ID (sequential) }
    res1:array[1..20] of byte;        { RESERVED SPACE #1 }

    sop,                              { SysOp }
    csop,                             { Co-SysOp }
    msop,                             { Message SysOp }
    fsop,                             { File SysOp }
    spw,                              { SysOp PW at logon }
    seepw,                            { see SysOp PWs remotely  }
    normpubpost,                      { make normal public posts }
    normprivpost,                     { send normal e-mail }
    anonpubread,                      { see who posted public anon }
    anonprivread,                     { see who sent anon e-mail }
    anonpubpost,                      { make anon posts }
    anonprivpost,                     { send anon e-mail }
    seeunval,                         { see unvalidated files }
    dlunval,                          { DL unvalidated files }
    nodlratio,                        { no UL/DL ratio }
    nopostratio,                      { no post/call ratio }
    nofilepts,                        { no file points checking }
    ulvalreq:acstring;                { uploads require validation by SysOp }
    res2:array[1..100] of byte;       { RESERVED SPACE #2 }

    maxprivpost,                      { max e-mail can send per call }
    maxfback,                         { max feedback per call }
    maxpubpost,                       { max posts per call }
    maxchat,                          { max chat-pages per call }
    maxwaiting,                       { max mail in mail-box }
    csmaxwaiting,                     { max mail in mail-box for Co-SysOp + }
    maxlines,                         { max lines in message }
    csmaxlines,                       { max lines in message for Co-SysOp + }
    maxlogontries,                    { tries allowed for PW's at logon }
    bsdelay,                          { backspacing delay }
    sysopcolor,                       { SysOp color in chat mode }
    usercolor:byte;                   { user color in chat mode }
    minspaceforpost,                  { minimum K drive space left to post }
    minspaceforupload:integer;        { minimum K drive space left to upload }
    backsysoplogs,                    { days to keep SYSOP##.LOG }
    wfcblanktime:byte;                { minutes after which to blank WFC menu }
    linelen,                          { default video line length }
    pagelen:byte;                     { default video page length }
    res3:array[1..18] of byte;        { RESERVED SPACE #3 }

    specialfx,                        { WFC menu "special effects" }
    fossil,                           { make use of FOSSIL comm driver }
    allowalias,                       { allow alias's? (handles) }
    phonepw,                          { use phone number password in logon? }
    localsec,                         { is local security ON? }
    localscreensec,                   { is local screen-security ON? }
    globaltrap,                       { trap ALL USER'S activity? }
    autochatopen,                     { does chat buffer auto-open? }
    autominlogon,                     { Auto-Message in logon? }
    bullinlogon,                      { bulletins in logon? }
    lcallinlogon,                     { "Last Few Callers" list in logon? }
    yourinfoinlogon,                  { "Your Info" in logon? }
    multitask,                        { is BBS multitasking? }
    offhooklocallogon,                { take phone off-hook for local logons? }
    forcevoting,                      { is manditory logon voting active? }
    compressbases,                    { "compress" file/message base numbers? }
    searchdup:boolean;                { search for dup. filenames when UL? }
    slogtype:byte;                    { SysOp log type: File/Printer/Both }
    stripclog:boolean;                { strip colors from SysOp log output? }
    newapp,                           { user# to send new user application to }
    guestuser,                        { user# of guest user account }
    timeoutbell,                      { minutes before time-out bell }
    timeout:integer;                  { minutes before timeout (logoff) }
    usewfclogo:boolean;               { whether to use WFC menu logo }
    useems:boolean;                   { attempt to use EMS for overlay }
    usebios:boolean;                  { use ROM BIOS for local video output }
    cgasnow:boolean;                  { suppress snow on CGA systems }
    res4:array[1..16] of byte;        { RESERVED SPACE #4 }

    filearcinfo:array[1..maxarcs] of filearcinforec; { archive specs }
    filearccomment:array[1..3] of string[80]; { BBS comments for archives }
    uldlratio,                        { are UL/DL ratios active? }
    fileptratio:boolean;              { is auto file-pt compensation active? }
    fileptcomp,                       { file point compensation ratio }
    fileptcompbasesize,               { file point "base compensation size" }
    ulrefund,                         { percent time refund for ULs }
    tosysopdir:byte;                  { "To SysOp" file base }
    validateallfiles:boolean;         { validate ALL FILES automatically? }
    remdevice:string[10];             { remote output device (GATEx,COMx,etc) }
    maxintemp,                        { max K allowed in TEMP\3\ }
    minresume:integer;                { min K to allow resume-later }
    maxdbatch,                        { max files in DL batch queue }
    maxubatch:byte;                   { max files in UL batch queue }
    res5:array[1..30] of byte;        { RESERVED SPACE #5 }

    newsl,                            { newuser SL }
    newdsl:byte;                      { newuser DSL }
    newar:set of acrq;                { newuser AR }
    newac:set of uflags;              { newuser AC }
    newfp:integer;                    { newuser file points }
    autosl,                           { auto-validation SL }
    autodsl:byte;                     { auto-validation DSL }
    autoar:set of acrq;               { auto-validation AR }
    autoac:set of uflags;             { auto-validation AC }

    allstartmenu:string[8];           { logon menu to start ALL users on }
    chatcfilter1,                     { SysOp chat color-filter }
    chatcfilter2:string[12];          { user chat color-filter }
    bulletprefix:string[8];           { default bulletins filename prefix }
    res6:array[1..15] of byte;        { RESERVED SPACE #6 }

    timeallow,                        { time allowance }
    callallow,                        { call allowance }
    dlratio,                          { # ULs/# DLs ratios }
    dlkratio,                         { DLk/ULk ratios }
    postratio:secrange;               { post/call ratios }

    {rcg11272000 y2k stuff.}
    (*lastdate:string[8];               { last system date }*)
    lastdate:string[10];              { last system date }
    curwindow:byte;                   { type of SysOp window currently in use }
    istopwindow:boolean;              { is SysOp window on top of screen? }
    callernum:longint;                { total number of callers }
    numusers:integer;                 { number of users }

    todayzlog:zlogrec;                { TODAY's ZLOG record }

    postcredits:integer; {file points/upload credit compensation for posts}
    rebootforevent:boolean;           { reboot before events? }
    watchdogdoor:boolean;             { Telegard WatchDog active in doors? }

    windowon:boolean;

    swappath:string[79];              { swap shell path }
    res:array[1..119] of byte;        {((((((>>> RESERVED <<<))))))}
  end;

  tbflags=
   (tbunhidden,                   { whether *VISIBLE* to users w/o access }
    tbnetlink,                    { whether Net-Linked to other Telegards }
    tbisdir);                     { if a text-file base directory }

  tfilerec=                       { GFILES.DAT : Text-file records }
  record
    title:string[40];             { title }
    filen:string[12];             { filename }
    {rcg11272000 Y2K shit.}
    (*gdate:string[8];              { date of Tfile / Tfile base }*)
    gdate:string[10];             { date of Tfile / Tfile base }
    gdaten:integer;               { numeric date for fast calculation }
    acs,                          { access requirement }
    ulacs:acstring;               { upload to base access requirement }
    tbstat:set of tbflags;        { text-file base status vars }
    permindx:longint;             { permanent index # }
  tbdepth:integer;                { tfile base dir depth }
    res:array[1..4] of byte;      { RESERVED }
  end;

  smr=                            { SHORTMSG.DAT : One-line messages }
  record
    msg:astr;
    destin:integer;
  end;

  vdatar=                         { VOTING.DAT : Voting records }
  record
    question:string[79];          { voting question }
    numa:integer;                 { number of user's who have answered }
    answ:array[0..numvoteas] of
    record
      ans:string[40];             { answer description }
      numres:integer;             { # user's who picked this answer }
    end;
  end;

  mbflags=
   (mbunhidden,                   { whether *VISIBLE* to users w/o access }
    mbrealname,                   { whether real names are forced }
    mbisdir,                      { if a message base directory }
    mbmsgpath,                    { if *.BRD file stored in MSGPATH }
    mbfilter,                     { whether to filter ANSI/8-bit ASCII }
    mbskludge,                    { strip IFNA kludge lines }
    mbsseenby,                    { strip SEEN-BY lines }
    mbsorigin,                    { strip origin lines }
    mbscenter,                    { strip centering codes }
    mbsbox,                       { strip box codes }
    mbmcenter,                    { center boxed/centered lines }
    mbaddtear,                    { add tear/origin lines }
    mbtopstar);                   { whether Top Star for GroupMail base }

  boardrec=                       { BOARDS.DAT : Message base records }
  record
    name:string[40];              { message base description }
    filename:string[8];           { BRD/MIX/TRE data filename }
    lastmsgid:longint;            { last message ID number }
    msgpath:string[40];           { messages pathname   }
    acs,                          { access requirement }
    postacs,                      { post access requirement }
    mciacs:acstring;              { MCI usage requirement }
    maxmsgs:word;                 { max message count }
    anonymous:anontyp;            { anonymous type }
    password:string[20];          { base password }
    mbstat:set of mbflags;        { message base status vars }
    permindx:longint;             { permanent index # }
    mbtype:integer;               { base type (0=Local,1=Echo,2=Group) }
    origin:string[50];            { origin line }
    text_color,                   { color of standard text }
    quote_color,                  { color of quoted text }
    tear_color,                   { color of tear line }
    origin_color:byte;            { color of origin line }
    zone,                         { alternate address     }
    net,                          { (zone:net/node.point) }
    node,
    point:integer;
    res:array[1..3] of byte;      { RESERVED }
  end;

  fbflags=
   (fbnoratio,                    { if <No Ratio> active }
    fbunhidden,                   { whether *VISIBLE* to users w/o access }
    fbdirdlpath,                  { if *.DIR file stored in DLPATH }
    fbisdir,                      { if a file base directory }
    fbusegifspecs,                { whether to use GifSpecs }
    fbnetlink);                   { whether Net-Linked to other Telegards }

  ulrec=                          { UPLOADS.DAT : File base records }
  record
    name:string[40];              { area description  }
    filename:string[12];          { filename + ".DIR" }
    dlpath,                       { download path     }
    ulpath:string[40];            { upload path       }
    maxfiles:integer;             { max files allowed }
    password:string[20];          { password required }
    arctype,                      { wanted archive type (1..max,0=inactive) }
    cmttype:byte;                 { wanted comment type (1..3,0=inactive) }
    fbdepth:integer;              { file base dir depth }
    fbstat:set of fbflags;        { file base status vars }
    acs,                          { access requirements }
    ulacs,                        { upload requirements }
    nameacs:acstring;             { see-names requirements }
    permindx:longint;             { permanent index # }
    res:array[1..6] of byte;      { RESERVED }
  end;

  filstat=
   (notval,                       { if file is NOT validated }
    isrequest,                    { if file is REQUEST }
    resumelater);                 { if file is RESUME-LATER }

  ulfrec=                         { *.DIR : File records }
  record
    filename:string[12];          { Filename }
    description:string[60];       { File description }
    filepoints:integer;           { File points }
    nacc:integer;                 { Number DLs }
    ft:byte;                      { File type (useless?) }
    blocks:integer;               { # 128 byte blks }
    owner:integer;                { ULer of file }
    stowner:string[36];           { ULer's name }
    {rcg11272000 y2k stuff.}
    (*date:string[8];               { Date ULed }*)
    date:string[8];               { Date ULed }
    daten:integer;                { Numeric date ULed }
    vpointer:longint;             { Pointer to verbose descr, -1 if none }
    filestat:set of filstat;      { File status }
    res:array[1..10] of byte;     { RESERVED }
  end;

  verbrec=                        { VERBOSE.DAT : Verbose descriptions }
  record
    descr:array[1..4] of string[50];
  end;

  lcallers=                       { LASTON.DAT : Last few callers records }
  record
    callernum:integer;            { system caller number }
    name:string[36];              { user name of caller }
    number:integer;               { user number of caller }
    citystate:string[30];         { city/state of caller }
    datet:string[9]              { time of last caller}
  end;

  eventrec=                       { EVENTS.DAT : Event records }
  record
    active:boolean;               { whether active }
    description:string[30];       { event description (for logs) }
    etype:char;                   { A:CS, C:hat, D:os call, E:xternal }
    execdata:string[20];          { errorlevel if "E", commandline if "D" }
    busytime:integer;             { off-hook time before; 0 if none }
    exectime:integer;             { time of execution }
    busyduring:boolean;           { busy phone DURING event? }
    duration:integer;             { length of time event takes }
    execdays:byte;                { bitwise execution days or day of month if monthly }
    monthly:boolean;              { monthly event? }
  end;

  macrorec=                       { MACROS.LST : Macro records }
  record
    macro:array[1..4] of string[240];
  end;

  mnuflags=
   (clrscrbefore,                 { C: clear screen before menu display }
    dontcenter,                   { D: don't center the menu titles! }
    nomenuprompt,                 { N: no menu prompt whatsoever? }
    forcepause,                   { P: force a pause before menu display? }
    autotime);                    { T: is time displayed automatically? }

  menurec=                        { *.MNU : Menu records }
  record
    menuname:array[1..3] of string[100]; { menu name }
    directive,                           { help file displayed }
    tutorial:string[12];                 { tutorial help file }
    menuprompt:string[120];              { menu prompt }
    acs:acstring;                        { access requirements }
    password:string[15];                 { password required }
    fallback:string[8];                  { fallback menu }
    forcehelplevel:byte;                 { forced help level for menu }
    gencols:byte;                        { generic menus: # of columns }
    gcol:array[1..3] of byte;            { generic menus: colors }
    menuflags:set of mnuflags;           { menu status variables }
  end;

  cmdflags=
   (hidden,                       { H: is command ALWAYS hidden? }
    unhidden);                    { U: is command ALWAYS visible? }

  commandrec=                       { *.MNU : Command records }
  record
    ldesc:string[70];               { long command description }
    sdesc:string[35];               { short command description }
    ckeys:string[14];               { command-execution keys }
    acs:acstring;                   { access requirements }
    cmdkeys:string[2];              { command keys: type of command }
    mstring:string[50];             { MString: command data }
    commandflags:set of cmdflags;   { command status variables }
  end;

  xbflags=
   (xbactive,
    xbisbatch,
    xbisresume,
    xbxferokcode);

  protrec=
  record
    xbstat:set of xbflags;                       { protocol flags }
    ckeys:string[14];                            { command keys }
    descr:string[40];                            { description }
    acs:acstring;                                { access string }
    templog:string[25];                          { temp. log file }
    uloadlog,dloadlog:string[25];                { permanent log files }
    ulcmd,dlcmd:string[78];                      { UL/DL commandlines }
    ulcode,dlcode:array [1..6] of string[6];     { UL/DL codes }
    envcmd:string[60];                        {B}{ environment setup cmd }
    dlflist:string[25];                       {B}{ DL file lists }
    maxchrs:integer;                             { max chrs in cmdline }
    logpf,logps:integer;                      {B}{ pos in log file for data }
    permindx:longint;                            { permanent index # }
    res:array[1..11] of byte;                    { RESERVED }
  end;

  datetimerec=
  record
    day,hour,min,sec:longint;
  end;

  cfilterrec=array[0..255] of byte;          { color filter record }

  fidorec=                          { FIDONET.DAT : FidoNet information }
  record
    zone:integer;                   { FidoNet zone number }
    net:integer;                    { FidoNet net number }
    node:integer;                   { FidoNet node number }
    point:integer;                  { FidoNet point number }
    origin:string[50];              { origin line }
    text_color:byte;                { color of standard text }
    quote_color:byte;               { color of quoted text }
    tear_color:byte;                { color of tear line }
    origin_color:byte;              { color of origin line }
    skludge:boolean;                { strip kludge lines? }
    sseenby:boolean;                { strip SEEN-BY lines? }
    sorigin:boolean;                { strip origin line? }
    scenter:boolean;                { strip TG centering codes? }
    sbox:boolean;                   { strip TG box codes? }
    mcenter:boolean;                { center boxed/centered lines? }
    addtear:boolean;                { add tear/origin lines? }
    res:array[1..1978] of byte;     { RESERVED }
  end;

  {rcg11182000 added by me.}
  V20_mtreerec=                       { *.TRE : Message reply-tree records }
  record
    messagerunning,                   { message number, running }
    messagenum:word;                  { actual message number in *.MIX }
    ilevel:byte;                      { indent level - for replys }
    isreplyto,                        { reply this message is to (-1=None) }
    numreplys:word;                   { number of replys to THIS message }
    msgdate:array[1..6] of byte;      { message id date }
    msgdowk:byte;                     { message day-of-week }
  end;

  mtreerec        = V20_mtreerec;           { *.TRE }
  {rcg11182000 end adds.}

