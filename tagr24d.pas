(*****************************************************************************)
(*                                                                           *)
(*                T.A.G. v2.4 record structure definition file               *)
(*                                                                           *)
(*                                                                           *)
(*                                                                           *)
(*  Presently includes definitions for USER.LST, FBOARDS.DAT, and *.DIR      *)
(*                                                                           *)
(*  Hacked out by Eric Oman 01/01/89-01/02/89                                *)
(*                                                                           *)
(*****************************************************************************)

const
  tag_ver:string[15]='2.4d';
  tag_maxboards=55;       { 0 - x }   { 39; }
  tag_maxuboards=95;      { 0 - x }   { 39; }
  tag_maxevents=10;       { 0 - x }   { #0 is Nightly Events (if active) }
  tag_numvoteqs=20;

type
  tag_acrq  = '@'..'Z';
  tag_flagrec=(txautoprivdel,   {A=Force user to delete private mail}
               txnopostcall,    {B=No post call ratio}
               txrautomsg,      {C=Restrict from posting auto-message}
               txranon,         {D=Restrict from posting anonymous}
               txrbbslist,      {E=Restrict from adding to other BBS list}
               txrchat,         {F=Restrict from chatting}
               txnodllimit,     {G=No download ratio limit}
               txrpubmsg,       {H=Restrict from posting public mail}
               txrprivmsg,      {I=Restrict from sending private mail}
               txrvoting,       {J=Restrict from voting}
               txonecall,       {K=One call per day allowed}
               txpubnotval,     {L=Public posts not validated}
               txprotdel,       {M=Protect from deletion}
               txnofilepts,     {N=No file points checks}
               txwordwrap,      {O=Word wrap in messages enabled}
               txpause,         {P=[PAUSE] active}
               txansi,          {Q=ANSI graphics active}
               txcolor,         {R=Color active if ANSI present}
               txonekey,        {S=Onekey input used instead of line input}
               txalert,         {T=Alert active for user's next call}
               txusermale,      {U=User is of the male gender}
               txmboxclosed,    {V=Mail box closed to all by SysOp's}
               txtabs,          {W=VT100 tabs are used to optimize display}
               txclschar);      {X=Clear screen characters used}
               {3 bytes used for 24 flags}

  tag_flagset=set of tag_flagrec; {Set of the above user flags}

  tag_msgscanrec=set of 0..tag_maxboards; {Set of message section scan flags}
  tag_filescanrec=set of 0..tag_maxuboards; {Set of file section scan flags}
  tag_colorrec=array[FALSE..TRUE,0..9] of byte; {Array of colors
                                                 false=Black and white monitor
                                                 true =Color monitor}

  tag_messages=
  record
    ltr:char;
    number:integer;
    ext:byte;
  end;

  umsgsrec=record   {Last message read pointer (e.g. A-28432)}
    ltr:char;       {Letter of last message read (e.g. "A")}
    number:integer; {Number of last message read (e.g. -28432)}
  end;

  tag_smalrec =
    record                          (******** "NAMES.LST" structure *******)
      name:string[36];
      number:integer;
    end;

  tag_userrec=
    record                          (******** "USER.LST" structure ********)
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
      ar:set of tag_acrq;               {Set of AR flags}
      flags:tag_flagset;                {Special flags}
      msgsysop:array[1..4] of byte;     {Boards user is SubOp of (255=none)}
      msgscan:tag_msgscanrec;           {Message areas to scan}
      dlscan:tag_filescanrec;           {File sections to scan}
      colors:tag_colorrec;              {Programmed colors for user}
    end;

  tag_ulrec =
    record                          (******* "FBOARDS.DAT" structure ******)
      name:string[39];                             (* base description    *)
      filename:string[8];                          (* *.DIR filename      *)
      dlpath:string[30];                           (* DL location         *)
      ulpath:string[30];                           (* ULs go here         *)
      password:string[16];                         (* password for access *)
      dsl:byte;                                    (* DSL req. for access *)
      namedsl:byte;                                (* see who ULed access *)
      ar:tag_acrq;                                 (* AR req. for access  *)
      noratio:boolean;                             (* if <No Ratio> active*)
    end;

  tag_ulfrec =
    record                          (********** "*.DIR" structure *********)
      filename:string[12];                         (* filename            *)
      description:string[78];                      (* description         *)
      nacc:integer;                                (* times DLed          *)
      ft:byte;                                     (* file type (255)     *)
      blocks:integer;                              (* # 128 byte blocks   *)
      owner:string[36];                            (* ULer of file        *)
      date:string[8];                              (* date ULed           *)
      daten:integer;                               (* date ULed (???)     *)
      unval:boolean;                               (* TRUE if unvalidated *)
      filepoints:byte;                             (* # filepoints req.   *)
    end;

  tag_anontyp=(noanon,yesanon,forcedanon);
  tag_boardrec=
    record                          (******* "BOARDS.DAT" structure *******)
      name:string[45];                               { base description    }
      filename:string[12];                           { filename            }
      sl:byte;                                       { SL req. for access  }
      maxmsgs:byte;                                  { max msgs allowed in }
      pw:string[16];                                 { password for access }
      anonymous:tag_anontyp;                         { anonymous type      }
      ar:tag_acrq;                                   { AR for access       }
      noansi:boolean;                                { if ANSI allowed     }
      postsl:byte;                                   { SL req. to post     }
    end;

  tag_vdatar=
    record
      question:string[74];
      numa:integer;
      answ:array[0..9] of
        record
          ans:string[40];
          numres:integer;
        end;
    end;

  tag_msgstat=(tag_validated,tag_unvalidated,tag_deleted);
  tag_messagerec=
  record
    title:string[30];
    messagestat:tag_msgstat;
    message:tag_messages;
    owner:integer;
    date:integer;
    mage:byte;
  end;

  tag_systatrec=
    record
      a:char;
      b:char;
      c:char;
      i:integer;
    end;

