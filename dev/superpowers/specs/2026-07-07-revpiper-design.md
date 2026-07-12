# revpiper — Design Specification

- **Date:** 2026-07-07; consolidated 2026-07-12. This document states the
  current design once. Git history holds the evolution: the amendment trail
  lives in the pre-consolidation spec (through commit 2e1acd2), the phase
  plans, and dev/superpowers/plans/2026-07-08-phase-1-planning-notes.md; the
  consolidation audit is
  dev/superpowers/plans/2026-07-12-spec-consolidation-extraction.md.
- **Status:** consolidated per the 2026-07-12 brief; pending Liz's diff
  review. All content restates decisions already signed off; the rewrite
  adds none.
- **Process:** produced through Socratic brainstorming
  (superpowers:brainstorming); decisions made jointly and incrementally with
  Liz, dated in §9. AI-assisted (Claude Code); auditable via this
  repository's git history per TRIPOD-LLM disclosure practice.
- **Companion documents:** dev/conventions.md is the single home for coding
  rules (style, naming, testing, dependencies, git, single-source
  principles, terminology). inst/schema/fields.yaml and
  inst/schema/checks.yaml are the registries holding every spec-field
  property and check instance. This spec points at those homes and never
  mirrors them.
- **Scope:** whole-project standards and architecture; the processing module
  in detail. The visualisation module gets its own brainstorm and spec
  later; only its boundary is fixed here (§3).

## 1. Purpose & goals

**revpiper** is an open-source R package that takes a systematic review team
from *extracted data* to *manuscript-ready and supplementary outputs*,
driven by user-authored specifications rather than user-written code. It is
GitHub-installable from day one; CRAN is a possible later milestone, not a
prerequisite. Exported functions carry the `rev_` prefix (naming rationale
in §9).

A scaffolding function (`rev_project()`) generates a ready-to-run project —
data folders, complete working example specs wired to a bundled synthetic
dataset, a three-line run script — so the user experience is "modify a
working template" while all logic stays versioned, tested, and centrally
fixable in the package. The scaffolded project is a git repository with renv
initialised: each user's review is version-frozen, a reproducibility
credential for systematic reviews.

The existing Python/R pipeline (`original-repo`) is inspiration and
requirements source, not code to preserve. It defines the tasks the new tool
must achieve; the means may differ freely. Its raw data, transformed data,
and final outputs serve as an end-to-end validation fixture (study-level,
published-paper data, confirmed non-sensitive). Reproducing the original
paper is explicitly not a goal.

Three modules, built in order:

1. **Processing module** (this spec, detailed): user files + data dictionary
   in → assembled, cleaned, validated, corrected, transformed, certified
   dataset out.
2. **Visualisation module, static** (own spec later): consumes the processed
   dataset through one stable data contract; produces standard review
   tables/figures with declarative control.
3. **Interactive layer** (explicitly deferred): constrains module 2 only via
   the shared content-preparation boundary.

The boundary rule between them is an architecture invariant (§7): a single
documented data contract — the processed dataset plus machine-readable
metadata travelling together. Module 2 never reaches upstream of it; module
1 knows nothing about presentation.

## 2. Users & ways of working

**Target users:** health-science researchers conducting standard reviews
(intervention/exposure–outcome) with baseline R skills — can install
packages, follow a vignette, run a short script, and edit well-templated
plain-text specs. Explicitly not served in v1: zero-R users (the future
interactive layer's audience) and umbrella/scoping reviews.

**Collaborator situations** the design serves (recorded 2026-07-12): three
reviews engage at the spec/dictionary design stage — two before data
collection, where the dictionary is authored first and doubles as the
extraction instrument's source of truth, and one retrofitting a completed
collection for cleaning, derivation, and visualisation. For the pre-data
collaborators, flexibility is explicit: the dictionary is not a lock-in;
piloting and extraction changes are expected, and the spec evolves with the
review.

**The workflow** is a sequence of discrete steps — **spec → load →
process**, then **transform** (v2) and **present** (v3) — each a standalone
unit of work with its own verification, its own report + certification
(§6.1), and its own fix surface. Steps compose through `rev_run()`
(default: all shipped steps; `through =` stops earlier — steps are prefixes
of one deterministic run from the raw files, §6.2, so nothing stale passes
between them), and each step keeps its own check command (spellings settle
at each phase's implementation walkthrough). The order is how work is
checked and delivered, not a straitjacket: a user can add a dataset first
and generate a template dictionary from it (`rev_draft_dictionary()`), or
author and certify the full spec before any data exists.

- **Get the project (once):** `remotes::install_github(...)`;
  `rev_project("my-review/")` creates `data/raw/`, `specs/`
  (`tables/<table>.yaml` per input + `joins.yaml`; transform declarations
  and reference tables from v2 — all as complete working examples wired to
  the bundled synthetic dataset), `readers.R` and `derivations.R` templates
  (each with a fill-in-the-blanks AI-assistant prompt block),
  `corrections.csv`, `run.R`, `output/`, renv initialisation, git init. The
  example project runs successfully the moment it is created; users swap in
  their reality piece by piece.
- **Spec:** author dictionaries and joins by editing the working templates;
  verify (data-free); fix by editing the spec YAML. Deliverable: a
  CERTIFIED spec report — a timestamped prespecification artifact,
  achievable as a first or standalone deliverable before data collection
  begins.
- **Load:** drop data files into `data/raw/`; verify structurally — files
  readable, sheets present, declared columns found, undeclared columns
  annexed. Fix by editing the dictionary, re-exporting the source file, or
  fixing the reader.
- **Process:** standardise → correct → validate → join (§6.2); fix via
  `corrections.csv` (the audited value-level mechanism) or spec edits.
  Deliverable: the certified clean dataset — the natural sign-off point.
- **Transform (v2):** declare derived variables and mappings (the transform
  stage's own prespecification spec); run; verify against the derived
  dictionary; fix via the mapping/valence tables or spec edits.
- **Present (v3):** a declarative output spec + `rev_render()`, consuming
  only the data contract; processing and presentation rerun independently.
- **Update (the payoff):** new search results → update the raw file →
  `rev_run()`. Corrections re-apply (stale ones fail loudly by name);
  derivations re-run identically; the run summary and git diff show exactly
  what changed.

Check commands diagnose without touching pipeline state: they always
reflect the user's corrections to date, and their outputs are reports and
diagnostics only (`output/reports/`, `output/diagnostics/` — §6), never
pipeline artifacts or anything in `data/raw/`.

**Ergonomic commitments:** every user-facing function takes the project path
(no working-directory magic); failures name file/column/row and route to the
fix location in the user's vocabulary; check commands are always safe;
`data/raw/` is never modified.

**Capability calibration (accepted):** the floor is baseline R, not zero-R.
YAML risk is mitigated by modify-don't-write templates, complete findings,
and AI-assist-friendly plain text; codebook(Excel)→YAML generation is a v1.x
roadmap item if piloting demands it. Declaring keys and levels is review
methodology, not programming — the vignette's worked example carries it. The
v1 input contract is consensus rows only — one extraction of record per row;
a reviewer column can be declared as an ordinary level, which surfaces
disagreement as findings if pre-consensus data is fed, and adjudication
stays human (multi-reviewer structures: §10).

## 3. Scope & non-goals

**Releases map to workflow steps (§2):** **v1** ships the spec, load, and
process steps (through clean-certification, including the corrections
engine), the scaffold, the designed synthetic review, task-oriented
vignettes, and the minimal dictionary draft generator
(`rev_draft_dictionary()` — needed for the dress rehearsal). **v2** ships
transform; **v3** ships the visualisation module. ("v1/v2/v3" are milestone
names; the R version numbers they ship under follow standard
MAJOR.MINOR.PATCH practice, decided at release.)

**Explicitly out of scope for v1:** the transform and present steps (v2 and
v3); the interactive layer and dashboards; umbrella/scoping reviews;
codebook-document→YAML parsing (the draft generator is in; document parsing
stays v1.x); CRAN submission; pre-commit hooks; fledge-style NEWS
automation.

**Visualisation module — boundary commitments only:** input is the data
contract, never raw files or upstream specs (the forcing function keeping
the contract complete). Content preparation is split from rendering:
prepared, renderer-agnostic objects handed to dumb renderers
(flextable→Word and Quarto-compatible emitters in v1; interactive widgets
later) — one prepared object, N renderers, the structural anti-duplication
guarantee. A declarative output spec + `rev_render()` names the standard
outputs (study-characteristics table, results/evidence table, forest-style
display, RoB summary). Study-level tables carry per-row citation keys
resolved at document render time against the user's `.bib`; figures are
ggplot2 objects with save helpers. Reserved now: the `prepare-*.R` /
`render-*.R` namespace and an output-spec slot in the scaffold. Everything
else stays open for module 2's own brainstorm.

**Roadmap** (each phase: spec → plan → TDD → review). Phases mirror the
workflow steps deliberately — one contained, PR-able workflow unit per
phase (decision 2026-07-12):

- **Phase 0 — bootstrap:** DONE (merged 2026-07-08).
- **Phase 1 — spec:** schema machinery, dictionary and join spec checking,
  spec reports/certification, the spec-step command, spec-axis file
  layout. The expressiveness risk starts burning down here. IN PROGRESS
  (dev/superpowers/plans/2026-07-09-phase-1-implementation.md, as re-cut by
  execution amendment 8).
- **Phase 2 — load:** readers (shipped, generic, user-written), structural
  R-checks, findings machinery, the load report;
  `rev_draft_dictionary()` (a spec-axis tool, but it reads data files, so
  it ships here); `rev_run()` arrives with the second step.
- **Phase 3 — process:** standardise, validate, join execution, the
  corrections engine, clean-certification.
- **Phase 4 — scaffold + synthetic review + vignettes** (`rev_project()`,
  designed synthetic dataset, getting-started and prepare-your-data
  vignettes, pkgdown live).
- **Phase 5 — dress rehearsal** (original-review specs + validation fixture;
  divergences adjudicated individually).
- **Phase 6 — usability pilot** → **v1**.
- **Phase 7 — transform** (three tiers, metafor wrappers, policies,
  derived-dictionary certification) → **v2**; then the module-2
  (visualisation) brainstorm → v3.

**Risks & mitigations:**

1. *Spec language can't express real reviews* (existential): early dress
   rehearsal (test layer 3) + the Tier-3 pressure valve; every gap found
   becomes a design fix pre-users.
2. *YAML defeats the target user*: templates, findings quality, AI-assist;
   usability pilot; codebook→YAML as the v1.x response.
3. *data-dict immaturity*: own schema with aligned vocabulary (§5), no CLI
   dependency; convergence review at data-dict 1.0.
4. *Derivation-catalogue creep*: Tier-2 admission criterion +
   promote-on-evidence.
5. *Maintainer bandwidth (R-beginner maintainer)*: small exported API; CI
   vigilance; conventions doc making every session consistent.

## 4. Concepts & vocabulary

The settled vocabulary — column, field, entry, section, kind, level,
virtual column, property, check, problem, finding — is defined in
dev/conventions.md (Terminology), together with the retired-words list
("role", "identifier", "context", "block", "collection", "appears_in",
"walker"). That section is the single home; this spec uses the terms without
redefining them. The load-bearing distinctions:

- **Problems vs findings:** spec defects are *problems* (reported at load,
  in spec-file vocabulary); data defects are *findings* (accumulated,
  routed, never aborting). Only internal bugs produce tracebacks.
- **Consequence, not severity:** a finding states what it mechanically
  prevents, never how bad it is (§6).
- **Certification:** a stage report's status — CERTIFIED exactly when zero
  standing items — with explicit, listed acknowledgments as the only pass.
- **Scopes:** spec checks are coded by how much context they read — YF
  (one field), YE (one entry), YS (one file), YX (across files); data-side
  families are R (reading), V (per-table validation), J (joins), C
  (corrections application).

## 5. The spec stage

### 5.1 Core concept

The pipeline never demands prescribed column names. The user authors a data
dictionary describing their own columns; everything downstream refers to
columns via the user's names. What is prescribed is the canonical shape
(§5.3) and the declarations each stage consumes. This is deliberately not a
general mapping engine (rejected: unbounded structural variety): every
declaration is flat, finite, and per-column or per-entry.

revpiper owns its dictionary schema. data-dict was evaluated and not
adopted (pre-1.0, closed to extension keys, Parquet-only validation); its
vocabulary is reused where concepts overlap, its check-code/level
architecture adopted, and a convergence review is logged for data-dict 1.0.

### 5.2 Dictionaries

One YAML file per input table (`specs/tables/<table>.yaml`) carrying:

- `table` (the file's identity) and optional `description`;
- `source:` — file, optional sheet, optional reader (§6, read stage);
- `levels:` (§5.3);
- `columns:` — one entry per column of interest.

The dictionary lists exactly the columns the user imports, checks, and
uses. Each column entry declares a required `type` — five prespecified
types (text, integer, decimal, boolean, date; no datetime in v1); the type
is declared, never inferred, because the stage's purpose is
prespecify-then-check. Optional restrictions: `values` (closed set — on
text, and on integer/decimal as the alternative to `range`, so
non-sequential code sets are closed-checkable) and `range`/`units`;
`values` and `range` are mutually exclusive per column. The permission rule:
boolean admits no constraint fields; `range` needs an ordered type;
`values`/`units` are otherwise free. Also per column: `required`/`unique`
booleans, `missing` codes (declared reactively via findings; only
""/whitespace are auto-missing), `constant_within_level` (§5.3),
`description`. The purpose/semantics axis (id/ordinal/quantity, value
labels) is deliberately absent — designed later beside its consumers
(transform, module 2).

Source columns not declared are surfaced informationally, never as
findings, and are dropped from pipeline artifacts until declared (§6).

`rev_draft_dictionary()` generates minimal skeletons from data files:
column names + draft types for the user to confirm, empty fields —
deliberately minimal; cleaning concerns do not belong in dictionary
authoring.

### 5.3 Canonical shape and levels

The main input is a single denormalised table, one row per extracted
estimate, study-level characteristics repeated on each of a study's rows —
matching how extraction actually happens. Preserved exception: multiple
adjustment levels for a single estimate live within one row; selecting
among them is derivation-layer logic. Multiple estimates per study are the
natural case; single-estimate reviews are the trivial special case.
Auxiliary inputs (e.g. an RoB workbook) stay in their native shapes, each
its own declared table with its reader and its join.

`levels:` maps each user-named grouping of the data to what identifies it:
a bare column name, `keys:` naming column(s), or `combine:` naming columns
whose concatenation (optional `separator`, default `""`) builds a **virtual
column** named by the level. Combined keys exist solely because joins
cannot wait for the transform stage; they are concatenation only, built
after
standardisation. Optional `within:` names the parent level — nesting is
explicit because that matches how users say it and makes the hierarchy
itself checkable; nesting cycles are spec errors. A level's keys may
reference another level's virtual column; forward references among sibling
levels are legal. Level names are always the user's own words — nothing is
pipeline-reserved, and level keys are never policed against a pipeline
vocabulary (pipeline consumers that look up a conventional name report its
absence informationally, never as a finding).

Declared levels buy generated consistency checks: values declared
`constant_within_level` must be constant within their grouping, so the
canonical shape's repetition becomes a free transcription-error check. No
declared level, no check. A violation routes BOTH ways — transcription
error (a correction) or undeclared substructure (add a level key) — since
some studies reveal substudies only through usually-constant variables
differing.

### 5.4 Joins

`specs/joins.yaml` declares each combination independently; a missing file
is a valid single-table project. Joins stay in the pipeline because the
value is the validation users cannot safely replicate on unclean keys. Per
join:

- `adds: variables | observations` (required) — the join's declared type,
  which sets the overlap expectation: `variables` is a mutating join, where
  non-key column overlap becomes a data-side finding; `observations` is a
  row append, where column mismatch becomes the data-side finding and the
  keys are identity columns for cross-table collision checks. The words are
  deliberately shape-neutral — a wide input's on-disk layout never changes
  what a join *adds*; orientation is the reader's job (§6).
- `left`/`right` — the two sides, resolved against the loaded tables.
- `keys:` — complete (composite where needed) key sets, both sides covered;
  key columns resolve against the side's declared plus virtual columns.
- `relationship` — the full dplyr domain (one-to-one, one-to-many,
  many-to-one, many-to-many), passed through to dplyr's `relationship`
  enforcement; users never reorder a join to fit the vocabulary.
- `unmatched_ok` — the explicit acknowledgment for legitimately-partial
  joins.

`relationship` and `unmatched_ok` are legal only when `adds: variables`,
and requiredness applies only where a field is permitted. There are no
wrappers: each spec row compiles to one dplyr join / bind_rows call with
checks around it. There is no per-join granularity declaration — uniqueness
expectations derive from `keys` + `relationship` (single home).

### 5.5 Spec validation

Spec files are validated at load, before any data is read, and spec errors
stop the run — specs must parse; only data problems become findings. Every
problem is reported at once (never first-error-stops), with file-and-entry
precision and did-you-mean suggestions; a broken field reports its root
cause once rather than cascading.

Validation is schema-driven: `inst/schema/fields.yaml` declares every spec
field's properties, and checks are generated from properties — one
definition per check, instances declared in the schema (the model is §7.2;
the field-by-field facts live only in the registry). Codes carry the scope
prefixes of §4, and the full catalogue with message templates and fix
routes is `inst/schema/checks.yaml`.

Within-source validation is standalone: one dictionary file validates
completely alone, with zero knowledge of other sources. Across-source
validation (join references, table-name uniqueness) is a separate,
composable, data-free step. This preserves the prespecification workflow —
a dictionary can be authored, validated, and certified before any data
exists, deliberately checking that `source.file` is declared, never that it
exists (§6, stage contract).

## 6. The pipeline stages

### 6.1 Stage contract

Every user-facing stage command always completes and always emits a report
plus certification through one shared machinery: stage name, timestamp,
items, status, acknowledgments, informational annex — written to
`output/reports/` as `<stage>-<runstamp>.xlsx` (items) and
`<stage>-<runstamp>-certificate.txt`, one certificate format with a stage
line. Stage runners never abort on their own items: spec problems make a
NOT CERTIFIED spec report exactly as findings make a NOT CERTIFIED check
report; classed aborts remain for constructors called directly. A CERTIFIED
spec report doubles as a timestamped prespecification artifact,
registerable before data collection. Data diagnostics
(`preprocessed-<table>.csv`) go under `output/diagnostics/`.

Certification is absolute — zero standing findings — and per-scope: a table
certification certifies internal coherence and correctness without
reference to other files; join-stage issues decertify the joined artifact
only, with fixes routing back into tables as needed. Acceptance happens
only by explicit declaration (e.g. `unmatched_ok: true`), listed on the
certificate.

The steps are named **spec, load, process, transform** (resolved
2026-07-12; "derive" is retired as the user-facing stage word). Reports and
certificates carry the step name; `rev_run()` (renamed from
`rev_process()`, whose old name became a step's) composes the steps —
default all shipped, `through =` to stop earlier — and per-step command
spellings settle at each phase's implementation walkthrough.

### 6.2 Run order and stages

The load step reads each table; the process step then runs per table:
standardise → compose keys → apply corrections → validate; then joins
(skipped only on key findings); one consolidated process report. Every
per-table check runs before joins because post-join validation would
multiply study-level findings across estimate rows. The steps are prefixes
of this one deterministic run — running a later step re-does the earlier
work from the raw files and reports it, so nothing is handed between steps
and nothing can go stale; the one true handoff is transform consuming the
certified clean artifact.

**Load.** Readers produce canonical per-table frames (rows = observations,
columns = the declared variables); the join layer never sees orientation.
Shape-normalisation happens through readers, not a user-facing reshape
grammar (real export shapes are tool-specific patterns; a grammar crept
toward the rejected mapping engine, and user R code is
massively in-distribution for AI assistants): a shipped per-tool importer
(v1 registry: `covidence` plus generic csv/excel), a parameterised generic
reader, or a user-written function in the project's `readers.R` (documented
contract: file in → canonical table out; sourced into an isolated
environment; recurring shapes promoted into shipped importers). All raw
ingestion is character — types exist only through declared coercion, so
nothing is guessed before the dictionary speaks. Undeclared source columns
are returned as an informational list, reported and carried on the
certificate as an annex, and dropped from pipeline artifacts until
declared.

**Standardise** (automated, dictionary-driven, deterministic; re-derived
from the untouched raw file each run). Five closed, ordered, idempotent
ops: lossless encoding normalisation (UTF-8/NFC, exotic whitespace,
zero-width; never diacritic-stripping or transliteration — Müller survives
to presentation); trim (leading/trailing only); missing standardisation
(""/whitespace built-in; per-column declared codes); type coercion —
boolean accepts exactly TRUE/FALSE case-insensitively, date is strict ISO
round-trip, and un-coercible values are left standing for validation to
report (a column with any failure stays text — never half-coerced, never
silently nulled); safe declared-values canonicalisation (identity up to
case+trim against a declared value; no fuzzy matching). Counts logged per
column; per-column named opt-outs; artifact written as
`preprocessed-<table>` ("clean" is reserved for the certified artifact).
Nothing hand-coded per column — everything generated from declarations.
Machine-fixable issues therefore never appear as findings, only as log
counts; findings are always the post-standardisation, post-corrections
residual.

**Validate** (per table). The full check catalogue on post-standardisation
data, so findings are exactly the set requiring human judgment. Always-run,
always-write: every check that can run always runs; the report is always
complete. Findings carry a consequence, not a severity (severity conflated
defect-description with permission; consequence describes, the user decides
what to fix when): key findings → joins skipped; un-coercible → dependent
checks on that column not run; every finding → not certifiable.

**Join.** Declared joins execute with checks around them: non-unique keys,
relationship violations, and unmatched rows in both directions — with
near-miss suggestions (suggest-only, resolved via corrections, never
auto-applied) as the key-drift net. The loud failure remains the
*undeclared* many-to-many. Exact data-side semantics for declared
many-to-many joins and observation appends are parked (§10).

**Corrections** (manual, audited; engine lands in Phase 3 against a
designed-in per-table seam). A corrections file applied programmatically —
the auditable replacement for hard-coded patch lines. Every correction
targets a named input table and applies pre-join, where the value
physically lives (`table` defaults away for single-input reviews). Each
entry: predicate targeting (column=value conditions), an expected match
count and, for replacements, the expected old value — either mismatch fails
loudly by correction (the data shifted underneath) — and a mandatory
`reason`. Automatic re-validation follows. Raw files are never hand-edited
(read-only by convention and code); the fix path is a correction entry or a
fresh export committed as a new data version.

**Transform** (v2). Three tiers, in declared order, each derivation
documenting inputs/outputs for lineage:

- *Tier 1 — declarative primitives* (closed set, pure spec): recode/map,
  collapse, bin, rename, coalesce, conditional assignment,
  map-via-reference-table.
- *Tier 2 — built-in named derivations*: effect-size computations as thin
  wrappers over metafor's `escalc()` — zero reimplemented statistics; tests
  assert agreement with metafor, never with hand-derived values. Admission
  criterion: only derivations whose definition is stable across reviews;
  anything encoding a review's judgment enters as user-declared rules or
  custom code, never as package defaults.
- *Tier 3 — quarantined custom code*: a spec entry pointing at a
  user-written function in `derivations.R`; provenance distinguishes
  built-in from custom. Recurring Tier-3 patterns get promoted into Tier 2.

Policies (review judgments) are declared, not defaulted. Canonical
instance — direction alignment: a mechanical coding-direction column, a
user-authored construct-valence reference table (the researcher's
meaning-decision externalised as a reviewable, citable artefact), and
mechanical composition with a provenance flag. Constructs missing from the
valence table fail loudly by name; the pipeline never guesses.
Best-estimate selection follows the same pattern.

Mappings come in two visually distinct shapes for two distinct operations:
collapse/recode maps are always derived-keyed sets (one line per derived
value; free validation — no raw value in two sets, no raw value in none
unless a passthrough policy is declared), while annotations are always
value-keyed attributes. Inline by default; promoted to a standalone
reference table only when earned (long, reused, or externally maintained).
Both forms feed identical machinery.

**Certify & hand off** (closes transform, v2). Validation against the
derived dictionary (the user declares expectations for derived variables
too — the transform stage's own prespecification), provenance stamping, and
the data contract written to `output/`. In v1, the process step's
clean-certification is the terminal certificate.

### 6.3 Findings

- User vocabulary only: their column names, their study IDs.
- Counts and instances, grouped by consequence — which is also the fix-flow
  ordering.
- Record schema: `code`, `consequence`, `table`, `variable`, `study_id`
  (where an identifying study value is resolvable; the exact lookup is a
  Phase 1 plan item), `rows` (numbered against the named
  `preprocessed-<table>` artifact), `message`, `fix_options`.
- Routing, not prescription: every finding says *where* to act
  (corrections vs dictionary vs joins spec — mechanically determinable from
  the check type), offers both routes where genuinely ambiguous, and never
  claims to know the correct value.
- Automatic export to Excel (one row per finding) — where review teams
  actually triage; console print and data-frame access remain.
- Message copy is interface: snapshot-tested, so wording regressions fail
  tests and phrasing is reviewable in PR diffs.

### 6.4 Provenance & auditability

Corrections log with reasons; derivation lineage; per-run plain-text log in
`output/`; reports persisted per run; every output stamped with package
version + spec checksums. Intermediate outputs at each stage boundary, on
by default, off-switchable. Cross-run comparison: scaffolded projects are
git repositories (specs, corrections, outputs committed — study-level data
is small and non-sensitive) plus a per-run run summary (row counts,
correction hits, derivation and findings counts), so diffs answer "what
changed since last run"; stale corrections failing loudly is the third leg.
Artefact checksums are staleness guards: the transform step on an
out-of-date clean snapshot warns loudly; `rev_run()` makes staleness
impossible by construction.

## 7. Architecture

### 7.1 Invariants

- **The data contract** (§1): module 2 consumes only the contract; module 1
  knows nothing about presentation. Anything module 2 needs must arrive via
  the contract.
- **Guidance-vs-pipeline rule:** an operation belongs in the pipeline,
  declaratively, when it is (a) from an enumerable set, (b) parameterisable
  by declaration rather than judgment, (c) mechanically validatable. It
  belongs in guidance + corrections when it requires human judgment about
  content. Reshapes (in readers), joins, coercions, recodes: pipeline.
  Fixing a mistyped author name, adjudicating duplicates: corrections.
- **Single source of truth** (principles and processes in
  dev/conventions.md): every fact has one authoritative home, preferably
  data; code is generic over declared facts; registry-first for new
  fact-families. In revpiper the registries are `inst/schema/fields.yaml`
  and `inst/schema/checks.yaml`.
- **Error doctrine — three vocabularies for three audiences:** spec errors
  point at spec file + entry; data errors accumulate into findings in user
  terms; internal errors are ours and the only tracebacks. All messages via
  cli; entry-point validation via rlang's checkers.
- **Functional core + light S3:** pure functions composable into stages; S3
  for spec objects and results with validators and friendly `print()`
  methods; no R6/S4 unless a specific need is argued; explicit data flow —
  no globals, no hidden state; side effects quarantined at the
  orchestration layer.
- **No config file, no global options, no environment magic:** a run's
  inputs are the project directory (specs) and the function call. The
  original pipeline's config.yaml is absorbed by specs + scaffold
  conventions.
- **Prespecify-then-check** (§5): nothing inferred that the user can
  declare; declared expectations checked against reality, with the
  mismatch reported in the user's vocabulary.

### 7.2 The schema grammar

The package schema (`inst/schema/fields.yaml`) is the single source of
truth for spec-field validation. Its model:

- A closed `kinds:` list names the kinds of entry (file, source, column,
  level, join, join_file). Fields are grouped under their kind — the
  grouping *is* the statement of legality, and parse-time duplicate-key
  failure polices field names at the right scope, so the same field name
  may carry kind-specific properties per kind (level `keys` vs join `keys`:
  same concept, same word). "kind" is provisional wording — internal-only,
  cheap to rename (§10 pointer).
- A `properties:` section defines the property vocabulary itself (meaning,
  loading type, allowed values); loaders and conformance tests read it, so
  property handling exists nowhere in code.
- Checks are generated from properties: one definition per check, instances
  declared in the schema, codes and message templates in
  `inst/schema/checks.yaml` (registry entries keyed by code, so duplicates
  fail at parse). Container fields declare what kind of entry they hold
  (`contains`); a mapping with no contained kind has user-chosen keys —
  data, not vocabulary.
- Conditional permissions exist as two instances of one pattern
  (`permitted_types` on column types, `permitted_adds` on join types); a
  third occurrence forces the general mechanism (rule of three; the
  candidate `permitted_when` generalisation is on the architecture-
  discussion agenda held in the phase-1 plan).

A deferred schema refactor is recorded as direction, not plan (§9): the
vocabulary gaps found while building Task 5 (a mapping-of-entries container
shape, scalar shorthand as a property, a one-of requirement, acyclic
refers_to) would each replace custom code with schema rows.

### 7.3 Package internals

R files mirror the workflow units on two axes (decision 2026-07-12).
`spec-*` files hold declaration surfaces: `spec-check.R` (the shared
schema-driven check battery — the one named exception to files-as-workflow-
units, since shared machinery belongs to no single unit), `spec-source.R`
(one dictionary, within-source, plus reading the set), `spec-join.R` (the
join declarations, across-source), `spec-draft.R` (the skeleton generator),
and later `spec-transform.R` (the derived-variable prespecification, which
validates through the same battery). Execution stages prefix their own
files: `load*.R`, `process-*.R` (standardise, validate, join, correct,
certify), `transform-*.R`. Stage-neutral machinery is unprefixed
(`schema.R`, `report.R`, `findings.R`) or `utils-*`. Within that principle
the layout stays adjustable: the binding rules remain the mirror rule,
topic-coherent files, and no user-facing "clean" naming before
certification; reshuffling in PRs is free and expected. S3 classes are few
and purposeful: `rev_dictionary`, `rev_findings`, `rev_report` exist;
`rev_corrections`, `rev_derivation_spec`, and `rev_dataset` (a tibble
subclass carrying dictionary/lineage/checksums as attributes — the data
contract in object form) arrive with their phases.

## 8. Quality & testing strategy

Four test layers:

1. **Unit tests** (bulk; mirror rule): tiny inline tibbles; normal, edge,
   and expected-failure paths asserting the *right finding*; snapshot tests
   on rendered messages.
2. **Integration tests on the bundled synthetic review**: scaffold → specs
   → all stages → expected shape/values/provenance. The synthetic dataset
   is a designed artefact deliberately containing the awkward realities,
   and does triple duty — test fixture, scaffold example, vignette
   narrative — so it cannot rot.
3. **Original-review validation fixture**: real study-level data with specs
   we author — the design's first dress rehearsal, surfacing
   expressiveness gaps before any outside user. Asserts agreement with the
   original pipeline's outputs (numeric tolerance for effect sizes; exact
   for counts); divergences individually adjudicated. Skip-if-absent guard.
4. **metafor agreement tests**: Tier-2 wrappers vs direct `escalc()` calls
   — enforcing zero-reimplemented-statistics.

Schema validation gets two layers of its own: a property matrix generated
from the schema (every property × every field, applies and does-not-apply)
proves the logic by construction, and a small curated fixture set with
snapshots guards wording and routing. A kitchen-sink "complete example"
fixture was considered and dropped — the matrix, the good fixtures, and the
boundary-legal tests carry positive coverage; do not resurrect it.

Fixture policy: the Covidence example export is dummy data and may seed
shape-realistic fixtures; the real family-comparison workbook is NEVER
committed — it serves as a local-only, skip-if-absent fixture, with a
committed synthetic derivative folded into Phase 4's designed synthetic
review.

Infrastructure: testthat 3e, parallel, TDD, covr+Codecov measured-not-
gated, full-matrix CI (rules in dev/conventions.md). Message copy, spec
reports, and certificates are the product's public voice: every new
snapshot is read before acceptance.

## 9. Decisions log

One row per decision: date, decision, one-line rationale. Fuller rationale:
git history (the pre-consolidation spec), the planning notes, and the
phase-1 plan's amendment trail.

| Date | Decision | Rationale |
|---|---|---|
| 2026-07-07 | Name `revpiper`, exports `rev_`-prefixed; repo renamed before first push | noun+r convention, review signal, no collisions; `synthr` rejected (synthesisr adjacency, "synth" = synthetic data in statistics) |
| 2026-07-07 | Tidyverse style, Air formatter; lintr defaults + package checks | community standard; only maintained linter; deliberately stricter than tidyverse core given team composition |
| 2026-07-07 | testthat 3e + TDD; coverage measured, never gated | hard gates invite assertion-free test theatre; TDD keeps real coverage high |
| 2026-07-07 | roxygen2; R Markdown vignettes as primary docs; pkgdown site | Quarto would add a contributor dependency (revisited in module 2) |
| 2026-07-07 | NEWS.md hand-curated per user-facing PR; no Conventional Commits | squash merges + GitHub release notes design away the automation payoff |
| 2026-07-07 | r-lib CI workflows, full OS/R matrix, branch protection; format-check not format-suggest | maintained workflows; users skew Windows; format-suggest's `pull_request_target` privilege pattern declined (Phase 0) |
| 2026-07-07 | Pre-push suite + CI backstop; no pre-commit hooks | friction vs a solo-plus-Claude team; CI stays authoritative regardless |
| 2026-07-07 | Justify-each-dependency; depend / vendor / write; renv dev-only, CI unpinned | aggregate-use test; unpinned CI catches upstream drift early |
| 2026-07-07 | renv required in scaffolded user projects | version-frozen reviews are a reproducibility credential |
| 2026-07-07 | PR-only main, squash-merge, standard R versioning | PRs are the review gate over AI-produced work; one clean commit per task |
| 2026-07-07 | MIT license | tidyverse default; maximises adoption; relicensing conviction needed before external PRs |
| 2026-07-07 | R floor 4.2 (tidyverse window) | native pipe and `_` placeholder usable; no newer-than-floor features without logged justification |
| 2026-07-07 | Mirror rule; `rev_` prefix; snake_case; first arg = data/path; c_/t_/r_ scheme not carried over | discoverability for weak-R users; the new data model is designed on its own merits |
| 2026-07-07 | Functional core + light S3; rule of three (qualified); usethis-first | matches r-lib practice; R6 only where mutable state is essential |
| 2026-07-08 | v1 input contract: consensus rows only | formal tools resolve discrepancies upstream; reviewer declarable as an ordinary level; adjudication stays human |
| 2026-07-08 | Own dictionary schema; data-dict vocabulary reused; no CLI; convergence review at 1.0 | data-dict is pre-1.0, closed to extension keys, Parquet-only validation |
| 2026-07-08 | Readers replace the reshape grammar; joins stay in the pipeline; one YAML per table + joins.yaml | real shapes are tool-specific patterns; the grammar crept toward the rejected mapping engine; join validation is the value users cannot replicate |
| 2026-07-08 | Draft generator minimal; assisted authoring via templates + AI-prompt scaffolds | cleaning concerns don't belong in dictionary authoring; the surface awaits user consultation |
| 2026-07-09 | Five types; `categorical` and per-column `pattern` removed; composition moved to the key block | inferred storage contradicted prespecification; join near-miss suggestions remain the key-drift net |
| 2026-07-09 | Five standardisation ops, lossless encoding, `preprocessed-` naming | machine-fixable issues should never be findings; "clean" reserved for the certified artifact |
| 2026-07-09 | Per-table validation before joins; single table-scoped corrections model | post-join validation multiplies study-level findings across estimate rows |
| 2026-07-09 | Consequence replaces severity; certification absolute; always-run always-write | severity conflated defect-description with permission; consequence describes, the user decides |
| 2026-07-09 | File layout provisional; fixture policy (dummy Covidence in, real workbook local-only) | layout has no structural meaning in R packages; identifiable review content stays private |
| 2026-07-09 | `rev_check()` writes reports + diagnostics (supersedes "writes nothing") | findings' row numbers must reference an inspectable artifact; "always safe" preserved |
| 2026-07-10 | CLAUDE.md relocated to .claude/ (pkgdown renders README+NEWS only) | pkgdown 2.2.0 has no exclusion config; relocation beats build wrappers (YAGNI) |
| 2026-07-10 | Vendoring dropped; rlang floor 1.3.0; `%||%` the sole namespace import | upstream moved the needed checkers into rlang's exports; depend-first |
| 2026-07-10 | Dictionary lists exactly the columns of interest; `type` required; undeclared columns informational | no consequence means no finding; list-and-drop keeps artifacts honest |
| 2026-07-11 | Schema-driven validation: fields.yaml + generated checks + scope codes; standalone-source rule | one definition per check; single source of truth; prespecification needs files that validate alone |
| 2026-07-11 | Uniform stage reporting; stage runners never abort; `output/reports/` layout | spec development must work standalone and leave a durable, registerable record |
| 2026-07-11 | Single-source-of-truth invariant adopted (conventions) | recurring duplication was caught reactively; prevention became structural |
| 2026-07-11 | Level/role keys are user-chosen, never policed; broad roles vision rejected | users reference their own column names directly for later purposes |
| 2026-07-12 | `identifiers:` merged into `levels:`; explicit `within:` nesting; virtual columns | one concept, one section; explicit nesting matches how users say it and is checkable |
| 2026-07-12 | Joins: required `adds:` type; `granularity` dropped; full dplyr relationship domain; per-column `shared:` rejected | the declared type carries the overlap expectation; uniqueness derives from keys + relationship (single home) |
| 2026-07-12 | Schema restructure: fields grouped under `kinds:`; `requires` + `permitted_adds` properties; "kind" wording provisional | grouping states legality and polices duplicates at the right scope; same word for the same concept per kind |
| 2026-07-12 | Certification is per-scope | a table certificate certifies internal coherence; join issues decertify only the joined artifact |
| 2026-07-12 | Deferred schema refactor recorded as direction, not plan. Triggers: the architecture discussion / Phase 2 planning, and Task 14's structural review | the vocabulary gaps (container shape, scalar shorthand, one-of, acyclic refers_to, `permitted_when`) each replace custom code with schema rows — decided with the full check inventory in view |
| 2026-07-12 | No architecture-review skill | considered and dropped as overengineering |
| 2026-07-12 | Spec consolidated (this rewrite) | git holds the history; the document holds the present |
| 2026-07-12 | Workflow re-modelled as discrete steps — spec → load → process → transform (v2) → present (v3) — each with its own verification, report + certificate, and fix surface (spec: edit YAML; load: dictionary, source file, or reader; process: corrections.csv or spec; transform: mapping/valence tables or spec) | modular units workable standalone and composable; the fix mechanism honestly differs per step and findings route accordingly |
| 2026-07-12 | `rev_run()` (renamed from `rev_process()`) composes steps, default all shipped, `through =` to stop earlier | the pipeline is stateless, so steps are prefixes of one run — "which steps" honestly means "how far"; "process" became a step name |
| 2026-07-12 | Step vocabulary settled: spec, load, process, transform; "derive" retired as the user-facing stage word | resolves the provisional stage vocabulary (amendment 5) ahead of its Task 9 schedule |
| 2026-07-12 | Releases: v1 = spec + load + process; v2 = transform; v3 = vis. Phases re-cut one workflow unit each (Phase 1 = spec only); corrections + clean-certification move ahead of transform | phases mirroring steps keeps each deliverable contained and manageable; verify-and-correct is what makes v1 complete |
| 2026-07-12 | Two-axis file naming: `spec-*` declaration surfaces vs `load-`/`process-`/`transform-*` execution; shared machinery unprefixed; spec-dictionary.R splits into spec-check.R + spec-source.R; spec-joins.R renamed spec-join.R | files map to discrete workflow units; the shared battery is the one named exception |
| 2026-07-12 | Held architecture agenda closed: user-facing format passes the convolution check; "kind" wording kept; same-named-field divergence list kept (conformance test guards drift); schema vocabulary gaps + `permitted_when` stay deferred — triggers: the transform spec's kinds as the likely third permission instance, and phase close-out structural reviews | decide with evidence in view; build nothing speculatively |

## 10. Open questions (with owners)

| Question | Owner | Status |
|---|---|---|
| data-dict: format-only vs CLI dependency | Module-1 implementation planning | **Resolved 2026-07-09** (§5.1: own schema, aligned vocabulary, no CLI; convergence review at data-dict 1.0) |
| Shared-mapping representation (named in-spec vs external files) | Module-1 implementation planning | Open — deferred to Phase 7 (transform) planning (derivation mappings; value→label maps deferred there too, 2026-07-09) |
| Extraction-tool export formats (Covidence, DistillerSR) | Module-1 implementation planning | **Resolved 2026-07-09** (real-file investigation → readers design, §6.2; findings in the Phase 1 planning notes) |
| `escalc()` coverage vs original pipeline's derivations | Module-1 implementation planning | Open — Phase 7 (transform) planning |
| Check-type→routing table for findings | Module-1 implementation planning | **Structured 2026-07-09** (scope/family codes + consequence model, §4/§6); full enumeration incl. the data-dict coverage mapping delivered in the phase-1 plan |
| Multi-reviewer row structures (declaration + handling; v1 = consensus rows only) | Later phase / user consultation | Open (deferred 2026-07-09) |
| Citation rendering (flextable/officer vs Quarto-mediated) | Module-2 design | Open |
| `revpiper` availability check; repo rename | First implementation step | **Resolved 2026-07-07** (Phase 0) |
| Documentation templates per function type | Phase 1, with real functions | Open — lands during Phase 1 implementation |
| Missing-codes-in-dictionary vs corrections split (UX) | Usability pilot / user consultation | Open (flagged 2026-07-09) |
| Package split: data spec / data process / data vis as 2-3 packages (boundary discipline enforced now — spec machinery never reaches pipeline internals) | Later phase decision | Open (flagged 2026-07-11, amendment 4) |
| User-facing stage model: step names, correct standalone vs folded, joins placement, function/report/certificate renames | Task 9 walkthrough (report naming); Phase 2 planning (full model) | **Resolved 2026-07-12** (workflow amendment, plan amendment 8: steps spec → load → process → transform, each with verify + fix; joins execute and report in process, the joins *spec* reports in the spec step; `rev_run()` composes; per-step command spellings settle at each phase's walkthrough) |
| Joins declaring expected column overlap between sides (`shared:`); overlap semantics differ between same-variables merges and different-information merges | Task 5 walkthrough (Phase 1) | **Resolved 2026-07-12** (amendment 7: the join's declared type `adds: variables \| observations` sets the overlap expectation; per-column `shared:` rejected) |
| Data-side J-check semantics for declared many-to-many joins (candidates: observed-vs-declared looseness nudge, row accounting on the join report) and for observation appends (column match with near-miss suggestions, key collisions); J-code assignments | Phase 3 (process) — old Task 11's walkthrough | Open (flagged 2026-07-12, amendment 7e) |
| Certification granularity: certify table A while table B is broken? | Task 5 walkthrough (Phase 1) | **Resolved 2026-07-12** (amendment 7d: yes — table certifications certify internal coherence only, without reference to other files) |
| R file organisation: review what lives in each per-topic R file vs a shared utils file, once enough code exists to see the seams | First pass at Task 14's audit; revisit at Phase 2 planning | **Resolved 2026-07-12** (two-axis scheme, §7.3; seams confirmed at each phase's close-out review) |
| Workflow ordering: within-source data checking + corrections vs across-source post-join checking + corrections; join spec may be authored upfront so sheets are set up compatibly; pipeline gating rules for partial processing (loading/processing one source before others are join-ready) — amendment 5 defers | Phase 3 (process) planning (corrections engine) | Open (flagged 2026-07-11) |
| Schema vocabulary gaps (container shape, scalar shorthand, one-of, acyclic refers_to) and `permitted_when` generalisation — the deferred refactor direction, §9; `rev_spec_run()`'s per-kind dispatch (file routing, reader, output slot, and `read_joins()`'s dictionaries-NULL scope sentinel) noted as further instances awaiting the same registry — deferral agreed (Liz, 2026-07-12): build the registry when the transform spec arrives, shaped by three real kinds, and look then for common structure ACROSS steps (a registry spanning all steps' kinds, not just the spec step's) | Phase close-out structural reviews; the transform spec's kinds are the likely third permission instance | Open ("kind" wording **Resolved 2026-07-12**: kept, internal-only) |
| Joins disposition in the spec step's audit/run commands | Task 17 walkthrough (Phase 1) | **Resolved 2026-07-12** (amendment 9d: TRUE/FALSE `joins` parameter, default TRUE — the user intentionally overrides; TRUE + no joins.yaml errors, FALSE skips without warning; disposition always stated on report + certificate) |
| Per-step `rev_<step>_run` vs the step-free `rev_run(through =)` (amendment 8): overlapping user surfaces; incumbent reads `rev_<step>_run` as the stateless prefix run through that step, with step-free `rev_run()`/`rev_audit()` possibly kept as thin sugar wrappers (Liz leans keep; plan amendment 9e) | Phase 2 planning | Open (deferred 2026-07-12) |
| Importing externally generated data dictionaries into the spec format: REDCap (and similar EDC tools) auto-export an Excel/CSV dictionary that a converter could turn into spec YAML; its choice encodings (e.g. `1, No \| 2, Yes`) map to value labels, and its branching-logic column (format unverified; likely "show if fieldX = value") could seed conditional spec-data checks (cf. `permitted_when`, §9) | Later phase (spec importers); needs real REDCap exports from Liz to pin the formats | Open (flagged 2026-07-12, Liz) |

**Resolution mechanism:** when a phase begins, its owned questions become
the first tasks of that phase's planning step (typically short
investigations). Each resolution is committed back into this spec via PR,
so the spec remains the living, dated record of decisions.

## Appendix: externally verified references consulted during design

- Air formatter: posit-dev/air; tidyverse blog (Feb 2025, Jun 2025);
  usethis `use_air()`. Distribution: Positron-bundled, installer script,
  Homebrew, pixi/mise; not on CRAN (Rust binary).
- Tidyverse practice: tidy tools manifesto; design.tidyverse.org; tidyverse
  CONTRIBUTING (per-PR NEWS bullets); tidyups 004 governance
  (squash-merge); `use_tidy_github_actions()`; style.tidyverse.org/news.html.
- Repo inspections (July 2026 clones): tidyverse/ellmer,
  tidyverse/duckplyr, r-lib/usethis — air.toml universal; no `.lintr`;
  format-suggest workflows; `Config/testthat/parallel`; `utils-<domain>.R`;
  `import-standalone-*.R`; usethis AGENTS.md.
- data-dict: github.com/tidyverse/data-dict (YAML spec + Rust CLI;
  validate-spec/meta/data ladder; agent skills).
- Ecosystem: metafor/escalc; synthesisr, revtools, metagear (Lajeunesse
  2016, Methods Ecol Evol), PRISMA2020, appraise; pharmaverse
  (metacore/metatools/admiral pattern — pattern adopted, packages not).
- R versions: R 4.6.1 current (June 2026); native pipe/lambda R 4.1; `_`
  placeholder 4.2; extended placeholder 4.3; base `%||%` 4.4.
