{$A+,B+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
unit msgpack;

interface

uses
  crt, dos,

  {rcg11172000 no overlay under Linux.}
  {overlay,}

  common,
  mail0;

procedure packbase(fn:string; maxm:longint);

implementation

procedure packbase(fn:string; maxm:longint);
var brdf1,brdf2:file;
    mixf1,mixf2:file of msgindexrec;
    mheader:mheaderrec;
    mixr,mixr2:msgindexrec;
    brdsig,mlength,numm,totload:longint;
    i,j,k:integer;
    s:string;
    done,isemail,sdone:boolean;

  function iseq:boolean;
  var i:integer;
  begin
    iseq:=FALSE;
    if (mixr.isreplytoid<>mixr2.msgid) then exit;
    iseq:=TRUE;
  end;

begin
  fn:=allcaps(fn); isemail:=(fn='EMAIL');
  fn:=systat.msgpath+fn;

  assign(brdf1,fn+'.BRD');
  {$I-} reset(brdf1,1); {$I+}
  if (ioresult<>0) then exit;

  assign(mixf1,fn+'.MIX'); reset(mixf1);

  assign(brdf2,fn+'.PK1'); rewrite(brdf2,1);
  assign(mixf2,fn+'.PK2'); rewrite(mixf2);

  { FIRST makes sure that filesize is greater than max messages...;
    if so, it then finds out how many undeleted messages there are,
    compares that with the max messages for base, and deletes the
    remainder from the beginning of the base.  C'est ‡a, n'est-ce pas? }

  if ((maxm<>0) and (filesize(mixf1)>maxm)) then begin
    numm:=0;
    seek(mixf1,0);
    while (filepos(mixf1)<filesize(mixf1)) do begin
      read(mixf1,mixr);
      if ((miexist in mixr.msgindexstat) and (mixr.hdrptr<>-1)) then inc(numm);
    end;
    if (numm>maxm) then begin
      dec(numm,maxm);
      seek(mixf1,0);
      while ((numm>0) and (filepos(mixf1)<filesize(mixf1))) do begin
        read(mixf1,mixr);
        if ((miexist in mixr.msgindexstat) and
          (not (mipermanent in mixr.msgindexstat))) then
        begin
          mixr.msgindexstat:=mixr.msgindexstat-[miexist];
          seek(mixf1,filepos(mixf1)-1); write(mixf1,mixr);
          dec(numm);
        end;
      end;
    end;
  end;

  i:=0;
  while (i<=filesize(mixf1)-1) do begin
    seek(mixf1,i);
    read(mixf1,mixr);
    if ((miexist in mixr.msgindexstat) and (mixr.hdrptr<>-1)) then begin
      seek(brdf1,mixr.hdrptr);
      loadmhead1(brdf1,i,mheader);
      seek(brdf1,mheader.msgptr);
      mixr.hdrptr:=filesize(brdf2);
      mheader.msgptr:=mixr.hdrptr+sizeof(mheaderrec);
      seek(brdf2,mixr.hdrptr);
      savemhead1(brdf2,mheader);
      totload:=0;
      repeat
        blockreadstr2(brdf1,s);
        blockwritestr2(brdf2,s);
        inc(totload,length(s)+2);
      until (totload>=mheader.msglength);

      if ((not isemail) and (mixr.isreplyto<>65535) and
          (filesize(mixf2)<>0)) then begin
        done:=FALSE; sdone:=FALSE; j:=0; k:=filesize(mixf2);
        seek(mixf2,0);
        while (not done) do begin
          read(mixf2,mixr2);
          if (mixr.isreplytoid=mixr2.msgid) then begin
            done:=TRUE;
            sdone:=TRUE;
          end else begin
            inc(j);
            if (j>=k) then done:=TRUE;
          end;
        end;
        if (sdone) then mixr.isreplyto:=j else mixr.isreplyto:=65535;
        seek(mixf2,filesize(mixf2));
      end;
      write(mixf2,mixr);
    end;
    inc(i);
  end;

  close(brdf1); erase(brdf1);
  close(brdf2); rename(brdf2,fn+'.BRD');
  close(mixf1); erase(mixf1);
  close(mixf2); rename(mixf2,fn+'.MIX');

  if (not isemail) then begin
    assign(brdf,fn+'.BRD'); reset(brdf,1);
    assign(mixf,fn+'.MIX'); reset(mixf,sizeof(mixr));
    findhimsg;
    close(brdf);
    close(mixf);
  end;
end;

end.
