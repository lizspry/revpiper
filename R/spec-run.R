#' Run the spec step
#'
#' Reads and validates the project's spec set — every table dictionary
#' standalone, the across-dictionary identity check, and (with
#' `joins = TRUE`) the joins spec against the dictionaries — and returns
#' the validated spec objects. A run of an unsound spec cannot produce
#' output: any spec problem aborts with the complete problem list;
#' `rev_spec_audit()` turns the same problems into a report instead of an
#' error.
#'
#' @param dir The spec folder: table dictionaries in `<dir>/tables/`, the
#'   joins spec at `<dir>/joins.yaml`.
#' @param file A single spec filename to run standalone with within-file
#'   checks only: a dictionary filename resolved in `<dir>/tables/`, or
#'   `"joins.yaml"`. A filename, never a path. Overrides `joins`.
#' @param joins Include the joins spec? `TRUE` (the default) errors when
#'   `<dir>/joins.yaml` does not exist; `FALSE` skips it even when
#'   present.
#' @return A list with one entry per spec kind: `tables` (named list of
#'   `rev_dictionary` objects) and `joins` (the joins tibble; zero rows
#'   when skipped or not selected).
#' @examples
#' specs_dir <- system.file("extdata", "specs-example", package = "revpiper")
#' specs <- rev_spec_run(specs_dir)
#' names(specs$tables)
#' specs$joins
#'
#' # one dictionary standalone, within-file checks only
#' one <- rev_spec_run(specs_dir, file = "estimates.yaml")
#' names(one$tables)
#' @export
rev_spec_run <- function(dir = "specs", file = NULL, joins = TRUE) {
  rlang::check_string(dir)
  rlang::check_bool(joins)
  if (is.null(file)) {
    return(run_spec_set(dir, joins))
  }
  rlang::check_string(file)
  if (basename(file) != file) {
    cli::cli_abort(
      c(
        "{.arg file} must be a filename, not a path.",
        i = "Dictionary filenames resolve in {.file {spec_tables_dir(dir)}}.",
        spec_error_footer
      ),
      class = "revpiper_spec_error",
      call = NULL
    )
  }
  if (file == spec_joins_file) {
    path <- spec_joins_path(dir)
    stop_missing_path("Spec file", path)
    res <- read_joins(path)
    if (nrow(res$problems) > 0) {
      stop_spec(res$problems)
    }
    return(spec_set(joins = res$value))
  }
  path <- file.path(spec_tables_dir(dir), file)
  stop_missing_path("Spec file", path)
  res <- read_dictionary(path)
  if (nrow(res$problems) > 0) {
    stop_spec(res$problems)
  }
  spec_set(tables = name_by_table(list(res$value)))
}

run_spec_set <- function(dir, joins) {
  tables <- read_dictionaries(spec_tables_dir(dir))
  if (!joins) {
    return(spec_set(tables = tables))
  }
  path <- spec_joins_path(dir)
  if (!file.exists(path)) {
    cli::cli_abort(
      c(
        "{.arg joins} is TRUE but {.file {path}} does not exist.",
        i = "Set {.code joins = FALSE} to run a spec set without joins.",
        spec_error_footer
      ),
      class = "revpiper_spec_error",
      call = NULL
    )
  }
  res <- read_joins(path, tables)
  if (nrow(res$problems) > 0) {
    stop_spec(res$problems)
  }
  spec_set(tables = tables, joins = res$value)
}
