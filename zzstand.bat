@echo off
echo 
cecho $0b "Generating " $0e "STANDARD" $0b " version ...."
echo 
cecho $09 "þ " $0b "Converting current version to STANDARD"
mabs 1
cecho $03 "- Done."
echo 
cecho $09 "þ " $0b "ZIPing up required files"
if exist bbs.zip del bbs.zip
pkzip -ex bbs.zip bbs.exe bbs.ovr \doc\release.doc new*.txt history\ver.txt
copy d:\bbs\afiles\bulletd1.msg bullett.msg
copy d:\bbs\afiles\bulletd1.cfg bullett.cfg
pkzip -ex bbs.zip bullett.msg bullett.cfg
echo 
cecho $03 "- Done."
echo 
cecho $09 "þ " $0b "Converting current version back to ALPHA"
mabs1
cecho $03 "- Done."
echo 
