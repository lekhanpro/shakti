"""Validate the saved brand exports, PDF font embedding and handover archive."""
from pathlib import Path
import json
import xml.etree.ElementTree as ET
import zipfile
from PIL import Image
from pypdf import PdfReader
from pypdf.generic import ContentStream

ROOT = Path(__file__).resolve().parents[2]
BRAND = ROOT / 'brand'
entries = json.loads((BRAND / 'asset-manifest.json').read_text())
for item in entries:
    image = Image.open((BRAND / item['asset']).with_suffix('.png'))
    assert image.size == (item['width'], item['height']), item
    assert ('A' in image.mode) == item['alpha'], item
    assert image.getbbox() is not None, item
for svg in BRAND.rglob('*.svg'):
    root = ET.parse(svg).getroot()
    assert root.tag.endswith('svg'), svg
    assert not root.findall('.//{http://www.w3.org/2000/svg}text'), svg
    assert not root.findall('.//{http://www.w3.org/2000/svg}image'), svg
icon = Image.open(BRAND / 'store/google-play-icon-512.png')
assert icon.size == (512, 512) and icon.mode == 'RGBA'
assert (BRAND / 'store/google-play-icon-512.png').stat().st_size <= 1024 * 1024
favicon = Image.open(BRAND / 'icons/favicon.ico')
assert favicon.mode == 'RGBA'
graphic = Image.open(BRAND / 'store/google-play-feature-graphic-1024x500.png')
assert graphic.size == (1024, 500) and graphic.mode == 'RGB'
guide = PdfReader(BRAND / 'guides/shakti-brand-guide.pdf')
assert len(guide.pages) == 5
for page in guide.pages:
    used = set()
    current_font = None
    for operands, operation in ContentStream(page.get_contents(), guide).operations:
        if operation == b'Tf': current_font = operands[0]
        if operation in (b'Tj', b'TJ', b"'", b'"'):
            used.add(current_font)
    for name in used:
        font = page['/Resources']['/Font'][name].get_object()
        descriptor = font.get('/FontDescriptor')
        assert descriptor, font
        descriptor = descriptor.get_object()
        assert any(key in descriptor for key in ['/FontFile', '/FontFile2', '/FontFile3']), font
poster = PdfReader(BRAND / 'print/shakti-community-poster-A4.pdf').pages[0]
assert abs(float(poster.mediabox.width) - 595.276) < 0.02
assert abs(float(poster.mediabox.height) - 841.89) < 0.02
with zipfile.ZipFile(ROOT / 'output/brand/shakti-brand-kit.zip') as archive:
    assert archive.testzip() is None
    assert 'brand/README.md' in archive.namelist()
    assert 'brand/tools/build_brand.py' in archive.namelist()
print(f'Validated {len(entries)} asset families, SVG outlines, Play formats, embedded guide fonts, A4 poster and ZIP integrity.')
