echo off
c:
cd \tp\telegard
del *.bak
ds en
echo 
type baa2.ans
echo 
cecho $07 "C:\T> " $0b "\com\tp\tpc /m /l " $09 "bbs.pas" $0b " /DAlpha"
cbbs lcbbs.pas
c:\com\tp\tpc /m /l bbs.pas /DAlpha /uc:\com\tp
mabs1
rem mabs 2 mylicens.dat 1
echo 
