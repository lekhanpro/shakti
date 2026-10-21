"""Rebuild Shakti's original vector identity, exports and asset catalogue.

Requires reportlab, Pillow, pypdfium2, pypdf and fontTools. No remote requests.
Fonts are the app's existing Poppins/Nunito files; SVG lettering is outlined.
"""
from pathlib import Path
import argparse
import hashlib
import io
import json
import math
import shutil
import sys
import zipfile
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parents[2]
FONT_TOOLS = ROOT / 'tmp/pdfs/font-tools'
if FONT_TOOLS.exists():
    sys.path.insert(0, str(FONT_TOOLS))
from fontTools.ttLib import TTFont as OutlineFont
from fontTools.pens.svgPathPen import SVGPathPen
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.graphics.svgpath import SvgPath
from reportlab.graphics import renderPDF
from reportlab.graphics.shapes import Drawing
from reportlab.lib.colors import HexColor
from PIL import Image
import pypdfium2 as pdfium

DEST = ROOT / 'brand'
INK, NIGHT, PANEL = '#0F172A', '#070B14', '#1E293B'
INDIGO, LILAC, WHITE = '#4F46E5', '#A5B4FC', '#F8FAFC'
MUTED, GREEN, ROSE = '#94A3B8', '#10B981', '#E11D48'
SHIELD = 'M128 30 L204 59 L204 120 C204 169 169 205 128 226 C87 205 52 169 52 120 L52 59 Z'
FLAME = 'M136 75 C143 96 165 117 159 139 C156 157 141 171 124 170 C102 169 89 153 93 134 C95 122 103 113 111 104 C108 121 115 131 124 134 C117 116 124 91 136 75 Z'
FONTS = {}
for label, filename in [('display', 'Poppins-Bold.ttf'), ('body', 'Nunito-Regular.ttf'), ('bold', 'Nunito-Bold.ttf')]:
    path = DEST / 'fonts' / filename
    if not path.exists(): path = ROOT / 'app/assets/fonts' / filename
    pdfmetrics.registerFont(TTFont(label, str(path)))
    FONTS[label] = OutlineFont(str(path))


class Scene:
    def __init__(self, width, height, bg=None):
        self.w, self.h = width, height
        self.ops = []
        if bg:
            self.rect(0, 0, width, height, bg)

    def rect(self, x, y, w, h, fill, radius=0):
        self.ops.append(('rect', x, y, w, h, fill, radius))

    def circle(self, x, y, r, fill=None, stroke=None, width=1):
        self.ops.append(('circle', x, y, r, fill, stroke, width))

    def path(self, d, fill=None, stroke=None, width=1, x=0, y=0, scale=1):
        self.ops.append(('path', d, fill, stroke, width, x, y, scale))

    def text(self, value, x, baseline, size, fill=INK, font='body'):
        self.ops.append(('text', value, x, baseline, size, fill, font))

    def line(self, x1, y1, x2, y2, color, width=1):
        self.path(f'M{x1} {y1} L{x2} {y2}', stroke=color, width=width)

    def mark(self, x, y, size, color=INDIGO):
        self.path(SHIELD, stroke=color, width=12, x=x, y=y, scale=size / 256)
        self.path(FLAME, fill=color, x=x, y=y, scale=size / 256)

    def logo(self, x, y, scale=1, color=INDIGO, text=INK):
        self.mark(x, y, 96 * scale, color)
        self.text('Shakti', x + 112 * scale, y + 70 * scale, 72 * scale, text, 'display')

    def svg(self):
        output = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w}" height="{self.h}" viewBox="0 0 {self.w} {self.h}" role="img"><title>Shakti - Personal Safety Network</title>']
        for op in self.ops:
            kind, *v = op
            if kind == 'rect':
                x,y,w,h,fill,r = v
                output.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}"/>')
            elif kind == 'circle':
                x,y,r,fill,stroke,width = v
                output.append(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill or "none"}" stroke="{stroke or "none"}" stroke-width="{width}"/>')
            elif kind == 'path':
                d,fill,stroke,width,x,y,scale = v
                output.append(f'<path d="{d}" transform="translate({x} {y}) scale({scale})" fill="{fill or "none"}" stroke="{stroke or "none"}" stroke-width="{width}" stroke-linejoin="round" stroke-linecap="round"/>')
            elif kind == 'text':
                text,x,y,size,fill,font = v
                f = FONTS[font]
                glyphs = f.getGlyphSet()
                cmap = f.getBestCmap()
                units = f['head'].unitsPerEm
                cursor = 0
                output.append(f'<g aria-label="{escape(text)}" fill="{fill}" transform="translate({x} {y}) scale({size/units} {-size/units})">')
                for ch in text:
                    name = cmap.get(ord(ch), '.notdef')
                    pen = SVGPathPen(glyphs)
                    glyphs[name].draw(pen)
                    d = pen.getCommands()
                    if d:
                        output.append(f'<path d="{d}" transform="translate({cursor} 0)"/>')
                    cursor += f['hmtx'].metrics[name][0]
                output.append('</g>')
        return '\n'.join(output + ['</svg>'])

    def paint(self, c):
        c.saveState()
        c.translate(0, self.h)
        c.scale(1, -1)
        for kind, *v in self.ops:
            if kind == 'rect':
                x,y,w,h,fill,r = v
                c.setFillColor(HexColor(fill))
                c.roundRect(x,y,w,h,r,stroke=0,fill=1)
            elif kind == 'circle':
                x,y,r,fill,stroke,width = v
                if fill: c.setFillColor(HexColor(fill))
                if stroke: c.setStrokeColor(HexColor(stroke))
                c.setLineWidth(width)
                c.circle(x,y,r,stroke=int(bool(stroke)),fill=int(bool(fill)))
            elif kind == 'path':
                d,fill,stroke,width,x,y,scale = v
                c.saveState()
                c.translate(x,y)
                c.scale(scale,scale)
                p = SvgPath(d, fillColor=HexColor(fill) if fill else None,
                            strokeColor=HexColor(stroke) if stroke else None,
                            strokeWidth=width, strokeLineJoin=1, strokeLineCap=1)
                drawing=Drawing(self.w,self.h)
                drawing.add(p)
                renderPDF.draw(drawing,c,0,0)
                c.restoreState()
            elif kind == 'text':
                value,x,y,size,fill,font = v
                c.saveState()
                c.translate(x,y)
                c.scale(1,-1)
                c.setFont(font,size)
                c.setFillColor(HexColor(fill))
                c.drawString(0,0,value)
                c.restoreState()
        c.restoreState()

    def pdf(self, page_size=None):
        stream=io.BytesIO()
        c=canvas.Canvas(stream,pagesize=page_size or (self.w,self.h),pageCompression=1,invariant=1)
        c.setTitle('Shakti | Personal Safety Network')
        c.setAuthor('Lekhan, Manas, Vikat and Hemanth | DBIT')
        if page_size: c.scale(page_size[0]/self.w,page_size[1]/self.h)
        self.paint(c)
        c.showPage()
        c.save()
        return stream.getvalue()


manifest=[]
def save(scene, relative, transparent=False, pdf=False, sizes=None, pdf_size=None):
    base=DEST / relative
    base.parent.mkdir(parents=True,exist_ok=True)
    base.with_suffix('.svg').write_text(scene.svg(),encoding='utf-8')
    data=scene.pdf(pdf_size)
    if pdf: base.with_suffix('.pdf').write_bytes(data)
    document=pdfium.PdfDocument(data)
    bitmap=document[0].render(scale=2, fill_color=(0,0,0,0) if transparent else (255,255,255,255))
    img=bitmap.to_pil().copy()
    img=img.convert('RGBA' if transparent else 'RGB')
    img=img.resize((scene.w,scene.h),Image.Resampling.LANCZOS)
    img.save(base.with_suffix('.png'),optimize=True)
    for size in sizes or []:
        img.resize((size,size),Image.Resampling.LANCZOS).save(base.parent/f'{base.name}-{size}.png',optimize=True)
    bitmap.close()
    document.close()
    manifest.append({'asset':relative,'width':scene.w,'height':scene.h,'alpha':transparent})
    return img


def orbit(s,cx,cy,scale=1,dark=True):
    ring='#2C335C' if dark else '#D9DDF8'
    for r in [110,180,250]: s.circle(cx,cy,r*scale,stroke=ring,width=1.5*scale)
    points=[(-145,-105),(175,-43),(-54,184)]
    for dx,dy in points:
        x,y=cx+dx*scale,cy+dy*scale
        s.line(cx,cy,x,y,ring,2*scale)
        s.circle(x,y,20*scale,INDIGO)
        s.circle(x,y,5*scale,WHITE)
    s.circle(cx,cy,84*scale,INDIGO)
    s.mark(cx-67*scale,cy-67*scale,134*scale,WHITE)


def campaign(width,height,kind):
    s=Scene(width,height,NIGHT)
    k=width/1200
    if kind=='story':
        s.logo(78,110,1.0,LILAC,WHITE)
        s.text('PERSONAL SAFETY NETWORK',82,278,22,LILAC,'bold')
        s.text('Your people.',78,420,88,WHITE,'display')
        s.text('Within reach.',78,530,88,WHITE,'display')
        orbit(s,width/2,1040,1.65)
        s.text('Walk with intention.',82,1580,38,WHITE,'bold')
        s.text('Stay connected to your circle.',82,1640,32,MUTED)
        s.line(82,1734,width-82,1734,'#334155')
        s.text('SHAKTI  /  ANDROID COMMUNITY PROJECT',82,1795,21,LILAC,'bold')
    else:
        s.logo(66*k,48*k,0.62*k,LILAC,WHITE)
        tall=height/width>0.7
        if tall:
            s.text('Your people.',70*k,280*k,88*k,WHITE,'display')
            s.text('Within reach.',70*k,385*k,88*k,WHITE,'display')
            orbit(s,width/2,height*0.68,1.15*k)
            s.text('Personal Safety Network',70*k,height-65*k,27*k,MUTED)
        else:
            s.text('Your people.',66*k,height*.49,76*k,WHITE,'display')
            s.text('Within reach.',66*k,height*.49+90*k,76*k,WHITE,'display')
            s.text('Personal Safety Network',68*k,height-66*k,25*k,MUTED)
            orbit(s,width*.79,height*.52,.77*k)
    return s


def guide():
    pages=[]
    s=Scene(1200,800,NIGHT)
    s.text('SHAKTI  /  IDENTITY SYSTEM 01',64,70,18,LILAC,'bold')
    s.logo(58,133,2.1,LILAC,WHITE)
    s.text('Your people. Within reach.',68,464,43,WHITE,'display')
    s.text('A calm identity for a personal safety network.',70,527,25,MUTED)
    s.line(68,639,1132,639,'#334155')
    s.text('Lekhan  /  Manas  /  Vikat  /  Hemanth',70,695,23,WHITE,'bold')
    s.text('DBIT  /  VTU 1BCP308 Community Project',70,738,20,MUTED)
    pages.append(s)
    s=Scene(1200,800,'#F4F5FB')
    s.text('01 / THE MARK',64,70,18,INDIGO,'bold')
    s.text('Strength, held with care.',64,150,46,INK,'display')
    s.mark(75,206,340,INDIGO)
    s.text('The shield creates a protective boundary.',525,275,24,INK,'bold')
    s.text('The flame carries agency, energy and resolve.',525,323,22,INK)
    s.text('It is a symbol of support, never a rescue guarantee.',525,366,20,INK)
    s.text('Clear space = one quarter of mark width.',525,448,21,INDIGO,'bold')
    s.text('Minimum: mark 24 px; full logo 144 px wide.',525,491,20,INK)
    s.mark(70,600,88,INDIGO)
    s.mark(212,600,88,INK)
    s.rect(355,588,113,113,NIGHT,16);s.mark(368,601,87,WHITE)
    s.text('Primary / ink / reverse',525,653,21,INK)
    pages.append(s)
    s=Scene(1200,800,NIGHT)
    s.text('02 / COLOUR WITH MEANING',64,70,18,LILAC,'bold')
    s.text('Indigo is identity. Rose is SOS.',64,150,43,WHITE,'display')
    swatches=[('Indigo',INDIGO,'Brand and actions'),('Night',NIGHT,'Primary canvas'),('Cloud',WHITE,'Text and light canvas'),('Lilac',LILAC,'Secondary accents'),('Emerald',GREEN,'Safe / checked in'),('Rose',ROSE,'Emergency only')]
    for i,(name,color,use) in enumerate(swatches):
        x=64+(i%3)*365;y=220+(i//3)*242
        s.rect(x,y,333,120,color,14)
        if color==NIGHT: s.path(f'M{x} {y} h333 v120 h-333 Z',stroke='#334155')
        s.text(name,x,y+158,23,WHITE,'bold');s.text(color,x+204,y+158,18,MUTED)
        s.text(use,x,y+193,18,MUTED)
    pages.append(s)
    s=Scene(1200,800,'#F4F5FB')
    s.text('03 / TYPE AND VOICE',64,70,18,INDIGO,'bold')
    s.text('Poppins Bold',64,170,67,INK,'display')
    s.text('Clear. Calm. Human.',66,239,36,INDIGO,'display')
    s.text('Nunito / readable body text and helpful detail',68,309,28,INK)
    s.line(64,358,1135,358,'#D9DDF8')
    s.text('Say what happens next.',64,425,28,INK,'bold')
    for y,line in enumerate(['Use: "Start a walk", "Add a trusted contact", "SMS handed off".',
                             'Avoid: "Always safe", "Guaranteed rescue", "Police notified".',
                             'Explain cellular and internet requirements in nearby product copy.',
                             'Use real screenshots and measured results in release materials.']):
        s.text(line,66,484+y*47,22,INK)
    s.text('Web keeps its Bricolage Grotesque / Instrument Sans pairing.',66,718,21,INDIGO,'bold')
    pages.append(s)
    s=Scene(1200,800,NIGHT)
    s.text('04 / USE THE SYSTEM',64,70,18,LILAC,'bold')
    s.text('One identity. Every touchpoint.',64,150,43,WHITE,'display')
    for i,(title,detail) in enumerate([
        ('Logo masters','SVG paths and transparent PNGs; dark, light and one-colour variants.'),
        ('Android and store','512 px Play icon; 1024 x 500 feature graphic; adaptive icon layers.'),
        ('Community and social','Square, portrait, story, share card, poster and presentation covers.'),
        ('Editable sources','All geometry, copy and layouts rebuild from tools/build_brand.py.')]):
        y=244+i*114
        s.text(f'0{i+1}',66,y,31,LILAC,'display')
        s.text(title,150,y,28,WHITE,'bold')
        s.text(detail,150,y+42,21,MUTED)
    s.text('No Play badge, fabricated app screenshots or launch claims are included.',66,740,20,MUTED)
    pages.append(s)
    path=DEST/'guides/shakti-brand-guide.pdf'
    path.parent.mkdir(parents=True,exist_ok=True)
    c=canvas.Canvas(str(path),pagesize=(1200,800),pageCompression=1,invariant=1)
    c.setTitle('Shakti | Brand Guide');c.setAuthor('Shakti team | DBIT')
    for s in pages: s.paint(c);c.showPage()
    c.save()


def build(integrate=False):
    DEST.mkdir(exist_ok=True)
    for name,color in [('indigo',INDIGO),('ink',INK),('white',WHITE),('black','#000000')]:
        s=Scene(256,256);s.mark(0,0,256,color)
        save(s,f'logos/shakti-symbol-{name}',True,pdf=True,sizes=[24,32,64,128,512])
    for name,mark,ink in [('light',INDIGO,INK),('dark',LILAC,WHITE),('mono-black','#000000','#000000'),('mono-white','#FFFFFF','#FFFFFF')]:
        s=Scene(660,170);s.logo(18,20,1.35,mark,ink)
        save(s,f'logos/shakti-horizontal-{name}',True,pdf=True)
    for name,bg,color in [('light','#F4F5FB',INDIGO),('dark',NIGHT,WHITE)]:
        s=Scene(600,600,bg);s.mark(170,60,260,color)
        s.text('Shakti',164,418,85,color,'display')
        s.text('PERSONAL SAFETY NETWORK',132,478,18,color,'bold')
        save(s,f'logos/shakti-stacked-{name}',pdf=True)
    s=Scene(1024,1024,INDIGO);s.mark(42,42,940,WHITE)
    icon=save(s,'icons/shakti-app-icon',sizes=[16,32,48,64,72,96,128,144,180,192,256,512])
    store=DEST/'store';store.mkdir(exist_ok=True)
    icon.convert('RGBA').resize((512,512),Image.Resampling.LANCZOS).save(store/'google-play-icon-512.png')
    icon.convert('RGBA').save(DEST/'icons/favicon.ico',sizes=[(16,16),(32,32),(48,48)])
    save(campaign(1024,500,'wide'),'store/google-play-feature-graphic-1024x500')
    save(campaign(1200,630,'wide'),'social/shakti-opengraph-1200x630')
    save(campaign(1080,1080,'square'),'social/shakti-square-1080')
    save(campaign(1080,1350,'portrait'),'social/shakti-portrait-1080x1350')
    save(campaign(1080,1920,'story'),'social/shakti-story-1080x1920')
    s=Scene(1600,400,NIGHT);s.logo(72,95,1.35,LILAC,WHITE)
    s.text('Your people. Within reach.',705,213,42,WHITE,'display')
    s.text('Personal Safety Network',708,275,24,MUTED)
    save(s,'social/shakti-banner-1600x400')
    s=Scene(1920,1080,NIGHT);s.logo(110,98,1.4,LILAC,WHITE)
    s.text('Your people.',110,430,112,WHITE,'display');s.text('Within reach.',110,565,112,WHITE,'display')
    orbit(s,1480,500,1.3)
    s.line(110,856,1810,856,'#334155');s.text('Lekhan  /  Manas  /  Vikat  /  Hemanth',110,926,31,WHITE,'bold')
    s.text('DBIT  /  VTU 1BCP308 Community Project',110,991,26,MUTED)
    save(s,'presentation/shakti-title-1920x1080',pdf=True)
    s=Scene(1920,1080,'#F4F5FB');s.logo(90,62,.7,INDIGO,INK)
    s.text('Section title',94,270,72,INK,'display');s.line(96,332,1824,332,'#D9DDF8')
    s.text('Add evidence, insights or a diagram in this space.',96,438,32,INK)
    s.text('SHAKTI  /  PERSONAL SAFETY NETWORK',96,1000,21,INDIGO,'bold')
    save(s,'presentation/shakti-content-template-1920x1080',pdf=True)
    s=Scene(1190,1684,'#F4F5FB');s.logo(80,80,1.1,INDIGO,INK)
    s.text('Your people.',84,377,96,INK,'display');s.text('Within reach.',84,495,96,INK,'display')
    s.text('Meet your personal safety network.',86,581,31,INDIGO,'bold')
    orbit(s,595,983,1.05,False)
    s.text('Plan a walk. Add trusted contacts. Learn the SOS flow.',86,1370,28,INK,'bold')
    s.text('An Android community project. Ask the team about invited testing.',86,1425,26,INK)
    s.line(86,1485,1104,1485,'#D9DDF8')
    s.text('Lekhan  /  Manas  /  Vikat  /  Hemanth',86,1540,26,INK,'bold')
    s.text('DBIT  /  VTU 1BCP308 Community Project',86,1594,23,INDIGO)
    save(s,'print/shakti-community-poster-A4',pdf=True,pdf_size=(595.276,841.89))
    s=Scene(1920,1080,NIGHT);orbit(s,960,500,1.35);s.text('Shakti',812,944,83,WHITE,'display')
    save(s,'wallpapers/shakti-desktop-1920x1080')
    s=Scene(1080,1920,NIGHT);orbit(s,540,860,1.5);s.text('Shakti',392,1498,83,WHITE,'display')
    s.text('YOUR PEOPLE. WITHIN REACH.',282,1570,24,LILAC,'bold')
    save(s,'wallpapers/shakti-phone-1080x1920')
    # Abstract supporting illustrations are brand artwork, never product screenshots.
    for name in ['circle','walk','vault']:
        s=Scene(640,480)
        if name=='circle': orbit(s,320,240,.75,False)
        elif name=='walk':
            s.path('M90 340 C210 420 180 100 350 150 C440 180 430 300 550 100',stroke=INDIGO,width=8)
            for x,y in [(90,340),(550,100)]:s.circle(x,y,18,INDIGO);s.circle(x,y,6,WHITE)
            s.mark(251,177,130,INDIGO)
        else:
            s.rect(176,132,288,240,INDIGO,32);s.path('M240 140 V108 C240 24 400 24 400 108 V140',stroke=INDIGO,width=20)
            s.circle(320,234,27,WHITE);s.rect(310,247,20,54,WHITE,5)
        save(s,f'illustrations/shakti-{name}',True)
    guide()
    s=Scene(1600,1000,'#E7EAF5')
    s.text('SHAKTI / IDENTITY KIT',55,66,22,INDIGO,'bold')
    s.rect(50,110,1000,310,NIGHT,24);s.logo(100,177,1.9,LILAC,WHITE)
    s.rect(1090,110,460,460,INDIGO,32);s.mark(1120,140,400,WHITE)
    s.rect(50,460,1000,270,'#FFFFFF',24);s.logo(104,509,1.7,INDIGO,INK)
    s.text('PERSONAL SAFETY NETWORK',108,684,22,INDIGO,'bold')
    s.text('Your people.',1090,661,38,INK,'display');s.text('Within reach.',1090,711,38,INK,'display')
    for i,color in enumerate([INDIGO,NIGHT,WHITE,LILAC,GREEN,ROSE]):
        x=50+i*251;s.rect(x,796,230,106,color,18);s.text(color,x,946,21,INK,'bold')
    save(s,'identity-preview')
    tokens={'name':'Shakti','descriptor':'Personal Safety Network','tagline':'Your people. Within reach.',
            'colors':{'brand':INDIGO,'night':NIGHT,'ink':INK,'cloud':WHITE,'lilac':LILAC,'safe':GREEN,'sos':ROSE},
            'typography':{'brand':'Poppins Bold','body':'Nunito','webDisplay':'Bricolage Grotesque','webBody':'Instrument Sans'},
            'clearSpace':'25% of symbol width','minimumSymbolPx':24,'minimumHorizontalPx':144}
    (DEST/'tokens.json').write_text(json.dumps(tokens,indent=2)+'\n')
    if integrate: integration(icon)
    # Build a human-readable contact sheet from final files.
    thumbs=[('Play feature',DEST/'store/google-play-feature-graphic-1024x500.png'),('Share card',DEST/'social/shakti-opengraph-1200x630.png'),('Square post',DEST/'social/shakti-square-1080.png'),('Portrait post',DEST/'social/shakti-portrait-1080x1350.png'),('Presentation',DEST/'presentation/shakti-title-1920x1080.png'),('Phone wallpaper',DEST/'wallpapers/shakti-phone-1080x1920.png')]
    from PIL import ImageDraw,ImageFont
    sheet=Image.new('RGB',(1600,1430),'#E7EAF5');d=ImageDraw.Draw(sheet)
    font=ImageFont.truetype(str(ROOT/'app/assets/fonts/Nunito-Bold.ttf'),27)
    for i,(label,path) in enumerate(thumbs):
        img=Image.open(path);img.thumbnail((728,370),Image.Resampling.LANCZOS)
        x=48+(i%2)*790;y=60+(i//2)*455
        sheet.paste(img,(x+(728-img.width)//2,y))
        d.text((x,y+385),label,fill=INK,font=font)
    sheet.save(DEST/'preview.jpg',quality=91)
    (DEST/'asset-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    cards=[]
    for item in manifest:
        name=item['asset']
        bg=NIGHT if any(word in name for word in ['white','-dark']) else '#F4F5FB'
        links=f'<a href="{name}.svg">SVG</a> <a href="{name}.png">PNG</a>'
        if (DEST/f'{name}.pdf').exists(): links+=f' <a href="{name}.pdf">PDF</a>'
        cards.append(f'<article><div class="art" style="background:{bg}"><img src="{name}.png" alt="{escape(name.split("/")[-1].replace("-"," "))}" loading="lazy"></div><h2>{escape(name.split("/")[-1])}</h2><p>{item["width"]} x {item["height"]}</p><nav>{links}</nav></article>')
    (DEST/'index.html').write_text('''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Shakti | Brand assets</title>
<style>@font-face{font-family:Poppins;src:url(fonts/Poppins-Bold.ttf)}@font-face{font-family:Nunito;src:url(fonts/Nunito-Regular.ttf)}*{box-sizing:border-box}body{margin:0;background:#f4f5fb;color:#0f172a;font-family:Nunito,sans-serif}header{padding:64px max(5vw,24px);background:#070b14;color:#f8fafc}header img{width:260px;max-width:100%}h1{font:40px Poppins,sans-serif;margin:36px 0 10px}header p{color:#a5b4fc;font-size:20px}a{color:#4f46e5}header a{color:#a5b4fc}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,300px),1fr));gap:24px;padding:40px max(5vw,24px)}article{padding:16px;border:1px solid #d9ddf8;border-radius:20px;background:white;min-width:0}.art{height:240px;border-radius:12px;display:grid;place-items:center;padding:16px}.art img{max-width:100%;max-height:208px}h2{font-size:17px;overflow-wrap:anywhere}nav a{display:inline-block;margin-right:12px;padding:8px 0}footer{padding:24px max(5vw,24px)}@media(prefers-reduced-motion:no-preference){a{transition:opacity .15s}a:hover{opacity:.7}}</style>
<header><img src="logos/shakti-horizontal-dark.svg" alt="Shakti"><h1>Your people. Within reach.</h1><p>Editable identity kit / 26 asset families</p><a href="guides/shakti-brand-guide.pdf">Read the brand guide</a> &nbsp; <a href="README.md">Usage and sources</a></header><main>'''+''.join(cards)+'''</main><footer>Lekhan / Manas / Vikat / Hemanth · DBIT · VTU 1BCP308 Community Project</footer></html>''',encoding='utf-8')
    archive=ROOT/'output/brand/shakti-brand-kit.zip';archive.parent.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for file in sorted(DEST.rglob('*')):
            if file.is_file() and '__pycache__' not in file.parts:z.write(file,file.relative_to(DEST.parent))
    print(json.dumps({'families':len(manifest),'files':len(list(DEST.rglob('*.*'))),'archive':str(archive)},indent=2))


def integration(icon):
    target=ROOT/'web/public/brand';target.mkdir(exist_ok=True)
    for name in ['shakti-symbol-white','shakti-horizontal-dark','shakti-horizontal-light']:
        shutil.copy2(DEST/f'logos/{name}.svg',target/f'{name}.svg')
    shutil.copy2(DEST/'social/shakti-opengraph-1200x630.png',target/'shakti-opengraph.png')
    shutil.copy2(DEST/'icons/shakti-app-icon.svg',ROOT/'web/app/icon.svg')
    shutil.copy2(DEST/'icons/favicon.ico',ROOT/'web/app/favicon.ico')
    icon.resize((180,180),Image.Resampling.LANCZOS).save(ROOT/'web/app/apple-icon.png')
    for folder,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
        path=ROOT/f'app/android/app/src/main/res/mipmap-{folder}/ic_launcher.png'
        icon.resize((size,size),Image.Resampling.LANCZOS).save(path)
    # 108dp layer, meaningful artwork inside a 66dp safe circle.
    fg=f'''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="256" android:viewportHeight="256">
  <group android:scaleX="0.60" android:scaleY="0.60" android:translateX="51.2" android:translateY="51.2">
    <path android:pathData="{SHIELD}" android:fillColor="#00000000" android:strokeColor="#FFF8FAFC" android:strokeWidth="12" android:strokeLineJoin="round"/>
    <path android:pathData="{FLAME}" android:fillColor="#FFF8FAFC"/>
  </group>
</vector>
'''
    draw=ROOT/'app/android/app/src/main/res/drawable'
    (draw/'ic_launcher_foreground.xml').write_text(fg)
    (draw/'ic_launcher_monochrome.xml').write_text(fg.replace('#FFF8FAFC','#FFFFFFFF'))
    (draw/'ic_launcher_background.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
    <path android:pathData="M0 0 H108 V108 H0 Z" android:fillColor="#FF4F46E5"/>
</vector>
''')
    for p in (ROOT/'app/android/app/src/main/res/mipmap-anydpi-v26').glob('*.xml'):
        content=p.read_text().replace('<monochrome android:drawable="@drawable/ic_launcher_foreground"','<monochrome android:drawable="@drawable/ic_launcher_monochrome"')
        p.write_text(content)


if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--integrate',action='store_true')
    build(parser.parse_args().integrate)
