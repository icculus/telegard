(*****************************************************************************)
(*>                                                                         <*)
(*>  MISC1   .PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  Various miscellaneous functions used by the BBS.                       <*)
(*>                                                                         <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit misc1;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common;

procedure reqchat(x:astr);
procedure TimeBank(s:astr);
function ctp(t,b:longint):astr;
procedure vote;

implementation

uses mail2;

procedure reqchat(x:astr);
var c,ii,i:integer;
    r:char;
    chatted:boolean;
    s,why:astr;
begin
  why:='';
  if (pos(';',x)<>0) then why:=copy(x,pos(';',x)+1,length(x));
  if (why='') then why:='^3Why do you want to chat?';
  nl;
  if ((chatt<systat.maxchat) or (cso)) then begin
    sprint(why);
    chatted:=FALSE;

    prt(':'); mpl(70); inputl(s,70);

    if (s<>'') then begin
      inc(chatt);
      if ((not sysop) or (rchat in thisuser.ac)) then
        if (length(s)<64) then
          sysoplog(#3#4+'Chat attempt: "'+#3#5+s+#3#4+'"')
        else begin
          sysoplog(#3#4+'Chat attempt:');
          sl1(#3#4+' "'+#3#5+s+#3#4+'"');
        end
      else begin
        sl1(#3#4+'Chat: "'+#3#5+s+#3#4+'"');
        commandline('Press <SPACE> to chat or <ENTER> to SHUT UP for rest of call');
        nl;
        sprint(fstring.chatcall1);
        nl;
        ii:=0; c:=0;
        repeat
          inc(ii);
          if (outcom) then sendcom1(^G);
          sprompt(fstring.chatcall2);
          if (outcom) then sendcom1(^G);
          if (shutupchatcall) then delay(1500)
          else
            for i:=1 to 5 do begin
              sound(800); delay(33);
              sound(1300); delay(35);
              sound(1700); delay(37);
              sound(2100); delay(39);
              sound(3200); delay(45);
              sound(2100); delay(39);
              sound(1700); delay(37);
              sound(1300); delay(35);
              sound(800);
            end;
          nosound;
          if (keypressed) then begin
            r:=readkey;
            case r of
              #32:begin
                    commandline('');
                    chatted:=TRUE; chatt:=0;
                    pap:=0;
                    chat;
                  end;
               ^M:shutupchatcall:=TRUE;
            end;
          end;
        until ((chatted) or (ii=9) or (hangup));
        commandline('');
      end;
      if (not chatted) then begin
        chatr:=s;
        printf('nosysop');
        if (value(x)<>0) then begin
          irt:='Tried chatting.';
          imail(value(x));
        end;
      end else
        chatr:='';
      tleft;
    end;
  end else begin
    printf('goaway');
    irt:='Tried chatting (more than '+cstr(systat.maxchat)+' times!)';
    sysoplog('Tried chatting more than '+cstr(systat.maxchat)+' times');
    imail(value(x));
  end;
end;

procedure TimeBank(s:astr);
var lng,maxperday,maxever:longint;
    zz:integer;
    oc:astr;
    c:char;

  function cantdeposit:boolean;
  begin
    cantdeposit:=TRUE;
    if ((thisuser.timebankadd>=maxperday) and (maxperday<>0)) then exit;
    if ((thisuser.timebank>=maxever) and (maxever<>0)) then exit;
    cantdeposit:=FALSE;
  end;

begin
  maxperday:=value(s); maxever:=0;
  if (pos(';',s)<>0) then maxever:=value(copy(s,pos(';',s)+1,length(s)));
  if ((maxever<>0) and (thisuser.timebank>maxever)) then
    thisuser.timebank:=maxever;
  nl; nl;
  sprint('^5Telegard Time Bank v'+ver);
  nl;
  if (not cantdeposit) then
    sprint('^3A^1)dd time to your account.');
  sprint('^3G^1)oodbye, log off now.');
  sprint('^3Q^1)uit to BBS.');
  if (choptime=0.0) then
    sprint('^3W^1)ithdraw time from your account.');
  nl;
  if (choptime<>0.0) then
    sprint(#3#7+'You cannot withdraw time during this call.');
  if (cantdeposit) then begin
    if ((thisuser.timebankadd>=maxperday) and (maxperday<>0)) then
      sprint(#3#7+'You cannot add any more time to your account today.');
    if ((thisuser.timebank>=maxever) and (maxever<>0)) then
      sprint(#3#7+'You cannot add any more time to your account!');
  end;
  nl;
  sprompt(#3#5+'In your account: '+#3#3+cstr(thisuser.timebank)+
          #3#5+'   Time left online: '+#3#3+cstr(trunc(nsl) div 60));
  if (thisuser.timebankadd<>0) then
    sprompt('   ^5Deposited today: ^3'+cstr(thisuser.timebankadd));
  nl;
  sprompt(#3#5+'Account limits: '+#3#3);
  if (maxever<>0) then sprompt(cstr(maxever)+' max')
    else sprompt('No max limit');
  if (maxperday<>0) then sprompt(' / '+cstr(maxperday)+' per day');
  nl; nl;
  prt('Time Bank :');
  oc:='QG';
  if (choptime=0.0) then oc:=oc+'W';
  if (not cantdeposit) then oc:=oc+'A';
  onek(c,oc);
  case c of
    'A':begin
          prt('Add how many minutes? '); inu(zz); lng:=zz;
          nl;
          if (not badini) then
            if (lng>0) then
              if (lng>trunc(nsl) div 60) then
                sprint(#3#7+'You don''t have that much time left to deposit!')
              else
                if (lng+thisuser.timebankadd>maxperday) and (maxperday<>0) then
                  sprint(#3#7+'You can only add '+cstr(maxperday)+' minutes to your account per day!')
                else
                  if (lng+thisuser.timebank>maxever) and (maxever<>0) then
                    sprint(#3#7+'Your account deposit limit is '+cstr(maxever)+' minutes!')
                  else begin
                    inc(thisuser.timebankadd,lng);
                    inc(thisuser.timebank,lng);
                    dec(thisuser.tltoday,lng);
                    sprint('^5In your account: ^3'+cstr(thisuser.timebank)+
                           '^5   Time left online: ^3'+cstr(trunc(nsl) div 60));
                    sysoplog('TimeBank: Deposited '+cstr(lng)+' minutes.');
                  end;
              end;
          'G':hangup:=TRUE;
          'W':begin
                prt('Withdraw how many minutes? '); inu(zz); lng:=zz;
                nl;
                if (not badini) then
                  if (lng>thisuser.timebank) then
                    sprint(#3#7+'You don''t have that much time left in your account!')
                  else
                    if (lng>0) then begin
                      dec(thisuser.timebankadd,lng);
                      if (thisuser.timebankadd<0) then thisuser.timebankadd:=0;
                      dec(thisuser.timebank,lng);
                      inc(thisuser.tltoday,lng);
                      sprint('^5In your account: ^3'+cstr(thisuser.timebank)+
                             '^5   Time left online: ^3'+cstr(trunc(nsl) div 60));
                      sysoplog('TimeBank: Withdrew '+cstr(lng)+' minutes.');
                    end;
                  end;
  end;
end;

function ctp(t,b:longint):astr;
var s,s1:astr;
    n:real;
begin
  if ((t=0) or (b=0)) then begin
    ctp:='  0.0%';
    exit;
  end;
  n:=(t*100)/b;
  str(n:5:1,s);
  s:=s+'%';
  ctp:=s;
(*
  s:=cstr((t*100) div b);
  if (length(s)=1) then s:=' '+s;
  s:=s+'.';
  if (length(s)=3) then s:=' '+s;
  n:=t/(b+0.0005);
  s1:=cstr(trunc(n*1000) mod 10);
  ctp:=s+s1+'%';
*)
end;

function vote1x(answeringall:boolean; qnum:integer; var vd:vdatar):boolean;
var s,pva:astr;
    i,tv:integer;
    c:char;
    abort,next,changed,doneyet,b:boolean;

  procedure showvotes(stats,nocom:boolean);
  var s:astr;
      i:integer;
  begin
    cls;
    sprint('Current standings for Question #'+cstr(qnum)+' :');
    nl; sprint(#3#7+vd.question); nl;
    tv:=0;
    for i:=1 to vd.numa do inc(tv,vd.answ[i].numres);
    if (tv=0) then tv:=1;
    sprint('Users voting: '+#3#3+ctp(tv,systat.numusers)); nl;
    abort:=FALSE; i:=1;
    if (nocom) then begin
      sprint(#3#0+'  0:No Comment');
      pva:='Q0';
    end else
      pva:='';
    while (i<=vd.numa) do begin
      if (not abort) then begin
        s:=#3#5+cstr(i)+#3#7+':'+#3#3+vd.answ[i].ans;
        if (stats) then
          s:=mln(s,41+length(cstr(i)))+#3#4+' :'+#3#0+mn(vd.answ[i].numres,3)+
             #3#4+':'+#3#0+ctp(vd.answ[i].numres,tv)+#3#4+':';
        if (i=thisuser.vote[qnum]) then s:=#3#8+'*'+s else s:=' '+s;
        printacr(' '+s,abort,next);
      end;
      pva:=pva+cstr(i);
      inc(i);
    end;
  end;

begin
  changed:=FALSE;
  if (vd.numa<>0) then begin
    doneyet:=(thisuser.vote[qnum]<>0);
    showvotes(doneyet,not systat.forcevoting);
    nl;
    sprint(#3#5+'Your vote: '+#3#3+vd.answ[thisuser.vote[qnum]].ans);
    if (not (rvoting in thisuser.ac)) and (not hangup) then begin
      if (answeringall) then b:=TRUE else b:=pynq('Change it? ');
      if (b) then begin
        nl; prt('Which number (0-'+cstr(vd.numa)+') ? ');
        onek(s[1],pva);
        s[0]:=#1; i:=value(s);
        if (s<>'') and (i>=0) and (i<=vd.numa) then begin
          if (thisuser.vote[qnum]<>0) then
            dec(vd.answ[thisuser.vote[qnum]].numres);
          thisuser.vote[qnum]:=i;
          if (i<>0) then inc(vd.answ[i].numres);
          changed:=TRUE;

          if (not answeringall) then showvotes(TRUE,FALSE);
        end;
      end;
    end;
  end else
    if (not answeringall) then print('Inactive question.');
  vote1x:=changed;
end;

procedure vote;
var vdata:file of vdatar;
    vd:vdatar;
    i,j,int2,vna:integer;
    s,i1,ij:astr;
    abort,next,done,lq,waschanged:boolean;

  procedure getvote(qnum:integer);
  begin
    seek(vdata,qnum-1); read(vdata,vd);
  end;

  procedure vote1(answeringall:boolean; qnum:integer);
  begin
    getvote(qnum);
    if (vote1x(answeringall,qnum,vd)) then begin
      seek(vdata,qnum-1);
      write(vdata,vd);
      waschanged:=TRUE;
    end;
  end;

begin
  s:=''; done:=FALSE; lq:=TRUE; waschanged:=FALSE;
  assign(vdata,systat.gfilepath+'voting.dat');
  {$I-} reset(vdata); {$I+}
  if (ioresult<>0) then print('No voting today.')
  else begin
    sysoplog('Entered voting booths');
    repeat
      done:=FALSE;
      ij:='Q?';
      abort:=FALSE;
      if (lq) then begin
        cls;
        printacr(#3#5+'Current Questions:',abort,next);
        nl;
      end;
      int2:=0;
      for i:=1 to numvoteqs do begin
        seek(vdata,i-1); read(vdata,vd);
        if vd.numa<>0 then begin
          inc(int2);
          if (lq) and (not abort) then begin
            if (thisuser.vote[i]=0) then i1:=#3+#8+'* ' else i1:='  ';
            i1:=i1+#3#5+cstr(i)+#3#7+': '+#3#3+vd.question;
            printacr(i1,abort,next);
          end;
          ij:=ij+cstr(i);
        end;
      end;
      lq:=FALSE;
      if (int2=0) then begin
        print('No voting questions now.');
        done:=TRUE;
      end else begin
        nl;
        prt('Which question (##,L:ist,A:nswer all,Q:uit) : ');
        input(s,2);
        i:=value(s);
        if (s='A') then begin
          j:=0;
          i:=1;
          while ((i<=numvoteqs) and (not hangup)) do begin
            getvote(i);
            if ((vd.numa<>0) and (thisuser.vote[i]=0)) then begin
              vote1(TRUE,i);
              inc(j);
            end;
            inc(i);
          end;
          if (j=0) then begin nl; sprint(#3#7+'No more questions need answering!'); end;
        end;
        if ((s='Q') or (s='')) then done:=TRUE;
        if ((s='L') or (s='?')) then lq:=TRUE;
        if (i>=1) and (i<=numvoteqs) then vote1(FALSE,i);
      end;
      if (systat.forcevoting) and (done) then begin
        vna:=0;
        for i:=1 to numvoteqs do begin
          seek(vdata,i-1); read(vdata,vd);
          if ((vd.numa<>0) and (thisuser.vote[i]=0)) then inc(vna);
        end;
        if (vna<>0) then begin
          nl;
          print('Voting is mandatory - all questions must be answered.');
          done:=FALSE;
        end;
      end;
    until (done) or (hangup);

    close(vdata);

    if (waschanged) then begin
      nl;
      sprint(#3#3+fstring.thanxvote);
    end;
  end;
end;

end.
