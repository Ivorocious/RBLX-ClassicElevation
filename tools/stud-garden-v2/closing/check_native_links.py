from pathlib import Path
from html.parser import HTMLParser
import re

root = Path('docs/artifacts/stud-garden-v2/closing-20261005')
class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
    def handle_starttag(self, tag, attrs):
        self.links.extend(value for key, value in attrs if key in ('href', 'src') and value)

missing = []
for name in ['NATIVE_PREVIEW.html', 'CLOSING_PREVIEW.html', 'NATIVE_VALIDATION.md', 'CLOSING_STATUS.md']:
    source = (root / name).read_text(encoding='utf-8')
    if name.endswith('.html'):
        parser = Links()
        parser.feed(source)
        links = parser.links
    else:
        links = re.findall(r'\]\(([^)]+)\)', source)
    for link in links:
        if not link.startswith(('http', '#')) and not (root / link.split('#')[0]).exists():
            missing.append({'document': name, 'target': link})
print({'missing': missing})
raise SystemExit(bool(missing))
