(*****************************************************************************)
(*>                                                                         <*)
(*>  MISC4   .PAS -  InfoForm questionairre system.                         <*)
(*>                                                                         <*)
(*****************************************************************************)
{$A+,B+,D-,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit misc4;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  doors, misc3,
  common;

procedure readq(filen:astr; infolevel:integer);
procedure readasw(usern:integer; fn:astr);
procedure readasw1(fn:astr);

implementation

procedure readq(filen:astr; infolevel:integer);
const level0name:string='';
var infile,outfile,outfile1:text;
    outp,lin,s,mult,got,lastinp,ps,ns,es,infilename,outfilename:astr;
    i:integer;
    abort,next,plin:boolean;
    c:char;

  procedure gotolabel(got:astr);
  var s:astr;
  begin
    got:=':'+allcaps(got);
    reset(infile);
    repeat
      readln(infile,s);
    until (eof(infile)) or (allcaps(s)=got);
  end;

  procedure dumptofile;
  begin
      { output answers to *.ASW file, and delete temporary file }
    reset(outfile1);
    {$I-} append(outfile); {$I+}
    if (ioresult<>0) then rewrite(outfile);

    while (not eof(outfile1)) do begin
      readln(outfile1,s);
      writeln(outfile,s);
    end;
    close(outfile1); close(outfile);
    erase(outfile1);
  end;

begin
  infilename:=filen;
  if (not exist(infilename)) then begin
    fsplit(infilename,ps,ns,es);
    infilename:=ps+ns+'.INF';
    if (not exist(infilename)) then begin
      infilename:=systat.afilepath+ns+'.INF';
      if (not exist(infilename)) then begin
        sysoplog('** InfoForm not found: "'+filen);
        print('** InfoForm not found: "'+filen);
        exit;
      end;
    end;
  end;

  assign(infile,infilename);
  {$I-} reset(infile); {$I+}
  if (ioresult<>0) then begin
    sysoplog('** InfoForm not found: "'+filen+'"');
    print('** InfoForm not found: "'+filen+'"');
    exit;
  end;

  fsplit(infilename,ps,ns,es);
  outfilename:=systat.afilepath+ns+'.ASW';

  assign(outfile1,systat.afilepath+'TEMP$'+cstr(infolevel)+'.ASW');
  if (infolevel=0) then begin
    level0name:=outfilename;
    assign(outfile,outfilename);
    sysoplog('** Answered InfoForm "'+filen+'"');
    rewrite(outfile1);
    writeln(outfile1,'User: '+nam);
    writeln(outfile1,'Date: '+dat);
    writeln(outfile1);
  end else begin
    sysoplog('**>> Answered InfoForm "'+filen+'"');
    rewrite(outfile1);
    assign(outfile,level0name);
  end;

  nl;
  printingfile:=TRUE;

  repeat
    abort:=FALSE;
    readln(infile,outp);
    if (pos('*',outp)<>0) and (copy(outp,1,1)<>';') then outp:=';A'+outp;
    if (length(outp)=0) then nl else
      case outp[1] of
        ';':begin
              if (pos('*',outp)<>0) then
                if (outp[2]<>'D') then outp:=copy(outp,1,pos('*',outp)-1);
              lin:=copy(outp,3,length(outp)-2);
              i:=80-length(lin);
              s:=copy(outp,1,2);
              if (s[1]=';') then
                case s[2] of
                  'C','D','G','I','K','L','Q','T',';':i:=1; { do nothing }
                else
                      sprompt(lin);
                end;
              s:=#1#1#1;
              case outp[2] of
                'A':inputl(s,i);
                'B':input(s,i);
                'C':begin
                      mult:=''; i:=1;
                      s:=copy(outp,pos('"',outp),length(outp)-pos('"',outp));
                      repeat
                        mult:=mult+s[i];
                        inc(i);
                      until (s[i]='"') or (i>length(s));
                      lin:=copy(outp,i+3,length(s)-(i-1));
                      sprompt(lin);
                      onek(c,mult);
                      s:=c;
                    end;
                'D':begin
                      dodoorfunc(outp[3],copy(outp,4,length(outp)-3));
                      s:=#0#0#0;
                    end;
                'G':begin
                      got:=copy(outp,3,length(outp)-2);
                      gotolabel(got);
                      s:=#0#0#0;
                    end;
                'H':hangup:=TRUE;
                'I':begin
                      mult:=copy(outp,3,length(outp)-2);
                      i:=pos(',',mult);
                      if i<>0 then begin
                        got:=copy(mult,i+1,length(mult)-i);
                        mult:=copy(mult,1,i-1);
                        if allcaps(lastinp)=allcaps(mult) then
                          gotolabel(got);
                      end;
                      s:=#0#0#0;
                    end;
                'K':begin
                      close(infile);
                      close(outfile1); erase(outfile1);
                      if (infolevel<>0) then begin
                        {$I-} append(outfile); {$I+}
                        if (ioresult<>0) then rewrite(outfile);
                        writeln(outfile,'** Aborted InfoForm: "'+filen+'"');
                        close(outfile);
                      end;
                      sysoplog('** Aborted InfoForm.  Answers not saved.');
                      printingfile:=FALSE; cfilteron:=FALSE;
                      exit;
                    end;
                'L':begin
                      writeln(outfile1,copy(outp,3,length(outp)-2));
                      s:=#0#0#0;
                    end;
                'Q':begin
                      close(outfile1);
                      dumptofile;
                      readq(copy(outp,3,length(outp)-2),infolevel+1);
                      rewrite(outfile1);
                      s:=#0#0#0;
                    end;
                'T':begin
                      s:=copy(outp,3,length(outp)-2);
                      printf(s);
                      s:=#0#0#0;
                    end;
                'Y':if yn then s:='YES' else s:='NO';
                ';':s:=#0#0#0;
              end;
              if (s<>#1#1#1) then begin
                outp:=lin+s;
                lastinp:=s;
              end;
              if (s=#0#0#0) then outp:=#0#0#0;
            end;
        ':':outp:=#0#0#0;
      else
            printacr(outp,abort,next);
      end;
    if (outp<>#0#0#0) then begin
      if (pos('@7',outp)<>0) then delete(outp,pos('@7',outp),2);
      writeln(outfile1,outp);
    end;
  until ((eof(infile)) or (hangup));
  if (hangup) then begin
    writeln(outfile1);
    writeln(outfile1,'** HUNG UP **');
  end;

  close(outfile1);
  dumptofile;
  close(infile);

  printingfile:=FALSE; cfilteron:=FALSE;
end;

procedure readasw(usern:integer; fn:astr);
var qf:text;
    user:userrec;
    qs,ps,ns,es:astr;
    i,userntimes:integer;
    abort,next,userfound,usernfound,ufo:boolean;

  procedure exactmatch;
  begin
    reset(qf);
    repeat
      readln(qf,qs);
      if (copy(qs,1,6)='User: ') then begin
        i:=value(copy(qs,pos('#',qs)+1,length(qs)-pos('#',qs)));
        if (i=usern) then begin
          inc(userntimes); usernfound:=TRUE;
          if (allcaps(qs)=allcaps('User: '+user.name+' #'+cstr(usern))) then
            userfound:=TRUE;
        end;
      end;
      if (not empty) then wkey(abort,next);
    until (eof(qf)) or (userfound) or (abort);
  end;

  procedure usernmatch;
  begin
    sprompt(#3#7+'No exact user name matches; user number was found ');
    if (userntimes=1) then sprompt('once')
      else sprompt(cstr(userntimes)+' times');
    sprint('.');
    nl;

    reset(qf);
    repeat
      readln(qf,qs);
      if (copy(qs,1,6)='User: ') then begin
        i:=value(copy(qs,pos('#',qs)+1,length(qs)-pos('#',qs)));
        if (i=usern) then
          if (userntimes=1) then userfound:=TRUE
          else begin
            sprompt(#3#4+'User: '+#3#3+copy(qs,7,length(qs)-6));
            userfound:=pynq('  -- Is this right? ');
          end;
      end;
      if (not empty) then wkey(abort,next);
    until (eof(qf)) or (userfound) or (abort);
    nl;
  end;

begin
  ufo:=(filerec(uf).mode<>fmclosed);
  if (not ufo) then reset(uf);
  if ((usern>=1) and (usern<=filesize(uf)-1)) then begin
    seek(uf,usern); read(uf,user);
  end else begin
    print('Invalid user number: '+cstr(usern));
    exit;
  end;
  if (not ufo) then close(uf);

  nl;
  abort:=FALSE; next:=FALSE;
  fn:=allcaps(fn);
  fsplit(fn,ps,ns,es);
  fn:=allcaps(systat.afilepath+ns+'.ASW');
  if (not exist(fn)) then begin
    fn:=allcaps(systat.gfilepath+ns+'.ASW');
    if (not exist(fn)) then begin
      print('InfoForm answer file not found: "'+fn+'"');
      exit;
    end;
  end;
  assign(qf,fn);
  {$I-} reset(qf); {$I+}
  if (ioresult<>0) then print('"'+fn+'": unable to open.')
  else begin
    userfound:=FALSE; usernfound:=FALSE; userntimes:=0;
    exactmatch;
    if (not userfound) and (usernfound) and (not abort) then usernmatch;

    if (not userfound) and (not abort) then
      print('Questionairre answers not found.')
    else begin
      sprint(qs); (*(#3#4+'User: '+#3#3+caps(user.name)+' #'+cstr(usern));*)
      repeat
        readln(qf,qs);
        if (copy(qs,1,6)<>'User: ') then printacr(qs,abort,next)
          else userfound:=FALSE;
      until eof(qf) or (not userfound) or (abort);
    end;
    close(qf);
  end;
end;

procedure readasw1(fn:astr);
var ps,ns,es:astr;
    usern:integer;
begin
  nl;
  print('Read InfoForm answers -');
  nl;
  if (fn='') then begin
    prt('Enter filename: '); mpl(8); input(fn,8);
    nl;
    if (fn='') then exit;
  end;
  fsplit(fn,ps,ns,es);
  fn:=allcaps(systat.gfilepath+ns+'.ASW');
  if (not exist(fn)) then begin
    fn:=allcaps(systat.afilepath+ns+'.ASW');
    if (not exist(fn)) then begin
      print('InfoForm answer file not found: "'+fn+'"');
      exit;
    end;
  end;
  print('Enter user number, user name, or partial search string:');
  prt(':'); finduserws(usern);
  if (usern<>0) then
    readasw(usern,fn)
  else begin
    nl;
    if pynq('List entire answer file? ') then begin
      nl;
      printf(ns+'.ASW');
    end;
  end;
end;

end.
