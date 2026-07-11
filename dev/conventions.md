# Coding conventions (standing template)

Origin: revpiper design spec §2 (dev/superpowers/specs/2026-07-07-revpiper-design.md),
which holds the full rationale for every rule here. This file is the
operational digest, reusable across projects.

Environment and sandbox operating rules live in CLAUDE.md (single
source), not here — this document covers code conventions only.

## Terminology (recorded 2026-07-11, Phase 1 amendment 4)
- Data tables have **columns** (synonym in prose: variables), which hold values.
- A dictionary describes each column via **fields** (`type:`, `values:`, ...).
- The package schema (`inst/schema/fields.yaml`) defines each field's
  **properties** (shape, cardinality, domain, ...). Properties generate
  **checks**; check failures are **problems** (spec side, abort) or
  **findings** (data side, routed). Never say "attributes" (R-reserved).
- A **mapping** is a named group of `key: value` pairs (YAML mapping, R
  named list). A mapping either has schema-vocabulary keys and a `context`
  to validate its contents as (source block, column entries), or
  user-chosen keys that are data, not vocabulary (identifiers, levels).

Plain-language terms (recorded 2026-07-11, Liz's Task 4 review):
- An **entry** is one described thing in a spec file — one column, one
  identifier, one source — written as a group of `key: value` fields.
- An entry's **name** is the value of the one field that identifies it
  (`name:` for a column, `table:` for a dictionary file; the schema marks
  that field `identity: true`). Messages refer to entries by name, and
  duplicate names among sibling entries are always policed.
- A **collection** is the set of names declared by one block of a spec
  file (currently: the declared columns, the declared levels). A field the
  schema marks `refers_to` a collection is valid only if every one of its
  values is a member of that collection.
- An **identifier** (block `identifiers:`, formerly `roles:`) maps a
  pipeline handle such as `study_id` to one of the user's own columns, or
  to a `combine` block that builds one — the built column is a **virtual
  column** named by the identifier. Identifier keys are pipeline
  vocabulary; identifier values are always the user's words.
- Spec-check codes carry a scope prefix, with one term per scope used
  everywhere: **YF** form (within one field), **YE** entry (across fields
  within one entry), **YS** source (across entries within one file),
  **YX** cross-source (across files). Within-source validation is
  standalone; across-source is a separate, composable, data-free step.

## Style & formatting
- Tidyverse style guide, uncustomised. Air formats everything (air.toml
  committed, defaults only). Never hand-format; never argue with Air.
- snake_case; `<-` for assignment; native pipe `|>` in new code.
- Comment section headers are single `# Text` lines with a blank line
  above; subheaders name the check code they implement. No decorative
  `---`/`===` rules in comments or text.
- `paste0()`/`sprintf()` assemble tokens only (patterns, keys, paths).
  User-facing prose is never composed from fragments: every full phrase
  lives whole in data (message_template, shape_phrases) or a single cli
  call. No testing exception — snapshots pin phrases; they do not
  license composing them.

## Naming

Principles:
- Functions are verbs; objects and arguments are nouns. snake_case; no
  dots in function names (S3 ambiguity).
- Exported functions share the `rev_` prefix (family autocomplete).
- Name length proportional to scope; no abbreviations (`context`, never
  `ctx`); one word per concept, everywhere (see Terminology).

Closed decisions (this project):
- Predicates: `is_*` / `has_*`, or `matches_*` for comparisons.
- Constructors: `new_<class>()`.
- `check_<x>` implements exactly one coded check (defined under that
  code's subheader; returns problem rows, never throws); `run_*_checks`
  compose them - drivers with no code of their own, in the Orchestration
  section, ordered narrow to broad (field, entry, context, list).
  rlang's throwing `check_*` are always namespace-qualified.
- Problem workflow verbs: `new_problem()` constructs the row,
  `flag_problem()` is how a check reports one (registry-rendered),
  `stop_spec()` throws the collected set.
- Cached data getters are plain nouns naming what they return
  (`schema_fields`, `schema_properties`, `check_registry`).

## Linting
- lintr with defaults + library_call_linter, namespace_linter,
  backport_linter pinned to the declared R floor. Zero lints at all times.

## Testing
- testthat 3e, parallel. TDD: test first, watch it fail, minimal code,
  watch it pass, commit. Snapshot-test user-facing message wording.
- Coverage measured (covr/Codecov), never gated. ~90% informal on core logic.

## Documentation
- roxygen2 for every export; comments say why, not what; internal helpers
  get at most one line. NEWS.md bullet in every user-facing PR.
- Vignettes are the primary user docs; heavy content goes to
  vignettes/articles/ (website-only).

## Dependencies
- Justify each package-wide (aggregate use, maintainer quality, API
  surface); log the justification in the PR that adds it.
- Options in order: depend / vendor r-lib standalone / write it.
- No library() in R/. Depends: holds only the R floor.
- External calls are namespace-qualified (`pkg::fun()`). Infix operators,
  which cannot be qualified, are imported via `@importFrom` — a closed
  list, kept to the minimum (currently rlang's `%||%` only; additions
  need a recorded decision).
- renv pins the dev environment only (Rbuildignored); CI unpinned.

## Design
- Functional core + light S3. No R6/S4 without an argued need.
- Pure functions: data + explicit args in, value out; side effects only
  at orchestration edges. Fail fast with cli_abort at entry points.
- Rule of three, qualified: third occurrence forces a decision —
  extract, or leave a one-line written justification.
- usethis-first for all scaffolding/config.

## Single source of truth (recorded 2026-07-11, Phase 1 amendment 6)

Principles (invariants, project-independent):
- Every fact — a vocabulary, a rule, a mapping, a message, a default —
  has exactly one authoritative home. A literal appearing in two places
  is a defect, not a style choice.
- Prefer data over code as the home: facts declared in data files, with
  generic code over them. Code holds logic; data holds knowledge.
- Registry-first (the data analogue of test-first): a new fact-family
  gets its registry, loader, and closure test BEFORE the code that
  consumes it.
- Checks by construction beat checks by review: where an invariant can
  be enforced by a conformance or closure test, add the test; never rely
  on discipline for what a test can hold.

Processes (habits that apply the principles):
- Walkthroughs include a facts-and-sources section: every fact the new
  code needs, each with its single authoritative home named. A fact with
  two homes, or a literal home in code, is flagged before implementation
  begins.
- Pre-commit duplication pass (alongside reading new snapshots): what
  did I hard-code, what now exists twice, what failed to generalise?
  Findings are reported at the check-in, never silently absorbed.
- Plan self-review includes a single-source scan beside the placeholder
  scan: which facts does in-plan code hard-code that belong in a
  registry?

(Specific homes — which registries exist and what lives in each — are
project decisions and live in the project's plan/spec, not here. In
revpiper: inst/schema/fields.yaml and checks.yaml.)

## Git
- PR-only main (protected). Short-lived branches, one per task, deleted
  on merge. Squash-merge. Plain imperative commit messages.
- Version: MAJOR.MINOR.PATCH(.9000 dev). NEWS heading per release.

## Pre-push suite (run locally before every push; CI is the backstop)
    air format .
    Rscript -e 'pkgload::load_all(quiet = TRUE); lintr::lint_package()'
    # (load_all first: object_usage_linter needs the package namespace
    #  loadable to resolve cross-file calls; CI installs local::. for
    #  the same reason)
    Rscript -e 'devtools::test()'
    Rscript -e 'devtools::check()'   # before PRs; test() suffices mid-branch
