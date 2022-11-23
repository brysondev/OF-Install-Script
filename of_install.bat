:: OF Install Wrapper Script.
:: https://bry.so
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
setlocal ENABLEEXTENSIONS
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
cd %TEMP%
@RD /S /Q %TEMP%\murse
)

if not exist "%MURSE_PATH%murse.exe" (
    echo Installing Murse CLI...
    echo.
    cd %TEMP%
    md "murse"
    cd "murse"
    powershell -Command "(New-Object Net.WebClient).DownloadFile('https://git.sr.ht/~welt/murse/refs/download/v0.3.2/murse-v0.3.2-windows-386.zip', 'murse.zip')"
    Call :UnZipFile "%MURSE_PATH%" "%MURSE_PATH%murse.zip"
) 
goto verify

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:verify
echo Verifying Murse exists...
cd /D "%MURSE_PATH%"
murse.exe -h

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

:: TODO: Possibly let them input threads, but honestly this should be fine for now...
murse.exe upgrade "%STEAM_REG_PATH%\open_fortress" -1
if %ERRORLEVEL% EQU 1 (
    echo Something went wrong... 
    goto exitmain
)
echo Validating just in case... 
echo This will take a while...
:: Since people are getting confused with the messages output by the verify command, here's a warning.
SETLOCAL EnableExtensions DisableDelayedExpansion
for /F %%a in ('echo prompt $E ^| cmd') do (
  set "ESC=%%a"
)
SETLOCAL EnableDelayedExpansion
echo %ESC%[44mIGNORE ANY ERRORS/MESSAGES ABOUT GAMEUI.DLL!! %ESC%[0m
echo.
murse.exe verify "%STEAM_REG_PATH%\open_fortress" -1 -r 
:: > nul 2>&1
if %ERRORLEVEL% EQU 1 (
    echo Something went wrong... 
    goto exitmain
)
echo. 
echo Finished!

tasklist /fi "ImageName eq steam.exe" /fo csv 2>NUL | find /I "steam.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo Steam is still running! Restarting it now...
    taskkill /F /IM steam.exe
)
TIMEOUT /T 3
tasklist /fi "ImageName eq steam.exe" /fo csv 2>NUL | find /I "steam.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo.
    echo Steam is still running! We can't kill it for some reason. Exiting...
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
echo %ESC%[35mMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNXXKKKKKKKXXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMM%ESC%[0m
echo %ESC%[35mMMMMMMMMMMMMMMMMMMMMMMWWNK0OkxdooolllllllloodxkO0KNWWMWMMMMMMMMMMMMMMMMMMMM%ESC%[0m
echo %ESC%[35mMMMMMMMMMMMMMMMMMMMWNKOxdollllllllllcllllllllllllldxOKNWMMMMMMMMMMMMMMMMMMM%ESC%[0m
echo %ESC%[35mMMMMMMMMMMMMMMMMWN0kdlllllllllllc::;,',;::cllllllllllldk0NWWWMMMMMMMMMMMMMM%ESC%[0m
echo %ESC%[35mMMMMMMMMMMMMMWWKkdllcllllllcccc;'''::;'...';ccccllllllclldkKWWWMMMMMMMMMMMM%ESC%[0m
echo %ESC%[35mMMMMMMMMMMMWWKxolllllllcc:;'..'..oKN0d;.....'..',:cclllllllokKWMMMMMMMMMMMM%ESC%[0m
echo %ESC%[35mMMMMMMMMMMWXkolllllc:;,'''......,OWMKd;............',;:ccllllokXWMMMMMMMMMM%ESC%[0m
echo %ESC%[35mMMMMMMMMMN0dllllll:'.':okOl..,cdONWMKd;.......:xo......':lllllld0NWMMMMMMMM%ESC%[0m
echo %ESC%[35mMMMMMMMWXklllllllc,..dNWMW0k0XWWMMWMKd;.......;l:.......,clllllllkNWWMMMMMM%ESC%[0m
echo %ESC%[35mMMMMMMWXxllllllll:'.;0MWMMMMMMMWNNWMKd:.................':llllllllxXWMMMMMM%ESC%[0m
echo %ESC%[35mMMMMMWXxlclcllclc;..lXMMMMMWN0kOKNWMKd:..................;cclccclclxXWMMMMM%ESC%[0m
echo %ESC%[35mMMMMMNklccccccccc,.'xWWWNKxoclkXWMMMKd;..................,ccccccccclkNMMMMM%ESC%[0m
echo %ESC%[35mMMMMW0occccccccc:..;0MXd;''ckNWMMMMMKd;...................:ccccccccco0WMMMM%ESC%[0m
echo %ESC%[35mMMMMNxcccccccccc,..lXMO,'l0NMWWMMMMMKd;............,,.....,ccccccccccxNMMMM%ESC%[0m
echo %ESC%[35mMMMW0occccccccc:'.'xWWd,dNMMMMMMMMMMKd;............:c.....':cccccccccoKWMMM%ESC%[0m
echo %ESC%[35mMMMWOl:cccccccc;..;0MXccKMMMMMMMMMMMKd;............cd,.....;c:ccccccclOWMMM%ESC%[0m
echo %ESC%[35mMMMNkc:::::::::,..lNMOcxWMMMMMMMMMMMKd;............cO:.....,::c::::::ckWMMM%ESC%[0m
echo %ESC%[35mMMMNkc:::::::::'.'xWWxoXMMMMMMMMMMMMKd;............cKo.....':::::::::ckNMMM%ESC%[0m
echo %ESC%[35mMMMWkc::::::::;..;0MXdkWMMMMMMMMMMMMKd;............cXk'.....;::::::::cOWMMM%ESC%[0m
echo %ESC%[35mMMMW0l::::::::,..lNMKkXMMMMMMMMMMMMMKd;...,:cc:;,'.lXK:.....,::::::::l0WMMM%ESC%[0m
echo %ESC%[35mMMMMXd:::::::;'.'kWWKKWMMMMMMMMMWWMMKd:....,cdk0KK0KWNo.....';:::::;:dXMMMM%ESC%[0m
echo %ESC%[35mMMMMWOc;;;;;;,..;KMWXNMMMMMMMMMMMWWXxc,........,cd0XWWx'.....,;;;;;;cOWMMMM%ESC%[0m
echo %ESC%[35mMMMMMNx:;;;;;'..oNMWWWMMMMMWMWWXOdc,...............;lxd,.....';;;;;:xNMMMMM%ESC%[0m
echo %ESC%[35mMMMMMWKo;;;;,..'kWWWMMMMMMWXOdc,..............................,;;;;oKWMMMMM%ESC%[0m
echo %ESC%[35mMMMMMMWKo;;;,..:KWMMMWWXOdc,.....',,;;;,''....................,;;;oKWMMMMMM%ESC%[0m
echo %ESC%[35mMMMMMMMWXd;,'..oNWWXOdc,.....'',,,,,,,,,,,,,''................',;dXWMMMMMMM%ESC%[0m
echo %ESC%[35mMMMMMMMMWNk:..'oOdc,......',,,,,,,,,,,,,,,,,,,,,'..............:xNWMMMMMMMM%ESC%[0m
echo %ESC%[35mMMMMMMMMMMW0c.........'',,,,,,,,,,,,,,,,,,,,,,,,,,,''.........c0WMMMMMMMMMM%ESC%[0m
echo %ESC%[35mMMMMMMMMMMMMNk:...''',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'''..':kNMMMMMMMMMMMM%ESC%[0m
echo %ESC%[35mMMMMMMMMMMMMMWNOo:,''''''''''''''''''''''''''''''''''''',:oONWMMMMMMMMMMMMM%ESC%[0m
echo %ESC%[35mMMMMMMMMMMMMMMMMWKkl;''''''''''''''''''''''''''''''''';lkKWMMMMMMMMMMMMMMMM%ESC%[0m
echo %ESC%[35mMMMMMMMMMMMMMMMMMMWWKkdc;''''.''''''....''''..'''';cokKWWMMMMMMMMMMMMMMMMMM%ESC%[0m
echo %ESC%[35mMMMMMMMMMMMMMMMMMMMMMMWNKOxol:;,,'''''''''',;:loxOKNWMMMMMMMMMMMMMMMMMMMMMM%ESC%[0m
echo %ESC%[35mMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXK00OOOkOOO00KXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMM%ESC%[0m
echo.
echo Cleaning up...
if exist %MURSE_PATH% ( 
cd %TEMP%
@RD /S /Q %TEMP%\murse
)
goto exitmain

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:exitmain
echo.
echo For any issues you are unsure about regarding the install, kindly leave a message in the offical public Open Fortress Discord in #windows-troubleshooting.
echo Discord: https://discord.gg/mKjW2ACCrm
echo.
PAUSE
EXIT
