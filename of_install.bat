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

REG QUERY HKCU\SOFTWARE\Valve\Steam\Apps\440 > nul 2>&1
if %ERRORLEVEL% EQU 0 (
	REG QUERY HKCU\SOFTWARE\Valve\Steam\Apps\243750 > nul 2>&1
	if %ERRORLEVEL% EQU 0 (
		goto cont 
	)
)

set /p gameInst="Games not detected. Do you want to install them now? (y/n): "
If /i "%gameInst%"=="y" goto instgm
If /i "%gameInst%"=="n" goto cont

:instgm
echo.
echo Installing TF2...
start "" steam://install/440
echo.
echo Once the game has downloaded successfully, hit enter.
pause
echo.
echo Installing Source SDK 2013 Multiplayer...
start "" steam://install/243750
echo.
echo Once the game has downloaded successfully, hit enter.
pause
goto cont 
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
    set STEAM_REG_PATH=%%C
)

if not exist %STEAM_REG_PATH%\NUL > nul 2>&1(
	if not exist "%STEAM_REG_PATH%\" > nul 2>&1(
		echo Missing registry path for sourcemods. You know you need to download the required games right?
		goto exitmain
	)
)

:: :32bitSteam
:: 01/07/21 - If you don't have any source engine games installed or attempted to have installed, keys don't generate. The paths are still fucked tho...
::
:: Steam fucked up the registry keys for 32 bit systems https://i.imgur.com/w816RTW.png
:: Gotta use HKLM
:: 
:: set PATH_STEAM=HKEY_LOCAL_MACHINE\SOFTWARE\Valve\Steam
:: set VALUE_STEAM=InstallPath
:: 
:: FOR /F "usebackq skip=2 tokens=1,2*" %%A IN (`REG QUERY %PATH_STEAM% /reg:32 /v %VALUE_STEAM% 2^>nul`) DO (
::     set STEAM_REG_PATH=%%C
:: )
:: 
:: set "STEAM_REG_PATH=%STEAM_REG_PATH%\steamapps\sourcemods"
:: 
:: if not exist "%STEAM_REG_PATH%\" (
:: 	echo Something broke...
:: 	goto exitmain
:: )

cd /D %STEAM_REG_PATH%
goto installOF
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:installOF
echo Installing Open Fortress...
echo.
echo.
:: This is such a pain since by default users won't install command line application...
if exist "open_fortress\.svn\wc.db" (
	"%TORT_REG_PATH%" /command:cleanup /path:".\open_fortress" /cleanup /noui /noprogressui /breaklocks /refreshshell /externals /fixtimestamps /vacuum /closeonend:1
	"%TORT_REG_PATH%" /command:update /path:".\open_fortress" /skipprechecks /closeonend:1
	if not %ERRORLEVEL% == 0 (
		echo Found an error. Attempting to relocate, update then cleanup...
		echo.
		"%TORT_REG_PATH%" /command:relocate /path:".\open_fortress" /closeonend:2
		echo Please enter this url inside the box that just popped up: https://svn.openfortress.fun/svn/open_fortress
		echo.
		"%TORT_REG_PATH%" /command:update /path:".\open_fortress" /skipprechecks /closeonend:1
	)
	echo Cleaning up update...
	echo.
	"%TORT_REG_PATH%" /command:cleanup /path:".\open_fortress" /cleanup /noui /noprogressui /breaklocks /refreshshell /externals /fixtimestamps /vacuum /closeonend:2
) ELSE (
	echo Make sure you click ok for the popup as I cannot through this script...
	echo.
	"%TORT_REG_PATH%" /command:checkout /url:https://svn.openfortress.fun/svn/open_fortress /path:".\open_fortress" /closeonend:2
	echo Cleaning up install...
	echo.
	"%TORT_REG_PATH%" /command:cleanup /path:".\open_fortress" /cleanup /noui /noprogressui /breaklocks /refreshshell /externals /fixtimestamps /vacuum /closeonend:2
)
goto finishMain
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:finishMain
echo ======================================
echo Successfully installed Open Fortress!
echo ======================================
echo Please restart Steam (If you aren't updating) by clicking STEAM ^> ^EXIT at the top of the steam client, then restart!
echo.
goto exitmain
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:exitmain
PAUSE