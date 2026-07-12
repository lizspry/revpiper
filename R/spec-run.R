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
        i = "Dictionary filenames resolve in {.file {spec_tables_dir(dir)}}."
      ),
      class = "revpiper_spec_error",
      call = NULL
    )
  }
  if (file == spec_joins_file) {
    path <- spec_joins_path(dir)
    stop_missing_file("Spec file", path)
    return(spec_set(joins = read_joins(path)))
  }
  dict <- read_dictionary(file.path(spec_tables_dir(dir), file))
  spec_set(tables = stats::setNames(list(dict), dict$table))
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
        i = "Set {.code joins = FALSE} to run a spec set without joins."
      ),
      class = "revpiper_spec_error",
      call = NULL
    )
  }
  spec_set(tables = tables, joins = read_joins(path, tables))
}

# The spec step's output: the one home for its shape.
spec_set <- function(
  tables = stats::setNames(list(), character(0)),
  joins = no_joins()
) {
  list(tables = tables, joins = joins)
}

# The spec folder layout: the one home for its paths.
spec_joins_file <- "joins.yaml"

spec_tables_dir <- function(dir) {
  file.path(dir, "tables")
}

spec_joins_path <- function(dir) {
  file.path(dir, spec_joins_file)
}
