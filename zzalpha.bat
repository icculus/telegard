@echo off
echo 
cecho $09 "þ " $0b "ZIPing up required files"
if exist alpha.zip del alpha.zip
pkzip -ex alpha.zip bbs.exe bbs.ovr \doc\release.doc \doc\beta.doc new*.txt history\ver.txt
copy d:\bbs\afiles\bulletd1.msg bullett.msg
copy d:\bbs\afiles\bulletd1.cfg bullett.cfg
pkzip -ex alpha.zip bullett.msg bullett.cfg
echo 
cecho $03 "- Done."
echo 
