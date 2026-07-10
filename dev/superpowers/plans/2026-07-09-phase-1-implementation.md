# Phase 1 — Spec Machinery + Stages 1–3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (Liz's
> standing preference: checkpointed mode, check in at every checkpoint) to implement
> this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

- **Status:** SIGNED OFF (Liz, 2026-07-09) with amendments through commit d038c87,
  and with this **binding execution protocol**: Liz reviewed the front matter and
  task sequence but not the in-plan code in depth, so execution is
  **walkthrough-gated per task** — before starting each task, explain what it will
  do and broadly (not line-by-line) how the code works and why it was chosen; give
  Liz a turn to read the explanation alongside the plan step and code; **begin the
  task only on her explicit confirmation**. Checkpointed in-session execution
  (superpowers:executing-plans), never autonomous batching.
- **Pre-flight:** run 2026-07-09 post-sign-off. Verdict: **proceed after one
  amendment**. Findings:
  1. **Task 14 / embedded decision 8 — CONFIRMED DEFECT, RESOLVED (Liz,
     2026-07-10):** pkgdown 2.2.0 has no `.md`-exclusion config; its
     `package_mds()` uses a hardcoded skip-list only (verified by reading the
     installed function source). Resolution: relocate `CLAUDE.md` to
     `.claude/CLAUDE.md` (see embedded decision 8). An interim post-build-prune
     proposal and a permanent set-based acceptance check were considered and
     dropped (superseded / YAGNI).
  2. Packages already present in the project library: yaml, dplyr, stringi, cli,
     rlang, tibble (+ toolchain). **To install in Task 1: readr, readxl, writexl,
     tidyr** — consistent with the plan (renv::install is idempotent for the rest).
  3. Routes green: PPM reachable (400 at bare root = expected), GitHub reachable
     (use_standalone source), git identity correct, R 4.6.1 / Air 0.10.0 present,
     DESCRIPTION floor R >= 4.2 matches spec, no Imports yet (skeleton state),
     family workbook present in the host mount for the fixtures-local copy.
- **Execution amendment (2026-07-10, during Task 1; SIGNED OFF, Liz 2026-07-10):**
  the r-lib standalone vendoring is DROPPED. Task 1 execution found the standalone's
  upstream changelog (2026-03-17) moved `check_bool()`, `check_string()`, and
  `check_data_frame()` out of the standalone file into rlang's own exports (verified
  present in installed rlang 1.3.0). Per conventions ("depend / vendor / write it" —
  depend first): no vendored files; the three checkers are called qualified
  (`rlang::check_string()` etc.); rlang floor raised to >= 1.3.0. `%||%` stays and is
  imported via `@importFrom rlang "%||%"` — the package's sole namespace import
  (infix operators cannot be namespace-qualified; ecosystem-standard exception,
  recorded as a closed rule in dev/conventions.md). Task 1 Step 3's gate restated:
  0 errors / 0 warnings / exactly one expected NOTE (declared-but-not-yet-used
  Imports), which shrinks as Tasks 2-13 land code and must be gone at Task 14's
  error_on = "note" pre-push gate. Also fixed: "nine Imports" miscount (ten).
- **Execution amendment 2 (2026-07-10, before Task 2; SIGNED OFF, Liz 2026-07-10):**
  `abort_spec()` renamed `stop_spec()` (Liz's preference; `stop_` is the
  base-R-familiar error-constructor prefix, per rlang/vctrs convention). Zebra
  assertion strengthened to `expect_identical(..., NA_character_)` (pins the typed
  NA). Problem-line formatting vectorised (`sprintf` over whole columns) in place
  of row-wise `vapply` — simpler and idiomatic; performance immaterial on the
  error path.
- **Execution amendment 3 (2026-07-10, before Task 3; SIGNED OFF, Liz 2026-07-10):**
  design change from Liz's walkthrough review, replacing the name-only
  acknowledgment concept entirely. (a) **The dictionary declares exactly the
  columns the user imports, checks, and uses**: `type` becomes required per
  column (generalised Y017 — same helper, second call site). (b) **R006 is
  retired**: source columns absent from the dictionary are never findings — they
  carry no consequence; `rev_read_table()` returns them as `unspecified`,
  `rev_check()` reports them informationally, the certificate lists them as an
  annex, and pipeline artifacts drop them until declared (list-and-drop). R005
  is unchanged. (c) **Y012 extended** to missing (not just duplicate/empty)
  column names — `name` is the entry's identity. (d) **Y020 defined**: a field
  declared with no value (YAML NULL) is an error, not a silent absence;
  `description` exempt (draft skeletons carry empty descriptions by design).
  (e) `rev_read_dictionary()` gains a missing-file guard aborting with class
  `revpiper_spec_error` (raw `yaml::read_yaml()` connection errors violate the
  error doctrine for an exported function). (f) The `acknowledged` column leaves
  `rev_dictionary`; the good fixture's `notes_temp` gains `type: text`; Tasks 6,
  9, and 12 adjusted accordingly. Design-spec §3.1/§3.4 amended in the same
  commit (rides the phase-1-core PR, like decision 1's §4 amendment).
- **Source of truth:** dev/superpowers/specs/2026-07-07-revpiper-design.md
  (as amended through 2026-07-09). Rationale trail:
  dev/superpowers/plans/2026-07-08-phase-1-planning-notes.md.

**Goal:** Implement revpiper's spec machinery and pipeline stages 1–3 — per-table
dictionaries, joins spec, readers, standardisation, per-table validation, joins with
J-checks, the consequence-based findings object with certification, `rev_check()`,
and the minimal dictionary draft generator — fully TDD'd, CI green.

**Architecture:** Functional core; one file per topic (provisional layout, spec §5);
S3 for `rev_dictionary`, `rev_findings`, `rev_certificate`. All input read as
character; types exist only via declared coercion (prespecify-then-check). Findings
carry consequences, never severities; certification = zero standing findings, with
explicit acknowledgment declarations the only pass.

**Tech Stack:** R (4.2 floor), yaml, readxl, writexl, dplyr, tidyr, stringi, cli,
rlang (>= 1.3.0, supplying the entry-point type checkers); testthat 3e (parallel,
snapshots).

## Global Constraints (spec §2; every task implicitly includes these)

- R floor **4.2**; native pipe `|>` and `\(x)` fine; no base `%||%` (needs R >= 4.4)
  — use rlang's, imported via `@importFrom rlang "%||%"` in `R/revpiper-package.R`,
  the package's sole namespace import; every other external call is qualified
  `pkg::fun()`.
- Tidyverse style via **Air** (never hand-format); **zero lints** (`lintr::lint_package()`).
- **TDD strictly**: failing test first, minimal code, watch pass, commit.
- **Mirror rule**: every `R/` file gets `tests/testthat/test-<name>.R`.
- Exports prefixed **`rev_`**; internals unprefixed; snake_case; first arg = data/project path.
- **No `library()` in `R/`**; messages via **cli** only; user-facing message wording
  **snapshot-tested**.
- Errors: spec errors point at file+entry (+did-you-mean); data problems become
  findings; only internal bugs traceback.
- Nothing user-facing named "clean" before certification (stage-2 artifact =
  `preprocessed-<table>`).
- Commits: plain imperative; **one branch for this phase** (`phase-1-core`), tasks =
  squash-mergeable commits; sandbox NEVER pushes; NEWS.md bullet included (Task 14).
- Package installs: **PPM binaries only** (options set in Task 1 command); on any
  network-policy block, STOP and report the domain.
- Pre-push suite before declaring the branch ready: `air format .`,
  `lintr::lint_package()`, `devtools::test()`, `devtools::check()` (all clean).

## Decisions embedded in this plan (for sign-off with the plan)

1. **`rev_check()` writes diagnostics.** Spec §4 says rev_check "writes nothing";
   D4's findings row numbers reference `preprocessed-<table>` artifacts. Resolved:
   rev_check writes ONLY under `output/diagnostics/` (`preprocessed-<table>.csv`,
   `findings-<runstamp>.xlsx`) — never pipeline artifacts, never `data/raw/`. "Always
   safe" is preserved; the row numbers users see are inspectable. Spec §4 gets a
   one-line amendment when this plan is signed off.
2. **New Imports** (each justified per Area 7, logged here + in the commit):
   `yaml` (spec files; the maintained R YAML parser), `readr` (CSV ingestion:
   platform-independent UTF-8/BOM handling — a core behaviour, since encoding
   correctness is a product feature and users skew Windows; type-guessing disabled
   via all-character cols), `readxl` (Excel ingestion, `.xls` AND `.xlsx`
   auto-detected; de-facto standard, no Java), `writexl` (findings export;
   zero-dependency, already spec-logged §3.7), `dplyr` + `tidyr` (joins with `relationship` enforcement;
   covidence pivot; Area 7 pre-approves), `stringi` (Unicode NFC + space/format-char
   classes — base R cannot NFC-normalise), `cli` (messages; first-logged dependency),
   `rlang` (`%||%`, abort classes, entry-point type checkers `check_string()` /
   `check_bool()` / `check_data_frame()` exported since 1.3.0 — hence the floor;
   cli dependency anyway), `tibble` (comes with dplyr).
3. **All raw ingestion is character.**
   `readr::read_csv(col_types = readr::cols(.default = readr::col_character()))` /
   `readxl::read_excel(col_types = "text")`: types exist only through declared
   coercion, so nothing is guessed before the dictionary speaks. Extension dispatch:
   `.csv` → readr; `.xls`/`.xlsx` → readxl (auto-detects format).
4. **The dictionary lists exactly the columns of interest** (amendment 3;
   supersedes the name-only acknowledgment concept): every entry requires
   `type`; declared columns must exist (R005), are imported, standardised,
   checked, and used. Source columns not declared are surfaced informationally
   (`unspecified` list, certificate annex) and dropped from pipeline artifacts —
   never findings, never silently absorbed.
5. **Boolean coercion accepts** exactly TRUE/FALSE (case-insensitive); **date** =
   strict ISO `YYYY-MM-DD`. Everything else is V001.
6. **Shipped reader registry v1** = `covidence` + the generic csv/excel readers;
   user readers resolve from `readers.R` sourced into an isolated environment.
7. **Draft generator lands here (Task 13)** — schema-coupled, and we need it for the
   Phase 4 dress rehearsal.
8. **pkgdown README+NEWS-only** (Task 14, resolved by relocation — Liz 2026-07-10):
   `CLAUDE.md` moves to `.claude/CLAUDE.md` (documented, equally-supported Claude
   Code project-instruction location, verified against code.claude.com docs
   2026-07-10; pkgdown's `package_mds()` scans only the repo root and `.github/`,
   so `.claude/` never enters the site). No exclusion config, no build wrapper, no
   permanent custom acceptance check (dropped as YAGNI — post-move, our top-level
   `.md` set is the ecosystem-standard one). One-time verification at execution
   only. Supersedes both the `home: exclude` mechanism (doesn't exist in pkgdown
   2.2.0) and the interim post-build-prune proposal.

## File map (provisional layout per spec §5)

| File | Responsibility | Test twin |
|---|---|---|
| `R/utils-messages.R` | spec-error formatting, did-you-mean, cli wrappers | `tests/testthat/test-utils-messages.R` |
| `R/spec-dictionary.R` | load/validate `specs/tables/<t>.yaml` → `rev_dictionary` (Y-checks) | `test-spec-dictionary.R` |
| `R/spec-joins.R` | load/validate `specs/joins.yaml` (Y-checks vs dictionaries) | `test-spec-joins.R` |
| `R/read.R` | generic csv/xlsx readers, reader dispatch, R-checks | `test-read.R` |
| `R/read-covidence.R` | Covidence all-data CSV importer | `test-read-covidence.R` |
| `R/standardise.R` | five ops + composed keys + counts log | `test-standardise.R` |
| `R/findings.R` | `rev_findings`, consequences, print, xlsx export, certificate | `test-findings.R` |
| `R/validate.R` | V-checks per table | `test-validate.R` |
| `R/join.R` | join execution + J-checks + near-miss suggestions | `test-join.R` |
| `R/check.R` | `rev_check()` orchestration + diagnostics output | `test-check.R` |
| `R/draft.R` | `rev_draft_dictionary()` | `test-draft.R` |

## Check catalogue, routing, and data-dict coverage (plan deliverable)

Consequence constants: `not certifiable` (every finding, always) plus, where
mechanical: `join '<left>-<right>' skipped`; `dependent checks on '<column>' not run`.

### Y — spec validation (parse time; these ABORT with all problems listed, file+entry)

| Code | Check | Fix routes to |
|---|---|---|
| Y001 | unknown field name (with did-you-mean, `utils::adist` ≤ 2) | named spec file + entry |
| Y002 | unknown `type` (not text/integer/decimal/boolean/date) | column entry |
| Y003 | `values` and `range` both present on one column | column entry |
| Y004 | `values` on boolean/date | column entry |
| Y005 | `range` on text/boolean | column entry |
| Y006 | `units` on non-integer/decimal | column entry |
| Y007 | mixed-type or empty `values` list; `range` not length-2 of column's type | column entry |
| Y008 | descending `range` | column entry |
| Y009 | role names unknown column, or invalid `combine` (unknown/duplicate/empty parts, missing separator) | roles block |
| Y010 | `levels` key names unknown column | levels block |
| Y011 | `constant_within_level` names an undeclared level | column entry |
| Y012 | duplicate, empty, or missing column name within a table | columns block |
| Y013 | duplicate table name across `specs/tables/*.yaml` | the two files named |
| Y014 | join references unknown table | joins.yaml entry |
| Y015 | join `keys` reference unknown column (roles-block combined keys count as known) | joins.yaml entry |
| Y016 | `relationship` not one-to-one/one-to-many; `granularity` not a declared level of the "one" side; `unmatched_ok` not boolean | joins.yaml entry |
| Y017 | missing required field (top level: `table`, `source`, `columns`; per column: `type`) | spec file / column entry |
| Y018 | `reader` neither shipped nor a function in `readers.R` | source block / readers.R |
| Y019 | `source.file` missing from source block | source block |
| Y020 | field declared with no value (YAML NULL; `description` exempt — draft skeletons carry empty descriptions) | the named entry |

### R — reading/structure (findings; consequence: table skipped → its joins skipped; not certifiable)

| Code | Check | Fix routes to |
|---|---|---|
| R001 | `source.file` does not exist | source block / file placement |
| R002 | declared `sheet` absent from workbook | source block |
| R003 | reader errored (error text relayed) | readers.R / source block |
| R004 | reader returned non-data-frame | readers.R |
| R005 | declared column absent from data | dictionary vs re-export |
| R006 | *retired (amendment 3)* — undeclared source columns are informational, never findings: returned as `unspecified`, reported by `rev_check()`, listed on a certificate annex, dropped from pipeline artifacts | add to the dictionary if wanted |

### V — per-table validation (findings; per column/rows)

| Code | Check | Consequence beyond "not certifiable" | Fix routes to |
|---|---|---|---|
| V001 | value(s) not coercible to declared type | `dependent checks on '<col>' not run`; column stays text | `missing:` declaration or corrections |
| V002 | value not in declared `values` | — | corrections, or add to `values:` |
| V003 | value outside declared `range` | — | corrections, or widen `range:` |
| V004 | `required` column has missing | if a join key: that join skipped | corrections / source data |
| V005 | `unique` violated | — | corrections |
| V006 | `constant_within_level` violated | — | **dual route**: corrections (transcription error) OR add a level key (undeclared substructure) |

### J — combination (findings)

| Code | Check | Consequence | Fix routes to |
|---|---|---|---|
| J001 | join-key column has missing values | that join skipped | corrections |
| J002 | "one"-side keys not unique at declared granularity | that join skipped | corrections / joins.yaml granularity |
| J003 | declared relationship violated at execution | that join skipped | joins.yaml / corrections |
| J004 | unmatched left rows (near-miss suggestions, `adist` ≤ 2 case-insensitive) | not certifiable unless `unmatched_ok` | corrections / finish extraction / `unmatched_ok: true` |
| J005 | unmatched right rows (ditto) | ditto | ditto |

### C — corrections application (codes reserved; engine = Phase 2)

C001 predicate match-count mismatch; C002 expected-old-value mismatch; C003 stale
correction (matches nothing). Fix routes to the corrections.csv entry named.

### data-dict coverage mapping (every S/M/D check accounted for)

| data-dict | Ours | Status |
|---|---|---|
| S01 unresolved FK | — | N/A: no `foreign_key` constraint in v1 (joins declare keys; Y014/Y015) |
| S02 unknown table | Y014 | adopted |
| S03 unknown column | Y015 | adopted |
| S04 invalid join expr | Y015/Y016 | adapted (structured keys, not expressions) |
| S05 unresolved conflict col | — | N/A: no `conflicts` field v1; overlapping non-key columns get dplyr suffixes + unspecified-columns visibility |
| S06 inconsistent cardinality | Y016 + J002/J003 | adapted (declared vs constraint consistency checked at data level) |
| S07 wrong representation key | Y003–Y005 | adapted (values/range optionality per type) |
| S08 units w/o quantity | Y006 | adopted |
| S09 missing $learn_more | — | N/A: no counterpart field |
| S10 duplicate name | Y012/Y013 | adopted |
| S11 empty name | Y012 | adopted (folded) |
| S12 wrong value type | Y007 | adopted |
| S13 descending range | Y008 | adopted |
| S14/S15 time zone | — | N/A: datetime dropped from v1 |
| S16 misplaced single-table description | — | N/A: per-table files by design |
| S17 malformed version | — | N/A: data-version field not adopted; provenance stamped by pipeline (§3.8) |
| S18 missing $version | — | N/A: schema versioning deferred to first breaking change |
| M01 type mismatch | V001 | adapted (coercion-based) |
| M02 missing column | R005 | adopted |
| M03 undocumented column | — | adapted (amendment 3): informational unspecified-columns listing, not a finding |
| M04 missing source | Y017/Y019 | adopted |
| M05 unreadable source | R001–R004 | adopted + extended (readers) |
| D01 nulls in required | V004 | adopted |

---

### Task 1: Dependencies, namespace, branch

**Files:**
- Modify: `DESCRIPTION` (Imports; rlang floored >= 1.3.0)
- Modify: `R/revpiper-package.R` (`@importFrom rlang "%||%"`) + regenerated `NAMESPACE`
- Modify: `renv.lock` (snapshot)

**Interfaces:** Produces the Imports every later task assumes; entry-point
validation uses rlang's exported checkers, called qualified —
`rlang::check_string()`, `rlang::check_bool()`, `rlang::check_data_frame()`
(exported since the 2026-03 standalone migration; floor 1.3.0 verified) — plus
`%||%`, the sole namespace import.

- [ ] **Step 1: branch.** `git checkout -b phase-1-core main`
- [ ] **Step 2: add Imports** (PPM binaries only; belt-and-braces UA line):

```r
Rscript -e 'options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version["platform"], R.version["arch"], R.version["os"]))); renv::install(c("yaml","readr","readxl","writexl","dplyr","tidyr","stringi","cli","rlang","tibble"), repos = sub("CODENAME", system("lsb_release -cs", intern = TRUE), "https://packagemanager.posit.co/cran/__linux__/CODENAME/latest"))'
Rscript -e 'usethis::local_project("."); usethis::use_package("yaml"); usethis::use_package("readr"); usethis::use_package("readxl"); usethis::use_package("writexl"); usethis::use_package("dplyr"); usethis::use_package("tidyr"); usethis::use_package("stringi"); usethis::use_package("cli"); usethis::use_package("rlang", min_version = "1.3.0"); usethis::use_package("tibble")'
Rscript -e 'renv::snapshot(prompt = FALSE)'
```

Then add the operator import to `R/revpiper-package.R` (between the usethis
namespace markers) and regenerate NAMESPACE:

```r
## usethis namespace: start
#' @importFrom rlang %||%
## usethis namespace: end
```

`Rscript -e 'devtools::document()'`

Expected: all binary installs (report any source compile and PAUSE); DESCRIPTION
gains ten Imports with `rlang (>= 1.3.0)`; NAMESPACE gains
`importFrom(rlang,"%||%")`. No vendored files (amendment 2026-07-10: upstream
moved the needed checkers into rlang's exports).
- [ ] **Step 3: verify check.** `Rscript -e 'devtools::check(args = "--no-manual", build_args = "--no-manual", error_on = "warning")'` →
  0 errors / 0 warnings / exactly one NOTE ("Namespaces in Imports field not
  imported from" — the declared-but-not-yet-used packages). The note is expected
  and shrinks as Tasks 2-13 land code; Task 14 Step 4's `error_on = "note"` gate
  requires it gone.
- [ ] **Step 4: commit** with the dependency justifications (from "Decisions embedded" #2) in the body.

### Task 2: Spec-error infrastructure (`utils-messages.R`)

**Files:** Create `R/utils-messages.R`, `tests/testthat/test-utils-messages.R`

**Interfaces — Produces:**
- `suggest_name(name, known)` → closest of `known` within adist ≤ 2 (case-insensitive) or `NA_character_`
- `spec_problem(file, entry, code, message, suggestion = NULL)` → one-row problem tibble
- `stop_spec(problems)` → `cli_abort` (class `revpiper_spec_error`) listing every problem as `code file / entry: message (did you mean ...?)`

- [ ] **Step 1: failing tests**

```r
# tests/testthat/test-utils-messages.R
test_that("suggest_name finds near misses and refuses far ones", {
  expect_equal(suggest_name("descrption", c("description", "type")), "description")
  expect_equal(suggest_name("VALUES", c("values", "range")), "values")
  expect_identical(suggest_name("zebra", c("description", "type")), NA_character_)
})

test_that("stop_spec reports every problem with file, entry, and code", {
  p <- rbind(
    spec_problem("specs/tables/estimates.yaml", "column 'mean_age'", "Y001",
                 "unknown field 'rnge'", suggestion = "range"),
    spec_problem("specs/joins.yaml", "join 1", "Y014", "unknown table 'robb'",
                 suggestion = "rob")
  )
  expect_error(stop_spec(p), class = "revpiper_spec_error")
  expect_snapshot(error = TRUE, stop_spec(p))
})
```

- [ ] **Step 2: run, expect FAIL** — `Rscript -e 'devtools::test(filter = "utils-messages")'` → objects not found.
- [ ] **Step 3: implement**

```r
# R/utils-messages.R
suggest_name <- function(name, known) {
  d <- utils::adist(tolower(name), tolower(known))[1, ]
  if (min(d) <= 2) known[which.min(d)] else NA_character_
}

spec_problem <- function(file, entry, code, message, suggestion = NULL) {
  tibble::tibble(
    file = file, entry = entry, code = code, message = message,
    suggestion = suggestion %||% NA_character_
  )
}

stop_spec <- function(problems) {
  hint <- ifelse(is.na(problems$suggestion), "",
                 sprintf(" (did you mean '%s'?)", problems$suggestion))
  lines <- sprintf("%s %s / %s: %s%s",
                   problems$code, problems$file, problems$entry, problems$message, hint)
  names(lines) <- rep("x", length(lines))
  cli::cli_abort(
    c("Spec validation failed ({nrow(problems)} problem{?s}):", lines),
    class = "revpiper_spec_error", call = NULL
  )
}
```

- [ ] **Step 4: run, expect PASS**; accept the message snapshot after reading it.
- [ ] **Step 5:** `air format . && Rscript -e 'lintr::lint_package()'` (0 lints) → commit.

### Task 3: Dictionary loading + field/type Y-checks (`spec-dictionary.R`, part 1)

**Files:** Create `R/spec-dictionary.R`, `tests/testthat/test-spec-dictionary.R`,
fixtures under `tests/testthat/fixtures/specs-good/tables/estimates.yaml` and
`fixtures/specs-bad/…` (one bad yaml per Y-code exercised).

**Interfaces — Produces:**
- `rev_read_dictionary(path)` → `rev_dictionary`: list(`table` chr, `description` chr,
  `source` list(file, sheet = NULL, reader = NULL), `roles` named list (chr column or
  list(combine = chr(), separator = chr)), `levels` named list of chr(),
  `columns` tibble(name, type, values <list>, range <list>, units, required, unique,
  missing <list>, constant_within_level, description), `path` chr)
  — or `stop_spec()` listing ALL problems.
- Constants: `spec_types <- c("text","integer","decimal","boolean","date")`,
  `dict_fields`, `column_fields`, `source_fields` (closed field sets).

Good fixture (used across later tasks — keep exactly):

```yaml
# tests/testthat/fixtures/specs-good/tables/estimates.yaml
table: estimates
description: One row per extracted estimate.
source:
  file: data/raw/estimates.csv
roles:
  study_id: study
levels:
  study: [study]
columns:
  - name: study
    type: text
    required: true
  - name: design
    type: text
    values: [RCT, Cohort]
  - name: mean_age
    type: decimal
    range: [10, 60]
    units: years
    constant_within_level: study
    missing: ["NR"]
  - name: rob_score
    type: integer
    values: [1, 2, 9]
  - name: notes_temp
    type: text
```

- [ ] **Step 1: failing tests** — parse the good fixture and assert every slot above
  (types, values list, defaults); then one `expect_snapshot(error =
  TRUE, rev_read_dictionary(<bad fixture>))` per bad fixture: unknown top-level field
  (Y001 with suggestion), unknown column field (Y001), bad type (Y002), values+range
  together (Y003), values on date (Y004), range on text (Y005), units on text (Y006),
  mixed values `[1, two]` (Y007), descending range (Y008), duplicate column (Y012),
  column entry with no `name` (Y012), column entry with no `type` (Y017 per column),
  a valueless field e.g. bare `range:` (Y020), missing `source:` (Y017), missing
  `source.file` (Y019). Write each bad yaml fixture as a minimal copy of the good
  one with the single defect. Plus one non-fixture case: a nonexistent path →
  snapshot of the classed missing-file error (amendment 3).
- [ ] **Step 2: run, expect FAIL.**
- [ ] **Step 3: implement.** Structure (complete the per-check helpers following
  these two models — every check appends `spec_problem()` rows, nothing aborts until
  the end):

```r
# R/spec-dictionary.R
spec_types <- c("text", "integer", "decimal", "boolean", "date")
dict_fields <- c("table", "description", "source", "roles", "levels", "columns")
source_fields <- c("file", "sheet", "reader")
column_fields <- c("name", "type", "values", "range", "units", "required",
                   "unique", "missing", "constant_within_level", "description")

rev_read_dictionary <- function(path) {
  rlang::check_string(path)
  if (!file.exists(path)) {
    cli::cli_abort(
      "Dictionary file {.file {path}} does not exist.",
      class = "revpiper_spec_error", call = NULL
    )
  }
  raw <- yaml::read_yaml(path)
  pr <- rbind(
    check_known_fields(raw, dict_fields, path, "top level"),
    check_required_fields(raw, c("table", "source", "columns"), path),   # Y017
    check_source_block(raw$source, path),                                # Y001/Y019
    check_columns_block(raw$columns, path)                               # Y001-Y008, Y012
  )
  if (nrow(pr) > 0) stop_spec(pr)
  new_dictionary(raw, path)
}

check_known_fields <- function(x, known, file, entry) {          # -> Y001 rows
  bad <- setdiff(names(x), known)
  do.call(rbind, c(list(spec_problem(file, entry, "Y001", character(0))[0, ]),
    lapply(bad, \(f) spec_problem(file, entry, "Y001",
      sprintf("unknown field '%s'", f), suggestion = suggest_name(f, known)))))
}

check_column <- function(col, file) {                            # one column's checks
  entry <- sprintf("column '%s'", col$name %||% "<unnamed>")
  pr <- rbind(
    check_known_fields(col, column_fields, file, entry),         # Y001
    check_required_fields(col, "type", file, entry),             # Y017 (per column)
    check_empty_fields(col, file, entry)                         # Y020 (description exempt)
  )
  if (!is.null(col$values) && !is.null(col$range))               # Y003: type-independent, so pre-return
    pr <- rbind(pr, spec_problem(file, entry, "Y003", "'values' and 'range' are mutually exclusive"))
  if (is.null(col$type)) return(pr)                              # type-DEPENDENT checks need a type
  if (!col$type %in% spec_types)
    pr <- rbind(pr, spec_problem(file, entry, "Y002",
      sprintf("unknown type '%s'", col$type), suggest_name(col$type, spec_types)))
  if (!is.null(col$values) && isTRUE(col$type %in% c("boolean", "date")))
    pr <- rbind(pr, spec_problem(file, entry, "Y004", sprintf("'values' is not allowed on type '%s'", col$type)))
  if (!is.null(col$range) && isTRUE(col$type %in% c("text", "boolean")))
    pr <- rbind(pr, spec_problem(file, entry, "Y005", sprintf("'range' is not allowed on type '%s'", col$type)))
  if (!is.null(col$units) && !isTRUE(col$type %in% c("integer", "decimal")))
    pr <- rbind(pr, spec_problem(file, entry, "Y006", "'units' is only allowed on integer/decimal"))
  pr <- rbind(pr, check_values_range_types(col, file, entry))    # Y007, Y008
  pr
}
```

plus `check_values_range_types()` (homogeneous non-empty values matching the declared
type; range length-2, ascending, type-matching → Y007/Y008), `check_columns_block()`
(maps `check_column`, adds Y012 for duplicate/empty/missing names), `check_source_block()`
(Y001 on unknown source fields, Y019), `check_required_fields()` (Y017; called at the
top level and per column entry), `check_empty_fields()` (Y020: any field present with
a NULL value, `description` exempt), and `new_dictionary()` (tibble-ise columns;
defaults: required/unique FALSE, missing = list(character(0))).
- [ ] **Step 4: run, expect PASS** (accept snapshots after reading each).
- [ ] **Step 5:** format, lint, commit.

### Task 4: Cross-reference Y-checks (roles/levels/combine; multi-file) (`spec-dictionary.R`, part 2)

**Files:** Modify `R/spec-dictionary.R`; extend `test-spec-dictionary.R` + bad fixtures.

**Interfaces — Produces:**
- `rev_read_dictionaries(dir)` → named list of `rev_dictionary` (reads
  `<dir>/tables/*.yaml`; adds cross-file Y013)
- Within-file additions to `rev_read_dictionary()`: Y009 (roles: unknown column /
  invalid combine — unknown or duplicate parts, missing separator; a valid combine
  registers a **virtual column** named by the role), Y010 (level keys must be
  declared or virtual columns), Y011 (`constant_within_level` names a declared level).
- `dictionary_key_columns(dict)` → chr of all real+virtual columns usable as keys.

- [ ] **Step 1: failing tests** — good fixture with
  `study_id: {combine: [author, year], separator: "_"}` parses and
  `dictionary_key_columns()` includes `study_id`; bad fixtures for Y009 (combine
  names unknown column; duplicate parts; missing separator), Y010, Y011, and a
  two-file fixture dir with duplicate `table:` names for Y013 via
  `rev_read_dictionaries()`. Snapshot each error.
- [ ] **Step 2: run, expect FAIL.**
- [ ] **Step 3: implement** (`check_roles_block()`, `check_levels_block()`,
  `check_cwl()` appended into `rev_read_dictionary`'s problem collection;
  `rev_read_dictionaries()` = `lapply` + Y013 scan over `vapply(dicts, \(d) d$table, "")`).
- [ ] **Step 4: run, expect PASS.**  - [ ] **Step 5:** format, lint, commit.

### Task 5: Joins spec (`spec-joins.R`)

**Files:** Create `R/spec-joins.R`, `tests/testthat/test-spec-joins.R`, fixtures
`fixtures/specs-good/joins.yaml` + bad variants.

Good fixture:

```yaml
# tests/testthat/fixtures/specs-good/joins.yaml
joins:
  - left: estimates
    right: rob
    keys:
      estimates: [study]
      rob: [study_id]
    granularity: study
    relationship: one-to-many
    unmatched_ok: false
```

(Requires a second good table fixture `fixtures/specs-good/tables/rob.yaml`: table
`rob`, source file `data/raw/rob.csv`, columns `study_id` (text, required) +
`rob_direct` (text, values [low, high]); levels `study: [study_id]`.)

**Interfaces — Produces:**
- `rev_read_joins(path, dictionaries)` → tibble(left, right, keys_left <list chr>,
  keys_right <list chr>, granularity, relationship, unmatched_ok) with Y-checks:
  Y001 (unknown fields), Y014 (unknown table), Y015 (key not in
  `dictionary_key_columns()` of its side), Y016 (bad relationship / granularity not a
  declared level of the "one" side / non-boolean unmatched_ok). Missing joins.yaml →
  zero-row tibble (single-table projects are valid).

- [ ] **Steps 1–5:** failing tests (good parse incl. defaults `unmatched_ok = FALSE`;
  snapshot per bad fixture; absent file → zero rows), watch fail, implement
  (`check_join_entry()` per join, same problem-collection pattern), watch pass,
  format+lint, commit.

### Task 6: Generic readers + dispatch + R-checks (`read.R`)

**Files:** Create `R/read.R`, `tests/testthat/test-read.R`, fixtures
`fixtures/miniproject/data/raw/estimates.csv` and `rob.csv` (write them to match the
good dictionaries: estimates = columns study, design, mean_age, rob_score, notes_temp,
extra_col with 5 rows incl. one "NR" mean_age, one "rct" design, one out-of-range 340,
duplicate study values; rob = study_id, rob_direct, 3 rows, one study_id absent from
estimates). Also: add `tests/testthat/fixtures-local/` to `.gitignore` (real-data
fixtures live there, NEVER committed — decision Liz 2026-07-09, option 3: local-only
skip-if-absent now; committed synthetic derivative belongs to Phase 3's designed
synthetic review).

**Interfaces — Produces:**
- `rev_read_table(dict, project)` → list(`data` = all-character tibble | NULL
  (declared columns only, amendment 3), `findings` = rev_findings-shaped tibble
  (Task 9 constructor not yet available — return `fnd_stub()` rows: plain tibble
  with the findings columns; Task 9 swaps the constructor in one place),
  `unspecified` = chr of source columns not in the dictionary)
- Internal: `read_generic(source, project)` (`.csv` via
  `readr::read_csv(col_types = readr::cols(.default = readr::col_character()),
  show_col_types = FALSE)`; `.xls`/`.xlsx` via
  `readxl::read_excel(col_types = "text")`; extension dispatch; R001/R002), `resolve_reader(source,
  project)` (NULL → generic; "covidence" → registry; else function named in
  `readers.R`, sourced via `source(local = new.env())`; unknown → Y018 abort),
  R003/R004 wrapping, R005 against `dict$columns`; source columns absent from the
  dictionary go to `unspecified` and are dropped from `data` (amendment 3).

- [ ] **Steps 1–5:** failing tests (good read returns a 5×5 character tibble of the
  declared columns, with `extra_col` in `unspecified` and absent from `data`, no
  finding; missing file → R001 finding row + NULL data; missing declared column →
  R005; erroring user reader → R003 carrying the error text), watch fail, implement,
  watch pass, format+lint, commit.
- [ ] **Step 6: local real-workbook breadth test (skip-if-absent).** In
  `test-read.R`, guarded by
  `skip_if_not(file.exists(test_path("fixtures-local", "family-comparison.xlsx")))`:
  read the workbook's `"Results and characteristics"` sheet through the generic Excel
  reader (`skip = 2`, so row 3 supplies names) and through a test-local reader
  function exercising the user-reader contract:

```r
family_wide_test_reader <- function(path, sheet) {
  raw <- readxl::read_excel(path, sheet = sheet, skip = 2, col_types = "text")
  tidyr::pivot_longer(raw, cols = dplyr::matches("^(Unadjusted|Adjusted)"),
                      names_to = c("adjustment", ".value"), names_sep = "_")
}
```

  Assertions: generic read yields > 10 rows and > 40 all-character columns with
  non-empty names; the test reader returns a data frame with an `adjustment` column
  and more rows than the sheet. (Exact column patterns to be trued against the real
  file during TDD — the test is written by first LOOKING at the file, which the
  executing session has at `/run/sandbox/source/working/refs/`; copy it to
  `tests/testthat/fixtures-local/family-comparison.xlsx` as part of this step.)
  Expected in CI / repos without the file: SKIPPED, suite green.

### Task 7: Covidence importer (`read-covidence.R`)

**Files:** Create `R/read-covidence.R`, `tests/testthat/test-read-covidence.R`,
fixture `tests/testthat/fixtures/covidence-dummy.csv` — **copy the dummy export**
(`working/refs/review_154081_extracted_all_data_csv_20260708215907.csv`, confirmed
dummy by Liz 2026-07-09) verbatim.

**Interfaces — Produces:**
- `reader_covidence(path, sheet = NULL)` → tibble, one row per
  study×form×reviewer×outcome×timepoint: passthrough identity columns (`Study ID` …
  everything not in an outcome block), plus `outcome`, `timepoint` (NA where the
  export has none), and one column per result stat (`mean`, `SD`, `Total`, `Events` —
  whatever the name-parse yields). Registry: `.rev_readers <- list(covidence = reader_covidence)`.

Column-name grammar (from the real export): `Result data: <outcome> (<timepoint>)
<stat>` and `Outcome details: <outcome> - <field>` / `Outcome details: <outcome>
(<timepoint>) <field>`.

- [ ] **Step 1: failing tests** — on the fixture: result has the passthrough columns
  + outcome/timepoint; `nrow(result) > nrow(read.csv(fixture))` (blocks pivoted to
  rows); every non-NA `Result data … mean` value in the raw file appears exactly once
  in `result$mean`; rows for the dichotomous outcome carry `Events`/`Total`.
- [ ] **Step 2: run, expect FAIL.**
- [ ] **Step 3: implement** with `tidyr::pivot_longer(matches("^Result data: "),
  names_pattern = "^Result data: (.+?)(?: \\((.+)\\))? (\\w+)$",
  names_to = c("outcome", "timepoint", "stat"))` → drop all-NA values →
  `tidyr::pivot_wider(names_from = stat)`; join outcome-details columns by
  outcome(+timepoint where parenthesised); keep `Outcome details` general fields as
  outcome-level passthrough.
- [ ] **Step 4: run, expect PASS.**  - [ ] **Step 5:** format, lint, commit.

### Task 8: Standardisation (`standardise.R`)

**Files:** Create `R/standardise.R`, `tests/testthat/test-standardise.R`.

**Interfaces — Produces:**
- `rev_standardise(data, dict)` → list(`data` tibble (typed where fully coercible;
  composed key columns appended), `log` tibble(column, op, count),
  `failures` tibble(column, value, rows <list>) for V001,
  `skipped` chr (columns whose dependent checks must not run))
- Ops in order (each skippable per column via dictionary `clean:` map — add `clean`
  to `column_fields` in Task 3's constant, values validated as named list of booleans
  with op names → else Y001): `encoding`, `trim`, `missing`, `coerce`, `canonicalise`.

- [ ] **Step 1: failing tests**

```r
test_that("the five ops run in order and log counts", {
  dict <- rev_read_dictionary(test_path("fixtures", "specs-good", "tables", "estimates.yaml"))
  raw <- tibble::tibble(
    study = c("S1", " S1", "S2", "S2", "S3"),
    design = c("rct", "RCT", "Cohort", "", "Cohort"),
    mean_age = c("34.2", "34.2", "NR", "29.1", "340"),
    rob_score = c("1", "1", "2", "9", "2"),
    notes_temp = c("x y", "", "a", "b", "c")   # non-breaking space
  )
  s <- rev_standardise(raw, dict)
  expect_equal(s$data$study[2], "S1")                      # trimmed
  expect_equal(s$data$design[1], "RCT")                    # canonicalised
  expect_true(is.na(s$data$design[4]))                     # "" -> NA
  expect_true(is.na(s$data$mean_age[3]))                   # declared missing "NR"
  expect_type(s$data$mean_age, "double")                   # fully coercible after NR->NA
  expect_type(s$data$rob_score, "integer")
  expect_equal(s$data$notes_temp[1], "x y")                # NBSP -> space
  expect_equal(s$log$count[s$log$column == "design" & s$log$op == "canonicalise"], 1L)
})

test_that("uncoercible values leave the column as text and are reported", {
  dict <- rev_read_dictionary(test_path("fixtures", "specs-good", "tables", "estimates.yaml"))
  raw <- tibble::tibble(study = "S1", design = "RCT", mean_age = "12..3",
                        rob_score = "1", notes_temp = "a")
  s <- rev_standardise(raw, dict)
  expect_type(s$data$mean_age, "character")
  expect_equal(s$failures$value, "12..3")
  expect_equal(s$skipped, "mean_age")
})

test_that("standardisation is idempotent", {
  dict <- rev_read_dictionary(test_path("fixtures", "specs-good", "tables", "estimates.yaml"))
  raw <- tibble::tibble(study = " S1", design = "rct", mean_age = "NR",
                        rob_score = "1", notes_temp = "a")
  once <- rev_standardise(raw, dict)
  again <- rev_standardise(
    tibble::as_tibble(lapply(once$data, as.character)), dict)
  expect_identical(again$data, once$data)
})
```

- [ ] **Step 2: run, expect FAIL.**
- [ ] **Step 3: implement** — per column: `op_encoding` =
  `stringi::stri_trans_nfc()` then `stri_replace_all_regex("[\\p{Zs}]", " ")` then
  `stri_replace_all_regex("[\\p{Cf}]", "")`; `op_trim` = `trimws`; `op_missing`
  (`x[grepl("^\\s*$", x) | x %in% declared] <- NA`); `op_coerce` per type (integer
  `^[+-]?[0-9]+$` → `as.integer`; decimal `!is.na(suppressWarnings(as.numeric(x)))`;
  boolean `tolower(x) %in% c("true","false")`; date `as.Date(x, "%Y-%m-%d")`
  round-trip equality; any failure → record + keep character); `op_canonicalise`
  (text-with-values: fold on `tolower(trimws(x)) == tolower(values)`). Build combined
  key columns from `dict$roles`/levels combine entries after ops. Count every change
  into `log`.
- [ ] **Step 4: run, expect PASS.**  - [ ] **Step 5:** format, lint, commit.

### Task 9: Findings object + certificate (`findings.R`)

**Files:** Create `R/findings.R`, `tests/testthat/test-findings.R`; modify `R/read.R`
(swap `fnd_stub()` for the real constructor — one call site).

**Interfaces — Produces:**
- `new_finding(code, consequence, table, variable = NA, study_id = NA,
  rows = integer(), message, fix_options)` → one-row `rev_findings`
- `bind_findings(...)` → `rev_findings` (tibble subclass, class
  `c("rev_findings","tbl_df","tbl","data.frame")`); `no_findings()` → zero-row
- `print.rev_findings` — grouped by consequence, counts + instances, user vocabulary
  (snapshot-tested)
- `rev_export_findings(findings, path)` → writes xlsx via `writexl::write_xlsx`
  (rows list-column collapsed to `"3, 7, 12"`)
- `rev_certificate(findings, acknowledgments, unspecified = character(0))` →
  list(status = `"CERTIFIED"|"NOT CERTIFIED"`, n_findings, acknowledgments chr,
  unspecified chr); `print.rev_certificate` snapshot-tested for both statuses,
  including the informational unspecified-columns annex when non-empty
- Consequence constants: `csq_not_certifiable()`, `csq_join_skipped(left, right)`,
  `csq_checks_skipped(column)`

- [ ] **Steps 1–5:** failing tests (constructor field types; print snapshot with 2
  findings across 2 consequences; certificate snapshots for certified-with-
  acknowledgments and not-certified; xlsx export → `readxl::read_excel` round-trip
  has the collapsed rows string), watch fail, implement, watch pass (accept
  snapshots), format+lint, commit.

### Task 10: Per-table validation (`validate.R`)

**Files:** Create `R/validate.R`, `tests/testthat/test-validate.R`.

**Interfaces — Produces:**
- `rev_validate_table(std, dict)` → `rev_findings` (std = `rev_standardise()` output).
  Checks, using `dict$roles$study_id` to fill `study_id` where resolvable: V001 (from
  `std$failures`; consequence `csq_checks_skipped(column)`), V002 values, V003 range,
  V004 required-missing, V005 unique, V006 `constant_within_level` (grouped by the
  level's keys; message names the group; fix_options carries BOTH routes). Columns in
  `std$skipped` get only V001 (dependent checks suppressed). All value checks skip NA.

- [ ] **Step 1: failing tests** — feed the Task 8 first-test tibble through
  standardise+validate and assert: V003 for 340 (rows = 5L, study_id = "S3"), V002
  absent (design canonicalised), V005 absent (unique not declared), V006 fires on a
  crafted frame where mean_age varies within study S2 and its fix_options match
  regexp `"transcription|level key"`; V001 consequence equals
  `csq_checks_skipped("mean_age")` and no V003 fires for the uncoercible column.
  Snapshot the full findings print for the crafted frame.
- [ ] **Steps 2–5:** watch fail, implement (each check a `check_v00X(std, dict)`
  helper returning findings; `rev_validate_table` binds them), watch pass, format+lint,
  commit.

### Task 11: Joins + J-checks (`join.R`)

**Files:** Create `R/join.R`, `tests/testthat/test-join.R`.

**Interfaces — Produces:**
- `rev_join_tables(tables, joins)` → list(`data` = assembled tibble | NULL when all
  joins skipped, `findings` = rev_findings). `tables` = named list of standardised
  tibbles; `joins` = `rev_read_joins()` tibble. Per join: J001 (NA in any key column,
  either side → skip join, `csq_join_skipped`), J002 ("one" side not unique on its
  keys at declared granularity → skip), execution via
  `dplyr::left_join(by = setNames(keys_right, keys_left), relationship = relationship)`
  wrapped in `tryCatch` → J003 on relationship error (skip); J004/J005 unmatched
  (anti-joins both directions; suppressed into acknowledgments when `unmatched_ok`);
  near-miss: for each unmatched key value, `suggest_name()` against the other side's
  key values, folded into the message.
- `join_acknowledgments(joins, findings)` → chr lines for the certificate.

- [ ] **Step 1: failing tests** — two tiny tibbles (estimates 5 rows / rob 3 rows,
  one rob `study_id` = "s1 " vs estimates "S1" after deliberate skip of
  standardisation → near-miss message contains `did you mean`); happy join returns
  8-column assembled data with rob columns NA-filled for the unmatched study and a
  J004 finding; `unmatched_ok = TRUE` variant → no J004, acknowledgment line instead;
  duplicate rob study_id → J002 + `data` lacks rob columns (join skipped); NA key →
  J001. Snapshot the near-miss message.
- [ ] **Steps 2–5:** watch fail, implement, watch pass, format+lint, commit.

### Task 12: Orchestration (`check.R`)

**Files:** Create `R/check.R`, `tests/testthat/test-check.R`, fixture project
`tests/testthat/fixtures/miniproject/` completed: `specs/tables/estimates.yaml`,
`specs/tables/rob.yaml`, `specs/joins.yaml` (copies of the good fixtures with paths
pointing at `data/raw/*.csv` from Task 6), plus a second all-clean fixture project
`fixtures/miniproject-clean/` whose data contains no defects; `extra_col` stays
undeclared and appears only in the certificate's informational annex.

**Interfaces — Produces:**
- `rev_check_specs(project = ".")` → validates ALL spec files with **no data
  required** (dictionaries via `rev_read_dictionaries()`, joins via
  `rev_read_joins()`); on problems, the standard `stop_spec()` listing; on success,
  prints "All specs valid: {n} table{?s}, {n} join{?s}." (snapshot-tested) and
  returns the loaded specs invisibly. Serves the prespecification workflow
  (dictionary authored before data collection as the extraction instrument's source
  of truth) — spec validation deliberately checks that `source.file` is *declared*,
  never that it exists.
- `rev_check(project = ".", quiet = FALSE)` → invisibly `rev_findings` with
  attributes `certificate` (`rev_certificate`) and `assembled` (tibble | NULL).
  Internally begins with the same loading step as `rev_check_specs()`.
  Sequence per D4: read dictionaries + joins spec (spec errors abort) → per table:
  `rev_read_table` → `rev_standardise` → `rev_validate_table` → `rev_join_tables` →
  bind findings → certificate (acknowledgments from `unmatched_ok` joins;
  informational annex = unspecified columns per table) → unless `quiet`, print
  certificate then findings →
  write `output/diagnostics/preprocessed-<table>.csv` and
  `findings-<format(Sys.time(), "%Y%m%d-%H%M%S")>.xlsx` (skip xlsx when zero
  findings). Never touches `data/raw/` (test asserts mtimes unchanged).

- [ ] **Step 1: failing tests** — `rev_check_specs()`: on the miniproject → success
  message snapshot + invisible specs list; on a copy whose data/raw/ is DELETED →
  still succeeds (no data required); on a bad-spec fixture → `revpiper_spec_error`.
  `rev_check()` on the miniproject: returns findings containing codes
  `{"V003","J004"}` at least (`extra_col` sits in the unspecified annex, not in
  findings); certificate status "NOT CERTIFIED";
  `output/diagnostics/preprocessed-estimates.csv` exists and its row numbering
  matches the `rows` in the V003 finding; raw file mtimes unchanged.
  miniproject-clean: zero findings, "CERTIFIED", the informational annex mentions
  `extra_col`; full console output snapshot for both projects.
- [ ] **Steps 2–5:** watch fail, implement, watch pass (read snapshots carefully —
  this is the product's voice), format+lint, commit.

### Task 13: Draft generator (`draft.R`)

**Files:** Create `R/draft.R`, `tests/testthat/test-draft.R`.

**Interfaces — Produces:**
- `rev_draft_dictionary(file, table, project = ".", sheet = NULL)` → writes
  `specs/tables/<table>.yaml` (aborts via cli if it already exists) and returns the
  path invisibly. Emits MINIMAL skeleton (D2a): `table`, `description: ""`,
  `source:` (file, sheet if given), empty `roles: {}` / `levels: {}`, and per data
  column `name` + draft `type` (inference on the raw character column: all
  integer-regex → integer; all numeric → decimal; all in true/false → boolean; all
  ISO dates → date; else text; blanks ignored; all-blank → text) + `description: ""`.
  No values/range/comments — the user fills the rest.

- [ ] **Steps 1–5:** failing test (run on the miniproject estimates.csv → yaml
  round-trips via `rev_read_dictionary()` with zero problems; `mean_age` drafts as
  text — the "NR" proves inference is draft-not-truth; existing-file abort
  snapshot), watch fail, implement (`yaml::write_yaml`), watch pass, format+lint,
  commit.

### Task 14: Site config, NEWS, docs, pre-push, handoff

**Files:** Modify `_pkgdown.yml`, `NEWS.md`, `README.md`; roxygen for all exports.

- [ ] **Step 1: pkgdown rendered set — relocate CLAUDE.md** (resolution per embedded
  decision 8, Liz 2026-07-10):

```bash
mkdir -p .claude
git mv CLAUDE.md .claude/CLAUDE.md
```

Update `.Rbuildignore`: replace the `^CLAUDE\.md$` line with `^\.claude$`. Rebuild:
`Rscript -e 'pkgdown::build_site(preview = FALSE)'`. One-time verification (not a
committed test):

```r
stopifnot(
  !file.exists("docs/CLAUDE.html"),
  file.exists("docs/index.html"),        # README rendered (homepage)
  file.exists("docs/news/index.html")    # NEWS rendered (changelog)
)
```

Also update the spec's Area 4 pkgdown note in the same commit ("resolved by
relocating CLAUDE.md to .claude/ — the default rendered set is then README+NEWS")
and verify a fresh `devtools::check()` stays 0/0/0 (the `.claude/` dir must be
build-ignored).
- [ ] **Step 2: NEWS bullets** (user-facing additions this phase):

```markdown
- `rev_check()` diagnoses a review project end to end: per-table dictionaries,
  standardisation, validation with routed findings, declared joins, and an honest
  certification status.
- `rev_check_specs()` validates every spec file with no data present — dictionaries
  can be authored and checked before data collection begins.
- `rev_draft_dictionary()` generates a minimal dictionary skeleton from a data file.
- Findings report consequences (what a problem prevents), never severities; outputs
  are always written and always labelled CERTIFIED / NOT CERTIFIED.
```

- [ ] **Step 3: roxygen pass** — every export documented with a runnable example on
  the miniproject fixture; `devtools::document()`; reference complete-but-terse
  (vignettes are Phase 3).
- [ ] **Step 4: full pre-push suite** — `air format .` (no diff),
  `lintr::lint_package()` (0), `devtools::test()` (all pass),
  `devtools::check(args = "--no-manual", build_args = "--no-manual", error_on =
  "note")` (0/0/0). Fix anything found; commit.
- [ ] **Step 5: handoff.** Report to Liz: branch `phase-1-core` ready; she fetches,
  pushes, opens the PR (squash-merge; CI green gate). Spec §4 one-line amendment
  (rev_check diagnostics, Decision 1) rides the same PR.

## Self-review (performed at authoring)

1. **Spec coverage:** §3.1 dictionary schema → Tasks 3–4, 13; §3.2 levels/contract →
   Tasks 3, 8, 10; §3.3 readers+joins → Tasks 5–7, 11; §3.4 stages 1–3 semantics →
   Tasks 8, 10, 12; §3.7 findings/routing/xlsx/snapshots → Tasks 9–12 + catalogue
   above; §5 layout/S3/error doctrine → file map + Tasks 2, 9; §7 test layers 1
   (unit) throughout, layer 2 seeded by miniproject fixtures (full synthetic review =
   Phase 3 as spec'd); pkgdown item → Task 14. Corrections (stage 4) correctly
   absent: Phase 2, seam noted in Task 12's sequence. Not covered by design (and so
   not here): `rev_clean()` certification artifacts beyond diagnostics — Phase 2.
2. **Placeholder scan:** helper names referenced in Task 3/4/5 step 3 are defined
   with their check codes and models in the same step; no TBDs remain.
3. **Type consistency:** `rev_findings` columns match between Tasks 6 (stub), 9
   (constructor), 10–12 (consumers); `rev_standardise()` output consumed by Tasks
   10–12 as produced; `dictionary_key_columns()` (Task 4) consumed by Task 5's Y015.
