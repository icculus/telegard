@echo off
echo 
cecho $0b "Generating " $0e "BETA" $0b " version ...."
echo 
cecho $09 "þ " $0b "Converting current version to BETA"
mabs 3
cecho $03 "- Done."
echo 
cecho $09 "þ " $0b "ZIPing up required files"
if exist beta.zip del beta.zip
pkzip -ex beta.zip bbs.exe bbs.ovr \doc\release.doc \doc\beta.doc new*.txt history\ver.txt
copy d:\bbs\afiles\bulletd1.msg bullett.msg
copy d:\bbs\afiles\bulletd1.cfg bullett.cfg
pkzip -ex beta.zip bullett.msg bullett.cfg
echo 
cecho $03 "- Done."
echo 
cecho $09 "þ " $0b "Converting current version back to ALPHA"
mabs1
cecho $03 "- Done."
echo 
