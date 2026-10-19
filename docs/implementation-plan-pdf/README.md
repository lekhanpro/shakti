# Shakti implementation plan

Eight A4 pages, including the cover. Prepared for VTU 1BCP308 Community Project, Topic 25, by Lekhan, Manas, Vikat and Hemanth. Document date: 17 October 2026.

## Edit and compile

Open `main.tex` in a LaTeX editor. All text, fonts and vector-diagram sources required by this document are included. Compile **from this source directory**, so the relative font and input paths resolve:

```text
tectonic main.tex --keep-logs
```

This produces `main.pdf`. The published copy is named `shakti_implementation_plan.pdf`. The verified authoring compiler is Tectonic 0.16.9; its first run may need internet access to obtain TeX packages. No shell escape, external diagram renderer or system font installation is required.

## Source layout

- `main.tex` assembles the cover and seven content pages, with explicit page breaks.
- `preamble.tex` defines the reference-matched typography, margins, palette, tables and callouts.
- `cover.tex` contains the cover composition and team credit.
- `pages/` contains the editable content, in page order.
- `diagrams/` contains four editable TikZ diagrams, rendered as vector artwork in the PDF.
- `fonts/` contains the required font files and their original licenses.
- `content-coverage.md` maps the original core features to their implementation and acceptance coverage.

Keep the body at 10 pt and tables at 9 pt when editing. If content spills beyond eight pages, edit the text or rebalance sections before changing the design. Recompile and review all pages after substantive edits.

## Font provenance and licenses

Google Sans is copied from the reference's bundled static files. Latin Modern uses its 7/8/9/10/12-point optical faces for the relevant body, table, heading and diagram sizes. The font licenses are included in `fonts/` and remain separate from the report's copyright.

The cover's title letterforms are Playfair Display Black Italic 1.004, the same outlines and advance widths as the reference. That old font file contains a reserved OS/2 embedding flag that Tectonic rejects despite its declared SIL Open Font License. The document includes an OFL-permitted metadata-corrected copy, renamed **Shakti Cover Serif** to respect the Reserved Font Name requirement. Only embedding/name metadata was changed; every glyph program and horizontal metric was compared with the original and found identical. The original author's copyright and license remain in the modified files, and `OFL-Playfair.txt` is included.

## Content basis and boundaries

The current Shakti design specification, implementation plan, hardware checklist, app/web manifests, service contracts and Supabase schema supply the content. The earlier Aegis master plan supplies the 60-day outline and team responsibilities where compatible. Performance figures are acceptance targets, not achieved measurements. Costs and provider policies were checked on 17 October 2026 and should be rechecked at deployment.

This deliverable documents the complete proposed build. It does not certify the current application or deploy any services.

Copyright 2026 Shakti project team. Third-party font and reference rights remain with their owners.
