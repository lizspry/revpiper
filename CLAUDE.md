# revpiper — instructions for AI sessions

Read first: dev/conventions.md (rules) and
dev/superpowers/specs/2026-07-07-revpiper-design.md (design + rationale).

## Hard rules
- **Network policy:** whenever anything is blocked by network policy (HTTP
  403 "Blocked by network policy"), STOP that line of work immediately,
  tell Liz the exact domain(s), and wait for her to allowlist them. Never
  substitute source compilation, manual vendoring of libraries, or
  alternative download channels without asking first. This applies even
  where a plan documents a fallback.
- **Installed software and versions:** before installing any software or
  package, check whether it (or another version of it) is already
  present. If what is present, or what would be installed, differs from
  what was recommended or agreed with Liz, STOP and ask which version to
  use. Never install a second/parallel version of a provisioned runtime
  without her explicit approval. (Recorded decision for this project,
  Liz 2026-07-07, per plan v2: the sandbox image ships no R; the dev R
  is the current CRAN release (4.6.1), installed from CRAN's official
  Ubuntu apt repository as the sole R.)
- This sandbox NEVER pushes to GitHub. Commit locally on a feature
  branch; Liz fetches via the sandbox remote, pushes, and opens the PR.
- Git author and committer must be "claude" <liz.spry+claude@gmail.com>
  (set by claude-config settings; verify with `git var GIT_AUTHOR_IDENT`
  at session start and before each commit).
- main is protected; never commit to it. One branch per task.
- TDD for all feature code. Run the pre-push suite (dev/conventions.md)
  before declaring any branch ready.
- Raw data under any project's data/raw/ is read-only, always.
- Every user-facing change adds a NEWS.md bullet in the same PR.

## Rhythm
- Plan → get Liz's sign-off → pre-flight → implement in small reviewed steps.
  A signed-off plan is itself the trigger for the pre-flight check
  (~/.claude/rules/preflight.md): run it in the executing sandbox before the
  first task; findings are fixed by plan amendment before execution.
- Open questions resolve at their owning phase's planning step and are
  committed back into the spec via PR (spec §8.2).

## Project status pointers
- Superpowers specs/plans live in dev/superpowers/{specs,plans}/ —
  never write into docs/ (gitignored pkgdown output). This overrides
  the superpowers skills' default docs/superpowers/ location.
- Design spec: dev/superpowers/specs/2026-07-07-revpiper-design.md
  (amended through 2026-07-10 by Phase 1 planning).
- Active plan: dev/superpowers/plans/2026-07-09-phase-1-implementation.md —
  SIGNED OFF, pre-flight complete, execution NOT yet begun. Binding protocol
  in its Status block: walkthrough-gated per task (explain → Liz reads plan
  step + code → she confirms → execute), via superpowers:executing-plans.
  Work on branch phase-1-planning until execution starts its own
  phase-1-core branch (Task 1 Step 1). Planning rationale:
  dev/superpowers/plans/2026-07-08-phase-1-planning-notes.md.
- Completed: Phase 0 (merged to main 2026-07-08; its plan's Status section
  is the record; do not resume phase-0 branches).
