(*****************************************************************************)
(*>                                                                         <*)
(*>  SYSOP6  .PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  SysOp functions: Event editor                                          <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit sysop6;

interface

procedure eventedit;

implementation

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common,
  sysop1;

procedure eventedit;
var evf:file of eventrec;
    i1,i2,ii:integer;
    c:char;
    abort,next:boolean;
    s:astr;

  function onoff(b:boolean):astr;
  begin
    if b then onoff:='On ' else onoff:='Off';
  end;

  function dactiv(l:boolean; days:byte; b:boolean):astr;
  const dayss:string[7]='SMTWTFS';
  var s:astr;
      i:integer;
  begin
    if b then begin
      s:=cstr(days);
      if l then s:=s+' (monthly)' else s:=s+' mthly';
    end else begin
      s:='';
      for i:=6 downto 0 do
        if (days and (1 shl i)<>0) then
          s:=s+dayss[7-i] else s:=s+'-';
    end;
    if not l then s:=mln(s,7);
    dactiv:=s;
  end;

  function schedt(l:boolean; c:char):astr;
  begin
    case c of
      'A':if (l) then schedt:='ACS users' else schedt:='ACS';
      'C':if (l) then schedt:='Chat event' else schedt:='Cht';
      'D':if (l) then schedt:='DOS shell' else schedt:='DOS';
      'E':if (l) then schedt:='External' else schedt:='Ext';
      'P':if (l) then schedt:='Pack bases' else schedt:='Pak';
    end;
  end;

  procedure eed(i:integer);
  var x:integer;
  begin
    if (i>=1) and (i<=numevents) then begin
      dec(numevents);
      for x:=i to numevents do events[x]^:=events[x+1]^;
      rewrite(evf);
      for x:=1 to numevents do write(evf,events[x]^);
      close(evf);
      dispose(events[numevents+1]);   (* DISPOSE OF DYNAMIC MEMORY! *)
    end;
  end;

  procedure eei(i:integer);
  var x:integer;
  begin
    if (i>=1) and (i<=numevents+1) and (numevents<maxevents) then begin
      inc(numevents);
      new(events[numevents]);         (* DEFINE DYNAMIC MEMORY! *)
      for x:=numevents downto i do events[x]^:=events[x-1]^;
      with events[i]^ do begin
        active:=FALSE;
        description:='A NEW Telegard Event';
        etype:='D';
        execdata:='event.bat';
        busytime:=5;
        exectime:=0;
        busyduring:=TRUE;
        duration:=1;
        execdays:=0;
        monthly:=FALSE;
      end;
      rewrite(evf);
      for x:=1 to numevents do write(evf,events[x]^);
      close(evf);
    end;
  end;

  procedure eem;
  var ii,i,j:integer;
      c:char;
      s:astr;
      bb:byte;
      changed:boolean;
  begin
    prt('Begin editing at which? (1-'+cstr(numevents)+') : '); inu(ii);
    c:=' ';
    if (ii>=1) and (ii<=numevents) then begin
      while (c<>'Q') and (not hangup) do begin
        with events[ii]^ do
          repeat
            if (c<>'?') then begin
              cls;
              print('Event #'+cstr(ii)+' of '+cstr(numevents)); nl;
              print('!. Active     : '+syn(active));
              print('1. Description: '+description);
              print('2. Sched. type: '+schedt(TRUE,etype));
              print('3. Event data : '+execdata);
              print('4. Busy time  : '+
                    aonoff((busytime<>0),cstr(busytime)+' minutes','None.'));
              print('5. Exec. time : '+copy(ctim(exectime),4,5));
              print('6. Busy during: '+syn(busyduring));
              print('7. Duration   : '+cstr(duration));
              print('8. Days active: '+dactiv(TRUE,execdays,monthly));
            end;
            nl;
            prt('Edit menu (?=help) : ');
            onek(c,'Q!12345678[]FJL?'^M);
            nl;
            case c of
              '!':active:=not active;
              '1':begin
                    prt('New description: ');
                    mpl(30); inputwn(description,30,changed);
                  end;
              '2':begin
                    prt('New schedule type? [ACDEP] : ');
                    onek(c,'QACDEP'^M);
                    if (pos(c,'ACDEP')<>0) then etype:=c;
                  end;
              '3':begin
                    sprint(#3#5+'ACS: ACS string');
                    sprint(#3#5+'Cht: "0" if off, "1" if on');
                    sprint(#3#5+'DOS: Dos commandline');
                    sprint(#3#5+'Ext: Errorlevel to exit BBS with');
                    sprint(#3#5+'Pak: Pack The Message Bases');
                    nl;
                    prt('New event data: ');
                    mpl(20); inputwn(execdata,20,changed);
{*****
                    if s=' ' then
                      if pynq('Set to NULL string? ') then
                        execdata:=''
                    else if s<>'' then execdata:=s;
 *****}
                  end;
              '4':begin
                    prt('New busy time (0 for none) : ');
                    inu(i);
                    if not badini then busytime:=i;
                  end;
              '5':begin
                    sprint(#3#5+'All entries in 24 hour time.  Hour: (0-23), Minute: (0-59)');
                    nl;
                    prompt('New event time:');
                    prt('  Hour   : '); mpl(5); inu(i);
                    if not badini then begin
                      if (i<0) or (i>23) then i:=0;
                      prt('                 Minute : '); mpl(5); inu(j);
                      if not badini then begin
                        if (j<0) or (j>59) then j:=0;
                        exectime:=i*60+j;
                      end;
                    end;
                  end;
              '6':busyduring:=not busyduring;
              '7':begin
                    prt('New duration: '); mpl(5); inu(i);
                    if not badini then duration:=i;
                  end;
              '8':begin
                    if monthly then c:='M' else c:='W';
                    prt('[W]eekly or [M]onthly? ['+c+'] : ');
                    onek(c,'QWM'^M);
                    if c in ['M','W'] then monthly:=(c='M');
                    if c='M' then execdays:=1;
                    if monthly then begin
                      nl;
                      prt('What day of the month? (1-31) ['+cstr(execdays)+'] : ');
                      mpl(3); ini(bb);
                      if not badini then
                        if bb in [1..31] then execdays:=bb;
                    end else begin
                      nl;
                      sprint(#3#5+'Current: '+dactiv(TRUE,execdays,FALSE));
                      nl;
                      sprint(#3#5+'Modify by entering an "X" under days active.');
                      prt('[SMTWTFS]');
                      nl; prt(':'); mpl(7); input(s,7);
                      if s<>'' then begin
                        bb:=0;
                        for i:=1 to length(s) do
                          if s[i]='X' then
                            inc(bb,1 shl (7-i));
                        execdays:=bb;
                      end;
                    end;
                  end;
              '[':if (ii>1) then dec(ii) else c:=' ';
              ']':if (ii<numevents) then inc(ii) else c:=' ';
              'F':if (ii<>1) then ii:=1 else c:=' ';
              'J':begin
                    prt('Jump to entry: ');
                    input(s,3);
                    if (value(s)>=1) and (value(s)<=numevents) then ii:=value(s) else c:=' ';
                  end;
              'L':if (ii<>numevents) then ii:=numevents else c:=' ';
              '?':ee_help;
            end;
          until ((c in ['Q','[',']','F','J','L']) or (hangup));
      end;
      reset(evf);
      for ii:=1 to numevents do write(evf,events[ii]^);
      close(evf);
    end;
  end;

  procedure eep;
  var i,j,k:integer;
  begin
    prt('Move which event? (1-'+cstr(numevents)+') : '); inu(i);
    if ((not badini) and (i>=1) and (i<=numevents)) then begin
      prt('Move before which event? (1-'+cstr(numevents+1)+') : '); inu(j);
      if ((not badini) and (j>=1) and (j<=numevents+1) and
          (j<>i) and (j<>i+1)) then begin
        eei(j);
        if (j>i) then k:=i else k:=i+1;
        events[j]^:=events[k]^;
        if (j>i) then eed(i) else eed(i+1);
      end;
    end;
  end;

begin
  assign(evf,systat.gfilepath+'events.dat');
  c:=#0;
  repeat
    if c<>'?' then begin
      cls; abort:=FALSE;
      printacr(#3#3+' NN'+sepr2+'Description                   '+
               sepr2+'Typ'+sepr2+'Bsy'+sepr2+'Time '+sepr2+'Len'+sepr2+'Days   '+
               sepr2+'ExecData',abort,next);
      printacr(#3#4+' ==:==============================:===:===:=====:===:=======:============',abort,next);
      ii:=1;
      while (ii<=numevents) and (not abort) do
        with events[ii]^ do begin
          if (active) then s:=#3#5+'+' else s:=#3#1+'-';
          s:=s+#3#0+mn(ii,2)+' '+#3#3+mln(description,30)+' '+
              schedt(FALSE,etype)+' '+
              #3#5+mn(busytime,3)+' '+copy(ctim(exectime),4,5)+' '+
              mn(duration,3)+' '+dactiv(FALSE,execdays,monthly)+' '+
              #3#3+mln(execdata,9);
          printacr(s,abort,next);
          inc(ii);
        end;
    end;
    nl;
    prt('Event editor (?=help) : ');
    onek(c,'QDIMP?'^M);
    case c of
      '?':begin
            nl;
            sprint('<^3CR^1>Redisplay screen');
            lcmds(13,3,'Delete event','Insert event');
            lcmds(13,3,'Modify event','Position event');
            lcmds(13,3,'Quit','');
          end;
      'D':begin
            prt('Event to delete? (1-'+cstr(numevents)+') : '); inu(ii);
            if (ii>=1) and (ii<=numevents) then begin
              nl; sprint('Event: '+#3#4+events[ii]^.description);
              if pynq('Delete this? ') then begin
                sysoplog('* Deleted event: '+events[ii]^.description);
                eed(ii);
              end;
            end;
          end;
      'I':begin
            prt('Event to insert before? (1-'+cstr(numevents+1)+') : '); inu(ii);
            if (ii>=1) and (ii<=numevents+1) then begin
              sysoplog('* Inserted new event');
              eei(ii);
            end;
          end;
      'M':eem;
      'P':eep;
    end;
  until (c='Q') or (hangup);
end;

end.
