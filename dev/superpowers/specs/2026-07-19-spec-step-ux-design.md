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
- **Run performs, writes, and prints exactly what audit does — literally
  the same commands** (same checks, same per-file reports including the
  certified reports on success; the console shows the same per-file
  certification lines under the verb's own banner, run adding its
  final-act lines — wording sharpened 2026-07-19, battery finding: the
  earlier "same console lines" overclaimed). It always completes
  all checking first (no first-file abort). It differs only in its final
  act: on success it returns the spec set invisibly; on any failure it
  raises one clear error — nothing returned, no later pipeline step
  executes.
- An audit finishes examining everything **independent** and explicitly
  marks — rather than attempts — everything **dependent** on a failure
  (e.g. a join referencing a table whose file failed). It never continues
  *through* a dependency, only *around* one. Cross-step this is
  structural: a failed spec step yields no object, so no later step can
  check data against an unsound spec.

## Per-file reports, written by audit and run alike
## (replaces xlsx workbook + certificate)

- One plain-text report **per input spec file**, written to a per-run
  folder that MIRRORS the spec folder's layout (battery amendment, Liz
  2026-07-19 — full input filename kept, so same-stem inputs can never
  collide on one report path): dictionaries under
  `output/reports/spec-<runstamp>/tables/<file>.txt`, the joins spec at
  `output/reports/spec-<runstamp>/joins.yaml.txt`. Never overwrites
  prior runs; folder name neutral — both functions write it.
- Certified dictionary report: status + summary of the file's own contents
  (table, source, columns, levels). **No joins information in a
  dictionary's report** — joins summaries and errors belong solely to
  `joins.yaml`'s report, which follows the same pattern.

```
revpiper spec report — estimates.yaml
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
revpiper spec report — estimates.yaml
Status: NOT CERTIFIED (2 errors)

Errors:
entry           code   message                suggestion   related
column entry 4  YE01   unknown field 'nam'    name         another error sits in this entry — fixing it may clear this one
column entry 4  YE02   field 'name' missing                another error sits in this entry — fixing it may clear this one
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
2. **Incomplete search** (amended 2026-07-19, Liz): the error is a failed
   name lookup, and the pool it searched is *provably incomplete*:
   - within a file — the referred section contains entries whose own
     names cannot be read (`entry_names()` NA); related reads
     `a column entry's name cannot be read, so this search ran against
     an incomplete list — fixing it may clear this one` (self-contained
     wording, Liz 2026-07-19; phrases live in one home,
     `related_phrases` in spec-problems.R).
     Errors that do not remove names from the pool (e.g. a bad range on
     a correctly named column) never trigger related — they cannot
     explain a failed reference.
   - across files — a join side names the table a failed spec file
     intended (its `table:` field, read from raw YAML; if unreadable, no
     link); related reads `spec file estimates.yaml failed its checks,
     so its table was not available to search`.

**User-facing definition (verbatim in the help docs, signed off
2026-07-19):**

> The `related` column never guesses causes. It records one of two
> checkable facts:
>
> - **Same entry:** this error sits in the same entry as at least one
>   other error. Fixing that one entry and re-running may clear several
>   errors at once.
> - **Incomplete search:** this error says a name couldn't be found (a
>   column, a table) — and the place that should have declared that name
>   is itself broken (a column entry whose own name can't be read, or a
>   spec file that failed its checks). The search was therefore run
>   against an incomplete list. Fix the broken declaration first; this
>   error may then disappear on its own.
>
> The note appears only when the broken declaration belongs to the very
> list that was searched: a nameless column entry depletes searches of
> the columns list, never of the levels list (whose names are the
> mapping keys and always readable).
>
> When `related` is empty, the error stands on its own as far as
> revpiper can tell — most often a typo or a genuine omission, and the
> `suggestion` column is the better guide.

## Console output (no duplication with the files)

Both functions print the same per-file certification lines from the same
core; only the closing differs.

Audit — points to the reports it wrote:

```
revpiper spec audit: NOT CERTIFIED (1 of 3 files certified)
✔ rob.yaml — CERTIFIED
✖ estimates.yaml — NOT CERTIFIED (2 errors) — see output/reports/spec-20260719-101502/tables/estimates.yaml.txt
✖ joins.yaml — NOT CERTIFIED (1 error) — see output/reports/spec-20260719-101502/joins.yaml.txt
```

(Audit success: the same shape — overall line, per-file CERTIFIED lines,
reports-written line as in run's success mock below.)

Run, failure — identical to audit, then the halting error (R always
prints a final `Error:` line when a script is stopped; it is kept to one
short sentence):

```
revpiper spec run: NOT CERTIFIED (1 of 3 files certified)
✔ rob.yaml — CERTIFIED
✖ estimates.yaml — NOT CERTIFIED (2 errors) — see output/reports/spec-20260719-101502/tables/estimates.yaml.txt
✖ joins.yaml — NOT CERTIFIED (1 error) — see output/reports/spec-20260719-101502/joins.yaml.txt
Error: spec set not certified and not returned.
```

Run, success — invisible return:

```
revpiper spec run: SUCCESS
✔ all input files CERTIFIED (3 of 3 files certified)
✔ estimates.yaml — CERTIFIED
✔ rob.yaml — CERTIFIED
✔ joins.yaml — CERTIFIED
✔ reports written to output/reports/spec-20260719-101502/
✔ spec set returned, ready for the load step
```

## Returns

- `rev_spec_audit()`: certification information only — per-file statuses,
  standing problems, report paths. Printable. The `attr(report, "specs")`
  ride-along is removed.
- `rev_spec_run()`: identical side effects to `rev_spec_audit()` (same
  reports, same console lines). Return value: the spec set, **invisibly**,
  on success; on failure nothing is returned — the error above halts the
  script. Single-file mode (`file =`) retained, same presentation.

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
