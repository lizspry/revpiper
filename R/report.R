# Rendering and writing for the spec-step outcome: the per-file report
# text, the console/print lines (one source, so they never drift), and
# the per-run export. Nothing here is exported except the S3 methods.

# One plain-text report per input spec file (design 2026-07-19): status,
# then a summary of the file's own contents when certified, or its error
# table when not. The header says "report" — audit and run write the
# identical file (Liz, 2026-07-19).
format_file_report <- function(record, joins_excluded = FALSE) {
  status <- if (record$certified) {
    "Status: CERTIFIED"
  } else {
    sprintf("Status: NOT CERTIFIED (%s)", n_errors_label(nrow(record$problems)))
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
    },
    if (joins_excluded) c("", joins_excluded_line)
  )
}

# A certified file's summary: its own contents only — a dictionary's
# report never describes joins (Liz, 2026-07-19); joins.yaml gets the
# join lines.
# The pluralized error count: one home for both the report status line
# and the console per-file line.
n_errors_label <- function(n) {
  sprintf("%d error%s", n, if (n == 1) "" else "s")
}

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
  } else if (record$kind == "dictionary") {
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
  } else {
    cli::cli_abort(
      "Internal error: no summary renders a {.val {record$kind}} record."
    )
  }
}

# The error table as text: headers plain, every cell left-aligned,
# contents-width columns, NA shown empty. The file column is dropped —
# the report is per-file.
# The problem-display column set: one home, shared with the tests'
# projection helper.
problem_display_columns <- c(
  "entry",
  "code",
  "message",
  "suggestion",
  "related"
)

format_problem_table <- function(problems) {
  columns <- problem_display_columns
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
      writeLines(
        format_file_report(
          record,
          joins_excluded = isTRUE(outcome$joins_excluded)
        ),
        path
      )
      path
    },
    character(1)
  )
  names(files) <- vapply(outcome$files, `[[`, character(1), "name")
  invisible(list(dir = run_dir, files = files))
}

# The joins disposition, stated wherever the summary appears (Liz,
# 2026-07-19: an excluded joins spec must never read as certified; the
# phrase lives whole per conventions, hence the long line).
# nolint next: line_length_linter.
joins_excluded_line <- "joins excluded (joins = FALSE) and therefore not audited/run"

# The console/print lines, from one source (design mocks, signed off
# 2026-07-19): the overall line first, one certification line per file
# with a pointer to the log of any file that failed, the reports-written
# line on success. The final acts (run's spec-set line, run's abort) are
# the callers' own.
report_lines <- function(outcome) {
  paths <- outcome$paths
  n <- length(outcome$files)
  ok <- vapply(outcome$files, `[[`, logical(1), "certified")
  tag <- function(level, text) list(level = level, text = text)
  lines <- if (outcome$certified) {
    list(
      tag("plain", sprintf("revpiper spec %s: SUCCESS", outcome$verb)),
      tag(
        "success",
        sprintf(
          "all input files CERTIFIED (%d of %d files certified)",
          sum(ok),
          n
        )
      )
    )
  } else {
    list(tag(
      "plain",
      sprintf(
        "revpiper spec %s: NOT CERTIFIED (%d of %d files certified)",
        outcome$verb,
        sum(ok),
        n
      )
    ))
  }
  per_file <- lapply(seq_along(outcome$files), function(i) {
    record <- outcome$files[[i]]
    if (record$certified) {
      tag("success", sprintf("%s \u2014 CERTIFIED", record$name))
    } else {
      # path by index, never by name: two records may share a name
      # (review finding, 2026-07-19)
      tag(
        "danger",
        sprintf(
          "%s \u2014 NOT CERTIFIED (%s) \u2014 see %s",
          record$name,
          n_errors_label(nrow(record$problems)),
          paths$files[[i]]
        )
      )
    }
  })
  lines <- c(lines, per_file)
  if (outcome$certified) {
    lines <- c(
      lines,
      list(tag("success", sprintf("reports written to %s/", paths$dir)))
    )
  }
  if (isTRUE(outcome$joins_excluded)) {
    lines <- c(lines, list(tag("info", joins_excluded_line)))
  }
  lines
}

# One level -> (cli verb, glyph) map: the console and print() consume the
# same tagged lines, so they cannot drift. Every prebuilt line is
# interpolated as a VALUE ("{text}"), never as a cli template: filenames
# are user-controlled and may contain braces (review, 2026-07-19).
line_cli <- list(
  plain = cli::cli_text,
  success = cli::cli_alert_success,
  danger = cli::cli_alert_danger,
  info = cli::cli_alert_info
)
line_glyphs <- c(success = "\u2714", danger = "\u2716", info = "\u2139")

announce_spec <- function(outcome) {
  for (line in report_lines(outcome)) {
    text <- line$text # nolint: object_usage_linter. Consumed by cli's glue.
    line_cli[[line$level]]("{text}")
  }
}

# print() repeats exactly what the call announced, glyphs included.
#' @export
format.rev_report <- function(x, ...) {
  vapply(
    report_lines(x),
    function(line) {
      if (line$level == "plain") {
        line$text
      } else {
        paste(line_glyphs[[line$level]], line$text)
      }
    },
    character(1)
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

# The runstamp format: the one home for report folder naming's time
# part. Whole-second resolution is an accepted limitation (Liz,
# 2026-07-19, re-affirmed after review challenge): use is human-paced,
# and a same-second audit+run of the same spec set writes byte-identical
# reports.
runstamp <- function() {
  format(Sys.time(), "%Y%m%d-%H%M%S")
}
