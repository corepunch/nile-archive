#!/usr/bin/env python3
"""Serve the locally extracted June's Journey scene viewer."""

import argparse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import re
from urllib.parse import urlsplit

from scene_data import build_scene

HERE = Path(__file__).resolve().parent
DEFAULT_DATA = HERE.parents[1] / 'reference/junes-journey-analysis'


def handler_for(root, scene):
    assets = root / 'scenes'
    static = {
        '/': ('index.html', 'text/html'),
        '/app.js': ('app.js', 'text/javascript'),
        '/style.css': ('style.css', 'text/css'),
    }

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            path = urlsplit(self.path).path
            try:
                if path == '/api/scene':
                    return self.send_bytes(json.dumps(scene, ensure_ascii=False).encode(), 'application/json')
                if path in static:
                    name, mime = static[path]
                    return self.send_bytes((HERE / name).read_bytes(), mime)
                match = re.fullmatch(r'/assets/(scene-001-01|clues)/([A-Za-z0-9_-]+\.png)', path)
                if match:
                    return self.send_bytes((assets / match[1] / match[2]).read_bytes(), 'image/png')
                self.send_error(404)
            except FileNotFoundError:
                self.send_error(404)
            except OSError as error:
                self.send_error(500, str(error))

        def send_bytes(self, body, mime):
            self.send_response(200)
            self.send_header('Content-Type', mime if mime.startswith('image/') else mime + '; charset=utf-8')
            self.send_header('Content-Length', str(len(body)))
            self.send_header('Cache-Control', 'private, max-age=3600' if mime.startswith('image/') else 'no-store')
            self.send_header('X-Content-Type-Options', 'nosniff')
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, *args):
            pass

    return Handler


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--data', type=Path, default=DEFAULT_DATA)
    parser.add_argument('--port', type=int, default=8766)
    args = parser.parse_args()
    try:
        scene = build_scene(args.data)
    except (OSError, ValueError) as error:
        parser.error(f'Extracted scene data is missing or invalid: {error}. See tools/junes-viewer/README.md.')
    server = ThreadingHTTPServer(('127.0.0.1', args.port), handler_for(args.data, scene))
    print(f"June's Journey viewer: http://127.0.0.1:{server.server_port}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == '__main__':
    main()
