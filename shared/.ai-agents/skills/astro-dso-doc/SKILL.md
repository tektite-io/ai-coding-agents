---
name: astro-dso-doc
description: >
  Generates a complete, polished HTML documentation page for a deep-sky object (DSO) 
  astrophotography project. Use this skill whenever the user mentions astrophotography, 
  a DSO name (NGC, IC, Messier, Sharpless, etc.), wants to document an imaging session, 
  mentions PixInsight project documentation, wants to create an observation report, or 
  asks to generate a page/document for a nebula, galaxy, cluster, or other deep-sky target. 
  Triggers on phrases like "create doc for NGC XXXX", "generate DSO page", 
  "document my session on", "make a PixInsight doc for", "astro documentation page".
  Always use this skill — not a generic HTML generator — when the subject is a deep-sky object.
---

# Astro DSO Documentation Generator

Generates a rich, self-contained HTML documentation page for a deep-sky object (DSO) astrophotography project, using the Catppuccin flavor palette system with a theme switcher.

## Workflow

### Step 1 — Identify the Target

Extract the DSO name/catalog number from the user's message. If ambiguous or missing, ask for it before proceeding.

Common catalog prefixes: NGC, IC, M (Messier), Sh2 (Sharpless), B (Barnard), vdB, LBN, LDN, Ced, RCW.

---

### Step 2 — Collect Acquisition Data (interactive)

Ask the user the following questions **one block at a time** (don't dump all at once). Wait for answers before proceeding.

**Block A — Instrument:**

```
What instrument did you use?
  (e.g. telescope model, focal length, f-ratio, camera, built-in filter)
```

**Block B — Site:**

```
Where did you image from?
  (location name, lat/lon if known, approximate altitude)
```

**Block C — Session files:**

```
Please provide the path to the folder or list of session files.
  (e.g. /path/to/sessions/ or paste filenames directly)
```

If the user gives a **directory path**, scan it:

```bash
ls -1 /path/to/sessions/
```

Filter for image files: `.tiff`, `.tif`, `.fit`, `.fits`, `.xisf`, `.cr2`, `.nef`, `.jpg`.
Sort chronologically. Present the list for confirmation.

If the user **pastes filenames**, accept them directly.

**Block D — Optional extras** (ask once, accept "skip" gracefully):

```
Any additional notes? (sky conditions, Bortle class, total integration time, etc.)
```

---

### Step 3 — Research the DSO

Use `web_search` to gather comprehensive data. Run **at least 3 searches** in parallel or sequence:

1. `{DSO name} {common name} astronomical data distance magnitude type constellation`
2. `{DSO name} star forming region physical properties HII nebula galaxy cluster`
3. `{DSO name} NASA Hubble ESA observations history discovery`
4. (if nebula) `{DSO name} astrophotography imaging narrowband dual-band filter tips`

Collect:

- Coordinates (RA / Dec J2000)
- Distance (ly and parsecs)
- Apparent size (arcmin)
- Visual magnitude
- Physical diameter
- Object type (HII region, reflection nebula, galaxy, globular cluster, etc.)
- Discovery history (who, when, instrument)
- Physical structure and processes
- Notable stars or ionizing sources
- Observation/imaging notes
- Key references (NASA, ESA, SIMBAD, catalogues)
- All catalog designations (NGC, IC, Sh2, LBN, etc.)

---

### Step 4 — Generate the HTML Page

Read the full HTML template from `references/template.html`.

Fill in all the template placeholders using:

- Research data (Step 3)
- Acquisition data (Step 2)
- Session file list (Step 2C)

Save the output to `/mnt/user-data/outputs/{DSO_ID}_documentation.html`

Then call `present_files` to deliver it to the user.

---

## Template Placeholders Reference

See `references/template.html` for the full annotated template.

Key placeholders:

- `{{DSO_ID}}` — e.g. `NGC2174`
- `{{COMMON_NAME}}` — e.g. `Monkey Head Nebula`
- `{{RA}}`, `{{DEC}}` — J2000 coordinates
- `{{DISTANCE_LY}}`, `{{DISTANCE_PC}}` — with uncertainty range if known
- `{{APPARENT_SIZE}}` — e.g. `40′ × 30′`
- `{{MAGNITUDE}}` — visual magnitude
- `{{PHYSICAL_DIAMETER}}` — e.g. `~75 ly`
- `{{OBJECT_TYPE}}` — e.g. `H II Region`
- `{{CONSTELLATION}}` — full name
- `{{CATALOG_ROWS}}` — `<tr>` rows for the catalog table
- `{{SCIENTIFIC_DESCRIPTION}}` — 3–5 `<p>` paragraphs
- `{{KEY_STAR_BLOCK}}` — filled if a dominant ionizing/notable star exists, else empty
- `{{TIMELINE_ITEMS}}` — `<div class="timeline-item">` blocks for history
- `{{PHYSICAL_STRUCTURE}}` — 3–4 `<p>` paragraphs
- `{{OBSERVATION_TIPS}}` — `<div class="tip-card">` blocks
- `{{INSTRUMENT}}`, `{{FILTER}}`, `{{SITE}}`, `{{SITE_COORDS}}` — acquisition fields
- `{{SESSION_COUNT}}` — integer
- `{{SESSION_FILES}}` — `<span class="session-file">filename</span>` per file
- `{{REFERENCES_ROWS}}` — `<tr>` rows for references table
- `{{GENERATED_DATE}}` — today's date `YYYY-MM-DD`
- `{{AUTHOR_NOTES}}` — optional free-text notes block (omit section if empty)

---

## Quality Standards

- **All 4 Catppuccin flavors** must be wired up: Latte, Frappé, Macchiato (default), Mocha
- Theme preference persists via `localStorage`
- Page must be **fully self-contained** — single HTML file, no external dependencies except Google Fonts
- Sections with no data should be **omitted gracefully** (e.g. no key star block if data unavailable)
- Session files should be presented in **chronological order**
- All scientific content must come from actual web searches — never fabricate measurements
- Cite uncertainty ranges when distance estimates vary significantly between sources

---

## Edge Cases

| Situation                          | Handling                                                      |
| ---------------------------------- | ------------------------------------------------------------- |
| DSO not well-documented            | Note gaps explicitly; still generate page with available data |
| Directory path given but empty     | Ask user to paste filenames manually                          |
| No session files provided          | Omit Section 08, note in footer                               |
| Galaxy / cluster instead of nebula | Skip narrowband tip cards; adapt physical description section |
| User skips optional questions      | Generate page with "—" placeholders, easy to fill later       |
| File extensions unexpected         | Accept `.png`, `.jpeg`, `.dng`, `.raf` as well                |
