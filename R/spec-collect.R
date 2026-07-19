# The spec step's one checking core: audit and run both call exactly
# this. Assembles per-file records from the pure readers — problems are
# data end-to-end, so there is no tryCatch anywhere. Step-scope facts
# (folder layout, the spec-set shape, the set-identity check) live here.

collect_spec_step <- function(dir, joins = TRUE, file = NULL) {
  if (!is.null(file)) {
    return(collect_one(dir, file))
  }
  files <- dictionary_files(spec_tables_dir(dir))
  read <- lapply(files, read_dictionary)
  loaded <- !vapply(read, \(r) is.null(r$value), logical(1))
  tables <- name_by_table(lapply(read[loaded], `[[`, "value"))
  intended <- intended_tables(files[!loaded])
  failed_tables <- split(basename(intended$files), intended$tables)
  # Identity polices every DECLARED table name — loaded, or readable
  # from a failed file's raw table: field — so two broken files claiming
  # one table are visible too (Liz, 2026-07-19, battery follow-up).
  identity <- check_table_identity(
    c(names(tables), intended$tables),
    c(files[loaded], intended$files)
  )
  records <- lapply(seq_along(files), \(i) {
    hit <- vapply(
      identity$involved,
      \(involved) basename(files[[i]]) %in% involved,
      logical(1)
    )
    own <- rbind(read[[i]]$problems, identity$problems[hit, ])
    new_record(basename(files[[i]]), "dictionary", own, read[[i]]$value)
  })
  if (length(files) == 0) {
    # Zero dictionaries never certifies vacuously (battery decision,
    # Liz 2026-07-19): a spec set that describes nothing is a standing
    # problem, parallel to an expected-but-absent joins.yaml.
    problems <- flag_problem(
      spec_tables_dir(dir),
      "spec set",
      "YX04",
      path = spec_tables_dir(dir)
    )
    records <- c(
      list(new_record(spec_tables_dirname, "set", problems, NULL)),
      records
    )
  }
  if (joins) {
    records <- c(records, list(collect_joins(dir, tables, failed_tables)))
  }
  new_outcome(records, joins_excluded = !joins)
}

# One record per input spec file: certification is per file, rule 1 of
# the related column is applied where the file's problems are assembled.
new_record <- function(name, kind, problems, value) {
  problems <- relate_same_entry(problems)
  list(
    name = name,
    kind = kind,
    certified = nrow(problems) == 0,
    problems = problems,
    value = value
  )
}

# The outcome owns the certification rule: every record certified. The
# spec set exists exactly when the whole step certified — audit strips
# it before returning; run hands it onward.
new_outcome <- function(records, joins_excluded = FALSE) {
  certified <- all(vapply(records, `[[`, logical(1), "certified"))
  specs <- NULL
  if (certified) {
    dicts <- Filter(\(r) r$kind == "dictionary", records)
    joins_record <- Filter(\(r) r$kind == "joins", records)
    specs <- spec_set(
      tables = name_by_table(lapply(dicts, `[[`, "value")),
      joins = if (length(joins_record)) joins_record[[1]]$value else no_joins()
    )
  }
  structure(
    list(
      stage = "spec",
      verb = NA_character_,
      files = records,
      certified = certified,
      joins_excluded = joins_excluded,
      specs = specs
    ),
    class = "rev_report"
  )
}

# The table each failed file INTENDED, read straight from its raw YAML;
# an unreadable or non-string table field asserts nothing (related and
# identity stay deterministic or absent, never guessed). Every intending
# file is kept (accumulate, Liz 2026-07-19): the related note names them
# all, and the identity check sees them all.
intended_tables <- function(failed_files) {
  tables <- vapply(
    failed_files,
    \(f) {
      table <- tryCatch(yaml::read_yaml(f)$table, error = \(e) NULL)
      if (is_string(table)) table else NA_character_
    },
    character(1),
    USE.NAMES = FALSE
  )
  list(
    tables = tables[!is.na(tables)],
    files = failed_files[!is.na(tables)]
  )
}

collect_joins <- function(dir, tables, failed_tables) {
  path <- spec_joins_path(dir)
  if (!file.exists(path)) {
    problems <- flag_problem(
      path,
      "spec set",
      "YX03",
      path = path,
      hint = "set joins = FALSE to run the spec step without a joins spec"
    )
    return(new_record(spec_joins_file, "joins", problems, NULL))
  }
  res <- read_joins(path, tables, failed_tables)
  new_record(spec_joins_file, "joins", res$problems, res$value)
}

# Single-file selection: one record, within-file checks only. A file
# argument that is not a filename is a usage error, not a spec problem.
collect_one <- function(dir, file) {
  rlang::check_string(file)
  if (basename(file) != file) {
    cli::cli_abort(
      c(
        "{.arg file} must be a filename, not a path.",
        i = "Dictionary filenames resolve in {.file {spec_tables_dir(dir)}}.",
        spec_error_footer
      ),
      class = "revpiper_spec_error",
      call = NULL
    )
  }
  if (file == spec_joins_file) {
    path <- spec_joins_path(dir)
    stop_missing_path("Spec file", path)
    res <- read_joins(path)
    return(new_outcome(list(
      new_record(spec_joins_file, "joins", res$problems, res$value)
    )))
  }
  path <- file.path(spec_tables_dir(dir), file)
  stop_missing_path("Spec file", path)
  res <- read_dictionary(path)
  new_outcome(list(new_record(file, "dictionary", res$problems, res$value)))
}

# The spec step's output: the one home for its shape.
spec_set <- function(
  tables = stats::setNames(list(), character(0)),
  joins = no_joins()
) {
  list(tables = tables, joins = joins)
}

# The spec folder layout: the one home for its paths and names — the
# report tree mirrors it through these same constants.
spec_joins_file <- "joins.yaml"
spec_tables_dirname <- "tables"

spec_tables_dir <- function(dir) {
  file.path(dir, spec_tables_dirname)
}

spec_joins_path <- function(dir) {
  file.path(dir, spec_joins_file)
}

# YX01: two spec files claim the same table name — a set-level fact, at
# home with the set's assembly. Returns the fact structurally beside the
# rows (involvement is data; the comma-joined string exists only for
# display) so the collector never parses prose. Deliberately not
# check_identity: code, params, entry label, and file semantics differ.
check_table_identity <- function(tables, files) {
  dupes <- unique(tables[duplicated(tables)])
  involved <- lapply(dupes, \(d) basename(files[tables == d]))
  problems <- bind_problems(lapply(seq_along(dupes), \(i) {
    display <- paste(involved[[i]], collapse = ", ")
    flag_problem(
      display,
      "dictionary set",
      "YX01",
      table = dupes[[i]],
      files = display
    )
  }))
  list(problems = problems, involved = involved)
}

# The shared spine: exactly what both audit and run do, once (design
# 2026-07-19: run performs, writes, and prints exactly what audit does,
# differing only in its final act).
spec_step <- function(dir, joins, file = NULL, verb) {
  rlang::check_string(dir)
  rlang::check_bool(joins)
  outcome <- collect_spec_step(dir, joins, file)
  outcome$verb <- verb
  outcome$paths <- export_spec_reports(outcome)
  announce_spec(outcome)
  outcome
}
