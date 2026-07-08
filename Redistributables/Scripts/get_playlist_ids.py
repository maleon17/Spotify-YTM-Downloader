#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys, re

try:
    from ytmusicapi import YTMusic
except ImportError:
    print("ERROR: the 'ytmusicapi' package is not installed.", file=sys.stderr)
    print("Install it with: python3 -m pip install ytmusicapi", file=sys.stderr)
    sys.exit(1)

def extract_playlist_id(url_or_id):
    m = re.search(r'list=([A-Za-z0-9_-]+)', url_or_id)
    if m:
        return m.group(1)
    # plain id
    rid = url_or_id.strip()
    if rid and ' ' not in rid and len(rid) < 50:
        return rid
    return None

def main():
    if len(sys.argv) < 2:
        print("ERROR: no playlist URL or ID was passed to get_playlist_ids.py", file=sys.stderr)
        sys.exit(1)
    pid = extract_playlist_id(sys.argv[1])
    if not pid:
        print(f"ERROR: could not find a playlist ID in '{sys.argv[1]}'", file=sys.stderr)
        sys.exit(1)
    try:
        yt = YTMusic()
        data = yt.get_playlist(pid, limit=None)
    except Exception as e:
        print(f"ERROR: failed to fetch playlist '{pid}': {e}", file=sys.stderr)
        sys.exit(1)
    tracks = data.get("tracks", [])
    printed = 0
    for track in tracks:
        vid = track.get("videoId")
        if vid:
            print(vid)
            printed += 1
    if printed == 0:
        print(f"ERROR: playlist '{pid}' returned no downloadable tracks.", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
