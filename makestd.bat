@Echo Off
Cls
Cbbs Lcbbs.Pas
Ds Dtne
Echo.
Tpc Bbs.Pas /M /L
If Errorlevel 1 Goto Failed
Mabs 0
Echo.
Echo Compile Successful
Goto Stop
:Failed
Echo.
Echo Compile Failed!
:Stop
Echo.
