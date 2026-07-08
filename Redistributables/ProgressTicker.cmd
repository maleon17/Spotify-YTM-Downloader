:YTM Progress Ticker
:Runs detached (via start /b) while a track downloads, so the bar keeps animating
:during long blocking calls. Reads state from progressState.txt and stops as soon
:as progressTickerRun.txt is deleted by the caller.
:Version 1.0

@echo off
:loop
if not exist "%~dp0progressTickerRun.txt" goto :eof
if not exist "%~dp0progressState.txt" goto wait
set "pbState="
set /p pbState=<"%~dp0progressState.txt"
for /f "tokens=1,2,* delims=|" %%a in ("%pbState%") do call "%~dp0ProgressBar.cmd" tick %%a %%b "%%c"
:wait
timeout /t 1 /nobreak >nul
goto loop
