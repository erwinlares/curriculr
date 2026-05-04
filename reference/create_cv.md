# Generate a CV document from a curriculr workbook

Called with no arguments, `create_cv()` runs in **scaffold mode**: it
copies the template Excel workbook and placeholder profile image to the
current working directory and prints instructions for the next step. No
rendering takes place.

## Usage

``` r
create_cv(
  data = NULL,
  photo = NULL,
  output_file = "CV.pdf",
  overwrite = FALSE,
  variant = "cv",
  use_icons = "fontawesome"
)
```

## Arguments

- data:

  A character string or `NULL`. Path to the Excel workbook. Defaults to
  `NULL`, which triggers scaffold mode.

- photo:

  A character string or `NULL`. Path to the profile image. Defaults to
  `NULL`, which renders the CV without a profile photo using a
  single-column header layout. Supply a path to use a photo with the
  two-column header layout.

- output_file:

  A character string. Name of the output PDF file. Defaults to
  `"CV.pdf"`. Ignored in scaffold mode.

- overwrite:

  A logical. Whether to overwrite existing files. Defaults to `FALSE`.

- variant:

  A character string. Controls content scope. `"cv"` (the default)
  renders all rows from every section. `"resume"` renders only rows
  where `include_in_resume` is checked in the workbook.

- use_icons:

  A character string. `"fontawesome"` (the default) renders contact
  fields in the CV header with Font Awesome icons via the Typst
  `@preview/fontawesome` package. `"none"` renders plain text.

## Value

In scaffold mode, invisibly returns the path to the directory where
files were copied. In render mode, invisibly returns the path to the
rendered PDF.

## Details

Called with `data` and `photo` arguments, `create_cv()` runs in **render
mode**: it reads the workbook, generates `CV.qmd`, and renders it to PDF
using Quarto's Typst engine. Both `CV.qmd` and `CV.pdf` are written to
the same directory as the workbook.

**Scaffold mode** (no arguments):

1.  Copies `cv-data-template.xlsx` to
    [`getwd()`](https://rdrr.io/r/base/getwd.html).

2.  Copies `placeholder.png` to
    [`getwd()`](https://rdrr.io/r/base/getwd.html).

3.  Prints instructions for editing the workbook and rendering the CV.

**Render mode** (`data` supplied):

1.  Resolves and validates the workbook and photo paths.

2.  Reads the workbook with
    [`read_cv_data()`](https://erwinlares.github.io/curriculr/reference/read_cv_data.md),
    applying `variant` filtering.

3.  Resolves theme values from the workbook or built-in defaults.

4.  Writes `CV.qmd` by injecting all resolved values into the package
    template via sentinel substitution.

5.  Calls
    [`quarto::quarto_render()`](https://quarto-dev.github.io/quarto-r/reference/quarto_render.html)
    to produce the PDF.

When `photo = NULL`, the CV header renders as a single full-width column
containing the name, contact line, address, and profile statement. When
a photo path is supplied, the header uses a two-column layout with the
photo on the left.

When `variant = "resume"`, row-level filtering is controlled entirely by
the `include_in_resume` column in each section sheet. Check the rows you
want included in the resume and leave the rest unchecked.

Theme values (fonts, colors, page layout) are read from the `theme`
sheet in the workbook. If the `theme` sheet is absent, built-in defaults
are used. Individual keys missing from a partial `theme` sheet are
filled from defaults.

## Examples

``` r
if (FALSE) { # \dontrun{
# Scaffold mode — copy template files to current directory
create_cv()

# Render mode — full CV with photo and Font Awesome icons
create_cv(
  data  = "~/my_cv/cv-data.xlsx",
  photo = "~/my_cv/me.jpeg"
)

# Render mode — no photo, single-column header
create_cv(
  data = "~/my_cv/cv-data.xlsx"
)

# Render mode — resume variant
create_cv(
  data        = "~/my_cv/cv-data.xlsx",
  photo       = "~/my_cv/me.jpeg",
  variant     = "resume",
  output_file = "resume.pdf"
)

# Render mode — plain text contact line, custom output filename
create_cv(
  data        = "~/my_cv/cv-data.xlsx",
  photo       = "~/my_cv/me.jpeg",
  use_icons   = "none",
  output_file = "erwin-lares-cv.pdf"
)
} # }
```
