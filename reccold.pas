(*****************************************************************************)
(**                                                                         **)
(**                                                                         **)
(**                    ---   R E C C O L D . P A S   ---                    **)
(**                    Old Record Structures Header File                    **)
(**                                                                         **)
(**              Used as a filter for RECxxxx.PAS record files              **)
(**                                                                         **)
(**                                                                         **)
(**                                                                         **)
(*****************************************************************************)

{$I rec20.pas}

CONST
  xx_s_ver:string[30]= V20_s_ver;
  ver:string[30]  = V20_ver;
  verdate         = V20_verdate;

  maxboards       = V20_maxboards;
  maxuboards      = V20_maxuboards;
  maxprotocols    = V20_maxprotocols;
  maxevents       = V20_maxevents;
  maxarcs         = V20_maxarcs;
  maxubatchfiles  = V20_maxubatchfiles;
  numvoteqs       = V20_numvoteqs;
  numvoteas       = V20_numvoteas;
  maxmenucmds     = V20_maxmenucmds;

TYPE
  astr            = V20_astr;
  acstring        = V20_acstring;
  acrq            = V20_acrq;
  newtyp          = V20_newtyp;
  uflags          = V20_uflags;
  anontyp         = V20_anontyp;
  clrs            = V20_clrs;
  secrange        = V20_secrange;
  mzscanr         = V20_mzscanr;
  fzscanr         = V20_fzscanr;
  mhireadr        = V20_mhireadr;
  smalrec         = V20_smalrec;            { NAMES.LST }
  userrec         = V20_userrec;            { USER.LST }
  zscanrec        = V20_zscanrec;           { ZSCAN.DAT }
  msgindexstatr   = V20_msgindexstatr;      { *.MIX flags }
  msgindexrec     = V20_msgindexrec;        { *.MIX }
  msghdrrec       = V20_msghdrrec;          { *.HDR }
{}  msgstat         = V20_msgstat;
{}  messagerec      = V20_messagerec;
{}  mailrec         = V20_mailrec;
  zlogrec         = V20_zlogrec;            { ZLOG.DAT }
  filearcinforec  = V20_filearcinforec;
  modemrec        = V20_modemrec;           { MODEM.DAT }
  fstringrec      = V20_fstringrec;         { STRING.DAT }
  systatrec       = V20_systatrec;          { STATUS.DAT }
  tbflags         = V20_tbflags;            { GFILES.DAT flags }
  tfilerec        = V20_tfilerec;           { GFILES.DAT }
  smr             = V20_smr;                { SHORTMSG.DAT }
  vdatar          = V20_vdatar;             { VOTING.DAT }
  mbflags         = V20_mbflags;            { BOARDS.DAT flags }
  boardrec        = V20_boardrec;           { BOARDS.DAT }
  fbflags         = V20_fbflags;            { UPLOADS.DAT flags }
  ulrec           = V20_ulrec;              { UPLOADS.DAT }
  filstat         = V20_filstat;            { *.DIR flags }
  ulfrec          = V20_ulfrec;             { *.DIR }
  verbrec         = V20_verbrec;            { VERBOSE.DAT }
  lcallers        = V20_lcallers;           { LASTON.DAT }
  eventrec        = V20_eventrec;           { EVENTS.DAT }
  macrorec        = V20_macrorec;           { MACRO.LST }
  mnuflags        = V20_mnuflags;           { *.MNU flags (header) }
  menurec         = V20_menurec;            { *.MNU (header) }
  cmdflags        = V20_cmdflags;           { *.MNU flags (commands) }
  commandrec      = V20_commandrec;         { *.MNU (commands) }
  xbflags         = V20_xbflags;            { PROTOCOL.DAT flags }
  protrec         = V20_protrec;            { PROTOCOL.DAT }
  datetimerec     = V20_datetimerec;
  cfilterrec      = V20_cfilterrec;



CONST
  rp              = V20_rp;
  lt              = V20_lt;
  rm              = V20_rm;

  rlogon          = V20_rlogon;
  rchat           = V20_rchat;
  rvalidate       = V20_rvalidate;
  rbackspace      = V20_rbackspace;
  ramsg           = V20_ramsg;
  rpostan         = V20_rpostan;
  rpost           = V20_rpost;
  remail          = V20_remail;
  rvoting         = V20_rvoting;
  rmsg            = V20_rmsg;
  spcsr           = V20_spcsr;
  onekey          = V20_onekey;
  wordwrap        = V20_wordwrap;
  pause           = V20_pause;
  novice          = V20_novice;
  ansi            = V20_ansi;
  color           = V20_color;
  alert           = V20_alert;
  smw             = V20_smw;
  nomail          = V20_nomail;
  fnodlratio      = V20_fnodlratio;
  fnopostratio    = V20_fnopostratio;
  fnofilepts      = V20_fnofilepts;
  fnodeletion     = V20_fnodeletion;

  atno            = V20_atno;
  atyes           = V20_atyes;
  atforced        = V20_atforced;
  atdearabby      = V20_atdearabby;
  atanyname       = V20_atanyname;

  miexist         = V20_miexist;
  miencrypted     = V20_miencrypted;
  miunvalidated   = V20_miunvalidated;
  mipermanent     = V20_mipermanent;
  miallowmci      = V20_miallowmci;
  mithreads       = V20_mithreads;
  mimassmail      = V20_mimassmail;

  validated       = V20_validated;
  unvalidated     = V20_unvalidated;
  deleted         = V20_deleted;
  permanentpost   = V20_permanentpost;
  mciallowed      = V20_mciallowed;
  anonymouspost   = V20_anonymouspost;
  sysopanonymous  = V20_sysopanonymous;

  tbunhidden      = V20_tbunhidden;
  tbnetlink       = V20_tbnetlink;
  tbisdir         = V20_tbisdir;

  mbunhidden      = V20_mbunhidden;
  mbnetlink       = V20_mbnetlink;
  mbisdir         = V20_mbisdir;
  mbmsgpath       = V20_mbmsgpath;

  fbnoratio       = V20_fbnoratio;
  fbunhidden      = V20_fbunhidden;
  fbdirdlpath     = V20_fbdirdlpath;
  fbisdir         = V20_fbisdir;
  fbusegifspecs   = V20_fbusegifspecs;
  fbnetlink       = V20_fbnetlink;

  notval          = V20_notval;
  isrequest       = V20_isrequest;
  resumelaterw    = V20_resumelater;

  clrscrbefore    = V20_clrscrbefore;
  dontcenter      = V20_dontcenter;
  nomenuprompt    = V20_nomenuprompt;
  forcepause      = V20_forcepause;
  autotime        = V20_autotime;

  hidden          = V20_hidden;
  unhidden        = V20_unhidden;

  xbactive        = V20_xbactive;
  xbisbatch       = V20_xbisbatch;
  xbisresume      = V20_xbisresume;
  xbxferokcode    = V20_xbxferokcode;


