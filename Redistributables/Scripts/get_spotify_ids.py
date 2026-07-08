#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Resolves a Spotify track/album/playlist URL into YouTube Music video IDs.

Track/artist metadata is read from Spotify's own public web-player data via
the spotifyscraper package - no Spotify account, API key, or Premium
subscription is needed, and only publicly visible track/artist names are
read; audio is never touched on Spotify's side. Each track is then matched
by title+artist against YouTube Music via ytmusicapi, and only the matched
video ID is printed to stdout (one per line), exactly like get_playlist_ids.py
does for native YTM playlists. Progress/errors go to stderr so stdout stays
clean for the caller to redirect into URLs.txt.
"""
import re
import sys
import threading
from pathlib import Path

NOT_FOUND_PATH = Path(__file__).resolve().parent.parent.parent / "NotFound.txt"

try:
    from spotify_scraper import SpotifyClient
except ImportError:
    print("ERROR: the 'spotifyscraper' package is not installed.", file=sys.stderr)
    print("Install it with: python3 -m pip install spotifyscraper", file=sys.stderr)
    sys.exit(1)

try:
    from ytmusicapi import YTMusic
except ImportError:
    print("ERROR: the 'ytmusicapi' package is not installed.", file=sys.stderr)
    print("Install it with: python3 -m pip install ytmusicapi", file=sys.stderr)
    sys.exit(1)


class ProgressBar:
    """Bottom-pinned progress bar, same visual style as Redistributables\\ProgressBar.cmd."""

    WIDTH = 29

    def __init__(self):
        self.current = 0
        self.total = 1
        self.label = ""
        self.chomp = "C"
        self._lock = threading.Lock()
        self._stop = threading.Event()
        self._thread = threading.Thread(target=self._tick_loop, daemon=True)

    def start(self, total):
        with self._lock:
            self.total = max(total, 1)
            self.current = 0
        self._draw()
        self._thread.start()

    def update(self, current, label):
        with self._lock:
            self.current = current
            self.label = label
        self._draw()

    def _tick_loop(self):
        while not self._stop.wait(1):
            with self._lock:
                self.chomp = "c" if self.chomp == "C" else "C"
            self._draw()

    def log(self, message):
        sys.stderr.write("\r" + " " * 90 + "\r")
        sys.stderr.write(message + "\n")
        self._draw()

    def _draw(self):
        with self._lock:
            current, total, label, chomp = self.current, self.total, self.label, self.chomp
        percent = min(100, int(current * 100 / total))
        filled = min(self.WIDTH, int(self.WIDTH * current / total))
        bar = "=" * filled + chomp + "-" * (self.WIDTH - filled)
        label_fixed = (label + " " * 28)[:28]
        line = f"{current}/{total} {label_fixed} [{bar}] {percent}%     "
        sys.stderr.write("\r" + line)
        sys.stderr.flush()

    def done(self):
        self._stop.set()
        self._thread.join(timeout=2)
        sys.stderr.write("\r" + " " * 90 + "\r\n")
        sys.stderr.flush()


def append_not_found(entries):
    """Append 'Artist - Title' lines to NotFound.txt, skipping ones already recorded."""
    existing = set()
    if NOT_FOUND_PATH.exists():
        existing = set(NOT_FOUND_PATH.read_text(encoding="utf-8", errors="ignore").splitlines())
    new_lines = [e for e in entries if e not in existing]
    if new_lines:
        with open(NOT_FOUND_PATH, "a", encoding="utf-8") as f:
            for line in new_lines:
                f.write(line + "\n")


def extract_spotify_ref(url):
    m = re.search(r"open\.spotify\.com/(track|album|playlist)/([A-Za-z0-9]+)", url)
    if m:
        return m.group(1), m.group(2)
    m = re.search(r"spotify:(track|album|playlist):([A-Za-z0-9]+)", url)
    if m:
        return m.group(1), m.group(2)
    return None, None


def get_tracks(client, kind, spotify_id):
    """Returns a list of (title, artist) tuples."""
    if kind == "track":
        t = client.get_track(spotify_id)
        return [(t.name, t.artists[0].name)]

    if kind == "album":
        album = client.get_album(spotify_id)
        return [(t.name, t.artists[0].name) for t in album.tracks if t.artists]

    if kind == "playlist":
        playlist = client.get_playlist(spotify_id, max_tracks=10000)
        out = []
        for item in playlist.tracks:
            t = item.track
            if t and t.name and t.artists:
                out.append((t.name, t.artists[0].name))
        return out

    return []


def main():
    if len(sys.argv) < 2:
        print("ERROR: no Spotify URL passed to get_spotify_ids.py", file=sys.stderr)
        sys.exit(1)

    kind, spotify_id = extract_spotify_ref(sys.argv[1])
    if not kind:
        print(f"ERROR: '{sys.argv[1]}' is not a recognizable Spotify track/album/playlist link.", file=sys.stderr)
        sys.exit(1)

    try:
        yt = YTMusic()
    except Exception as e:
        print(f"ERROR: failed to initialize YouTube Music client: {e}", file=sys.stderr)
        sys.exit(1)

    try:
        with SpotifyClient() as client:
            tracks = get_tracks(client, kind, spotify_id)
    except Exception as e:
        print(f"ERROR: failed to read '{kind}' {spotify_id} from Spotify: {e}", file=sys.stderr)
        print("NOTE: this only works for PUBLIC Spotify links.", file=sys.stderr)
        sys.exit(1)

    if not tracks:
        print(f"ERROR: Spotify {kind} {spotify_id} has no tracks (it may be private).", file=sys.stderr)
        sys.exit(1)

    bar = ProgressBar()
    bar.start(len(tracks))
    found = 0
    not_found = []
    for i, (title, artist) in enumerate(tracks, start=1):
        label = f"{artist} - {title}"
        bar.update(i - 1, label)
        query = f"{artist} {title}"
        try:
            search = yt.search(query, filter="songs", limit=1)
            if not search:
                search = yt.search(query, limit=1)
            video_id = search[0]["videoId"] if search else None
        except Exception as e:
            bar.log(f"WARNING: search failed for '{label}': {e}")
            video_id = None

        if video_id:
            print(video_id)
            found += 1
        else:
            bar.log(f"WARNING: no YouTube Music match found for '{label}', skipping.")
            not_found.append(label)
        bar.update(i, label)

    bar.done()
    sys.stdout.flush()
    if found == 0:
        print("ERROR: none of the Spotify tracks could be matched on YouTube Music.", file=sys.stderr)
        sys.exit(1)
    if not_found:
        append_not_found(not_found)
        print(f"NOTE: {len(not_found)} of {len(tracks)} tracks were not found on YouTube Music.", file=sys.stderr)
        print(f"The list is saved in {NOT_FOUND_PATH} - you can find and add them yourself.", file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()
