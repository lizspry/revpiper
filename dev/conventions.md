# Coding conventions (standing template)

Origin: the revpiper design spec
(dev/superpowers/specs/2026-07-07-revpiper-design.md), whose decisions log
(§9) dates each rule with a one-line rationale; fuller rationale lives in
git history. This file is the single home for the rules themselves,
reusable across projects.

Environment and sandbox operating rules live in CLAUDE.md (single
source), not here — this document covers code conventions only.

## Terminology (recorded 2026-07-11, Phase 1 amendment 4; vocabulary
## settled with Liz at the Task 4 review — five words, researcher-first)
- Data tables have **columns** (synonym in prose: variables), which hold values.
- A spec **file** (dictionary) has **sections** — its named top-level parts:
  `source:`, `levels:`, `columns:`. Sections hold entries.
- An **entry** is one item described by its **fields** (`key: value`
  pairs): a column with its fields, the source with its fields, a
  combination of columns with its fields — and the file itself, whose
  top-level fields form the file entry.
- Entries come in **kinds** — file, source, column, level, and (from the
  joins spec) join and join_file. The schema groups fields under their kind
  (`kinds:` list; there is no appears_in property), so which fields are
  legal follows from the grouping and the same field name may carry
  kind-specific properties; container fields declare the kind of entry
  inside them (`contains`). "kind" is provisional wording — internal-only,
  cheap to rename, under later review (Liz 2026-07-12).
- An entry's **name** is the value of the one field that identifies it
  (`name:` for a column, `table:` for the file; the schema marks that
  field `identity: true`). Messages point at entries by name; duplicate
  names among sibling entries are always policed.
- A field the schema marks `refers_to` a section must have values naming
  something that section declares (a declared column, a declared level);
  unresolved references get did-you-mean suggestions.
- A **level** (section `levels:`, which absorbed `identifiers:` —
  execution amendment 7) maps a user-named grouping of the data to what
  identifies it: a column name, `keys:` naming column(s), or `combine:`
  building a **virtual column** named by the level (optional `separator`,
  default `""`); optional `within:` names the parent level (explicit
  nesting; cycles are spec errors). Level names are always the user's
  words — nothing is pipeline-reserved.
- The package schema (`inst/schema/fields.yaml`) defines each field's
  **properties** (shape, cardinality, domain, ...). Properties generate
  **checks**; check failures are **problems** (spec side, abort) or
  **findings** (data side, routed). Never say "attributes" (R-reserved).
- A **mapping** is a named group of `key: value` pairs (YAML mapping, R
  named list); a mapping with no `contains` kind has user-chosen keys —
  data, not vocabulary (levels).
- Retired words — never reintroduce: "context" for entry kinds (and "top"
  for the file kind), "block" (say section), "collection" (say what a
  section declares), "role" and "identifier" (say level — the sections
  merged, amendment 7), "appears_in" (kind grouping replaced it), "walker"
  (describe the job).
- Spec-check codes carry a scope prefix, with one term per scope used
  everywhere: **YF** form (within one field), **YE** entry (across fields
  within one entry), **YS** source (across entries within one file),
  **YX** cross-source (across files). Within-source validation is
  standalone; across-source is a separate, composable, data-free step.
- Workflow **steps** — spec, load, process, transform (then present,
  module 2) — are the user-facing stage words (2026-07-12, plan amendment
  8): reports, certificates, and R-file prefixes carry
  them. "derive" is retired as the user-facing stage word (say transform;
  internal helper names may keep it where clearer).
- User-facing workflow functions read `rev_<step>_<action>` (2026-07-12,
  plan amendment 9). Two **action** words, the same pair at every step:
  **audit** — check and report (writes the step's report + certificate,
  never aborts); **run** — execute the step and produce its output
  (aborts on problems, pointing at the audit). "check" stays internal
  (`check_*` functions); never name a user-facing function with it.

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
- Close-out adversarial battery (standing practice, Liz 2026-07-13):
  at each phase close-out, spec-only black-box test design by
  fresh-context agents. The brief is the design spec's user-facing
  sections plus exported docs ONLY — never implementation or existing
  tests, because errors correlate: the author's code, tests, and even
  generated matrices share one mind's blind spots, so the entire
  artifact set gets independent review. Protocol: oracle-first
  (expected outcome + clause citation committed before execution);
  UNDETERMINED is a first-class verdict routing to spec amendment;
  minimal pairs preferred; rotating lenses — naive user, language
  lawyer, hostile input, QA professional, security (grow the roster) —
  plus a completeness-critic pass mapping cases to spec clauses and
  naming the untested; rounds repeat until one finds nothing new.
  Execution is blind and mechanical; findings triage to bug / test gap
  / spec ambiguity; no fixes during the run; adopted divergences
  become regression tests. First run: 2026-07-13, spec step (54 cases;
  YS05, YS06, canonical examples, six determinations).

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
  extract, or leave a one-line written justification. It is a floor,
  not a barrier (Liz, 2026-07-12): duplication flagged at two
  occurrences (review, /simplify) may be extracted whenever the
  extraction is judged an improvement.
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
- A registry must guard the uniqueness of its own keys, preferably by
  construction (entries keyed in a YAML mapping fail at parse when
  duplicated); any uniqueness invariant a format cannot hold needs a
  stated conformance test (lesson recorded 2026-07-11: field-name
  uniqueness went unguarded in the list-form schema).

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
