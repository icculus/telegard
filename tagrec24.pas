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

type
  tag_acrq = '@'..'Z';
  tag_flags = (aflag,bflag,cflag,dflag,eflag,fflag,gflag,hflag,iflag,jflag,
               kflag,lflag,mflag,nflag,oflag,pflag,qflag,rflag,sflag,tflag,
               uflag,vflag,wflag,xflag);
  tag_bscan = set of 0..55;
  tag_fscan = set of 0..95;
  tag_clrs = array[FALSE..TRUE,0..9] of byte;

  tag_smalrec = record              (******** "NAMES.LST" structure *******)
                  name:string[36];
                  number:integer;
                end;
  tag_userrec = record              (******** "USER.LST" structure ********)
                  name:string[36];                 (* user name           *)
                  realname:string[36];             (* real name           *)
                  street:string[30];               (* street address      *)
                  computer:string[30];             (* computer type       *)
                  citystate:string[30];            (* city, state         *)
                  note:string[30];                 (* sysop note          *)
                  lastdate:integer;                (* last logon w/spdate *)
                  lasttime:integer;                (* last logon w/sptime *)
                  pw:string[16];                   (* password            *)
                  ph:string[12];                   (* phone number        *)
                  zipcode:string[10];              (* zipcode             *)
          unknown1:array[1..168] of byte;          {-----------------------}
                  vote:array[1..20] of byte;       (* voting answers      *)
                  callspread:array[1..15] of byte; (* call spread         *)
                  ttimeon:real;                    (* total time on       *)
                  uk:real;                         (* total upload K      *)
                  dk:real;                         (* total download K    *)
                  userno:integer;                  (* user number         *)
                  emailsent:integer;               (* email sent          *)
                  msgpost:integer;                 (* public msgs posted  *)
                  feedback:integer;                (* feedback sent       *)
                  loggedon:integer;                (* total logon times   *)
                  uploads:integer;                 (* total # of uploads  *)
                  downloads:integer;               (* total # of downloads*)
                  forusr:integer;            (* user # to forward mail to *)
                  maxbaud:integer;                 (* maximum baud rate   *)
                  ttoday:integer;                  (* total time on today *)
                  credit:integer;                  (* $$$ credit in cents *)
          unknown2:array[1..2] of byte;            {-----------------------}
                  filepoints:integer;              (* # of file points    *)
                  timebank:integer;                (* mins in time bank   *)
                  birthdate:integer;               (* birthdate w/ spdate *)
          unknown3:array[1..5] of byte;            {-----------------------}
                  sl:byte;                         (* SL level            *)
                  dsl:byte;                        (* DSL level           *)
                  helplevel:byte;                  (* help level (1-4)    *)
                  linelen:byte;                    (* line length (cols)  *)
                  pagelen:byte;                    (* page length (rows)  *)
                  ontoday:byte;                    (* logon times today   *)
                  illegal:byte;                 (* illegal logon attempts *)
                  waiting:byte;                    (* # mail waiting      *)
                  lastmsg:byte;                    (* last msg base       *)
                  lastfil:byte;                    (* last file base      *)
          unknown4:array[1..2] of byte;            {-----------------------}
                  ar:set of tag_acrq;              (* AR flags            *)
                  ac:set of tag_flags;             (* Special flags       *)
          unknown5:array[1..4] of byte;            {-----------------------}
                  zbscan:tag_bscan;                (* msg board scan ptrs *)
                  zfscan:tag_fscan;                (* file board scan ptrs*)
                  cols:tag_clrs;                   (* user colors         *)
                end;

  tag_ulrec = record                (******* "FBOARDS.DAT" structure ******)
                name:string[26];                   (* base description    *)
        unknown1:array[1..13] of byte;             {-----------------------}
                filename:string[8];                (* *.DIR filename      *)
                dlpath:string[30];                 (* DL location         *)
                ulpath:string[30];                 (* ULs go here         *)
                password:string[16];               (* password for access *)
                dsl:byte;                          (* DSL req. for access *)
                namedsl:byte;                      (* see who ULed access *)
                ar:tag_acrq;                       (* AR req. for access  *)
                noratio:boolean;                   (* if <No Ratio> active*)
              end;

  tag_ulfrec = record               (********** "*.DIR" structure *********)
                 filename:string[12];              (* filename            *)
                 description:string[78];           (* description         *)
                 nacc:integer;                     (* times DLed          *)
                 ft:byte;                          (* file type (255)     *)
                 blocks:integer;                   (* # 128 byte blocks   *)
                 owner:string[36];                 (* ULer of file        *)
                 date:string[8];                   (* date ULed           *)
                 daten:integer;                    (* date ULed (???)     *)
                 unval:boolean;                    (* TRUE if unvalidated *)
                 filepoints:byte;                  (* # filepoints req.   *)
               end;
  tag_anontyp=(noanon,yesanon,forcedanon);
  tag_boardrec=record               (******* "BOARDS.DAT" structure *******)
                 name:string[30];                  (* base description    *)
         unknown1:array[1..15] of byte;            {-----------------------}
                 filename:string[8];              (* filename            *)
         unknown2:array[1..4] of byte;             {-----------------------}
                 sl:byte;                          (* SL req. for access  *)
                 maxmsgs:byte;                     (* max msgs allowed in *)
                 pw:string[16];                    (* password for access *)
                 anonymous:tag_anontyp;            (* anonymous type      *)
                 ar:acrq;                          (* AR for access       *)
                 ansi:boolean;                     (* if ANSI allowed     *)
                 postsl:byte;                      (* SL req. to post     *)
               end;
  tag_vdatar=record
               question:string[74];
               numa:integer;
               answ:array[0..9] of record
                                     ans:string[40];
                                     numres:integer;
                                   end;
             end;

