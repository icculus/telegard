{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit common3;

interface

uses
  crt, dos,
  myio,
  tmpcom;

procedure inu(var i:integer);
procedure ini(var i:byte);
procedure inputwn1(var v:string; l:integer; flags:string; var changed:boolean);
procedure inputwn(var v:string; l:integer; var changed:boolean);
procedure inputwnwc(var v:string; l:integer; var changed:boolean);
procedure inputmain(var s:string; ml:integer; flags:string);
procedure inputwc(var s:string; ml:integer);
procedure input(var s:string; ml:integer);
procedure inputl(var s:string; ml:integer);
procedure inputcaps(var s:string; ml:integer);
procedure mmkey(var s:string);

implementation

uses
  common, common1, common2;

procedure inu(var i:integer);
var s:string[5];
begin
  badini:=FALSE;
  input(s,5); i:=value(s);
  if (s='') then badini:=TRUE;
end;

procedure ini(var i:byte);
var s:string[3];
begin
  badini:=FALSE;
  input(s,3); i:=value(s);
  if s='' then badini:=TRUE;
end;

procedure inputwn1(var v:string; l:integer; flags:string; var changed:boolean);
var s,os:string;
begin
  os:=v;
  inputmain(s,l,flags);
  if (s=' ') then
    if pynq('Set to NULL string? ') then v:='' else
	begin
	end
  else if (s<>'') then v:=s;
  if (os<>v) then changed:=TRUE;
end;

procedure inputwn(var v:string; l:integer; var changed:boolean);
begin
  inputwn1(v,l,'',changed);
end;

procedure inputwnwc(var v:string; l:integer; var changed:boolean);
begin
  inputwn1(v,l,'c',changed);
end;

(* flags: "U" - Uppercase only
          "C" - Colors allowed
          "L" - Linefeeds OFF - no linefeed after <CR> pressed
          "D" - Display old if no change
          "P" - Capitalize characters ("ERIC OMAN" --> "Eric Oman")
*)
procedure inputmain(var s:string; ml:integer; flags:string);
var os:string;
    cp:integer;
    c:char;
    origcolor:byte;
    xxupperonly,xxcolor,xxnolf,xxredisp,xxcaps:boolean;

  procedure dobackspace;
  var i:integer;
      c:byte;
  begin
    if (cp>1) then begin
      dec(cp);
      if (s[cp] in [#32..#255]) then begin
        outkey(^H); outkey(' '); outkey(^H);
        if (trapping) then write(trapfile,^H' '^H);
        if (pap>0) then dec(pap);
      end else begin
        dec(pap);
        if (cp>1) then
          if (not (s[cp-1] in [#32..#255])) then begin
            dec(cp); dec(pap);
            if (s[cp]=#3) then begin
              c:=origcolor;
              i:=1;
              while (i<=cp-1) do begin
                if (s[i]=#3) then begin
                  c:=thisuser.cols[color in thisuser.ac][ord(s[i+1])];
                  inc(i);
                end;
                inc(i);
              end;
              setc(c);
            end;
          end;
      end;
    end;
  end;

begin
  flags:=allcaps(flags);
  xxupperonly:=(pos('U',flags)<>0); xxcolor:=(pos('C',flags)<>0);
  xxnolf:=(pos('L',flags)<>0); xxredisp:=(pos('D',flags)<>0);
  xxcaps:=(pos('P',flags)<>0);
  origcolor:=curco; os:=s;

  checkhangup;
  if (hangup) then exit;
  cp:=1;
  repeat
    getkey(c);
    if (xxupperonly) then c:=upcase(c);
    if (xxcaps) then
      if (cp>1) then begin
        if (c in ['A'..'Z','a'..'z']) then
          if (s[cp-1] in ['A'..'Z','a'..'z']) then begin
            if (c in ['A'..'Z']) then c:=chr(ord(c)+32);
          end else
            if (c in ['a'..'z']) then c:=chr(ord(c)-32);
      end else
        c:=upcase(c);
    if (c in [#32..#255]) then
      if (cp<=ml) then begin
        s[cp]:=c; inc(cp); inc(pap); outkey(c);
        if (trapping) then write(trapfile,c);
      end else
	  begin
	  end
    else case c of
      ^H:dobackspace;
      ^P:if ((xxcolor) and (cp<=ml-1)) then begin
           getkey(c);
           if (c in ['0'..'9']) then begin
             cl(ord(c)-48);
             s[cp]:=#3; s[cp+1]:=chr(ord(c)-48);
             inc(cp,2);
           end;
         end;
      ^X:while (cp<>1) do dobackspace;
    end;
  until ((c=^M) or (c=^N) or (hangup));
  s[0]:=chr(cp-1);
  if ((xxredisp) and (s='')) then begin
    s:=os;
    prompt(s);
  end;
  if (not xxnolf) then nl;
end;

procedure inputwc(var s:string; ml:integer);
  begin inputmain(s,ml,'c'); end;

procedure input(var s:string; ml:integer);
  begin inputmain(s,ml,'u'); end;

procedure inputl(var s:string; ml:integer);
  begin inputmain(s,ml,''); end;

procedure inputcaps(var s:string; ml:integer);
  begin inputmain(s,ml,'p'); end;

procedure mmkey(var s:string);
var s1:string;
    i,newarea:integer;
    c,cc:char;
    achange,bb:boolean;
begin
  s:='';
  if (buf<>'') then
    if (copy(buf,1,1)='`') then begin
      buf:=copy(buf,2,length(buf)-1);
      i:=pos('`',buf);
      if (i<>0) then begin
        s:=allcaps(copy(buf,1,i-1));
        buf:=copy(buf,i+1,length(buf)-i);
        nl;
        exit;
      end;
    end;

  if (not (onekey in thisuser.ac)) then
    input(s,60)
  else
    repeat
      achange:=FALSE;
      repeat
        getkey(c); c:=upcase(c);
      until ((c in [^H,^M,#32..#255]) or (hangup));
      if (c<>^H) then begin
        outkey(c);
        if (trapping) then write(trapfile,c);
        inc(pap);
      end;
      if (c='/') then begin
        s:=c;
        repeat
          getkey(c); c:=upcase(c);
        until (c in [^H,^M,#32..#255]) or (hangup);
        if (c<>^M) then begin
          case c of
            #225:bb:=bb; {* do nothing *}
          else
               begin
                 outkey(c);
                 if (trapping) then write(trapfile,c);
               end;
          end;
          inc(pap);
        end else
          nl;
        if (c in [^H,#127]) then prompt(' '+c);
        if (c in ['/',#225]) then begin
          bb:=systat.localsec;
          cc:=fstring.echoc;
          if (c=#225) then begin
            systat.localsec:=TRUE;
            fstring.echoc:=' ';
            echo:=FALSE;
          end;
          cl(6); input(s,60);
          systat.localsec:=bb;
          fstring.echoc:=cc;
          echo:=TRUE;
        end else
          if (not (c in [^H,#127,^M])) then begin s:=s+c; nl; end;
      end else
      if (c=';') then begin
        input(s,60);
        s:=c+s;
      end else
      if (c in ['0'..'9']) and ((fqarea) or (mqarea)) then begin
        s:=c; getkey(c);
        if (c in ['0'..'9']) then begin
          print(c);
          s:=s+c;
        end;
        if (c=^M) then nl;
        if (c in [^H,#127]) then prompt(c+' '+c);
      end else
        if (c=^M) then nl
        else
        if (c<>^H) then begin
          s:=c;
          nl;
        end;
    until (not (c in [^H,#127])) or (hangup);
  if (pos(';',s)<>0) then                 {* "command macros" *}
    if (copy(s,1,2)<>'\\') then begin
      if (onekey in thisuser.ac) then begin
        s1:=copy(s,2,length(s)-1);
         if (copy(s1,1,1)='/') then s:=copy(s1,1,2) else s:=copy(s1,1,1);
         s1:=copy(s1,length(s)+1,length(s1)-length(s));
      end else begin
        s1:=copy(s,pos(';',s)+1,length(s)-pos(';',s));
        s:=copy(s,1,pos(';',s)-1);
      end;
      while (pos(';',s1)<>0) do s1[pos(';',s1)]:=^M;
      dm(' '+s1,c);
    end;
end;

end.
