# Agent notes: Introduction to Geospatial Archaeology

| | |
|---|---|
| Public URL | https://teaching.wccarleton.org/intro_geospatial_archaeology/ |
| Course slug | `intro_geospatial_archaeology` |
| Cloudflare Pages project | `intro-geospatial-archaeology` (`intro-geospatial-archaeology.pages.dev`) |
| Build output | `docs/intro_geospatial_archaeology/` |

Created from `course_template` (2026-11-16). Lecture 1 is
`slides/01-geospatial-archaeology-and-gis.qmd`; its images are still placeholders
(`../assets/placeholders/image.svg`, alt text starting `PLACEHOLDER:`). When adding
a lecture, also add it to the navbar in `_quarto.yml` and the schedule in
`index.qmd`.

See README.md for authoring; SLIDE-ELEMENTS.md for slide components.

## How the teaching sites fit together

Every course is its own repository and its own Cloudflare Pages project. Students
reach all of them through one domain:

```
teaching.wccarleton.org/                 -> teaching_home repo (landing page + routing)
teaching.wccarleton.org/<slug>/...  --proxy-->  <project>.pages.dev/<slug>/...  (this repo)
```

- `teaching_home` (sibling folder `../teaching_home`) owns the custom domain. Its
  Pages Function `functions/_middleware.js` maps each course slug to the course's
  `*.pages.dev` address (`COURSES`) and passes requests through unchanged.
- This repo builds into `docs/<slug>/` (not `docs/`) so the course's own Pages
  project serves exactly the same paths as the public URL. That is what lets the
  proxy pass paths through without rewriting them.

## Build

- Use the shared `teaching` conda environment (`environment.yml`): Quarto is
  pinned to **1.9.37** there. The system Quarto on the Linux workstation
  (`/usr/local/bin/quarto`, 1.4.x) is older; do not use it for output that gets
  committed, because mixing versions silently changes the published HTML.

  ```bash
  conda activate teaching            # or: conda run -n teaching quarto render
  export QUARTO_PYTHON="$(which python)"   # only needed for decks with Python cells
  quarto render
  ```

- Without `QUARTO_PYTHON`, Quarto may pick a Jupyter kernel from an unrelated
  environment. Delete any stray `slides/*.ipynb` left behind by a failed render.
- Check the generator after rendering:
  `grep -o 'quarto-[0-9.]*' docs/<slug>/index.html | head -1` should say 1.9.37.

## Deploy

Deployment is "commit the built site, push to `main`":

1. `quarto render`
2. `git add -A` (this includes `docs/`) and commit.
3. `git push`. Cloudflare Pages deploys `main` automatically in about a minute.

Cloudflare Pages project settings (already configured; needed again only for a
new course):

| Setting | Value |
|---|---|
| Production branch | `main` |
| Framework preset | None |
| Build command | `exit 0` (nothing is built on Cloudflare) |
| Build output directory | `docs` |

Rules for `docs/`:

- `docs/` is committed on purpose. Never hand-edit files under `docs/<slug>/`;
  re-render instead.
- `docs/_redirects` and `docs/_headers` sit outside `docs/<slug>/`, so Quarto
  never deletes them. They only affect the `*.pages.dev` address: `/` redirects to
  the public course URL, and `X-Robots-Tag: noindex` keeps search engines off the
  pages.dev copy (the proxy strips that header for the public domain).
- Do not change `course-slug`, `output-dir`, or `site-url` in `_quarto.yml`
  without also updating `COURSES` and the course card in `teaching_home`; the
  course would disappear from `teaching.wccarleton.org`.

## Paths

- Use paths relative to the file (`../assets/branding/section_bg.png` from a deck
  in `slides/`). Never use root paths like `/assets/...`: the site lives under
  `/<slug>/`, so `/` points at the landing site, not this course.
- Absolute links to other courses or the landing page use the full
  `https://teaching.wccarleton.org/...` URL.

## Access control (Cloudflare Access)

The sites are deliberately behind a login, mainly because slides use third-party
figures under the teaching exception (only enrolled students may see them).

- One Zero Trust Access application ("Access controls -> Applications") protects
  `teaching.wccarleton.org`, `teaching-home.pages.dev`, and every course's
  `*.pages.dev` address. A new course's `*.pages.dev` hostname must be added to
  that application, or it is a way around the login.
- The landing proxy authenticates to the course `*.pages.dev` addresses with the
  service token `teaching-home-proxy` (env vars `ACCESS_CLIENT_ID` /
  `ACCESS_CLIENT_SECRET` on the teaching-home Pages project; admitted by a
  "Service Auth" policy on the application). If a course page shows "This course
  could not be loaded (teaching site configuration error)", the token is missing,
  expired, or no longer allowed by the policy.
- Do not re-enable the old account-level Bulk Redirect
  (`redirect-pagesdev-to-teaching` / list `lectures_pagesdev_to_teaching`). It
  redirects `lectures-urban-modelling.pages.dev` to the public domain, which
  makes the proxy loop.
- Verifying from a script: without a login, every address should return a 302 to
  `https://<team>.cloudflareaccess.com/cdn-cgi/access/login/...`. Content cannot be
  checked from outside; check the rendered files in `docs/<slug>/`, use
  `quarto preview`, or ask the user to look in a logged-in browser.

## Images

- Images that must stay behind the login (third-party figures) go in the repo
  under `assets/content/<lecture>/`, referenced with relative paths. They are
  served through the protected domain.
- The `teaching` R2 bucket (`https://teaching-assets.wccarleton.org/<slug>/`) is
  public to anyone with a link and is not covered by Access. Use it only for the
  user's own or openly licensed images: put them in the Git-ignored `images/`
  folder, run `scripts/sync-media.ps1` (optimises, then `rclone copy` to
  `r2-teaching:teaching/<slug>`; never deletes), and reference them as
  `![...](assets:<path-inside-images>)`. As of 2026-11-16 the bucket, its public
  domain, and the `r2-teaching` rclone remote have not been created yet; see the
  README before relying on them.
- Never commit `images/`, `media-originals/`, `tools/`, rclone config, or
  credentials.

## Adding a new course (from the template)

1. Create the repo from `course_template` (GitHub "Use this template"), then
   `./scripts/new-course.ps1 -Slug <slug> -Title "<Title>"` (slug: lowercase,
   digits, underscores; it becomes the URL path and the bucket folder).
2. Render, commit (including `docs/`), push.
3. Cloudflare: Workers & Pages -> Create -> Pages -> Import an existing Git
   repository; use the settings in the table above. Project name: the slug with
   hyphens.
4. Zero Trust -> Access controls -> Applications -> the teaching app ->
   Destinations: add `<project>.pages.dev` (use "Switch to custom input").
5. In `teaching_home`: add `<slug>: "https://<project>.pages.dev"` to `COURSES`
   in `functions/_middleware.js`, add a card to `index.qmd`, run
   `node tests/middleware.test.mjs`, render, commit, push.
