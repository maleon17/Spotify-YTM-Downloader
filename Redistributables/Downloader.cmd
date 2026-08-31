:YTM Download Script
:Originally created by Tristian Dedinas - https://github.com/Tech-How/YouTube-Music-Downloader
:Version 1.0.1

:Uses third-party licenses
:yt-dlp - https://github.com/yt-dlp/yt-dlp
:ffmpeg - https://ffmpeg.org/
:Album Art Downloader - https://sourceforge.net/projects/album-art/

@echo off
setlocal
set "URL=%1"
set "workingDir=%~dp0.."
if not defined YTM_MAX_RETRIES set "YTM_MAX_RETRIES=6"
if not defined YTM_RETRY_STEP_SECONDS set "YTM_RETRY_STEP_SECONDS=15"
if not exist "%workingDir%\YTMusic" md "%workingDir%\YTMusic"
cd /d "%workingDir%"

:Progress logic
set /p dlProgress=<Redistributables\dlProgress
set dlProgress=%dlProgress: =%
set /a dlProgress=%dlProgress%+1
echo %dlProgress% > Redistributables\dlProgress
title Download - %dlProgress%/%2

REM --- Skip if already downloaded ---
if exist "%workingDir%\done_ids.txt" (
	findstr /x /c:"%URL%" "%workingDir%\done_ids.txt" >nul 2>&1
	if not errorlevel 1 (
		call "%~dp0ProgressBar.cmd" log "Track %URL% already downloaded, skipping."
		call "%~dp0ProgressBar.cmd" draw %dlProgress% %2 "Skipped %URL%"
		exit /b 0
	)
)

call "%~dp0ProgressBar.cmd" draw %dlProgress% %2 "Preparing %URL%"

:tempdir
set temp=%random%
md "%workingDir%\Cache\%temp%"
if errorlevel 1 goto tempdir

:Check whether or not to count track numbers
cd Redistributables
if not exist TotalTracks.txt set currenttrack=1 && set totaltracks=1 && goto Download
set /p totaltracks=<TotalTracks.txt
set /p currenttrack=<Track.txt
set /a currenttrack=%currenttrack%+1
echo %currenttrack% > Track.txt

:Download YouTube audio to cache and store file name in variable
cd..
set currenttrack=%currenttrack: =%
set totaltracks=%totaltracks: =%
set dlTryCount=0
set dlTrySeconds=0

call "%~dp0ProgressBar.cmd" draw %dlProgress% %2 "Downloading %URL%"
>"%~dp0progressState.txt" echo %dlProgress%^|%2^|Downloading %URL%
>"%~dp0progressTickerRun.txt" echo 1
start /b "" cmd /c "%~dp0ProgressTicker.cmd"

:dlRetry
Redistributables\YouTube-DL\youtube-dl.exe "https://www.youtube.com/watch?v=%URL%" -o "%workingDir%\Cache\%temp%\%%(track)s;%%(artist)s;%%(album)s;" -x --audio-format mp3 --no-warnings --embed-metadata --audio-quality 0 --restrict-filenames --ffmpeg-location "%~dp0FFMPEG\bin\ffmpeg.exe" --postprocessor-args "-metadata track="%currenttrack%/%totaltracks%" -metadata disc="1/1"" >>"%~dp0ytdlp.log" 2>&1
if errorlevel 1 (
	if %dlTryCount%==%YTM_MAX_RETRIES% (
	if exist "%~dp0progressTickerRun.txt" del /q "%~dp0progressTickerRun.txt"
	call "%~dp0ProgressBar.cmd" log "FATAL: Download of track ID %URL% failed. See Redistributables\ytdlp.log"
		goto DownloadFailed
)
set /a dlTryCount=%dlTryCount%+1
set /a dlTrySeconds=%dlTrySeconds%+%YTM_RETRY_STEP_SECONDS%
call "%~dp0ProgressBar.cmd" log "Retry %dlTryCount%/%YTM_MAX_RETRIES% for track %URL% in %dlTrySeconds%s (request was rejected)..."
call "%~dp0ProgressBar.cmd" draw %dlProgress% %2 "Retrying %URL%"
timeout %dlTrySeconds% /nobreak >nul
goto dlRetry
)
if exist "%~dp0progressTickerRun.txt" del /q "%~dp0progressTickerRun.txt"
call "%~dp0ProgressBar.cmd" draw %dlProgress% %2 "Tagging %URL%"
set "filename1="
for /f "tokens=* usebackq" %%f in (`dir /b /a-d "%workingDir%\Cache\%temp%" 2^>nul`) do set filename1=%%f
if not defined filename1 (
	call "%~dp0ProgressBar.cmd" log "FATAL: yt-dlp returned no audio file for track %URL%."
	goto DownloadFailed
)

:Replace underscores with spaces and rename file
set filename=%filename1:_= %
REM --- Fix NA or empty titles ---
if "%filename%"==";;;" set "filename=NA;Unknown Artist;Unknown Album"
if "%filename%"=="NA;NA;NA.mp3" set "filename=NA;Unknown Artist;Unknown Album"
ren "%workingDir%\Cache\%temp%\%filename1%" "%filename%"

:Parse variable to retreive original track metadata
for /f "tokens=1 delims=;" %%f in ("%filename%") do set track=%%f
for /f "tokens=2 delims=;" %%f in ("%filename%") do set artist=%%f
for /f "tokens=3 delims=;" %%f in ("%filename%") do set album=%%f

:Retrieve non-ASCII metadata
for /f "tokens=* usebackq" %%f in (`call "%~dp0Get Info.cmd" "%workingDir%\Cache\%temp%\%filename%" 13`) do set artistfull=%%f
for /f "tokens=* usebackq" %%f in (`call "%~dp0Get Info.cmd" "%workingDir%\Cache\%temp%\%filename%" 14`) do set albumfull=%%f
set "artistdisplay=%artistfull%"

:Get first artist in non-ASCII metadata
for /f "tokens=1 delims=," %%f in ("%artistfull%") do set artistfull=%%f

:Move song to Artist folder if already exists
set "tracklocator=%track%"
if exist "%workingDir%\YTMusic\%track%.mp3" set "tracklocator=%track% (%random%)"

:Search iTunes store for album artwork
ren "%workingDir%\Cache\%temp%\%filename%" "%track%.tmp.mp3"
set keepalbumcover=0
if exist "%workingDir%\Cache\Album.jpg" copy "%workingDir%\Cache\Album.jpg" "%workingDir%\Cache\%temp%\%track%.jpg" >nul && goto Use
cd Redistributables
if exist TotalTracks.txt set keepalbumcover=1
cd..
call "%~dp0ProgressBar.cmd" draw %dlProgress% %2 "Artwork for %track%"
Redistributables\AlbumArtDownloader\aad.exe /ar "%artistfull%" /al "%albumfull%" /p "%workingDir%\Cache\%temp%\%track%.jpg" /s "iTunes" >nul 2>&1
if not exist "%workingDir%\Cache\%temp%\%track%.jpg" goto Re-format

:Use FFMPEG to embed album artwork, re-format contributing artists, and strip unnecessary data
if %keepalbumcover%== 1 copy "%workingDir%\Cache\%temp%\%track%.jpg" "%workingDir%\Cache\Album.jpg" >nul
Redistributables\FFMPEG\bin\ffmpeg.exe -hide_banner -loglevel error -y -i "%workingDir%\Cache\%temp%\%track%.tmp.mp3" -i "%workingDir%\Cache\%temp%\%track%.jpg" -map 0:0 -map 1:0 -c copy -id3v2_version 3 -metadata artist="%artistdisplay%" -metadata album_artist="%artistdisplay%" -metadata synopsis=\"\" -metadata description=\"\" -metadata purl=\"\" -metadata comment=\"\" "%workingDir%\YTMusic\%tracklocator%.mp3"
if errorlevel 1 goto FormatFailed
goto End

:Re-format contributing artists without embedding album artwork, if none is available
Redistributables\FFMPEG\bin\ffmpeg.exe -hide_banner -loglevel error -y -i "%workingDir%\Cache\%temp%\%track%.tmp.mp3" -map 0:0 -c copy -id3v2_version 3 -metadata artist="%artistdisplay%" -metadata album_artist="%artistdisplay%" -metadata synopsis=\"\" -metadata description=\"\" -metadata purl=\"\" -metadata comment=\"\" "%workingDir%\YTMusic\%tracklocator%.mp3"
if errorlevel 1 goto FormatFailed

:End
if not exist "%workingDir%\YTMusic\%tracklocator%.mp3" goto FormatFailed
echo %URL% >> "%workingDir%\done_ids.txt"
rd /s /q "%workingDir%\Cache\%temp%"

REM --- Keep done_ids.txt from growing without bound ---
for /f %%c in ('find /v /c "" "%workingDir%\done_ids.txt"') do set doneCount=%%c
set /a doneSkip=doneCount-5000
if %doneSkip% GTR 0 (
	more +%doneSkip% "%workingDir%\done_ids.txt" > "%workingDir%\done_ids.tmp"
	move /y "%workingDir%\done_ids.tmp" "%workingDir%\done_ids.txt" >nul
)
call "%~dp0ProgressBar.cmd" log "Saved %tracklocator%.mp3"
call "%~dp0ProgressBar.cmd" draw %dlProgress% %2 "Done %URL%"
exit /b 0

:FormatFailed
call "%~dp0ProgressBar.cmd" log "FATAL: Could not create the final MP3 for track %URL%."

:DownloadFailed
if exist "%~dp0progressTickerRun.txt" del /q "%~dp0progressTickerRun.txt" >nul 2>&1
if exist "%workingDir%\Cache\%temp%" rd /s /q "%workingDir%\Cache\%temp%" >nul 2>&1
findstr /x /c:"%URL%" "%workingDir%\FailedDownloads.txt" >nul 2>&1
if errorlevel 1 echo %URL%>>"%workingDir%\FailedDownloads.txt"
call "%~dp0ProgressBar.cmd" draw %dlProgress% %2 "FAILED %URL%"
exit /b 1
