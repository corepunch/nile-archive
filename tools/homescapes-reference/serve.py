#!/usr/bin/env python3
"""Serve extracted board definitions on loopback only."""
import argparse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import zipfile
from urllib.parse import parse_qs, urlsplit

from level_viewer import PAGE, SOURCE, load_level
from story_index import SOURCE as APP_ARCHIVE


class Handler(BaseHTTPRequestHandler):
    paths = {}
    icons = {}

    def send_bytes(self, body, content_type):
        self.send_response(200)
        self.send_header('Content-Type', content_type)
        self.send_header('Content-Length', str(len(body)))
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        url = urlsplit(self.path)
        if url.path == '/':
            self.send_bytes(PAGE.encode(), 'text/html; charset=utf-8')
        elif url.path == '/api/list':
            self.send_bytes(json.dumps(sorted(self.paths)).encode(), 'application/json')
        elif url.path.startswith('/api/icon/'):
            name = url.path.removeprefix('/api/icon/')
            if name not in self.icons:
                self.send_error(404)
                return
            self.send_bytes(self.icons[name], 'image/webp')
        elif url.path == '/api/level':
            query = parse_qs(url.query)
            names = query.get('path', [])
            if len(names) != 1 or names[0] not in self.paths:
                self.send_error(404)
                return
            payload = load_level(self.paths[names[0]])
            self.send_bytes(json.dumps(payload).encode(), 'application/json')
        else:
            self.send_error(404)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', type=int, default=8767)
    args = parser.parse_args()
    if not SOURCE.is_dir():
        parser.error('Extract level archive first with extract_archives.py')
    Handler.paths = {p.relative_to(SOURCE).as_posix(): p for p in SOURCE.rglob('*.xml')}
    if not Handler.paths:
        parser.error('No decoded XML levels found')
    prefix = 'base_mm/Match3/vso/textures/UI/Match3TargetsBase/'
    with zipfile.ZipFile(APP_ARCHIVE) as archive:
        Handler.icons = {name[len(prefix):]: archive.read(name) for name in archive.namelist()
                         if name.startswith(prefix) and name.endswith('.webp')
                         and '/' not in name[len(prefix):]}
    server = ThreadingHTTPServer(('127.0.0.1', args.port), Handler)
    print(f'{len(Handler.paths)} files: http://127.0.0.1:{args.port}/', flush=True)
    server.serve_forever()


if __name__ == '__main__':
    main()
