{*****************************************************************************
 *                               Project Coyote                              *
 *                             ===================                           *
 *                                                                           *
 * Modification History                                                      *
 * ====================                                                      *
 *   11/19/92 - 0.14 - Robert Merritt                                        *
 *                                                                           *
 *                                                                           *
 * NOTE: Project Coyote originated from TeleGard 2.5i which was originally   *
 *       written by Eric Oman, and Martin Pollard.                           *
 *                                                                           *
 *****************************************************************************}
{$A+,B+,E+,F+,I+,L-,N-,O+,R-,S+,V-}
{$M 60000,0,45000}      { Memory Allocation Sizes }

Program BBS;
Uses

  {rcg11172000 no overlay under Linux.}
  {Overlay,}

  Crt,      Dos,      InitP,    Sysop1,   Sysop2,   Sysop3,
  Sysop4,   Sysop5,   Sysop6,   Sysop7,   Sysop8,   Sysop9,   Sysop10,
  Sysop11,  Mail0,    Mail1,    Mail2,    Mail3,    Mail4,    Mail5,
  Mail6,    Mail9,    File0,    File1,    File2,    File3,    File4,
  File5,    File6,    File7,    File8,    File9,    File10,   File11,
  File12,   File13,   File14,   Archive1, Archive2, Archive3, Misc1,
  Misc2,    Misc3,    Misc4,    MiscX,    CUser,    Doors,    Menus2,
  Menus3,   Menus4,   MyIO,     Logon1,   Logon2,   NewUsers, WfcMenu,
  Menus,    FvType,   TimeJunk, TmpCom,   MsgPack,  Common,   Common1,
  Common2,  Common3,  ExecSwap;        {* MiniTerm, Window2,  NewCom *}

{$O MsgPack   } {$O Common1   } {$O Common2   } {$O Common3   } {$O InitP     }
{$O WfcMenu   } {$O FvType    } {$O TimeJunk  } {$O Sysop1    } {$O Sysop2    }
{$O Sysop21   } {$O Sysop2a   } {$O Sysop2b   } {$O Sysop2c   } {$O Sysop2d   }
{$O Sysop2e   } {$O Sysop2f   } {$O Sysop2fa  } {$O Sysop2g   } {$O Sysop2h   }
{$O Sysop2i   } {$O Sysop2s   } {$O Sysop2z   } {$O Sysop3    } {$O Sysop4    }
{$O Sysop5    } {$O Sysop6    } {$O Sysop7    } {$O Sysop7m   } {$O Sysop8    }
{$O Sysop9    } {$O Sysop10   } {$O Sysop11   } {$O Mail0     } {$O Mail1     }
{$O Mail2     } {$O Mail3     } {$O Mail4     } {$O Mail5     } {$O Mail6     }
{$O Mail9     } {$O File0     } {$O File1     } {$O File2     } {$O File3     }
{$O File4     } {$O File5     } {$O File6     } {$O File7     } {$O File8     }
{$O File9     } {$O File10    } {$O File11    } {$O File12    } {$O File13    }
{$O File14    } {$O Archive1  } {$O Archive2  } {$O Archive3  } {$O Logon1    }
{$O Logon2    } {$O NewUsers  } {$O Misc1     } {$O Misc2     } {$O Misc3     }
{$O Misc4     } {$O MiscX     } {$O CUser     } {$O Doors     } {$O ExecBat   }
{$O MyIO      } {$O Menus2    } {$O Menus3    } {$O Menus4    }

Const
  OvrMaxSize      = 60000;
  BBSMaxHeapSpace = 40000;

{$I LcBbs.Pas}

Var
  ExitSave  : Pointer;
  ExecFirst : Boolean;
  NewMenuCmd: String;

Procedure ErrorHandle;
{*****************************************************************************
 * Note: if error occurs IN THIS PROCEDURE,                                  *
 * it is NOT executed again!  That way an infinite loop is *avoided*....     *
 *****************************************************************************}
Var
  T:Text;
  F:File;
  S:String[80];
  VidSeg:Word;
  X,Y:Integer;
  C:Char;
Begin
  ExitProc:=ExitSave;
  If (ErrorAddr<>Nil) then
  Begin
    chdir(start_dir);
    if (textrec(sysopf).mode=fmoutput) then
    begin
      writeln(sysopf,#3#8+'*>>'+#3#7+' Runtime error '+cstr(exitcode)+
              ' at '+date+' '+time+#3#8+' <<*'+#3#5+
              ' (Check ERR.LOG in main BBS dir)');
      flush(sysopf); close(sysopf);
    end;
    if (textrec(trapfile).mode=fmoutput) then
    begin
      writeln(trapfile,'*>> Runtime error '+cstr(exitcode)+' at '+date+' '+
              time+' <<*');
      flush(trapfile); close(trapfile);
    end;

    assign(t,'err.log');
    {$I-} append(t); {$I+}
    if (ioresult<>0) then
    begin
      rewrite(t);
      append(t);
      writeln(t,'???????????????????????????????????????????????????????????????????????????????');
      writeln(t,'Critical Error Log file - Contains screen images at instant of Error.');
      writeln(t);
    end;
    writeln(t);
    if (serialnumber<>0) then
      s:=' ('+cstr(serialnumber)+vercs+')'
    else
      s:='';
    writeln(t,'?>? RT #'+cstr(exitcode)+' at '+date+' '+time+'  BBS-Ver: '+ver+s);
    if (useron) then begin
      if (spd<>'KB') then s:='at '+spd+' baud' else s:='Locally';
      writeln(t,'?>? User "'+allcaps(thisuser.name)+' #'+cstr(usernum)+
              '" was on '+s);
    end;
    writeln(t,'???????????????????????????? <?- Screen Image: -?> ????????????????????????????');

    {rcg11172000 Not under Linux...}
    {
    if (mem[$0000:$0449]=7) then vidseg:=$B000 else vidseg:=$B800;
    for y:=1 to 25 do
    begin
      s:='';
      for x:=1 to 80 do
      begin
        c:=chr(mem[vidseg:(160*(y-1)+2*(x-1))]);
        if (c=#0) then c:=#32;
        if ((x=wherex) and (y=wherey)) then c:=#178;
        if ((x<>80) or ((x=80) and (c<>#32))) then s:=s+c;
      end;
      writeln(t,s);
    end;
    }


    writeln('STUB: bbs.pas; ErrorHandler()...');
    writeln(t, '  (No screen dump. Sorry.  --ryan.)');


    writeln(t,'???????????????????????????????????????*???????????????????????????????????????');
    close(t);

    assign(f,'critical.err'); rewrite(f); close(f); setfattr(f,dos.hidden);

    sprint(#3#8+'*>>'+#3#7+' System error occured at '+date+' '+time+#3#8+' <<*');
    term_ready(TRUE); remove_port; {removeint(modemr.comport);}
    writeln('*>> System error '+cstr(exitcode)+' at '+date+' '+time+' <<*');

    if (exiterrors<>-1) then halt(exiterrors) else halt(254);
    {* CRITICAL ERROR ERRORLEVEL *}
  end;
end;

Procedure MenuExec;
Var
  Dt    : LDateTimeRec;
  Cmd,s : String;
  I     : Integer;
  Aa,Abort,Next,Done:Boolean;
Begin
  If (ExecFirst) then
  Begin
    ExecFirst:=FALSE;
    Cmd:=NewMenuCmd;
    NewMenuCmd:='';
  End Else MainMenuHandle(Cmd);

  if ((copy(cmd,1,2)='\\') and (thisuser.sl=255)) then begin
    domenucommand(done,copy(cmd,3,length(cmd)-2),newmenucmd);
    if (newmenucmd<>'') then cmd:=newmenucmd else cmd:='';
  end;

  If (Cmd='|') then
  Begin
    nl; sprint(#3#3+verline(1)); sprint(#3#3+verline(2)); nl;
    pdt2dt(sitedatetime,dt);
    sprint(#3#3+'Release date: unreleased ');
    lastcommandgood:=TRUE;
  end else
  if ((cmd='=') and (cso)) then showmenucmds
  else
  if (cmd<>'') then
  begin
    newmenucmd:='';
    repeat domenuexec(cmd,newmenucmd) until (newmenucmd='');
  end;
end;

Var
  OvrPath,VerType : String;
  I,RCode         : Integer;
  NeedToHangup    : Boolean;
  SyStatF         : File of systatrec;
Begin
  exitsave:=exitproc;
  exitproc:=@errorhandle;

  MaxHeapSpace:=BBSMaxHeapSpace;
  checksnow:=TRUE; directvideo:=FALSE;

  useron:=FALSE; usernum:=0;
  getdir(0,start_dir);

  assign(systatf,'status.dat');
  {$I-} reset(systatf); {$I+}
  if (ioresult<>0) then
  begin
    writeln;
    writeln('Unable to find STATUS.DAT data file.  This file is absolutely');
    writeln('*REQUIRED* to even load the BBS.  If you cannot find your');
    writeln('STATUS.DAT data file, re-create one using the INIT package.');
    if (exiterrors<>-1) then halt(exiterrors) else halt(254);
  end else begin
    {$I-} read(systatf,systat); {$I+}
    close(systatf);
  end;


  {rcg12132000 added checks. Friggin' Xterms... :)  }
  if (ScreenWidth <> 80) then
  begin
        writeln;
        writeln('Your terminal needs to be exactly 80 characters wide to run the BBS.');
        writeln(' If this is a window, please resize it.');
        halt(254);
  end;

  if ((ScreenHeight < 25) or (ScreenHeight > 50)) then
  begin
        writeln;
        writeln('Your terminal must be between 25 and 50 characters high to run the BBS.');
        writeln(' If this is a window, please resize it.');
        halt(254);
  end;


  {rcg11172000 No overlay on Linux.}
  {
  ovrinit('bbs.OVR');
  ovrpath:=fsearch('bbs.OVR',getenv('PATH'));
  if (ovrresult<>ovrok) then
  begin
    clrscr; writeln('Critical error: Overlay manager error.'); halt(1);
  end;
  if (systat.useems) then
  begin
    ovrinitems; if (ovrresult=ovrok) then overlayinems:=TRUE;
  end;
  ovrsetbuf(ovrmaxsize); ovrsetretry(ovrmaxsize div 2);

  initexecswap2:=initexecswap;
  execwithswap2:=execwithswap;
  shutdownexecswap2:=shutdownexecswap;

  findvertypeout(ovrpath,vercs,vertype,vertypes,serialnumber,licenseinfo,sitedatetime);
  ver:=ver+' '+vertype;
  }

  init;

  if (packbasesonly) then
  begin
    wfcmdefine; doshowpackbases; thisuser.ac:=thisuser.ac-[pause]; nl;
    sprint(#3#5+'Message bases have been packed.');
    cursoron(TRUE); halt(0);
  end;
  mailread:=FALSE; smread:=FALSE;

  needtohangup:=wascriterr;           { hang up if critical error last call! }

  repeat
    write_msg:=FALSE;
    sysopon:=not systat.localsec;
    wantout:=not systat.localscreensec;
    checksnow:=systat.cgasnow;

    wfcmenus(needtohangup);
    needtohangup:=FALSE;

    useron:=FALSE; usernum:=0;
    if (not doneday) then
    begin
      if (getuser) then newuser;
      if (not hangup) then
      begin
        macok:=TRUE;
        if (not hangup) then logon;
        if (not hangup) then
        begin
          with thisuser do
          begin
            newdate:=laston;
            if (not mbaseac(lastmsg)) then lastmsg:=1;
            if (not fbaseac(lastfil)) then lastfil:=1;
            board:=lastmsg; fileboard:=lastfil;
          end;
          batchtime:=0.0; numbatchfiles:=0; numubatchfiles:=0; hiubatchv:=0;
          newcomptables;

          menustackptr:=0; for i:=1 to 8 do menustack[i]:='';

          last_menu:=systat.allstartmenu+'.MNU';

          if (not exist(systat.menupath+last_menu)) then
          begin
            sysoplog('"'+systat.menupath+last_menu+'" is MISSING.  Loaded "MAIN.MNU" instead.');
            last_menu:='main.mnu';
          end;
          curmenu:=systat.menupath+last_menu; readin;

          if (novice in thisuser.ac) then chelplevel:=2 else chelplevel:=1;
        end;

        newmenucmd:=''; i:=1;
        while ((i<=noc) and (newmenucmd='')) do
        begin
          if (cmdr[i].ckeys='FIRSTCMD') then
            if (aacs(cmdr[i].acs)) then newmenucmd:='FIRSTCMD';
          inc(i);
        end;
        execfirst:=(newmenucmd='FIRSTCMD');
        while (not hangup) do menuexec;    {*** main BBS loop ***}
      end;

      if (quitafterdone) then
      begin
        elevel:=exitnormal; hangup:=TRUE; doneday:=TRUE; needtohangup:=TRUE;
      end;
      logoff;
      if (not doneday) then sl1(#3#3+'Logoff '+#3#5+'['+dat+']');

      if (textrec(sysopf1).mode=fmoutput) then
      begin
        {$I-} close(sysopf1); {$I+}
        if (ioresult<>0) then writeln('Errors closing SLOGxxxx.LOG');
      end;

      if ((com_carrier) and (not doneday)) then
        if (spd<>'KB') then needtohangup:=TRUE;
      if (enddayf) then endday;
      enddayf:=FALSE;
    end;
  until (doneday);

  if (needtohangup) then hangupphone;
  reset(sysopf); close(sysopf);
  term_ready(TRUE); remove_port; {removeint(modemr.comport);}

  if (exist('bbsdone.bat')) then shelldos(FALSE,'bbsdone.bat',rcode);

  textcolor(7); clrscr; textcolor(14);
  WriteLn('[> Exited with ErrorLevel ',elevel,' at '+date+' '+time);
  {rcg11182000 added NormVideo()...}
  NormVideo();
  halt(elevel);
end.
