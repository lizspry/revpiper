# Coding conventions (standing template)

Origin: revpiper design spec §2 (docs/superpowers/specs/2026-07-07-revpiper-design.md),
which holds the full rationale for every rule here. This file is the
operational digest, reusable across projects.

## Environment
- On any network-policy block (HTTP 403): stop, report the exact
  domain(s), wait for allowlisting. No substitute channels, source
  compilation, or manual vendoring without explicit approval.
- Inventory provisioned tooling before installing; use the provisioned
  R as the dev R; never install parallel runtime versions unasked.

## Style & formatting
- Tidyverse style guide, uncustomised. Air formats everything (air.toml
  committed, defaults only). Never hand-format; never argue with Air.
- snake_case; `<-` for assignment; native pipe `|>` in new code.

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
- renv pins the dev environment only (Rbuildignored); CI unpinned.

## Design
- Functional core + light S3. No R6/S4 without an argued need.
- Pure functions: data + explicit args in, value out; side effects only
  at orchestration edges. Fail fast with cli_abort at entry points.
- Rule of three, qualified: third occurrence forces a decision —
  extract, or leave a one-line written justification.
- usethis-first for all scaffolding/config.

## Git
- PR-only main (protected). Short-lived branches, one per task, deleted
  on merge. Squash-merge. Plain imperative commit messages.
- Version: MAJOR.MINOR.PATCH(.9000 dev). NEWS heading per release.

## Pre-push suite (run locally before every push; CI is the backstop)
    air format .
    Rscript -e 'lintr::lint_package()'
    Rscript -e 'devtools::test()'
    Rscript -e 'devtools::check()'   # before PRs; test() suffices mid-branch
