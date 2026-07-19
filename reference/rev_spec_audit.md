# Audit the spec step

Checks the project's spec set and reports — it never errors on spec
problems. Every table dictionary is validated standalone with problems
accumulated across all files, then the set-identity check runs over the
dictionaries that loaded, then the joins spec is validated against them.
All problems become report items; the report and its certificate are
always written under `output/reports/`, and one status line states the
outcome and the certificate's path. Data-free: it checks that sources
are declared, never that data files exist, so a spec set certifies
before any data is collected.

## Usage

``` r
rev_spec_audit(dir = "specs", joins = TRUE)
```

## Arguments

- dir:

  The spec folder: table dictionaries in `<dir>/tables/`, the joins spec
  at `<dir>/joins.yaml`.

- joins:

  Expect the joins spec? `TRUE` (the default) makes an absent
  `<dir>/joins.yaml` a standing item; `FALSE` audits without it.

## Value

The `rev_report`, returned visibly — it auto-prints as the certificate
when the call is not assigned. When certified, the loaded specs ride
along as the `"specs"` attribute.

## Examples

``` r
# the audit writes output/reports/ under the working directory, so
# this example runs in a throwaway one
specs_dir <- system.file("extdata", "specs-example", package = "revpiper")
owd <- setwd(tempdir())
report <- rev_spec_audit(dir = specs_dir)
#> ✔ Spec step CERTIFIED — certificate written to
#> output/reports/spec-20260719-042753-certificate.txt.
report
#> revpiper spec report
#> Status: CERTIFIED
#> Standing items: 0
#> Dictionary: estimates.yaml — table 'estimates'
#> Dictionary: rob.yaml — table 'rob'
#> Joins: included
list.files("output/reports")
#> [1] "spec-20260719-042753-certificate.txt"
#> [2] "spec-20260719-042753.xlsx"           
setwd(owd)
```
