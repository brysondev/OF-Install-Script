:: OF Install Wrapper Script.
:: https://brysondev.io
:: 
@ECHO OFF
cls
title OF Installer Script for Windows

echo (%TIME%) OF Install Script started.
echo.
echo Please make sure you have the required games installed before pressing continue!
echo Team Fortress 2 and Source SDK 2013 Multiplayer are REQUIRED for this game to run.
echo.
echo Also expect this to freeze a bunch for a fresh install!!
echo.
PAUSE

REG QUERY "HKLM\SOFTWARE\Microsoft\PowerShell\3" > nul 2>&1
if %ERRORLEVEL% EQU 1 (
    echo Missing Powershell v3. Please install it at the following link: https://www.microsoft.com/en-ca/download/details.aspx?id=34595 and re-run this script.
    powershell -Command "start https://www.microsoft.com/en-ca/download/details.aspx?id=34595"
	goto exitmain
)

REG QUERY HKCU\SOFTWARE\Valve\Steam\Apps\440 > nul 2>&1
if %ERRORLEVEL% EQU 0 (
	REG QUERY HKCU\SOFTWARE\Valve\Steam\Apps\243750 > nul 2>&1
	if %ERRORLEVEL% EQU 0 (
		goto murse 
	)
)

set /p gameInst="Games not detected. Do you want to install them now? (y/n): "
If /i "%gameInst%"=="y" goto instgm
If /i "%gameInst%"=="n" goto murse

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
echo Once the game has downloaded successfully.
pause
goto murse

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:murse
echo.
setlocal ENABLEEXTENSIONS
setlocal ENABLEDELAYEDEXPANSION
set MURSE_PATH=%TEMP%\murse\
set PATH_STEAM=HKEY_CURRENT_USER\SOFTWARE\Valve\Steam
set VALUE_STEAM=SourceModInstallPath
set STEAM_EXE=SteamExe

FOR /F "usebackq skip=2 tokens=1,2*" %%A IN (`REG QUERY %PATH_STEAM% /v %VALUE_STEAM% 2^>nul`) DO (
    set STEAM_REG_PATH=%%C
)

if not exist %STEAM_REG_PATH%\NUL > nul 2>&1(
	if not exist "%STEAM_REG_PATH%\" > nul 2>&1(
		echo Missing registry path for sourcemods. You know you need to download the required games right?
		goto exitmain
	)
)

if exist %MURSE_PATH% ( 
cd /D %TEMP%
@RD /S /Q %TEMP%\murse
)

if not exist "%MURSE_PATH%murse.exe" (
    echo Installing Murse CLI...
    echo.
    cd /D %TEMP%
    md "murse"
    cd /D "murse"
    :: For windows 7 backwards compatibility...
    powershell -Command "[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}; [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile('https://git.sr.ht/~webb/murse/refs/download/v0.4.0/murse-v0.4.0-windows-amd64.zip', 'murse.zip')"
    Call :UnZipFile "%MURSE_PATH%" "%MURSE_PATH%murse.zip"
) 
goto verify

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:verify
echo Verifying Murse exists...
cd /D "%MURSE_PATH%"
murse.exe -h > nul 2>&1

if errorlevel 1 (
    echo Murse inaccessable. Verify that murse exists in: %MURSE_PATH%.
    goto exitmain
)

echo.
echo Murse verified!
:: cd /D %STEAM_REG_PATH%
goto installOF

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:UnZipFile <ExtractTo> <newzipfile>
set vbs="%temp%\_.vbs"
if exist %vbs% del /f /q %vbs%
>>%vbs% echo Set fso = CreateObject("Scripting.FileSystemObject")
>>%vbs% echo If NOT fso.FolderExists(%1) Then
>>%vbs% echo fso.CreateFolder(%1)
>>%vbs% echo End If
>>%vbs% echo set objShell = CreateObject("Shell.Application")
>>%vbs% echo set FilesInZip=objShell.NameSpace(%2).items
>>%vbs% echo objShell.NameSpace(%1).CopyHere(FilesInZip)
>>%vbs% echo Set fso = Nothing
>>%vbs% echo Set objShell = Nothing
cscript //nologo %vbs%
if exist %vbs% del /f /q %vbs%
goto verify

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:installOF
echo.
echo Installing Open Fortress...
echo.
:: Since people are getting confused with the messages output by the verify command, here's a warning.
SETLOCAL EnableExtensions DisableDelayedExpansion
for /F %%a in ('echo prompt $E ^| cmd') do (
  set "ESC=%%a"
)
SETLOCAL EnableDelayedExpansion

:: TODO: Possibly let them input threads, but honestly this should be fine for now...
murse.exe upgrade "%STEAM_REG_PATH%\open_fortress"
if %ERRORLEVEL% EQU 1 (
    echo Something went wrong...
    echo %ESC%[101mTry again in 20 minutes or report the issue to the discord server.%ESC%[0m
    goto exitmain
)
echo Validating just in case... 
echo This will take a while...

murse.exe verify "%STEAM_REG_PATH%\open_fortress" -r
:: > nul 2>&1
if %ERRORLEVEL% EQU 1 (
    echo Something went wrong...
    goto exitmain
)
echo. 
echo Finished!

tasklist /fi "ImageName eq steam.exe" /fo csv 2>NUL | find /I "steam.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo Steam is still running. Restarting it now...
    taskkill /F /IM steam.exe
)
TIMEOUT /T 3
tasklist /fi "ImageName eq steam.exe" /fo csv 2>NUL | find /I "steam.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo.
    echo Steam is still running. We can't kill it for some reason. Exiting...
    goto exitmain
)

FOR /F "usebackq skip=2 tokens=1,2*" %%A IN (`REG QUERY %PATH_STEAM% /v %STEAM_EXE% 2^>nul`) DO (
    set STEAM_EXE_LOCATION=%%C
)

start "" "%STEAM_EXE_LOCATION%"

goto finishMain

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:finishMain
echo.
echo %ESC%[42m======================================%ESC%[0m
echo %ESC%[42mSuccessfully installed Open Fortress! %ESC%[0m
echo %ESC%[42m======================================%ESC%[0m
echo.
echo %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0mc%ESC%[0md%ESC%[0m0%ESC%[0m0%ESC%[0mM%ESC%[0mM%ESC%[0mM%ESC%[0mM%ESC%[0mX%ESC%[0m0%ESC%[0mx%ESC%[0ml%ESC%[0m.%ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m
echo %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m.%ESC%[0mo%ESC%[0mk%ESC%[0mX%ESC%[0mM%ESC%[0mM%ESC%[0m%ESC%[37mW%ESC%[0m%ESC%[37mN%ESC%[0m%ESC%[37mX%ESC%[0m%ESC%[34mX%ESC%[0m%ESC%[34mX%ESC%[0m%ESC%[34mX%ESC%[0m%ESC%[34mX%ESC%[0m%ESC%[37mX%ESC%[0m%ESC%[37mN%ESC%[0m%ESC%[37mW%ESC%[0mM%ESC%[0mM%ESC%[0mN%ESC%[0m0%ESC%[0md%ESC%[0m;%ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m
echo %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0mc%ESC%[0mK%ESC%[0mM%ESC%[0mM%ESC%[0m%ESC%[37mN%ESC%[0m%ESC%[34mK%ESC%[0m%ESC%[34mO%ESC%[0m%ESC%[34mx%ESC%[0m%ESC%[34mo%ESC%[0m%ESC%[34mo%ESC%[0m%ESC%[34mo%ESC%[0m%ESC%[34mo%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34mo%ESC%[0m%ESC%[34mo%ESC%[0m%ESC%[34mo%ESC%[0m%ESC%[34mo%ESC%[0m%ESC%[34md%ESC%[0m%ESC%[34mk%ESC%[0m%ESC%[34m0%ESC%[0m%ESC%[37mX%ESC%[0m%ESC%[37mW%ESC%[0mM%ESC%[0mN%ESC%[0mo%ESC%[0m.%ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m
echo %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0md%ESC%[0mW%ESC%[0mM%ESC%[0m%ESC%[37mN%ESC%[0m%ESC%[34mO%ESC%[0m%ESC%[34mx%ESC%[0m%ESC%[34mo%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34m;%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34md%ESC%[0m%ESC%[34mk%ESC%[0m%ESC%[34mX%ESC%[0mM%ESC%[0mM%ESC%[0mO%ESC%[0m.%ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m
echo %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0mo%ESC%[0mW%ESC%[0mM%ESC%[0m%ESC%[37mN%ESC%[0m%ESC%[34mk%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m;%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m'%ESC%[0mN%ESC%[0mW%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[34m;%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34mx%ESC%[0m%ESC%[34mK%ESC%[0mW%ESC%[0mM%ESC%[0mk%ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m
echo %ESC%[0m %ESC%[0m %ESC%[0mo%ESC%[0mM%ESC%[0mW%ESC%[0m%ESC%[34mO%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[37m;%ESC%[0m%ESC%[37mK%ESC%[0mW%ESC%[0m%ESC%[37m0%ESC%[0m%ESC%[37mk%ESC%[0m%ESC%[37mK%ESC%[0mW%ESC%[0mM%ESC%[0mW%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[37mo%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34mx%ESC%[0m%ESC%[37mW%ESC%[0mM%ESC%[0mK%ESC%[0m %ESC%[0m %ESC%[0m
echo %ESC%[0m %ESC%[0m:%ESC%[0mM%ESC%[0m%ESC%[37mW%ESC%[0m%ESC%[34mx%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[37mk%ESC%[0mM%ESC%[0mM%ESC%[0mM%ESC%[0mN%ESC%[0m%ESC%[37m0%ESC%[0mX%ESC%[0mW%ESC%[0mW%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34mo%ESC%[0m%ESC%[37mN%ESC%[0mM%ESC%[0mO%ESC%[0m %ESC%[0m
echo %ESC%[0m %ESC%[0mM%ESC%[0mM%ESC%[0m%ESC%[34mk%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m.%ESC%[0mW%ESC%[0mN%ESC%[0m%ESC%[37mo%ESC%[0m%ESC%[37ml%ESC%[0m%ESC%[37mx%ESC%[0mX%ESC%[0mM%ESC%[0mM%ESC%[0mW%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[34mo%ESC%[0m%ESC%[37mW%ESC%[0mM%ESC%[0m;%ESC%[0m
echo %ESC%[0mc%ESC%[0mM%ESC%[0m%ESC%[37mN%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[37ml%ESC%[0mM%ESC%[0m%ESC%[37md%ESC%[0m%ESC%[37ml%ESC%[0mW%ESC%[0mM%ESC%[0mM%ESC%[0mM%ESC%[0mM%ESC%[0mW%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[37ml%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m;%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[34m0%ESC%[0mM%ESC%[0mN%ESC%[0m
echo %ESC%[0mO%ESC%[0mM%ESC%[0m%ESC%[34m0%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m;%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[37m0%ESC%[0mW%ESC%[0m%ESC%[37mc%ESC%[0mN%ESC%[0mM%ESC%[0mM%ESC%[0mM%ESC%[0mM%ESC%[0mM%ESC%[0mW%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[37md%ESC%[0m%ESC%[37m:%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34mx%ESC%[0mM%ESC%[0mW%ESC%[0m
echo %ESC%[0mo%ESC%[0mM%ESC%[0m%ESC%[34m0%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m,%ESC%[0mW%ESC%[0mX%ESC%[0m%ESC%[37mO%ESC%[0mM%ESC%[0mM%ESC%[0mM%ESC%[0mM%ESC%[0mM%ESC%[0mM%ESC%[0mW%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[37mx%ESC%[0m%ESC%[37mk%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34mx%ESC%[0mM%ESC%[0mX%ESC%[0m
echo %ESC%[0m.%ESC%[0mM%ESC%[0m%ESC%[37mN%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[37md%ESC%[0mM%ESC%[0m%ESC%[37m0%ESC%[0mW%ESC%[0mM%ESC%[0mM%ESC%[0mM%ESC%[0mM%ESC%[0mM%ESC%[0mM%ESC%[0mW%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[37mc%ESC%[0m%ESC%[37mo%ESC%[0m%ESC%[37mx%ESC%[0m%ESC%[37md%ESC%[0m%ESC%[37mK%ESC%[0mN%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m;%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m0%ESC%[0mM%ESC%[0mo%ESC%[0m
echo %ESC%[0m %ESC%[0mo%ESC%[0mM%ESC%[0m%ESC%[34mx%ESC%[0m%ESC%[34m;%ESC%[0m%ESC%[34m;%ESC%[0m%ESC%[34m;%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[34m.%ESC%[0mX%ESC%[0mM%ESC%[0mN%ESC%[0mM%ESC%[0mM%ESC%[0mM%ESC%[0mM%ESC%[0mM%ESC%[0mN%ESC%[0m%ESC%[37m0%ESC%[0m%ESC%[37md%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[37ml%ESC%[0m%ESC%[37mx%ESC%[0m%ESC%[37mK%ESC%[0m%ESC%[37m;%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m;%ESC%[0m%ESC%[34m;%ESC%[0m%ESC%[34m;%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[37mW%ESC%[0mX%ESC%[0m %ESC%[0m
echo %ESC%[0m %ESC%[0m %ESC%[0mk%ESC%[0mW%ESC%[0m%ESC%[34md%ESC%[0m%ESC%[34m;%ESC%[0m%ESC%[34m;%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[37m;%ESC%[0mM%ESC%[0mM%ESC%[0mM%ESC%[0mW%ESC%[0m%ESC%[37mX%ESC%[0m%ESC%[37mk%ESC%[0m%ESC%[37ml%ESC%[0m%ESC%[34m;%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m;%ESC%[0m%ESC%[34m;%ESC%[0m%ESC%[34mc%ESC%[0m%ESC%[37mX%ESC%[0mW%ESC%[0m %ESC%[0m %ESC%[0m
echo %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0mK%ESC%[0mW%ESC%[0m%ESC%[34mk%ESC%[0m%ESC%[34m;%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[37mo%ESC%[0m%ESC%[37mX%ESC%[0m%ESC%[37mk%ESC%[0m%ESC%[37ml%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34mo%ESC%[0m%ESC%[37mN%ESC%[0mM%ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m
echo %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m.%ESC%[0mM%ESC%[0m%ESC%[37mX%ESC%[0m%ESC%[37ml%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[34m,%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[37m;%ESC%[0m%ESC%[37mO%ESC%[0mW%ESC%[0mc%ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m
echo %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0mK%ESC%[0m%ESC%[37mX%ESC%[0m%ESC%[34md%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m;%ESC%[0m%ESC%[34mo%ESC%[0m%ESC%[37m0%ESC%[0mW%ESC%[0m.%ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m
echo %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0ml%ESC%[0mW%ESC%[0m%ESC%[37mX%ESC%[0m%ESC%[37mk%ESC%[0m%ESC%[34mo%ESC%[0m%ESC%[34m:%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m.%ESC%[0m%ESC%[34m'%ESC%[0m%ESC%[34m;%ESC%[0m%ESC%[34ml%ESC%[0m%ESC%[34mx%ESC%[0m%ESC%[37m0%ESC%[0mW%ESC%[0m0%ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m
echo %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0mc%ESC%[0mN%ESC%[0m%ESC%[37mX%ESC%[0m%ESC%[37mK%ESC%[0m%ESC%[37m0%ESC%[0m%ESC%[37mO%ESC%[0m%ESC%[37mO%ESC%[0m%ESC%[37m0%ESC%[0m%ESC%[37m0%ESC%[0m%ESC%[37mK%ESC%[0m%ESC%[37mN%ESC%[0mk%ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m
echo %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m.%ESC%[0m.%ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m %ESC%[0m
echo.
echo Cleaning up...
if exist %MURSE_PATH% ( 
cd /D %TEMP%
@RD /S /Q %TEMP%\murse
)
goto exitmain

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:exitmain
echo.
echo For any issues you are unsure about regarding the install, kindly leave a message in the offical public Open Fortress Discord in #windows-troubleshooting.
echo Please include the entire output of the script so we can assist you.
echo Discord: https://discord.gg/mKjW2ACCrm
echo.
PAUSE
EXIT
