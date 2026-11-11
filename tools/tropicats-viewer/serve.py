#!/usr/bin/env python3
"""Serve the local Tropicats reference viewer; no third-party dependencies."""

import argparse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import re
from urllib.parse import urlsplit

HERE = Path(__file__).resolve().parent
DEFAULT_DATA = HERE.parents[1] / "reference/tropicats-analysis"


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def make_index(root):
    chapters = read_json(root / "config/chapterconfig.json")["chapters"]
    locale = read_json(root / "bundled/english.json")
    quests = read_json(root / "bundled/157_questconfig")["quests"]
    tasks = {}
    for quest in quests:
        for i, group in enumerate(quest["task_levels"]):
            for ref in group.split(","):
                if ref == "none":
                    continue
                tasks[int(ref[:-1])] = {
                    "quest": quest["id"], "title": locale.get("quest.title." + quest["id"], quest["id"]),
                    "tier": ref[-1], "item": quest["task_item"][i],
                    "action": quest["task_action_target"][i],
                }
    rows = []
    for area in read_json(root / "config/areasconfig.json")["areas"]:
        for level in area["levels"]:
            chapter = next(c for c in reversed(chapters) if c["first_level"] <= level["level"])
            rows.append({"number": level["level"], "objective": level["objective"],
                         "chapter": chapter["chapter"], "quest": tasks.get(level["level"])})
    return {"levels": rows, "chapters": [dict(c, title=locale.get(
        "quest.chapter.name_" + str(c["chapter"]), str(c["chapter"]))) for c in chapters]}


def handler_for(root, index):
    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            path = urlsplit(self.path).path
            try:
                if path == "/api/index":
                    return self.send_json(index)
                if path == "/api/art":
                    return self.send_json(art)
                artwork = re.fullmatch(r"/art/([A-Za-z0-9_-]+)\.png", path)
                if artwork:
                    if artwork[1] not in art:
                        return self.send_error(404)
                    return self.send_bytes((root / "art/sprites" / f"{artwork[1]}.png").read_bytes(), "image/png")
                match = re.fullmatch(r"/api/level/([1-9][0-9]{0,3})", path)
                if match:
                    number = int(match[1])
                    if number not in valid_numbers:
                        return self.send_error(404, "Unknown campaign level")
                    return self.send_json({tier: read_json(root / "levels" / f"{number:04d}{tier}")
                                           for tier in "abc"})
                files = {"/": ("index.html", "text/html"),
                         "/app.mjs": ("app.mjs", "text/javascript"),
                         "/model.mjs": ("model.mjs", "text/javascript"),
                         "/art.mjs": ("art.mjs", "text/javascript"),
                         "/style.css": ("style.css", "text/css")}
                if path not in files:
                    return self.send_error(404)
                name, mime = files[path]
                self.send_bytes((HERE / name).read_bytes(), mime)
            except (OSError, ValueError) as error:
                self.send_json({"error": f"Unable to read extracted data: {error}"}, 500)

        def send_json(self, value, status=200):
            self.send_bytes(json.dumps(value, ensure_ascii=False).encode(), "application/json", status)

        def send_bytes(self, body, mime, status=200):
            self.send_response(status)
            self.send_header("Content-Type", mime if mime.startswith("image/") else mime + "; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "private, max-age=3600" if mime.startswith("image/") else "no-store")
            self.send_header("X-Content-Type-Options", "nosniff")
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, *args):
            pass

    manifest = root / "art/sprites.json"
    art = read_json(manifest) if manifest.exists() else {}
    valid_numbers = {row["number"] for row in index["levels"]}
    return Handler


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--data", type=Path, default=DEFAULT_DATA)
    parser.add_argument("--port", type=int, default=8765)
    args = parser.parse_args()
    try:
        index = make_index(args.data)
    except (OSError, ValueError) as error:
        parser.error(f"Extracted reference data is missing or invalid: {error}")
    server = ThreadingHTTPServer(("127.0.0.1", args.port), handler_for(args.data, index))
    print(f"Tropicats viewer: http://127.0.0.1:{server.server_port}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
