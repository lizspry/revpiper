# Spec-step user-friendliness redesign

**Date:** 2026-07-19
**Status:** DRAFT — pending Liz's review
**Origin:** Liz's error-testing session, 2026-07-17/19. Decisions below were
settled point-by-point in that session's discussion.
**Relation to the design spec:** amends the report/certification machinery
(Tasks 16-17) and the spec-step audit/run semantics. The spec amendment to
`2026-07-07-revpiper-design.md` lands in the same branch as the
implementation, per the outward-docs-never-fork-the-design rule.

## Problems being solved

1. `rev_spec_run()` stops at the first bad file and dumps every problem as
   one opaque error; no statement of what passed or failed, per file.
2. The error footer ("Canonical spec examples ship with the package:
   `system.file(...)`") is jargon and routes the user somewhere unhelpful.
3. Cascading errors: one root problem (a misspelled field) produces
   downstream problems (missing required field; join fails to resolve)
   with nothing connecting them. With larger spec sets this balloons.
4. The report workbook's column headers are bold/centred (writexl default);
   contents should align naturally.
5. The run/audit distinction was not explainable, and certification was
   overall-only: certificate file + xlsx report + console text overlapped
   without any per-file view.

## The governing rule (settles run vs audit)

> **Audit checks and reports; run performs the same checks and, when
> sound, hands the step's product to the next step.**

- One shared checking engine; two thin entry points. The pair applies at
  every step (`rev_<step>_audit` / `rev_<step>_run`), preserving the
  settled grammar. Precedent: standard ETL practice (dbt `test` vs `run`,
  Frictionless `validate`, Great Expectations checkpoints).
- **Audit never errors on spec problems, never returns a usable spec
  object.** It returns certification information only.
- **Run always completes all checking for the step first** (no first-file
  abort), then on any failure raises one clear error: no object returned,
  no later pipeline step executes. On success it returns the spec set
  invisibly.
- An audit finishes examining everything **independent** and explicitly
  marks — rather than attempts — everything **dependent** on a failure
  (e.g. a join referencing a table whose file failed). It never continues
  *through* a dependency, only *around* one. Cross-step this is
  structural: a failed spec step yields no object, so no later step can
  check data against an unsound spec.

## Audit: per-file reports (replaces xlsx workbook + certificate)

- One plain-text report **per input spec file**, written to a per-run
  folder, never overwriting prior runs:
  `output/reports/spec-audit-<runstamp>/<specfile>.txt`.
- Certified dictionary report: status + summary of the file's own contents
  (table, source, columns, levels). **No joins information in a
  dictionary's report** — joins summaries and errors belong solely to
  `joins.yaml`'s report, which follows the same pattern.

```
revpiper spec audit — estimates.yaml
Status: CERTIFIED

Table:   estimates
Source:  data/raw/estimates.csv
Columns: 5 — study, design, mean_age, rob_score, notes_temp
Levels:  study

Errors: none.
```

- Uncertified file report: status + error log. Headers plain, columns
  aligned per contents (no centring).

```
revpiper spec audit — estimates.yaml
Status: NOT CERTIFIED (2 errors)

Errors:
entry           code   message                suggestion   related
column entry 4  YE01   unknown field 'nam'    name         other error in this entry
column entry 4  YE02   field 'name' missing                other error in this entry
```

- An error spanning two files (e.g. YX01 duplicate table name) appears in
  both files' reports.
- The xlsx workbook, the separate certificate .txt, and the `writexl`
  dependency are retired.

## The `related` column (replaces any causal claim)

Fully deterministic only — never asserts causation, never uses the
spelling-distance heuristic (that stays in `suggestion`, phrased as a
question):

1. **Same entry:** the error sits in an entry that has other errors.
2. **References an entry/file with errors:** the error arose resolving a
   reference to something that itself has standing errors — e.g.
   `'estimates' does not resolve — its spec file estimates.yaml has
   standing errors` (the intended table name read directly from the failed
   file's raw YAML; if unreadable, no link is asserted).

The implementation plan enumerates every reference route eligible for
rule 2 (joins sides/keys, level references, `constant_within_level`, …)
and states each route's trigger precisely.

## Console output (no duplication with the files)

Both functions print the same per-file certification lines from the same
core; only the closing differs.

Audit — points to the reports it wrote:

```
✔ rob.yaml — CERTIFIED
✖ estimates.yaml — NOT CERTIFIED (2 errors) — see output/reports/spec-audit-20260719-101502/estimates.txt
✖ joins.yaml — NOT CERTIFIED (1 error) — see output/reports/spec-audit-20260719-101502/joins.txt
Spec step: NOT CERTIFIED (1 of 3 files certified)
```

Run, failure — first error per failed file only, then one error that
halts the script and points to audit:

```
✔ rob.yaml — CERTIFIED
✖ estimates.yaml — NOT CERTIFIED — first error: unknown field 'nam' (did you mean 'name'?)
✖ joins.yaml — NOT CERTIFIED — references table 'estimates', whose spec file has errors
Spec step: NOT CERTIFIED (1 of 3 files certified)
Error: Spec step failed. Run rev_spec_audit() for the full diagnostic report.
```

Run, success — invisible return; detail routes to audit:

```
✔ estimates.yaml — CERTIFIED
✔ rob.yaml — CERTIFIED
✔ joins.yaml — CERTIFIED
Spec step: CERTIFIED (3 of 3 files)
ℹ For a detailed per-file record, run rev_spec_audit().
```

## Returns

- `rev_spec_audit()`: certification information only — per-file statuses,
  standing problems, report paths. Printable. The `attr(report, "specs")`
  ride-along is removed.
- `rev_spec_run()`: the spec set, returned **invisibly** on success
  (assignment and `print()` behave as normal R); nothing on failure.
  Single-file mode (`file =`) retained, same presentation.

## Error footer

Every spec-error footer becomes a plain help pointer (replacing the
`system.file()` examples pointer; the example files themselves are
unchanged and remain runnable documentation):

> See `?rev_spec_run` for the expected spec layout, with correctly
> formatted examples.

## Unchanged

- All check codes, gates, and within-entry root-cause-once behaviour.
- The schema registry, problem schema (plus the new `related` column).
- `dir`/`file`/`joins` arguments and their validation.

## Out of scope

- Any change to later steps (the rule above binds their design, but their
  implementation arrives in their own phases).
- Helpers not agreed: no `rev_spec_last()`, no examples-copying helper.
