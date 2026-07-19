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

# One plain-text report per input spec file (design 2026-07-19): status,
# then a summary of the file's own contents when certified, or its error
# table when not. The header says "report" — audit and run write the
# identical file (Liz, 2026-07-19).
format_file_report <- function(record) {
  n <- nrow(record$problems)
  status <- if (record$certified) {
    "Status: CERTIFIED"
  } else {
    sprintf("Status: NOT CERTIFIED (%d error%s)", n, if (n == 1) "" else "s")
  }
  c(
    sprintf("revpiper spec report — %s", record$name),
    status,
    "",
    if (record$certified) c(format_summary(record), ""),
    if (record$certified) {
      "Errors: none."
    } else {
      c("Errors:", format_problem_table(record$problems))
    }
  )
}

# A certified file's summary: its own contents only — a dictionary's
# report never describes joins (Liz, 2026-07-19); joins.yaml gets the
# join lines.
format_summary <- function(record) {
  if (record$kind == "joins") {
    joins <- record$value
    c(
      sprintf("Joins: %d", nrow(joins)),
      if (nrow(joins) > 0) {
        sprintf(
          "  %s <-> %s — adds %s",
          joins$left,
          joins$right,
          joins$adds
        )
      }
    )
  } else {
    d <- record$value
    levels <- names(d$levels)
    c(
      sprintf("Table:   %s", d$table),
      sprintf("Source:  %s", d$source$file),
      sprintf(
        "Columns: %d — %s",
        nrow(d$columns),
        paste(d$columns$name, collapse = ", ")
      ),
      sprintf(
        "Levels:  %s",
        if (length(levels) == 0) "none" else paste(levels, collapse = ", ")
      )
    )
  }
}

# The error table as text: headers plain, every cell left-aligned,
# contents-width columns, NA shown empty. The file column is dropped —
# the report is per-file.
format_problem_table <- function(problems) {
  columns <- c("entry", "code", "message", "suggestion", "related")
  cells <- vapply(
    columns,
    \(column) {
      values <- as.character(problems[[column]])
      values[is.na(values)] <- ""
      formatC(
        c(column, values),
        width = max(nchar(c(column, values))),
        flag = "-"
      )
    },
    character(nrow(problems) + 1)
  )
  trimws(apply(cells, 1, paste, collapse = "   "), which = "right")
}

# Write one report per record into a fresh runstamped folder under
# output/reports/. Returns the folder and the per-record paths invisibly.
export_spec_reports <- function(outcome, dir = output_reports_dir) {
  run_dir <- file.path(dir, sprintf("%s-%s", outcome$stage, runstamp()))
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)
  files <- vapply(
    outcome$files,
    \(record) {
      path <- file.path(run_dir, sub("\\.ya?ml$", ".txt", record$name))
      writeLines(format_file_report(record), path)
      path
    },
    character(1)
  )
  names(files) <- vapply(outcome$files, `[[`, character(1), "name")
  invisible(list(dir = run_dir, files = files))
}

# Where step reports and certificates live, relative to the project root:
# the one home for this layout fact.
output_reports_dir <- "output/reports"

# Write the report workbook and its certificate beside it, named by stage
# and runstamp. Returns both paths invisibly.
export_report <- function(report, dir = output_reports_dir) {
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
