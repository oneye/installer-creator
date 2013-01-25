@rem
@rem Copyright © since 2013 Lars Knickrehm, mail@lars-sh.de
@rem
@rem This script creates a pseudo prompt for Windows users to comfortably enter
@rem command line arguments for the installer creator script.

@rem Disable too many output.
@echo off

rem Path to cygwin directory
set cygwin_path=C:\cygwin
if not exist "%cygwin_path%\bin\bash.exe" (
	goto notFound
)

rem Set path variables
set file=%~n0
set path=%~dp0

rem Replace back slashes by slashes and remove colons.
set unix_path=%path:\=/%
set unix_path=%unix_path::=%

rem Show the installer creator help.
echo %path:~0,-1%>"%file%.sh"  --help
bash --login -i -- "/cygdrive/%unix_path%/%file%.sh" --help
echo.

rem Read arguments.
set /P args="%path:~0,-1%>"%file%.sh" "
echo.

rem Remember current working directory in order to revert it correctly.
set old_cd=%CD%
cd /d "%cygwin_path%\bin"

rem Pass through all given arguments.
bash --login -i -- "/cygdrive/%unix_path%/%file%.sh" %args%

rem Revert working directory.
cd /d "%old_cd%"

echo.
pause
goto:eof

:notFound
echo Cygwin not found.
echo.
pause