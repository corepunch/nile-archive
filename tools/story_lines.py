#!/usr/bin/env python3
"""List script lines that may be narration rather than speech (docs/STORY_WRITING.md#speech-only-no-narration).

    python3 tools/story_lines.py christmas-market        # candidates, with level
    python3 tools/story_lines.py relic-rush --count      # only the number

A candidate has no listener and no intention a script can see: no I/we/you,
no name of someone present, no question and no imperative opener. Every
candidate needs a human read: rewrite it as speech to someone, or cut it.
"""
import argparse
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PERSON = re.compile(r"\b(i|i'm|i've|i'll|i'd|me|my|mine|we|we're|we've|we'll|we'd|us|our|ours|you|you're|you've|"
                    r"you'll|you'd|your|yours|let's)\b", re.I)
OPENERS = re.compile(r"^(look|listen|come|go|take|give|bring|tell|mind|wait|hold|keep|stop|help|please|thank|thanks|"
                     r"sit|stand|watch|hush|quick|careful|leave|put|try|ask|don't|do|did|have|has|is|are|was|were|can|"
                     r"could|will|would|shall|should|who|what|where|when|why|how|yes|no|oh|ah|well|right|deal|"
                     r"goodnight|good morning|morning|evening|hello|welcome)\b", re.I)


def lines(game):
    text = (ROOT / 'games' / game / 'docs/story.md').read_text()
    text = re.split(r'^## (?:Small lines|Implementation|Checks)', text, flags=re.M)[0]   # notes, not scenes
    speakers = '|'.join(re.escape(s) for s in sorted(set(re.findall(r'^- \*\*([^*:(]+?)(?: \(\w+\))?:\*\*', text, re.M))))
    level = None
    for row in text.splitlines():
        heading = re.match(r'\*\*(?:Before level|Level|After restoration|Upgrade|Placed|With|Visit) (\w+)', row)
        if heading:
            level = heading[1]   # a level number, or an upgrade's event id
        m = re.match(r'- \*\*([^*:(]+?)(?: \((\w+)\))?:\*\* (.+)', row)
        if m and level:
            yield level, m[1], m[2], m[3], speakers


def candidate(speaker, kind, line, speakers):
    if kind == 'thought' or line.startswith('"'):
        return False
    names = re.compile(r'\b(%s|Gran|Mum|love|pet|dear)\b' % speakers)
    return not (PERSON.search(line) or '?' in line or OPENERS.match(line) or names.search(line.replace(speaker, '')))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('game')
    parser.add_argument('--count', action='store_true')
    args = parser.parse_args()
    found = [(lv, who, line) for lv, who, kind, line, speakers in lines(args.game) if candidate(who, kind, line, speakers)]
    if not args.count:
        for lv, who, line in found:
            print(f'{lv:>6} {who}: {line}')
    print(f'{len(found)} candidate report lines')


if __name__ == '__main__':
    main()
