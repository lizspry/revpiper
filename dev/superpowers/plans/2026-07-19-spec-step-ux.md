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

## Deferred-deletions ledger (check off AT the named task; none may
## survive the branch)

- Task 7: old report machinery (`new_stage_report`, `is_certified`,
  `export_report`, old format/print bodies) + their test-report.R tests;
  `audit_joins()`; test-spec-audit.R's file-local `spec_project`/
  `scrub_runstamp` shadows; **writexl out of DESCRIPTION Imports**
  (deferred from Task 6 — its last caller dies here).
- Task 8: `stop_spec()`; `read_dictionaries()` (retire if no runtime
  caller remains — expected); helper.R's `thrown_problems()`;
  spec-run.R's interim single-file/run_spec_set paths.

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

### Task 3: Rule 2 within a file — references into a provably incomplete pool

**Files:**
- Modify: `R/spec-generic.R` (check_reference), `R/spec-source.R`
  (resolve_references, pool_incomplete)
- Test: `tests/testthat/test-spec-source.R`

**Interfaces:**
- Consumes: `flag_problem(..., related =)` from Task 1.
- Produces: `check_reference(values, declared, section, file, entry,
  code = "YS02", related_for = NULL)` — `related_for` is a function from
  a failed value to its related text (or NULL); the ONE seam both rules-2
  routes share (Task 4 passes its own closure).
  `pool_incomplete(raw, section)` in spec-source.R.

Trigger (exact, amended 2026-07-19 with Liz): a reference fails AND the
pool it resolved against is PROVABLY INCOMPLETE — the referred section
contains entries whose identity could not be read (`entry_names()` NA).
Only column entries can go nameless (level names are mapping keys, always
readable), so within-file related fires only for column-referring pools
(`columns`, `key columns`), with the verbatim phrase
`"the columns section has entries whose names cannot be read"`.
Errors that do not remove names from the pool (e.g. a bad range on a
correctly named column) never trigger related — they cannot explain a
failed reference. No label parsing, no prior-problems threading:
the trigger reads the raw spec data.

- [ ] **Step 1: Write the failing test** (test-spec-source.R, using the
  suite's `minimal_dict()` / `problems_of()` idiom)

```r
test_that("a failed reference beside nameless column entries carries related", {
  d <- minimal_dict()
  d$levels <- list(study = "studyx") # fails to resolve
  d$columns[[2]] <- list(nam = "site", type = "text") # nameless entry
  p <- problems_of(d)
  expect_identical(
    p[p$code == "YS02", ]$related,
    "the columns section has entries whose names cannot be read"
  )

  # clean names: the same failed reference stands alone (typo territory)
  d2 <- minimal_dict()
  d2$levels <- list(study = "studyx")
  p2 <- problems_of(d2)
  expect_identical(p2[p2$code == "YS02", ]$related, NA_character_)
})
```

- [ ] **Step 2: Run to verify failure** — `devtools::test(filter =
  "spec-source")`; expected: related is NA in the first case.

- [ ] **Step 3: Implement**

`check_reference()` in `R/spec-generic.R`:

```r
check_reference <- function(
  values,
  declared,
  section,
  file,
  entry,
  code = "YS02",
  related_for = NULL
) {
  bad <- setdiff(values, declared)
  bind_problems(lapply(bad, \(v) {
    flag_problem(
      file,
      entry,
      code,
      value = v,
      section = section,
      suggestion = suggest_name(v, declared),
      related = if (!is.null(related_for)) related_for(v)
    )
  }))
}
```

In `R/spec-source.R`, beside resolve_references:

```r
# Whether a referred-to section's name pool is provably incomplete: it
# contains entries whose identity could not be read. Level names are
# mapping keys (always readable), so only column entries can go nameless.
pool_incomplete <- function(raw, section) {
  if (!section %in% c("columns", "key columns")) {
    return(FALSE)
  }
  is_list_of_mappings(raw$columns) &&
    anyNA(entry_names(raw$columns, "column"))
}
```

In `resolve_references()`, per referring row compute the closure and pass
it through (read_dictionary is untouched — the trigger reads raw, not
prior problems):

```r
related_for <- if (pool_incomplete(raw, row$refers_to)) {
  \(value) "the columns section has entries whose names cannot be read"
}
# ... check_reference(instance$values, known, row$refers_to, file,
#                     instance$entry, related_for = related_for)
```

- [ ] **Step 4: Run to verify pass**, then full suite.

- [ ] **Step 5: Commit** — `related rule 2 (within-file): references into a provably incomplete pool`

### Task 4: Rule 2 across files — joins referencing a failed dictionary

**Files:**
- Modify: `R/spec-join.R` (read_joins, resolve_join_references)
- Test: `tests/testthat/test-spec-join.R`

**Interfaces:**
- Consumes: `check_reference(..., related_for =)` from Task 3.
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
related_for <- function(v) {
  if (v %in% names(failed_tables)) {
    sprintf("spec file %s has standing errors", failed_tables[[v]])
  }
}
problems <- check_reference(
  sides, tables, "the loaded tables", file, entry,
  code = "YX02", related_for = related_for
)
```

Key-column resolution is untouched: it already runs only for sides that
resolved (`intersect(sides, tables)`) — around the dependency, never
through it.

- [ ] **Step 4: Run to verify pass**, full suite.

- [ ] **Step 5: Commit** — `related rule 2 (cross-file): join sides naming a failed dictionary's table`

### Task 5a: Readers return (value, problems) — the throw/catch layer removed

(Restructure signed off by Liz 2026-07-19: under the new contract every
caller catches, so nothing should throw. Problems are data.)

**Files:**
- Rename: `R/utils-messages.R` -> `R/spec-problems.R` (git mv), and move
  `no_problems()` / `bind_problems()` into it from spec-generic.R — one
  home for the problem schema (two-axis naming: spec- prefix, per Liz).
- Modify: `R/spec-generic.R` (parse_spec_yaml), `R/spec-source.R`
  (read_dictionary), `R/spec-join.R` (read_joins), `R/spec-audit.R`
  (audit_one deleted; call sites call readers directly), `R/spec-run.R`
  (interim: keeps aborting via the retained stop_spec until Task 8),
  `tests/testthat/helper.R` (spec_problems becomes `\(x) x$problems`),
  affected reader tests/snapshots.

**Interfaces (produced, consumed by 5b-8):**
- `read_dictionary(path)` -> `list(value = rev_dictionary|NULL, problems)`
  (value non-NULL iff zero problems; parse failure = YS05 problem row,
  value NULL, no validation attempted)
- `read_joins(path, dictionaries = NULL, failed_tables = character(0))`
  -> `list(value = joins tibble|NULL, problems)`; missing file stays
  `list(value = no_joins(), problems = no_problems())`
- `parse_spec_yaml(path)` -> `list(raw = <yaml>|NULL, problems)`
- DELETED: `audit_one()`. RETAINED FOR TASK 8's DELETION: `stop_spec()`
  (sole remaining caller: spec-run.R's interim paths; test-utils-messages'
  stop_spec tests move to test-spec-problems.R and die in Task 8).

- [ ] **Step 1: Failing contract tests** (test-spec-source.R and
  test-spec-join.R):

```r
test_that("read_dictionary returns value + problems, never throwing on spec problems", {
  good <- read_dict(minimal_dict())
  expect_named(good, c("value", "problems"))
  expect_s3_class(good$value, "rev_dictionary")
  expect_identical(nrow(good$problems), 0L)
  bad <- minimal_dict()
  bad$columns[[1]] <- list(nam = "study", type = "text")
  res <- read_dict(bad)
  expect_null(res$value)
  expect_gt(nrow(res$problems), 0)
})
```

```r
test_that("read_joins returns value + problems, never throwing on spec problems", {
  good <- joins_from_list(list(minimal_join()))
  expect_s3_class(good$value, "tbl_df")
  expect_identical(nrow(good$problems), 0L)
  bad <- minimal_join()
  bad$left <- "nope"
  res <- joins_from_list(list(bad))
  expect_null(res$value)
  expect_gt(nrow(res$problems), 0)
})
```

- [ ] **Step 2: Run to verify failure** (readers currently throw).

- [ ] **Step 3: Implement.** Readers collect problems exactly as now but
  END with `list(value = if (nrow(problems) == 0) <constructor> else NULL,
  problems = problems)` instead of `stop_spec()`. parse_spec_yaml wraps
  its tryCatch result the same way; read_dictionary/read_joins
  short-circuit on `is.null(p$raw)`. Adapt in place, same commit:
  - helper.R: `spec_problems <- function(x) x$problems`; joins_from_list
    returns the reader result unchanged; audit tests' fixture flows are
    untouched (audit adapts below).
  - spec-audit.R: `audited <- lapply(files, read_dictionary)`;
    `audit_joins` calls `read_joins()` directly (result already has the
    value/problems shape audit_one used to build).
  - spec-run.R interim (dies in Task 8): read_dictionaries aggregates —
    `results <- lapply(files, read_dictionary)` + identity check, then
    `stop_spec(all problems)` if any stand; single-file paths likewise
    read then `stop_spec()` on problems. Behaviour note: run now reports
    problems across ALL files (was: first bad file) — snapshot diffs in
    run's error tests are expected and reviewed, not resisted; they
    preview Task 8's contract.
  - git mv utils-messages.R spec-problems.R (+ tests file rename);
    move no_problems/bind_problems in.
- [ ] **Step 4: Full suite; review every snapshot diff (aggregation-only
  changes); accept; `air format .`.**
- [ ] **Step 5: Commit** — `Readers return (value, problems): throw/catch removed; spec-problems.R consolidated`

### Task 5b: The collector — assembly without exception plumbing

**Files:**
- Create: `R/spec-collect.R`
- Modify: `R/spec-source.R` (check_table_identity moves OUT to
  spec-collect.R), `R/spec-run.R` (spec_set + layout paths move OUT to
  spec-collect.R), `tests/testthat/helper-spec.R` (promoted helpers)
- Test: `tests/testthat/test-spec-collect.R` (new)

**Interfaces:**
- Produces: `collect_spec_step(dir, joins = TRUE, file = NULL)` -> the
  outcome object exactly as previously specified (records with name/kind/
  certified/problems/value; certified; specs when certified; verb stamped
  by callers). Step-scope facts re-homed here: `spec_set()`,
  `spec_tables_dir()`, `spec_joins_path()`, `spec_joins_file`,
  `check_table_identity()`, plus new `intended_tables()`.
- Consumes: 5a's reader contract. NO tryCatch anywhere.

Semantics and the six tests: UNCHANGED from the pre-amendment Task 5
(every file visited; YX01 in both records; YX04 record for missing
expected joins; joins = FALSE; single-file mode; usage errors still
abort). Helper promotions as amended (spec_project/scrub_runstamp to
helper-spec.R on withr; break_file/record/expect_named_records new).
The collector body simplifies to:

```r
collect_spec_step <- function(dir, joins = TRUE, file = NULL) {
  if (!is.null(file)) {
    return(collect_one(dir, file))
  }
  files <- dictionary_files(spec_tables_dir(dir))
  read <- lapply(files, read_dictionary)
  loaded <- !vapply(read, \(r) is.null(r$value), logical(1))
  tables <- name_by_table(lapply(read[loaded], `[[`, "value"))
  identity <- check_table_identity(names(tables), files[loaded])
  failed_tables <- intended_tables(files[!loaded])
  records <- lapply(seq_along(files), \(i) {
    own <- rbind(
      read[[i]]$problems,
      identity[grepl(basename(files[[i]]), identity$file, fixed = TRUE), ]
    )
    new_record(basename(files[[i]]), "dictionary", own, read[[i]]$value)
  })
  if (joins) {
    records <- c(records, list(collect_joins(dir, tables, failed_tables)))
  }
  new_outcome(records)
}
```

with `new_outcome(records)` deriving certified internally (it owns the
rule), `collect_joins`/`collect_one`/`intended_tables`/`new_record` as
previously specified minus audit_one (readers give the shape directly;
collect_one reads then wraps, no tryCatch).

- [ ] **Step 1: helpers + the six failing tests** (as previously
  specified, reading `specs_example_copy()` per the amended note)
- [ ] **Step 2: verify failure** (collect_spec_step not found)
- [ ] **Step 3: implement spec-collect.R + the moves** (git-mv-style:
  function bodies unchanged for moved pieces)
- [ ] **Step 4: full suite green; `air format .`**
- [ ] **Step 5: Commit** — `collect_spec_step: the spec step assembled from pure readers; step-scope facts re-homed`

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
design mock `estimates.txt`. Same-second collision handling deliberately
NOT built — Liz 2026-07-19: runs under one second apart are out of
scope; a second run in the same second reuses the folder.)

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
  run_dir <- file.path(dir, sprintf("%s-%s", outcome$stage, runstamp()))
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
  `tempdir()` exactly as the current example does. MUST include the
  related-column definition as a named section, verbatim from the design
  doc's "User-facing definition" block (signed off by Liz 2026-07-19),
  via `@section The related column:` — rev_spec_run inherits it with
  `@inheritSection rev_spec_audit The related column` (Task 8).
  `devtools::document()`.

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

### Task 9b: related-column wording review (added 2026-07-19, Liz)

**Files:**
- Modify (as decided at the walkthrough): the related-phrase call sites
  (`R/utils-messages.R` relate_same_entry, `R/spec-source.R`
  resolve_references, `R/spec-collect.R` failed-tables closure), their
  tests/snapshots, and the design doc if wording changes.

Joint wording review with Liz — this task is a decision point by
construction; nothing is predecided except the questions:

- [ ] **Step 1: Review the shipped phrases against the help-doc
  definition.** Decide whether each cell should carry the self-contained
  scenario wording directly (no help lookup needed to act on it), e.g.
  "another error sits in this same entry — fixing it may clear this one"
  vs the current "other error in this entry". Liz decides the final
  strings; snapshots updated accordingly.
- [ ] **Step 2: Generalisation pass.** All related phrases move to one
  home (a small constructor set or registry beside the check registry),
  so a future rule adds one entry there instead of scattering strings —
  mirror of how check messages already live in checks.yaml. Assess
  whether checks.yaml itself is that home (a `related_template` field)
  or a code-side constant block suffices; present both, Liz picks.
- [ ] **Step 3: Apply, run full suite, update design doc wording if
  changed, commit** — `related wording: reviewed strings, single home`.

### Task 9c: test-structure review with Liz (added 2026-07-19, Liz)

A guided walkthrough of the suite as it stands after this branch, so its
structure is understood and deliberate, not inherited:

- [ ] **Step 1: Map the layers.** Walk through, with examples from the
  live suite: unit tests of constructors/helpers; the per-check matrix
  tests (one battery per code, driven from minimal_dict/minimal_join
  mutations); the single-defect fixture batteries and what their
  snapshots showcase; snapshot mechanics (_snaps/, when a diff is
  reviewed vs accepted, the every-code-snapshotted invariant in
  test-schema.R); the integration tests over audit/run; helper inventory
  (helper.R vs helper-spec.R, the withr idiom) and the fixtures/ folders.
- [ ] **Step 2: Liz's questions answered against real files**; any
  structural decisions she takes (renames, splits, conventions) recorded.
- [ ] **Step 3: Record the settled description** as a short Testing
  section in dev/conventions.md (structure + where new tests of each
  kind belong), committed for sign-off in the PR.

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

- [ ] **Step 3b: Adversarial battery over the new surface** — per the
  STANDING protocol (conventions.md §Testing, adopted 2026-07-13, first
  run 54 cases) with the 2026-07-19 upgrades: blind pack (rendered
  ?rev_spec_run / ?rev_spec_audit, design governing rule + mocks,
  example specs — no source, no tests) committed at
  dev/adversarial/spec-step-blind-pack-2026-07.md; TOOLLESS
  different-model agents, pack in-prompt; oracle-first (expected outcome
  + clause citation before execution); rotating lenses (naive user,
  language lawyer, hostile input, QA); UNDETERMINED routes to spec
  amendment; triage with Liz (bug / test gap / spec ambiguity / docs
  bug); no fixes during the run; adopted divergences become regression
  fixtures.

- [ ] **Step 4: Pre-push suite** (dev/conventions.md, run all):
  `air format .`; `Rscript -e 'pkgload::load_all(quiet = TRUE); lintr::lint_package()'`
  (expect 0 lints); `Rscript -e 'devtools::test()'` (expect 0 failures);
  `Rscript -e 'devtools::check()'` (expect 0 errors / 0 warnings / 0 notes).

- [ ] **Step 5: Two-tier review (scope settled with Liz, 2026-07-19).**
  Tier 1, diff-scoped: /code-review (correctness) and /simplify
  (quality) over the full branch diff. Tier 2, repo-wide structural
  audit: every R/ and tests/ file read as one system and audited
  AGAINST conventions.md SECTION BY SECTION — Terminology (retired
  words grep), Style & formatting, Naming, Linting, Testing (layers,
  invariants, snapshot gates), Documentation, Dependencies, Design,
  the Single-source-of-truth inventory item by item (plus any new
  single-home fact this branch created), Git — and against the design
  spec and .claude/CLAUDE.md for code-vs-docs consistency. Findings
  triaged with Liz: small-and-in-scope fixed in-branch with
  walkthrough; real-but-out-of-scope logged explicitly, never silently
  absorbed. A principle worth checking that conventions.md does not
  record is itself a finding: proposed to Liz as a conventions
  addition.

- [ ] **Step 6: Commit** — `Spec amendment + NEWS: per-file report machinery, run/audit contract` —
  then hand to Liz: fetch, review PR (deliverable + amendment together),
  squash-merge on green CI.
