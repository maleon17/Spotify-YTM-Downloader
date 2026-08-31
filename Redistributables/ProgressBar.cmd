:YTM Progress Bar Helper
:Version 1.0.1
:Usage:
:  call ProgressBar.cmd draw <current> <total> <label>   - redraw the bar in place
:  call ProgressBar.cmd tick <current> <total> <label>   - redraw and flip the chomp animation
:  call ProgressBar.cmd log "some message"               - print a permanent line above the bar
:  call ProgressBar.cmd done                             - clear the bar and move to a fresh line

@echo off
if not defined BS for /F %%a in ('"prompt $H &for %%b in (1) do rem"') do set "BS=%%a"
if not defined pbErase (
	set "pbBlank=                                                                                          "
	set "pbErase=%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%%BS%"
)

if /i "%~1"=="draw" goto :pbDraw
if /i "%~1"=="tick" goto :pbDraw
if /i "%~1"=="log" goto :pbLog
if /i "%~1"=="done" goto :pbDone
goto :eof

:pbDraw
set "pbMode=%~1"
set "pbCurrent=%~2"
set "pbTotal=%~3"
set "pbLabel=%~4"
if not defined pbCurrent set "pbCurrent=0"
if not defined pbTotal set "pbTotal=0"
if "%pbTotal%"=="0" set "pbTotal=1"
set /a pbPercent=pbCurrent*100/pbTotal
if %pbPercent% GTR 100 set "pbPercent=100"
set /a pbFilled=29*pbCurrent/pbTotal
if %pbFilled% GTR 29 set "pbFilled=29"
if %pbFilled% LSS 0 set "pbFilled=0"
set /a pbEmpty=29-pbFilled

set "pbChomp=C"
if exist "%~dp0progressChomp.txt" set /p pbChomp=<"%~dp0progressChomp.txt"
if not defined pbChomp set "pbChomp=C"
set "pbChompNew="
if /i "%pbMode%"=="tick" if "%pbChomp%"=="C" set "pbChompNew=c"
if /i "%pbMode%"=="tick" if not "%pbChomp%"=="C" set "pbChompNew=C"
if defined pbChompNew set "pbChomp=%pbChompNew%"
if /i "%pbMode%"=="tick" >"%~dp0progressChomp.txt" echo %pbChomp%

set "pbFullEquals=========================================="
set "pbFullDashes=--------------------------------------------"
call set "pbFilledStr=%%pbFullEquals:~0,%pbFilled%%%"
call set "pbEmptyStr=%%pbFullDashes:~0,%pbEmpty%%%"
set "pbBar=%pbFilledStr%%pbChomp%%pbEmptyStr%"

set "pbLabelPadded=%pbLabel%                              "
set "pbLabelFixed=%pbLabelPadded:~0,28%"

set "pbLine=%pbCurrent%/%pbTotal% %pbLabelFixed% [%pbBar%] %pbPercent%%%     "
echo|set /p ="%pbErase%%pbBlank%%pbErase%%pbLine%"
goto :eof

:pbLog
echo|set /p ="%pbErase%%pbBlank%%pbErase%"
echo %~2
goto :eof

:pbDone
echo|set /p ="%pbErase%%pbBlank%%pbErase%"
echo:
if exist "%~dp0progressChomp.txt" del /q "%~dp0progressChomp.txt"
goto :eof
