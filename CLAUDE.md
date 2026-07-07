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
- **Installed software and versions:** before installing any software or
  package, check whether it (or another version of it) is already
  present. If what is present, or what would be installed, differs from
  what was recommended or agreed with Liz, STOP and ask which version to
  use. Never install a second/parallel version of a provisioned runtime
  without her explicit approval. (Recorded decision for this project:
  the dev R is the sandbox-provisioned R.)
- This sandbox NEVER pushes to GitHub. Commit locally on a feature
  branch; Liz fetches via the sandbox remote, pushes, and opens the PR.
- Git author and committer must be "claude" <liz.spry+claude@gmail.com>
  (set by claude-config settings; verify with `git var GIT_AUTHOR_IDENT`
  at session start and before each commit).
- main is protected; never commit to it. One branch per task.
- TDD for all feature code. Run the pre-push suite (docs/conventions.md)
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
- Design spec: docs/superpowers/specs/2026-07-07-revpiper-design.md
- Active plan: docs/superpowers/plans/2026-07-07-phase-0-bootstrap.md (v2;
  v1 was executed and discarded — see its Status section; do not resume
  the archived phase-0-attempt1 branch).
