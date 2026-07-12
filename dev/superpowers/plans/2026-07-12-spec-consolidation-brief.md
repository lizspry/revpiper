# Spec consolidation brief (2026-07-12)

Agreed with Liz 2026-07-12 (end of the Task 5 session). Task: rewrite
dev/superpowers/specs/2026-07-07-revpiper-design.md as a consolidated
design spec that states the current design once, cleanly. Git holds the
history; the document holds the present. Rationale is design content and
stays; amendment archaeology (stacked "*(Amended ...)*" notes) goes.

Sequence decided: (1) this consolidation; (2) THEN the architecture
discussion — what, if anything, to change (agenda held in the plan's
Task 5-close checkpoint blockquote: schema vocabulary gaps, permitted_when,
"kind" wording, divergence list); (3) then the collaborator deliverable
(framing in the same blockquote). No architecture-review skill is being
built (considered and dropped as overengineering, Liz 2026-07-12); no
refactor is decided by this rewrite.

## Skeleton (proposed 2026-07-12; Liz adjusts at draft review)

1. Purpose & goals
2. Users & ways of working (incl. the three collaborator situations)
3. Scope & non-goals
4. Concepts & vocabulary (settled terms; points to conventions)
5. The spec stage — dictionaries, levels, joins (user-facing formats)
6. The pipeline stages — read, standardise, validate, join, report,
   certify
7. Architecture — invariants and the schema grammar ONLY (tiers 1-2:
   doctrines with rationale + the kinds/properties model; registries hold
   the instances; file layout stays minimal and provisional)
8. Quality & testing strategy
9. Decisions log (decision, date, one-line rationale)
10. Open questions (current §8.2, surviving with all rows)

## Process

1. Extraction table FIRST: every decision and rationale in the current
   spec AND the amendment trail (plan Status block amendments 1-7, Task
   follow-up blockquotes) — each row resolved to kept (where in the new
   doc) / superseded (by what) / retired (why). No silent drops. A
   rationale recorded nowhere is marked UNRECORDED and becomes a question
   for Liz — never reconstructed from plausibility.
2. Draft per skeleton.
3. Internal review passes before returning to Liz, each against a written
   referent:
   - extraction table: no dropped decisions, no unsourced statements;
   - code + registries (inst/schema/fields.yaml, checks.yaml, R/ exports):
     no claim the implementation contradicts;
   - cross-document: no fact duplicated with conventions or registries —
     the spec points, never mirrors;
   - skeleton + style: hard-wrapped git-native prose at the file's
     prevailing width; §8.2 intact.
4. Deliverable to Liz: the extraction table + the rewritten spec,
   reviewed as a diff; commit via the usual PR route. Liz is the final
   verifier.

## Constraints

- No new design decisions inside the rewrite: anything ambiguous or
  unrecorded becomes a listed question, not a choice.
- The deferred schema refactor is recorded as direction with its two
  triggers (Phase 2 planning; Task 14 review) — a decisions-log entry,
  not a plan.
- Sources: the current design spec; the phase-1 plan (Status block,
  Task 4/5 blockquotes); dev/conventions.md; the planning notes
  (2026-07-08); inst/schema/*.yaml; R/.
