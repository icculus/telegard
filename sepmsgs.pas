uses crt,dos;

{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
{$M 50000,0,90000}      { Declared here suffices for all Units as well! }
{$I rec16e1.pas}

var systatf:file of systatrec;
    systat:systatrec;
    bf:file of boardrec;
    brd:boardrec;
    sp:string;
    i:integer;
    c:char;
    abort:boolean;

procedure tc(i:integer);
begin
  textcolor(i);
end;

procedure star(s:astr);
begin
  tc(9); write('þ ');
  tc(11); writeln(s);
end;

procedure ttl(s:string);
begin
  writeln;
  textcolor(9); write('ÄÄ[');
  textbackground(1); textcolor(15);
  write(' '+s+' ');
  textbackground(0); textcolor(9);
  write(']');
  repeat write('Ä') until wherex=80;
  writeln;
end;

function cstr(i:integer):astr;
var c:astr;
begin
  str(i,c);
  cstr:=c;
end;

function freek(d:integer):longint;    (* See disk space *)
{var r:registers;}
begin
  freek:=diskfree(d) div 1024;
{  r.ax:=$3600;
  r.dx:=d;
  msdos(dos.registers(r));
  freek:=trunc(1.0*r.bx*r.ax*r.cx/1024.0);}
end;

function exdrv(s:astr):byte;
begin
  {rcg11242000 point at root drive always. Ugh.}
  {
  s:=fexpand(s);
  exdrv:=ord(s[1])-64;
  }
  exdrv:=3;
end;

procedure movefile(srcname,destpath:string);
var buffer:array[1..16384] of byte;
    dfs,nrec:integer;
    src,dest:file;
    dd:dirstr;
    dn:namestr;
    de:extstr;

  procedure dodate;
  var r:registers;
      od,ot,ha:integer;
  begin
    srcname:=srcname+#0;
    destpath:=destpath+#0;
    with r do begin
      ax:=$3d00; ds:=seg(srcname[1]); dx:=ofs(srcname[1]); msdos(dos.registers(r));
      ha:=ax; bx:=ha; ax:=$5700; msdos(dos.registers(r));
      od:=dx; ot:=cx; bx:=ha; ax:=$3e00; msdos(dos.registers(r));
      ax:=$3d02; ds:=seg(destpath[1]); dx:=ofs(destpath[1]); msdos(dos.registers(r));
      ha:=ax; bx:=ha; ax:=$5701; cx:=ot; dx:=od; msdos(dos.registers(r));
      ax:=$3e00; bx:=ha; msdos(dos.registers(r));
    end;
  end;

begin
  fsplit(srcname,dd,dn,de);
  destpath:=destpath+dn+de;
  assign(src,srcname);
  {$I-} reset(src,1); {$I+}
  if (ioresult<>0) then begin
    writeln;
    star('"'+srcname+'": File not found.'^G^G);
    halt(1);
  end else begin
    dfs:=freek(exdrv(destpath));

    {rcg11172000 don't have LONGfilesize()...}
    {if (trunc(longfilesize(src)/1024.0)+1>=dfs) then begin}
    if (trunc(filesize(src)/1024.0)+1>=dfs) then begin
      writeln;
      star('"'+srcname+'": Disk full.');
      halt(1);
    end else begin
      assign(dest,destpath); rewrite(dest,1);
      repeat
        blockread(src,buffer,16384,nrec);
        blockwrite(dest,buffer,nrec);
      until (nrec<16384);
      close(dest);
      close(src);
      dodate;
      erase(src);
    end;
  end;
end;

procedure moveprivmail(npath:astr);
var j,k:integer;
    s,s1,odir:astr;
    mailfile:file of mailrec;
    mr:mailrec;
    f:file;
    lastm,thism:messages;   {* keep track of mass-mail duplicates *}
begin
  {rcg11242000 DOSism.}
  {while copy(npath,length(npath),1)='\' do}
  while copy(npath,length(npath),1)='/' do
    npath:=copy(npath,1,length(npath)-1);
  getdir(0,odir);
  {$I-} chdir(npath); {$I+}
  if ioresult=0 then begin
    chdir(odir);
    star('Using existing subdirectory ("'+npath+'")');
  end else begin
    star('Creating new subdirectory ("'+npath+'")');
    {$I-} mkdir(npath); {$I+}
  end;
  if (ioresult=0) then begin
    assign(mailfile,systat.gfilepath+'email.dat');
    {$I-} reset(mailfile); {$I+}
    if (ioresult=0) then begin
      k:=0;
      writeln;
      for j:=filesize(mailfile)-1 downto 0 do begin {* will sort messages in
                                                     * the order of
                                                     * newest-->oldest *}
        seek(mailfile,j); read(mailfile,mr);
        with mr.msg do begin
          s:=ltr+cstr(number)+'.'+cstr(ext);
          s1:=systat.pmsgpath+s;
          thism:=mr.msg;
          gotoxy(wherex,wherey-1); clreol;
          inc(k);
          {rcg11242000 DOSism.}
          {
	  star('Message file #'+cstr(k)+' of '+
                cstr(filesize(mailfile))+': '+npath+'\'+s);
          }
          star('Message file #'+cstr(k)+' of '+
                cstr(filesize(mailfile))+': '+npath+'/'+s);
          if ((thism.ltr<>lastm.ltr) or
              (thism.number<>lastm.number) or
              (thism.ext<>lastm.ext)) then begin
            assign(f,s1);
            {$I-} reset(f); {$I+}
            if ioresult=0 then begin
              close(f);
              {rcg11242000 DOSism.}
              {movefile(s1,npath+'\');}
              movefile(s1,npath+'/');
              lastm:=thism;
            end else star('File does not exist: '+s1);
            lastm:=thism;
          end;
        end;
      end;
      close(mailfile);
    end else star('Unable to open file: '+systat.gfilepath+'EMAIL.DAT');
  end else star('Unable to create subdirectory: '+npath);
end;

procedure movemsgbase(brd:boardrec; npath:astr; i:integer);
var j,k:integer;
    s,s1,odir:astr;
    f:file;
    mary:array[0..200] of messagerec;
begin
  {rcg11242000 DOSism.}
  {while copy(npath,length(npath),1)='\' do}
  while copy(npath,length(npath),1)='/' do
    npath:=copy(npath,1,length(npath)-1);
  with brd do begin
    getdir(0,odir);
    {$I-} chdir(npath); {$I+}
    if ioresult=0 then begin
      chdir(odir);
      star('Using existing subdirectory ("'+npath+'")');
    end else begin
      star('Creating new subdirectory ("'+npath+'")');
      {$I-} mkdir(npath); {$I+}
    end;
    if ioresult=0 then begin
      assign(f,systat.gfilepath+brd.filename+'.BRD');
      {$I-} reset(f,sizeof(messagerec)); {$I+}
      if ioresult=0 then begin
        writeln;
        blockread(f,mary[0],1);
        blockread(f,mary[1],mary[0].message.number);
        close(f);

        k:=0;
        for j:=mary[0].message.number downto 1 do  {* will sort messages in
                                                    * the order of
                                                    * newest-->oldest *}
          with mary[j].message do begin
            s:=ltr+cstr(number)+'.'+cstr(ext);
            s1:=systat.pmsgpath+s;
            assign(f,s1);
            {$I-} reset(f); {$I+}
            if ioresult=0 then begin
              close(f);
              gotoxy(wherex,wherey-1); clreol;
              inc(k);
              {rcg11242000 DOSisms.}
              {
	      star('Message file #'+cstr(k)+' of '+
                    cstr(mary[0].message.number)+': '+npath+'\'+s);
              movefile(s1,npath+'\');
              }
              star('Message file #'+cstr(k)+' of '+
                    cstr(mary[0].message.number)+': '+npath+'/'+s);
              movefile(s1,npath+'/');
            end else star('File does not exist: '+s1);
          end;
      end else star('Unable to open file: '+systat.gfilepath+brd.filename+'.BRD');
    end else star('Unable to create subdirectory: '+npath);
  end;
end;

begin
  getdir(0,sp);
  assign(systatf,'status.dat');
  reset(systatf); read(systatf,systat); close(systatf);

  star('Each message base in Telegard can now occupy its own, seperate directory');
  star('path on your drive.  Seperating the messages into seperate directorys');
  star('will speed up seek-time for messages considerably.');
  writeln;
  star('This program can do all the work of seperating all the messages');
  star('in each base into their own directories.');
  writeln;
  star('Message directories will be created off of your current Telegard MSGS/');
  star('directory according to the *.BRD FILENAMEs of each message base.');
  writeln;
  star('Example:');
  star('"'+systat.pmsgpath+'EMAIL/" for private mail');
  star('"'+systat.pmsgpath+'GENERAL/" for message base #1');
  star(' (if msg base #1 filename is "GENERAL")');
  star('"'+systat.pmsgpath+'MISC/" for message base #2');
  star(' (if msg base #2 filename is "MISC")');
  star('And so on.');
  writeln;
  write('Continue and do this? [Yes] : ');
  repeat c:=upcase(readkey) until c in ['Y','N',^M];
  abort:=(c='N');
  writeln(c);
  if (abort) then halt;

  writeln;
  writeln;
  ttl('Moving public message bases into seperate directory paths');
  assign(bf,systat.gfilepath+'boards.dat');
  reset(bf);
  for i:=0 to filesize(bf)-1 do begin
    seek(bf,i); read(bf,brd);
    {rcg11242000 DOSism.}
    {brd.msgpath:=brd.msgpath+brd.filename+'\';}
    brd.msgpath:=brd.msgpath+brd.filename+'/';
    seek(bf,i); write(bf,brd);
    star('Moving messages in '+brd.filename+'.BRD ('+brd.name+') to "'+brd.msgpath+'"');
    movemsgbase(brd,brd.msgpath,i+1);
  end;
  close(bf);
  chdir(sp);
  {rcg11242000 DOSisms.}
  {
  ttl('Moving private mail into "'+systat.pmsgpath+'EMAIL\"');
  moveprivmail(systat.pmsgpath+'EMAIL\');
  systat.pmsgpath:=systat.pmsgpath+'EMAIL\';
  }
  ttl('Moving private mail into "'+systat.pmsgpath+'EMAIL/"');
  moveprivmail(systat.pmsgpath+'EMAIL/');
  systat.pmsgpath:=systat.pmsgpath+'EMAIL/';
  rewrite(systatf); write(systatf,systat); close(systatf);
end.
