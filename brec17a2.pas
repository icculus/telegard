
(***** BETA CONVERSION RECORDS *****)

  ulrec17a2=                          { UPLOADS.DAT : File base records }
    record
      name:string[40];               { area description  }
      filename:string[12];            { filename + ".DIR" }
      dlpath,                         { download path     }
  ulpath:string[40];              { upload path       }
      namesl:byte;                    { req SL to see who ULed }
      maxfiles:integer;               { max files allowed }
      password:string[20];            { password required }
      arctype,                        { wanted archive type (1..maxarcs,0=inactive) }
      cmttype:byte;                   { wanted comment type (1..3,0=inactive) }
  fbdepth:integer;                { file base dir depth }
  fbstat:set of fbflags;          { file base status vars }
  acs:acstring;                   { access requirements }
  {}sl:byte;                        { SL required       }
  {}dsl:byte;                       { DSL required      }
  {}ar:acrq;                        { AR flag required  }
  {}agereq:byte;                    { age required      }
      res:array[1..6] of byte;        { RESERVED }
    end;

  systatrec17a4=
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
      autom,                          {auto msg borders     }
      echoc:char;                     {echo char for PWs    }

      uldlratio,                      {if UL/DL ratios on }
      fileptratio:boolean;            {if file pt ratios on }
      fileptcomp,                     {file pt compensation ratio }
      fileptcompbasesize:byte;        {file pt base compensation size }

      timeallow,                      {time allowance       }
      callallow,                      {call allowance       }
      dlratio,                        {# DLs ratios         }
      dlkratio,                       {DL k ratios          }
      postratio:secrange;             {post ratios          }

      normpubpost,anonpubpost,anonpubread, {public mail SLs }
      normprivpost,anonprivpost,anonprivread, {email SLs }
      maxpubpost,maxprivpost,         {max post/email per call }
      maxfback,maxchat,               {max feedback/pages per call }
      maxwaiting,csmaxwaiting,        {max mail waiting, normal/CS }
      maxlines,csmaxlines:byte;       {max lines in msg, normal/CS }

      sop,csop,                       {SysOp SL / CoSysOp SL   }
      msop,fsop,             {Message SysOp SL / File SysOp SL }
      spw,                            {SysOp PW at logon       }
      seepw,                          {see SysOp PWs remotely  }
      nodlratio,                      {no DL ratio checking    }
      nopostratio,                    {no post ratio checking  }
      nofilepts,                      {no file pts checking SL }
      seeunval,                       {see unvalidated files SL }
      dlunval,                        {download unval. files SL }
      ulrefund:byte;                  {% time refund for ULs   }

      eventwarningtime:integer;       {time before event warning }
      filearccomment:array[1..3] of string[80]; {BBS comment for ARC file }
      filearcinfo:array[1..6] of filearcinforec; {ARC specs}

      minspaceforpost,                {minimum K req'd for a post}
      minspaceforupload:integer;      {minimum K req'd for an upload}
postcredits:integer; {file points/upload credit compensation for posts}
ulvalreq:byte; {uploads require validation override SL}

mmmmm:array[1..31] of byte;

      backsysoplogs:byte;               {# back-days to keep SYSOP##.LOG}
      compressbases:boolean;            {whether to "compress" file/msg bases}
      remdevice:string[10];             {remote output device }
      userbaud:array[0..4] of integer;  {user baud rates ... }
      criterr:integer;                  {# critical errors occured today }

      searchdup:boolean;                {search for dup. filenames when UL?}
      istopwindow:boolean;              {put SysOp window on top of screen?}

      arq9600rate:word;            {baud rate to USE when 9600 ARQ result code}
      allstartmenu:string[8];           {menu to start ALL users out on}
  wfcblanktime:byte;                {minutes after which to blank WFC menu}
  validateallfiles:boolean;         {validate all files automatically?}
  maxintemp:integer;                {max k-bytes allowed in TEMP\3\}
  slogtype:byte;                    {output SysOp log to printer?}
  stripclog:boolean;                {strip color from SysOp log output?}
  noforcerate:boolean;              {whether to force baud rate}
  rebootforevent:boolean;           {reboot before events?}
  minresume:integer;                {minimum k-bytes to allow save for resume}

      res:array[1..123] of byte;        {***-> reserved <-***}
    end;

  boardrec17a5=                       { BOARDS.DAT : Message base records }
    record
      name:string[40];                { message base description }
      filename:string[12];            { *.BRD data filename }
      msgpath:string[40];             { messages pathname   }
      acs,                            { access requirement }
      postacs,                        { post access requirement }
      mciacs:acstring;                { MCI usage requirement }
      maxmsgs:byte;                   { max message count }
      anonymous:anontyp;              { anonymous type }
      password:string[20];            { base password }
      mbstat:set of mbflags;          { message base status vars }
      permindx:longint;               { permanent index # }
{*}mbdepth:integer;                { message base dir depth }
      res:array[1..4] of byte;        { RESERVED }
    end;

  modemrec17a7=
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
    end;

