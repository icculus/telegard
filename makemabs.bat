@Echo Off
Cls
If "%1"=="" Goto Normal
Tpc Mabs.Pas /L /M /DAS%1
Goto Cont
:Normal
Tpc Mabs.Pas /L /M
:Cont
Echo.
If Errorlevel 1 Goto Failed
Echo Compile Successful
If "%1"=="" Goto Stop
Rename Mabs.Exe Mabs%1.Exe
Goto Stop
:Failed
Echo Compile Failed!
:Stop
Echo.
