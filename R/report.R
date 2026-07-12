# Stage report + certification machinery, generic over steps. Nothing here
# is exported: each step's audit constructs, prints, and writes its report.
# The spec stage's items are the problems tibble; the findings item schema
# arrives with the load step (Phase 2).

# A step's report: CERTIFIED exactly when zero items stand.
new_stage_report <- function(
  stage,
  items,
  acknowledgments = NULL,
  unspecified = character(0)
) {
  structure(
    list(
      stage = stage,
      items = items,
      acknowledgments = acknowledgments,
      unspecified = unspecified,
      status = if (nrow(items) == 0) "CERTIFIED" else "NOT CERTIFIED"
    ),
    class = "rev_report"
  )
}

# The certificate text: the one home for its wording. The printed
# certificate and the exported .txt are this same text.
#' @export
format.rev_report <- function(x, ...) {
  lines <- c(
    sprintf("revpiper %s report", x$stage),
    sprintf("Status: %s", x$status),
    sprintf("Standing items: %d", nrow(x$items))
  )
  if (length(x$unspecified) > 0) {
    lines <- c(
      lines,
      sprintf("Unspecified columns (annex): %s", toString(x$unspecified))
    )
  }
  lines
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
runstamp <- function(time = Sys.time()) {
  format(time, "%Y%m%d-%H%M%S")
}
