@Echo Off
Cls
Tpc Miniterm.Pas /L /M
Echo.
If Errorlevel 1 Goto Failed
Echo Compile Successful
Goto Stop
:Failed
Echo Compile Failed!
:Stop
Echo.
