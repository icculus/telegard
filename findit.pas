uses dos;

var s,spath:string;
    ps:dirstr;
    ns:namestr;
    es:extstr;
    notfound:boolean;

begin
  writeln;
  writeln('Find EXE/COM/BAT files on the PATH.');
  writeln;
  writeln('Enter commandline:');
  write(':'); readln(s);

  while (copy(s,1,1)=' ') do s:=copy(s,2,length(s)-1);

  fsplit(s,ps,ns,es);

  notfound:=FALSE;
  s:=ns+'.EXE'; spath:=fsearch(s,getenv('PATH'));
  if (spath='') then begin
    s:=ns+'.COM'; spath:=fsearch(s,getenv('PATH'));
    if (spath='') then begin
      s:=ns+'.BAT'; spath:=fsearch(s,getenv('PATH'));
      if (spath='') then notfound:=TRUE;
    end;
  end;

  if (not notfound) then spath:=fexpand(spath);

  if (notfound) then writeln('Not found.') else writeln('Found: '+spath);

end.
