{
T.A.G. (C) Copyrighted 1986-1989 by Robert Numerick and Victor Capton
All rights reserved.

                   -----------------------------------
                   T.A.G. Version 2.4d Data Structures
                   -----------------------------------

All we ask if you use these records is to give credit where credit is due.

Additional structure information may be given out on an individual basis
depending on the situation.

Program: STRCT24D.PAS
}

type

  acrq='@'..'Z'; {AR flags}

                          {Special flag meanings when present}
  flagrec=(autoprivdel,   {A=Force user to delete private mail}
           nopostcall,    {B=No post call ratio}
           rautomsg,      {C=Restrict from posting auto-message}
           ranon,         {D=Restrict from posting anonymous}
           rbbslist,      {E=Restrict from adding to other BBS list}
           rchat,         {F=Restrict from chatting}
           nodllimit,     {G=No download ratio limit}
           rpubmsg,       {H=Restrict from posting public mail}
           rprivmsg,      {I=Restrict from sending private mail}
           rvoting,       {J=Restrict from voting}
           onecall,       {K=One call per day allowed}
           pubnotval,     {L=Public posts not validated}
           protdel,       {M=Protect from deletion}
           nofilepts,     {N=No file points checks}
           wordwrap,      {O=Word wrap in messages enabled}
           pause,         {P=[PAUSE] active}
           ansi,          {Q=ANSI graphics active}
           color,         {R=Color active if ANSI present}
           onekey,        {S=Onekey input used instead of line input}
           alert,         {R=Alert active for user's next call}
           usermale,      {S=User is of the male gender}
           mboxclosed,    {T=Mail box closed to all by SysOp's}
           tabs,          {U=VT100 tabs are used to optimize display}
           clschar);      {V=Clear screen characters used}
           {3 bytes used for 24 flags}


  flagset=set of flagrec; {Set of the above user flags}

  msgscanrec=set of 0..55; {Set of message section scan flags}

  filescanrec=set of 0..95; {Set of file section scan flags}

  colorrec=array[false..true,0..9] of byte; {Array of colors
                                               false=Black and white monitor
                                               true =Color monitor}

  umsgsrec=record   {Last message read pointer (e.g. A-28432)}
    ltr:char;       {Letter of last message read (e.g. "A")}
    number:integer; {Number of last message read (e.g. -28432)}
  end;

  userrec=record                      {User log record (user.lst)}
    uname,                            {User name}
    rname:string[36];                 {Real name}
    addr,                             {Address}
    comtype,                          {Computer type}
    citystate,                        {City/State}
    snote:string[30];                 {SysOp note}
    lastdate,                         {Last date on (MS-DOS compressed)}
    lasttime:integer;                 {Last time on (MS-DOS compressed)}
    pw:string[16];                    {Password}
    phone:string[12];                 {Phone number}
    zcode:string[10];                 {Zip code}
    qscan:array[0..55] of umsgsrec;   {Last read pointers for each msg section}
    vote:array[1..20] of byte;        {User's vote on each question}
    callspr:array[1..15] of byte;     {Call spread of last 15 calls}
    ttimeon,                          {Total time on system in minutes}
      ulk,                            {UL K-bytes}
      dlk:real;                       {DL K-bytes}
    usernum,                          {User's number 0=deleted
                                                     same as rec=normal
                                                     diff than rec=locked out}
      privpost,                       {Private posts}
      pubpost,                        {Public posts}
      feedback,                       {Feedback to sysop}
      numcalls,                       {Total number of calls}
      numul,                          {Number of downloads}
      numdl,                          {Number of uploads}
      fmail,                          {Forward mail to what user number}
      hbaud,                          {Highest baud rate user supports}
      timetoday,                      {Minutes user on day of last call}
      credit,                         {Credit in cents}
      debit,                          {Money spent sending mail in cents}
      points,                         {File points}
      timebank,                       {Minutes in time bank}
      bday,                           {Birthday of user (MS-DOS compressed)}
      uuui:integer;                   {Reserved}
    uuub1,                            {Reserved}
      uuub2,                          {Reserved}
      strtmenu,                       {Starting menu (not supported)}
      sl,                             {Security level (SL)}
      dsl,                            {Download security level (DSL)}
      hlvl,                           {Help level}
      colms,                          {Number columns on screen}
      lines,                          {Number lines on screen}
      callstoday,                     {Calls user made on day of last call}
      illegal,                        {Illegal logons since last on}
      waiting,                        {Number private messages waiting}
      lmsgbase,                       {Last message base user in}
      ldlbase,                        {Last file section user in}
      cls,                            {CLS character (not supported)}
      nulls:byte;                     {Number of nulls (not supported)}
    ar:set of acrq;                   {Set of AR flags}
    flags:flagset;                    {Special flags}
    msgsysop:array[1..4] of byte;     {Boards user is SubOp of (255=none)}
    msgscan:msgscanrec;               {Message areas to scan}
    dlscan:filescanrec;               {File sections to scan}
    colors:colorrec;                  {Programmed colors for user}
  end;

  dayrec=(Sun,Mon,Tue,Wed,Thu,Fri,Sat); {Days of week for events}

  eventrec=record           {Event record}
    offhook:boolean;        {Take phone off hook during event}
    elevel,                 {Error level to drop at}
      day:byte;             {Day of month event active (if zero weekly)}
    schtype:char;           {Schedule type}
                            {bit 7=1 if disabled}
    general,                {General variable (not used yet)}
      start,                {Starting time of event (# minutes from 00:00}
      duration,             {Minutes the event lasts}
      timebefore:integer;   {Time before event to disallow users}
    days:set of dayrec;     {Days of week event is active}
  end;

  messages=record   {Message filename record (e.g. A-32767.1)}
    ltr:char;       {Letter of message (e.g. "A")}
    number:integer; {Number of message (e.g. -32767)}
    ext:byte;       {Extension of message (e.g. 1)}
  end;

  range=array[0..255] of integer; {Range values for all security levels}

  systatrec=record                         {System status record (status.dat)}
    altpath,                               {Alternate file directory}
      msgspath:string[40];                 {Message text file directory}
    uusr:array[1..26] of byte;             {Reserved space}
    modemresultnocarrier:string[14];       {Modem NO CARRIER string}
    modemanswer:string[20];                {Modem answer string}
    modemresultring:string[14];            {Modem RING string}
    minkpost,                              {Minimum K-bytes to post}
      minkul:integer;                      {Minimum K-bytes to upload}
    autochatbufopen:boolean;               {Chat buffer auto opens when chat}
    modemoffhook:string[20];               {Modem off hook string}
    modemresultok:string[14];              {Modem OK string}
    logonpassword,                         {SL when SysOp PW#1 needed to logon}
      readtextmsg:byte;                    {SL when can /read in message}
    alertchatonly,                         {ALERT active only when chat on}
      genericinfo,                         {Generic mode active}
      logonphone:boolean;                  {Logon requires phone number}
    modeminit:string[54];                  {Modem initialization string}
    lastcaller:string[42];                 {Last caller on the system was...}
    modemhangup:string[20];                {Modem hang-up string}
    boardpw:string[16];                    {New user password}
    boardphone:string[12];                 {Phone number of the system}
    sysopcolor,                            {SysOp color in chat}
      usercolor:byte;                      {User color in chat}
    postcallflag:acrq;                     {AR flag used for post call ratio}
    nopostcallchk,                         {SL where no post call check made}
      reinittime,                          {Mins of no activity to init modem}
      startmenu:byte;                      {Starting menu for users}
    useautomsg,                            {Logon users auto-message}
      logonoffhook:boolean;                {Local logon takes phone off hook}
    nopointchk:byte;                       {DSL where no file point check made}
    lastdate:string[8];                    {Date last user logged on}
    event:array[1..34] of eventrec;        {Array of events}
    gfilespath:string[40];                 {Main data files directory}
    storebadlogon:boolean;                 {Store bad logon information}
    maxbdnum,                              {Max number of files in DL queue}
      maxbunum:byte;                       {Max number of files in UL queue}
    boardname:string[50];                  {System name}
    sysopname:string[36];                  {SysOp name}
    uubytes:array[1..124] of byte;         {Reserved space}
    ksm:array[1..9] of string[255];        {Internal use structure}
    sysoppw:array[1..3] of string[16];     {SysOp passwords}
    modemresult:array[1..8] of string[14]; {Result codes for each baud rate
                                            1,2:300 baud
                                            3,4:1200 baud
                                            5,6:2400 baud
                                            7,8:9600 baud}
    callernum,                             {Total calls to the system}
      ulktoday,                            {UL K-bytes today}
      dlktoday,                            {DL K-bytes today}
      uur1,                                {Reserved space}
      uur2,                                {Reserved space}
      uur3:real;                           {Reserved space}
    users,                                 {Number of active users}
      activetoday,                         {Minutes system is active today}
      callstoday,                          {Number of calls today}
      msgposttoday,                        {Number of public posts today}
      emailtoday,                          {Number of private posts today}
      fbacktoday,                          {Number of feedback's posted today}
      ultoday,                             {Number of uploads today}
      waitbaud,                            {Baud rate for modem initialization}
      lowtime,                             {Mins into day start of SysOp hours}
      hitime,                              {Mins into day end of SysOp hours}
      maxusers,                            {Maximum users allow on the system}
      errorstoday,                         {Number of system errors today}
      nuserstoday,                         {Number of new users today}
      dltoday,                             {Number of downloads today}
      newusermsgto,                        {User new user message is sent to}
      uui8,                                {Reserved space}
      sysopmailto,                         {User mail to SYSOP is sent to}
      guestuser,                           {Guest user number}
      low300time,                          {Mins into day 300 baud hours start}
      uui7,                                {Reserved space}
      usagelogdays,                        {Number of days usage log stores}
      hi300time,                           {Mins into day 300 baud hours end}
      uui0,                                {Reserved space}
      uui1,                                {Reserved space}
      uui2,                                {Reserved space}
      uui3,                                {Reserved space}
      uui4,                                {Reserved space}
      uui5,                                {Reserved space}
      uui6:integer;                        {Reserved space}
    sysoplvl,                              {SL of SysOp access}
      cosysoplvl,                          {SL of CoSysOp access}
      suboplvl,                            {SL of SubOp access}
      addbbslvl,                           {SL to add to the BBS list}
      emaillvl,                            {SL to send normal private mail}
      valsl,                               {Validation SL}
      valdsl,                              {Validation DSL}
      seeunvallvl,                         {DSL to see unvalidated files}
      dlcosysoplvl,                        {DSL of DL CoSysOp}
      noratiochk,                          {DSL for no ratio check}
      readanon,                            {SL to know who sent anon mail}
      replyanon,                           {SL to reply to anon mail}
      publicanonany,                       {SL to post anon on any msg base}
      privateanonany,                      {SL to send anon private mail}
      maxpubliccall,                       {Maximum public posts per call}
      maxprivcall,                         {Maximum private posts per call}
      maxfbackcall,                        {Maximum feedback per call}
      maxwaitso,                           {Maximum mail waiting SysOp}
      seepasswords,                        {SL to see passwords remotely}
      maxwaitcs,                           {Maximum mail waiting CoSysOp}
      maxwaitnorm,                         {Maximum mail waiting normal user}
      comport,                             {Com-port}
      timeout,                             {Minutes before no-activity timeout}
      timeoutbell,                         {Minutes before no-activity bell}
      backlogdays,                         {Number of back SYSOP.LOG days}
      privilagesl,                         {SL privilege level}
      privilagedsl,                        {DSL privilege level}
      cdmask,                              {Carrier detect mask}
      maxlogontries,                       {Maximum logon tries}
      numlines,                            {Maximum lines per msg normal user}
      csnumlines,                          {Maximum lines per msg CoSysOp}
      ultimepercent,                       {UL percent refund time}
      maxchats,                            {Maximum number of pages per call}
      readmsgview,                         {SL to view user while reading mail}
      readmsgval:byte;                     {SL to val user while reading mail}
    closedsystem,                          {System closed}
      titlepause,                          {Allow [PAUSE] on the title screen}
      logonbulletin,                       {Logon to bulletin section}
      blankwait,                           {Blank wait screen if no activity}
      handles,                             {Allow handles on the system}
      valclear,                            {Validation clears all restrictions}
      securesystem,                        {Keyboard security active}
      timeperday,                          {Time limits represent time per day}
      binkley,                             {Binkley Term active}
      sysopfemale,                         {SysOp of the system is female}
      unusedbool:boolean;                  {Reserved space}
    timeallowed,                           {SL array for time allowed on system}
      uldlnumratio,                        {DSL array for number of UL ratios}
      uldlkratio,                          {DSL array for K-byte UL ratios}
      callsallowed,                        {SL array of calls allowed per day}
      postcall:range;                      {SL array of post call ratios}
    hmsg:messages;                         {Main system high message pointer}
    valar:set of acrq;                     {Validation AR level set}
  end;

  anontyp=(no,yes,forced,atunused); {Anonymous status of a message section}

  boardrec=record        {Message section record (boards.dat)}
    name:string[45];     {Message base name}
                         {30 max real length, rest for color codes}
    filename:string[12]; {Header filename (don't believe it includes .BRD)}
    sl:byte;             {SL required to use base}
    maxmsgs:byte;        {Maximum messages allowed (must be 5-200)}
    pw:string[16];       {Password to enter base}
    anonymous:anontyp;   {Anonymous type of section}
    ar:acrq;             {AR flag required to use base}
    noansi:boolean;      {ANSI graphics allowed?}
    postsl:byte;         {SL required to post on the base}
  end;

  smr=record         {Small message record (shortmsg.dat)}
    msg:string[160]; {Text small message}
    destin:integer;  {User number who message is to}
  end;

  vdatar=record                {Voting data record (voting.dat)}
    question:string[74];       {Text of the question}
    numa:integer;              {Number of users who have answered the question}
    answ:array[0..9] of record {Answer data record array}
      ans:string[40];          {Test of the answer}
      numres:integer;          {Number user who choose this answer}
    end;
  end;

  ulrec=record             {File section record (fboards.dat)}
    name:string[39];       {Name of file section}
                           {26 max real length, rest is for color codes}
    filename:string[8];    {Filename of section listing (no .DIR)}
    dlpathname:string[30]; {Download pathname of section}
    ulpathname:string[30]; {Upload pathname of section}
    password:string[16];   {Password required to enter section}
    dsl,                   {DSL required to use section}
      seenames:byte;       {DSL required to see file owners}
    arlvl:acrq;            {AR flag required to enter section}
    noratio:boolean;       {Does this check charge for files}
  end;

  ulfrec=record             {File listing record (*.dir)}
    filename:string[12];    {Filename}
    description:string[78]; {Description}
    nacc:integer;           {Number of downloads for this file}
    ft:byte;                {File type (unused)}
    blocks:integer;         {Number of 128 byte blocks the file requires}
    owner:string[36];       {User who uploaded the file}
    date:string[8];         {Date the file was uploaded in MM/DD/YY format}
    daten:integer;          {Days since Jan 1, 1985 of upload date}
    flag:boolean;           {File unvalidated (true=yes)}
    points:byte;            {File points of the file}
  end;

  smalrec=record     {Small user pointer record (names.lst)}
    name:string[36]; {User name}
    number:integer;  {User number}
  end;

  macrorec=record                   {Macro record (macros.lst)}
    usern:integer;                  {User number who macro's belong}
    key:array[1..4] of string[160]; {Text of each macro}
  end;
