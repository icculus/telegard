@echo off
copy mabs.pas mabs%1.pas
call c mabs%1 /DAS%1
del mabs%1.pas
