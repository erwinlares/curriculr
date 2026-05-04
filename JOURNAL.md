---
title: "curriculr Development Journal"
date: 2026-04-29
---

## Session 1 — 2026-04-29
### What we set out to do

The goal of this session was to take an existing personal project — a
data-driven CV built with Quarto and Typst — and turn it into a bonafide R
package called **curriculr**. The original project was a working but
self-contained workflow: it rendered my CV from an Excel workbook but was
tightly coupled to my personal data, my file paths, and my design choices.
The package version needed to generalize all of that so anyone could use it.

We also used this session to make explicit a set of design decisions that
had been implicit in the original code, and to establish conventions that
will carry through the rest of the package development.

---

### Background: what the original project looked like

The original workflow consisted of three files:

```text
CV.qmd
R/read-cv-data.R
R/typst-cv-functions.R
```

`CV.qmd` was the main Quarto document. It sourced the two R helper scripts,
read the Excel workbook, and emitted raw Typst blocks for each CV section.
The document rendered to PDF using Quarto's Typst engine — no LaTeX, no
`vitae`, no custom `.cls` files. That part was already a significant
improvement over the original R Markdown version.

The Excel workbook (`data_driven_cv_data.xlsx`) held CV content organized
across eleven sheets: `admin_services`, `affiliations`, `certifications`,
`education`, `experience`, `grants_and_awards`, `invited_teaching`,
`presentations`, `projects`, `publications`, and `skills`.

The R helper scripts provided:

- `read_cv_data()` — read all sheets into a named list of data frames
- A family of Typst-building functions: `typst_escape()`, `cv_value()`,
  `cv_date_range()`, `cv_year_range()`, `cv_section()`, `cv_entry()`,
  `emit_entries()`, and `emit_simple_entries()`

The code was well-written and well-documented, but it had two problems that
needed solving before it could become a package: it contained hardcoded
personal information, and it had a schema inconsistency across sheets that
made the rendering functions more complex than necessary.

---

### Decision: the package name

We confirmed the name **curriculr**. A search of CRAN and GitHub found no
existing package with that name. The name is a play on *curriculum vitae*
with the R community's convention of dropping trailing vowels.

Branding assets — a hex sticker and a favicon — were already created and
placed in `man/figures/`.

---

### Decision: package identity and dependencies

curriculr is a **standalone package**, not part of toolero. It will depend
on toolero at runtime for one specific purpose: `create_cv()` will delegate
to toolero's `create_qmd()` for the Quarto scaffolding step. That makes
toolero and curriculr siblings — curriculr reuses one primitive from toolero
without being conceptually merged with it.

The runtime dependencies are: `toolero`, `readxl`, `cli`, `fs`, `glue`,
`purrr`. Development tools (`devtools`, `usethis`, `roxygen2`, `testthat`)
are tracked by `renv` but do not appear in `DESCRIPTION`.

The license is **MIT**, matching toolero. Apache 2 (used by containr) was
considered but rejected — the patent protections it adds over MIT are not
meaningful for a CV-rendering package.

---

### Schema changes: normalizing the Excel workbook

The original workbook had three columns that used section-specific names for
what was conceptually the same thing — the primary entry label:

| Sheet | Old column name | New column name |
|---|---|---|
| `education` | `degree` | `title` |
| `projects` | `accomplishment` | `title` |
| `skills` | `area` | `title` |

The `skills` sheet also renamed `skills` → `unit` to match the secondary
text convention used everywhere else.

The motivation was that `cv_render_section()` — the successor to
`emit_entries()` — should be able to treat every sheet identically. Having
section-specific column names forced special-case handling in `CV.qmd` and
made the rendering functions harder to reason about. With `title` normalized
across all sheets, the caller simply passes `title_col = "title"` every
time.

The `affiliations` sheet had its single column renamed from `unit` to
`title` for the same reason.

---

### Schema addition: the `profile` sheet

The original `CV.qmd` had all personal information hardcoded directly in a
raw Typst block:

```typst
#text(size: 27pt)[Erwin Lares]
#text[3544 N Cedar Ridge Ct, Janesville, WI 53545]
#text[erwin.lares@wisc.edu · erwinlares.com]
```

This was the most important thing to fix. A package cannot ship with one
person's name and address baked into a template.

The solution was to add a `profile` sheet to the workbook as the single
source of truth for all personal information. The sheet uses a simple
two-column schema:

| field | value |
|---|---|
| `first_name` | |
| `last_name` | |
| `job_title` | |
| `address` | |
| `email` | |
| `website` | |
| `github` | |
| `linkedin` | |
| `profile_statement` | |
| `photo` | |

The dividing line between what belongs in the workbook and what belongs in
YAML is: everything that answers *who is this person* lives in the
spreadsheet; everything that answers *how should this render* (paper size,
margins, params) lives in the YAML front matter.

`read_cv_data()` handles the `profile` sheet specially — it converts the
two-column data frame into a named character vector so that template code
can write `cv$profile[["first_name"]]` rather than a clunky row-filter
expression.

---

### Schema addition: the `readme` sheet

A `readme` sheet was added to both workbooks — the personal workbook and the
Frank Palmer example workbook — to make the schema self-documenting. The
sheet explains:

- The general rules for data entry
- A column-by-column reference table
- A date entry quick-reference covering all combinations of ongoing,
  completed, point-in-time, and undated entries
- A profile sheet field guide

The sheet was generated programmatically using `openpyxl` in Python, with
UW red header rows, alternating row fills, wrapped text, and frozen top
rows. The top three rows (title, intro paragraph, spacer) are frozen so
they remain visible while scrolling through the reference tables.

---

### Decision: `emit_entries()` and `emit_simple_entries()` → `cv_render_section()`

The original code had two iterator functions:

- `emit_entries()` — for sections with dates, locations, and detail
- `emit_simple_entries()` — for sections without dates or locations

The distinction between them was false. A "simple" entry was just a regular
entry with fewer fields populated — not a different kind of thing. Having
two functions implied a meaningful difference that did not exist.

Both were collapsed into a single function: `cv_render_section()`. Optional
columns default to `NULL` and are simply omitted from the rendered output.
`date_fun` defaults to `.cv_date_range()` for dated sections and is passed
`NULL` for undated sections like skills and affiliations. The caller controls
simplicity through arguments, not through which function they call.

---

### Decision: separating building from printing

In the original code, `emit_entries()` both constructed the Typst strings
*and* called `cat()` to write them to the document. This made the functions
untestable in isolation — you could not check their output without capturing
stdout.

The package version separates these two responsibilities:

- `.build_section_blocks()` — internal builder, iterates over rows, returns
  a character vector of Typst blocks, one per row. Fully testable.
- `cv_render_section()` — thin public wrapper, calls `.build_section_blocks()`
  then passes the result to `cat()`. This is the function that lives inside
  a Quarto chunk with `results = 'asis'`.

The `results = 'asis'` chunk option tells Quarto to pass R output through
raw into the document without any formatting wrapper. `cat()` writes
directly to that output stream. The builder knows nothing about `cat()` —
it just returns strings.

---

### Decision: naming conventions

Two conventions were established and applied consistently across all source
files:

**Function names:** internal functions carry a `.` prefix. Exported
functions do not.

| Visibility | Example |
|---|---|
| Internal | `.cv_value()`, `.typst_escape()`, `.cv_date_range()` |
| Internal | `.cv_year_range()`, `.cv_section()`, `.cv_entry()` |
| Internal | `.build_section_blocks()` |
| Exported | `cv_render_section()`, `read_cv_data()` |

**File names:** source files use `kebab-case.R`. Function names inside
files use `snake_case`. This matches the convention already established in
toolero and containr.

---

### Decision: `sprintf()` over `glue::glue()` for Typst strings

The Typst layout strings contain many literal `{` and `}` characters, which
are glue's interpolation delimiters. Using glue would require escaping every
literal brace as `{{` and `}}`, making the strings harder to read and
maintain. `sprintf()` uses `%s` placeholders that do not conflict with
Typst syntax at all, so it was kept for the layout functions.

glue remains available for other parts of the package — particularly
`create_cv()` — where it is genuinely more readable.

---

### Decision: `create_cv()` architecture — Model A abandoned, self-contained instead

Two models were considered for how `create_cv()` should relate to
`create_qmd()` in toolero:

- **Model A:** `create_cv()` calls `create_qmd()` internally, passing a
  CV-specific template and YAML structure.
- **Model B:** extract a shared internal helper that both functions call.

Model A was initially chosen. However, when we examined toolero's actual
`create_qmd()` function signature:

```r
create_qmd(filename, path, yaml_data, overwrite, use_purl)
```

it became clear that `create_qmd()` does not accept a `template` argument
and always uses its own internal template. The delegation model was not
implementable without a toolero release. `create_cv()` was therefore written
as a self-contained function that handles all scaffolding steps directly —
workbook copy, placeholder image copy, and Quarto template copy — without
calling toolero at all. The toolero dependency was removed from `DESCRIPTION`.
Delegation can be revisited when toolero v0.4.0 adds a `template` argument
to `create_qmd()`.

---

### Source files written this session

Six R source files were written and loaded cleanly:

```text
R/curriculr-package.R    — package sentinel
R/typst-helpers.R        — %||%, .cv_value(), .typst_escape()
R/typst-dates.R          — .cv_date_range(), .cv_year_range()
R/typst-layout.R         — .cv_section(), .cv_entry()
R/typst-render.R         — cv_render_section(), .build_section_blocks()
R/read-cv-data.R         — read_cv_data()
R/create-cv.R            — create_cv()
```

---

### Package scaffold commands run

```r
usethis::create_package("~/path/to/curriculr")
usethis::use_mit_license()
usethis::use_readme_md()
usethis::use_news_md()
usethis::use_testthat()
usethis::use_git()
usethis::use_package("readxl")
usethis::use_package("cli")
usethis::use_package("fs")
fs::dir_create("inst/extdata/img")
fs::dir_create("inst/templates")
fs::dir_create("man/figures")
renv::init()       # explicit mode — DESCRIPTION-driven
renv::install("devtools")
renv::snapshot()
usethis::use_github_action("check-standard")
usethis::use_github()
```

---

## Session 2 — 2026-04-30

### What we set out to do

Session 2 picked up where Session 1 left off. The R source files were all
written and loading cleanly. The remaining work was: write the generalized
Quarto template, write the test suite, fix `R CMD check` issues, finalize
`DESCRIPTION`, `README.md`, and `NEWS.md`, and prepare the package for its
first GitHub push.

---

### `inst/templates/CV.qmd` — the generalized template

The original `CV.qmd` had three problems that needed solving before it could
be shipped as a package template:

1. Personal information hardcoded in a raw Typst block
2. Helper scripts loaded via `source()` rather than via a package
3. Column names from the old schema (`degree`, `accomplishment`, `area`)

The generalized template addresses all three.

**Personal information** now comes from `cv$profile`. The raw Typst header
block was converted into an R chunk with `results: asis`. The chunk reads
each profile field from the named character vector returned by
`read_cv_data()`, escapes every value with `.typst_escape()`, assembles the
contact line dynamically — omitting blank fields automatically — and writes
the Typst block via `sprintf()`. No personal data appears anywhere in the
template file itself.

**Helper scripts** are gone. The template now loads curriculr with
`library(curriculr)` and calls `read_cv_data()` directly. The two `source()`
calls from the original are replaced by one `library()` call.

**Column names** are updated throughout to reflect the normalized schema:
`title` everywhere, `institution` for the education organization line.
`emit_entries()` and `emit_simple_entries()` are replaced by
`cv_render_section()` in every section block.

The document style settings block — font, size, color palette — remains as
a raw `{=typst}` block. These are rendering concerns, not data concerns, and
belong in the template rather than in the workbook.

---

### Test suite — 74 tests, zero failures

Five test files were written covering all testable units:

```text
tests/testthat/test-typst-helpers.R   — %||%, .cv_value(), .typst_escape()
tests/testthat/test-typst-dates.R     — .cv_date_range(), .cv_year_range()
tests/testthat/test-typst-layout.R    — .cv_section(), .cv_entry()
tests/testthat/test-typst-render.R    — .build_section_blocks(), cv_render_section()
tests/testthat/test-read-cv-data.R    — read_cv_data()
```

The key testing insight was the builder/printer split established in Session
1. `.build_section_blocks()` returns a character vector and is fully testable
without capturing stdout. `cv_render_section()` is tested only for its
return value (`NULL` invisibly) — the output it writes to the stream is
covered indirectly through the builder tests.

`create_cv()` and `cv_render_section()`'s `cat()` side effect are not unit
tested. Both require filesystem scaffolding or stdout capture that belongs in
integration tests planned for a future session.

Final result: 74 tests passing, 0 failures, 0 warnings, 0 skips.

---

### `R CMD check` issues resolved

Running `devtools::check()` surfaced two errors and four notes:

**Error: internal functions not found in examples.** Functions with a `.`
prefix are not exported and therefore not available when `R CMD check` runs
examples. All `@examples` blocks were removed from internal function
documentation. Internal functions do not need runnable examples — the test
suite covers them instead.

**Error: stray markdown heading in `.cv_entry()` roxygen block.** A comment
line beginning with `#` inside the documentation was being interpreted by
roxygen2 as a level-1 heading, which is not supported in `@return`. The
orphaned example block that contained it was removed. All `@return` tags on
internal functions were simplified to plain one-line descriptions.

**Note: `setNames` has no visible global function definition.** Replaced the
`setNames()` call in `read_cv_data()` with explicit assignment:

```r
out <- vector("list", length(sheets))
names(out) <- sheets
```

**Note: `JOURNAL.md` at top level.** Added to `.Rbuildignore` with
`usethis::use_build_ignore("JOURNAL.md")`.

**Note: `NEWS.md` has no entries.** Added the v0.1.0 entry.

**Note: unable to verify current time.** Environment-level issue unrelated
to package code. Will not affect CRAN submission.

After fixes: 0 errors, 0 warnings, 1 note (timestamp verification — not
actionable).

---

### `DESCRIPTION` finalized

The `Description` field was expanded to acknowledge the two prior works that
inspired curriculr:

```dcf
Inspired by the vitae package (O'Hara-Wild et al., 2024,
<https://CRAN.R-project.org/package=vitae>) and the Awesome CV LaTeX
template (Park, 2015, <https://github.com/posquit0/Awesome-CV>).
```

The `RoxygenNote` field was updated from 7.3.2 to 7.3.3 to match the
installed version.

---

### `README.md` finalized

The README was restructured to match toolero's pattern: hex sticker logo
aligned right, badges, one-paragraph pitch, installation, requirements,
getting started (three numbered steps), functions, workbook schema, date
conventions, roadmap, related packages, known limitations, and license.

Key change from the first draft: the `cv_render_section()` example no longer
shows internal functions (`.cv_section()`, `.cv_date_range()`) directly.
Users interact with `CV.qmd` rather than calling these functions themselves,
so the README example shows only what a user would actually write.

The CRAN installation block was omitted — the package is not yet on CRAN and
a non-working install command is worse than no command at all.

An acknowledgements section was added crediting vitae and Awesome CV, and
the `DESCRIPTION` field was updated to include formal citations for both.

---

### GitHub Actions configured

`usethis::use_github_action("check-standard")` created the R-CMD-check
workflow at `.github/workflows/R-CMD-check.yaml`. The `.github/` directory
was added to `.Rbuildignore` automatically. The workflow will trigger on
every push and pull request once the GitHub remote is connected.

---

### Package structure at end of Session 2

```text
curriculr/
├── .github/
│   └── workflows/
│       └── R-CMD-check.yaml
├── .Rbuildignore
├── DESCRIPTION
├── JOURNAL.md
├── LICENSE
├── LICENSE.md
├── NAMESPACE
├── NEWS.md
├── PLAN.md
├── R/
│   ├── create-cv.R
│   ├── curriculr-package.R
│   ├── read-cv-data.R
│   ├── typst-dates.R
│   ├── typst-helpers.R
│   ├── typst-layout.R
│   └── typst-render.R
├── README.md
├── curriculr.Rproj
├── inst/
│   ├── extdata/
│   │   ├── cv-data-template.xlsx
│   │   ├── erwinlares-cv-data.xlsx
│   │   └── img/
│   │       └── placeholder.png
│   └── templates/
│       └── CV.qmd
├── man/
│   ├── create_cv.Rd
│   ├── curriculr-package.Rd
│   ├── cv_render_section.Rd
│   ├── dot-build_section_blocks.Rd
│   ├── dot-cv_date_range.Rd
│   ├── dot-cv_entry.Rd
│   ├── dot-cv_section.Rd
│   ├── dot-cv_value.Rd
│   ├── dot-cv_year_range.Rd
│   ├── dot-typst_escape.Rd
│   ├── figures/
│   │   ├── favicon.ico
│   │   └── hex-sticker.png
│   └── read_cv_data.Rd
├── renv/
│   ├── activate.R
│   └── settings.json
├── renv.lock
└── tests/
    ├── testthat/
    │   ├── test-read-cv-data.R
    │   ├── test-typst-dates.R
    │   ├── test-typst-helpers.R
    │   ├── test-typst-layout.R
    │   └── test-typst-render.R
    └── testthat.R
```

---

### What remains

- Push to GitHub and verify R-CMD-check Action passes
- Render `CV.qmd` using the Frank Palmer workbook to verify the full
  pipeline works end-to-end
- Create `inst/CITATION`
- CRAN submission prep (future milestone)

**v0.2.0 roadmap:**

- Add `template` argument to `toolero::create_qmd()` and restore delegation
  from `create_cv()`
- Filtering logic for CV variants (`resume: true`, `years`, `npresentations`)
- Section-level `include` flags in the workbook
- Integration tests for `create_cv()`
    - The tests we wrote this session are unit tests — they test individual
    functions in isolation. .build_section_blocks() takes a data frame and returns
    a character vector. .typst_escape() takes a string and returns a string. These
    are pure, self-contained, and easy to verify.
    create_cv() is different. It doesn't return a value you can inspect — it
    creates files and folders on disk.
- Testing it properly means:
    Creating a temporary directory
    Calling create_cv() on it
    Checking that the expected files and folders actually exist
    Checking that the workbook was copied correctly
    Checking that the placeholder image is in the right place
    Checking that CV.qmd was created with the right name
    Cleaning up afterward
    
## Session 3 -- 2026-04-30

### What we set out to do

Session 3 built v0.2.0 from the ground up. The core insight driving the
entire session was that v0.1.0 had two fundamental design problems: the user
had no control over what got rendered in their CV, and create_cv() was the
wrong kind of function. We fixed both.

---

### Decision: sections sheet drives rendering

In v0.1.0, the section structure of the CV was entirely hardcoded in
CV.qmd. Eleven section blocks in a fixed order, each with column arguments
hardcoded as strings. A user who wanted to remove a section, reorder sections,
or add a custom section had to edit CV.qmd directly -- which required knowing
Quarto and Typst and meant the package was doing less than it should.

The fix was to add a sections sheet to the workbook. Each row in the sheet
corresponds to one CV section. The columns encode every argument that
cv_render_section() needs: title_col, org_col, detail_col, date_fun, and
where_col. Row order is render order. Deleting a row excludes the section.
Adding a row for any sheet that follows the standard column schema renders
it automatically -- no R code changes required.

This design means the answer to "how do I add a new section?" is "add a row
to the sections sheet and create a matching workbook sheet." Nothing else.

---

### Decision: date_fun tokens

The sections sheet needed a way to encode the date_fun argument -- an R
function -- as a spreadsheet value. The solution was a small vocabulary of
string tokens:

| token | produces |
|---|---|
| date | full month/year range |
| year | year range only |
| month_year | single point in time |
| year_only | single year |
| none | no date |

A new exported function, resolve_date_fun(), maps these tokens to the
corresponding R functions. Unknown tokens produce a cli warning and fall
back to NULL rather than crashing. This makes the system forgiving of typos
while still giving clear feedback.

---

### Decision: create_cv() scaffold/render mode split

v0.1.0's create_cv() was a project scaffolding function -- it created
directories, copied files, and set up a folder structure. That's a one-time
operation and not what most users need most of the time.

The right mental model for a CV tool is a render function, not a scaffold
function. You run it repeatedly as you update your data. It takes your
workbook and produces a PDF.

The redesign gives create_cv() two modes triggered by whether data is NULL:

Scaffold mode (no arguments): copies the template workbook and placeholder
image to getwd() and prints instructions. Does not render. Designed for the
first-run experience -- a new user calls create_cv(), gets the files, edits
the workbook, and then calls create_cv() again in render mode.

Render mode (with data and photo): reads the workbook, validates the sections
sheet, writes CV.qmd by injecting resolved paths into the template, and calls
quarto::quarto_render() to produce the PDF. Both CV.qmd and CV.pdf land next
to the workbook.

---

### The sentinel substitution pattern

CV.qmd cannot have hardcoded paths because the workbook and photo live in
different places on different users' machines. The solution was to put two
placeholder strings in the template:

  __CURRICULR_DATA_PATH__
  __CURRICULR_PHOTO_PATH__

When create_cv() writes CV.qmd it calls gsub() to replace these sentinels
with the actual resolved paths. The photo path is computed relative to the
output directory using fs::path_rel() so that Quarto can find it when
rendering from that location.

---

### Exported functions: typst_escape(), cv_section(), resolve_date_fun()

v0.1.0 kept all layout functions internal with the dot prefix. That worked
for CV.qmd when it sourced R scripts directly, but when Quarto renders
CV.qmd it starts a fresh R session that can only see exported functions.
Calling .typst_escape() in a fresh session fails with "could not find function".

The fix was to export the three functions called directly in CV.qmd:
typst_escape(), cv_section(), and resolve_date_fun(). These are also
genuinely useful to anyone building a custom Quarto template, so exporting
them is honest rather than just a workaround.

.cv_entry() stays internal -- it is only ever called by .build_section_blocks()
inside the package.

---

### Bug: unexpected img/ folder creation

The first version of render mode copied the photo into an img/ subfolder of
the output directory. This was wrong -- the photo stays where the user put it.
The fix was to remove the copy entirely and instead compute the photo path
relative to the output directory using fs::path_rel(). The file is not moved
or copied; only the path written into CV.qmd changes.

---

### Bug: fresh R session cannot find curriculr

When Quarto renders CV.qmd it starts a fresh R session. That session calls
library(curriculr) and fails if the package is only loaded via
devtools::load_all() rather than properly installed. The fix for local
development is devtools::install() before testing. The fix for end users is
that they install the package properly via pak or install.packages().

The check run during R CMD check passes because the check environment
installs the package before running examples.

---

### R CMD check issues resolved

Non-ASCII em dash in cli messages. The em dash character used in two
"Skipping -- already exists" messages was flagged as non-ASCII by R CMD
check. Replaced with \u2014 Unicode escape.

CV.qmd and img/ in check directory. The check run of create_cv() leaves
CV.qmd, CV.pdf, and img/ in the check directory. Added CV.qmd, CV.pdf,
and img/ to .gitignore. The note is cosmetic and does not affect CRAN
submission.

---

### Files changed in v0.2.0

```
R/typst-helpers.R       -- typst_escape() and resolve_date_fun() exported
R/typst-layout.R        -- cv_section() exported
R/read-cv-data.R        -- sections validation, readme skip, sections no-sort
R/create-cv.R           -- full rewrite: scaffold/render mode split
inst/templates/CV.qmd   -- sections loop replaces hardcoded blocks, sentinels
```

---

### Package structure at end of Session 3

Same as Session 2 with these additions:

- sections sheet in both workbooks
- readme sheet updated to document sections schema
- .gitignore updated to exclude CV.qmd, CV.pdf, img/
- Version bumped to 0.2.0

---

### What remains for v0.3.0

- Integration tests for create_cv()
- inst/CITATION
- Frank Palmer workbook updated with sections sheet
- CV variant support (resume: true, years, npresentations)
- HTML output
- Theming support
- sections include column
- add support for awesomefont icons

## Session 4

## Session 4 -- 2026-04-30

### What we set out to do

Session 4 was a documentation and polish pass following the v0.2.0 code
work in Session 3. The goals were: restructure the README for new and
existing users, add a vignette, configure the favicon, add a CITATION file,
integrate the Zenodo DOI, set up Codecov coverage tracking, add a lifecycle
badge, and commit everything cleanly.

---

### README restructured

The v0.1.0 README described the package and workflow generically. The v0.2.0
README is addressed directly to two distinct audiences.

New users get a three-step onboarding path: call create_cv() with no
arguments to scaffold, fill in the workbook, call create_cv() again with
data and photo to render. The scaffold mode output and the step-by-step
instructions are shown verbatim so the user knows exactly what to expect.

Existing users migrating from v0.1.0 get a concise explanation of what
changed: create_cv() has two modes, the workbook needs a sections sheet,
and the date_fun token vocabulary is documented in a quick-reference table.

A customization section covers changing section order, colors, fonts, and
margins with concrete examples of what to edit and where.

---

### Vignette: Why curriculr

A new vignette was added at vignettes/curriculr-why.Rmd making the case
for the data-driven CV approach. The vignette is structured as an argument
rather than a tutorial: it identifies the problem (content and presentation
bundled together), explains the curriculr model, and positions curriculr
honestly against the closest prior art.

The comparisons cover Word/Pages, LaTeX CVs, vitae, and datadrivencv. The
vignette closes with the reproducibility argument: a curriculr CV is
reproducible in the same sense that an R analysis script is reproducible.

The vignette YAML uses a creation date hardcoded alongside a dynamic
last-updated date:

```yaml
date: "Created 2026-04-30 | Last updated `r Sys.Date()`"
```

There is no built-in mechanism to track document creation dates
automatically -- git creation timestamps reset on clone and are unreliable
in a CRAN build environment. Hardcoding the creation date once is the
pragmatic solution.

On the vignette engine: R Markdown was chosen over Quarto for the vignette
despite the package being Quarto-native. Quarto vignettes are supported as
of Quarto 1.4 but require Quarto in the check environment, which is not yet
universal on CRAN machines. R Markdown is the safer choice for now.

DESCRIPTION additions:

```dcf
Suggests:
    knitr,
    rmarkdown,
    ...
VignetteBuilder: knitr
```

---

### Favicon configured in pkgdown

The favicon was already in man/figures/favicon.ico from Session 1 but was
not wired into the pkgdown site. Added to _pkgdown.yml:

```yaml
template:
  bootstrap: 5
  favicon: man/figures/favicon.ico
```

---

### inst/CITATION added

A CITATION file was added to inst/ so that citation("curriculr") returns a
properly formatted citation. The file uses meta$Version to pull the installed
version number automatically from DESCRIPTION, and format(Sys.Date(), "%Y")
for the year.

The initial attempt produced a ???? year and a warning:

```
could not determine year for 'curriculr' from package DESCRIPTION file
```

The fix was to add a Date field to DESCRIPTION:

```dcf
Date: 2026-04-30
```

A typo in the filename (inst/CITATTION with double T) was caught during the
git status review before committing and corrected with mv.

---

### Zenodo DOI integrated

A Zenodo DOI was obtained for the package: 10.5281/zenodo.19930400

It was integrated in three places:

CITATION -- doi field in bibentry and URL in textVersion
DESCRIPTION -- added to the URL field alongside the GitHub and pkgdown URLs
README -- DOI badge added as the first badge in the badges block

The DOI badge uses the standard Zenodo badge format matching the pattern
already used in toolero's README.

---

### Codecov coverage tracking

usethis::use_coverage() added:
- codecov.yml configuration file
- Codecov badge to README
- .Rbuildignore entry

usethis::use_github_action("test-coverage") added:
- .github/workflows/test-coverage.yaml

The CODECOV_TOKEN was retrieved from app.codecov.io and added as a GitHub
repository secret. Codecov does not list R as a language option in its
setup wizard -- the wizard was ignored entirely since the GitHub Actions
workflow generated by usethis handles everything correctly.

---

### Lifecycle badge

usethis::use_lifecycle() added the four lifecycle SVGs to man/figures/:
- lifecycle-experimental.svg
- lifecycle-stable.svg
- lifecycle-deprecated.svg
- lifecycle-superseded.svg

The experimental badge was added to README.md using the shields.io URL
rather than the local SVG, which is the correct approach for the README.
The local SVGs are used when lifecycle::badge() is called inside roxygen
documentation blocks -- that step is deferred to v0.3.0 when we add
lifecycle badges to individual exported function docs.

---

### v0.3.0 roadmap additions

Font Awesome icon support was added to the roadmap. The plan is to use
Typst's @preview/fontawesome package to replace plain text contact labels
with icons for email, website, GitHub, and LinkedIn in the CV header.

Full v0.3.0 priority list:
1. Update Frank Palmer workbook with sections sheet
2. Integration tests for create_cv()
3. CV variant support (resume, years, npresentations params)
4. Font Awesome icon support in the contact line
5. Theming support
6. HTML output
7. add_section() convenience function
>>This is a good place to pick up. Before drafting, let me make sure I understand the intended behavior clearly.
add_section() would take an existing cv-data.xlsx workbook and add a new sheet to it with the correct column headers pre-populated — the standard section spine:
title | unit | startMonth | startYear | endMonth | endYear | where | detail
And it would also add a corresponding row to the sections sheet so the new section is registered for rendering.
A few questions before drafting:
What does the user pass in? At minimum the workbook path and a name for the new section. Anything else — a label for the sections sheet, a date_fun token, column overrides?
Should it open the workbook after adding the section? Some users might want to immediately start filling it in.
What happens if the section already exists? Error, warning, or skip silently?
Does it write back to the same file or produce a new one? Writing back to the same file is the natural behavior but worth confirming since it is a destructive operation.
What package would handle the Excel read/write? curriculr already uses readxl for reading — for writing back you would need openxlsx or writexl. Do you have a preference?

8. sections sheet include boolean column

---

### Deployment

All changes deployed to GitHub without errors. Three Actions ran
successfully on push:
- R-CMD-check: clean (0 errors, 0 warnings, 1 irrelevant note)
- pkgdown: site rebuilt and deployed
- test-coverage: coverage uploaded to Codecov, badge activated

---

### Package structure at end of Session 4

New files added since Session 3:

```text
.github/workflows/test-coverage.yaml
codecov.yml
inst/CITATION
man/figures/lifecycle-deprecated.svg
man/figures/lifecycle-experimental.svg
man/figures/lifecycle-stable.svg
man/figures/lifecycle-superseded.svg
vignettes/
+-- curriculr-why.Rmd
```

Fields added to DESCRIPTION:

```dcf
Date: 2026-04-30
VignetteBuilder: knitr
```

Active badges:
- DOI (Zenodo)
- R-CMD-check (GitHub Actions)
- CRAN status (not yet on CRAN -- badge pending)
- Lifecycle: experimental
- Codecov test coverage
