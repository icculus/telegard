unit windows;

interface

uses crt,dos;

procedure box(linetype,TLX,TLY,BRX,BRY:integer);
procedure setwindow(WindNum,TLX,TLY,BRX,BRY,TColr,BColr,BoxType:integer);
procedure removewindow(windno:integer);
procedure color(FG,BG:integer);

implementation

var
  scrn:array[1..1,0..4003] of byte;

procedure color(FG,BG:integer);
begin
  textColor(FG);
  textBackground(BG);
end;

procedure box(linetype,TLX,TLY,BRX,BRY:integer);
var i,j:integer;
    TL,TR,BL,BR,HLine,VLine:char;
Begin
  window(1,1,80,25);
  case linetype of
    1:begin
        TL := #218; TR := #191; BL := #192; BR := #217;
        VLine := #179; HLine := #196;
      end;
    2:begin
        TL := #201; TR := #187; BL := #200; BR := #188;
        VLine := #186; HLine := #205;
      end;
    3:begin
        TL := #176; TR := #176; BL := #176; BR := #176;
        VLine := #176; HLine := #176;
      end;
    4:begin
        TL := #177; TR := #177; BL := #177; BR := #177;
        VLine := #177; HLine := #177;
      end;
    5:begin
        TL := #178; TR := #178; BL := #178; BR := #178;
        VLine := #178; HLine := #178;
      end;
    6:begin
        TL := #219; TR := #219; BL := #219; BR := #219;
        VLine := #219; HLine := #219;
      end;
  else
      begin
        TL := #32; TR := #32; BL := #32; BR := #32;
        VLine := #32; HLine := #32;
      end;
  end;
  gotoxy(TLX,TLY); write(TL);
  gotoxy(BRX,TLY); write(TR);
  gotoxy(TLX,BRY); write(BL);
  gotoxy(BRX,BRY); write(BR);
  for i:=TLX+1 to BRX-1 do
  begin
    gotoxy(i,TLY);
    write(HLine);
  end;
  for i:=TLX+1 to BRX-1 do
  begin
    gotoxy(i,BRY);
    write(HLine);
  end;
  for i:=TLY+1 to BRY-1 do
  begin
    gotoxy(TLX,i);
    write(VLine);
  end;
  for i:=TLY+1 to BRY-1 do
  begin
    gotoxy(BRX,I);
    write(VLine);
  end;
  if linetype>0 then window(TLX+1,TLY+1,BRX-1,BRY-1)
                else window(TLX,TLY,BRX,BRY);
end;

procedure setwindow(WindNum,TLX,TLY,BRX,BRY,TColr,BColr,BoxType: integer);
var i:integer;

  procedure savescreen(WindNo,TLX,TLY,BRX,BRY:integer);
  var x,y,i:integer;
  begin
{rcg11172000 sux}
{
    scrn[windno,4000]:=TLX; scrn[windno,4001]:=TLY;
    scrn[windno,4002]:=BRX; scrn[windno,4003]:=BRY;

    i:=0;
    for y:=TLY to BRY do
      for x:=TLX to BRX do begin
        scrn[WindNo,i]:=mem[$B800:(160*(y-1)+2*(x-1))];
        scrn[WindNo,i+1]:=mem[$B800:(160*(y-1)+2*(x-1))+1];
        i:=i+2;
      end;
}

    writeln('STUB: windows.pas; savescreen()...');
  end;



begin
  savescreen(WindNum,TLX,TLY,BRX,BRY);     { save under window }
  window(TLX,TLY,BRX,BRY);                 { set window size }
  color(TColr,BColr);                      { set window colors }
  clrScr;                                  { clear window for action }
  box(BoxType,TLX,TLY,BRX,BRY);            { Set the border }
end;

procedure removewindow(windno:integer);
var TLX,TLY,BRX,BRY,x,y,i:integer;
begin
  window(1,1,80,25);                       { set back to full screen }
  color(14,0);

{rcg11172000 sux}
{
  TLX:=scrn[windno,4000]; TLY:=scrn[windno,4001];
  BRX:=scrn[windno,4002]; BRY:=scrn[windno,4003];

  i:=0;
  for y:=TLY to BRY do
    for x:=TLX to BRX do begin
      mem[$B800:(160*(y-1)+2*(x-1))]:=scrn[windno,i];
      mem[$B800:(160*(y-1)+2*(x-1))+1]:=scrn[windno,i+1];
      i:=i+2;
    end;
}
    writeln('STUB: windows.pas; removewindow()...');
end;

end.
