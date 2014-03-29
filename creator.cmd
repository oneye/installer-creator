@rem
@rem Copyright © since 2013 Lars Knickrehm, mail@lars-sh.de
@rem
@rem This script creates a pseudo prompt for Windows users to comfortably enter
@rem command line arguments for the installer creator script.

@rem Disable too many output.
@echo off

rem Path to cygwin directory
set cygwin_path=C:\cygwin64
if not exist "%cygwin_path%\bin\bash.exe" (
	goto notFound
)

rem Set path variables
set file=%~n0
set path=%~dp0

rem Lower case drive letter, replace back slashes by slashes and remove colons.
set drive=%path:~0,1%
SET drive=%drive:A=a%
SET drive=%drive:B=b%
SET drive=%drive:C=c%
SET drive=%drive:D=d%
SET drive=%drive:E=e%
SET drive=%drive:F=f%
SET drive=%drive:G=g%
SET drive=%drive:H=h%
SET drive=%drive:I=i%
SET drive=%drive:J=j%
SET drive=%drive:K=k%
SET drive=%drive:L=l%
SET drive=%drive:M=m%
SET drive=%drive:n=n%
SET drive=%drive:O=o%
SET drive=%drive:P=p%
SET drive=%drive:Q=q%
SET drive=%drive:R=r%
SET drive=%drive:S=s%
SET drive=%drive:T=t%
SET drive=%drive:U=u%
SET drive=%drive:V=v%
SET drive=%drive:W=w%
SET drive=%drive:X=x%
SET drive=%drive:Y=y%
SET drive=%drive:Z=z%
set unix_path=%path:\=/%
set unix_path=%drive%%unix_path:~2%

rem Remember current working directory in order to revert it correctly.
set old_cd=%CD%
cd /d "%cygwin_path%\bin"

rem Show the installer creator help.
echo %path:~0,-1%>"%file%.sh" --help
bash --login -i -- "/cygdrive/%unix_path%/%file%.sh" --help
echo.

rem Read arguments.
set /P args="%path:~0,-1%>%file%.sh "
echo.

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