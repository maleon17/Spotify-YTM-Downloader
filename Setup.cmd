:YTM Downloader Setup
:Downloads/installs the third-party dependencies listed in README.md "Setup"
:Version 1.1

@echo off
title YTM Downloader Setup
cd /d "%~dp0"

echo ===============================================
echo  YTM Downloader - dependency setup
echo ===============================================
echo.

REM --- 1. yt-dlp ---
if exist "Redistributables\YouTube-DL\yt-dlp.exe" (
	echo [1/6] yt-dlp already present, skipping.
) else if exist "Redistributables\YouTube-DL\youtube-dl.exe" (
	echo [1/6] yt-dlp already installed ^(as youtube-dl.exe^), skipping.
) else (
	echo [1/6] Downloading yt-dlp...
	if not exist "Redistributables\YouTube-DL" md "Redistributables\YouTube-DL"
	powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe' -OutFile 'Redistributables\YouTube-DL\yt-dlp.exe' -UseBasicParsing } catch { exit 1 }"
	if errorlevel 1 (
		echo   FAILED - download it manually from https://github.com/yt-dlp/yt-dlp/releases
		echo   and place yt-dlp.exe in Redistributables\YouTube-DL\
	) else (
		echo   Done.
	)
)
echo.

REM --- 2. ffmpeg ---
if exist "Redistributables\FFMPEG\bin\ffmpeg.exe" (
	echo [2/6] ffmpeg already present, skipping.
) else (
	echo [2/6] Downloading ffmpeg...
	powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri 'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip' -OutFile 'Redistributables\FFMPEG\ffmpeg.zip' -UseBasicParsing } catch { exit 1 }"
	if errorlevel 1 (
		echo   FAILED - download a Windows build manually from https://www.gyan.dev/ffmpeg/builds/
		echo   and drop the zip file into Redistributables\FFMPEG\
	) else (
		echo   Downloaded. It will be unpacked automatically the first time you run
		echo   Download.cmd or Add Music.cmd.
	)
)
echo.

REM --- 3. AlbumArtDownloader ---
if exist "Redistributables\AlbumArtDownloader\aad.exe" (
	echo [3/6] AlbumArtDownloader already present, skipping.
) else if exist "C:\Program Files\AlbumArtDownloader" (
	echo [3/6] AlbumArtDownloader is installed - Download.cmd/Add Music.cmd will copy
	echo   the files it needs on their first run.
) else (
	echo [3/6] AlbumArtDownloader isn't installed. Downloading its installer...
	powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri 'https://sourceforge.net/projects/album-art/files/latest/download' -OutFile '%TEMP%\AlbumArtDownloaderSetup.exe' -UseBasicParsing } catch { exit 1 }"
	if errorlevel 1 (
		echo   FAILED - download and install it manually from https://sourceforge.net/projects/album-art/
	) else (
		echo   Opening the installer - please complete the setup wizard, then re-run this script
		echo   so the needed files get copied into Redistributables\AlbumArtDownloader\.
		start "" "%TEMP%\AlbumArtDownloaderSetup.exe"
	)
)
echo.

REM --- 4. msg.exe ---
if exist "Redistributables\msg.exe" (
	echo [4/6] msg.exe already present, skipping.
) else if exist "%SystemRoot%\System32\msg.exe" (
	echo [4/6] Copying msg.exe from Windows...
	copy /y "%SystemRoot%\System32\msg.exe" "Redistributables\msg.exe" >nul
	echo   Done.
) else (
	echo [4/6] msg.exe not found ^(Windows Home doesn't ship it^). This only powers a
	echo   one-time notification popup - everything else still works without it, but
	echo   the integrity check in Download.cmd/Add Music.cmd will complain it's missing.
)
echo.

REM --- 5. Python ---
set "PYCMD="
where python3 >nul 2>&1
if not errorlevel 1 set "PYCMD=python3"
if not defined PYCMD (
	where python >nul 2>&1
	if not errorlevel 1 set "PYCMD=python"
)
if defined PYCMD (
	echo [5/6] Python already installed, skipping.
) else (
	where winget >nul 2>&1
	if errorlevel 1 (
		echo [5/6] Python not found, and winget isn't available to install it automatically.
		echo   Install it manually from https://www.python.org/downloads/
		echo   ^(tick "Add python.exe to PATH" during install^), then run this script again.
	) else (
		echo [5/6] Installing Python via winget...
		winget install -e --id Python.Python.3.13 --source winget --accept-package-agreements --accept-source-agreements
		if errorlevel 1 (
			echo   FAILED - install it manually from https://www.python.org/downloads/
		) else (
			echo   Done. Windows needs a fresh terminal to pick up the PATH change -
			echo   close this window and run Setup.cmd again to install the Python packages.
			pause
			exit /b
		)
	)
)
echo.

REM --- 6. Python packages ---
if not defined PYCMD (
	echo [6/6] Skipped - no Python available yet.
) else (
	echo [6/6] Installing Python packages ^(ytmusicapi, spotifyscraper^)...
	%PYCMD% -m pip install --upgrade ytmusicapi spotifyscraper
)
echo.

echo ===============================================
echo  Setup finished. Run Add Music.cmd to get started.
echo ===============================================
pause
