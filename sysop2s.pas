(*****************************************************************************)
(*>                                                                         <*)
(*>  SYSOP2S .PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  SysOp functions: System Configuration Editor -- "S" command.           <*)
(*>                                                                         <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit sysop2s;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common;

procedure postring;

implementation

const
  aresure='Are you sure this is what you want? ';

procedure instring(p:astr; var v:astr; len:integer);
var changed:boolean;
begin
  print('Enter new "'+p+'" string:');
  inputwnwc(v,len,changed);
end;

procedure postring;
var fstringf:file of fstringrec;
    s,s2:astr;
    onpage:integer;
    c:char;
    abort,next,done:boolean;

  function cc(s:astr):astr;
  begin
    while pos('^',s)>0 do s[pos('^',s)]:=#3;
    cc:=#3#1+s;
  end;

  procedure showstrings;
  begin
    abort:=FALSE; next:=FALSE;
    with fstring do
      case onpage of
        1:begin
            printacr('A. Ansi logon Q.:'+cc(ansiq),abort,next);
            printacr('B. Logon note #1:'+cc(note[1]),abort,next);
            printacr('   Logon note #2:'+cc(note[2]),abort,next);
            printacr('C. Logon prompt :'+cc(lprompt),abort,next);
            printacr('D. Echo chr     :'+cc(echoc),abort,next);
            printacr('E. SysOp IN     :'+cc(sysopin),abort,next);
            printacr('F. SysOp OUT    :'+cc(sysopout),abort,next);
            printacr('G. Engage chat  :'+cc(engage),abort,next);
            printacr('H. Exit chat    :'+cc(endchat),abort,next);
            printacr('I. Sysop working:'+cc(wait),abort,next);
            printacr('J. Pause screen :'+cc(pause),abort,next);
            nl;
            prt('Enter selection (A-J,[,]),(Q)uit : ');
            onek(c,'QABCDEFGHIJ[]');
          end;
        2:begin
            printacr('A. Message entry L#1:'+cc(entermsg1),abort,next);
            printacr('B. Message entry L#2:'+cc(entermsg2),abort,next);
            printacr('C. NewScan start    :'+cc(newscan1),abort,next);
            printacr('D. NewScan done     :'+cc(newscan2),abort,next);
            printacr('E. Read msgs prompt :'+cc(scanmessage),abort,next);
            printacr('F. Automessage by:  :'+cc(automsgt),abort,next);
            printacr('G. Auto border char.:'+autom,abort,next);
            nl;
            prt('Enter selection (A-G,[,]),(Q)uit : ');
            onek(c,'QABCDEFG[]');
          end;
        3:begin
            printacr('A. Shell to DOS L#1 :'+cc(shelldos1),abort,next);
            printacr('B. Shell to DOS L#2 :'+cc(shelldos2),abort,next);
            printacr('C. Chat call L#1    :'+cc(chatcall1),abort,next);
            printacr('D. Chat call L#2    :'+cc(chatcall2),abort,next);
            printacr('E. Guest user info  :'+cc(guestline),abort,next);
            printacr('F. Name not found   :'+cc(namenotfound),abort,next);
            printacr('G. Bulletin line    :'+cc(bulletinline),abort,next);
            printacr('H. Thanks for voting:'+cc(thanxvote),abort,next);
            nl;
            prt('Enter selection (A-H,[,]),(Q)uit : ');
            onek(c,'QABCDEFGH[]');
          end;
        4:begin
            printacr('A. List line        :'+cc(listline),abort,next);
            printacr('B. File NewScan line:'+cc(newline),abort,next);
            printacr('C. Search line      :'+cc(searchline),abort,next);
            printacr('D. Find Descrip. L#1:'+cc(findline1),abort,next);
            printacr('E. Find Descrip. L#2:'+cc(findline2),abort,next);
            printacr('F. Download line    :'+cc(downloadline),abort,next);
            printacr('G. Upload line      :'+cc(uploadline),abort,next);
            printacr('H. View content line:'+cc(viewline),abort,next);
            printacr('I. Insuff. file pts :'+cc(nofilepts),abort,next);
            printacr('J. Bad UL/DL ratio  :'+cc(unbalance),abort,next);
            nl;
            prt('Enter selection (A-J,[,]),(Q)uit : ');
            onek(c,'QABCDEFGHIJ[]');
          end;
        5:begin
            printacr('A. P/N file info    :'+cc(pninfo),abort,next);
            printacr('B. Get filespec L#1 :'+cc(gfnline1),abort,next);
            printacr('C. Get filespec L#2 :'+cc(gfnline2),abort,next);
            printacr('D. Add to batch     :'+cc(batchadd),abort,next);
            nl;
            prt('Enter selection (A-D,[,]),(Q)uit : ');
            onek(c,'QABCD[]');
          end;
      end;
  end;

  procedure dostringstuff;
  begin
{    cl(4);}
    case c of
      'Q':done:=TRUE;
      '[':begin
            dec(onpage);
            if (onpage<1) then onpage:=5;
          end;
      ']':begin
            inc(onpage);
            if (onpage>5) then onpage:=1;
          end;
    end;
    with fstring do
      case onpage of
        1:case c of
            'A':instring('ANSI logon question',ansiq,80);
            'B':begin
                  print('Enter new logon note.  You may use two lines.');
                  inputwc(s,80);
                  inputwc(s2,80);
                  if (s<>'') then note[1]:=s;
                  if (s2<>'') then note[2]:=s2;
                end;
            'C':instring('Logon prompt',lprompt,40);
            'D':begin
                  prt('Enter new echo character: ');
                  mpl(1); inputl(s,1);
                  if (s<>'') then echoc:=s[1];
                end;
            'E':instring('SysOp IN',sysopin,80);
            'F':instring('SysOp OUT',sysopout,80);
            'G':instring('Engage chat',engage,80);
            'H':instring('End chat',endchat,80);
            'I':instring('SysOp working',wait,80);
            'J':instring('Pause',pause,80);
            'Q':done:=TRUE;
          end;
        2:case c of
            'A':instring('Message entry line 1',entermsg1,80);
            'B':instring('Message entry line 2',entermsg2,80);
            'C':instring('NewScan line 1',newscan1,80);
            'D':instring('NewScan line 2',newscan2,80);
            'E':instring('Read message prompt',scanmessage,80);
            'F':instring('Auto message title',automsgt,80);
            'G':begin
                  print('Enter new auto message border character:');
                  inputl(s,1);
                  if (s<>'') then autom:=s[1];
                end;
          end;
        3:case c of
            'A':instring('Shell to DOS line 1',shelldos1,80);
            'B':instring('Shell to DOS line 2',shelldos2,80);
            'C':instring('Chat call line 1',chatcall1,80);
            'D':instring('Chat call line 2',chatcall2,80);
            'E':instring('Guest user info at logon prompt',guestline,80);
            'F':instring('Name not found line during logon',namenotfound,80);
            'G':instring('Bulletins prompt line',bulletinline,80);
            'H':instring('Thanks for voting',thanxvote,80);
          end;
        4:case c of
            'A':instring('List line',listline,80);
            'B':instring('File NewScan line',newline,80);
            'C':instring('Search line',searchline,80);
            'D':instring('Find description line 1',findline1,80);
            'E':instring('Find description line 2',findline2,80);
            'F':instring('Download line',downloadline,80);
            'G':instring('Upload line',uploadline,80);
            'H':instring('View interior contents line',viewline,80);
            'I':instring('Insufficient file points',nofilepts,80);
            'J':instring('Upload/Download ratio unbalanced',unbalance,80);
          end;
        5:case c of
            'A':instring('P / N file information',pninfo,80);
            'B':instring('Get filespec line 1',gfnline1,80);
            'C':instring('Get filespec line 2',gfnline2,80);
            'D':instring('Add to batch queue',batchadd,80);
          end;
      end;
  end;

begin
  onpage:=1; done:=FALSE;
  repeat
    cls;
    sprint(#3#5+'String configuration - page '+cstr(onpage)+' of 5');
    nl;
    showstrings;
    nl;
    dostringstuff;
  until ((done) or (hangup));
  assign(fstringf,systat.gfilepath+'string.dat');
  reset(fstringf); seek(fstringf,0); write(fstringf,fstring); close(fstringf);
end;

end.
