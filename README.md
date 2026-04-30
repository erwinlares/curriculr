`title` is always the primary entry label — the degree name, job title,
project name, publication title, or skill area. `unit` is the secondary
line: employer, institution, publisher, or venue.

### Date conventions

| Situation | startMonth | startYear | endMonth | endYear |
|---|---|---|---|---|
| Ongoing role | Jan | 2018 | present | *(blank)* |
| Completed role | Mar | 2015 | Dec | 2022 |
| Single-year event | *(blank)* | 2021 | *(blank)* | *(blank)* |
| No date | *(blank)* | *(blank)* | *(blank)* | *(blank)* |

Leave cells blank rather than typing `NA`. The `readme` sheet in the
workbook has a full date quick-reference.

## Key functions

### `read_cv_data(path)`

Reads all sheets from the workbook into a named list of data frames. The
`profile` sheet is returned as a named character vector for convenient scalar
access.

```r
cv <- read_cv_data("data/cv-data-template.xlsx")

cv$experience          # a data frame
cv$profile[["email"]] # a scalar string
```

Sheets containing a `startYear` column are sorted in descending order
automatically — most recent entries appear first.

### `cv_render_section(data, title_col, ...)`

The main rendering function. Iterates over a CV data frame and writes each
row as a Typst entry block. Called inside a Quarto chunk with
`results = 'asis'`.

```r
#| results: asis
cat(.cv_section("Experience"))
cv_render_section(
  cv$experience,
  title_col  = "title",
  org_col    = "unit",
  detail_col = "detail",
  date_fun   = .cv_date_range
)
```

Optional arguments — `org_col`, `detail_col`, `date_fun`, `where_col` —
default to `NULL` and are simply omitted from the rendered output when not
supplied. Pass `date_fun = NULL` for undated sections like skills and
affiliations.

### `create_cv(path, filename, overwrite)`

Scaffolds a new CV project. Copies the template workbook, placeholder image,
and ready-to-render `CV.qmd` into the specified directory.

```r
create_cv(path = "~/my-cv")
create_cv(path = "~/my-cv", filename = "academic-cv.qmd", overwrite = TRUE)
```

## CV variants (roadmap)

The `CV.qmd` template includes YAML params for future variant support:

```yaml
params:
  resume: false
  years: 5
  npresentations: 10
```

These are not yet fully wired into the rendering logic but provide a place
to support things like a short resume, a rolling year window, or a limited
number of presentations. Filtering logic is planned for v0.2.0.

## Relationship to toolero and containr

curriculr is one of three sibling packages:

- [toolero](https://github.com/erwinlares/toolero) — a toolkit for research
  workflows: project initialization, Quarto document creation, data reading,
  and context detection.
- [containr](https://github.com/erwinlares/containr) — tools for
  containerizing R projects with Docker.
- **curriculr** — data-driven CV generation with Quarto and Typst.

## Known limitations

- Font rendering may differ slightly across operating systems depending on
  whether Lato is installed locally.
- Page breaks may need manual tuning for longer CVs.
- Icon-based contact fields are not currently supported.
- The Typst color palette and font size are not yet user-configurable without
  editing `CV.qmd` directly.

## License

MIT © Erwin Lares
