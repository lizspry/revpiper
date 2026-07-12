# Spec consolidation — extraction table (2026-07-12)

Step 1 of dev/superpowers/plans/2026-07-12-spec-consolidation-brief.md: every
decision and rationale in the pre-consolidation design spec AND the amendment
trail, each resolved to a disposition. No silent drops; anything whose
rationale is recorded nowhere is marked UNRECORDED and listed as a question
for Liz at the end.

Sources swept:

- dev/superpowers/specs/2026-07-07-revpiper-design.md as amended through
  2026-07-12 ("old §" below refers to that version, at commit 2e1acd2)
- dev/superpowers/plans/2026-07-09-phase-1-implementation.md: Status block
  (pre-flight, execution amendments 1–7), embedded decisions 1–8, Task 3b /
  Task 4 / Task 5 follow-up blockquotes
- dev/superpowers/plans/2026-07-08-phase-1-planning-notes.md (D1–D8 rationale
  trail)
- dev/conventions.md; inst/schema/fields.yaml; inst/schema/checks.yaml; R/

Dispositions ("new §" = the consolidated spec at the same path):

- **kept → §N** — stated once in the named section of the new spec
- **kept → conventions** — the rule's single home is dev/conventions.md; the
  new spec points, never mirrors; the decision itself gets a §9 log row
- **kept → registry** — the instances' single home is inst/schema/*.yaml;
  the new spec describes the model and points
- **kept → plan** — an execution-process fact whose home is the phase plan,
  not the design spec
- **superseded by X** — replaced by a later decision; the supersessor is kept
- **retired — why** — deliberately dropped from the living documents; git
  history remains the record

## Old §1 — Product overview

| # | Decision / rationale | Disposition |
|---|---|---|
| 1.1 | Spec-driven R package: extracted data → manuscript-ready outputs, user-authored specs not user code; GitHub-installable day one, CRAN later | kept → §1 |
| 1.2 | `rev_project()` scaffold; "modify a working template" UX; all logic versioned/tested/centrally fixable in the package | kept → §1, §2 |
| 1.3 | original-repo = inspiration + requirements source, not code to preserve; its data = end-to-end validation fixture; reproducing the paper NOT a goal | kept → §1, §8 |
| 1.4 | Target users: baseline-R health-science researchers; zero-R users and umbrella/scoping reviews excluded from v1 | kept → §2, §3 |
| 1.5 | Module map (processing → static visualisation → interactive layer) + build order; boundary rule: one documented data contract, module 2 never upstream of it, module 1 knows nothing of presentation | kept → §1 (map), §7 (invariant) |
| 1.6 | Name revpiper + `rev_` prefix; rationale (noun+r convention, review signal, no collisions; `synthr` rejected: synthesisr adjacency, "synth" statistics connotation); availability check + repo rename resolved 2026-07-07 | kept → §9 (log rows); prefix rule → conventions |

## Old §2 — Standards & conventions (Areas 1–12)

Old §2 was the standards decision log, duplicated operationally by
dev/conventions.md ("the spec holds the full rationale"). Consolidation makes
conventions.md the single home for the rules; each Area becomes a §9
decisions-log row (decision, date, one-line rationale); fuller rationale
stays in git history (the pre-consolidation spec). conventions.md's origin
note is updated to match. This resolves the mirror the cross-document rule
forbids.

| # | Decision / rationale | Disposition |
|---|---|---|
| 2.1 | Area 1: tidyverse style, uncustomised; Air formatter (styler fallback) | kept → conventions + §9 |
| 2.2 | Area 2: lintr defaults + package-development checks; honestly labelled stricter than tidyverse core | kept → conventions + §9 |
| 2.3 | Area 3: testthat 3e parallel; TDD throughout; coverage measured never gated (~90% informal) — hard gates invite test theatre | kept → conventions + §8 + §9 |
| 2.4 | Area 3: four test layers | kept → §8 |
| 2.5 | Area 4: roxygen2; R Markdown vignettes (not Quarto — contributor dependency; Quarto revisited in module 2); vignettes = primary docs; pkgdown on Pages; site renders README+NEWS only | kept → conventions + §8 + §9 |
| 2.6 | Area 4: NEWS.md hand-curated per user-facing PR; no Conventional Commits (automation payoff designed away by squash merges); fledge noted as later option | kept → conventions + §9; fledge → §3 non-goals |
| 2.7 | Area 4: commenting norms (why not what, brevity bias); documentation templates agreed with real functions during Phase 1 | kept → conventions; templates → §10 (open) |
| 2.8 | Area 5: r-lib GitHub Actions via use_tidy_github_actions + lintr + format-check (format-suggest's pull_request_target privilege pattern declined, Phase 0 am. 5); full OS/R matrix (users skew Windows); branch protection on main | kept → conventions + §9 |
| 2.9 | Area 6: editor format-on-save + mandatory pre-push suite + CI backstop; no pre-commit hooks initially (friction vs solo+Claude team; CI stays authoritative) | kept → conventions + §9; hooks → §3 non-goals |
| 2.10 | Area 7: justify-each-dependency package-wide; depend / vendor standalone / write it; no library() in R/; renv for dev only, CI deliberately unpinned (catches upstream drift); DESCRIPTION declares minimums | kept → conventions + §9 |
| 2.11 | Area 7: renv in the scaffolded user project is a product requirement — version-frozen reviews as a reproducibility credential | kept → §2 (scaffold), §9 |
| 2.12 | Area 8: PR-only main, short-lived branches, squash-merge, plain imperative messages, standard R versioning | kept → conventions + §9 |
| 2.13 | Area 9: MIT license; GPL-dependency note; relicensing conviction needed before external PRs | kept → §9 |
| 2.14 | Area 10: tidyverse R window, floor 4.2; feature allowances/exclusions per version | kept → conventions + §9 |
| 2.15 | Area 11: R/ by topic; mirror rule; `rev_` exports; snake_case; first arg = data/path; same concept same name | kept → conventions + §9 |
| 2.16 | Area 11: original repo's c_/t_/r_ column-prefix scheme NOT carried over | kept → §9 |
| 2.17 | Area 12: functional core + light S3; no R6/S4 without argued need; single responsibility; explicit data flow; fail fast; side effects at orchestration edges | kept → conventions + §7 (doctrine) |
| 2.18 | Area 12: qualified rule of three (+ 2026-07-12 floor-not-barrier note); KISS/YAGNI tiebreakers; usethis-first | kept → conventions + §9 |

## Old §3 — Processing module architecture

| # | Decision / rationale | Disposition |
|---|---|---|
| 3.1 | Names free, shape prescribed, everything declared; general mapping engine rejected (unbounded structural variety); flat finite per-column declaration | kept → §5 |
| 3.2 | Own dictionary schema (data-dict pre-1.0, closed to extensions, Parquet-only validation); reuse its vocabulary; convergence review at data-dict 1.0 | kept → §5 + §9 |
| 3.3 | Topology: one YAML per input table (source/levels/columns) + specs/joins.yaml; dictionaries describe, assembly acts (D2b) | kept → §5 |
| 3.4 | Five prespecified types; type required per column; declared never inferred (prespecify-then-check); datetime dropped from v1 | kept → §5; domain instance → registry |
| 3.5 | `categorical` type removed (inferred storage contradicted prespecification); per-column `pattern` removed (join near-miss suggestions remain the key-drift net) — review amendments 2026-07-09 | kept → §9 (log rows) |
| 3.6 | `values`/`range` mutually exclusive; values on integer/decimal as alternative to range (non-sequential code sets); permission rule per am. 4: boolean admits no constraints, range needs an ordered type, values/units otherwise free | kept → §5 (rule); instances → registry |
| 3.7 | `required`/`unique` booleans; `missing` codes declared reactively (only ""/whitespace auto-missing; no NR/-99 guessing); `constant_within_level`; `description` | kept → §5, §6 |
| 3.8 | Purpose/semantics axis (id/ordinal/quantity, labels) deliberately absent — designed later beside its consumers | kept → §5 |
| 3.9 | Spec files validated at load, before any data; all problems at once; did-you-mean; spec errors stop the run, only data problems become findings | kept → §5 |
| 3.10 | Validation is schema-driven (am. 4): fields.yaml single source of truth; checks generated from properties; scope codes YF/YE/YS/YX; within-source validation standalone, across-source separate/composable/data-free | kept → §5, §7; instances → registry |
| 3.11 | `rev_draft_dictionary()` minimal skeleton in v1; codebook-document parsing stays v1.x | kept → §5, §3 |
| 3.12 | Levels (am. 7a): identifiers merged into `levels:`; entry = column name, `keys:`, or `combine:` (virtual column, optional `separator` default ""); explicit `within:` nesting (matches how users say it; hierarchy checkable); cycles are spec errors; level names always the user's words, nothing pipeline-reserved | kept → §5 |
| 3.13 | Superseded chain for the record: `roles:` (pipeline handles) → renamed `identifiers:`, broad future-roles vision REJECTED (Task 4 follow-up a) → merged into `levels:` (am. 7a); "role" and "identifier" retired vocabulary | superseded by 3.12; rejection of roles vision kept → §9 |
| 3.14 | Composed keys: concatenation only, built after standardisation, exists solely because joins cannot wait for derive | kept → §5 |
| 3.15 | Canonical shape: single denormalised main table, one row per extracted estimate, study-level values repeated; exception: multiple adjustment levels within one row (selection = derivation logic) | kept → §5 |
| 3.16 | Declared levels generate consistency checks (constant within grouping); repetition becomes a free transcription-error check; no declared level, no check; violations route BOTH ways (transcription error vs undeclared substructure) | kept → §5, §6 |
| 3.17 | Input contract: v1 ingests consensus rows only; reviewer declarable as an ordinary level (surfaces disagreement as findings); adjudication stays human; multi-reviewer structures deferred | kept → §2, §5; deferral → §10 |
| 3.18 | Auxiliary inputs in native shapes, each its own declared table + reader + join | kept → §5 |
| 3.19 | Readers replace the declarative-reshape grammar (real shapes are tool-specific patterns; grammar crept toward the rejected mapping engine; user R code is AI-in-distribution); shipped / generic / user readers.R with documented contract; recurring shapes promoted | kept → §6 + §9 |
| 3.20 | Every reader delivers the canonical frame; the join layer never sees orientation; guidance via readers.R template + import-and-shaping vignette (am. 7f) | kept → §6 |
| 3.21 | Joins stay in the pipeline — the value is validation users cannot safely replicate on unclean keys | kept → §5, §6 |
| 3.22 | Joins format (am. 7b): required `adds: variables \| observations` sets the overlap expectation (per-column `shared:` rejected — tedious, the type carries the fact); words deliberately shape-neutral; `granularity` DROPPED (J002 derives from keys + relationship — single home); full dplyr relationship domain (users never reorder a join to fit vocabulary); `relationship`/`unmatched_ok` legal only on variables joins; requiredness applies only where permitted; no wrappers — one dplyr call per spec row with checks around it | kept → §5; instances → registry |
| 3.23 | Guidance-vs-pipeline rule: enumerable + parameterisable-by-declaration + mechanically validatable → pipeline; judgment about content → guidance + corrections | kept → §7 (doctrine) |
| 3.24 | Extraction-tool export formats investigation | resolved 2026-07-09 → readers design; row survives in §10 |
| 3.25 | Run order (D4): per table read → standardise → compose keys → apply corrections → validate; then joins (skipped only on key findings); one consolidated report; rationale: post-join validation would multiply study-level findings across estimate rows | kept → §6 |
| 3.26 | Uniform stage contract (am. 5): every stage command always completes, always emits report + certification through one shared machinery; `output/reports/<stage>-<runstamp>` pairs; one certificate format with a stage line; stage runners never abort on their own items; classed aborts remain for constructors; CERTIFIED spec report = timestamped prespecification artifact | kept → §6 |
| 3.27 | Stage vocabulary provisional (spec → load → correct → transform working model); resolved Task 9 walkthrough + Phase 2 planning | kept → §6 note + §10 |
| 3.28 | Standardise: five closed ordered idempotent ops; encoding lossless (never diacritic-stripping — Müller survives); un-coercible values left standing, column stays text; canonicalisation identity-up-to-case+trim only; counts logged; per-column opt-outs; artifact `preprocessed-<table>` ("clean" reserved for certified); nothing hand-coded per column | kept → §6 |
| 3.29 | Validate: full catalogue on post-standardisation data; always-run always-write; findings carry consequence not severity (severity conflated defect-description with permission — D5); certification absolute, zero standing findings; acceptance only by explicit declaration, listed on the certificate | kept → §6 + §9 |
| 3.30 | Certification is per-scope (am. 7d): a table certificate certifies internal coherence without reference to other files; join-stage issues decertify the joined artifact only | kept → §6 + §9 |
| 3.31 | Undeclared source columns: informational annex, never findings; dropped from pipeline artifacts until declared (am. 3; R006 retired; supersedes the name-only acknowledgment concept) | kept → §6 |
| 3.32 | Corrections: single table-scoped model applied pre-join; predicate targeting; expected match count + expected old value fail loudly; mandatory reason; auto re-validation; raw files never hand-edited (read-only by convention and code) | kept → §6 |
| 3.33 | Derive: three tiers (declarative primitives / built-in named derivations / quarantined custom code); Tier 2 = thin metafor wrappers, zero reimplemented statistics; admission criterion (stable across reviews); Tier 3 promoted on recurrence | kept → §6 |
| 3.34 | Policies (review judgments) declared, not defaulted; canonical instance: direction alignment via user-authored valence reference table; mechanical composition; missing constructs fail loudly by name; the pipeline never guesses | kept → §6 |
| 3.35 | Mappings: collapse/recode maps always derived-keyed sets (overlap + coverage free validation); annotations always value-keyed attributes; two visually distinct shapes for two operations; inline by default, promote to standalone reference table when earned | kept → §6 |
| 3.36 | Findings: user vocabulary only; counts and instances, never first-error-stops; grouped by consequence (= fix-flow ordering); record schema (code, consequence, table, variable, study_id, rows, message, fix_options); routing not prescription; xlsx export (writexl); message copy snapshot-tested | kept → §6 |
| 3.37 | Findings `severity` field (D4 original schema) | superseded by consequence (D5 / old §3.7) |
| 3.38 | Provenance: corrections log, derivation lineage, per-run log, persisted reports, version + spec-checksum stamps; intermediate outputs at stage boundaries, off-switchable; scaffolded projects are git repos + per-run run summary; staleness guards on artefact checksums | kept → §6 |

## Old §4 — User workflow

| # | Decision / rationale | Disposition |
|---|---|---|
| 4.1 | Steps 0–4 (install/scaffold → describe → clean/correct/derive → present → update); the example project runs the moment it is created; update-rerun is the payoff | kept → §2 |
| 4.2 | `rev_check()` = full diagnosis reflecting corrections to date; `rev_clean()` = same + artifacts + certificate. Original "writes nothing" superseded: reports + certificates under `output/reports/`, data diagnostics under `output/diagnostics/` (embedded decision 1, restated by am. 5); "always safe" preserved | kept → §2, §6 |
| 4.3 | Ergonomic commitments: project path everywhere, no working-directory magic; failures name file/column/row and route in user vocabulary; `rev_check()` always safe; `data/raw/` never modified | kept → §2 |
| 4.4 | Capability calibration: floor is baseline R; YAML risk mitigated by templates/findings/AI-assist; codebook(Excel)→YAML = v1.x roadmap item; usability pilot early | kept → §2, §3 |

## Old §5 — Package internals

| # | Decision / rationale | Disposition |
|---|---|---|
| 5.1 | File layout provisional, not a commitment; binding rules: mirror rule, topic-coherent files, utils-<domain>/import-standalone conventions, no user-facing "clean" before certification; reshuffling free in PRs | kept → §7 |
| 5.2 | S3 classes: few, purposeful, friendly print(); the planned set (rev_dictionary, rev_findings, rev_report, rev_corrections, rev_derivation_spec, rev_dataset as data-contract-in-object-form) | kept → §7 |
| 5.3 | Error doctrine: three vocabularies for three audiences (spec / data / internal); all messages via cli; entry-point validation via rlang checkers | kept → §7 |
| 5.4 | No config file, no global options, no environment magic; a run's inputs = project directory + function call | kept → §7 |
| 5.5 | Logging: cli console (suppressible) + plain-text per-run log in output/ | kept → §6 |

## Old §6 — Visualisation module boundary

| # | Decision / rationale | Disposition |
|---|---|---|
| 6.1 | Input boundary = the data contract only (forcing function for contract completeness) | kept → §3, §7 |
| 6.2 | Content-preparation vs rendering split; one prepared object, N renderers | kept → §3 |
| 6.3 | Declarative output spec + rev_render(); citation keys resolved at document render; figures as modifiable ggplot objects; namespace/scaffold reservations | kept → §3 |

## Old §7 — Testing strategy

| # | Decision / rationale | Disposition |
|---|---|---|
| 7.1 | Four layers: unit / synthetic-review integration / original-review validation fixture / metafor agreement | kept → §8 |
| 7.2 | Fixture policy (Liz 2026-07-09 + D8): Covidence dummy export committable; family workbook NEVER committed — local-only skip-if-absent; committed synthetic derivative in Phase 3 | kept → §8 |
| 7.3 | Synthetic dataset = designed artefact with the awkward realities; triple duty (fixture, scaffold example, vignette narrative) so it cannot rot | kept → §8 |
| 7.4 | Two-layer schema tests (am. 4d): generated property matrix proves logic by construction; small curated fixture set + snapshots guards wording and routing | kept → §8 |
| 7.5 | Kitchen-sink "complete-example" fixture DROPPED (Task 4 gate, do not resurrect): matrix + good fixture + boundary-legal test carry positive coverage | kept → §8 |

## Old §8 — Risks, open questions, roadmap

| # | Decision / rationale | Disposition |
|---|---|---|
| 8.1 | Five risks + mitigations (expressiveness, YAML vs user, data-dict immaturity, derivation creep, maintainer bandwidth) | kept → §3 |
| 8.2 | Open-questions table — every row, with owners and statuses; resolution mechanism (owned questions become first tasks of the owning phase's planning; resolutions committed back into the spec) | kept → §10, all rows |
| 8.3 | Explicit v1 non-goals | kept → §3 |
| 8.4 | Roadmap phases 0–5 with per-phase notes | kept → §3 |
| 8.5 | Appendix of externally verified references | kept → Appendix |

## Phase-1 plan — Status block, embedded decisions, follow-ups

| # | Decision / rationale | Disposition |
|---|---|---|
| P1 | Pre-flight finding + embedded decision 8: CLAUDE.md → .claude/ so pkgdown renders README+NEWS only; exclusion config / build wrapper / custom check dropped as YAGNI | kept → §9 |
| P2 | Embedded decision 1: rev_check writes reports + diagnostics (see 4.2) | kept → §2, §6, §9 |
| P3 | Embedded decision 2: the ten Imports with per-package justifications | kept → plan (implementation record; process rule → conventions) |
| P4 | Embedded decision 3: all raw ingestion is character — types exist only through declared coercion, nothing guessed before the dictionary speaks | kept → §6 |
| P5 | Embedded decision 4: dictionary lists exactly the columns of interest (am. 3): type required; declared columns must exist; undeclared columns informational and dropped | kept → §5, §6, §9 |
| P6 | Embedded decision 5: boolean coercion = TRUE/FALSE case-insensitive; date = strict ISO round-trip | kept → §6 |
| P7 | Embedded decision 6: shipped reader registry v1 = covidence + generic csv/excel; user readers from readers.R in an isolated environment | kept → §6 |
| P8 | Embedded decision 7: draft generator lands in Phase 1 (needed for the dress rehearsal) | kept → §3 |
| A1 | Amendment 1: r-lib standalone vendoring DROPPED (upstream moved checkers into rlang exports; depend-first); rlang floor 1.3.0; `%||%` sole namespace import | kept → conventions + §9 |
| A2 | Amendment 2: stop_spec naming, typed-NA assertion, vectorised formatting | kept → conventions (Naming closed decisions) |
| A3 | Amendment 3: see P5; plus Y012/Y020 extensions and the missing-file guard (error-doctrine conformance) | kept → §5, §6; check instances → registry |
| A4 | Amendment 4: schema-driven validation (see 3.10); scope taxonomy + renumbering; two-layer tests (7.4); terminology to conventions; deferred decisions logged | kept → §5, §7, §8 + conventions |
| A5 | Amendment 5: uniform stage reporting (see 3.26–3.27); pipeline gating deferred | kept → §6; deferral → §10 |
| A6 | Amendment 6: single-source-of-truth invariant (principles + processes in conventions; plan gains audit backstops) | kept → conventions + §7 pointer + §9 |
| A7 | Amendment 7 (a–h): levels merge (3.12), joins redesign (3.22), schema restructure — `kinds:` grouping dissolves appears_in, per-kind field properties, `requires` + `permitted_adds` properties, "kind" provisional wording; certification per-scope (3.30); J-semantics parked (→ §10); reader guidance (3.20); Task 4 rework as Task 5 Step 0; structural reviews at Task 14 | kept → §5, §6, §7, §9, §10; instances → registry |
| T1 | Task 3b follow-up: shape vocabulary consolidated (mapping/list_of_mappings + contains); schema-driven recursion; generalised identity check | kept → §7 (model); properties → registry |
| T2 | Task 4 gate (a): level/role keys are user-chosen, never policed; known-name lookups report absence informationally | kept → §5 + §9 |
| T3 | Task 4 gate (c): /simplify trial on task diffs, edits reviewed jointly | kept → plan (execution protocol) |
| T4 | Task 4 follow-up (c) granularity question | superseded by am. 7b (granularity dropped) |
| T5 | Task 4 follow-up (d): early-return exits rely on a "reported one level up" promise — deserves an explicit gate; structural follow-up | kept → plan (Task 14 structural review scope) |
| T6 | Task 4 follow-ups (b)(e): plain-language terminology, five researcher-first words, retired-words list | kept → conventions (Terminology) |
| T7 | Task 4 follow-up (f): kinds/sections/levels overlap smell | superseded by am. 7 (its resolution); residual vocabulary gaps → architecture discussion (plan Task 5-close blockquote), direction logged → §9 |
| T8 | Task 5-close (1): format-review / architecture-discussion agenda (schema vocabulary gaps, permitted_when generalisation, "kind" wording, same-named-field divergence list — currently `keys`) | kept → plan (agenda); direction + triggers → §9 log row per the brief |
| T9 | Task 5-close (2): collaborator deliverable framing; the three collaborator situations (two pre-data-collection, one retrofitting) | kept → §2 (situations); deliverable framing → plan |
| N1 | Planning notes D1–D8: rationale trail for the decisions above | kept → planning-notes doc (unchanged); §9 rows cite dates |

## Questions for Liz (UNRECORDED rationale)

None found: every decision swept above carries a recorded rationale in the
spec, the plan, the planning notes, or a registry comment. Two items are
recorded as deliberately provisional rather than unrecorded — the user-facing
stage vocabulary (3.27) and the "kind" wording (A7) — and survive as such.
