## R CMD check results

0 errors | 0 warnings | 2 notes

## Notes

**New submission** — this is a new submission to CRAN.

**Non-standard file at top level** — `cran-comments.md` has been added to
`.Rbuildignore` and will not appear in the package tarball.

## Resubmission

This is a resubmission addressing notes from the initial automated check:

- `cran-comments.md` added to `.Rbuildignore` to remove it from the tarball.
- `Description` field rewritten to wrap software names (`Typst`, `Quarto`,
  `vitae`, `Awesome CV`) in single quotes per CRAN convention, removing
  author name citations and rephrasing to eliminate flagged words.

## Test environments

- Local: macOS aarch64, R 4.5.0
- R-hub: Linux, macOS, Windows (all passing)
- win-builder: R-devel (2 expected notes: new submission, HTML Tidy version)

## Reverse dependencies

None. This is a new submission.
