CONST
  ver:string[15]='1.7a';

  maxusers=500;
  maxboards=64;       { 1 - x }
  maxuboards=96;      { 0 - x }
  maxprotocols=120;   { 0 - x }
  maxevents=10;       { 0 - x }   { #0 is Nightly Events (if active) }
  maxarcs=6;          { 1 - x }
  maxubatchfiles=20;
  numvoteqs=20;
  maxmenucmds=50;

TYPE
  astr = string[160];  { generic string type for parameters       }
                       { note the change from Wayne's str => Astr }

  acrq    ='@'..'Z';
  newtyp  =(rp,lt,rm);  {* message NewScan type *}
  uflags  =(rlogon,rchat,rvalidate,rbackspace,
            ramsg,rpostan,rpost,remail,
            rvoting,rmsg,spcsr,onekey,
            wordwrap,pause,novice,ansi,
            color,alert,smw,nomail,
            fnodlratio,fnopostratio,fnofilepts,fnodeletion);
  dlnscan =set of 0..maxuboards;
  emary   =array[1..20] of integer;
  anontyp =(no,yes,forced,dearabby);
  clrs    =array[FALSE..TRUE,0..9] of byte;
  secrange=array[0..255] of integer;

  messages=
    record
      ltr:char;
      number:integer;
      ext:byte;
    end;

  smalrec=
    record
      name:string[36];
      number:integer;
    end;

  userrec=
    record
      name:string[36];                 {* user name        *}
      realname:string[36];             {* real name        *}
      pw:string[20];                   {* user password    *}
      ph:string[12];                   {* user phone #     *}
      bday:string[8];                  {* user birthdate   *}
   firston:string[10];              {* firston date     *}
      laston:string[10];               {* laston date      *}
      street:string[30];               {* mailing address  *}
      citystate:string[30];            {* city, state      *}
      zipcode:string[10];              {* zipcode          *}
      computer:string[30];             {* type of computer *}
      occupation:string[40];           {* occupation       *}
      wherebbs:string[40];             {* BBS reference    *}
      note:string[39];                 {* SysOp note       *}

      lockedout:boolean;               {* if locked out    *}
      deleted:boolean;                 {* if deleted       *}
      lockedfile:string[8];            {* lockout msg to print *}

      ac:set of uflags;                {* user flags   *}
      ar:set of acrq;                  {* AR flags     *}

      qscan:array[1..maxboards] of messages; {* last read msg pointers *}
      qscn:array[1..maxboards] of boolean; {* scan boards flags  *}
      dlnscn:dlnscan;                  {* scan uboards flags *}

      vote:array[1..20] of byte;       {* voting data  *}

      sex:char;                        {* user sex *}

      ttimeon:longint;                 {* total mins spent on  *}
      x1xx:integer;
      uk:longint;                      {* UL k                 *}
      x2xx:integer;
      dk:longint;                      {* DL k                 *}
      x3xx:integer;

      uploads,downloads:integer;       {* # of ULs / # of DLs  *}
      loggedon:integer;                {* # times logged on    *}
      tltoday:integer;                 {* # min left today     *}
      msgpost:integer;                 {* # public posts       *}
      emailsent:integer;               {* # email sent         *}
      feedback:integer;                {* # feedback sent      *}
      forusr:integer;                  {* forward mail to user # *}
      filepoints:integer;              {* # of file points     *}

      waiting:byte;                    {* mail waiting         *}
      linelen:byte;                    {* line length (# cols) *}
      pagelen:byte;                    {* page length (# rows) *}
      ontoday:byte;                    {* # times on today     *}
      illegal:byte;                    {* # illegal logon attempts *}
      sl,dsl:byte;                     {* SL / DSL *}

      cols:clrs;                       {* user colors *}

      lastmsg,lastfil:byte;            {* last msg/file areas   *}
      credit:longint;                  {* $$$ credit in dollars *}
      x4xx:integer;
      timebank:integer;                {* # mins in Time Bank   *}
      boardsysop:array[1..5] of byte;  {* msg board SysOp       *}

      trapactivity:boolean;            {* if trapping users activity *}
      trapseperate:boolean;            {* if trap to seperate TRAP file *}

{* NEW STUFF *}

timebankadd:integer;
      mpointer:longint;                {* pointer to entry in MACRO.LST *}
      chatauto:boolean;                {* if auto chat trapping *}
      chatseperate:boolean;            {* if seperate chat file to trap to *}

{* NEW STUFF *ENDS* *}

      res:array[1..68] of byte;
    end;

  msgstat=(validated,unvalidated,deleted);
  messagerec=
    record
      title:string[30];
      messagestat:msgstat;
      message:messages;
      owner:integer;
      date:integer;
      mage:byte;
    end;

  filearcinforec=
    record
      active:boolean;       {* whether this archive format is active *}
      ext:string[3];        {* 3-chr file extension *}
      listline:string[25];  {* /x for internal;
                               x: 1=ZIP, 2=ARC/PAK, 3=ZOO, 4=LZH *}
      arcline:string[25];
      unarcline:string[25];
      testline:string[25];  {* '' for *None* *}
      cmtline:string[25];   {* '' for *None* *}
      succlevel:integer;    {* -1 for ignore results *}
    end;

  zlogt=
    record
      date:string[8];
      userbaud:array[0..4] of integer;
      active,calls,newusers,pubpost,privpost,fback,criterr:integer;
      uploads,downloads:integer;
      uk,dk:longint;
    end;

  systatrec=
    record
      bbsname:string[40];             {BBS's name                     }
      bbsphone:string[12];            {BBS's phone #                  }
      sysopfirst:string[12];          {SysOp's 1st name               }
      sysoplast:string[16];           {SysOp's 2nd name               }
      boardpw:string[20];             {newuser PW (if active)         }
      sysoppw:string[20];             {SysOp PW                       }
      bbspw:string[20];               {board PW (if matrix)           }
      closedsystem:boolean;           {if no new users accepted       }
      matrix:boolean;                 {if Shuttle Logon active        }
      alias:boolean;                  {if allow alias's               }
      clearmsg:boolean;               {if clear scr. before msg       }
      fone:boolean;                   {if ph# PW's active             }
      multitask:boolean;              {if BBS is multitasking         }
      bwindow:boolean;                {if large window active         }
      lock300:boolean;                {if lockout 300 baud            }
      wantquote:boolean;              {///                            }
      mcimsg:boolean;                 {///                            }
      special:boolean;                {WFC menu special effects       }
      localsec:boolean;               {if local security on           }
      localscreensec:boolean;         {whether local screen security  }
      autominlogon:boolean;           {if automessage in logon        }
      bullinlogon:boolean;            {if bulletins in logon          }
      lcallinlogon:boolean;           {if last caller list in logon   }
      autochatopen:boolean;           {if chat buffer auto-open       }
      yourinfoinlogon:boolean;        {whether yourinfo in logon      }
      globaltrap:boolean;             {if trap all users activity     }
      snowchecking:boolean;           {whether snow checking on       }
      forcevoting:boolean;            {manditory voting during logon  }
      offhooklocallogon:boolean;{take phone off hook when logon locally }

      hmsg:messages;                  {highest msg counter    }
      tfiledate:string[8];            {last Tfiles date       }
      lastdate:string[8];             {/// }

      callernum:longint;              {# of callers           }
      users:integer;                  {# of users             }
      activetoday:integer;            {TODAY's time-on count  }
      callstoday:integer;             {TODAY's caller count   }
      msgposttoday:integer;           {TODAY's post count     }
      emailtoday:integer;             {TODAY's email count    }
      fbacktoday:integer;             {TODAY's feedback count }
      uptoday:integer;                {TODAY's upload count   }
      newuk:integer;                  {TODAY's upload K count }
      newusertoday:integer;           {TODAY's new user count }
      dntoday:integer;                {TODAY's download count }
      newdk:integer;                  {TODAY's download K count }

      gfilepath:string[79];           {GFILES path }
      pmsgpath:string[79];            {Private mail path }
      menupath:string[79];            {MENUS path  }
      tfilepath:string[79];           {TFILES path }
      afilepath:string[79];           {alternate text files path }
      trappath:string[79];            {user audit trap path }
      temppath:string[79];            {"temp" directory path }

      lowtime,hitime:integer;         {SysOp hours }
      dllowtime,dlhitime:integer;     {download hours }
      b300lowtime,b300hitime:integer; {300 baud hours }
      b300dllowtime,b300dlhitime:integer; {300 baud DL hours }

      app:integer;                    {user num to send new user application to }
      guestuser:integer;              {user num of guest user }
      timeoutbell:integer;            {mins before timeout bell }
      timeout:integer;                {mins before timeout   }

      sysopcolor,usercolor:byte;      {colors in chat mode   }
      bsdelay:byte;                   {backspacing delay     }
      tosysopdir:byte;                {"To SysOp" file dir   }

      comport:byte;                   {comport #    }
      maxbaud:word;                   {max baud     }
      init:string[40];                {init string  }
      hangup:string[40];              {hangup string }
      offhook:string[40];             {phone off hook string }
      answer:string[40];              {answer string }

      resultcode:array[1..2,0..4] of integer; {**-Result codes-** }
      nocarrier:integer;              {no carrier result code }
      nodialtone:integer;             {no dialtone result code }
      busy:integer;                   {busy result code }
      nocallinittime:integer;         {reinit modem after x mins of inactivity }
      tries:byte;                     {tries allowed for PW's }

      newsl,newdsl:byte;              {new-       }
      newar:set of acrq;              {user       }
      newac:set of uflags;            {automatic  }
      newfp:integer;                  {settings   }

      autosl,autodsl:byte;            {auto-      }
      autoar:set of acrq;             {validation }
      autoac:set of uflags;           {settings   }

      ansiq:string[80];               {"do you want ANSI" string }
      engage:string[79];              {engage chat string   }
      endchat:string[79];             {end chat string      }
      sysopin:string[79];             {if in sysop hours    }
      sysopout:string[79];            {if outside sysop hours }
      note:array[1..2] of string[79]; {logon notes (L 1-2)  }
      lprompt:string[40];             {logon prompt (L 3)   }
      wait:string[79];                {sysop working string }
      pause:string[79];               {pause string         }
      msg1:string[79];                {enter msg line 1     }
      msg2:string[79];                {enter msg line 2     }
      new1:string[79];                {newscan begin string }
      new2:string[79];                {newscan done string  }
      read:string[79];                {Msg (S)can prompt    }
      auto1:string[79];               {auto msg title       }
      autom:char;                     {auto msg borders     }
      echoc:char;                     {echo char for PWs    }

      uldlratio:boolean;              {if UL/DL ratios on }
      fileptratio:boolean;            {if file pt ratios on }
      fileptcomp:byte;                {file pt compensation ratio }
      fileptcompbasesize:byte;        {file pt base compensation size }

      timeallow:secrange;             {time allowance       }
      callallow:secrange;             {call allowance       }
      dlratio:secrange;               {# DLs ratios         }
      dlkratio:secrange;              {DL k ratios          }
      postratio:secrange;             {post ratios          }

      normpubpost,anonpubpost,anonpubread:byte; {public mail SLs }
      normprivpost,anonprivpost,anonprivread:byte;  {email SLs }
      maxpubpost,maxprivpost:byte;    {max post/email per call }
      maxfback,maxchat:byte;          {max feedback/pages per call }
      maxwaiting,csmaxwaiting:byte;   {max mail waiting, normal/CS }
      maxlines,csmaxlines:byte;       {max lines in msg, normal/CS }

      sop,csop:byte;                  {SysOp SL / CoSysOp SL   }
      msop,fsop:byte;        {Message SysOp SL / File SysOp SL }
      spw:byte;                       {SysOp PW at logon       }
      seepw:byte;                     {see SysOp PWs remotely  }
      nodlratio:byte;                 {no DL ratio checking    }
      nopostratio:byte;               {no post ratio checking  }
      nofilepts:byte;                 {no file pts checking SL }
      seeunval:byte;                  {see unvalidated files SL }
      dlunval:byte;                   {download unval. files SL }
      ulrefund:byte;                  {% time refund for ULs   }

      eventwarningtime:integer;            {time before event warning }
      filearccomment:array[1..3] of string[80]; {BBS comment for ARC file }
      filearcinfo:array[1..maxarcs] of filearcinforec; {ARC specs }

      minspaceforpost:integer;  (* minimum K req'd for a post *)
      minspaceforupload:integer; (* minimum K req'd for an upload *)
postcredits:integer; (* file points/upload credit compensation for posts *)
ulvalreq:byte; (* uploads require validation override SL *)

      moveline:string[30];            {commandline for MOVE utility }
      backsysoplogs:byte;       {# back-days to keep SYSOP##.LOG }
      compressbases:boolean;    {whether to "compress" file/msg bases user
                                   doesn't have access to }
      remdevice:string[10];     {remote output device }
      userbaud:array[0..4] of integer;  {user baud rates ... }
      criterr:integer;                  {# critical errors occured today }

      searchdup:boolean;     {whether to search for duplicate filenames when UL }
      istopwindow:boolean;  {whether to put SysOp window on top of screen.. }

arq9600rate:word; {baud rate to USE when 9600 ARQ result code}

      res:array[1..138] of byte;      {reserved}
    end;

  blk=array[1..255] of byte;

  mailrec=
    record
      title:string[30];
      from,destin:integer;
      msg:messages;
      date:integer;
      mage:byte;
    end;

  gft=
    record
      num:integer;
      title:string[40];
      filen:string[12];
      ar:acrq;
      gdate:string[8];
      gdaten:integer;
    end;

  smr=
    record
      msg:astr;
      destin:integer;
    end;

  vdatar=
    record
      question:string[79];
      numa:integer;
      answ:array[0..9] of
        record
          ans:string[40];
          numres:integer;
        end;
    end;

  boardrec=
    record
      name:string[30];
      filename:string[12];
      msgpath:string[40];          {* path for message text *}
      sl:byte;
      postsl:byte;
      ar:acrq;
      maxmsgs:byte;
      anonymous:anontyp;
      password:string[10];
    end;

  ulrec=
    record
      name:string[25];                {* area description  *}
      filename:string[12];            {* filename + ".DIR" *}
      dlpath:string[40];              {* download path     *}
      noratio:boolean;                {* if <No Ratio> active *}
      sl:byte;                        {* SL required       *}
      dsl:byte;                       {* DSL required      *}
      namesl:byte;                    {* see who ULed SL req. *}
      ar:acrq;                        {* AR flag required  *}
      maxfiles:integer;               {* max files allowed *}
      agereq:byte;                    {* age required      *}
      password:string[10];            {* password required *}
      arctype:byte;                   {* wanted archive type (1-maxarcs,0=inactive) *}
      cmttype:byte;                   {* wanted comment type (1-3,0=inactive) *}
      unhidden:boolean;               {* whether *VISIBLE* to users w/o access *}
{*ulpath:string[39];              * upload path       * *}
    end;

  filstat=(notval,isrequest,resumelater);

  ulfrec=
    record
      filename:string[12];           {* filename           *}
      description:string[60];        {* file description   *}
      filepoints:integer;            {* file points        *}
      nacc:integer;                  {* # of DLs           *}
      ft:byte;                       {* file type          *}
      blocks:integer;                {* # of 128 byte blocks *}
      owner:integer;                 {* uploader of file   *}
      stowner:string[36];            {* uploader's name    *}
      date:string[8];                {* date ULed          *}
      daten:integer;                 {* date ULed, numeric *}
      vpointer:longint;              {* pointer to verbose description. *}
      filestat:set of filstat;       {* file's status      *}
      res:array[1..10] of byte;      {* RESERVED *}
    end;

  strptr=^strrec;
  strrec=
    record
      i:astr;
      next,last:strptr;
    end;

  expro=
    record
      active:boolean;
      descr:string[30];
      key:char;
      rcmd,scmd:string[50];
      brcmd,bscmd:string[50];
      rescmd:string[50];
      ptype,xferok:integer;
      sl,dsl:byte;
      ar:acrq;
    end;

  verbrec=
    record
      descr:array[1..4] of string[50];
    end;

  lcallers=
    record
      callernum:integer;
      name:string[36];
      number:integer;
      citystate:string[30];
    end;

  eventrec=
    record
      active:boolean;             (* whether active or not *)
      description:string[30];     (* description *)
      etype:char;                 (* [E]xternal or [D]os call *)
      execdata:string[20];        (* errorlevel if [E], commandline if [D] *)
      busytime:integer;           (* off-hook time before; 0 if none *)
      exectime:integer;           (* execution time *)
      busyduring:boolean;         (* whether to busy phone DURING event *)
      duration:integer;           (* length of time takes *)
      execdays:byte;              (* bitwise execution days; DATE if monthly *)
      monthly:boolean;            (* whether once a month *)
    end;

  macrorec=
    record
      macro:array [1..4] of string[240];
    end;

  mnuflags=(autohelp,autotime,dslchk,nomenuprompt); {* H, T, D, N *}
  menurec=
    record
      menuname:string[100];     {* menu name            *}
      directive:string[12];     {* help file displayed  *}
      tutorial:string[12];      {* tutorial help file   *}
      menuprompt:string[120];   {* menu prompt          *}
      secreq:byte;              {* security check (SL/DSL - see SL/DSL flag) *}
      arreq:acrq;               {* AR required          *}
      password:string[15];      {* password required    *}
      fallback:string[8];       {* fallback menu        *}
      gencols:byte;             {* generic menus: # of columns *}
      gcol:array[1..3] of byte; {* generic menus: colors *}
      menuflags:set of mnuflags;{* DHT - (D)SL security checking,
                                   (H)elp display automatic,
                                   (T)ime display,
                                   (N)o menu prompt *}
    end;

  cmdflags=(checkeither,dslcheck,hidden);    {* C, D, H *}
  commandrec=
    record
      ldesc:string[70];
      sdesc:string[35];
      ckeys:string[14];
      secreq:byte;
      arreq:acrq;
      cmdkeys:string[2];
      mstring:string[50];
      commandflags:set of cmdflags;
    end;

  protrec=
    record
      active:boolean;                            (* whether active *)
      isbatch,isresume:boolean;                  (* batch protocol? *)
      ckeys:string[14];                          (* command keys *)
      descr:string[70];                          (* description *)
      minbaud,maxbaud:integer;                   (* min/max baud rates *)
      sl,dsl:byte;                               (* SL/DSL req'd *)
      ar:acrq;                                   (* AR flag *)
      templog:string[60];                        (* temp. log file *)
      uloadlog,dloadlog:string[60];              (* permanent log files *)
      ulcmd,dlcmd:string[78];                    (* UL/DL commandlines *)
      xferokcode:boolean;                        (* codes mean X-fer ok *)
      ulcode,dlcode:array [1..6] of string[10];  (* UL/DL codes *)
      envcmd:string[60];                      {B}(* environment setup cmd *)
      dlflist:string[60];                     {B}(* DL file lists *)
      maxchrs:integer;                           (* max chrs in cmdline *)
      logpf,logps:integer;                    {B}(* pos in log file for data *)
    end;

