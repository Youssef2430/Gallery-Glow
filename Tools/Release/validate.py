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
metadata = (ROOT / 'app-store-assets/metadata.md').read_text()
if f'Product ID: `{product_id}`' not in metadata:
    errors.append('Release metadata must identify the product offered by the app')
metadata_build = re.search(r'^# Gallery Glow — build [\d.]+ \((\d+)\)', metadata)
if not metadata_build or metadata_build.group(1) not in versions:
    errors.append('Release metadata build number must match the Xcode project')
review_screenshot = ROOT / 'app-store-assets/iap-review-screenshot.png'
if not review_screenshot.is_file():
    errors.append('Missing IAP review screenshot')
else:
    data = review_screenshot.read_bytes()
    if len(data) < 26 or data[:8] != b'\x89PNG\r\n\x1a\n' or struct.unpack('>II', data[16:24]) != (1920, 1080):
        errors.append('IAP review screenshot must be a native 1920 x 1080 PNG')
if '[iap-review-screenshot.png](iap-review-screenshot.png)' not in metadata:
    errors.append('Release metadata must link the IAP review screenshot')
for path in [ROOT / 'README.md', ROOT / 'app-store-assets/metadata.md', *pages.keys()]:
    if re.search(r'youssef2430\.github\.io|github\.com/Youssef2430', path.read_text(), re.I):
        errors.append(f'Outdated website/repository URL: {path.relative_to(ROOT)}')

screens = list((ROOT / 'app-store-assets/release-1.0-7').glob('*.png'))
if len(screens) != 8:
    errors.append('Expected eight current App Store screenshots')
for path in screens:
    data = path.read_bytes()
    if data[:8] != b'\x89PNG\r\n\x1a\n' or struct.unpack('>II', data[16:24]) != (3840, 2160):
        errors.append(f'{path.name}: expected a 3840 x 2160 PNG')

# tvOS requires opaque backgrounds and banners, but genuine alpha in depth layers.
brand = ROOT / 'Gallery Glow/Assets.xcassets/App Icon & Top Shelf Image.brandassets'
for path in brand.rglob('*.png'):
    match = re.search(r'(\d+)x(\d+)(?:@(\d)x)?\.png$', path.name)
    if not match:
        errors.append(f'Unrecognized brand asset size: {path.name}')
        continue
    width, height, scale = int(match[1]), int(match[2]), int(match[3] or 1)
    data = path.read_bytes()
    if struct.unpack('>II', data[16:24]) != (width * scale, height * scale):
        errors.append(f'Incorrect brand asset dimensions: {path.name}')
    expected_color_type = 6 if path.name.startswith(('front-', 'middle-')) else 2
    if data[25] != expected_color_type:
        errors.append(f'Incorrect transparency for {path.name}')

if errors:
    raise SystemExit('\n'.join(errors))
print(f'Validated {len(pages)} pages, local links, asset references, build versions, product ID, IAP review attachment, and {len(screens)} listing screenshots. App Store Connect submission must be verified separately.')
