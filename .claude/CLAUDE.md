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
  Host-side commands: `git fetch sandbox-<name>` (note the `sandbox-`
  prefix; `<name>` = this sandbox's $SANDBOX_VM_ID), then
  `git checkout <branch>`.
- Outward-facing documents never fork the design: a deliverable that
  changes scope or design carries a spec-amendment commit in the same
  branch, so the PR review signs off both together. (Adopted 2026-07-15,
  one-pagers session — dashboards/umbrella scope changes briefly lived
  only in deliverables.)
- Git author and committer must be "claude" <liz.spry+claude@gmail.com>
  (set by claude-config settings; verify with `git var GIT_AUTHOR_IDENT`
  at session start and before each commit).
- main is protected; never commit to it. One branch per task.
- TDD for all feature code. Run the pre-push suite (dev/conventions.md)
  before declaring any branch ready.
- Raw data under any project's data/raw/ is read-only, always.
- Every user-facing change adds a NEWS.md bullet in the same PR.

## Explaining things to Liz
- Short and plain (Liz, 2026-07-13). Lead with the one-sentence answer
  in everyday words; skip jargon she hasn't used; a couple of sentences
  beats paragraphs. She asks ("expand") when she wants the long version.
- Outward-facing documents: avoid absolutes; Liz consistently softens
  claims to defensible phrasing (her 2026-07-15 edits: "frequently",
  "primarily", "free, open-source"). Don't deploy an explanation before
  its referents are introduced; make divisions of labour explicit.

## Rhythm
- Plan → get Liz's sign-off → pre-flight → implement in small reviewed steps.
  A signed-off plan is itself the trigger for the pre-flight check
  (~/.claude/rules/preflight.md): run it in the executing sandbox before the
  first task; findings are fixed by plan amendment before execution.
- Open questions resolve at their owning phase's planning step and are
  committed back into the spec via PR (spec §10, Open questions).

## Project status pointers
- Superpowers specs/plans live in dev/superpowers/{specs,plans}/ —
  never write into docs/ (gitignored pkgdown output). This overrides
  the superpowers skills' default docs/superpowers/ location.
- Design spec: dev/superpowers/specs/2026-07-07-revpiper-design.md
  (consolidated 2026-07-12 per the spec-consolidation brief; diff
  SIGNED OFF, Liz 2026-07-12; git history holds the amendment trail,
  audited in
  dev/superpowers/plans/2026-07-12-spec-consolidation-extraction.md).
- Active plan: dev/superpowers/plans/2026-07-09-phase-1-implementation.md —
  SIGNED OFF with execution amendments 1-9 (amendment 9, 2026-07-12:
  `rev_<step>_<action>` grammar, audit/run action pair per step,
  rev_spec_audit + rev_spec_run(dir, file, joins = TRUE) replacing the
  three exported readers; amendment 8 signed off
  2026-07-12 after one review amendment, the front matter rewritten in
  place: workflow step model spec → load → process → transform;
  rev_run(); Phase 1 re-cut to SPEC ONLY, phases re-numbered 1-7 with
  releases v1 = spec+load+process, v2 = transform, v3 = vis; two-axis
  file scheme; old Tasks 6-13 frozen and moved to Phases 2-3).
  Executing on branch phase-1-core. DONE:
  Tasks 1, 2, 3, 3b, 4, 5 (amendment 7: levels merge, joins spec,
  schema restructure) + spec consolidation per the 2026-07-12 brief
  (diff signed off, Liz 2026-07-12) + amendment 9 implementation
  (rev_spec_run, commits 03d8d22/59aaa1d) + Task 15 (two-axis file
  split, 1a0f5d2) + Task 16 (report machinery, 87be99a/3d2dfbb;
  spec-check.R renamed spec-generic.R 1aac084) + Task 17
  (rev_spec_audit, 19b6025/91f0326) + Task 18 (close-out: CLAUDE.md
  relocated to .claude/, examples, audits, gates all clean — 381 tests,
  0 lints, check 0/0/0; Imports re-cut and lint gate settled by Liz
  2026-07-13). PHASE 1 COMPLETE sandbox-side. The collaborator
  deliverable (Task 5-close item 2) is DELIVERED on branch
  collab-onepagers (2026-07-15/16, ~13 commits, planned via
  academic-planning): three docs in dev/deliverables/ — shared project
  one-pager, review-team one-pager (substantially the Task 5-close
  deliverable, Markdown per Liz), engineer brief — plus the RAISE 2026
  PDFs, cited/cited.bib (citation-tracking rule; all claims verified via
  paperclip), and a spec amendment (dashboards in scope for v3, umbrella
  reviews in scope from v1, §10 corrections-container-format question
  for Phase 3). NEXT, in order: (1) Liz pulls spec-step-ux, pushes, opens the PR
  (squash-merge, CI green gate) — the PR reviews the implementation,
  the design doc, the spec amendments, and the conventions changes
  together; (2) Phase 2 (load) planning.
  DONE since the one-pagers session: phase-1-core MERGED to main
  (PR #7); collab-onepagers MERGED. The spec-step UX redesign is
  COMPLETE on branch spec-step-ux (2026-07-19, error-testing session;
  design dev/superpowers/specs/2026-07-19-spec-step-ux-design.md and
  plan dev/superpowers/plans/2026-07-19-spec-step-ux.md, all tasks +
  9b/9c executed): readers return value+problems (nothing throws spec
  problems), collect_spec_step + spec_step spine, per-file plain-text
  reports mirroring the spec tree, related column (deterministic, self-
  contained phrases in related_phrases), YE09 self-join + YX05 zero-
  dictionaries checks, joins-excluded disposition, withr test idiom
  suite-wide, adversarial battery run (4 blind internal lenses + Liz's
  external-model pack, dev/adversarial/) with all decisions applied,
  two-tier review (workflow code-review + conventions audit) and
  /simplify applied. Gates at close: 519 tests, 0 lints, check 0/0/0.
  Parked for later: pruning overlap between
  test-spec-run-public-promises.R and the core suites (Liz's call); a
  notices mechanism if a second disposition ever joins joins_excluded;
  outcome finalization lifecycle note; YS01 twin test (Phase 2 list).
  m:m/append data-check semantics parked to the process phase (old
  Task 11); structural reviews at each phase's close-out (amendment
  7h/8e).
  Binding protocol: walkthrough-gated per task (explain, incl. a
  facts-and-sources section, → Liz reads plan step + code → she confirms →
  execute), pre-commit duplication pass, /simplify on the task diff before
  final commit (edits reviewed jointly), via superpowers:executing-plans.
  READ dev/conventions.md FIRST — Terminology (settled vocabulary +
  retired words), Naming, and Single-source-of-truth sections bind all
  code. Liz edits/commits on the host too: fetch /run/sandbox/source and
  fast-forward before working.
  Planning rationale:
  dev/superpowers/plans/2026-07-08-phase-1-planning-notes.md.
- Completed: Phase 0 (merged to main 2026-07-08; its plan's Status section
  is the record; do not resume phase-0 branches).
