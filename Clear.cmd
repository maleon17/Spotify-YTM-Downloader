:YTM Workspace Cleaner
:Version 1.0

@echo off
title YTM Cleaner
cd /d "%~dp0"

set busy=0
if exist Redistributables\dlProgress set busy=1
if exist Cache set busy=1
if exist YTMusic set busy=1

if %busy%==1 (
echo WARNING: It looks like a download may currently be running, or was interrupted
echo and not yet recovered. Running Download.cmd first will safely recover any
echo partially downloaded tracks before you clean up here.
echo.
echo Continue cleaning anyway? Any in-progress files will be permanently deleted. [Y/N]
choice /c yn /n /m "> "
if errorlevel 2 exit
echo.
)

echo Cleaning temporary files and folders...
if exist Cache rd /s /q Cache
if exist YTMusic rd /s /q YTMusic
if exist Redistributables\dlProgress del /q Redistributables\dlProgress
if exist Redistributables\Track.txt del /q Redistributables\Track.txt
if exist Redistributables\TotalTracks.txt del /q Redistributables\TotalTracks.txt
if exist Redistributables\LastRun.txt del /q Redistributables\LastRun.txt
if exist Redistributables\progressTickerRun.txt del /q Redistributables\progressTickerRun.txt
if exist Redistributables\progressState.txt del /q Redistributables\progressState.txt
if exist Redistributables\progressChomp.txt del /q Redistributables\progressChomp.txt
if exist Redistributables\ytdlp.log del /q Redistributables\ytdlp.log

echo.
echo Workspace cleaned. Your queue (URLs.txt), settings, download history
echo (done_ids.txt) and backups (URLs.txt.bak*) were left untouched.
echo.
echo Would you also like to reset the "already downloaded" history (done_ids.txt)?
echo This is normally NOT necessary, and doing so may cause previously downloaded
echo songs to be re-downloaded if you run the same queue again. [Y/N]
choice /c yn /n /m "> "
if errorlevel 2 goto done
if exist done_ids.txt del /q done_ids.txt
echo Download history reset.

:done
echo.
echo Press any key to exit...
pause >nul
exit
