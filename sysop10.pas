(*****************************************************************************)
(*>                                                                         <*)
(*>  SYSOP10 .PAS -  Written by Eric Oman                                   <*)
(*>                                                                         <*)
(*>  SysOp functions: Voting question editor, voting results output.        <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit sysop10;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common;

procedure initvotes;
procedure voteprint;

implementation

procedure initvotes;
var vdata:file of vdatar;
    cv,tv,ii:integer;
    s,i1,i2:astr;
    vd:vdatar;
    t1,tf,abort,next:boolean;
    u1:userrec;
begin
  assign(vdata,systat.gfilepath+'voting.dat');
  {$I-} reset(vdata); {$I+}
  if ioresult<>0 then begin
    rewrite(vdata);
    vd.question:='<< No Question >>'; vd.numa:=0;
    for cv:=0 to numvoteqs-1 do write(vdata,vd);
  end;
  repeat
    cls;
    abort:=FALSE; next:=FALSE;
    for cv:=1 to numvoteqs do begin
      seek(vdata,cv-1); read(vdata,vd);
      printacr(#3#0+mn(cv,2)+sepr2+vd.question,abort,next);
    end;
    abort:=FALSE; next:=FALSE;
    prt('Vote editor - modify which? : '); input(s,2);
    ii:=value(s); t1:=FALSE;
    if ((ii>=1) and (ii<=numvoteqs)) then begin
      cv:=1; t1:=TRUE;
      print('Enter new question: (79 characters max)');
      print('<CR>=No change.');
      prt(':');
      inputwc(vd.question,79);
      if (vd.question<>'') then begin
        vd.answ[0].ans:='No Comment';
        vd.answ[0].numres:=0;
        nl; print('Enter blank line for last answer; max 9 answers, 40 chars/answer.');
        tf:=FALSE;
        repeat
          sprompt(#3#4+cstr(cv)+#3#7+':'+#3#3);
          inputwc(vd.answ[cv].ans,40); vd.answ[cv].numres:=0;
          if (vd.answ[cv].ans='') then begin
            tf:=TRUE;
            if (cv=1) then vd.question:='<< No Question >>';
          end
          else inc(cv);
        until (cv>=numvoteas+1) or (tf) or (hangup);

        vd.numa:=cv-1;
        seek(vdata,ii-1); write(vdata,vd);
        reset(uf);
        for cv:=1 to filesize(uf)-1 do begin
          seek(uf,cv); read(uf,u1);
          u1.vote[ii]:=0;
          seek(uf,cv); write(uf,u1);
        end;
        close(uf);
        thisuser.vote[ii]:=0;
      end;
    end;
  until (not t1) or (hangup);
  close(vdata);
end;

procedure voteprint;
var vdata:file of vdatar;
    vd:vdatar;
    user:userrec;
    t:text;
    vn,i1,i2:integer;
    s1,s2:astr;
    sfo:boolean;
    sr:smalrec;
begin
  assign(t,systat.afilepath+'votes.txt');
  rewrite(t);
  writeln(t); writeln(t,'Votes as of '+dat);
  print('Beginning output to file "VOTES.TXT"');
  i1:=1;

  reset(uf);
  assign(vdata,systat.gfilepath+'voting.dat');
  reset(vdata);
  sfo:=(filerec(sf).mode<>fmclosed);
  if (not sfo) then reset(sf);
  for vn:=1 to numvoteqs do begin
    seek(vdata,vn-1); read(vdata,vd);
    if (vd.numa<>0) then begin
      writeln(t); writeln(t,vd.question);
      print(vd.question);
      for i1:=1 to vd.numa do begin
        writeln(t,'   '+vd.answ[i1].ans);
        for i2:=1 to filesize(sf)-1 do begin
          seek(sf,i2); read(sf,sr);
          seek(uf,sr.number); read(uf,user);
          if (user.vote[vn]=i1) then
            writeln(t,'      '+caps(sr.name)+' #'+cstr(sr.number));
        end;
      end;
    end;
  end;
  if (not sfo) then close(sf);
  close(uf);
  close(t);
  close(vdata);
  print('Output complete.');
end;

end.
