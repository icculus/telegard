program tpage;

uses myio,
     crt, dos;

procedure titlepage;
var x,y,col,col1:byte;
    c:char;
begin
{rcg11172000 gay.}
{
  clrscr; cursoron(FALSE);
  textbackground(0); textcolor(0);
  writeln;
  writeln('  ���������    ���������');
  writeln('  �    �����   �    �����');
  writeln('  �    �����   �     ����                  �� �');
  writeln('  ��������     ����������     �����   ��  �   �   �   � ����  �� ����');
  writeln('  �    �����   �     ����      ����� �  � ��  ��  � � � ���� �   ���');
  writeln('  �    �����   �     ����   �������   ��  �    ��  � �   ��� �    �������������');
  writeln('  ���������    �  __�����   ���������������������������������������������������');
  writeln;
  writeln('             P r E s E n T s ! ! ! ! ! !');
  col1:=0;
  repeat
    for x:=3 to 79 do begin
      col1:=col1 mod 2+1;
      case col1 of 1:col:=14; 2:col:=4; end;
      for y:=2 to 8 do mem[vidseg:(160*(y-1)+2*(x-1))+1]:=col;
    end;
    delay(100);
  until (keypressed);
  c:=readkey;
  textcolor(14);
  clrscr; cursoron(TRUE);
}
end;

begin
  checkvidseg;
  titlepage;
end.
