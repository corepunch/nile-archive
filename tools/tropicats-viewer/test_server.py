"""Focused HTTP checks using the user's extracted reference data, when present."""
import json
import threading
import unittest
from http.server import ThreadingHTTPServer
from urllib.error import HTTPError
from urllib.request import urlopen

from serve import DEFAULT_DATA, handler_for, make_index


@unittest.skipUnless((DEFAULT_DATA / "config/areasconfig.json").exists(), "Local reference data unavailable")
class ViewerServerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.index = make_index(DEFAULT_DATA)
        cls.server = ThreadingHTTPServer(("127.0.0.1", 0), handler_for(DEFAULT_DATA, cls.index))
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        cls.url = f"http://127.0.0.1:{cls.server.server_port}"

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join()

    def get(self, path):
        return urlopen(self.url + path, timeout=3)

    def test_campaign_index_and_story_mapping(self):
        with self.get("/api/index") as response:
            data = json.load(response)
        self.assertEqual(len(data["levels"]), 2730)
        self.assertEqual(data["levels"][0]["quest"]["item"], "shovel")
        self.assertEqual(data["levels"][-1]["quest"]["tier"], "c")

    def test_actual_tiers_and_static_module(self):
        with self.get("/api/level/1") as response:
            level = json.load(response)
        self.assertEqual([level[t]["data"]["moves"] for t in "abc"], [30, 25, 25])
        self.assertTrue(all(len(level[t]["layout"]["fields"]) == 81 for t in "abc"))
        with self.get("/app.mjs") as response:
            self.assertIn("text/javascript", response.headers["Content-Type"])

    @unittest.skipUnless((DEFAULT_DATA / "art/sprites.json").exists(), "Local sprites unavailable")
    def test_original_sprite_manifest_and_png(self):
        with self.get("/api/art") as response:
            art = json.load(response)
        self.assertIn("dot_red", art)
        with self.get(art["dot_red"]["url"]) as response:
            self.assertEqual(response.headers["Content-Type"], "image/png")
            self.assertEqual(response.read(8), b"\x89PNG\r\n\x1a\n")
        with self.get("/art.mjs") as response:
            self.assertIn("text/javascript", response.headers["Content-Type"])

    def test_no_arbitrary_files_or_invalid_levels(self):
        for path in ["/../serve.py", "/%2e%2e/serve.py", "/api/level/0", "/api/level/2731", "/api/level/1a", "/config/areasconfig.json", "/art/../../serve.py", "/art/unknown.png", "/art/%2e%2e.png"]:
            with self.subTest(path=path), self.assertRaises(HTTPError) as caught:
                self.get(path)
            self.assertEqual(caught.exception.code, 404)


if __name__ == "__main__":
    unittest.main()
