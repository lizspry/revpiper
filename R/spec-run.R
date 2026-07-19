#' Run the spec step
#'
#' Performs, writes, and prints exactly what [rev_spec_audit()] does —
#' the same checks, the same per-file reports, the same console lines —
#' then, when every file certifies, returns the validated spec set
#' invisibly, ready for the next step. When any file does not certify,
#' it raises one error after all checking has completed: nothing is
#' returned, and no later pipeline step executes on an unsound spec.
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
#'   `"joins.yaml"`. A filename, never a path. Overrides `joins`.
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
