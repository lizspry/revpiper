# Run the spec step

Reads and validates the project's spec set — every table dictionary
standalone, the across-dictionary identity check, and (with
`joins = TRUE`) the joins spec against the dictionaries — and returns
the validated spec objects. A run of an unsound spec cannot produce
output: any spec problem aborts with the complete problem list;
[`rev_spec_audit()`](https://lizspry.github.io/revpiper/reference/rev_spec_audit.md)
turns the same problems into a report instead of an error.

## Usage

``` r
rev_spec_run(dir = "specs", file = NULL, joins = TRUE)
```

## Arguments

- dir:

  The spec folder: table dictionaries in `<dir>/tables/`, the joins spec
  at `<dir>/joins.yaml`.

- file:

  A single spec filename to run standalone with within-file checks only:
  a dictionary filename resolved in `<dir>/tables/`, or `"joins.yaml"`.
  A filename, never a path. Overrides `joins`.

- joins:

  Include the joins spec? `TRUE` (the default) errors when
  `<dir>/joins.yaml` does not exist; `FALSE` skips it even when present.

## Value

A list with one entry per spec kind: `tables` (named list of
`rev_dictionary` objects) and `joins` (the joins tibble; zero rows when
skipped or not selected).

## Examples

``` r
specs_dir <- system.file("extdata", "specs-example", package = "revpiper")
specs <- rev_spec_run(specs_dir)
names(specs$tables)
#> [1] "estimates" "rob"      
specs$joins
#> # A tibble: 1 × 7
#>   adds      left      right keys_left keys_right relationship unmatched_ok
#>   <chr>     <chr>     <chr> <list>    <list>     <chr>        <lgl>       
#> 1 variables estimates rob   <chr [1]> <chr [1]>  one-to-many  FALSE       

# one dictionary standalone, within-file checks only
one <- rev_spec_run(specs_dir, file = "estimates.yaml")
names(one$tables)
#> [1] "estimates"
```
