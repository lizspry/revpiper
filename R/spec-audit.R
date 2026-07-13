#' Audit the spec step
#'
#' Checks the project's spec set and reports — it never errors on spec
#' problems. Every table dictionary is validated standalone with problems
#' accumulated across all files, then the set-identity check runs over the
#' dictionaries that loaded, then the joins spec is validated against
#' them. All problems become report items; the report and its certificate
#' are always written under `output/reports/`, and one status line states
#' the outcome and the certificate's path. Data-free: it checks that
#' sources are declared, never that data files exist, so a spec set
#' certifies before any data is collected.
#'
#' @param dir The spec folder: table dictionaries in `<dir>/tables/`, the
#'   joins spec at `<dir>/joins.yaml`.
#' @param joins Expect the joins spec? `TRUE` (the default) makes an
#'   absent `<dir>/joins.yaml` a standing item; `FALSE` audits without it.
#' @return The `rev_report`, returned visibly — it auto-prints as the
#'   certificate when the call is not assigned. When certified, the
#'   loaded specs ride along as the `"specs"` attribute.
#' @export
rev_spec_audit <- function(dir = "specs", joins = TRUE) {
  rlang::check_string(dir)
  rlang::check_bool(joins)
  tables_dir <- spec_tables_dir(dir)
  stop_missing_path("Dictionary directory", tables_dir, dir.exists(tables_dir))

  files <- sort(list.files(
    tables_dir,
    pattern = "\\.ya?ml$",
    full.names = TRUE
  ))
  audited <- lapply(files, \(f) audit_one(read_dictionary(f)))
  loaded <- !vapply(audited, \(a) is.null(a$value), logical(1))
  tables <- name_by_table(lapply(audited[loaded], \(a) a$value))
  joins_audit <- audit_joins(dir, joins, tables)

  items <- bind_problems(c(
    lapply(audited, \(a) a$problems),
    list(
      check_table_identity(names(tables), files[loaded]),
      joins_audit$problems
    )
  ))
  report <- new_stage_report(
    "spec",
    items,
    annex = c(
      sprintf(
        "Dictionary: %s — table '%s'",
        basename(files[loaded]),
        names(tables)
      ),
      sprintf("Joins: %s", joins_audit$disposition)
    )
  )
  if (is_certified(report)) {
    attr(report, "specs") <- list(tables = tables, joins = joins_audit$value)
  }
  announce_audit(report, export_report(report, output_reports_dir))
  report
}

# The always-once status line: outcome + where the certificate landed. A
# pointer, never a restatement of certificate content.
announce_audit <- function(report, paths) {
  if (is_certified(report)) {
    cli::cli_alert_success(
      "Spec step CERTIFIED — certificate written to
       {.file {paths[[\"certificate\"]]}}."
    )
  } else {
    cli::cli_alert_danger(
      "Spec step NOT CERTIFIED ({nrow(report$items)} standing problem{?s}) —
       report written to {.file {paths[[\"report\"]]}}."
    )
  }
}

# Run one spec-reading call for the audit: its value, or its problems.
audit_one <- function(expr) {
  tryCatch(
    list(value = expr, problems = no_problems()),
    revpiper_spec_error = \(e) list(value = NULL, problems = e$problems)
  )
}

# The joins side of the audit: what loaded (zero-row when not), the
# problems, and the disposition line the certificate always carries.
audit_joins <- function(dir, joins, tables) {
  if (!joins) {
    return(list(
      value = no_joins(),
      problems = no_problems(),
      disposition = "excluded (joins = FALSE)"
    ))
  }
  path <- spec_joins_path(dir)
  if (!file.exists(path)) {
    return(list(
      value = no_joins(),
      problems = flag_problem(
        path,
        "spec set",
        "YX04",
        path = path,
        hint = "set joins = FALSE to audit without a joins spec"
      ),
      disposition = "expected but absent"
    ))
  }
  audit <- audit_one(read_joins(path, tables))
  list(
    value = audit$value %||% no_joins(),
    problems = audit$problems,
    disposition = "included"
  )
}

# Where step reports and certificates live, relative to the project root:
# the one home for this layout fact (shared home when Phase 2 audits land).
output_reports_dir <- "output/reports"
