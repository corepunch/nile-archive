#!/usr/bin/env python3
"""Serve extracted board definitions on loopback only."""
import argparse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import zipfile
from urllib.parse import parse_qs, urlsplit

from decode_board_atlases import OUTPUT as ART
from level_viewer import PAGE, SOURCE, load_level
from story_index import SOURCE as APP_ARCHIVE

MODEL_ART = Path(__file__).with_name('model_sprites.json')


class Handler(BaseHTTPRequestHandler):
    paths = {}
    icons = {}
    art_files = {}
    sprite_ids = []
    model_art = b'{}'

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
        elif url.path == '/api/sprites':
            self.send_bytes(json.dumps(self.sprite_ids).encode(), 'application/json')
        elif url.path == '/api/model-art':
            self.send_bytes(self.model_art, 'application/json')
        elif url.path in self.art_files:
            path, content_type = self.art_files[url.path]
            self.send_bytes(path.read_bytes(), content_type)
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


def load_art(root):
    manifest = root / 'manifest.json'
    if not manifest.is_file():
        return {}, []
    data = json.loads(manifest.read_text(encoding='utf-8'))
    files = {'/art/': (root / 'index.html', 'text/html; charset=utf-8'),
             '/art/manifest.json': (manifest, 'application/json')}
    prefab_index = root / 'prefab-references.json'
    if prefab_index.is_file():
        files['/art/prefab-references.json'] = (prefab_index, 'application/json')
    ids = []
    for page in data['pages']:
        for name in ('color', 'auxiliary'):
            file = f'pages/{page["id"]}' + ('-auxiliary.png' if name == 'auxiliary' else '.png')
            files['/art/' + file] = (root / file, 'image/png')
    for sprite in data['sprites']:
        identifier = sprite['id']
        if not identifier or not identifier.replace('-', '').isalnum() or identifier in ids:
            raise ValueError(f'Invalid or duplicate board sprite ID: {identifier}')
        file = f'sprites/{identifier}.png'
        files['/art/' + file] = (root / file, 'image/png')
        ids.append(identifier)
    if any(not path.is_file() for path, _ in files.values()):
        raise ValueError('Decoded board art is incomplete. Regenerate it with decode_board_atlases.py.')
    return files, ids


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
    Handler.art_files, Handler.sprite_ids = load_art(ART)
    Handler.model_art = MODEL_ART.read_bytes()
    server = ThreadingHTTPServer(('127.0.0.1', args.port), Handler)
    print(f'{len(Handler.paths)} files: http://127.0.0.1:{args.port}/', flush=True)
    server.serve_forever()


if __name__ == '__main__':
    main()
