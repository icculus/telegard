@Echo Off
Cls
Ds Ne
If Exist C:\Source.Zip Del C:\Source.Zip
Pkzip -A C:\Source Make*.Bat *.Obj *.Pas
Echo.
