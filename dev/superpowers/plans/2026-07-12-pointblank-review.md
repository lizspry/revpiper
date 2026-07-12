# pointblank review — how revpiper stacks up

Reviewed 2026-07-12 at Liz's request. Grounded in the package source
(github.com/rstudio/pointblank, cloned at v0.12.3.9000, last commit
2026-01-14, maintainer Rich Iannone / Posit, MIT licensed, repostatus
"active"), read via three source sweeps: validation core, metadata and
reporting, positioning docs. Facts below cite pointblank functions;
revpiper facts cite the design spec.

## What each package is

**pointblank** is a general-purpose data-validation and table-metadata
package for local and remote tables (data frames, DBI databases, Spark;
validation runs in-database for remote backends). Its model: build an
"agent" carrying a validation plan of ~40 step types (`col_vals_*`,
`col_is_*`, `rows_distinct`, `col_schema_match`, ...), then
`interrogate()`; every step counts pass/fail "test units" (usually
rows) and trips warn/stop/notify states against `action_levels()`
thresholds (absolute counts or failure fractions), which can fire
hooks (email via blastula, log4r logging). Reports are gt HTML tables;
plans round-trip through YAML (`yaml_write`/`yaml_read_agent`); a
separate "informant" documents tables as a rendered data dictionary;
`scan_data()` profiles a table (overview, variables, interactions,
correlations, missingness, sample); `draft_validation()` generates a
starter plan from observed data; multiagent reports compare
interrogations over time, steps matched by SHA1 hash. Six advertised
workflows, from pipeline gating to testthat expectations. 21 hard
Imports (gt, blastula, DBI, dbplyr, dplyr, tidyr, testthat, ...).

**revpiper** is a workflow tool for systematic-review/meta-analysis
data: the researcher hand-authors per-table YAML dictionaries and a
joins spec BEFORE data exists; the package validates the specs
themselves (schema-generated checks, all problems at once), then
carries data through spec → load → process → transform with a report +
certificate per step; findings carry consequences (never severities);
certification = zero standing findings; fixes route to user-owned
artifacts (the YAML, corrections.csv), never in-place edits; raw data
is read-only and everything is re-runnable from it.

## Overlap map

| revpiper | pointblank counterpart | how close |
|---|---|---|
| dictionary `type` + declared coercion | `col_is_*()`, `col_schema_match()` | same intent; theirs checks types in place, ours coerces from character by declaration |
| `values:`/`range:`/`units:` checks (V-checks, Phase 3) | `col_vals_in_set()`, `col_vals_between()`, `col_vals_regex()` | heavy overlap on the checks themselves |
| spec report + certificate | agent report (gt table), `all_passed()` | overlap in role; theirs has no certification concept (word absent from their docs) |
| per-table YAML dictionary | YAML agent plan + informant-as-data-dictionary | ours is ONE artifact (spec = dictionary = validation source); theirs splits validation plan and documentation into two objects |
| `rev_draft_dictionary()` (Phase 2) | `draft_validation()` | near-identical idea: generate a starter spec from observed data |
| planned data-overview report (§10, flagged 2026-07-12) | `scan_data()` OVICMS report | theirs exists and is mature |
| planned custom checks (§10) | `specially()` (fn → logical vector or table with last col logical), `conjointly()`, `serially()` | theirs is a proven extension model |
| provenance / living-review diffing (§10) | multiagent Wide report: interrogations over time, steps keyed by SHA1 | theirs solves a neighbouring problem (monitoring drift), not frozen-publication diffing, but the mechanism is instructive |
| joins spec + J-checks | — | no counterpart: pointblank is strictly single-table |
| corrections workflow | — | no counterpart; theirs extracts failing rows (`get_data_extracts`, `get_sundered_data`) but has no fix-routing or audit trail of corrections |
| prespecification before data exists | — | agents are declarative but need a target table (or table-prep formula); no authoring-before-data workflow |
| step model with per-step certification gates | action_levels warn/stop/notify thresholds | philosophically opposed: thresholds tolerate failure fractions; certification is binary |

## The deep differences

1. **Prespecification vs inspection.** pointblank's centre of gravity
   is validating tables that exist (its drafts are generated FROM
   data). revpiper's centre is a registerable prespecification a team
   commits to before data collection — the CERTIFIED spec report as
   the artifact. Nothing in pointblank's docs mentions
   prespecification, certification, or registration.
2. **Consequences vs severities.** action_levels is a severity model:
   5% failing rows may "warn", 10% "stop". revpiper deliberately
   rejected severity (spec §4): findings carry mechanical consequences
   (join skipped, not certifiable) and certification requires zero
   standing findings — acknowledgment declarations, not tolerance
   thresholds, are the only pass.
3. **Audience.** pointblank's user pipes R functions (its YAML is a
   serialization of code-built plans); revpiper's user writes YAML by
   hand as the primary interface — collaborators who never open R can
   author and read specs.
4. **Scope of workflow.** pointblank stops at validate-and-report;
   revpiper owns the pipeline around it: joins with declared
   relationships, corrections with audit trail, certification gating,
   transform prespecification.
5. **Backends.** pointblank invests heavily in databases/Spark —
   irrelevant to our CSV/Excel extraction-tool world and part of why
   it carries 21 Imports.

## Verdict on unique value

revpiper's value is distinct and holds. The honest overlap is the
single-table value checks — `col_vals_between` covers the same ground
a V-check will — but checks were never the product. The product is the
prespecify → collect → certify → correct → transform workflow with a
paper trail suitable for a systematic review's methods section, and no
part of that exists in pointblank. Conversely we should NOT drift
toward general data-quality monitoring: that ground is taken, by a
Posit-maintained package.

## Ideas worth taking (principles, not code)

- **`specially()`'s contract for custom checks** (flagged §10 today):
  a user function returning a logical vector (or table whose last
  column is logical) is a minimal, provable extension contract — a
  strong candidate shape for our custom-check registration, alongside
  our isolated-sourcing precedent from readers.R.
- **`scan_data()`'s section menu** (O V I C M S) is a ready-made
  requirements list for our eyeball report (§10): overview, per-
  variable summaries, interactions, correlations, missingness, sample.
  Ours should add spec-awareness: profile AGAINST the dictionary
  (declared vs observed), which theirs cannot do.
- **Step-hash provenance.** Multiagent's SHA1-per-step matching across
  interrogations is a concrete mechanism for the living-review diff
  question (§10): stable identities for checks/join-declarations so
  reports diff across published snapshots even as specs evolve.
- **Test-unit accounting** (n_passed/f_passed per check) would make
  our stage reports more informative than problem lists alone —
  compatible with certification (still zero-tolerance; fractions are
  information, not thresholds).
- **`draft_validation()` validates our Task 13 bet** (draft generator
  from observed data) — convergent evolution by a mature package.
- **Their briefs/autobrief** (auto-generated human description per
  step) parallels our registry-rendered messages; nothing to change.

## Import their functionality?

Recommendation: **no dependency, now or foreseeably.**

- Weight: 21 hard Imports including gt and blastula against our lean
  Imports policy (Area 7); we'd carry an HTML/email stack we never use.
- Philosophy: threshold-based pass/fail is the one thing we
  deliberately designed away from; embedding their engine would
  reintroduce it at the core.
- Overlap is in the cheap part (per-column predicates our schema
  already generates) not the hard part (workflow, certification,
  joins, corrections).
- MIT license poses no barrier if a narrow borrow is ever wanted, and
  `scan_data()`-as-inspiration for the eyeball report is the likeliest
  candidate — to be weighed at Phase 2 planning against lighter
  profiling options and a spec-aware in-house report.

## Actions taken with this review

- §10 rows updated: pointblank recorded on the custom-checks row
  (specially() contract as candidate shape), the eyeball-report row
  (scan_data as reference), and the provenance row (step-hash idea).
- Spec appendix: pointblank added to externally verified references.
