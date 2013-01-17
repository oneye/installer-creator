@echo off

set filepath=%~dpn0
set filepath=%filepath:\=/%
set filepath=%filepath::=%

if exist C:\cygwin\bin\bash.exe (
	cd /d C:\cygwin\bin
	bash --login -i "/cygdrive/%filepath%.sh"
) else (
	echo Cygwin not found.
)

echo.
pause