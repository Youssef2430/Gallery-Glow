#!/usr/bin/env python3
"""Dependency-free checks for release links, asset references, and metadata."""
import json
import re
import struct
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[2]
errors = []
class Page(HTMLParser):
    def __init__(self):
        super().__init__()
        self.refs = []
        self.ids = set()
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if 'id' in attrs:
            self.ids.add(attrs['id'])
        for key in ['href', 'src']:
            if attrs.get(key):
                self.refs.append(attrs[key])
        if 'srcset' in attrs:
            self.refs.extend(part.strip().split()[0] for part in attrs['srcset'].split(','))
        if tag == 'img' and 'alt' not in attrs:
            errors.append('Image missing alt text')

pages = {}
for path in (ROOT / 'docs').glob('*.html'):
    page = Page()
    page.feed(path.read_text())
    pages[path.resolve()] = page
for path, page in pages.items():
    for ref in page.refs:
        url = urlsplit(ref)
        if url.scheme or url.netloc or ref.startswith('//'):
            continue
        target = (path.parent / unquote(url.path)).resolve() if url.path else path
        if target.is_dir():
            target /= 'index.html'
        if not target.exists():
            errors.append(f'{path.name}: missing {ref}')
        elif url.fragment and target in pages and unquote(url.fragment) not in pages[target].ids:
            errors.append(f'{path.name}: missing anchor {ref}')

for path in (ROOT / 'Gallery Glow/Assets.xcassets').rglob('Contents.json'):
    contents = json.loads(path.read_text())
    for item in contents.get('images', []) + contents.get('layers', []):
        filename = item.get('filename')
        if filename and not (path.parent / filename).exists():
            errors.append(f'Missing asset: {path.parent / filename}')

project = (ROOT / 'Gallery Glow.xcodeproj/project.pbxproj').read_text()
versions = set(re.findall(r'CURRENT_PROJECT_VERSION = (\d+);', project))
if len(versions) != 1:
    errors.append('App, extension and test build numbers must match')
manager = (ROOT / 'Gallery Glow/PurchaseManager.swift').read_text()
product_id = re.search(r'lifetimeProductID = "([^"]+)"', manager).group(1)
storekit = json.loads((ROOT / 'Gallery GlowTests/GalleryGlow.storekit').read_text())
if not any(p['productID'] == product_id and p['type'] == 'NonConsumable' for p in storekit['products']):
    errors.append('StoreKit test configuration must include the live non-consumable product ID')
for path in [ROOT / 'README.md', ROOT / 'app-store-assets/metadata.md', *pages.keys()]:
    if re.search(r'youssef2430\.github\.io|github\.com/Youssef2430', path.read_text(), re.I):
        errors.append(f'Outdated website/repository URL: {path.relative_to(ROOT)}')

screens = list((ROOT / 'app-store-assets/release-1.0-6').glob('*.png'))
if len(screens) != 8:
    errors.append('Expected eight current App Store screenshots')
for path in screens:
    data = path.read_bytes()
    if data[:8] != b'\x89PNG\r\n\x1a\n' or struct.unpack('>II', data[16:24]) != (3840, 2160):
        errors.append(f'{path.name}: expected a 3840 x 2160 PNG')

if errors:
    raise SystemExit('\n'.join(errors))
print(f'Validated {len(pages)} pages, local links, asset references, build versions, product ID, and {len(screens)} screenshots.')
