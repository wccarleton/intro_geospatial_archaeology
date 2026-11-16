# Introduction to Geospatial Archaeology

Course website: lecture decks and a bibliography, built with Quarto.

- Public URL: `https://teaching.wccarleton.org/intro_geospatial_archaeology/`
- Course slug: `intro_geospatial_archaeology`
- Images: `https://teaching-assets.wccarleton.org/intro_geospatial_archaeology/`
- Cloudflare Pages project: `intro-geospatial-archaeology` (see "Publish a new course")

Created from the `course_template` repository.

## Layout

- `_quarto.yml`: course slug, title, navbar, and the image base URL.
- `index.qmd`: course home page (abstract, schedule, assignments).
- `slides/`: lecture decks; `slides/_metadata.yml` holds the shared Reveal settings.
- `assignments/`: assignment briefs and handouts (HTML pages).
- `references.bib`, `bibliography.qmd`: the course reading list.
- `mpg.scss`, `title-slide.html`, `assets/`: shared slide styling, fonts, and branding.
- `filters/`: image resolution (`assets:` prefix) and photo-card layout.
- `scripts/`: course setup, media upload, and offline export.
- `docs/`: the built site, **committed**; Cloudflare Pages serves it as is.
- [SLIDE-ELEMENTS.md](SLIDE-ELEMENTS.md): slide components and house style.

## Write lectures

Copy `slides/01-example.qmd` to a new file, e.g. `slides/02-topic.qmd`, and add it
to the navbar and the schedule. Decks inherit the author, theme, logo, footer,
and 1920 × 1080 layout from `slides/_metadata.yml`; a deck's front matter can
override any of these.

Use paths relative to the deck, such as `../assets/branding/section_bg.png`.
Avoid root paths like `/assets/...`: the site lives under `/<course-slug>/`, so
they would point outside the course.

```powershell
quarto preview                              # whole site
quarto preview slides/02-topic.qmd          # one deck
```

## Build environment

Build with the shared `teaching` conda environment, which pins Quarto (1.9.37)
and has Jupyter for decks with Python code cells and Pillow for images:

```bash
conda env create -f environment.yml    # once per computer
conda activate teaching
quarto render
```

All course sites use the same environment, so they build with the same Quarto.

## Images

Images are kept out of Git and served from the `teaching` R2 bucket, one folder
per course:

| | |
|---|---|
| Bucket | `teaching` (rclone remote `r2-teaching`) |
| This course's folder | `teaching/<course-slug>/` |
| Public URL | `https://teaching-assets.wccarleton.org/<course-slug>/...` |

Put images in the Git-ignored `images/` folder, organised however suits the
course (e.g. one subfolder per lecture), then upload:

```powershell
./scripts/sync-media.ps1
```

This optimises images (max 2000 px edge; large PNGs become WebP and the script
prints `RENAMED:` lines), archives the originals in the Git-ignored
`media-originals/`, and copies `images/` to `r2-teaching:teaching/<course-slug>`.
It never deletes anything in the bucket. `images/02-topic/map.webp` is then
available as:

```markdown
![Caption](assets:02-topic/map.webp){.img-card width=70% fig-align="center"}
```

`assets:` is resolved by `filters/assets.lua` against `assets-base` in
`_quarto.yml`. Full HTTPS image URLs and absolute local paths also work. To
preview before uploading, point the base at the local folder for a session:

```powershell
$env:TALKS_ASSETS_BASE = 'images'
quarto preview
Remove-Item Env:TALKS_ASSETS_BASE
```

(The variable keeps its `TALKS_` name so the filter stays identical to the
talks repository's copy.)

Images in the bucket are public to anyone with the link. Use your own figures,
openly licensed figures with attribution, or figures you discuss and cite.

### One-time media setup (per computer)

1. Create the `teaching` environment (see [Build environment](#build-environment));
   the script uses it for Pillow. Pass `-CondaEnvironment` to use another one.
2. Install rclone on `PATH`, or put `rclone.exe` in the Git-ignored `tools/rclone/`.
3. Create an R2 API token with **Object Read & Write** on the `teaching` bucket,
   then `rclone config` → new remote `r2-teaching`, type S3, provider Cloudflare,
   your account's S3 endpoint (without a bucket name), region `auto`. Keep the
   keys in rclone's own config, never in this repository.
4. Check: `rclone lsf r2-teaching:teaching --max-depth 1`.

The bucket needs a public custom domain, `teaching-assets.wccarleton.org`
(R2 → bucket → Settings → Custom Domains). This is done once, for all courses.

Tests (no uploads):

```powershell
conda run -n teaching python scripts/test_optimize_media.py
powershell -NoProfile -File scripts/test_sync_media.ps1
```

## Publish a new course

The course gets its own Cloudflare Pages project; `teaching_home` routes
`teaching.wccarleton.org/<course-slug>/` to it.

1. Cloudflare → Workers & Pages → Create → Pages → connect this GitHub repository.
   - Production branch: `main`
   - Build command: `exit 0`
   - Build output directory: `docs`
   - Name the project after the slug with hyphens, e.g. `intro-geospatial-archaeology`.
2. Note the project's address, e.g. `https://intro-geospatial-archaeology.pages.dev`.
   Visiting it redirects to the public course URL; the course itself is at
   `<address>/<course-slug>/`.
3. In `teaching_home`, add the slug and address to `COURSES` in
   `functions/_middleware.js` and a card to `index.qmd`; render, commit, push.

After that, every push to this repository's `main` updates the course.

The site is built into `docs/<course-slug>/` so that the course's Pages project
serves the same paths as the public URL. Quarto only replaces that folder;
`docs/_redirects` and `docs/_headers` (Pages settings for the `*.pages.dev`
address) stay put.

## Offline export

To present without internet, from Bash or WSL:

```bash
scripts/export-deck.sh slides/01-example.qmd
```

This writes a self-contained HTML deck and a PowerPoint file under the
Git-ignored `export/`, downloading hosted images into them.
