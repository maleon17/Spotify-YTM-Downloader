import sys
import unittest
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parents[1] / "Redistributables" / "Scripts"
sys.path.insert(0, str(SCRIPTS))

from get_spotify_ids import result_score


class SpotifyMatchingTests(unittest.TestCase):
    def test_exact_studio_track_beats_live_version(self):
        exact = {
            "title": "Never Gonna Give You Up",
            "artists": [{"name": "Rick Astley"}],
            "duration_seconds": 213,
            "videoId": "exact",
        }
        live = {
            "title": "Never Gonna Give You Up - Live",
            "artists": [{"name": "Rick Astley"}],
            "duration_seconds": 250,
            "videoId": "live",
        }
        exact_score = result_score(exact, "Never Gonna Give You Up", "Rick Astley", 213)
        live_score = result_score(live, "Never Gonna Give You Up", "Rick Astley", 213)
        self.assertGreater(exact_score, 0.9)
        self.assertGreater(exact_score, live_score)

    def test_matching_version_marker_is_not_penalized(self):
        slowed = {
            "title": "Example Song - Slowed",
            "artists": [{"name": "Example Artist"}],
            "duration_seconds": 240,
            "videoId": "slowed",
        }
        score = result_score(slowed, "Example Song Slowed", "Example Artist", 240)
        self.assertGreater(score, 0.9)


if __name__ == "__main__":
    unittest.main()
