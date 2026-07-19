#' Audit the spec step
#'
#' Checks every spec file and reports, per file — it never errors on
#' spec problems, and never returns a usable spec object. Every table
#' dictionary is checked standalone with problems accumulated across all
#' files, the across-dictionary identity check runs over the
#' dictionaries that loaded, and (with `joins = TRUE`) the joins spec is
#' checked against them. One plain-text report per input spec file is
#' written to a fresh run folder under `output/reports/` — a summary of
#' the file's contents when it certifies, its error log when it does not
#' — and the console states each file's certification with a pointer to
#' the log of any file that failed. Data-free: it checks that sources
#' are declared, never that data files exist, so a spec set certifies
#' before any data is collected.
#'
#' `rev_spec_run()` performs, writes, and prints exactly what this audit
#' does, then hands the validated spec set to the next step; the audit
#' is the check-only member of the pair.
#'
#' @section The related column:
#' The `related` column never guesses causes. It records one of two
#' checkable facts:
#'
#' * **Same entry:** this error sits in the same entry as at least one
#'   other error. Fixing that one entry and re-running may clear several
#'   errors at once.
#' * **Incomplete search:** this error says a name couldn't be found (a
#'   column, a table) — and the place that should have declared that
#'   name is itself broken (a column entry whose own name can't be read,
#'   or a spec file that failed its checks). The search was therefore
#'   run against an incomplete list. Fix the broken declaration first;
#'   this error may then disappear on its own.
#'
#' When `related` is empty, the error stands on its own as far as
#' revpiper can tell — most often a typo or a genuine omission, and the
#' `suggestion` column is the better guide.
#'
#' @param dir The spec folder: table dictionaries in `<dir>/tables/`, the
#'   joins spec at `<dir>/joins.yaml`.
#' @param joins Expect the joins spec? `TRUE` (the default) makes an
#'   absent `<dir>/joins.yaml` a standing error; `FALSE` audits without
#'   it.
#' @return Certification information only, invisibly (the same lines
#'   were just printed; `print()` the result to see them again): the
#'   per-file records (`$files`), the overall `$certified`, and the
#'   report paths (`$paths`). Never the spec set — `rev_spec_run()` is
#'   the function that hands the validated specs onward.
#' @examples
#' # the audit writes output/reports/ under the working directory, so
#' # this example runs in a throwaway one
#' specs_dir <- system.file("extdata", "specs-example", package = "revpiper")
#' owd <- setwd(tempdir())
#' rev_spec_audit(dir = specs_dir)
#' list.files("output/reports", recursive = TRUE)
#' setwd(owd)
#' @export
rev_spec_audit <- function(dir = "specs", joins = TRUE) {
  outcome <- spec_step(dir, joins, verb = "audit")
  outcome$specs <- NULL # never hands back a usable spec object
  invisible(outcome)
}
