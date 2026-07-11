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
- **Execution amendment 4 (2026-07-11, after Task 3; SIGNED OFF, Liz 2026-07-11):**
  schema-driven validation architecture, from Liz's structural review of the checks.
  (a) **Single source of truth**: `inst/schema/fields.yaml` declares every spec
  field with ALL properties explicit (level, required, shape, cardinality,
  empty_ok, domain [always inline], permitted_types, permission handling, excludes,
  content_typed, ordered, unique_entries, refers_to, identity, default). Checks are
  GENERATED from properties — one definition per check kind, instances declared in
  the schema. Cardinality `one_or_many` accepts scalar-for-list everywhere (users
  never penalised for `missing: NR`). Permissive permission sets: values/units on
  everything except boolean; range on integer/decimal/date.
  (b) **Scope taxonomy + code prefixes** (option b, Liz): checks are classed by how
  much context they read — YF within one field, YE within one entry, YS within one
  source file, YX across sources. Y-series renumbered accordingly (mapping in the
  catalogue); collapses: one permission check (old Y004/Y005/Y006), one reference
  resolver (old Y009/Y010/Y011/Y014/Y015), one identity check (old Y012/Y013),
  old Y016 dissolved into domain/shape/reference, old Y019 into required.
  (c) **Standalone-source rule**: `rev_read_dictionary()` exhausts YF/YE/YS alone —
  one file fully validates with zero knowledge of other sources; YX runs in a
  separate, composable, DATA-FREE set-level step (prespecification workflow
  preserved). Task 3 as executed is superseded by Task 3b; Tasks 4-6 restated.
  (d) **Two-layer tests**: a property matrix GENERATED from the schema (every
  property × every field × applies/does-not-apply) proves logic by construction; a
  small curated fixture set with snapshots guards wording and routing.
  (e) **Terminology** (recorded in dev/conventions.md): data tables have *columns*
  (variables); a dictionary describes each column via *fields*; the package schema
  defines each field's *properties*; properties generate *checks*; failures are
  *problems* (spec, abort) or *findings* (data, routed). "Attributes" avoided
  (R-reserved meaning).
  (f) **Deferred decisions logged in spec §8.2**: possible package split
  (spec/process/vis); joins declaring expected column overlap; workflow ordering of
  within-source vs across-source data checking + corrections (join spec may be
  authored upfront for sheet compatibility).
- **Execution amendment 5 (2026-07-11; SIGNED OFF, Liz 2026-07-11):** uniform
  stage reporting, from Liz's requirement that spec development work standalone
  and leave a durable record. (a) **Every user-facing stage command emits a
  report + certification through ONE reusable machinery** (stage name, timestamp,
  items, status, acknowledgments/annex; shared print, export, certificate
  rendering — new stages bring only an item schema and a gate rule; the stage
  name is a parameter, so the machinery is independent of the stage taxonomy).
  Phase 1 implements the core plus two instantiations: `spec` (items = problems)
  and the consolidated data-check report per D4 (items = findings). **The
  user-facing stage VOCABULARY is provisional** (Liz 2026-07-11): the working
  model is spec -> load (import) -> correct (manual, non-algorithmic) ->
  transform (derive), each followed by a package check that flags issues;
  whether correct stands alone and where joins/gating sit are open — resolved at
  Task 9's walkthrough (report naming) and Phase 2 planning (full model), logged
  in spec §8.2. (b) **Storage**: everything under
  `output/reports/`, named `<stage>-<runstamp>.xlsx` (items) +
  `<stage>-<runstamp>-certificate.txt`; certificates share one format with a
  stage line ("Stage: specification — CERTIFIED"). A CERTIFIED spec report is a
  timestamped prespecification artifact (registerable before data collection).
  `output/diagnostics/` keeps the preprocessed-<table>.csv data artifacts
  (decision 1 restated). (c) **Doctrine refined**: every stage always completes
  and always reports; consequently the STAGE RUNNERS (`rev_check_specs()`,
  `rev_check()`) no longer abort on spec problems — they return a NOT CERTIFIED
  report (matching `rev_check()`'s no-abort behaviour on findings); classed
  aborts remain for the constructors (`rev_read_dictionary()` etc.) called
  directly. `rev_check()` with an uncertified spec writes the spec report and
  skips data stages (they are impossible, not merely gated). (d) **Pipeline
  gating deferred** (Liz): rules for partial processing — loading/processing one
  source before others are join-ready — folded into the spec §8.2 workflow
  question. Task 9 generalised (R/report.R core + findings as first item
  schema); Task 12 restated.
- **Execution amendment 6 (2026-07-11; SIGNED OFF, Liz 2026-07-11):**
  single-source invariant adopted, from Liz's review of recurring duplication /
  hard-coding / missed abstraction across Tasks 1-3b (each caught reactively;
  this makes prevention structural). PRINCIPLES and PROCESSES recorded in
  dev/conventions.md ("Single source of truth"): one authoritative home per
  fact, preferably data; registry-first for new fact-families; checks by
  construction over review; walkthrough facts-and-sources section; pre-commit
  duplication pass; plan-authoring single-source scan. IN THIS PLAN: the
  invariant joins Global Constraints (binding on Tasks 4-14); walkthroughs
  from Task 4 onward carry facts-and-sources; Task 14's pre-push suite gains a
  whole-package duplication/abstraction audit as the phase backstop. Specific
  homes remain plan/spec decisions (currently inst/schema/fields.yaml and
  checks.yaml).
- **Source of truth:** dev/superpowers/specs/2026-07-07-revpiper-design.md
  (as amended through 2026-07-11). Rationale trail:
  dev/superpowers/plans/2026-07-08-phase-1-planning-notes.md.

**Goal:** Implement revpiper's spec machinery and pipeline stages 1–3 — per-table
dictionaries, joins spec, readers, standardisation, per-table validation, joins with
J-checks, the consequence-based findings object with certification, `rev_check()`,
and the minimal dictionary draft generator — fully TDD'd, CI green.

**Architecture:** Functional core; one file per topic (provisional layout, spec §5);
S3 for `rev_dictionary`, `rev_findings`, `rev_report`. All input read as
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
- **Single source of truth (amendment 6)**: every fact has one authoritative
  home, preferably data (`inst/schema/`); code is generic over declared facts;
  a literal appearing twice is a defect. New fact-family -> registry + loader +
  closure test FIRST. Walkthroughs name each new fact's home
  (facts-and-sources); every commit is preceded by a duplication pass, findings
  reported at the check-in.

## Decisions embedded in this plan (for sign-off with the plan)

1. **`rev_check()` writes diagnostics and reports.** Spec §4 says rev_check
   "writes nothing"; D4's findings row numbers reference `preprocessed-<table>`
   artifacts. Resolved (restated by amendment 5): stage reports + certificates go
   under `output/reports/` (`<stage>-<runstamp>.xlsx`,
   `<stage>-<runstamp>-certificate.txt`); data artifacts
   (`preprocessed-<table>.csv`) under `output/diagnostics/` — never pipeline
   artifacts, never `data/raw/`. "Always safe" is preserved; the row numbers users
   see are inspectable. Spec §4 gets a one-line amendment when this plan is signed
   off.
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
| `R/report.R` | generic stage report + certification machinery (all stages) | `test-report.R` |
| `R/findings.R` | `rev_findings`, consequences, check-stage item schema | `test-findings.R` |
| `R/validate.R` | V-checks per table | `test-validate.R` |
| `R/join.R` | join execution + J-checks + near-miss suggestions | `test-join.R` |
| `R/check.R` | `rev_check()` orchestration + diagnostics output | `test-check.R` |
| `R/draft.R` | `rev_draft_dictionary()` | `test-draft.R` |
| `inst/schema/fields.yaml` | single source of truth: every spec field's properties | schema self-validation in `test-schema.R` |
| `R/schema.R` | schema loader (cached), accessors | `test-schema.R` |

## Check catalogue, routing, and data-dict coverage (plan deliverable)

Consequence constants: `not certifiable` (every finding, always) plus, where
mechanical: `join '<left>-<right>' skipped`; `dependent checks on '<column>' not run`.

### Spec validation (parse time; these ABORT with all problems listed, file+entry)

Codes are prefixed by SCOPE — how much context the check reads (amendment 4;
one term per scope, used everywhere): **YF** form (within one field) · **YE**
entry (across fields within one entry) · **YS** source (across entries within
one file) · **YX** cross-source (across files). Every check is one definition; its instances are declared by
schema properties in `inst/schema/fields.yaml`.

#### YF — form checks (within one field)

| Code | Property | Check | Fix routes to |
|---|---|---|---|
| YF01 | `empty_ok` | field written with no value (YAML null); `description` exempt (draft skeletons) | the named entry |
| YF02 | `shape` + `cardinality` | value malformed: wrong element type, or wrong count (`range` needs exactly two; empty list where one-or-more required) | the named entry |
| YF03 | `domain` | value outside its closed domain, did-you-mean (`type`; joins `relationship`) | the named entry |
| YF04 | `unique_entries` | duplicate entries within a list field (`values`, `combine`, level keys) | the named entry |
| YF05 | `ordered` | `range` descending (numeric or chronological) | the named entry |

#### YE — entry checks (across fields within one entry)

| Code | Property | Check | Fix routes to |
|---|---|---|---|
| YE01 | field vocabulary | unknown field name, did-you-mean vs the context's legal set | the named entry |
| YE02 | `required` | required field absent (top: `table`,`source`,`columns`; source: `file`; column: `name`,`type`; combine: `combine`,`separator`) | the named entry |
| YE03 | `permitted_types` | constraint on a column type outside its permitted set (`values`/`units`: all but boolean; `range`: integer/decimal/date) | column entry |
| YE04 | `excludes` | mutually exclusive fields both present (`values`+`range`); type-independent | column entry |
| YE05 | `content_typed` | constraint entries do not match the column's declared type (incl. mixed-type entries) | column entry |
| YE06 | *custom: union dispatch* | role entry neither a column name nor a combine block | roles block |

#### YS — source checks (across entries within one file)

| Code | Property | Check | Fix routes to |
|---|---|---|---|
| YS01 | `identity` (file scope) | duplicate column name within a table | columns block |
| YS02 | `refers_to` (file scope) | unresolved within-file reference: role/level key → declared columns; `constant_within_level` → declared levels; did-you-mean | the named entry |
| YS03 | *custom: environment* | declared `reader` neither shipped nor a function in readers.R | source block / readers.R |

#### YX — cross-source checks (across files; separate, composable, data-free set-level step)

| Code | Property | Check | Fix routes to |
|---|---|---|---|
| YX01 | `identity` (set scope) | duplicate table name across `specs/tables/*.yaml` | the two files named |
| YX02 | `refers_to` (set scope) | unresolved cross-source reference: join `left`/`right` → tables; `keys` → the side's key columns (combined keys count); `granularity` → a declared level of the "one" side; did-you-mean | joins.yaml entry |

Old→new mapping (amendment 4): Y001→YE01 · Y002→YF03 · Y003→YE04 · Y004/Y005/Y006→YE03 ·
Y007→YF02+YE05 · Y008→YF05 · Y009→YS02+YE06 · Y010/Y011→YS02 · Y012→YS01 (+YE02/YF01
for missing/empty names) · Y013→YX01 · Y014/Y015→YX02 · Y016→YF03/YF02/YX02 ·
Y017/Y019→YE02 · Y018→YS03 · Y020→YF01 · Y021(draft)→YF02 · new: YF04.

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
| S01 unresolved FK | — | N/A: no `foreign_key` constraint in v1 (joins declare keys; YX02) |
| S02 unknown table | YX02 | adopted |
| S03 unknown column | YX02 | adopted |
| S04 invalid join expr | YX02/YF03 | adapted (structured keys, not expressions) |
| S05 unresolved conflict col | — | N/A: no `conflicts` field v1; overlapping non-key columns get dplyr suffixes + unspecified-columns visibility |
| S06 inconsistent cardinality | YF03/YX02 + J002/J003 | adapted (declared vs constraint consistency checked at data level) |
| S07 wrong representation key | YE03/YE04 | adapted (values/range permissions per type) |
| S08 units w/o quantity | YE03 | adapted (permissive: units allowed except boolean, amendment 4) |
| S09 missing $learn_more | — | N/A: no counterpart field |
| S10 duplicate name | YS01/YX01 | adopted |
| S11 empty name | YE02/YF01 | adopted (folded into required/empty) |
| S12 wrong value type | YF02/YE05 | adopted |
| S13 descending range | YF05 | adopted |
| S14/S15 time zone | — | N/A: datetime dropped from v1 |
| S16 misplaced single-table description | — | N/A: per-table files by design |
| S17 malformed version | — | N/A: data-version field not adopted; provenance stamped by pipeline (§3.8) |
| S18 missing $version | — | N/A: schema versioning deferred to first breaking change |
| M01 type mismatch | V001 | adapted (coercion-based) |
| M02 missing column | R005 | adopted |
| M03 undocumented column | — | adapted (amendment 3): informational unspecified-columns listing, not a finding |
| M04 missing source | YE02 | adopted (folded) |
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

> **Executed 2026-07-10 as written (commits 199465a, c3c945e). SUPERSEDED by
> Task 3b (amendment 4): the hand-written checks below are replaced by
> schema-driven validators and the Y-codes by the YF/YE/YS/YX catalogue. Kept
> as the record of what ran; do not execute again.**

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

### Task 3b: Schema-driven validation rewrite (amendment 4)

**Files:** Create `inst/schema/fields.yaml`, `R/schema.R`,
`tests/testthat/test-schema.R`; rewrite `R/spec-dictionary.R` internals (public
interface unchanged); rewrite `tests/testthat/test-spec-dictionary.R` (two-layer);
rename `fixtures/specs-bad/*` to new codes; update the two example codes in
`test-utils-messages.R` (Y001→YE01, Y014→YX02) and regenerate snapshots.

**Interfaces — Produces:**
- `field_schema(level)` → tibble of schema rows for `"top"|"source"|"column"|"combine"`
  (loaded once from `inst/schema/fields.yaml`, cached in a package environment)
- `schema_types()` → chr(5), read from the `type` row's inline domain
- Scope-classed validators, each one definition driven by schema rows:
  within-field `check_empty` (YF01), `check_shape` (YF02: element type + cardinality,
  `one_or_many` normalises scalar→list), `check_domain` (YF03, did-you-mean),
  `check_unique_entries` (YF04), `check_ordered` (YF05); within-entry
  `check_vocabulary` (YE01), `check_required` (YE02), `check_permitted` (YE03),
  `check_excludes` (YE04), `check_content_typed` (YE05). Per-context battery:
  `check_entry(x, level, file, entry)` runs all ten with that level's schema slice.
- `rev_read_dictionary(path)` — same export, same return shape, now YF/YE-complete
  per entry plus YS01 (duplicate column names); still aborts once via `stop_spec()`.
- Ordering gates preserved: YE01 first; YF01/YF02 before content checks; YE04
  type-independent; type-dependent checks suppressed without a valid `type`.

- [ ] **Step 1: schema file.** One field per line (flow style: field-level diffs);
  ALL properties explicit; `any`/`null` are stated, never implied:

```yaml
# inst/schema/fields.yaml — single source of truth for spec-field validation.
# Properties: field, level, required, shape (string|boolean|scalar|block|
# named_list|list_of_blocks), cardinality (one|one_or_many|two), empty_ok,
# domain (inline list or null), permitted_types (any | list of types),
# excludes, content_typed, ordered (ascending|null), unique_entries,
# refers_to (columns|levels|null), identity, default.
fields:
  - {field: table, level: [top], required: true, shape: string, cardinality: one, empty_ok: false, domain: null, permitted_types: any, excludes: null, content_typed: false, ordered: null, unique_entries: false, refers_to: null, identity: true, default: null}
  - {field: description, level: [top, column], required: false, shape: string, cardinality: one, empty_ok: true, domain: null, permitted_types: any, excludes: null, content_typed: false, ordered: null, unique_entries: false, refers_to: null, identity: false, default: null}
  - {field: source, level: [top], required: true, shape: block, cardinality: one, empty_ok: false, domain: null, permitted_types: any, excludes: null, content_typed: false, ordered: null, unique_entries: false, refers_to: null, identity: false, default: null}
  - {field: roles, level: [top], required: false, shape: named_list, cardinality: one, empty_ok: false, domain: null, permitted_types: any, excludes: null, content_typed: false, ordered: null, unique_entries: false, refers_to: columns, identity: false, default: null}
  - {field: levels, level: [top], required: false, shape: named_list, cardinality: one, empty_ok: false, domain: null, permitted_types: any, excludes: null, content_typed: false, ordered: null, unique_entries: true, refers_to: columns, identity: false, default: null}
  - {field: columns, level: [top], required: true, shape: list_of_blocks, cardinality: one_or_many, empty_ok: false, domain: null, permitted_types: any, excludes: null, content_typed: false, ordered: null, unique_entries: false, refers_to: null, identity: false, default: null}
  - {field: file, level: [source], required: true, shape: string, cardinality: one, empty_ok: false, domain: null, permitted_types: any, excludes: null, content_typed: false, ordered: null, unique_entries: false, refers_to: null, identity: false, default: null}
  - {field: sheet, level: [source], required: false, shape: string, cardinality: one, empty_ok: false, domain: null, permitted_types: any, excludes: null, content_typed: false, ordered: null, unique_entries: false, refers_to: null, identity: false, default: null}
  - {field: reader, level: [source], required: false, shape: string, cardinality: one, empty_ok: false, domain: null, permitted_types: any, excludes: null, content_typed: false, ordered: null, unique_entries: false, refers_to: null, identity: false, default: null}
  - {field: name, level: [column], required: true, shape: string, cardinality: one, empty_ok: false, domain: null, permitted_types: any, excludes: null, content_typed: false, ordered: null, unique_entries: false, refers_to: null, identity: true, default: null}
  - {field: type, level: [column], required: true, shape: string, cardinality: one, empty_ok: false, domain: [text, integer, decimal, boolean, date], permitted_types: any, excludes: null, content_typed: false, ordered: null, unique_entries: false, refers_to: null, identity: false, default: null}
  - {field: values, level: [column], required: false, shape: scalar, cardinality: one_or_many, empty_ok: false, domain: null, permitted_types: [text, integer, decimal, date], excludes: [range], content_typed: true, ordered: null, unique_entries: true, refers_to: null, identity: false, default: null}
  - {field: range, level: [column], required: false, shape: scalar, cardinality: two, empty_ok: false, domain: null, permitted_types: [integer, decimal, date], excludes: [values], content_typed: true, ordered: ascending, unique_entries: false, refers_to: null, identity: false, default: null}
  - {field: units, level: [column], required: false, shape: string, cardinality: one, empty_ok: false, domain: null, permitted_types: [text, integer, decimal, date], excludes: null, content_typed: false, ordered: null, unique_entries: false, refers_to: null, identity: false, default: null}
  - {field: required, level: [column], required: false, shape: boolean, cardinality: one, empty_ok: false, domain: null, permitted_types: any, excludes: null, content_typed: false, ordered: null, unique_entries: false, refers_to: null, identity: false, default: false}
  - {field: unique, level: [column], required: false, shape: boolean, cardinality: one, empty_ok: false, domain: null, permitted_types: any, excludes: null, content_typed: false, ordered: null, unique_entries: false, refers_to: null, identity: false, default: false}
  - {field: missing, level: [column], required: false, shape: string, cardinality: one_or_many, empty_ok: false, domain: null, permitted_types: any, excludes: null, content_typed: false, ordered: null, unique_entries: true, refers_to: null, identity: false, default: []}
  - {field: constant_within_level, level: [column], required: false, shape: string, cardinality: one, empty_ok: false, domain: null, permitted_types: any, excludes: null, content_typed: false, ordered: null, unique_entries: false, refers_to: levels, identity: false, default: null}
  - {field: combine, level: [combine], required: true, shape: string, cardinality: one_or_many, empty_ok: false, domain: null, permitted_types: any, excludes: null, content_typed: false, ordered: null, unique_entries: true, refers_to: columns, identity: false, default: null}
  - {field: separator, level: [combine], required: true, shape: string, cardinality: one, empty_ok: false, domain: null, permitted_types: any, excludes: null, content_typed: false, ordered: null, unique_entries: false, refers_to: null, identity: false, default: null}
```

> Follow-up (2026-07-11, Liz's 3b review): shape vocabulary consolidated —
> `block`/`named_list`/`list_of_blocks` become `mapping`/`list_of_mappings`
> plus an explicit `context` property (the level to validate a mapping's
> contents as; null = user-chosen keys are data). Recursion into
> source/columns is now schema-driven (`check_contexts()`), and the
> file-scope identity check generalised (`check_mapping_list()`). NEW Task 4
> agenda item: role KEYS are pipeline vocabulary (`study_id`), not free
> names — should unknown roles be checked? (Liz's "who owns the keys" lens.)

(Task 5 appends `level: [join]` rows — `left`/`right`/`keys`/`granularity`/
`relationship`/`unmatched_ok` — to this same file; `refers_to` for
roles/levels/cwl is consumed in Task 4.)
- [ ] **Step 2: failing schema tests** (`test-schema.R`): `field_schema("column")`
  returns one row per column field with all fifteen properties non-missing;
  `schema_types()` == the five types; SELF-VALIDATION — every property value is in
  its closed vocabulary, every `permitted_types`/`content_typed` list ⊆
  `schema_types()`, every `excludes`/`refers_to` target exists, `domain` only on
  rows where it is a list, exactly one `identity` row per scope. Run: FAIL
  (loader absent).
- [ ] **Step 3: loader** (`R/schema.R`): `yaml::read_yaml` +
  `tibble` conversion, cached via `local()` env; accessors above. Run: PASS.
- [ ] **Step 4: failing property-matrix tests** (rewritten
  `test-spec-dictionary.R`, layer 1): a generator builds a minimal valid
  dictionary as an R list; for every schema row × property the matrix mutates one
  aspect and asserts the mapped code fires — and asserts silence on the
  complementary set (required false → deletion silent; each `one_or_many` field
  accepts scalar AND list; every permitted type × constraint silent; every banned
  type → YE03; etc.). Codes asserted programmatically via
  `err$problems` (stop_spec gains a `problems` field on the condition for this).
  Layer 2: curated fixtures renamed (`ye01-top-level.yaml`, `yf03-bad-type.yaml`,
  … one per code incl. YF04-new; many-defects kept), snapshot each. Run: FAIL.
- [ ] **Step 5: rewrite `R/spec-dictionary.R`** — the ten validators + battery per
  the Interfaces block, consuming `field_schema()`; delete the hand-written
  check family; keep `rev_read_dictionary()` signature, guard, `new_dictionary()`
  (defaults now read from schema `default`), `stop_spec()` call. Run: PASS;
  READ every snapshot (renumbered codes are new product voice).
- [ ] **Step 6:** `air format .`, zero lints, full `devtools::test()`, commit.

### Task 4: Within-source references + set-level step (`spec-dictionary.R`, part 2)

> **Gate status (2026-07-11):** a walkthrough was approved, then superseded -
> Liz wants a FRESH walkthrough from the next session before execution.
> Execution NOT started. Decisions resolved at the 2026-07-11 walkthrough:
> (a) **Role keys are user-chosen, never policed** (no key_domain property, no
> YF06): a role's VALUE is still YS02-checked, joins catch key mismatches via
> YX02, and pipeline consumers that look up a known role (`study_id`, Task 10)
> report its absence informationally - never as a finding. (b) **The
> "complete-example"/kitchen-sink fixture is DROPPED** (considered and
> rejected: the matrix + good fixture + boundary-legal test carry positive
> coverage; docs completeness comes from the generated reference, realism
> from the miniproject; do not resurrect). (c) **/simplify trial**: run on
> the task diff after tests are green and before the final commit; its edits
> are reviewed jointly with Liz before keeping; treat as review feedback
> (verify against conventions, re-run suite, report at check-in).

**Files:** Modify `R/spec-dictionary.R`; extend `test-spec-dictionary.R` + fixtures.

**Interfaces — Produces:**
- Within-file additions to `rev_read_dictionary()` (completes YS scope; standalone
  rule holds — one file, zero knowledge of other sources): YE06 (role entry
  neither string nor combine block — union dispatch; a valid combine block is
  validated as a `combine`-level context and registers a **virtual column** named
  by the role), YS02 via the schema's `refers_to` (role strings + level keys +
  combine parts → declared columns; `constant_within_level` → declared levels;
  did-you-mean vs the collection), YS01 (duplicate column names — `identity`,
  file scope).
- `dictionary_key_columns(dict)` → chr of real + virtual columns usable as keys.
- `rev_read_dictionaries(dir)` → named list of `rev_dictionary` PLUS the
  data-free set-level step: YX01 (duplicate `table` across files — `identity`,
  set scope). Loads each file standalone, then validates the set.

- [ ] **Step 1: failing tests** — good fixture variant with
  `study_id: {combine: [author, year], separator: "_"}` parses;
  `dictionary_key_columns()` includes `study_id`; matrix additions for `refers_to`
  (each referring field × resolves/doesn't); curated fixtures: ye06 (role entry a
  number), ys02 (combine part unknown; cwl names undeclared level), yf04
  (duplicate combine parts), ys01 stays, yx01 two-file dir. Snapshot each.
- [ ] **Step 2: run, expect FAIL.**
- [ ] **Step 3: implement** — `resolve_references(dict_raw, file)` (one resolver,
  schema-driven collections), `check_role_entries()` (dispatch + combine context
  via the battery), identity check at both scopes,
  `rev_read_dictionaries()` = per-file `rev_read_dictionary()` + set-level
  identity scan.
- [ ] **Step 4: run, expect PASS; read snapshots.**
- [ ] **Step 5:** format, lint, commit.

> Follow-up (2026-07-11, Liz's Task 4 review, after the task's main commit):
> (a) `roles:` renamed `identifiers:` — the broad future-roles vision is
> REJECTED (Liz: for later purposes users reference their own column names
> directly); schema row, YE06 registry entry (message/params/fix), code,
> tests, and fixtures renamed; do not reintroduce "role". (b) `identities_of`
> renamed `entry_names`; plain-language terminology (entry, name, collection,
> identifier, virtual column) added to dev/conventions.md Terminology.
> (c) OPEN — decide at the Task 5 walkthrough: drop `levels:` and joins'
> `granularity`? Liz judges granularity context-bound and per-join (join keys
> and cardinality vary between joins), so a table-level grouping vocabulary
> may not be parsimonious; candidate simplification is
> `constant_within_level` naming key column(s) directly and J002 deriving
> uniqueness from `keys` + `relationship`. Affects Task 5 (granularity, J002,
> rob fixture levels), Task 8 V006 (fix route wording), Task 13 skeleton
> (`levels: {}`), and a contained Task 4 rework (schema rows, walkers,
> matrix regenerates).
> (d) Flagged smell, later structural follow-up: early
> `return(no_problems())` exits rely on the promise "shape problem already
> reported one level up" — held today by the matrix's exact-code assertions,
> but deserves an explicit single gate rather than a comment.

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
- Schema extension: `level: [join]` rows appended to `inst/schema/fields.yaml` —
  `left`/`right` (required strings, `refers_to: tables`), `keys` (required
  named_list; values `refers_to` the named side's `dictionary_key_columns()` —
  the one context-parameterised reference, thin custom code), `granularity`
  (required string, `refers_to` the "one" side's declared levels), `relationship`
  (required string, `domain: [one-to-one, one-to-many]`), `unmatched_ok` (boolean,
  `default: false`). The battery + resolver from Tasks 3b/4 do the rest: YE01
  unknown fields, YE02 required, YF02 shapes, YF03 relationship domain, YX02
  unresolved tables/keys/granularity.
- `rev_read_joins(path, dictionaries)` → tibble(left, right, keys_left <list chr>,
  keys_right <list chr>, granularity, relationship, unmatched_ok). Missing
  joins.yaml → zero-row tibble (single-table projects are valid). This is the
  across-source (YX) validation step — data-free, composable, callable on its own.

- [ ] **Steps 1–5:** failing tests (good parse incl. defaults `unmatched_ok = FALSE`;
  matrix additions for the join schema rows; snapshot per curated bad fixture —
  unknown table, unknown key, bad relationship, granularity not a level; absent
  file → zero rows), watch fail, implement, watch pass, format+lint, commit.
- Open question resolved AT THIS TASK's walkthrough (amendment 4): should joins
  declare expected column overlap between sides (`shared:`), with overlap beyond
  keys+shared a finding? (Liz 2026-07-11: overlap semantics differ between
  same-variables merges and different-information merges.)
- REQUIREMENT (Liz 2026-07-11, Task 4 review): many-to-many joins must be
  declarable. `relationship`'s planned domain [one-to-one, one-to-many]
  cannot express them — it gains `many-to-many`, and J002's key-uniqueness
  expectation applies only to a side a declared relationship makes "one".
  Resolve the exact semantics at this task's walkthrough, alongside the
  open levels/granularity question recorded under Task 4.

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
  `readers.R`, sourced via `source(local = new.env())`; unknown → YS03 abort),
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
- Ops in order (each skippable per column via dictionary `clean:` map — add a
  `clean` field row to `inst/schema/fields.yaml` (level column, shape named_list);
  op-name/boolean validation via the battery → YE01/YF02): `encoding`, `trim`,
  `missing`, `coerce`, `canonicalise`.

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

### Task 9: Stage-report machinery + findings (`report.R`, `findings.R`)

**Files:** Create `R/report.R`, `tests/testthat/test-report.R`, `R/findings.R`,
`tests/testthat/test-findings.R`; modify `R/read.R` (swap `fnd_stub()` for the
real constructor — one call site).

**Interfaces — Produces (amendment 5: one machinery, all stages):**
- `new_stage_report(stage, items, acknowledgments = character(0),
  unspecified = character(0))` → `rev_report`: list(stage chr
  ("spec"|"check"|later "correct"|"derive"), timestamp, items (stage's item
  tibble: problems for spec, findings for check), status = "CERTIFIED" iff zero
  standing items, acknowledgments chr, unspecified chr)
- `print.rev_report` — certificate header (one format, stage line: "Stage:
  specification — CERTIFIED") then items grouped per stage's conventions;
  snapshot-tested per stage × both statuses, incl. the unspecified annex
- `rev_export_report(report, dir = "output/reports")` → writes
  `<stage>-<runstamp>.xlsx` (items; list-columns collapsed, e.g. rows →
  `"3, 7, 12"`) + `<stage>-<runstamp>-certificate.txt` (rendered certificate);
  returns paths invisibly; creates dir
- Check-stage item schema (`R/findings.R`): `new_finding(code, consequence,
  table, variable = NA, study_id = NA, rows = integer(), message, fix_options)`
  → one-row `rev_findings`; `bind_findings(...)`; `no_findings()`;
  `print.rev_findings` grouped by consequence (snapshot-tested); consequence
  constants `csq_not_certifiable()`, `csq_join_skipped(left, right)`,
  `csq_checks_skipped(column)`. Spec-stage items are the Task 2 problems tibble
  — no new schema needed.

- [ ] **Steps 1–5:** failing tests (report constructor: status derivation both
  stages; print snapshots spec/check × certified/not; export → files exist,
  `readxl::read_excel` round-trip has collapsed rows string, certificate txt
  contains stage line + status; findings constructor field types; findings print
  snapshot with 2 findings across 2 consequences), watch fail, implement, watch
  pass (READ snapshots — certificate wording is the product's public record),
  format+lint, commit.

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
  `rev_read_joins()`, catching the constructors' classed aborts via their
  `problems` condition field). ALWAYS completes: prints the spec report, writes
  `output/reports/spec-<runstamp>.xlsx` + certificate (amendment 5), returns the
  `rev_report` invisibly (loaded specs as attribute when certified). NO abort on
  problems — status "NOT CERTIFIED" (consistent with `rev_check()` on findings);
  snapshot-tested both statuses. Serves the prespecification workflow
  (dictionary authored before data collection as the extraction instrument's
  source of truth; the CERTIFIED report is the registerable artifact) — spec
  validation deliberately checks that `source.file` is *declared*, never that it
  exists.
- `rev_check(project = ".", quiet = FALSE)` → invisibly the check-stage
  `rev_report` (items = findings) with attribute `assembled` (tibble | NULL).
  Internally begins with the same loading step as `rev_check_specs()`.
  Sequence per D4: read dictionaries + joins spec (spec errors abort) → per table:
  `rev_read_table` → `rev_standardise` → `rev_validate_table` → `rev_join_tables` →
  bind findings → `new_stage_report("check", ...)` (acknowledgments from
  `unmatched_ok` joins; informational annex = unspecified columns per table) →
  unless `quiet`, print the report →
  write `output/diagnostics/preprocessed-<table>.csv` and the check-stage
  report via `rev_export_report()` (`output/reports/check-<runstamp>.xlsx` +
  certificate; runstamp `format(Sys.time(), "%Y%m%d-%H%M%S")`; always written,
  even certified). If the spec stage is NOT CERTIFIED, write the spec report and
  return it — data stages are impossible without valid specs. Never touches
  `data/raw/` (test asserts mtimes unchanged).

- [ ] **Step 1: failing tests** — `rev_check_specs()`: on the miniproject →
  CERTIFIED report snapshot + spec report files exist under `output/reports/`;
  on a copy whose data/raw/ is DELETED → still CERTIFIED (no data required); on
  a bad-spec fixture → completes with status "NOT CERTIFIED", problems as items,
  report files written, no error thrown.
  `rev_check()` on the miniproject: returns findings containing codes
  `{"V003","J004"}` at least (`extra_col` sits in the unspecified annex, not in
  findings); report status "NOT CERTIFIED";
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
  `pkgload::load_all(); lintr::lint_package()` (0), `devtools::test()` (all
  pass), `devtools::check(args = "--no-manual", build_args = "--no-manual",
  error_on = "note")` (0/0/0), plus the phase's duplication/abstraction audit
  (amendment 6): sweep the whole package for facts with two homes, literals in
  code that belong in a registry, and parallel code that failed to generalise;
  findings fixed or explicitly justified before handoff. Fix anything found;
  commit.
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
