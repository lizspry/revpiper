# Spec-step blind pack — adversarial battery brief (2026-07)

You are designing adversarial test cases for an R package's spec step,
from its PUBLIC PROMISES ONLY. This pack is your complete knowledge: the
rendered help pages, the signed-off design excerpts, and the shipped
example spec files. You have not seen the implementation or its tests.

Your task: design spec files (YAML, complete file contents) and call
sequences intended to BREAK the promises below. For EVERY case, commit
your oracle FIRST: the exact expected outcome (certified or not; which
files certify; which error codes/columns appear where; what the console
must and must not say; what run returns) AND a citation of the clause in
this pack that entails it. If this pack does not determine the outcome,
say UNDETERMINED and state the ambiguity precisely — that is a
first-class, valuable verdict. Prefer minimal pairs (two nearly
identical cases whose outcomes must differ). Return 6-10 cases as:
CASE n / LENS / FILES (fenced yaml per file with its path) / CALL /
EXPECTED (the oracle) / CLAUSE (quoted phrase).


===== RENDERED HELP: rev_spec_run.Rd =====
_R_u_n _t_h_e _s_p_e_c _s_t_e_p

_D_e_s_c_r_i_p_t_i_o_n:

     Performs, writes, and prints exactly what ‘rev_spec_audit()’ does
     — the same checks, the same per-file reports, the same console
     lines — then, when every file certifies, returns the validated
     spec set invisibly, ready for the next step. When any file does
     not certify, it raises one error after all checking has completed:
     nothing is returned, and no later pipeline step executes on an
     unsound spec.

_U_s_a_g_e:

     rev_spec_run(dir = "specs", file = NULL, joins = TRUE)
     
_A_r_g_u_m_e_n_t_s:

     dir: The spec folder: table dictionaries in <dir>/tables/, the
          joins spec at <dir>/joins.yaml.

    file: A single spec filename to run standalone with within-file
          checks only: a dictionary filename resolved in <dir>/tables/,
          or ‘"joins.yaml"’. A filename, never a path. Overrides
          ‘joins’.

   joins: Include the joins spec? ‘TRUE’ (the default) makes an absent
          <dir>/joins.yaml a standing error; ‘FALSE’ runs without it.

_V_a_l_u_e:

     The validated spec set, invisibly, on success: $tables (a named
     list of dictionaries) and $joins (the joins tibble; zero rows when
     skipped). Assign it to use it: ‘specs <- rev_spec_run()’. On
     failure, nothing is returned — the error halts the script, with
     the certification outcome riding on the condition as $outcome.

_S_p_e_c _l_a_y_o_u_t:

     A spec folder holds one dictionary per table in <dir>/tables/, and
     the joins spec beside them at <dir>/joins.yaml. Correctly
     formatted example files ship with the package — locate them with
     ‘system.file("extdata", "specs-example", package = "revpiper")’.

_T_h_e _r_e_l_a_t_e_d _c_o_l_u_m_n:

     The ‘related’ column never guesses causes. It records one of two
     checkable facts:

        • *Same entry:* this error sits in the same entry as at least
          one other error. Fixing that one entry and re-running may
          clear several errors at once.

        • *Incomplete search:* this error says a name couldn't be found
          (a column, a table) — and the place that should have declared
          that name is itself broken (a column entry whose own name
          can't be read, or a spec file that failed its checks). The
          search was therefore run against an incomplete list. Fix the
          broken declaration first; this error may then disappear on
          its own.

     When ‘related’ is empty, the error stands on its own as far as
     revpiper can tell — most often a typo or a genuine omission, and
     the ‘suggestion’ column is the better guide.

_E_x_a_m_p_l_e_s:

     # run writes output/reports/ under the working directory, so this
     # example runs in a throwaway one
     specs_dir <- system.file("extdata", "specs-example", package = "revpiper")
     owd <- setwd(tempdir())
     specs <- rev_spec_run(specs_dir)
     names(specs$tables)
     specs$joins
     setwd(owd)
     


===== RENDERED HELP: rev_spec_audit.Rd =====
_A_u_d_i_t _t_h_e _s_p_e_c _s_t_e_p

_D_e_s_c_r_i_p_t_i_o_n:

     Checks every spec file and reports, per file — it never errors on
     spec problems, and never returns a usable spec object. Every table
     dictionary is checked standalone with problems accumulated across
     all files, the across-dictionary identity check runs over the
     dictionaries that loaded, and (with ‘joins = TRUE’) the joins spec
     is checked against them. One plain-text report per input spec file
     is written to a fresh run folder under output/reports/ — a summary
     of the file's contents when it certifies, its error log when it
     does not — and the console states each file's certification with a
     pointer to the log of any file that failed. Data-free: it checks
     that sources are declared, never that data files exist, so a spec
     set certifies before any data is collected.

_U_s_a_g_e:

     rev_spec_audit(dir = "specs", joins = TRUE)
     
_A_r_g_u_m_e_n_t_s:

     dir: The spec folder: table dictionaries in <dir>/tables/, the
          joins spec at <dir>/joins.yaml.

   joins: Expect the joins spec? ‘TRUE’ (the default) makes an absent
          <dir>/joins.yaml a standing error; ‘FALSE’ audits without it.

_D_e_t_a_i_l_s:

     ‘rev_spec_run()’ performs, writes, and prints exactly what this
     audit does, then hands the validated spec set to the next step;
     the audit is the check-only member of the pair.

_V_a_l_u_e:

     Certification information only, invisibly (the same lines were
     just printed; ‘print()’ the result to see them again): the
     per-file records ($files), the overall $certified, and the report
     paths ($paths). Never the spec set — ‘rev_spec_run()’ is the
     function that hands the validated specs onward.

_T_h_e _r_e_l_a_t_e_d _c_o_l_u_m_n:

     The ‘related’ column never guesses causes. It records one of two
     checkable facts:

        • *Same entry:* this error sits in the same entry as at least
          one other error. Fixing that one entry and re-running may
          clear several errors at once.

        • *Incomplete search:* this error says a name couldn't be found
          (a column, a table) — and the place that should have declared
          that name is itself broken (a column entry whose own name
          can't be read, or a spec file that failed its checks). The
          search was therefore run against an incomplete list. Fix the
          broken declaration first; this error may then disappear on
          its own.

     When ‘related’ is empty, the error stands on its own as far as
     revpiper can tell — most often a typo or a genuine omission, and
     the ‘suggestion’ column is the better guide.

_E_x_a_m_p_l_e_s:

     # the audit writes output/reports/ under the working directory, so
     # this example runs in a throwaway one
     specs_dir <- system.file("extdata", "specs-example", package = "revpiper")
     owd <- setwd(tempdir())
     rev_spec_audit(dir = specs_dir)
     list.files("output/reports", recursive = TRUE)
     setwd(owd)
     

===== DESIGN EXCERPTS (signed off 2026-07-19) =====
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
  certified reports on success, same console lines). It always completes
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
## Per-file reports, written by audit and run alike
## (replaces xlsx workbook + certificate)

- One plain-text report **per input spec file**, written to a per-run
  folder, never overwriting prior runs:
  `output/reports/spec-<runstamp>/<specfile>.txt` (folder name neutral —
  both functions write it).
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
✖ estimates.yaml — NOT CERTIFIED (2 errors) — see output/reports/spec-20260719-101502/estimates.txt
✖ joins.yaml — NOT CERTIFIED (1 error) — see output/reports/spec-20260719-101502/joins.txt
```

(Audit success: the same shape — overall line, per-file CERTIFIED lines,
reports-written line as in run's success mock below.)

Run, failure — identical to audit, then the halting error (R always
prints a final `Error:` line when a script is stopped; it is kept to one
short sentence):

```
revpiper spec run: NOT CERTIFIED (1 of 3 files certified)
✔ rob.yaml — CERTIFIED
✖ estimates.yaml — NOT CERTIFIED (2 errors) — see output/reports/spec-20260719-101502/estimates.txt
✖ joins.yaml — NOT CERTIFIED (1 error) — see output/reports/spec-20260719-101502/joins.txt
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

===== SHIPPED EXAMPLE SPECS =====

--- inst/extdata/specs-example/tables/estimates.yaml ---
table: estimates
description: One row per extracted estimate.
source:
  file: data/raw/estimates.csv
levels:
  study: study
columns:
  - name: study
    type: text
    required: true
  - name: design
    type: text
    values: [RCT, Cohort]
  - name: mean_age
    type: decimal
    range: [10, 60]
    units: years
    constant_within_level: study
    missing: ["NR"]
  - name: rob_score
    type: integer
    values: [1, 2, 9]
  - name: notes_temp
    type: text

--- inst/extdata/specs-example/tables/rob.yaml ---
table: rob
description: One row per study's risk-of-bias rating.
source:
  file: data/raw/rob.csv
levels:
  study: study_id
columns:
  - name: study_id
    type: text
    required: true
  - name: rob_direct
    type: text
    values: [low, high]

--- inst/extdata/specs-example/joins.yaml ---
joins:
  - adds: variables
    left: estimates
    right: rob
    keys:
      estimates: [study]
      rob: [study_id]
    relationship: one-to-many
    unmatched_ok: false
