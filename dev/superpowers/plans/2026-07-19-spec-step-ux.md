# Spec-Step UX Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans
> (project protocol: walkthrough-gated per task — explain, Liz reads plan step +
> code, she confirms, execute). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the spec step's reporting and console behaviour per
`dev/superpowers/specs/2026-07-19-spec-step-ux-design.md` (SIGNED OFF,
Liz 2026-07-19): one shared checking core; per-file plain-text reports
written identically by audit and run; the deterministic `related`
column; per-file console certification lines; run returning the spec
set invisibly on success and halting after complete checking on
failure; help-pointer footer; xlsx workbook, certificate file, and
writexl retired.

**Architecture:** A new internal collector (`collect_spec_step()`)
performs all checking and assembles a per-file outcome object (class
`rev_report`, reshaped). Rendering (per-file report text, console
lines) and writing (`output/reports/spec-<runstamp>/<file>.txt`) hang
off that object in `report.R`. `rev_spec_audit()` and `rev_spec_run()`
become thin wrappers over identical calls, differing only in the final
act (return certification info invisibly vs return spec set invisibly /
abort). The `related` column is filled by two deterministic rules only.

**Tech Stack:** R (>= 4.2), cli, rlang, tibble, yaml. testthat edition 3
(snapshot tests for console/report text). writexl is REMOVED.

## Global Constraints

- Branch: `spec-step-ux`. Never commit to main. Git author/committer must
  be `claude <liz.spry+claude@gmail.com>` (verify `git var GIT_AUTHOR_IDENT`
  before each commit).
- TDD per task; run `air format .` before each commit; pre-push suite
  before declaring the branch ready (dev/conventions.md §Pre-push suite).
- Terminology (dev/conventions.md + settled design): *certified /
  certification*, *spec set*, *step* (never "stage" in user-facing text),
  steps named spec/load/process/transform. Error text and report wording
  below is verbatim from the signed-off design — do not improvise.
- Every user-facing change adds a NEWS.md bullet in the same PR (Task 10).
- The spec amendment to `dev/superpowers/specs/2026-07-07-revpiper-design.md`
  lands in this branch (Task 10), per outward-docs-never-fork-the-design.
- Examples in roxygen must write only under `tempdir()` (both functions now
  write reports).
- Test idiom: withr (`withr::local_*`) for fixtures and state — adopted
  Liz 2026-07-19, recorded in dev/conventions.md §Style & formatting.
  withr enters Suggests at its first use (Task 5). No new setwd/on.exit
  or tempfile/on.exit pairs; existing ones migrate in Tasks 5-7 rewrites.
- First instance of any new pattern is a decision point: surface it at
  the task walkthrough for sign-off, never default silently
  (conventions.md rule, adopted 2026-07-19).
- One open wording point, flagged for Liz at Task 6's walkthrough: the
  per-file report header reads `revpiper spec report — <file>` (neutral,
  because run writes the identical file), a deviation from the design
  mock's `revpiper spec audit — <file>`.

---

### Task 1: `related` column in the problem schema

**Files:**
- Modify: `R/utils-messages.R` (new_problem), `R/spec-generic.R`
  (no_problems), `R/schema.R` (flag_problem)
- Test: `tests/testthat/test-utils-messages.R`

**Interfaces:**
- Produces: `new_problem(file, entry, code, message, suggestion = NULL,
  related = NULL)` — tibble gains `related` chr column (NA default).
  `flag_problem(file, entry, code, ..., suggestion = NULL, related = NULL)`
  passes it through. `no_problems()` includes the empty column.

- [ ] **Step 1: Write the failing tests** (append to test-utils-messages.R)

```r
test_that("problems carry a related column, NA by default", {
  p <- new_problem("f.yaml", "column entry 1", "YE01", "unknown field 'x'")
  expect_named(
    p,
    c("file", "entry", "code", "message", "suggestion", "related")
  )
  expect_identical(p$related, NA_character_)
  expect_identical(
    new_problem("f", "e", "C", "m", related = "other error in this entry")$related,
    "other error in this entry"
  )
  expect_identical(nrow(no_problems()), 0L)
  expect_true("related" %in% names(no_problems()))
})
```

- [ ] **Step 2: Run to verify failure**

Run: `Rscript -e 'devtools::test(filter = "utils-messages")'`
Expected: FAIL — names mismatch (no `related`).

- [ ] **Step 3: Implement**

In `R/utils-messages.R`, `new_problem()` gains the argument and column:

```r
new_problem <- function(file, entry, code, message, suggestion = NULL,
                        related = NULL) {
  tibble::tibble(
    file = file,
    entry = entry,
    code = code,
    message = message,
    suggestion = suggestion %||% NA_character_,
    related = related %||% NA_character_
  )
}
```

In `R/spec-generic.R`, `no_problems()` adds the empty column:

```r
no_problems <- function() {
  new_problem(
    character(0), character(0), character(0), character(0),
    suggestion = character(0), related = character(0)
  )
}
```

In `R/schema.R`, `flag_problem()` passes it through:

```r
flag_problem <- function(file, entry, code, ..., suggestion = NULL,
                         related = NULL) {
  new_problem(
    file, entry, code, render_message(code, ...),
    suggestion = suggestion, related = related
  )
}
```

- [ ] **Step 4: Run the full suite** — column addition must not break
  existing expectations. Run: `Rscript -e 'devtools::test()'`. Fix any
  test comparing full problem-tibble names/shape by adding `related`
  to its expectation (content expectations are unaffected).

- [ ] **Step 5: Commit** — `git add -A && git commit` message:
  `Problem schema: related column (NA default), threaded through flag_problem`

### Task 2: Rule 1 — same-entry relation, applied post-hoc

**Files:**
- Modify: `R/utils-messages.R`
- Test: `tests/testthat/test-utils-messages.R`

**Interfaces:**
- Produces: `relate_same_entry(problems)` — fills `related` with the
  verbatim string `"other error in this entry"` for every row whose
  (file, entry) pair appears more than once, only where `related` is NA.
  Task 5's collector calls it per file.

- [ ] **Step 1: Write the failing tests**

```r
test_that("relate_same_entry links co-located errors deterministically", {
  p <- rbind(
    new_problem("a.yaml", "column entry 4", "YE01", "unknown field 'nam'"),
    new_problem("a.yaml", "column entry 4", "YE02", "field 'name' missing"),
    new_problem("a.yaml", "column entry 2", "YF01", "empty")
  )
  out <- relate_same_entry(p)
  expect_identical(
    out$related,
    c("other error in this entry", "other error in this entry", NA)
  )
  # already-set related (rule 2 is more specific) is never overwritten
  p$related[1] <- "spec file b.yaml has standing errors"
  expect_identical(
    relate_same_entry(p)$related[1],
    "spec file b.yaml has standing errors"
  )
  # zero-row input passes through
  expect_identical(nrow(relate_same_entry(no_problems())), 0L)
})
```

- [ ] **Step 2: Run to verify failure** — `devtools::test(filter =
  "utils-messages")`; expected: `relate_same_entry` not found.

- [ ] **Step 3: Implement** (in `R/utils-messages.R`)

```r
# Rule 1 of the related column (design 2026-07-19): a plain fact of
# location, never causation. Rule 2 (set at flag time) wins where present.
relate_same_entry <- function(problems) {
  key <- paste(problems$file, problems$entry, sep = "\r")
  shared <- key %in% key[duplicated(key)]
  fill <- shared & is.na(problems$related)
  problems$related[fill] <- "other error in this entry"
  problems
}
```

- [ ] **Step 4: Run to verify pass**, then the full suite.

- [ ] **Step 5: Commit** — `related rule 1: same-entry co-location`

### Task 3: Rule 2 within a file — references into a troubled section

**Files:**
- Modify: `R/spec-generic.R` (check_reference), `R/spec-source.R`
  (read_dictionary, resolve_references)
- Test: `tests/testthat/test-spec-source.R`

**Interfaces:**
- Consumes: `flag_problem(..., related =)` from Task 1.
- Produces: `check_reference(values, declared, section, file, entry,
  code = "YS02", troubled = NA_character_, troubled_pool = character(0))`.
  `troubled` (single string or NA): the related text when the declared
  pool's section has standing errors. `troubled_pool` (named chr:
  value -> related text): per-value links, used by Task 4.
  `resolve_references(raw, file, prior)` gains the prior-problems arg.
  `section_troubled(prior, section)` returns the related phrase or NA.

Trigger (exact): a YS02 fires AND the section it resolves against already
has >= 1 problem in the same file. Section attribution is by the
codebase's single-home entry-label phrases: `columns` is troubled when any
prior entry starts with `"column "`; `levels` when any starts with
`"level "` or equals `section_label("levels")`; `"key columns"` when
either is troubled (its pool is columns + combine levels). The related
phrase is `sprintf("the %s section has standing errors", section)` with
the same `section` string the check already receives.

- [ ] **Step 1: Write the failing test** (fixture-based, following
  test-spec-source.R's existing helper pattern for writing temp specs)

```r
test_that("YS02 into a troubled section carries related; clean section does not", {
  # columns entry 2 is broken (name misspelled 'nam'); levels references
  # a column name that cannot resolve -> related states the section fact
  path <- write_spec_fixture(list(
    table = "t1", source = list(file = "d.csv"),
    levels = list(study = "study_id"),
    columns = list(
      list(name = "id", type = "text"),
      list(nam = "study_id", type = "text")
    )
  ))
  e <- tryCatch(read_dictionary(path), revpiper_spec_error = identity)
  ys02 <- e$problems[e$problems$code == "YS02", ]
  expect_identical(nrow(ys02), 1L)
  expect_identical(ys02$related, "the columns section has standing errors")

  # same reference failure with a CLEAN columns section: related stays NA
  path2 <- write_spec_fixture(list(
    table = "t2", source = list(file = "d.csv"),
    levels = list(study = "study_idx"),
    columns = list(list(name = "study_id", type = "text"))
  ))
  e2 <- tryCatch(read_dictionary(path2), revpiper_spec_error = identity)
  ys02b <- e2$problems[e2$problems$code == "YS02", ]
  expect_identical(ys02b$related, NA_character_)
})
```

(If no `write_spec_fixture()` helper exists in helper-spec.R, add one that
`yaml::write_yaml()`s the list to `withr::local_tempfile(fileext = ".yaml")`
— follow the file's existing fixture idiom; do not duplicate an existing
helper.)

- [ ] **Step 2: Run to verify failure** — related is NA in case 1.

- [ ] **Step 3: Implement**

`check_reference()` in `R/spec-generic.R`:

```r
check_reference <- function(
  values, declared, section, file, entry,
  code = "YS02", troubled = NA_character_, troubled_pool = character(0)
) {
  bad <- setdiff(values, declared)
  bind_problems(lapply(bad, \(v) {
    related <- if (v %in% names(troubled_pool)) {
      troubled_pool[[v]]
    } else if (!is.na(troubled)) {
      troubled
    } else {
      NULL
    }
    flag_problem(
      file, entry, code,
      value = v, section = section,
      suggestion = suggest_name(v, declared),
      related = related
    )
  }))
}
```

`section_troubled()` and the `resolve_references()` rewiring in
`R/spec-source.R`:

```r
# Whether a referred-to section already has standing problems, by the
# single-home entry-label phrases (entry_label / section_label).
section_troubled <- function(prior, section) {
  starts <- function(p) any(startsWith(prior$entry, p))
  hit <- switch(
    section,
    columns = starts("column "),
    levels = starts("level ") || any(prior$entry == section_label("levels")),
    "key columns" = starts("column ") || starts("level ") ||
      any(prior$entry == section_label("levels"))
  )
  if (hit) sprintf("the %s section has standing errors", section) else NA_character_
}
```

In `resolve_references(raw, file, prior)`: compute
`troubled <- section_troubled(prior, row$refers_to)` per referring row and
pass `troubled = troubled` into its `check_reference()` call. In
`read_dictionary()`, split the one `rbind` so references run last and see
the prior problems:

```r
problems <- rbind(
  run_entry_checks(raw, "file", path, root_entry_label),
  run_contents_checks(raw, "file", path),
  check_level_entries(raw, path),
  check_virtual_collisions(raw, path)
)
problems <- rbind(problems, resolve_references(raw, path, problems))
```

- [ ] **Step 4: Run to verify pass**, then full suite.

- [ ] **Step 5: Commit** — `related rule 2 (within-file): references into a troubled section`

### Task 4: Rule 2 across files — joins referencing a failed dictionary

**Files:**
- Modify: `R/spec-join.R` (read_joins, resolve_join_references)
- Test: `tests/testthat/test-spec-join.R`

**Interfaces:**
- Consumes: `check_reference(..., troubled_pool =)` from Task 3.
- Produces: `read_joins(path, dictionaries = NULL, failed_tables =
  character(0))` and `resolve_join_references(raw, file, dictionaries,
  failed_tables)`. `failed_tables` is a named chr vector: intended table
  name -> basename of the failed spec file (built by Task 5's collector
  from the raw YAML of files that failed validation; unreadable table
  fields are simply absent — no link asserted).

Trigger (exact): a join side fails to resolve against the loaded tables
AND its value equals a failed file's declared `table`. Related text,
verbatim: `sprintf("spec file %s has standing errors", failed_tables[[v]])`.

- [ ] **Step 1: Write the failing test**

```r
test_that("a join side naming a failed file's table carries the cross-file related", {
  # rob loads; estimates' dictionary is absent (failed): the join's left
  # side cannot resolve. With failed_tables knowledge, related states why.
  dicts <- good_dictionaries()["rob"]
  path <- withr::local_tempfile(fileext = ".yaml")
  yaml::write_yaml(list(joins = list(minimal_join())), path)
  e <- tryCatch(
    read_joins(path, dicts, failed_tables = c(estimates = "estimates.yaml")),
    revpiper_spec_error = identity
  )
  yx02 <- e$problems[e$problems$code == "YX02", ]
  expect_true("spec file estimates.yaml has standing errors" %in% yx02$related)
  # without the failed-tables knowledge: plain YX02, related NA
  e2 <- tryCatch(read_joins(path, dicts), revpiper_spec_error = identity)
  expect_true(all(is.na(e2$problems$related[e2$problems$code == "YX02"])))
})
```

(`good_dictionaries()` and `minimal_join()` are test-spec-join.R's
existing helpers; the temp-yaml round-trip mirrors its `joins_from_list()`
idiom, done inline because this call needs the `failed_tables` argument.)

- [ ] **Step 2: Run to verify failure.**

- [ ] **Step 3: Implement** — thread `failed_tables` through
  `read_joins()` into `resolve_join_references()`; in the sides
  resolution, build the per-value pool:

```r
pool <- stats::setNames(
  sprintf("spec file %s has standing errors", failed_tables),
  names(failed_tables)
)
problems <- check_reference(
  sides, tables, "the loaded tables", file, entry,
  code = "YX02", troubled_pool = pool
)
```

Key-column resolution is untouched: it already runs only for sides that
resolved (`intersect(sides, tables)`) — around the dependency, never
through it.

- [ ] **Step 4: Run to verify pass**, full suite.

- [ ] **Step 5: Commit** — `related rule 2 (cross-file): join sides naming a failed dictionary's table`

### Task 5: The collector — one core for audit and run

**Files:**
- Create: `R/spec-collect.R`
- Modify: `R/spec-audit.R` (audit_one moves to spec-collect.R unchanged)
- Test: `tests/testthat/test-spec-collect.R` (new)

**Interfaces:**
- Consumes: read_dictionary, read_joins(+failed_tables), audit_one,
  check_table_identity, dictionary_files, name_by_table, spec_set,
  relate_same_entry.
- Produces: `collect_spec_step(dir, joins = TRUE, file = NULL)` returning
  a classed outcome (class `rev_report`):

```r
structure(
  list(
    stage = "spec",
    verb = NA_character_,     # "audit"/"run", stamped by the caller
    files = <list of records>,
    certified = <all records certified>,
    specs = <spec_set(tables, joins) when certified, else NULL>
  ),
  class = "rev_report"
)
# each record:
list(
  name = <basename, e.g. "estimates.yaml">,
  kind = "dictionary" | "joins",
  certified = <logical>,
  problems = <problems tibble, related applied>,
  value = <rev_dictionary | joins tibble | NULL when failed>
)
```

Semantics locked by the design: every dictionary checked standalone
(problems accumulated across all files); set-identity (YX01) rows appear
in BOTH involved files' records; `failed_tables` built from failed files'
raw YAML (`tryCatch(yaml::read_yaml(f)$table, error = \(e) NULL)`, kept
only when a single string); joins.yaml is a record like any other —
missing-when-expected becomes its YX04 problem record (no abort);
`joins = FALSE` means no joins record and `specs$joins = no_joins()`;
`file =` mode returns a one-record outcome, within-file checks only
(`read_joins(path)` with no dictionaries for `file = "joins.yaml"`).
Usage errors (missing dir, `file` given as a path) still abort — they are
argument errors, not spec problems.

- [ ] **Step 1: Write the failing tests** — one per locked semantic:

```r
test_that("collector checks every file and certifies per file", {
  dir <- specs_example_copy()           # helper: copy inst example to tempdir
  break_file(dir, "estimates.yaml")     # helper: rename 'name:' to 'nam:' in column 4
  out <- collect_spec_step(dir)
  expect_s3_class(out, "rev_report")
  expect_named_records(out, c("estimates.yaml", "rob.yaml", "joins.yaml"))
  expect_false(record(out, "estimates.yaml")$certified)
  expect_true(record(out, "rob.yaml")$certified)
  expect_false(out$certified)
  expect_null(out$specs)
})

test_that("cross-file related reaches the joins record", {
  dir <- specs_example_copy(); break_file(dir, "estimates.yaml")
  out <- collect_spec_step(dir)
  joins_problems <- record(out, "joins.yaml")$problems
  expect_true(
    "spec file estimates.yaml has standing errors" %in% joins_problems$related
  )
})

test_that("clean set certifies and releases the spec set", {
  out <- collect_spec_step(specs_example_copy())
  expect_true(out$certified)
  expect_named(out$specs, c("tables", "joins"))
})

test_that("joins = FALSE: no joins record, zero-row joins in specs", {
  dir <- specs_example_copy(); unlink(file.path(dir, "joins.yaml"))
  out <- collect_spec_step(dir, joins = FALSE)
  expect_named_records(out, c("estimates.yaml", "rob.yaml"))
  expect_identical(nrow(out$specs$joins), 0L)
})

test_that("missing joins.yaml when expected is a YX04 record, not an abort", {
  dir <- specs_example_copy(); unlink(file.path(dir, "joins.yaml"))
  out <- collect_spec_step(dir)
  expect_identical(record(out, "joins.yaml")$problems$code, "YX04")
  expect_false(out$certified)
})

test_that("single-file mode collects one record, within-file only", {
  dir <- specs_example_copy()
  out <- collect_spec_step(dir, file = "estimates.yaml")
  expect_named_records(out, "estimates.yaml")
  expect_true(out$certified)
})
```

Helpers, all in `tests/testthat/helper-spec.R` (Tasks 6-8 use them too;
withr idiom per the adopted convention — add `withr` to DESCRIPTION
Suggests in this task, its first use):
- `spec_project(fixture)` — PROMOTED from test-spec-audit.R (delete it
  there in Task 7's rewrite), reimplemented with
  `dir <- withr::local_tempdir(.local_envir = parent.frame())`, copying
  `test_path("fixtures", fixture)` in as `<dir>/specs`, returning `dir`.
  Callers that need the cwd use `withr::local_dir(spec_project(...))`;
  Task 5's collector tests pass `file.path(root, "specs")` directly.
- `scrub_runstamp()` — PROMOTED from test-spec-audit.R verbatim.
- `break_file(root, file)` — rewrites `name:` to `nam:` in the last
  column entry of `<root>/specs/tables/<file>`.
- `record(out, name)` — the record whose `$name` matches.
- `expect_named_records(out, names)` — records' names setequal `names`.
- Migrate `joins_from_list()`'s `tempfile`/`on.exit` pair to
  `withr::local_tempfile()` (test-spec-join.R keeps working unchanged).
In the Task 5-8 test code below, read `specs_example_copy()` as
`file.path(spec_project("specs-good"), "specs")` for collector calls, and
as `withr::local_dir(spec_project("specs-good"))` + `"specs"` where the
test also exercises report-writing (Tasks 6-8).

- [ ] **Step 2: Run to verify failure** — collect_spec_step not found.

- [ ] **Step 3: Implement `R/spec-collect.R`** (audit_one moves here
  verbatim, with its comment):

```r
# The spec step's one checking core: audit and run both call exactly this.
collect_spec_step <- function(dir, joins = TRUE, file = NULL) {
  if (!is.null(file)) {
    return(collect_one(dir, file))
  }
  files <- dictionary_files(spec_tables_dir(dir))
  audited <- lapply(files, \(f) audit_one(read_dictionary(f)))
  loaded <- !vapply(audited, \(a) is.null(a$value), logical(1))
  tables <- name_by_table(lapply(audited[loaded], \(a) a$value))
  identity <- check_table_identity(names(tables), files[loaded])
  failed_tables <- intended_tables(files[!loaded])

  records <- lapply(seq_along(files), \(i) {
    own <- rbind(
      audited[[i]]$problems,
      identity[grepl(basename(files[[i]]), identity$file, fixed = TRUE), ]
    )
    new_record(basename(files[[i]]), "dictionary", own, audited[[i]]$value)
  })
  if (joins) {
    records <- c(records, list(collect_joins(dir, tables, failed_tables)))
  }
  certified <- all(vapply(records, `[[`, logical(1), "certified"))
  new_outcome(records, certified)
}

new_record <- function(name, kind, problems, value) {
  problems <- relate_same_entry(problems)
  list(
    name = name, kind = kind,
    certified = nrow(problems) == 0,
    problems = problems,
    value = value
  )
}

new_outcome <- function(records, certified) {
  specs <- NULL
  if (certified) {
    dicts <- Filter(\(r) r$kind == "dictionary", records)
    joins_rec <- Filter(\(r) r$kind == "joins", records)
    specs <- spec_set(
      tables = name_by_table(lapply(dicts, `[[`, "value")),
      joins = if (length(joins_rec)) joins_rec[[1]]$value else no_joins()
    )
  }
  structure(
    list(
      stage = "spec", verb = NA_character_,
      files = records, certified = certified, specs = specs
    ),
    class = "rev_report"
  )
}

# The table each failed file INTENDED, read straight from its raw YAML;
# unreadable or non-string table fields assert no link (design: related
# is deterministic or absent).
intended_tables <- function(failed_files) {
  out <- character(0)
  for (f in failed_files) {
    tab <- tryCatch(yaml::read_yaml(f)$table, error = \(e) NULL)
    if (is_string(tab)) {
      out[[tab]] <- basename(f)
    }
  }
  out
}

collect_joins <- function(dir, tables, failed_tables) {
  path <- spec_joins_path(dir)
  if (!file.exists(path)) {
    problems <- flag_problem(
      path, "spec set", "YX04",
      path = path,
      hint = "set joins = FALSE to run the spec step without a joins spec"
    )
    return(new_record(spec_joins_file, "joins", problems, NULL))
  }
  audit <- audit_one(read_joins(path, tables, failed_tables))
  new_record(spec_joins_file, "joins", audit$problems, audit$value)
}

collect_one <- function(dir, file) {
  rlang::check_string(file)
  if (basename(file) != file) {
    cli::cli_abort(
      c(
        "{.arg file} must be a filename, not a path.",
        i = "Dictionary filenames resolve in {.file {spec_tables_dir(dir)}}.",
        spec_error_footer
      ),
      class = "revpiper_spec_error", call = NULL
    )
  }
  if (file == spec_joins_file) {
    path <- spec_joins_path(dir)
    stop_missing_path("Spec file", path)
    audit <- audit_one(read_joins(path))
    return(new_outcome(
      list(new_record(spec_joins_file, "joins", audit$problems, audit$value)),
      certified = nrow(audit$problems) == 0
    ))
  }
  path <- file.path(spec_tables_dir(dir), file)
  stop_missing_path("Spec file", path)
  audit <- audit_one(read_dictionary(path))
  new_outcome(
    list(new_record(file, "dictionary", audit$problems, audit$value)),
    certified = nrow(audit$problems) == 0
  )
}
```

(Single-file certified outcome must release `specs` too — `new_outcome`
already does, via the records. Verify the joins-only single-file case
sets `specs$tables` to the empty named list: `spec_set()`'s default.)

- [ ] **Step 4: Run to verify pass**, full suite (spec-audit.R still
  compiles — it keeps its old body until Task 7; only audit_one moved).

- [ ] **Step 5: Commit** — `collect_spec_step: the one checking core for audit and run`

### Task 6: Rendering and writing — per-file reports (report.R rewrite)

**Files:**
- Modify: `R/report.R` (rewrite: delete `new_stage_report`,
  `is_certified`, old `format.rev_report` body, `export_report`; keep
  `output_reports_dir`, `runstamp`), `DESCRIPTION` (remove writexl from
  Imports)
- Test: `tests/testthat/test-report.R` (rewrite)

**Interfaces:**
- Consumes: the Task 5 outcome object.
- Produces:
  - `format_file_report(record)` -> character lines (the .txt content)
  - `format_problem_table(problems)` -> aligned text lines, columns
    `entry code message suggestion related` (file column dropped — the
    report is per-file), headers plain, every cell left-aligned, NA -> ""
  - `export_spec_reports(outcome, dir = output_reports_dir)` -> writes
    `<dir>/spec-<runstamp>/<record$name>.txt` per record; returns
    invisibly `list(dir = <run folder>, files = <named chr of paths>)`
- **Walkthrough flag for Liz:** header wording `revpiper spec report — <file>`
  (see Global Constraints).

Report content (verbatim shapes from the design; joins summary format is
this plan's concretisation of "same pattern"):

```
revpiper spec report — estimates.yaml        | revpiper spec report — joins.yaml
Status: CERTIFIED                            | Status: CERTIFIED
                                             |
Table:   estimates                           | Joins: 1
Source:  data/raw/estimates.csv              |   estimates <-> rob — adds variables
Columns: 5 — study, design, mean_age, ...    |
Levels:  study                               |
                                             |
Errors: none.                                | Errors: none.
```

NOT CERTIFIED files: `Status: NOT CERTIFIED (N errors)` then the aligned
error table only (no summary — per Liz: summaries for successful files,
error lists for unsuccessful). A failed file whose value is NULL has no
summary to draw on anyway.

- [ ] **Step 1: Write the failing tests** (snapshot the two report
  shapes; exact-string test for the alignment rule)

```r
test_that("certified dictionary report: status, summary, no errors", {
  out <- collect_spec_step(specs_example_copy())
  expect_snapshot(
    writeLines(format_file_report(record(out, "estimates.yaml")))
  )
  expect_snapshot(
    writeLines(format_file_report(record(out, "joins.yaml")))
  )
})

test_that("uncertified report: error table, aligned per contents", {
  dir <- specs_example_copy(); break_file(dir, "estimates.yaml")
  out <- collect_spec_step(dir)
  lines <- format_file_report(record(out, "estimates.yaml"))
  expect_snapshot(writeLines(lines))
  header <- grep("^entry", lines, value = TRUE)
  expect_identical(substr(header, 1, 5), "entry")   # no centring, no bold
})

test_that("export writes one txt per input file in a per-run folder", {
  withr::local_dir(withr::local_tempdir())
  out <- collect_spec_step(specs_example_copy())
  paths <- export_spec_reports(out)
  expect_true(dir.exists(paths$dir))
  expect_match(paths$dir, "^output/reports/spec-\\d{8}-\\d{6}$")
  expect_setequal(
    basename(paths$files),
    c("estimates.txt", "rob.txt", "joins.txt")
  )
  expect_true(all(file.exists(paths$files)))
})
```

(Report filename: `<spec filename with .yaml stripped>.txt` — matches the
design mock `estimates.txt`.)

`unique_run_dir(dir, stem)` (same file): returns `file.path(dir, stem)`
if it does not exist, else the first of `<stem>-2`, `<stem>-3`, ... that
does not — the design's never-overwrite promise held even for two runs
within one second. Test (add to the export test): call
`export_spec_reports(out)` twice in the same second; expect two distinct
existing directories.

- [ ] **Step 2: Run to verify failure.**

- [ ] **Step 3: Implement** (in `R/report.R`)

```r
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
    if (record$certified) "Errors: none." else c("Errors:", format_problem_table(record$problems))
  )
}

format_summary <- function(record) {
  if (record$kind == "joins") {
    joins <- record$value
    c(
      sprintf("Joins: %d", nrow(joins)),
      sprintf(
        "  %s <-> %s — adds %s",
        joins$left, joins$right, joins$adds
      )
    )
  } else {
    d <- record$value
    c(
      sprintf("Table:   %s", d$table),
      sprintf("Source:  %s", d$source$file),
      sprintf(
        "Columns: %d — %s",
        nrow(d$columns), paste(d$columns$name, collapse = ", ")
      ),
      sprintf("Levels:  %s", paste(names(d$levels), collapse = ", "))
    )
  }
}

format_problem_table <- function(problems) {
  cols <- c("entry", "code", "message", "suggestion", "related")
  cells <- vapply(cols, \(col) {
    v <- as.character(problems[[col]])
    v[is.na(v)] <- ""
    formatC(c(col, v), width = max(nchar(c(col, v))), flag = "-")
  }, character(nrow(problems) + 1))
  trimws(apply(cells, 1, paste, collapse = "   "), which = "right")
}

export_spec_reports <- function(outcome, dir = output_reports_dir) {
  run_dir <- unique_run_dir(dir, sprintf("%s-%s", outcome$stage, runstamp()))
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)
  files <- vapply(outcome$files, \(record) {
    path <- file.path(
      run_dir, sub("\\.ya?ml$", ".txt", record$name)
    )
    writeLines(format_file_report(record), path)
    path
  }, character(1))
  names(files) <- vapply(outcome$files, `[[`, character(1), "name")
  invisible(list(dir = run_dir, files = files))
}
```

Dictionary with no levels: `Levels:` line shows empty — render `"none"`
when `length(d$levels) == 0`. Include that in the implementation and a
snapshot (rob.yaml has levels, so add a fixture-based case only if the
snapshot for an existing fixture doesn't cover it).

- [ ] **Step 4: Delete the retired machinery** — `new_stage_report`,
  `is_certified`, `export_report`, the old `format.rev_report` /
  `print.rev_report` bodies (Task 7 re-creates format/print for the new
  object), the writexl call; remove `writexl` from DESCRIPTION Imports.
  `renv.lock` is left unchanged (the dev library still has writexl; the
  lockfile records the dev environment, not Imports).
  Old test-report.R tests for the deleted functions are deleted with them.

- [ ] **Step 5: Run to verify pass** — test-report.R green; spec-audit.R
  is now BROKEN (it calls deleted functions); that is expected mid-branch
  ONLY if Tasks 6 and 7 are committed together. To keep every commit
  green: implement Task 7's rewiring in this same working tree and commit
  Tasks 6+7 as their walkthroughs conclude — OR retain `new_stage_report`
  + `export_report` as deprecated internals until Task 7 and delete them
  there. Choose the second (each task = one green commit): keep the old
  functions in place this task, delete them in Task 7 Step 3.

- [ ] **Step 6: Commit** — `Per-file report rendering and per-run export; writexl retired from Imports`

### Task 7: Console lines + `rev_spec_audit()` rewired

**Files:**
- Modify: `R/spec-audit.R` (full rewrite of rev_spec_audit + announce;
  delete audit_joins), `R/report.R` (new format/print for the outcome;
  delete the Task-6-deferred old machinery)
- Test: `tests/testthat/test-spec-audit.R` (rewrite), `test-report.R`
  (format/print snapshots)

**Interfaces:**
- Consumes: collect_spec_step, export_spec_reports, format_file_report.
- Produces: `announce_spec(outcome, paths)` (cli side), `format.rev_report`
  / `print.rev_report` (the same lines, minus cli styling). `rev_spec_audit(
  dir = "specs", joins = TRUE)` returns the outcome **invisibly** (it has
  just printed the same lines — visible return would print twice).

Console shape (verbatim from the design; `<verb>` = outcome$verb):

```
revpiper spec <verb>: NOT CERTIFIED (1 of 3 files certified)
✔ rob.yaml — CERTIFIED
✖ estimates.yaml — NOT CERTIFIED (2 errors) — see output/reports/spec-20260719-101502/estimates.txt
✖ joins.yaml — NOT CERTIFIED (1 error) — see output/reports/spec-20260719-101502/joins.txt
```

Success:

```
revpiper spec <verb>: SUCCESS
✔ all input files CERTIFIED (3 of 3 files certified)
✔ estimates.yaml — CERTIFIED
✔ rob.yaml — CERTIFIED
✔ joins.yaml — CERTIFIED
✔ reports written to output/reports/spec-20260719-101502/
```

(run appends its spec-set line — Task 8.)

- [ ] **Step 1: Write the failing tests**

```r
test_that("audit prints per-file certification and returns the outcome invisibly", {
  withr::local_dir(withr::local_tempdir())
  dir <- specs_example_copy(); break_file(dir, "estimates.yaml")
  expect_snapshot(out <- rev_spec_audit(dir))
  expect_s3_class(out, "rev_report")
  expect_identical(out$verb, "audit")
  expect_false(out$certified)
  expect_null(out$specs)          # audit NEVER returns a usable spec object
  expect_invisible(rev_spec_audit(dir))
})

test_that("audit success: reports written, no error raised, outcome certified", {
  withr::local_dir(withr::local_tempdir())
  expect_snapshot(out <- rev_spec_audit(specs_example_copy()))
  expect_true(out$certified)
  expect_null(out$specs)          # certified or not: certification info only
  written <- list.files("output/reports", recursive = TRUE)
  expect_setequal(basename(written), c("estimates.txt", "rob.txt", "joins.txt"))
})
```

(Snapshots contain the runstamped path — scrub it with
`expect_snapshot(..., transform = scrub_runstamp)` where
`scrub_runstamp <- function(x) gsub("spec-\\d{8}-\\d{6}", "spec-<runstamp>", x)`;
put the helper in helper-spec.R, it is needed by test-spec-run.R too.)

- [ ] **Step 2: Run to verify failure.**

- [ ] **Step 3: Implement**

```r
rev_spec_audit <- function(dir = "specs", joins = TRUE) {
  rlang::check_string(dir)
  rlang::check_bool(joins)
  outcome <- collect_spec_step(dir, joins)
  outcome$verb <- "audit"
  outcome$specs <- NULL   # audit NEVER hands back a usable spec object
  paths <- export_spec_reports(outcome)
  outcome$paths <- paths
  announce_spec(outcome, paths)
  invisible(outcome)
}
```

`announce_spec()` + `format.rev_report` in R/report.R (one line source —
format() builds the plain lines; announce_spec maps them onto cli so the
console and print() never drift):

```r
report_lines <- function(outcome, paths) {
  n <- length(outcome$files)
  n_ok <- sum(vapply(outcome$files, `[[`, logical(1), "certified"))
  overall <- if (outcome$certified) {
    c(
      sprintf("revpiper spec %s: SUCCESS", outcome$verb),
      sprintf("all input files CERTIFIED (%d of %d files certified)", n_ok, n)
    )
  } else {
    sprintf(
      "revpiper spec %s: NOT CERTIFIED (%d of %d files certified)",
      outcome$verb, n_ok, n
    )
  }
  per_file <- vapply(outcome$files, \(record) {
    if (record$certified) {
      sprintf("%s — CERTIFIED", record$name)
    } else {
      n_err <- nrow(record$problems)
      sprintf(
        "%s — NOT CERTIFIED (%d error%s) — see %s",
        record$name, n_err, if (n_err == 1) "" else "s",
        paths$files[[record$name]]
      )
    }
  }, character(1))
  written <- if (outcome$certified) {
    sprintf("reports written to %s/", paths$dir)
  }
  list(overall = overall, per_file = per_file,
       ok = vapply(outcome$files, `[[`, logical(1), "certified"),
       written = written)
}

announce_spec <- function(outcome, paths) {
  lines <- report_lines(outcome, paths)
  cli::cli_text(lines$overall[[1]])
  for (extra in lines$overall[-1]) cli::cli_alert_success(extra)
  for (i in seq_along(lines$per_file)) {
    if (lines$ok[[i]]) cli::cli_alert_success(lines$per_file[[i]])
    else cli::cli_alert_danger(lines$per_file[[i]])
  }
  if (!is.null(lines$written)) cli::cli_alert_success(lines$written)
}
```

`format.rev_report(x, ...)` needs paths it does not carry — store them:
`export_spec_reports()` result is assigned onto the outcome by the
callers (`outcome$paths <- paths`) before announce; format() then reads
`x$paths`. Add that line to rev_spec_audit above and to Task 8's run.
`format.rev_report` returns
`with(report_lines(x, x$paths), c(overall, paste(ifelse(ok, "✔", "✖"), per_file), written))`
and `print.rev_report` writeLines it, returning invisibly.
Delete `audit_joins()` (superseded by collect_joins) and the old
machinery deferred from Task 6.

- [ ] **Step 4: Roxygen** — rewrite rev_spec_audit's docs: title "Audit
  the spec step"; describe per-file reports, the per-run folder, the
  certification-information-only return (explicitly: never the spec set —
  run is the function that hands the spec set onward); example runs in
  `tempdir()` exactly as the current example does. `devtools::document()`.

- [ ] **Step 5: Run to verify pass**, full suite.

- [ ] **Step 6: Commit** — `rev_spec_audit over the shared core: per-file console lines, invisible certification return`

### Task 8: `rev_spec_run()` — same commands, then the final act

**Files:**
- Modify: `R/spec-run.R` (rewrite rev_spec_run; delete run_spec_set;
  keep spec_set + path helpers)
- Test: `tests/testthat/test-spec-run.R` (rewrite)

**Interfaces:**
- Consumes: collect_spec_step, export_spec_reports, announce_spec.
- Produces: `rev_spec_run(dir = "specs", file = NULL, joins = TRUE)` —
  identical side effects to audit; on success returns `outcome$specs`
  (the spec set) **invisibly**, plus the console line
  `spec set returned, ready for the load step`; on failure aborts with
  the verbatim message `spec set not certified and not returned.`
  (class `revpiper_spec_error`, the outcome attached as `$outcome`).

- [ ] **Step 1: Write the failing tests**

```r
test_that("run success: audit-identical output, spec set returned invisibly", {
  withr::local_dir(withr::local_tempdir())
  expect_snapshot(specs <- rev_spec_run(specs_example_copy()))
  expect_named(specs, c("tables", "joins"))
  expect_s3_class(specs$tables[[1]], "rev_dictionary")
  expect_invisible(rev_spec_run(specs_example_copy()))
  written <- list.files("output/reports", recursive = TRUE)
  expect_true(length(written) > 0)      # run writes everything audit writes
})

test_that("run failure: all files checked, reports written, then one abort", {
  withr::local_dir(withr::local_tempdir())
  dir <- specs_example_copy(); break_file(dir, "estimates.yaml")
  expect_snapshot(error = TRUE, rev_spec_run(dir))
  written <- list.files("output/reports", recursive = TRUE)
  expect_setequal(basename(written), c("estimates.txt", "rob.txt", "joins.txt"))
  e <- tryCatch(rev_spec_run(dir), revpiper_spec_error = identity)
  expect_match(conditionMessage(e), "not certified and not returned")
  expect_s3_class(e$outcome, "rev_report")
})

test_that("single-file mode keeps the same presentation", {
  withr::local_dir(withr::local_tempdir())
  dir <- specs_example_copy()
  expect_snapshot(one <- rev_spec_run(dir, file = "estimates.yaml"))
  expect_named(one$tables, "estimates")
})
```

- [ ] **Step 2: Run to verify failure.**

- [ ] **Step 3: Implement**

```r
rev_spec_run <- function(dir = "specs", file = NULL, joins = TRUE) {
  rlang::check_string(dir)
  rlang::check_bool(joins)
  outcome <- collect_spec_step(dir, joins, file)
  outcome$verb <- "run"
  paths <- export_spec_reports(outcome)
  outcome$paths <- paths
  announce_spec(outcome, paths)
  if (!outcome$certified) {
    cli::cli_abort(
      "spec set not certified and not returned.",
      class = "revpiper_spec_error", call = NULL, outcome = outcome
    )
  }
  cli::cli_alert_success("spec set returned, ready for the load step")
  invisible(outcome$specs)
}
```

Delete `run_spec_set()` and rev_spec_run's old body including its
file-dispatch (now in collect_one). `spec_set()`, `spec_joins_file`,
`spec_tables_dir()`, `spec_joins_path()` stay — they are the layout's
single home, consumed by spec-collect.R.

- [ ] **Step 4: Roxygen** — rewrite: run performs, writes, and prints
  exactly what audit does, then returns the spec set invisibly on
  success / halts on failure with nothing returned; `@return` documents
  invisibility and the assignment idiom (`specs <- rev_spec_run()`);
  examples in `tempdir()` (they now write reports — the current examples
  do not use tempdir and MUST change). `devtools::document()`.

- [ ] **Step 5: Run to verify pass**, full suite.

- [ ] **Step 6: Commit** — `rev_spec_run: audit-identical side effects, invisible spec set or halting error`

### Task 9: The help-pointer footer

**Files:**
- Modify: `R/utils-messages.R` (spec_error_footer)
- Test: existing snapshots via `devtools::test()`

**Interfaces:** none new — the footer constant's wording changes; every
call site inherits it.

- [ ] **Step 1: Update the failing expectation first** — run
  `Rscript -e 'devtools::test()'` after editing one snapshot mention by
  hand is NOT the flow; instead: change the constant (Step 2), run tests,
  review every snapshot diff to confirm the ONLY change is the footer
  line, then `testthat::snapshot_accept()`.

- [ ] **Step 2: Implement**

```r
# Every spec-error abort ends with the same pointer: the one home for the
# footer's wording (help pointer per the 2026-07-19 UX design; replaced
# the system.file() examples pointer).
spec_error_footer <- c(
  i = "See {.code ?rev_spec_run} for the expected spec layout,
       with correctly formatted examples."
)
```

- [ ] **Step 3: Run tests, review snapshot diffs (footer line only),
  accept, run full suite.**

- [ ] **Step 4: Ensure `?rev_spec_run` holds its side of the pointer** —
  the Task 8 roxygen must include a "Spec layout" section (tables/ dir,
  joins.yaml beside it) and the examples pointer to
  `system.file("extdata", "specs-example", package = "revpiper")` so the
  footer's promise lands somewhere real. Verify with
  `Rscript -e 'devtools::document(); tools:::Rd2txt("man/rev_spec_run.Rd")'`.

- [ ] **Step 5: Commit** — `Spec-error footer: help pointer replaces the examples incantation`

### Task 10: Spec amendment, NEWS, close-out gates

**Files:**
- Modify: `dev/superpowers/specs/2026-07-07-revpiper-design.md` (§6.1
  Stage contract + certificate mentions at lines ~111, ~292, ~443-460,
  ~578), `NEWS.md`, `.claude/CLAUDE.md` (status pointers)
- Test: pre-push suite

- [ ] **Step 1: Amend §6.1 Stage contract** — replace the
  xlsx-plus-certificate paragraph (`<stage>-<runstamp>.xlsx` /
  `<stage>-<runstamp>-certificate.txt`) with the per-file machinery:
  one plain-text report per input spec file under
  `output/reports/<stage>-<runstamp>/`; certified files carry a summary,
  uncertified an error table with the deterministic `related` column
  (two rules, stated); audit and run write identically; run alone halts
  after complete checking (nothing returned) or returns the step's
  product invisibly; the CERTIFIED per-file report set remains the
  timestamped prespecification artifact. Update the audit-certificate
  sentence at ~line 292 (per-file reports name each dictionary by
  filename and table) and the terminal-certificate line ~578. Mark the
  amendment with date + "per 2026-07-19 spec-step UX design (signed
  off)".

- [ ] **Step 2: NEWS.md** — the 0.0.0.9000 bullets that describe the old
  behaviour are unreleased: rewrite the `rev_spec_audit()` and
  `rev_spec_run()` bullets to the new contracts, drop the
  canonical-examples pointer sentence, and add bullets: per-file reports
  replace the xlsx workbook + certificate (writexl dropped); the
  `related` column; the help-pointer footer.

- [ ] **Step 3: Repo sweep** — `grep -rn "writexl\|certificate\|canonical"
  R/ tests/ README.md man/ .claude/` and resolve every hit (delete,
  reword, or justify at the walkthrough). Update .claude/CLAUDE.md status
  pointers (spec-step-ux branch state, next steps).

- [ ] **Step 4: Pre-push suite** (dev/conventions.md, run all):
  `air format .`; `Rscript -e 'pkgload::load_all(quiet = TRUE); lintr::lint_package()'`
  (expect 0 lints); `Rscript -e 'devtools::test()'` (expect 0 failures);
  `Rscript -e 'devtools::check()'` (expect 0 errors / 0 warnings / 0 notes).

- [ ] **Step 5: Structural review** (amendment 7h/8e: at phase close-out)
  — read the final diff whole; run the pre-commit duplication pass and
  /simplify on the branch diff per the binding protocol; fixes reviewed
  jointly with Liz.

- [ ] **Step 6: Commit** — `Spec amendment + NEWS: per-file report machinery, run/audit contract` —
  then hand to Liz: fetch, review PR (deliverable + amendment together),
  squash-merge on green CI.
