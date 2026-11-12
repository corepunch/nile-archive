#!/usr/bin/env python3
"""Build a self-contained local gallery of the bundled Match3 goal-panel art."""
import base64
import html
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'reference/Homescapes.app/base.zip'
OUTPUT = ROOT / 'reference/homescapes-analysis/goal-icons.html'
PREFIX = 'base_mm/Match3/vso/textures/UI/Match3TargetsBase/'


def main():
    with zipfile.ZipFile(SOURCE) as archive:
        names = sorted(n for n in archive.namelist() if n.startswith(PREFIX) and n.endswith('.webp'))
        if not names:
            raise SystemExit('No goal icons found in ' + str(SOURCE))
        cards = []
        for name in names:
            label = name[len(PREFIX):].removesuffix('.webp')
            data = base64.b64encode(archive.read(name)).decode('ascii')
            cards.append('<article data-name="{}"><img alt="{}" src="data:image/webp;base64,{}"><p>{}</p></article>'.format(
                html.escape(label, quote=True), html.escape(label, quote=True), data, html.escape(label)))
    page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Homescapes goal icon inventory</title><style>
body{font:16px system-ui,sans-serif;color:#2a2231;background:#f6f3ee;margin:auto;max-width:1100px;padding:2rem}
h1{margin-bottom:.4rem}p{line-height:1.5}input{font:inherit;padding:.7rem;width:min(28rem,90%);border:1px solid #aaa;border-radius:.5rem}
#gallery{display:grid;grid-template-columns:repeat(auto-fill,minmax(145px,1fr));gap:1rem;margin-top:1.5rem}
article{background:white;border:1px solid #ddd;border-radius:.7rem;padding:.75rem;text-align:center;overflow-wrap:anywhere}
article img{width:100%;height:115px;object-fit:contain}article p{font-size:.8rem;margin:.3rem 0}
</style><h1>Homescapes match-3 goal icons</h1><p>Original bundled goal-panel images, including facelift variants. These are not necessarily the board sprites or the complete mechanic inventory. Names are source filenames; they do not prove rules.</p>
<label>Filter icons <input id="search" type="search" placeholder="Try chip, box, plane, facelift"></label><p id="count"></p><main id="gallery">''' + ''.join(cards) + '''</main><script>
const cards=[...document.querySelectorAll('article')],search=document.querySelector('#search'),count=document.querySelector('#count');
function filter(){let q=search.value.toLowerCase();let visible=0;for(const card of cards){let show=card.dataset.name.toLowerCase().includes(q);card.hidden=!show;if(show)visible++}count.textContent=visible+' of '+cards.length+' images'}search.addEventListener('input',filter);filter();
</script></html>'''
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(page, encoding='utf-8')
    print(f'{len(names)} icons: {OUTPUT}')


if __name__ == '__main__':
    main()
