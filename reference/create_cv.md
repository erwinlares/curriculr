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

  A character string. Name of the output PDF file, without a directory
  component – the PDF is always written beside the workbook. Defaults to
  `"CV.pdf"`. Ignored in scaffold mode.

- overwrite:

  A logical. Whether to overwrite existing files. Defaults to `FALSE`.
  In scaffold mode, controls whether the template workbook and
  placeholder image are replaced if they already exist in the
  destination directory. Has no effect in render mode – the intermediate
  `CV.qmd` is written to a temporary directory and never touches the
  workbook folder.

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
mode**: it reads the workbook, generates an intermediate `CV.qmd` in a
temporary directory, renders it to PDF there using Quarto's Typst
engine, and copies only the finished PDF back beside the workbook.
Nothing else is written to the workbook folder.

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

4.  Writes an intermediate `CV.qmd` to a temporary directory by
    injecting all resolved values into the package template via sentinel
    substitution.

5.  Renders that file to PDF **inside the temporary directory**, then
    copies the finished PDF beside the workbook. The temporary directory
    and everything in it are removed when the call returns.

Rendering in a temporary directory rather than in the workbook folder is
a deliberate reproducibility choice. Quarto stages Typst packages into a
`.quarto/` cache in whichever directory it renders, and it walks up the
directory tree looking for a `_quarto.yml` to decide whether it is
inside a project. Rendering in the workbook folder therefore made the
output depend on where the workbook happened to live: a folder carrying
a stale package cache, or sitting beneath someone's unrelated Quarto
project, could render the same workbook differently. A fresh temporary
directory has neither, so every render starts from the same conditions.
It also means curriculr never creates or deletes files in a directory it
does not own.

Because the workbook and photo paths are injected into the template as
absolute paths, they resolve correctly from the temporary directory.

When `variant = "resume"`, row-level filtering is controlled entirely by
the `include_in_resume` column in each section sheet. Check the rows you
want included in the resume and leave the rest unchecked.

Theme values (fonts, colors, page layout) are read from the `theme`
sheet in the workbook. If the `theme` sheet is absent, built-in defaults
are used. Individual keys missing from a partial `theme` sheet are
filled from defaults.

## Examples

``` r
# \donttest{
# Scaffold mode — copy template files to a temp directory
withr::with_dir(tempdir(), create_cv())
#> ✔ Created /tmp/Rtmp297DFq/cv-data-template.xlsx
#> ✔ Created /tmp/Rtmp297DFq/placeholder.png
#> ℹ Next steps:
#> Open /tmp/Rtmp297DFq/cv-data-template.xlsx and fill in the "profile" sheet with
#> your information.
#> Replace /tmp/Rtmp297DFq/placeholder.png with your own profile photo.
#> Call `create_cv(data = 'cv-data-template.xlsx', photo = 'your-photo.png')` to
#> render your CV.
# }

if (FALSE) { # \dontrun{
# Render mode — requires cv-data.xlsx, Quarto, and Typst
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
