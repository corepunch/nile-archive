#!/usr/bin/env python3
"""Run the built WebGL games in Chromium (cloud CI, requires Playwright)."""
import functools
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Thread

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]


def main():
    handler = functools.partial(SimpleHTTPRequestHandler, directory=str(ROOT / 'dist'))
    server = ThreadingHTTPServer(('127.0.0.1', 0), handler)
    Thread(target=server.serve_forever, daemon=True).start()
    try:
        with sync_playwright() as playwright:
            browser = playwright.chromium.launch(args=['--enable-unsafe-swiftshader'])
            for game in ('nile-archive', 'relic-rush', 'christmas-market', 'volcano', 'clayfight'):
                page = browser.new_page(viewport={'width': 800, 'height': 600})
                errors = []
                page.on('pageerror', lambda error: errors.append(str(error)))
                page.goto(f'http://127.0.0.1:{server.server_port}/{game}/?fresh&mute')
                page.wait_for_function('window.Module && Module.calledRun', timeout=60000)
                colors = page.evaluate('''() => new Promise(resolve => requestAnimationFrame(() => {
                    const canvas = document.getElementById('canvas'), gl = canvas.getContext('webgl2');
                    if (!gl) { resolve(0); return; }
                    const pixels = new Uint8Array(canvas.width * canvas.height * 4);
                    gl.readPixels(0, 0, canvas.width, canvas.height, gl.RGBA, gl.UNSIGNED_BYTE, pixels);
                    const colors = new Set();
                    for (let i = 0; i < pixels.length; i += 4)
                        colors.add(pixels[i] * 65536 + pixels[i + 1] * 256 + pixels[i + 2]);
                    resolve(colors.size);
                }))''')
                if errors or colors < (16 if game == 'clayfight' else 100):
                    raise RuntimeError(f'{game}: {colors} rendered colors; errors: {errors}')
                output = ROOT / f'build/web-smoke/{game}.png'
                output.parent.mkdir(parents=True, exist_ok=True)
                page.screenshot(path=str(output))
                print(f'{game}: WebGL launch/render passed ({colors} colors)', flush=True)
                page.close()
            # Play through the real game until it opens platform's WebAudio device.
            page = browser.new_page(viewport={'width': 480, 'height': 900})
            page.goto(f'http://127.0.0.1:{server.server_port}/relic-rush/?fresh&smoke')
            page.wait_for_function("Module['engineAudio']", timeout=60000)
            page.mouse.click(5, 5)  # AudioContext requires a user gesture.
            page.wait_for_function("Module['engineAudio'].context.state === 'running'", timeout=15000)
            page.evaluate("""() => {
                const device = Module['engineAudio'];
                window.audioProbe = device.context.createAnalyser();
                device.node.connect(window.audioProbe);
            }""")
            page.wait_for_function("""() => {
                const data = new Float32Array(window.audioProbe.fftSize);
                window.audioProbe.getFloatTimeDomainData(data);
                return data.some(sample => Math.abs(sample) > .0001);
            }""", timeout=30000)
            print('relic-rush: platform mixer produced nonzero WebAudio samples', flush=True)
            page.close()
            browser.close()
    finally:
        server.shutdown()


if __name__ == '__main__':
    main()
