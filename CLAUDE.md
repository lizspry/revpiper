# revpiper — instructions for AI sessions

Read first: docs/conventions.md (rules) and
docs/superpowers/specs/2026-07-07-revpiper-design.md (design + rationale).

## Hard rules
- **Network policy:** whenever anything is blocked by network policy (HTTP
  403 "Blocked by network policy"), STOP that line of work immediately,
  tell Liz the exact domain(s), and wait for her to allowlist them. Never
  substitute source compilation, manual vendoring of libraries, or
  alternative download channels without asking first. This applies even
  where a plan documents a fallback.
- **Provisioned tooling:** inventory the sandbox's provisioned tooling
  before installing anything. Use the provisioned R as the dev R; never
  install a second/parallel R version or replace provisioned runtimes
  without Liz's explicit approval.
- This sandbox NEVER pushes to GitHub. Commit locally on a feature
  branch; Liz fetches via the sandbox remote, pushes, and opens the PR.
- Git author must be "Claude Code (assistant to Liz Spry)"
  <liz.spry+claude@gmail.com> (repo-local git config; set and verify with
  `git config user.name` at session start).
- main is protected; never commit to it. One branch per task.
- TDD for all feature code. Run the pre-push suite (docs/conventions.md)
  before declaring any branch ready.
- Raw data under any project's data/raw/ is read-only, always.
- Every user-facing change adds a NEWS.md bullet in the same PR.

## Rhythm
- Plan → get Liz's sign-off → implement in small reviewed steps.
- Open questions resolve at their owning phase's planning step and are
  committed back into the spec via PR (spec §8.2).

## Project status pointers
- Design spec: docs/superpowers/specs/2026-07-07-revpiper-design.md
- Active plan: docs/superpowers/plans/2026-07-07-phase-0-bootstrap.md (v2;
  v1 was executed and discarded — see its Status section; do not resume
  the archived phase-0-attempt1 branch).
