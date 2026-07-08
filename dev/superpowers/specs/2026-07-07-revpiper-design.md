# revpiper — Design Specification

- **Date:** 2026-07-07
- **Status:** Approved by Liz (section-by-section) pending final review of this written document
- **Process:** Produced through Socratic brainstorming (superpowers:brainstorming); all decisions below were made jointly and incrementally. AI-assisted (Claude Code); auditable via this repository's git history per TRIPOD-LLM disclosure practice.
- **Scope of this spec:** standards & conventions (whole project), architecture (whole project), processing module (detailed). The visualisation module gets its own brainstorm and spec later; only its boundary is fixed here.

---

## 1. Product overview

### 1.1 What this is

An open-source R package, **revpiper**, that takes a systematic review team from *extracted data* to *manuscript-ready and supplementary outputs*, driven by user-authored specifications rather than user-written code. It is GitHub-installable from day one; CRAN is a possible later milestone, not a prerequisite.

The package ships a scaffolding function (`rev_project()`) that generates a ready-to-run project — data folders, complete working example specs wired to a bundled synthetic dataset, a three-line run script — so the user experience is "modify a working template," while all logic stays versioned, tested, and centrally fixable in the package.

### 1.2 Relationship to the original review (`original-repo`)

The existing Python/R pipeline is **inspiration and requirements source, not code to preserve**. It defines the tasks and functionality the new tool must achieve; the means may differ freely. Its raw data, transformed data, and final outputs serve as an end-to-end **validation fixture** (the data is study-level, drawn from published papers, confirmed non-sensitive and usable). Reproducing the original paper is explicitly **not** a goal.

### 1.3 Target users

Health-science researchers conducting standard reviews (intervention/exposure–outcome), with **baseline R skills**: can install packages, follow a vignette, run a short script, and edit well-templated plain-text specs. Explicitly not served in v1: zero-R users (the future interactive layer's audience), umbrella/scoping reviews.

### 1.4 Module map and build order

1. **Processing module** (build first): user files + data dictionary in → assembled, cleaned, validated, corrected, derived, certified dataset out.
2. **Visualisation module, static** (build second; own spec later): consumes the processed dataset through one stable data contract; produces standard review tables/figures with declarative user control. Citation-rendering investigation lives here.
3. **Interactive layer** (explicitly deferred; own brainstorm later): interactive supplements, possibly a dashboard. Constrains module 2 only via the shared content-preparation boundary (no code duplication across output types).

**Boundary rule:** a single documented data contract — the processed dataset plus machine-readable metadata (dictionary + derivation provenance travelling together). Module 2 never reaches upstream of it; module 1 knows nothing about presentation.

### 1.5 Name

Package name **revpiper**; exported-function prefix **`rev_`**. Rationale: noun+`r` R-community convention; "piper" humanises the pipeline metaphor; "rev" keeps the review signal; no apparent collisions in the evidence-synthesis package cluster (revtools, metagear, synthesisr, PRISMA2020, appraise). `synthr` was rejected: one syllable from `synthesisr` (different purpose, same community) and "synth" connotes synthetic data/controls in statistics (`synthpop`, `synthdid`, `Synth`).

- Mechanical availability check (`available::available("revpiper")`) is the first implementation step.
- Rename window: cheap until the package is publicised and others' scripts call `rev_*` functions; the deadline for final conviction is **before inviting external users/contributors** (which precedes CRAN anyway). GitHub repo may stay `review-pipeline` or be renamed to match — decided at first push. **Resolved (Liz, 2026-07-07, before first push):** repo renamed to `revpiper`, so DESCRIPTION URLs, badges, and the pkgdown URL carry the final name from the start; local working folders may keep the old name (R reads only DESCRIPTION).

---

## 2. Standards & conventions (decision log)

These apply to this project and serve as Liz's standing template for future coding projects. Each area lists the decision and its rationale. The overall calibration, verified against current tidyverse/r-lib repositories (ellmer, duckplyr, usethis, July 2026): **current tidyverse practice, deliberately stricter on linting and testing discipline.**

### Area 1 — Style & formatting

- **Tidyverse style guide**, standard conventions, no customisation. Rationale: the de facto community standard (default target of styler/lintr/Air; used by tidyverse, r-lib, rOpenSci); easiest to learn from precedents; friction-free for contributors. Liz's Python-leaning preferences noted but standardisation chosen deliberately for simplicity and collaboration.
- **Air** as formatter (Posit, 2025; deliberately non-configurable in the mould of black; confirmed present as `air.toml` in all inspected tidyverse repos). styler is the fallback if Air hits a limitation. Air is developer tooling only — users never need it.

### Area 2 — Linting

- **lintr**, default tidyverse rules **plus package-development checks** (undeclared dependencies, `library()` in package code, etc.). Rationale: the only maintained general R linter; catches real bugs, not just style.
- Honest label: this is **stricter than tidyverse core practice** (none of the inspected repos carry a `.lintr`; they substitute intensive human review). Deliberate choice given team composition.

### Area 3 — Testing

- **testthat (3rd edition)**, `Config/testthat/parallel: true`. **TDD throughout** (per Liz's standing instructions).
- Four test layers (see §7 for detail): toy-data unit tests; synthetic-dataset integration tests; original-review validation fixture; metafor agreement tests.
- **Coverage:** covr + Codecov, **measured and visible on every PR, never gated**. ~90% informal expectation on core logic. Rationale: hard gates invite assertion-free test theatre; TDD keeps real coverage high; reports catch blind spots (uncovered lines = never-tested behaviour).

### Area 4 — Documentation

- **roxygen2** for function reference (no alternative worth considering; examples are executed by checks and cannot rot).
- **Vignettes in R Markdown** (not Quarto, for now — avoids a contributor system dependency; Quarto questions consolidated in module 2). Task-oriented vignettes are the **primary user-facing documentation** and get the writing effort; reference docs complete but terse.
- **pkgdown** site on GitHub Pages, auto-deployed by CI. Heavy or web-context content goes in `vignettes/articles/` (website-only, not bundled — installs from GitHub skip vignette building by default, so the site is the primary consumption channel anyway).
- **NEWS.md** changelog, hand-curated for a user audience: every user-facing PR includes its own one-line bullet (review-checklist enforced). No Conventional Commits requirement (automation payoff designed away by squash merges + GitHub auto release notes; commit messages describe code for developers, NEWS describes changes for users). `fledge`-style automation noted as a later option (observed in duckplyr) if per-PR bullets prove annoying.
- **Commenting:** tidyverse norms (why, not what; no density quotas) with a **brevity bias** — internal helpers ideally a single line. A "documentation templates by function type" section (exported / internal / pipeline-stage) will be agreed with real functions in front of us during Phase 1 and added to the conventions doc.

### Area 5 — Continuous integration

- **GitHub Actions using r-lib's maintained workflows**, installed via `usethis::use_tidy_github_actions()` (covers full-matrix `R CMD check` failing on warnings, coverage→Codecov, pkgdown deploy) **plus** the stock lintr workflow **plus** Air formatting via the **format-suggest pattern** (posts the formatting diff as a PR suggestion rather than failing — observed as current tidyverse practice, friendlier than a hard `--check`).
- Full OS/R-version matrix (users skew Windows; dev happens on Linux/macOS).
- **Branch protection on `main`**: PRs required, checks must pass, no direct pushes.

### Area 6 — Enforcement layers

- Editor format-on-save (Liz: VS Code + Air extension + R extension for inline lintr) + **mandatory pre-push suite** (format, `devtools::test()`, `lintr::lint_package()`; `devtools::check()` before PRs) — encoded here as convention and wired into Claude Code session hooks so it is mechanical for AI sessions + **CI as backstop**.
- **No pre-commit hooks initially** (friction vs. a solo-plus-Claude team; CI must stay authoritative for outside contributors regardless). Revisit only if unformatted commits actually slip through.

### Area 7 — Dependencies & reproducibility

- **Tidyverse-friendly Imports** where they carry weight (dplyr, tidyr; ggplot2, flextable in module 2). `Depends` reserved for the R version only.
- **Justify-each-dependency, evaluated package-wide**: would removing it cost meaningful replicated code, correctness risk, or consistency *summed across all uses*? Weigh maintainer quality (r-lib ≫ solo-maintainer) and API surface used. Justifications logged in the conventions doc. Trigger points: writing similar boilerplate again (consider adding), a dependency used once trivially (inline and drop), release-time audits.
- Three-way choice per need: **depend / vendor a standalone / write it** — vendoring via `usethis::use_standalone()` (r-lib-blessed single files, provenance headers, never hand-edited; observed as `import-standalone-*.R` in ellmer). `standalone-types-check` earmarked for input validation.
- **No `library()` calls in package code** (lintr-enforced).
- **renv for the development environment** (lockfile in repo, `.Rbuildignore`d; reproducible across disposable sandboxes). **CI deliberately unpinned** — installs current CRAN per `DESCRIPTION`, catching upstream drift early. Packages don't pin for users; `DESCRIPTION` declares minimum versions.
- **renv in the scaffolded user project is a requirement** (module 1): each user's review version-frozen — a reproducibility credential for systematic reviews.

### Area 8 — Git workflow & versioning

- **PR-only `main`** (branch protection), short-lived feature branches (one per task, deleted after merge). Rationale: PRs are Liz's review gate over AI-produced work (auditable bounded diffs with CI verdicts), match the sandbox workflow, and are the single workflow outside contributors must use anyway.
- **Squash-merge** every PR (one clean commit per finished task on `main`; TDD micro-history remains in the closed PR). Verified as tidyverse practice.
- Plain, imperative, informative commit messages; body only when the *why* needs explaining.
- **Standard R versioning**: MAJOR.MINOR.PATCH + `.9000` in-development convention; version bump + NEWS heading per release; releases as GitHub releases (tags).

### Area 9 — License

- **MIT** (tidyverse default; maximises adoption for an academic tool). Note: depending on GPL packages (e.g. flextable) does not force our license under the general R-community understanding. Relicensing requires all contributors' consent — final conviction needed **before accepting external PRs**.

### Area 10 — R version support

- **Tidyverse window**: current release + 4 previous minor versions (floor **R 4.2** as of July 2026, R current 4.6.1; rolls forward annually). Native pipe `|>` and lambda `\(x)` (both 4.1) fully usable; `_` placeholder (4.2) usable; extended placeholder forms (4.3) and base `%||%` (4.4) avoided — rlang's `%||%` used instead. No newer-than-floor features without logged justification.

### Area 11 — Naming & file structure

- `R/` organised by coherent topic: one file per pipeline stage, `utils-<domain>.R` for shared internals (observed convention in usethis), one file per S3 class. No numbering (load order is irrelevant in packages).
- **Mirror rule**: every `R/` file has a `tests/testthat/test-*.R` twin (documented convention, R Packages 2e); principled exceptions allowed (package-doc file, vendored standalones).
- **All exported functions prefixed `rev_`** (discoverability by autocomplete for weak-R users; collision-proofing). Internals unprefixed.
- snake_case everywhere; verbs for functions, nouns for objects; **first argument of user-facing functions is the data / project path**; same concept = same argument name across the whole API.
- The original repo's `c_`/`t_`/`r_` column-prefix scheme is **not** carried over; the new data model is designed on its own merits.

### Area 12 — Code design principles

- **Functional core + light S3**: pure functions (data frame + explicit args in → data frame out) composable into pipeline stages; S3 for spec objects/results with validators and friendly `print()` methods. **No R6/S4 unless a specific need is argued** (matches observed r-lib practice: R6 only where mutable state is essential, e.g. ellmer's chat sessions).
- Single responsibility; exported functions are the user vocabulary (few, stable); internal helpers free and encouraged; explicit data flow (config and data always passed as arguments — no globals, no hidden state); **fail fast** with `cli::cli_abort()` and entry-point input validation; side effects (I/O, messages) quarantined at the orchestration layer.
- **Qualified rule of three**: second occurrence of similar code → note it; third occurrence → **mandatory decision** — extract, or leave a one-line written justification (comment/PR note). Legitimate escapes: coincidental (semantically distinct) duplication; cross-module-boundary duplication where coupling costs more; test code (readable self-contained tests trump DRY). Exact-and-obvious duplication may extract earlier.
- KISS and YAGNI as tiebreakers; the sanctioned exception is module boundaries, designed ahead so output types never force duplication.
- **usethis-first**: prefer provided, maintained scaffolding over hand-rolled configuration; hand-roll only with logged justification (mirror of the dependency rule, applied to tooling).

---

## 3. Processing module architecture

### 3.1 Core concept: names free, shape prescribed, everything declared

The pipeline never demands prescribed column names. The user authors a **data dictionary describing their own columns** — names, types, allowed ranges, controlled vocabularies — and assigns **roles** (which column identifies the study; which holds design, sample sizes, estimates…). Everything downstream refers to columns via the user's names. What is prescribed is the **canonical shape** (below) and the finite set of roles required by whichever stages the user runs. This is not a general mapping engine (rejected: unbounded structural variety); role assignment is a flat, finite, per-column declaration.

**data-dict.yaml**: the dictionary format follows the tidyverse `data-dict.yaml` specification (tables, columns, types, constraints, enum vocabularies, relationships, glossary; designed for human/AI co-authoring). **Open decision (this module's implementation planning):** adopt the *format* with our own R-native validation — the current lean, since the reference CLI is a Rust binary users cannot be asked to install — vs. depending on the CLI (dev-side optional at most). Worst case we own a fork of a sensible schema.

### 3.2 Canonical shape and levels

- **Main input: a single denormalised table, one row per extracted estimate**, study-level characteristics repeated on each of a study's rows — matching how extraction actually happens in Excel. Exception preserved from real practice: multiple adjustment levels for a single estimate live within one row; selecting among them is derivation-layer logic.
- **Declared column levels**: the dictionary may declare each column's level — estimate-, sample-, or study-level — with user-declared keys defining each level (a paper can report multiple samples; nesting is the user's, never assumed). Consistency checks are *generated from declarations*: values constant within their declared grouping. Repetition thereby becomes a free transcription-error check. No declared level, no check.
- **Auxiliary inputs in their native shapes** (e.g. the RoB workbook, one study per column, kept because it is ergonomically right for scoring): each declared in the dictionary with its orientation/reshape and its join.
- Multiple estimates per study are the natural case (rows); single-estimate reviews are the trivial special case.

### 3.3 Assembly (declared structure, not guidance and not a mapping engine)

Assembly operations are a **small, closed, enumerable set** — reshape (transpose, pivot) and join (by declared keys) — so they are *declared* per input file in the dictionary and executed by a generic assembly step. Joins declare — **each join independently, since keys and granularity can vary across the joins of a single review**: keys, **granularity** (study-level join on the study key; estimate-level join on study key + user-declared estimate key, e.g. outcome + respondent), and **expected relationship** (`one-to-one`, `one-to-many`), enforced via dplyr's `relationship` argument. Validation reports non-unique declared keys and unmatched rows (both directions, by study ID); the loud failure is reserved for the *undeclared* case (classically accidental many-to-many row explosion).

**Guidance-vs-pipeline rule (general):** an operation belongs in the structured pipeline, declaratively, when it is (a) from an enumerable set, (b) parameterisable by declaration rather than judgment, (c) mechanically validatable. It belongs in guidance + the manual-corrections step when it requires human judgment about content. Reshapes, joins, coercions, recodes: pipeline. Fixing a mistyped author name, adjudicating duplicates: corrections.

Extraction-tool export formats (Covidence, DistillerSR, Excel forms) are a **named investigation item** so the reshaping vignette addresses real exports.

### 3.4 The six stages

1. **Assemble** — declared reshapes and joins → one canonical long table. Fails on: undeclared many-to-many, non-unique declared keys; reports unmatched rows.
2. **Clean (automated, dictionary-driven, deterministic)** — whitespace/encoding normalisation; NA standardisation (empty, whitespace-only, declared missing codes → NA); type coercion per declared types, with un-coercible values *left standing for validation to report* (never silently nulled); vocabulary-safe canonicalisations where declared. Everything logged with counts; per-column opt-outs. Nothing hand-coded per column — cleaning is generated from declarations.
3. **Validate** — the full findings ladder (structure → types → values → declared-level consistency) on *post-cleaning* data, so findings are exactly the set requiring human judgment. **Complete-then-block**: every check always runs; the report is always complete; error-severity findings block progression (warnings don't).
4. **Corrections (manual, audited)** — a corrections file applied programmatically; replaces hard-coded patch lines with an auditable log. Each correction: **predicate targeting** (any combination of column=value conditions; one or many rows), **expected match count** (or ≥1) and, for value replacements, **expected old value** — either mismatch fails loudly by correction (the data shifted underneath); mandatory `reason`. Followed by automatic re-validation. Raw files are **never hand-edited** (read-only by convention and code); the fix path is a correction entry or a fresh export committed as a new data version.
5. **Derive** — the three-tier layer (§3.5), in declared order, each derivation documenting inputs/outputs for lineage.
6. **Certify & hand off** — validation against the *derived* dictionary (user declares expectations for derived variables too), provenance stamping, data contract written to `output/`.

### 3.5 Derivation: three tiers + policies as declarations

**Tier 1 — declarative primitives** (closed set, pure spec, no R): recode/map, collapse categories, bin, rename, coalesce, conditional assignment, map-via-reference-table.

**Tier 2 — built-in named derivations** (invoked declaratively; implemented and hard-tested by us): effect-size computations as **thin wrappers over metafor** (`escalc()`; `esc`/`effectsize` where gaps appear) — the wrapper is unavoidable glue (spec→function-call translation) plus our value-add (role-aware columns, missing-data policy, findings-style errors, provenance); **zero reimplemented statistics** — tests assert agreement with metafor, never with hand-derived values. Also: CI→SE conversions, parameterised presentation-string builders. **Admission criterion:** Tier 2 admits only derivations whose definition is stable across reviews; anything encoding a review's judgment enters as user-declared rules or custom code — never as package defaults. Coverage mapping of `escalc()` against the original pipeline's derivations: named investigation item.

**Tier 3 — quarantined custom code**: a spec entry may point to a user-written function in the project's `derivations.R` (one documented template: data in → new column(s) out). Output provenance distinguishes built-in from custom derivations (transparency for the user's own reviewers). Recurring Tier-3 patterns across reviews get promoted into Tier 2 — dissolving the anticipate-everything burden.

**Policies (review judgments) are declared, not defaulted.** Canonical instance — **direction alignment**: (i) extraction-level coding-direction column (mechanical); (ii) a user-authored **construct valence reference table** (construct → direction relative to a user-chosen target frame, e.g. assumed risk) — the researcher's meaning-decision externalised as a reviewable, citable artefact; (iii) mechanical composition (final flip = coding direction ⊕ valence ⊕ target frame) with a `direction_flipped` provenance flag. Constructs missing from the valence table fail loudly by name; the pipeline never guesses. Best-estimate selection: same pattern (user-declared preference rules). Both were hard-coded review-specific logic in the original pipeline; here they are user artefacts.

### 3.6 Mappings and reference tables

- **Collapse/recode maps are always derived-keyed sets** — `SCL: [SCL-90, HSC/SCL, SCL90R]` — one line per derived value (the many-to-one runs raw→derived; this reads as "my final categories and what composes each"). Free validation: no raw value in two sets (overlap → error); raw values in no set (coverage → error unless an explicit passthrough/other policy is declared).
- **Annotations are always value-keyed attributes** (construct → valence): nothing merges, so the key direction differs by meaning. Two visually distinct shapes for two distinct operations is itself an aid against confusion.
- **Inline by default; promote to a standalone reference table only when earned**: long (country→region), reused by multiple consumers (valence: direction alignment + module-2 groupings), or externally sourced/maintained (World Bank classifications). Both forms feed identical machinery (validation, coverage). **Open question (implementation planning):** representation of shared mappings — named in-spec definitions referenced by name (YAML-native) vs. external files; Liz's skepticism about external files logged.

### 3.7 Findings & error reporting (user-facing quality bar)

- **User vocabulary only** (their column names, their study IDs; roles as glosses).
- **Counts and instances, never first-error-stops**; grouped by severity with the consequence stated ("blocks rev_clean").
- **Routing, not prescription**: every finding says *where to act* (corrections.csv vs dictionary vs assembly spec — mechanically determinable from the check type; the check-type→routing table is part of implementation planning), offering both routes where genuinely ambiguous, and never claims to know the correct value.
- Spec errors get file-and-entry precision with did-you-mean suggestions.
- **Automatic export to Excel** (`output/findings-<runstamp>.xlsx`, one row per finding) — where review teams actually triage; console print + data-frame access remain. (Adds `writexl` — zero-dependency; logged.)
- **Message copy is tested** via testthat snapshot tests: wording regressions fail tests; phrasing is reviewable in PR diffs.

### 3.8 Provenance & auditability

- Corrections log with reasons (the hand-edit audit trail); derivation lineage (spec entry, tier, custom-code flags); per-run log (console events, machine-greppable, written to `output/`); validation reports persisted per run; every output stamped with package version + spec checksums.
- **Intermediate outputs at each stage boundary** (assembled/cleaned/validated/corrected/derived), on by default, off-switchable.
- **Cross-run comparison:** scaffolded projects are **git repositories** (specs, corrections, and outputs committed — study-level data is small and non-sensitive) + a per-run **run summary** (row counts per stage, correction hits, derivation counts, findings counts) so diffs answer "what changed since last run". Stale corrections failing loudly is the third leg: data updates cannot silently invalidate hand-fixes.
- Artefact checksums provide **staleness guards**: `rev_derive()` on an out-of-date cleaned snapshot warns loudly; `rev_process()` makes staleness impossible by construction.

---

## 4. User workflow

- **Step 0 — Install & scaffold (once):** `remotes::install_github(...)`; `revpiper::rev_project("my-review/")` creates `data/raw/`, `specs/` (dictionary, assembly, derivations, reference tables — as complete working examples wired to the bundled synthetic dataset), `derivations.R` (Tier-3 template), `corrections.csv` (headers + example), `run.R`, `output/`, renv initialisation, git init with `.gitignore`. **The example project runs successfully the moment it is created**; users swap in their reality piece by piece.
- **Step 1 — Describe (iterative):** drop extraction sheet(s) into `data/raw/`; edit dictionary + assembly declarations. Tight loop: `rev_check()` → read findings → fix spec or data → repeat.
- **Step 2 — Clean, correct, derive (iterative, phased):** findings needing judgment become `corrections.csv` entries; `rev_check()` again until clean; then `rev_clean()` certifies and writes the clean dataset — the artefact eyeballed as a natural sign-off point. Then declare derivations; `rev_derive()` (stages 5–6) consumes the clean artefact. `rev_process()` composes all six stages — primarily for update/rerun consistency.
- **How findings flow through check/clean:** automated cleaning (stage 2) runs *before* validation on every run — deterministic, in-memory, re-derived from the untouched raw file each time — so machine-fixable issues never appear as findings, only as log counts. Findings are always the post-cleaning, post-corrections residual: what still needs either a spec fix or a new corrections entry. **`rev_check()` = full dry-run diagnosis (stages 1–4: assemble, clean, apply corrections, validate), writing nothing** — so it always reflects the user's corrections to date rather than re-reporting resolved findings. **`rev_clean()` = the same + certification + written artefacts/reports.**
- **Step 3 — Present (module 2, previewed):** a declarative output spec + `rev_render()`, consuming only `output/`'s data contract; processing and presentation rerun independently.
- **Step 4 — Update (the payoff):** new search results → update raw file → `rev_process()`. Corrections re-apply (stale ones fail loudly by name); derivations re-run identically; run summary + git diff show exactly what changed; outputs regenerate.

**Ergonomic commitments:** every user-facing function takes the project path (no working-directory magic); failures name file/column/row and route to the fix location in the user's vocabulary; `rev_check()` is always safe; `data/raw/` is never modified.

**Capability calibration (accepted):** floor is baseline R (install, vignette, three-liner, edit templates), not zero-R. YAML risk mitigated by modify-don't-write templates, complete findings, AI-assist-friendly plain text; **codebook(Excel)→YAML generation is a v1.x roadmap item** (a natural AI-assistant task) if piloting demands it. Declaring keys/granularities is review methodology, not programming — the vignette's worked example carries it. **Usability pilot** (one basic-R colleague, observe where they stall) is an early roadmap item.

---

## 5. Package internals

- **File layout** (mirror-ruled): stages — `assemble.R`, `clean.R`, `validate.R`, `correct.R`, `derive.R`, `certify.R`; verbs — `project.R`, `check.R`, `process.R`; spec machinery — `spec-dictionary.R`, `spec-derivations.R`, `spec-corrections.R`; tiers — `derive-primitives.R`, `derive-effects.R`, `derive-custom.R`; internals — `utils-checks.R`, `utils-messages.R`, `utils-io.R`; vendored `import-standalone-*.R`.
- **S3 classes** (few, purposeful, friendly `print()`): `rev_dictionary`, `rev_derivation_spec`, `rev_corrections` (parsed-and-validated specs; parse errors caught at load in spec-file vocabulary); `rev_findings` (printable summary, `as.data.frame()`, xlsx export); `rev_dataset` (tibble subclass carrying dictionary/lineage/checksums as attributes — behaves as a plain data frame if the extras are ignored; the data contract in object form).
- **Error doctrine — three vocabularies for three audiences:** spec errors (point at spec file + entry); data errors (accumulate into `rev_findings`, user terms); internal errors (ours; the only tracebacks). All messages via **cli** (first logged aggregate-use dependency); entry-point validation via vendored standalone checkers.
- **No config file, no global options, no environment magic** — a run's inputs are the project directory (specs) + the function call (paths, verbosity). The original `config.yaml`'s role is absorbed by specs + scaffold conventions.
- **Logging:** cli console messages (suppressible) + plain-text per-run log in `output/`.

---

## 6. Visualisation module — boundary commitments only

- **Input boundary:** the data contract only; never raw files or upstream specs. Anything module 2 needs must arrive via the contract (the forcing function keeping the contract complete).
- **Content preparation vs rendering split:** prepared, renderer-agnostic objects (select/group/order/format/compose) handed to dumb renderers — flextable→Word and Quarto-compatible emitters in v1, interactive widgets later. One prepared object, N renderers: the structural anti-duplication guarantee.
- **Declarative output spec** (same grammar philosophy as derivations): which standard outputs (study-characteristics table, results/evidence table, forest-style display, RoB summary), columns, grouping, ordering, formatting, target formats. `rev_render()` executes; outputs regenerate independently.
- **Citations:** study-level tables carry per-row citation *keys* resolved at document render time against the user's `.bib`. **Named investigation item (module-2 design):** current flextable/officer citation-field capabilities in Word vs Quarto-mediated rendering — the tool-power vs user-learning trade-off decided there; the content/rendering split keeps both routes open.
- **Figures:** ggplot2, returned as modifiable objects with save helpers.
- **Reserved now:** `prepare-*.R` / `render-*.R` namespace; output-spec slot in the scaffold; contract completeness discipline. Everything else stays open for module 2's own brainstorm.

---

## 7. Testing strategy

1. **Unit tests** (bulk; mirror rule): tiny inline tibbles; normal, edge (all-NA, single study, zero rows), and expected-failure paths asserting the *right finding* — snapshot tests on rendered messages (message copy is interface).
2. **Integration tests on the bundled synthetic review**: `rev_project()` → specs → all six stages → expected shape/values/provenance. The synthetic dataset is a designed artefact deliberately containing the awkward realities (transposed RoB sheet, multi-sample studies, multiple estimates per study, every cleaning class, ≥1 correction, every Tier-1 primitive, every Tier-2 derivation, a Tier-3 function). Triple duty: test fixture, scaffold example, vignette narrative — so it cannot rot.
3. **Original-review validation fixture**: real study-level data with specs *we* author — the design's first dress rehearsal (expressiveness gaps surface before any outside user). Asserts agreement with reference outputs from the original Python pipeline (numeric tolerance for effect sizes; exact for counts/categories). Divergences individually adjudicated — where the old pipeline was wrong, the reference is corrected and documented. Lives in its own directory with a skip-if-absent guard (external contributors get a green suite without the data).
4. **metafor agreement tests**: Tier-2 wrappers vs direct `escalc()` calls on identical inputs — enforcing zero-reimplemented-statistics.

Infrastructure: testthat 3e, parallel, TDD, covr+Codecov measured-not-gated, full-matrix CI (Areas 3/5).

---

## 8. Risks, open questions, roadmap

### 8.1 Risks & mitigations

1. **Spec language can't express real reviews** (existential): early dress rehearsal (test layer 3) + Tier-3 pressure valve; every gap found becomes a design fix pre-users.
2. **YAML defeats the target user**: templates, findings quality, AI-assist; usability pilot; codebook→YAML as the v1.x response.
3. **data-dict immaturity** (2026-young; Rust CLI): lean = adopt the format, R-native validation, CLI optional dev-side; worst case, own a fork of a sensible schema.
4. **Derivation-catalogue creep**: admission criterion + promote-on-evidence.
5. **Maintainer bandwidth (R-beginner maintainer)**: small exported API; CI vigilance; conventions doc making every future session consistent.

### 8.2 Open questions (with owners)

| Question | Owner |
|---|---|
| data-dict: format-only vs CLI dependency | Module-1 implementation planning |
| Shared-mapping representation (named in-spec vs external files) | Module-1 implementation planning |
| Extraction-tool export formats (Covidence, DistillerSR) | Module-1 implementation planning |
| `escalc()` coverage vs original pipeline's derivations | Module-1 implementation planning |
| Check-type→routing table for findings | Module-1 implementation planning |
| Citation rendering (flextable/officer vs Quarto-mediated) | Module-2 design |
| `revpiper` availability check; repo rename | First implementation step |
| Documentation templates per function type | Phase 1, with real functions |

**Resolution mechanism:** when a phase begins, its owned questions become the first tasks of that phase's planning step (typically short investigations). Each resolution is committed back into this spec as an amendment via PR, so the spec remains the living, dated record of decisions.

### 8.3 Explicitly out of scope for v1

Interactive layer & dashboards; umbrella/scoping reviews; codebook→YAML generator; CRAN submission; pre-commit hooks; fledge.

### 8.4 Roadmap (each phase: spec → plan → TDD → review)

- **Phase 0 — Bootstrap:** package skeleton via the usethis sequence; conventions doc (drafted from §2, doubling as repo CLAUDE.md source and Liz's standing template); CI green on a hello-world package. *Implementation prerequisites:* name availability check; sandbox network allowlisting for CRAN/Posit package mirrors (GitHub already allowed). *(Amended 2026-07-07: the original third prerequisite — "switch `origin` to HTTPS and verify an end-to-end `git push`" — predated the adopted option-a workflow and contradicted it: the sandbox never pushes; Liz fetches from the sandbox remote and pushes from the host.)*
- **Phase 1 — Spec machinery + stages 1–3** (dictionary parsing/validation, assemble, clean, validate, findings). The expressiveness risk burns down here. *Phase 1 planning opens with its owned investigations — extraction-tool export formats (Covidence, DistillerSR; does reality export per-estimate rows or wide per-study sheets?) and the data-dict format-vs-CLI decision — before the stage-1 canonical-shape assumptions are finalised.*
- **Phase 2 — Stages 4–6** (corrections, three-tier derive, metafor wrappers, certify, provenance).
- **Phase 3 — Scaffold + synthetic review + vignettes** (`rev_project()`, designed synthetic dataset, getting-started + prepare-your-data vignettes, pkgdown live).
- **Phase 4 — Dress rehearsal** (original-review specs + validation fixture; adjudicate divergences; fix gaps).
- **Phase 5 — Usability pilot; then the module-2 (visualisation) brainstorm.**

---

## Appendix: externally verified references consulted during design

- Air formatter: posit-dev/air; tidyverse blog (Feb 2025, Jun 2025); usethis `use_air()`. Distribution: Positron-bundled, installer script, Homebrew, pixi/mise; not on CRAN (Rust binary).
- Tidyverse practice: tidy tools manifesto; design.tidyverse.org; tidyverse CONTRIBUTING (per-PR NEWS bullets); tidyups 004 governance (squash-merge); `use_tidy_github_actions()`; style.tidyverse.org/news.html.
- Repo inspections (July 2026 clones): tidyverse/ellmer, tidyverse/duckplyr, r-lib/usethis — air.toml universal; no `.lintr`; format-suggest workflows; `Config/testthat/parallel`; `utils-<domain>.R`; `import-standalone-*.R`; usethis AGENTS.md.
- data-dict: github.com/tidyverse/data-dict (YAML spec + Rust CLI; validate-spec/meta/data ladder; agent skills).
- Ecosystem: metafor/escalc; synthesisr, revtools, metagear (Lajeunesse 2016, Methods Ecol Evol), PRISMA2020, appraise; pharmaverse (metacore/metatools/admiral pattern — pattern adopted, packages not).
- R versions: R 4.6.1 current (June 2026); native pipe/lambda R 4.1; `_` placeholder 4.2; extended placeholder 4.3; base `%||%` 4.4.
