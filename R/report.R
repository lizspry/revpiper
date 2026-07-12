# Stage report + certification machinery, generic over steps. Nothing here
# is exported: each step's audit constructs, prints, and writes its report.
# The spec stage's items are the problems tibble; the findings item schema
# and acknowledgment cancellation arrive with the load step (Phase 2).

# A step's report. `annex` is pre-rendered certificate lines the step's
# audit supplies (e.g. the joins disposition); the formatter appends them
# verbatim and knows nothing about any stage.
new_stage_report <- function(stage, items, annex = character(0)) {
  structure(
    list(stage = stage, items = items, annex = annex),
    class = "rev_report"
  )
}

# The certification rule, in one place: zero items stand.
is_certified <- function(report) {
  nrow(report$items) == 0
}

# The certificate text: the one home for its wording. The printed
# certificate and the exported .txt are this same text.
#' @export
format.rev_report <- function(x, ...) {
  c(
    sprintf("revpiper %s report", x$stage),
    sprintf(
      "Status: %s",
      if (is_certified(x)) "CERTIFIED" else "NOT CERTIFIED"
    ),
    sprintf("Standing items: %d", nrow(x$items)),
    x$annex
  )
}

#' @export
print.rev_report <- function(x, ...) {
  writeLines(format(x))
  invisible(x)
}

# Write the report workbook and its certificate beside it, named by stage
# and runstamp. Returns both paths invisibly.
export_report <- function(report, dir) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  stem <- sprintf("%s-%s", report$stage, runstamp())
  paths <- c(
    report = file.path(dir, sprintf("%s.xlsx", stem)),
    certificate = file.path(dir, sprintf("%s-certificate.txt", stem))
  )
  writexl::write_xlsx(list(items = report$items), paths[["report"]])
  writeLines(format(report), paths[["certificate"]])
  invisible(paths)
}

# The runstamp format: the one home for report file naming's time part.
runstamp <- function() {
  format(Sys.time(), "%Y%m%d-%H%M%S")
}
