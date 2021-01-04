:: OF Install Script by Bryson :)
::
@ECHO OFF
cls
title OF Installer Script for Windows v1.0

echo (%TIME%) OF Install Script started.
echo.
echo Please make sure you have the required games installed before pressing continue!
echo Team Fortress 2 and Source SDK 2013 Multiplayer are REQUIRED for this game to run.
echo.
pause
:: lol i don't know how to get a browser to open properly
:: set /p gameInst="Do you want to install them now? (y/n): "
:: If /i "%gameInst%"=="y" goto instgm
:: If /i "%gameInst%"=="n" goto cont
:: 
:: :instgm
:: start steam://install/440
:: pause
:: start steam://install/243750
:: pause
:: goto cont 
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:cont
setlocal ENABLEEXTENSIONS
set PATH_TORT=HKEY_LOCAL_MACHINE\SOFTWARE\TortoiseSVN
set VALUE_TORT=ProcPath

FOR /F "usebackq skip=2 tokens=1,2*" %%A IN (`REG QUERY %PATH_TORT% /v %VALUE_TORT% 2^>nul`) DO (
    set ValueName=%%A
    set ValueType=%%B
    set TORT_REG_PATH=%%C
)

if not exist "%TORT_REG_PATH%" (
	echo TortiseSVN not installed!
	goto exitmain
)

set PATH_STEAM=HKEY_CURRENT_USER\SOFTWARE\Valve\Steam
set VALUE_STEAM=SourceModInstallPath

FOR /F "usebackq skip=2 tokens=1,2*" %%A IN (`REG QUERY %PATH_STEAM% /v %VALUE_STEAM% 2^>nul`) DO (
    set ValueName2=%%A
    set ValueType2=%%B
    set STEAM_REG_PATH=%%C
)

if not exist %STEAM_REG_PATH%\NUL (
	echo Steam not installed! ^(Or you've messed with your registry...^)
	goto exitmain
)

cd /D %STEAM_REG_PATH%
goto installOF
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:installOF
echo Installing...
echo.
echo Just press "OK" for anything that pops up. Everything is setup for you!
echo.
if exist "open_fortress\.svn\wc.db" (
	"%TORT_REG_PATH%" /command:update /path:".\open_fortress" /skipprechecks /closeonend:0
	echo Cleaning up...
	echo.
	"%TORT_REG_PATH%" /command:cleanup /path:".\open_fortress" /noui /noprogressui /breaklocks /refreshshell /externals /fixtimestamps /vacuum /closeonend:0
) ELSE (
	"%TORT_REG_PATH%" /command:checkout /url:https://svn.openfortress.fun/svn/open_fortress /path:".\open_fortress" /closeonend:0
	echo Cleaning up...
	echo.
	"%TORT_REG_PATH%" /command:cleanup /path:".\open_fortress" /noui /noprogressui /breaklocks /refreshshell /externals /fixtimestamps /vacuum /closeonend:0
)
goto finishMain
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:finishMain
echo ======================================
echo Succussfully installed Open Fortress!
echo ======================================
echo Please restart Steam (If you aren't updating) by clicking STEAM ^> ^EXIT at the top of the steam client, then restart!
echo.
goto exitmain
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:exitmain
PAUSE