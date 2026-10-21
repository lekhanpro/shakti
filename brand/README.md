# Shakti identity kit

An original, editable shield-and-flame identity for **Shakti: Personal Safety Network**. Indigo is the brand colour; rose stays reserved for emergency actions. The visual motif connects one central shield to three guardian nodes. It describes a support network, without claiming guaranteed protection.

Start with `preview.jpg` and `guides/shakti-brand-guide.pdf`.

| Folder | Deliverables |
|---|---|
| `logos/` | Outlined SVG, transparent PNG and vector PDF marks; horizontal/reversed/monochrome logos; stacked compositions |
| `icons/` | 1024 px master, 16–512 px exports, multi-size favicon |
| `store/` | 512 × 512 RGBA Play icon; 1024 × 500 RGB feature graphic |
| `social/` | 1200 × 630 share card; 1080 square, portrait and story graphics; 1600 × 400 banner |
| `presentation/` | 1920 × 1080 title and content templates in SVG, PNG and PDF |
| `print/` | A4 community poster, plus editable SVG and PNG |
| `illustrations/` | Transparent network-circle, walk and vault artwork |
| `wallpapers/` | Desktop and phone wallpapers |
| `guides/` | Five-page visual brand guide |
| `fonts/` | Poppins Bold and Nunito Regular/Bold, with their Open Font Licences |
| `tokens.json` | Machine-readable colours, typography and spacing rules |
| `tools/` | Reproducible artwork generator and validation tool |

## Editing and rebuilding

Edit copy, paths and placement in `tools/build_brand.py`, then run it from the repository with Python. Dependencies: `reportlab`, `Pillow`, `pypdfium2`, `pypdf`, `fonttools`. The generator uses the app's existing Poppins and Nunito TTF files. It can also discover the task-local fontTools installation under `tmp/pdfs/font-tools`; a normal installation works anywhere. No external API, network request, AI-generated bitmap, or remote font fetch is involved.

```powershell
python brand/tools/build_brand.py
# Also update the matching website and Android icon resources:
python brand/tools/build_brand.py --integrate
python brand/tools/validate_brand.py
```

For a fresh Python environment, install the tested dependencies with `python -m pip install -r brand/tools/requirements.txt` first.

SVG lettering is outlined for portability; the Python copy remains editable. PDF fonts are embedded. The three fonts used to rebuild the artwork are included with their original Open Font Licences. The wordmark uses Poppins Bold, body artwork uses Nunito; the website retains Bricolage Grotesque and Instrument Sans. The report's reference-matched fonts remain separate.

Use one quarter of the symbol width as clear space; display the symbol at 24 px or larger, and the horizontal logo at 144 px or larger. Use the simple icon for favicon sizes. Never stretch, skew, recolour with emergency rose, or place white artwork on a light background.

## Product integration

The same mark is used by the Flutter onboarding/lock painter, Android adaptive/legacy/themed icons, the website header and favicon, and the social share image. Android adaptive artwork is centred within the 66 dp safe circle on a 108 dp layer. The foreground and monochrome layers are separate resources.

`--integrate` refreshes exported website images and Android icon resources. The Flutter painter and website header also contain the master paths directly; keep those two source components in sync when changing the mark geometry.

The ZIP under `output/brand/` includes these deliverables and editable sources. It is a handover archive, excluded from Git; all required master/export files live here in version control.

## Store and launch use

Verified against official [Google Play graphic requirements](https://support.google.com/googleplay/android-developer/answer/9866151) and [Android adaptive-icon guidance](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive), 21 October 2026. Play icon: 512 px square, 32-bit PNG, under 1024 KB. Feature graphic: exactly 1024 × 500, RGB PNG with no alpha. Both are included.

The feature graphic is brand artwork. Actual app screenshots must be captured separately from a tested Android build before completing the Play listing; the kit does not fabricate device captures. Do not add a Google Play availability badge or a published-release claim until the listing is live. Closed testing, open testing and production remain subject to the account, signing, policy and device gates in `docs/play-alpha-release.md`.

No legal trademark clearance is implied. Team credit: **Lekhan, Manas, Vikat and Hemanth**, DBIT, VTU 1BCP308 Community Project. The supplied syllabus calls the applicable app category Topic 22; avoid repeating the older Topic 25 label in new assets.
