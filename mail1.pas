{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit mail1;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common,timejunk;

function inmsg(pub,uti:boolean; ftit:string; var mixr:msgindexrec;
               var mheader:mheaderrec):boolean;
procedure inli(var i:string);

implementation

uses mail0;

var
  inmsgfile:text;
  cmdsoff:boolean;
  lastline:string;

function inmsg(pub,uti:boolean; ftit:string; var mixr:msgindexrec;
               var mheader:mheaderrec):boolean;
var li:array[1..160] of astr;
    upin:string[255];
    an:anontyp;
    mftit,fto,spc,s,s1,s2:string;
    t,maxli,lc,ii,i,j,k,quoteli:integer;
    c,c1:char;
    cantabort,saveline,goquote,exited,save,abortit,abort,next,ptl1,ufo:boolean;

  procedure listit(stline:integer; linenum,disptotal:boolean);
  var lasts:string;
      l:integer;
  begin
    if (disptotal) then nl;
    l:=stline;
    abort:=FALSE;
    next:=FALSE;
    dosansion:=FALSE;
    lasts:='';

    while ((l<lc) and (not abort)) do begin
      if (linenum) then print(cstr(l)+':');
      if ((pos(^[,li[l])=0) and (pos(^[,lasts)=0)) then dosansion:=FALSE;

      reading_a_msg:=TRUE;
      if ((pub) and (aacs(memboard.mciacs))) then read_with_mci:=TRUE;
      printacr(li[l],abort,next);
      read_with_mci:=FALSE;
      reading_a_msg:=FALSE;

      lasts:=li[l];
      inc(l);
    end;

    dosansion:=FALSE;
    if (disptotal) then
      sprint('  ^3Total number of lines were: ^4[^3'+cstr(lc-1)+'^4] ');
    saveline:=FALSE;
  end;

  {rcg11172000 had to change this to get it compiling under Free Pascal...}
  {procedure rpl(var v:astr; old,new:astr);}
  procedure rpl(var v:astr; old,_new:astr);
  var p:integer;
  begin
    p:=pos(old,v);
    if (p>0) then begin
      insert(_new,v,p+length(old));
      delete(v,p,length(old));
    end;
  end;

  procedure ptl;
  var u:userrec;
      sr:smalrec;
      s,s1:astr;
      i,j,tl:integer;
      aa,aa1,done,ufo,sfo:boolean;
  begin
    tl:=60;
    s1:='';
    nl;
    if ((not ptl1) or (ftit<>'')) then begin
      if (ftit<>'') then begin
        prt('Subject: ');
        print(mftit);
      end else begin
        prt('Old:   ');
        print(mftit);
      end;
    end else if ((pub) and (uti)) then begin
      if (allcaps(copy(lastmheader.title,1,3))<>'RE:') then
        s1:='Re: '+copy(lastmheader.title,1,64) else
        s1:=lastmheader.title;
      sprint(#3#5+'Hit Enter to use the default title of:');
      nl;
      prt('Reply: ');
      print(s1);
    end;
    if (ftit='') then begin
      prt('Subject: ');
      mpl(tl);
      inputmain(s,tl,'l');
      if (s<>'') then begin
        cl(1);
        nl;
        mftit:=s
      end else begin
        if (s1<>'') then begin
          mftit:=s1;
          cl(6);
          prompt(mftit);
          cl(1);
          nl;
        end;
        if (ptl1) then exit else begin
          cl(6);
          prompt(mftit);
          cl(1);
          nl;
        end;
      end;
    end;
    if ((pub) and (ptl1) and (fto<>'')) then begin
      nl;
      prt('To:    ');
      cl(6);
      s:=fto;
      if (mbrealname in memboard.mbstat) then begin
        if (mheader.toi.real<>'') then begin
          s:=caps(mheader.toi.real);
          if (memboard.mbtype=0) then s:=s+' #'+cstr(mheader.toi.usernum);
        end else
          s:='';
      end;
      prompt(s);
      for i:=1 to 50-length(s) do
        prompt(' ');
      nl;
      ptl1:=FALSE;
      exit;
    end;
    if ((pub) and (not uti)) then begin
      nl;
      sprint(#3#5+'Address message to what person/people?');
      sprompt(#3#5+'Press <CR> to leave ');
      if (fto='') then sprint('unaddressed.') else sprint('unchanged.');
      nl;
      if (not ptl1) then begin
        prt('Old:   ');
        print(fto);
      end;
      prt('Reciever:    ');
      mpl(50);
      inputmain(s,50,'lp');
      cl(6);
      for i:=1 to length(s) do
        prompt(^H' '^H);
      aa1:=FALSE;
      if (s<>'') then begin
        fto:=s;
        if (copy(s,1,1)='#') then s:=copy(s,2,length(s)-1);
        val(s,i,j);
        if ((i<>0) and (j=0)) then begin
          ufo:=(filerec(uf).mode<>fmclosed);
          if (not ufo) then reset(uf);
          if ((i>=1) and (i<=filesize(uf)-1)) then begin
            seek(uf,i);
            read(uf,u);
            fto:=caps(u.name)+' #'+cstr(i);
            if (pub) then begin
              if (mbrealname in memboard.mbstat) then fto:=caps(u.realname)
                else fto:=caps(u.name);
              if (memboard.mbtype=0) then fto:=fto+' #'+cstr(i);
            end;
          end else begin
            prompt(s);
            cl(1);
            nl;
            print('Unable to find user number (left unaddressed).');
            fto:='';
            aa1:=TRUE;
          end;
          if (not ufo) then close(uf);
        end;
      end;
      aa:=(sqoutsp(fto)='');
      if (allcaps(sqoutsp(fto))='Everyone') then aa:=TRUE;
      if (aa) then fto:='All';

      if (not aa1) then begin
        prompt(fto);
        cl(1);
        nl;
      end;

      if (pap<>0) then nl;
      nl;
      if (not ptl1) then sprint(#3#0+'Please continue message...');
    end;
    ptl1:=FALSE;
  end;

  procedure rpl1;
  begin
    if (lc<=1) then sprint(#3#7+'Nothing to replace!') else begin
      sprint(#3#5+'Replace string -');
      nl;
      prt('On which line (1-'+cstr(lc-1)+') ? ');
      input(s,4);
      if (value(s)<1) or (value(s)>lc-1) then
        sprint(#3#7+'Invalid line number.')
      else begin
        nl;
        sprint(#3#3+'Original line:');
        abort:=FALSE;
        next:=FALSE;
        printacr(li[value(s)],abort,next);
        nl;
        sprint(#3#4+'Enter character(s) to replace:');
        prt(':');
        inputl(s1,78);
        if (s1<>'') then
          if (pos(s1,li[value(s)])=0) then
            sprint(#3#7+'Character(s) not found.')
          else begin
            sprint(#3#4+'Enter replacement character(s):');
            prt(':');
            inputl(s2,78);
            if (s2<>'') then begin
              rpl(li[value(s)],s1,s2);
              nl;
              sprint(#3#3+'Edited line:');
              abort:=FALSE;
              next:=FALSE;
              printacr(li[value(s)],abort,next);
            end;
          end;
      end;
      nl;
    end;
  end;

  procedure doquote;
  var f:text;
      t1:integer;
      s:string[80];
      done:boolean;

    procedure openquotefile;
    begin
      done:=FALSE;
      assign(f,'msgtmp');
      {$I-} reset(f); {$I+}
      if (ioresult<>0) then done:=TRUE;
    end;

    procedure readquoteline;
    begin
      if eof(f) then done:=TRUE else begin
        {$I-} readln(f,s); {$I+}
        if (ioresult<>0) then done:=TRUE;
      end;
    end;

    procedure gotoquoteline(b:boolean);
    begin
      if (b) then begin
        close(f);
        openquotefile;
      end;
      if (not done) then begin
        t1:=0;
        repeat
          inc(t1);
          readquoteline;
        until ((t1=quoteli) or (done));
      end;
      if (done) then quoteli:=1;
    end;

    procedure beginquote;
    begin
      if (lc>maxli) then done:=TRUE else begin
        li[lc]:=('----------Begin Quote----------');
        inc(lc);
        end;
      end;

    procedure endquote;
    begin
      if (lc>maxli) then done:=TRUE else begin
        li[lc]:=('-----------End Quote-----------');
        inc(lc);
        end;
      end;

  begin
    beginquote;
    openquotefile;
    if (not done) then begin
      done:=FALSE;
      gotoquoteline(FALSE);
      if (not done) then repeat
        if (memboard.mbtype=0) then sprompt(#3+cstr(fidor.quote_color))
          else sprompt(#3+cstr(memboard.quote_color));
        sprint(s);
        sprompt('[A]dd line [S]kip Line [P]revious Line [Q]uit :');
        repeat
          getkey(c1);
          c1:=upcase(c1);
        until (c1 in ['A','S','Q','P','?',^M]);
        for t1:=1 to 60 do
          prompt(^H' '^H);
        sprompt(#3#3);
        case c1 of
          'A':begin
                if (lc>maxli) then done:=TRUE else begin
                  li[lc]:=s;
                  inc(quoteli);
                  inc(lc);
                  readquoteline;
                  if (done) then dec(quoteli);
                end;
              end;
       ^M,'S':begin
                inc(quoteli);
                readquoteline;
                if (done) then dec(quoteli);
              end;
          'P':if (quoteli>1) then begin
                dec(quoteli);
                gotoquoteline(TRUE);
              end;
          'Q':done:=TRUE;
          end;
      until (done);
      endquote;
    end;
    {$I-} close(f); {$I+}
  end;

  procedure printmsgtitle;
  begin
    nl;
    sprint(fstring.entermsg1);
    sprint(fstring.entermsg2);
    cl(3);
    if (okansi) then
    print(copy('/-------------------------------------\_/-------------------------------------\',
      1,thisuser.linelen)) else
    print(copy('/-------------------------------------\_/-------------------------------------\',
      1,thisuser.linelen));
  end;

  procedure inputthemessage;
  var t1:integer;
  begin
    cmdsoff:=FALSE;
    abort:=FALSE;
    next:=FALSE;
    ptl1:=TRUE;
    goquote:=FALSE;
    quoteli:=1;
    if (freek(exdrv(systat.msgpath))<systat.minspaceforpost) then begin
      mftit:='';
      nl;
      print('Not enough disk space to save a message.');
      c:=chr(exdrv(systat.msgpath)+64);
      if (c='@') then sysoplog(#3#8+'>>>>'+#3#3+' Main BBS drive full!  Insufficient space to save a message!')
        else sysoplog(#3#8+'>>>>'+#3#3+' '+c+': drive full!  Insufficient space to save a message!');
    end else begin
      lc:=1;
      spc:='                                                                              ';
      lastline:='';
      if cso then maxli:=systat.csmaxlines
        else maxli:=systat.maxlines;
      ptl;
    end;
    if (mftit='') then
      if (not cantabort) then begin
        save:=FALSE;
        exit;
      end;
    printmsgtitle;
    repeat
      repeat
        saveline:=TRUE;
        nofeed:=FALSE;
        exited:=FALSE;
        save:=FALSE;
        abortit:=FALSE;
        write_msg:=TRUE;
        inli(s);
        write_msg:=FALSE;
        if (s='/'^H) then begin
          saveline:=FALSE;
          if (lc<>1) then begin
            dec(lc);
            lastline:=li[lc];
            if (copy(lastline,length(lastline),1)=#1) then
              lastline:=copy(lastline,1,length(lastline)-1);
            sprint(#3#0+'Backed up to line '+cstr(lc)+':');
          end;
        end;
        if (s='/') then begin
          sprompt('^3Command (^0?^3=^0help^3) : ^3');
          getkey(c);
          for t1:=1 to 19 do
            prompt(^H' '^H);
          saveline:=FALSE;
          case upcase(c) of
            '/','\':begin
                  if (mso) then sprompt(#3#0+'[C]enter [T]itle [U]pload : ')
                    else sprompt(#3#0+'[C]enter [T]itle : ');
                  getkey(c1); c1:=upcase(c1);
                  if (mso) then for t1:=1 to 28 do prompt(^H' '^H)
                           else for t1:=1 to 19 do prompt(^H' '^H);
                  if (c1 in ['C','T']) then begin
                    sprint(#3#3+c1+#3#1+':'+#3#3);
                    inli(s);
                    if (s<>'') then begin
                      case c1 of
                        'C':s:=#2+s;
                        'T':s:=BOXEDTITLE+s;
                      end;
                      saveline:=TRUE;
                    end;
                  end;
                  if ((not hangup) and (c1='U') and (mso)) then begin
                    prt('Enter file name to upload: ');
                    mpl(40);
                    inputl(s,40);
                    if ((s<>'') and (not hangup)) then begin
                      assign(inmsgfile,s);
                      {$I-} reset(inmsgfile); {$I+}
                      if (ioresult<>0) then
                        print('File not found.')
                      else begin
                        inmsgfileopen:=TRUE;
                        cmdsoff:=TRUE;
                      end;
                    end;
                  end;
                end;
            '?','H':printf('prhelp');
            'A':if (not cantabort) then
                  if pynq('@M^7Abort message? ') then begin
                    exited:=TRUE;
                    abortit:=TRUE;
                  end else
                    sprint(#3#0+'Nothing done.@M');
            'C':if pynq('@M^7Clear message? ') then begin
                  sprint(#3#0+'Message cleared.... Start over...');
                  lc:=1;
                end else
                  sprint(#3#0+'Nothing done.@M');
            'E':exited:=TRUE;
            'L':listit(1,pynq('@M^7List message with line numbers? '),TRUE);
            'O':printf('color');
            'P':rpl1;
            'Q':if (not exist('msgtmp')) then
                  sprint(#3#0+'You are not replying to a message.@M')
                else
                  goquote:=TRUE;
            'R':if (lc>1) then begin
                  sprint(#3#0+'Last line deleted.  Continue:'+#3#1);
                  dec(lc);
                end;
            'S':if ((not cantabort) or (lc>1)) then begin
                  exited:=TRUE;
                  save:=TRUE;
                end;
            'T':ptl;
          end;
        end;

        if (goquote) then begin
          doquote;
          goquote:=FALSE;
          cls;
          sprint(#3#0+'Quoting complete.  Continue:');
          printmsgtitle;
          if (lc>1) then
            if (lc>10) then listit(lc-10,FALSE,FALSE)
              else listit(1,FALSE,FALSE);
        end;

        if (saveline) then begin
          li[lc]:=s;
          inc(lc);
          if (lc>maxli) then begin
            print('You have used up your maximum amount of lines.');
            if (inmsgfileopen) then begin
              inmsgfileopen:=FALSE;
              cmdsoff:=FALSE;
              close(inmsgfile);
            end;
            exited:=TRUE;
          end;
        end;
      until ((exited) or (hangup));
      if (hangup) then abortit:=TRUE;
      if ((not abortit) and (not save)) then
        repeat
          prt(#3#3+'Message editor (^0?^3=^0help^3) : ');
          onek(c,'SACDILRTU?'); nl;
          case c of
            '?':begin
                  lcmds(15,3,'List message','Continue message');
                  lcmds(15,3,'Save message','Abort message');
                  lcmds(15,3,'Delete line','Insert line');
                  lcmds(15,3,'Replace line','Update line');
                  lcmds(15,3,'Title re-do','');
                end;
            'A':if (not cantabort) then
                  if pynq('Abort message? ') then abortit:=TRUE
                    else c:=' ';
            'C':if (lc>maxli) then begin
                  sprint(#3#7+'Too many lines!');
                  c:=' ';
                end else
                  sprompt(#3#0+'Continue...');
            'D':begin
                  prt('Delete which line (1-'+cstr(lc-1)+') ? ');
                  input(s,4);
                  t:=value(s);
                  if (t>0) and (t<lc) then begin
                    for t1:=t to lc-2 do
                      li[t1]:=li[t1+1];
                    dec(lc);
                  end;
                end;
            'I':if (lc<maxli) then begin
                  prt('Insert before which line (1-'+cstr(lc-1)+') ? ');
                  input(s,4);
                  t:=value(s);
                  if (t>0) and (t<lc) then begin
                    for t1:=lc downto t+1 do li[t1]:=li[t1-1];
                    inc(lc);
                    sprint(#3#3+'New line:');
                    inli(li[t]);
                  end;
                end else
                  sprint(#3#7+'Too many lines!');
            'L':listit(1,pynq('With line numbers? '),TRUE);
            'R':begin
                  prt('Line number to replace (1-'+cstr(lc-1)+') ? ');
                  input(s,4);
                  t:=value(s);
                  if ((t>0) and (t<lc)) then begin
                    abort:=FALSE;
                    nl;
                    sprint(#3#3+'Old line:');
                    printacr(li[t],abort,next);
                    sprint(#3#3+'Enter new line:');
                    inli(s);
                    if (li[t][length(li[t])]=#1) and
                       (s[length(s)]<>#1) then li[t]:=s+#1 else li[t]:=s;
                  end;
                end;
            'S':if ((not cantabort) or (lc>1)) then
                  save:=TRUE;
            'T':ptl;
            'U':rpl1;
          end;
          nl;
        until (c in ['A','C','S']) or (hangup);
    until ((abortit) or (save) or (hangup));
    if (lc=1) then begin
      abortit:=TRUE;
      save:=FALSE;
    end;
  end;

  function getorigin:string;
  var s:astr;
  begin
    if (memboard.origin<>'') then s:=memboard.origin
      else if (fidor.origin<>'') then s:=fidor.origin
        else s:=copy(stripcolor(systat.bbsname),1,50);
    while (copy(s,length(s),1)=' ') do
      s:=copy(s,1,length(s)-1);
    getorigin:=s;
  end;

  procedure saveit;
  var t:text;
      i,j,qcolor,tcolor:integer;
      c:char;
      s:astr;

    function getaddr(zone,net,node,point:integer):string;
    begin
      getaddr:=cstr(zone)+':'+cstr(net)+'/'+cstr(node)+'.'+cstr(point)+')';
    end;

  begin
    mheader.msglength:=0;
    with memboard do begin
      if (mbtype in [1,2]) then begin
        qcolor:=quote_color;
        tcolor:=text_color;
      end else begin
        qcolor:=fidor.quote_color;
        tcolor:=fidor.text_color;
      end;
      assign(t,'tgtemp1.$$$'); rewrite(t);
      if ((pub) and (mbfilter in mbstat)) then begin
        for i:=1 to lc-1 do
          if length(li[i])>0 then begin
            li[i]:=stripcolor(li[i]);
            for j:=1 to length(li[i]) do begin
              c:=li[i][j];
              if (c in [#0..#1,#3..#31,#127..#255]) then c:='*';
              li[i][j]:=c;
            end;
          end;
      end;
      for i:=1 to lc-1 do begin
        s:=li[i];
        j:=pos('>',stripcolor(s));
        if ((not pub) or (mbtype=0) or (copy(s,1,3)='`#[') or (s[1]=#2))
          then j:=0;
        if ((j>0) and (j<=5)) then s:=#3+cstr(qcolor)+s+#3+cstr(tcolor);
        writeln(t,s);
        inc(mheader.msglength,length(s)+2);
      end;
      if ((pub) and (mbtype in [1,2]) and (mbaddtear in mbstat)) then begin
        writeln(t,'');
        inc(mheader.msglength,2);
        s:=#3+cstr(tear_color)+'--- Telegard v'+ver;
        writeln(t,s);
        inc(mheader.msglength,length(s)+2);
        s:=#3+cstr(origin_color)+' * Origin: '+getorigin+' (';
        if (zone<>0) then s:=s+getaddr(zone,net,node,point)
          else s:=s+getaddr(fidor.zone,fidor.net,fidor.node,fidor.point);
        writeln(t,s);
        inc(mheader.msglength,length(s)+2);
      end;
      close(t);
      outmessagetext('tgtemp1.$$$',mheader,TRUE);
    end;
  end;

  procedure readytogo;
  var f:file;
  begin
    if (exist('msgtmp')) then begin
      assign(f,'msgtmp');
      {$I-} reset(f); {$I+}
      if (ioresult=0) then begin
        close(f);
        erase(f);
      end;
    end;
  end;

begin
  inmsg:=FALSE;
  if (uti) then fto:=caps(mheader.toi.as)
    else fto:='';
  if (ftit<>'') then mftit:=ftit
    else mftit:='';
  if (copy(mftit,1,1)='\') then begin
    mftit:=copy(mftit,2,length(mftit)-1);
    cantabort:=TRUE;
  end else
    cantabort:=FALSE;
  inputthemessage;
  if (not save) then begin
    print('Aborted.');
    readytogo;
    exit;
  end;

  with mheader do begin
    signature:=$FFFFFFFF;
    title:=mftit;
    origindate:='';
    with fromi do begin
      anon:=0;
      usernum:=common.usernum;
      as:=allcaps(thisuser.name);
      if ((not pub) or (memboard.mbtype=0)) then
        as:=as+' #'+cstr(common.usernum);
      real:=allcaps(thisuser.realname);
      alias:=allcaps(thisuser.name);
    end;
    if (not uti) then
      with toi do begin
        anon:=0;
        usernum:=0;
        as:='';
        if (allcaps(sqoutsp(fto))='EVERYONE') then fto:='';
        if (pub) then as:=fto;
        real:='';
        alias:='';
      end;
  end;

  loadboard(board);
  if (pub) then begin
    an:=memboard.anonymous;
    if ((an=atno) and (aacs(systat.anonpubpost))) then an:=atyes;
    if (rpostan in thisuser.ac) then an:=atno;
  end else
    if (aacs(systat.anonprivpost)) then an:=atyes else an:=atno;
  case an of
    atno      :;
    atforced  :if (cso) then mheader.fromi.anon:=2
                        else mheader.fromi.anon:=1;
    atyes     :begin
                 nl;
                 if pynq(aonoff(pub,'Post Anonymously? ',
                                    'Send Anonymously? ')) then
                   if (cso) then mheader.fromi.anon:=2
                            else mheader.fromi.anon:=1;
               end;
    atdearabby:begin
                 nl;
                 sprint(aonoff(pub,'Post as:','Send as:'));
                 nl;
                 sprint(#3#3+'1. ^7[^0User ^8X^7]');
                 sprint(#3#3+'2. ^1Problemed Person');
                 sprint(#3#3+'3. ^1'+nam);
                 nl;
                 prt('Which? '); onek(c,'123N'^M);
                 case c of
                   '1':mheader.fromi.anon:=3;
                   '2':mheader.fromi.anon:=4;
                 end;
               end;
    atanyname :begin
                 nl;
                 sprint('You can post your message under any name');
                 sprint('you want on this base.');
                 nl;
                 print('Enter name, or <CR> for your own.');
                 prt('Name: '); input(s,36);
                 if (s<>'') then begin
                   mheader.fromi.anon:=5;
                   mheader.fromi.as:=caps(s);
                 end;
               end;
  end;
  if ((pub) and (himsg<>65535)) then begin
    j:=0;
    for i:=0 to himsg do begin
      ensureloaded(i);
      k:=mintab[getmixnum(i)].messagenum;
      if (k>j) then j:=k;
    end;
    mixr.messagenum:=j+1;
  end;
  with mixr do begin
    hdrptr:=filesize(brdf);
    isreplytoid:=0;
    isreplyto:=65535;
    numreplys:=0;
    getpackdatetime(@msgdate);
    getdayofweek(msgdowk);
    msgid:=memboard.lastmsgid;
    inc(memboard.lastmsgid);
    msgindexstat:=[miexist];
    if (pub) then begin
      if (rvalidate in thisuser.ac) then
        msgindexstat:=msgindexstat+[miunvalidated];
      if (aacs(memboard.mciacs)) then
        msgindexstat:=msgindexstat+[miallowmci];
    end;
  end;

  nl;
  sprompt(#3#7+'I am processing your message...');
  while ((lc>1) and ((li[lc-1]='') or (li[lc-1]=^J))) do
    dec(lc);

  saveit;
  savesystat;
  ufo:=(filerec(bf).mode<>fmclosed);
  if (not ufo) then reset(bf);
  seek(bf,board-1);
  write(bf,memboard);
  if (not ufo) then close(bf);

  cl(5);
  for t:=1 to 31 do begin
    prompt('<');
    delay(20);
    prompt(^H' '^H^H);
  end;
  prompt('*');
  delay(20);
  prompt(^H' '^H);
  cl(9);
  readytogo;
  inmsg:=TRUE;
end;

procedure inli(var i:string);
var s:astr;
    cp,rp,cv,cc,xxy:integer;
    c,c1,ccc,d:char;
    hitcmdkey,hitbkspc,escp,dothischar,abort,next,savallowabort:boolean;

  procedure bkspc;
  begin
    if (cp>1) then begin
      if (i[cp-2]=#3) and (i[cp-1] in [#0..#9]) then begin
        dec(cp);
        cl(1);
      end else
        if (i[cp-1]=^H) then begin
          prompt(' ');
          inc(rp);
        end else
          if (i[cp-1]<>#10) then begin
            prompt(^H' '^H);
            dec(rp);
          end;
      dec(cp);
    end;
  end;

begin
  write_msg:=TRUE; hitcmdkey:=FALSE; hitbkspc:=FALSE;
  ccc:='1';
  escp:=FALSE;
  rp:=1; cp:=1;
  i:='';
  if (lastline<>'') then begin
    abort:=FALSE; next:=FALSE;
    savallowabort:=allowabort; allowabort:=FALSE;
    reading_a_msg:=TRUE;
    printa1(lastline,abort,next);
    reading_a_msg:=FALSE;
    allowabort:=savallowabort;
    i:=lastline; lastline:='';
    escp:=(pos(^[,i)<>0);
    cp:=length(i)+1;
    rp:=cp;
  end;
  repeat
    if ((inmsgfileopen) and (buf='')) then
      if (not eof(inmsgfile)) then begin
        readln(inmsgfile,buf);
        buf:=buf+^M;
      end else begin
        close(inmsgfile);
        inmsgfileopen:=FALSE; cmdsoff:=FALSE;
        dosansion:=FALSE;
        buf:=^P+'1';
      end;
    getkey(c);

    dothischar:=FALSE;
    if (c=^G) then begin
      cmdsoff:=not cmdsoff;
      nl; nl;
      if (cmdsoff) then begin
        sprint(#3#5+'Message commands OFF now, to allow entry of special characters.');
        sprint(#3#5+'Press Ctrl-G again to turn message commands back on.');
      end else
        sprint(#3#5+'Message commands back on again.');
      nl;
      for xxy:=1 to cp do s[xxy]:=i[xxy]; s[0]:=chr(cp-1);
      abort:=FALSE; next:=FALSE;
      reading_a_msg:=TRUE; printa1(s,abort,next); reading_a_msg:=FALSE;
    end;
    if (not cmdsoff) then
      if ((c>=#32) and (c<=#255)) then begin
        if (c='/') and (cp=1) then hitcmdkey:=TRUE else dothischar:=TRUE;
      end else
        case c of
          ^[:dothischar:=TRUE;
          ^B:dm(' -'^N'/'^N'l'^N'\'^N,c);
          ^H:if (cp=1) then begin
               hitcmdkey:=TRUE;
               hitbkspc:=TRUE;
             end else
               bkspc;
          ^I:begin
               cv:=5-(cp mod 5);
               if (cp+cv<strlen) and (rp+cv<thisuser.linelen) then
                 for cc:=1 to cv do begin
                   outkey(' '); if (trapping) then write(trapfile,' ');
                   i[cp]:=' ';
                   inc(rp); inc(cp);
                 end;
             end;
          ^J:if (not (rbackspace in thisuser.ac)) then begin
               outkey(c); i[cp]:=c;
               if (trapping) then write(trapfile,^J);
               inc(cp);
             end;
          ^N:if (not (rbackspace in thisuser.ac)) then begin
               outkey(^H); i[cp]:=^H;
               if (trapping) then write(trapfile,^H);
               inc(cp); dec(rp);
             end;
          ^P:if (okansi) and (cp<strlen-1) then begin
               getkey(c1);
               if (c1 in ['0'..'9']) then begin
                 ccc:=c1; i[cp]:=#3;
                 inc(cp); i[cp]:=chr(ord(c1)-ord('0'));
                 inc(cp); cl(ord(i[cp-1]));
               end;
             end;
          ^S:dm(' '+nam+' ',c);
          ^W:if (cp=1) then begin
               hitcmdkey:=TRUE;
               hitbkspc:=TRUE;
             end else
               repeat bkspc until (cp=1) or (i[cp]=' ') or
                                  ((i[cp]=^H) and (i[cp-1]<>#3));
          ^X:begin
               cp:=1;
               for cv:=1 to rp-1 do prompt(^H' '^H);
               rp:=1;
               if (ccc<>'1') then begin
                 c1:=ccc; i[cp]:=#3;
                 inc(cp); i[cp]:=chr(ord(c1)-ord('0'));
                 inc(cp); cl(ord(i[cp-1]));
               end;
             end;
        end;

    if ((dothischar) or (cmdsoff)) and ((c<>^G) and (c<>^M)) then
      if ((cp<strlen) and (escp)) or
         ((rp<thisuser.linelen) and (not escp)) then begin
        if (c=^[) then escp:=TRUE;
        i[cp]:=c; inc(cp); inc(rp);
        outkey(c);
        if (trapping) then write(trapfile,c);
        inc(pap);
      end;
  until ((rp=(thisuser.linelen)) and (not escp)) or ((cp=strlen) and (escp)) or
        (c=^M) or (hitcmdkey) or (hangup);

  if (hitcmdkey) then begin
    if (hitbkspc) then i:='/'^H else i:='/';
  end else begin
    i[0]:=chr(cp-1);
    if (c<>^M) and (cp<>strlen) and (not escp) then begin
      cv:=cp-1;
      while (cv>1) and (i[cv]<>' ') and ((i[cv]<>^H) or (i[cv-1]=#3)) do dec(cv);
      if (cv>rp div 2) and (cv<>cp-1) then begin
        lastline:=copy(i,cv+1,cp-cv);
        for cc:=cp-2 downto cv do prompt(^H);
        for cc:=cp-2 downto cv do prompt(' ');
        i[0]:=chr(cv-1);
      end;
    end;

    if (escp) and (rp=thisuser.linelen) then cp:=strlen;
    if (cp<>strlen) then nl
    else begin
      rp:=1; cp:=1;
      i:=i+#29;
    end;
  end;

  write_msg:=FALSE;
end;

end.
