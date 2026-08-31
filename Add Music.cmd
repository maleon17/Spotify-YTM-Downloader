:YTM Music Scraper
:Originally created by Tristian Dedinas - https://github.com/Tech-How/YouTube-Music-Downloader
:Version 1.0.1

:Uses third-party licenses
:yt-dlp - https://github.com/yt-dlp/yt-dlp

@echo off
title YTM Downloader
goto integritycheck
:integritypass
cls
set checkBusy=0
if exist Cache set /a checkBusy=%checkBusy%+1
if exist YTMusic set /a checkBusy=%checkBusy%+1
if %checkBusy%==2 echo Not so fast^! It appears music is already being downloaded. && echo Please wait for the current download to finish. && echo. && echo If this isn't the case, another download may have been interrupted. && echo Just run Download.cmd - it will safely recover it. Or run Clear.cmd to clean up. && pause && exit

:start
:yt-dl-update
set engineUpdatesAllowed=0
set lastUpdateCheck=0
if exist Settings\engineUpdatesAllowed.txt set/p engineUpdatesAllowed=<Settings\engineUpdatesAllowed.txt
set engineUpdatesAllowed=%engineUpdatesAllowed: =%
if %engineUpdatesAllowed%==false goto yt-dl-update-skip
if exist Settings\lastUpdateCheck.txt set/p lastUpdateCheck=<Settings\lastUpdateCheck.txt
set lastUpdateCheck=%lastUpdateCheck: =%
for /F "tokens=2 delims=. " %%a in ("%date%") do set "currentDate=%%a"
if "%currentDate%" equ "%lastUpdateCheck%" goto yt-dl-update-skip
echo Checking for engine updates...
Redistributables\YouTube-DL\youtube-dl.exe --update >nul 2>&1
echo %currentDate% > Settings\lastUpdateCheck.txt
echo true > Settings\engineUpdatesAllowed.txt
cls

:yt-dl-update-skip
goto help

:prompt
if not exist "%~dp0URLs.txt" goto skip_count
set trackcount=0
for /f "tokens=* usebackq" %%a in (`find /v /c "" "%~dp0URLs.txt"`) do set trackcount=%%a
for /f "tokens=3 delims=:" %%f in ("%trackcount%") do set trackcount=%%f
set trackcount=%trackcount: =%
set pl=items
if %trackcount%== 1 set pl=item
echo %trackcount% %pl% queued
echo ----------------

:skip_count
set/p "URL=Paste your link here: "
echo "%URL%"|find "beatbump.io/listen?id" >nul
if %errorlevel% neq 1 set URL=%URL:beatbump.io/listen?id=youtube.com/watch?v% && goto parseNow
echo "%URL%"|find "open.spotify.com" >nul
if not errorlevel 1 goto spotifyFlow
echo "%URL%"|find "music.youtube.com" >nul
if errorlevel 1 goto error
set URL=%URL:music=www%

:parseNow
cls
title Loading...
echo Please wait while your music is being prepared. This may take a few minutes.
echo ...
timeout 1 /nobreak >nul
echo Fetching track information for URL:
echo %URL%

echo "%URL%"|find "playlist?list=" >nul
if %errorlevel% equ 0 goto fetchPlaylistFull
Redistributables\YouTube-DL\youtube-dl.exe --ffmpeg-location "%~dp0Redistributables\FFMPEG\bin\ffmpeg.exe" -i --get-id "%URL%" >> "%~dp0URLs.txt"
if errorlevel 1 (
	echo.
	echo ERROR: yt-dlp could not read that YouTube Music link.
	echo Press any key to continue...
	pause >nul
	goto prompt
)
goto fetchDone

:fetchPlaylistFull
call :ensurePython
if not defined pythonCmd goto prompt
%pythonCmd% "%~dp0Redistributables\Scripts\get_playlist_ids.py" "%URL%" >> "%~dp0URLs.txt"
if errorlevel 1 (
	echo.
	echo ERROR: The YouTube Music playlist could not be added.
	echo Press any key to continue...
	pause >nul
	goto prompt
)

:fetchDone
cls
title YTM Downloader
echo Success^!
echo.
echo To download this music now, close this script and run the downloader.
echo You can also add more music to download below.
echo.
echo.
goto prompt

:spotifyFlow
call :ensurePython
if not defined pythonCmd goto prompt
cls
title Loading...
echo Please wait while your music is being matched on YouTube Music.
echo This can take a while for large playlists - each track is searched individually.
echo.
%pythonCmd% "%~dp0Redistributables\Scripts\get_spotify_ids.py" "%URL%" >> "%~dp0URLs.txt"
set "spotifyExit=%errorlevel%"
if "%spotifyExit%"=="1" (
	echo.
	echo Press any key to continue...
	pause >nul
	goto prompt
)
if "%spotifyExit%"=="2" (
	echo.
	echo Press any key to continue...
	pause >nul
)
goto fetchDone

:ensurePython
if defined pythonCmd goto :eof
where python3 >nul 2>&1
if not errorlevel 1 (set "pythonCmd=python3" & goto :eof)
where python >nul 2>&1
if not errorlevel 1 (set "pythonCmd=python" & goto :eof)
cls
echo ERROR: Python was not found, but this feature needs it.
echo Install it from https://www.python.org/downloads/ ^(tick "Add python.exe to PATH"
echo during install^), run Setup.cmd to install the required packages, then try again.
echo.
echo Single YouTube Music song links ^(not playlists/albums^) still work without Python.
echo.
echo Press any key to continue...
pause >nul
goto :eof

:error
cls
echo ERROR: The link you provided is not a valid YouTube Music or Spotify link.
echo.
goto prompt

:integritycheck
if not exist Redistributables\FFMPEG\bin goto prepare_redistributables
if not exist Redistributables\YouTube-DL\youtube-dl.exe goto prepare_redistributables
if not exist Redistributables\AlbumArtDownloader\aad.exe goto prepare_redistributables
:integritycheck_resume
set integrityverification=2
if not exist "Add Music.cmd" set integrityverification=1 && echo Missing "Add Music.cmd"
if not exist "Download.cmd" set integrityverification=1 && echo Missing "Download.cmd"
if not exist "Import.cmd" set integrityverification=1 && echo Missing "Import.cmd"
if not exist "Find Duplicates.cmd" set integrityverification=1 && echo Missing "Find Duplicates.cmd"
if not exist "Clear.cmd" set integrityverification=1 && echo Missing "Clear.cmd"
if not exist "Redistributables\AlbumArtDownloader\aad.exe" set integrityverification=1 && echo Missing "Redistributables\AlbumArtDownloader\aad.exe"
if not exist "Redistributables\FFMPEG\bin\ffmpeg.exe" set integrityverification=1 && echo Missing "Redistributables\FFMPEG\bin\ffmpeg.exe"
if not exist "Redistributables\YouTube-DL\youtube-dl.exe" set integrityverification=1 && echo Missing "Redistributables\YouTube-DL\youtube-dl.exe"
if not exist "Redistributables\Downloader.cmd" set integrityverification=1 && echo Missing "Redistributables\Downloader.cmd"
if not exist "Redistributables\ProgressBar.cmd" set integrityverification=1 && echo Missing "Redistributables\ProgressBar.cmd"
if not exist "Redistributables\ProgressTicker.cmd" set integrityverification=1 && echo Missing "Redistributables\ProgressTicker.cmd"
if not exist "Redistributables\Get Info.cmd" set integrityverification=1 && echo Missing "Redistributables\Get Info.cmd"
if not exist "Redistributables\Sleep.vbs" set integrityverification=1 && echo Missing "Redistributables\Sleep.vbs"
if %integrityverification%== 2 goto integritypass
echo.
echo One or more of the required redistributables is missing or not found. Please visit this project on GitHub.
echo The program cannot continue.
timeout -1 /nobreak >nul
exit

:prepare_redistributables
echo Setting up...
echo.
if exist Redistributables\YouTube-DL\yt-dlp.exe ren Redistributables\YouTube-DL\yt-dlp.exe youtube-dl.exe
for %%z in ("Redistributables\FFMPEG\*.zip") do (
tar.exe -x -f "%%z" -C "Redistributables\FFMPEG" >nul 2>&1
del /q "%%z"
)
for /d %%d in ("Redistributables\FFMPEG\ffmpeg-*") do (
if exist "%%d\bin" move /y "%%d\bin" "Redistributables\FFMPEG\" >nul 2>&1
if exist "%%d\doc" move /y "%%d\doc" "Redistributables\FFMPEG\" >nul 2>&1
if exist "%%d\presets" move /y "%%d\presets" "Redistributables\FFMPEG\" >nul 2>&1
if exist "%%d\LICENSE" move /y "%%d\LICENSE" "Redistributables\FFMPEG\" >nul 2>&1
if exist "%%d\README.txt" move /y "%%d\README.txt" "Redistributables\FFMPEG\" >nul 2>&1
rd /s /q "%%d" >nul 2>&1
)
if exist "C:\Program Files\AlbumArtDownloader\aad.exe" xcopy /e /i /y "C:\Program Files\AlbumArtDownloader\*" "Redistributables\AlbumArtDownloader\" >nul 2>&1
if exist "C:\Program Files (x86)\AlbumArtDownloader\aad.exe" xcopy /e /i /y "C:\Program Files (x86)\AlbumArtDownloader\*" "Redistributables\AlbumArtDownloader\" >nul 2>&1
if exist "Redistributables\AlbumArtDownloader\AlbumArt.exe" del /q "Redistributables\AlbumArtDownloader\AlbumArt.exe"
if exist "Redistributables\AlbumArtDownloader\aad.exe" if exist "Redistributables\msg.exe" Redistributables\msg.exe %username% All required files from AlbumArtDownloader have been copied to this project folder.
goto integritycheck_resume

:help
if exist Settings\helpShown.txt goto prompt
if exist Settings echo shown > Settings\helpShown.txt
echo -----------------------------------------------------------------------------------
echo Please read the README before using this program^!
echo.
echo Here you can queue music to be saved by the downloader.
echo.
echo - To begin, visit https://music.youtube.com in your browser.
echo - Search for songs, playlists, or albums.
echo - Right-click on the item, and select share to grab the link.
echo.
echo Spotify track/album/playlist links (open.spotify.com) are also accepted.
echo Track names are matched against YouTube Music and downloaded from there -
echo audio is never pulled from Spotify itself.
echo.
echo NOTE: Please ensure you are NOT selecting a video, as they are not yet compatible.
echo -----------------------------------------------------------------------------------
echo.
goto prompt
