:YTM Downloader Setup
:Downloads/installs the third-party dependencies listed in README.md "Setup"
:Version 1.0.1

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
	if not errorlevel 1 powershell -NoProfile -Command "$b=[IO.File]::ReadAllBytes('Redistributables\YouTube-DL\yt-dlp.exe'); if($b.Length -lt 2 -or $b[0] -ne 0x4D -or $b[1] -ne 0x5A){exit 1}"
	if errorlevel 1 (
		if exist "Redistributables\YouTube-DL\yt-dlp.exe" del /q "Redistributables\YouTube-DL\yt-dlp.exe"
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
	if not errorlevel 1 tar.exe -tf "Redistributables\FFMPEG\ffmpeg.zip" >nul 2>&1
	if errorlevel 1 (
		if exist "Redistributables\FFMPEG\ffmpeg.zip" del /q "Redistributables\FFMPEG\ffmpeg.zip"
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
) else if exist "C:\Program Files\AlbumArtDownloader\aad.exe" (
	echo [3/6] Copying AlbumArtDownloader files...
	if not exist "Redistributables\AlbumArtDownloader" md "Redistributables\AlbumArtDownloader"
	xcopy /e /i /y "C:\Program Files\AlbumArtDownloader\*" "Redistributables\AlbumArtDownloader\" >nul
	echo   Done.
) else if exist "C:\Program Files (x86)\AlbumArtDownloader\aad.exe" (
	echo [3/6] Copying AlbumArtDownloader files...
	if not exist "Redistributables\AlbumArtDownloader" md "Redistributables\AlbumArtDownloader"
	xcopy /e /i /y "C:\Program Files (x86)\AlbumArtDownloader\*" "Redistributables\AlbumArtDownloader\" >nul
	echo   Done.
) else (
	echo [3/6] AlbumArtDownloader isn't installed. Downloading its installer...
	powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri 'https://sourceforge.net/projects/album-art/files/latest/download' -OutFile '%TEMP%\AlbumArtDownloaderSetup.exe' -UseBasicParsing } catch { exit 1 }"
	if not errorlevel 1 powershell -NoProfile -Command "$b=[IO.File]::ReadAllBytes('%TEMP%\AlbumArtDownloaderSetup.exe'); if($b.Length -lt 2 -or $b[0] -ne 0x4D -or $b[1] -ne 0x5A){exit 1}"
	if errorlevel 1 (
		if exist "%TEMP%\AlbumArtDownloaderSetup.exe" del /q "%TEMP%\AlbumArtDownloaderSetup.exe"
		echo   FAILED - download and install it manually from https://sourceforge.net/projects/album-art/
	) else (
		echo   Opening the installer - complete the setup wizard. This window will wait
		echo   and copy the required files automatically when installation finishes.
		start /wait "" "%TEMP%\AlbumArtDownloaderSetup.exe"
		if exist "C:\Program Files\AlbumArtDownloader\aad.exe" xcopy /e /i /y "C:\Program Files\AlbumArtDownloader\*" "Redistributables\AlbumArtDownloader\" >nul
		if exist "C:\Program Files (x86)\AlbumArtDownloader\aad.exe" xcopy /e /i /y "C:\Program Files (x86)\AlbumArtDownloader\*" "Redistributables\AlbumArtDownloader\" >nul
		if exist "Redistributables\AlbumArtDownloader\aad.exe" (echo   Installed and copied successfully.) else (echo   Installer finished, but aad.exe was not found. See README.md for manual setup.)
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
	echo   no notification popup will be shown. This does not block the downloader.
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
	%PYCMD% -m pip install --upgrade -r requirements.txt
	if errorlevel 1 echo   FAILED - see the pip error above and try Setup.cmd again.
)
echo.

echo ===============================================
echo  Setup finished. Run Add Music.cmd to get started.
echo ===============================================
pause
