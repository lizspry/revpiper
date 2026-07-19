# Rendering and writing for the spec-step outcome: the per-file report
# text, the console/print lines (one source, so they never drift), and
# the per-run export. Nothing here is exported except the S3 methods.

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
    sprintf("revpiper spec report \u2014 %s", record$name),
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
          "  %s <-> %s \u2014 adds %s",
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
        "Columns: %d \u2014 %s",
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
# output/reports/, mirroring the spec folder's layout (battery decision,
# Liz 2026-07-19: dictionaries under tables/, full input filename kept —
# distinct inputs can never collide on one report path). Returns the
# folder and the per-record paths invisibly.
export_spec_reports <- function(outcome, dir = output_reports_dir) {
  run_dir <- file.path(dir, sprintf("%s-%s", outcome$stage, runstamp()))
  files <- vapply(
    outcome$files,
    \(record) {
      rel <- if (record$kind == "dictionary") {
        file.path(spec_tables_dirname, paste0(record$name, ".txt"))
      } else {
        paste0(record$name, ".txt")
      }
      path <- file.path(run_dir, rel)
      dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
      writeLines(format_file_report(record), path)
      path
    },
    character(1)
  )
  names(files) <- vapply(outcome$files, `[[`, character(1), "name")
  invisible(list(dir = run_dir, files = files))
}

# The console/print lines, from one source (design mocks, signed off
# 2026-07-19): the overall line first, one certification line per file
# with a pointer to the log of any file that failed, the reports-written
# line on success. The final acts (run's spec-set line, run's abort) are
# the callers' own.
report_lines <- function(outcome) {
  paths <- outcome$paths
  n <- length(outcome$files)
  ok <- vapply(outcome$files, `[[`, logical(1), "certified")
  overall <- if (outcome$certified) {
    c(
      sprintf("revpiper spec %s: SUCCESS", outcome$verb),
      sprintf(
        "all input files CERTIFIED (%d of %d files certified)",
        sum(ok),
        n
      )
    )
  } else {
    sprintf(
      "revpiper spec %s: NOT CERTIFIED (%d of %d files certified)",
      outcome$verb,
      sum(ok),
      n
    )
  }
  per_file <- vapply(
    outcome$files,
    \(record) {
      if (record$certified) {
        sprintf("%s \u2014 CERTIFIED", record$name)
      } else {
        n_err <- nrow(record$problems)
        sprintf(
          "%s \u2014 NOT CERTIFIED (%d error%s) \u2014 see %s",
          record$name,
          n_err,
          if (n_err == 1) "" else "s",
          paths$files[[record$name]]
        )
      }
    },
    character(1)
  )
  written <- if (outcome$certified) {
    sprintf("reports written to %s/", paths$dir)
  }
  list(overall = overall, per_file = per_file, ok = ok, written = written)
}

announce_spec <- function(outcome) {
  lines <- report_lines(outcome)
  cli::cli_text(lines$overall[[1]])
  for (extra in lines$overall[-1]) {
    cli::cli_alert_success(extra)
  }
  for (i in seq_along(lines$per_file)) {
    if (lines$ok[[i]]) {
      cli::cli_alert_success(lines$per_file[[i]])
    } else {
      cli::cli_alert_danger(lines$per_file[[i]])
    }
  }
  if (!is.null(lines$written)) {
    cli::cli_alert_success(lines$written)
  }
}

# print() repeats exactly what the call announced, glyphs included.
#' @export
format.rev_report <- function(x, ...) {
  lines <- report_lines(x)
  c(
    lines$overall[[1]],
    if (length(lines$overall) > 1) paste("\u2714", lines$overall[-1]),
    paste(ifelse(lines$ok, "\u2714", "\u2716"), lines$per_file),
    if (!is.null(lines$written)) paste("\u2714", lines$written)
  )
}

#' @export
print.rev_report <- function(x, ...) {
  writeLines(format(x))
  invisible(x)
}

# Where step reports live, relative to the project root: the one home
# for this layout fact.
output_reports_dir <- "output/reports"

# The runstamp format: the one home for report folder naming's time part.
runstamp <- function() {
  format(Sys.time(), "%Y%m%d-%H%M%S")
}
