#' Run the spec step
#'
#' Performs and writes exactly what [rev_spec_audit()] does — the same
#' checks, the same per-file reports — and prints the same per-file
#' certification lines under its own banner. Then comes run's own final
#' act: when every file certifies, the validated spec set is returned
#' invisibly, ready for the next step; when any file does not certify,
#' one error is raised after all checking has completed — nothing is
#' returned, and no later pipeline step executes on an unsound spec.
#' (The audit equivalence describes the whole-folder run; `file =` is
#' run's own standalone mode, which audit does not have.)
#'
#' @section Spec layout:
#' A spec folder holds one dictionary per table in `<dir>/tables/`, and
#' the joins spec beside them at `<dir>/joins.yaml`. Correctly formatted
#' example files ship with the package — locate them with
#' `system.file("extdata", "specs-example", package = "revpiper")`.
#'
#' @inheritSection rev_spec_audit The related column
#' @param dir The spec folder: table dictionaries in `<dir>/tables/`, the
#'   joins spec at `<dir>/joins.yaml`.
#' @param file A single spec filename to run standalone with within-file
#'   checks only: a dictionary filename resolved in `<dir>/tables/`, or
#'   `"joins.yaml"` (which returns empty `$tables` beside the
#'   within-file-checked joins tibble). A filename, never a path — a
#'   path is rejected as a usage error. Overrides `joins`.
#' @param joins Include the joins spec? `TRUE` (the default) makes an
#'   absent `<dir>/joins.yaml` a standing error; `FALSE` runs without it.
#' @return The validated spec set, invisibly, on success: `$tables` (a
#'   named list of dictionaries) and `$joins` (the joins tibble; zero
#'   rows when skipped). Assign it to use it: `specs <- rev_spec_run()`.
#'   On failure, nothing is returned — the error halts the script, with
#'   the certification outcome riding on the condition as `$outcome`.
#' @examples
#' # run writes output/reports/ under the working directory, so this
#' # example runs in a throwaway one
#' specs_dir <- system.file("extdata", "specs-example", package = "revpiper")
#' owd <- setwd(tempdir())
#' specs <- rev_spec_run(specs_dir)
#' names(specs$tables)
#' specs$joins
#' setwd(owd)
#' @export
rev_spec_run <- function(dir = "specs", file = NULL, joins = TRUE) {
  outcome <- spec_step(dir, joins, file, verb = "run")
  if (!outcome$certified) {
    cli::cli_abort(
      "spec set not certified and not returned.",
      class = "revpiper_spec_error",
      call = NULL,
      outcome = outcome
    )
  }
  cli::cli_alert_success("spec set returned, ready for the load step")
  invisible(outcome$specs)
}
