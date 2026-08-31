# Spotify-YTM-Downloader

Current release: **v1.0.1**

Windows batch scripts that download songs, albums, and playlists from **YouTube Music** (and **Spotify**, matched via YouTube Music) as tagged MP3 files - complete with metadata and album artwork - and hand them off to your media player of choice.

Originally based on [Tech-How/YouTube-Music-Downloader](https://github.com/Tech-How/YouTube-Music-Downloader), extended with Spotify support, crash recovery, a live progress bar, and various fixes.

> **Note:** this downloads audio from YouTube for personal use. That's outside YouTube's Terms of Service in most jurisdictions - use at your own discretion, for content you have the right to download.

## Features

- Download single songs, whole albums, or playlists from YouTube Music
- Paste a **Spotify** track/album/playlist link instead - track names are read from Spotify's public metadata (no account, API key, or Premium subscription needed) and matched against YouTube Music
- Automatic ID3 tags (title, artist, album, track number) and embedded album art (via iTunes)
- Live progress bar while downloading, and while matching Spotify tracks
- Automatically skips tracks you've already downloaded, even across separate runs
- Recovers cleanly if you close the terminal mid-download - just re-run `Download.cmd`
- Optional auto-import into your media player, or auto-move into a media library folder
- Tracks that can't be matched on YouTube Music are listed in `NotFound.txt` for manual lookup
- Failed downloads are listed in `FailedDownloads.txt`; the queue is kept so they can be retried safely

## Requirements

- Windows 10/11
- [Python 3.10+](https://www.python.org/downloads/) (needed for playlist/Spotify resolution), with `pip` on PATH - `Setup.cmd` (below) installs this for you via `winget` if it's missing

## Setup

This repo does **not** include the third-party tools it relies on, to keep the repo small and avoid redistributing other people's binaries. You need to grab each one once, after cloning.

**Quick way:** run `Setup.cmd`. It downloads yt-dlp and ffmpeg automatically, opens the AlbumArtDownloader installer for you, copies `msg.exe` from Windows if available, installs Python via `winget` if it's missing, and installs the required Python packages. Safe to re-run any time - it skips anything already in place.

> If `Setup.cmd` had to install Python itself, it'll ask you to close the window and run it
> again - Windows only picks up the new PATH in a fresh terminal, not the one that just ran the installer.

If you'd rather do it by hand (or `Setup.cmd` fails to download something), here's what it's doing:

### 1. yt-dlp (does the actual downloading)
Download the standalone `yt-dlp.exe` from the [yt-dlp releases page](https://github.com/yt-dlp/yt-dlp/releases) and place it in:
```
Redistributables\YouTube-DL\yt-dlp.exe
```
The first time you run `Add Music.cmd` or `Download.cmd`, it's automatically renamed to `youtube-dl.exe` and used from there.

### 2. ffmpeg (audio conversion, tagging, artwork embedding)
Download a Windows build (e.g. from [gyan.dev](https://www.gyan.dev/ffmpeg/builds/) or [BtbN's builds](https://github.com/BtbN/FFmpeg-Builds/releases)) and drop the downloaded **zip file** directly into:
```
Redistributables\FFMPEG\
```
It's automatically extracted (`bin`, `doc`, `presets`, etc.) on first run.

### 3. AlbumArtDownloader (album art search)
Install [AlbumArtDownloader](https://sourceforge.net/projects/album-art/) using its normal installer. On first run, the script automatically copies the needed files from `C:\Program Files\AlbumArtDownloader` into `Redistributables\AlbumArtDownloader\` - after that you're free to uninstall it.

### 4. msg.exe (optional - just shows a one-time notification)
This is a standard Windows utility. On Windows Pro/Enterprise it already exists at `C:\Windows\System32\msg.exe` - copy it into:
```
Redistributables\msg.exe
```
(Windows Home editions historically don't ship it. It is optional: without it, the downloader simply skips the one-time notification popup.)

### 5. Python
Install [Python 3.10+](https://www.python.org/downloads/) (tick "Add python.exe to PATH" during install), or via winget:
```
winget install -e --id Python.Python.3.13
```

### 6. Python packages
```
python3 -m pip install -r requirements.txt
```

Once all of the above are in place, run `Download.cmd` once - it'll tell you if anything required is still missing.

## Usage

1. Run **Add Music.cmd**. Paste links one at a time:
   - A YouTube Music song/album/playlist link (`music.youtube.com`)
   - A **public** Spotify track/album/playlist link (`open.spotify.com`) - see note below
   - A [beatbump.io](https://beatbump.io) link
2. Run **Download.cmd**. It'll ask if the queued songs are an album (keeps them numbered together and reuses one cover) or singles (each gets its own artwork).
3. Downloaded songs land in a dated folder in the project root. If auto-import is enabled (configured on first run), they're opened or moved into your media library automatically.

If one or more downloads fail, their IDs are written to `FailedDownloads.txt` and `URLs.txt` is kept intact. Run `Download.cmd` again to retry them; completed tracks are skipped through `done_ids.txt`.

Other scripts:
- **Import.cmd** - opens/moves songs from a given folder into your media player/library (also works via drag-and-drop onto the script)
- **Find Duplicates.cmd** - compares two folders for duplicate filenames
- **Clear.cmd** - deletes temporary files/folders left behind by Add Music/Download (`Cache`, leftover `YTMusic`, progress counters). Your queue, settings, and download history are left alone unless you opt in to resetting them.

### About Spotify links

Only works for playlists/albums that are set to **Public** in Spotify. Track and artist names are read from Spotify's public web-player data - Spotify audio itself is never touched. Each track is then searched for and downloaded from YouTube Music, so matching isn't guaranteed to be exact (e.g. a live version might get picked if the studio version isn't on YouTube Music). Anything that can't be matched is skipped and logged to `NotFound.txt` in the project root, so you can track it down manually.

## Project structure

```
.
├── Setup.cmd                  Downloads/installs the third-party dependencies below
├── Add Music.cmd              Queue up songs/playlists/albums (YTM, Spotify, beatbump)
├── Download.cmd               Downloads everything currently queued in URLs.txt
├── Import.cmd                 Open/move downloaded songs into your media player
├── Find Duplicates.cmd        Compare two folders for duplicate filenames
├── Clear.cmd                  Clean up temporary files/folders
├── Video [Experimental].cmd   Unsupported one-off video/audio downloader
└── Redistributables/
    ├── Downloader.cmd         Per-track download/tag/artwork logic (called by Download.cmd)
    ├── ProgressBar.cmd        Shared bottom-pinned progress bar renderer
    ├── ProgressTicker.cmd     Background process that animates the bar during downloads
    ├── Get Info.cmd           Reads Explorer-shell metadata from a file
    ├── Scripts/
    │   ├── get_playlist_ids.py   Resolves a YTM playlist link to video IDs
    │   └── get_spotify_ids.py    Resolves a Spotify link to matched YTM video IDs
    ├── FFMPEG/                third-party ffmpeg binaries (see Setup)
    ├── YouTube-DL/            third-party yt-dlp binary (see Setup)
    ├── AlbumArtDownloader/    third-party AlbumArtDownloader files (see Setup)
    └── msg.exe                optional Windows notification utility (see Setup)
```

## Credits

- [yt-dlp](https://github.com/yt-dlp/yt-dlp)
- [ffmpeg](https://ffmpeg.org/)
- [AlbumArtDownloader](https://sourceforge.net/projects/album-art/)
- [ytmusicapi](https://github.com/sigma67/ytmusicapi)
- [spotifyscraper](https://github.com/AliAkhtari78/SpotifyScraper)
- Original project: [Tech-How/YouTube-Music-Downloader](https://github.com/Tech-How/YouTube-Music-Downloader)

## License

This modified project is distributed under the [GNU General Public License v3.0](LICENSE), matching the license of the original project. Original and third-party copyright notices remain with their respective authors.
