# Spec-step adversarial pack (derived from public promises only)

This pack turns the promises in [spec-step-blind-pack-2026-07.md](/Users/claude/Documents/cc-workbench/revpiper/dev/adversarial/spec-step-blind-pack-2026-07.md) into oracle-first adversarial cases. It stays deliberately black-box: when the brief does not fix an outcome, the oracle says `UNDETERMINED`.

## CASE 1 / LENS / missing joins is a standing error by default

### CASE 1 FILES

Path: `specs/tables/estimates.yaml`

```yaml
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
```

No `specs/joins.yaml`.

### CASE 1 CALL

```r
audit <- rev_spec_audit(dir = "specs")
run_result <- tryCatch(rev_spec_run(dir = "specs"), error = identity)
```

### CASE 1 EXPECTED

- `rev_spec_audit()` does not error.
- Overall certification is false.
- `rev_spec_run()` performs the same checking and report writing, then errors once.
- The run error text must include `spec set not certified and not returned.`
- Nothing is returned from `rev_spec_run()`.
- Whether a missing `joins.yaml` gets its own report file is `UNDETERMINED`.

### CASE 1 CLAUSE

`TRUE (the default) makes an absent <dir>/joins.yaml a standing error` and `on any failure it raises one clear error — nothing returned`.

## CASE 2 / LENS / `joins = FALSE` flips Case 1

### CASE 2 FILES

Path: `specs/tables/estimates.yaml`

```yaml
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
```

No `specs/joins.yaml`.

### CASE 2 CALL

```r
audit <- rev_spec_audit(dir = "specs", joins = FALSE)
specs <- rev_spec_run(dir = "specs", joins = FALSE)
```

### CASE 2 EXPECTED

- If the dictionary certifies, audit certifies and run succeeds.
- `rev_spec_run()` returns invisibly.
- The returned object has `$joins` with zero rows.
- Reports are still written under `output/reports/spec-<runstamp>/`.

### CASE 2 CLAUSE

`FALSE runs without it` and `$joins (the joins tibble; zero rows when skipped)`.

## CASE 3 / LENS / single-file mode overrides joins

### CASE 3 FILES

Path: `specs/tables/estimates.yaml`

```yaml
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
```

No `specs/joins.yaml`.

### CASE 3 CALL

```r
specs <- rev_spec_run(dir = "specs", file = "estimates.yaml", joins = TRUE)
```

### CASE 3 EXPECTED

- The missing joins file must not matter.
- Only within-file checks apply.
- `file` overrides `joins`.
- Success return shape beyond an invisible validated object is `UNDETERMINED`.

### CASE 3 CLAUSE

`A single spec filename to run standalone with within-file checks only` and `Overrides joins`.

## CASE 4 / LENS / run must complete all checking before erroring

### CASE 4 FILES

Path: `specs/tables/estimates.yaml`

```yaml
table: estimates
description: One row per extracted estimate.
source:
  file: data/raw/estimates.csv
levels:
  study: study
columns:
  - nam: study
    type: text
```

Path: `specs/tables/rob.yaml`

```yaml
table: rob
description: One row per study's risk-of-bias rating.
source:
  file: data/raw/rob.csv
columns:
  - name: study_id
    type: text
```

Path: `specs/joins.yaml`

```yaml
joins:
  - adds: variables
    left: estimates
    right: rob
    keys:
      estimates: [study]
      rob: [study_id]
    relationship: one-to-many
    unmatched_ok: false
```

### CASE 4 CALL

```r
audit <- rev_spec_audit(dir = "specs")
run_result <- tryCatch(rev_spec_run(dir = "specs"), error = identity)
```

### CASE 4 EXPECTED

- Audit checks all inputs without aborting at the first failure.
- Run also checks all inputs before the single halting error.
- Reports are written for all input spec files.
- The joins failure, if dependent on the broken dictionary, is marked rather than checked through.
- Exact error-code inventory is only partly fixed by the brief.

### CASE 4 CLAUSE

`It always completes all checking first (no first-file abort)` and `explicitly marks — rather than attempts — everything dependent on a failure`.

## CASE 5 / LENS / same-entry related text on multiple errors in one entry

### CASE 5 FILES

Path: `specs/tables/estimates.yaml`

```yaml
table: estimates
description: One row per extracted estimate.
source:
  file: data/raw/estimates.csv
columns:
  - nam: study
    type: text
```

Path: `specs/joins.yaml`

```yaml
joins: []
```

### CASE 5 CALL

```r
audit <- rev_spec_audit(dir = "specs")
```

### CASE 5 EXPECTED

- `estimates.yaml` is not certified.
- Its report shows multiple errors for the same column entry if the sample codes are implemented.
- For those errors, `related` is not empty and carries the same-entry meaning.
- The text must not claim causation.

### CASE 5 CLAUSE

`Same entry: this error sits in the same entry as at least one other error`.

## CASE 6 / LENS / within-file incomplete-search versus ordinary missing name

### CASE 6 FILES A

Path: `specs/tables/estimates.yaml`

```yaml
table: estimates
description: One row per extracted estimate.
source:
  file: data/raw/estimates.csv
columns:
  - nam: study
    type: text
  - name: mean_age
    type: decimal
    constant_within_level: study
```

Path: `specs/joins.yaml`

```yaml
joins: []
```

### CASE 6 FILES B

Path: `specs/tables/estimates.yaml`

```yaml
table: estimates
description: One row per extracted estimate.
source:
  file: data/raw/estimates.csv
columns:
  - name: study_id
    type: text
  - name: mean_age
    type: decimal
    constant_within_level: study
```

Path: `specs/joins.yaml`

```yaml
joins: []
```

### CASE 6 CALL

```r
rev_spec_audit(dir = "specs")
```

### CASE 6 EXPECTED

- In A, the failed lookup of `study` is against a provably incomplete pool, so `related` must carry the incomplete-search wording.
- In B, the failed lookup of `study` is a plain missing name in a readable pool, so `related` must be empty.
- Suggestion content is `UNDETERMINED`.

### CASE 6 CLAUSE

`Errors that do not remove names from the pool ... never trigger related` and `the referred section contains entries whose own names cannot be read`.

## CASE 7 / LENS / across-file incomplete-search from failed dictionary

### CASE 7 FILES

Path: `specs/tables/estimates.yaml`

```yaml
table: estimates
description: One row per extracted estimate.
source:
  file: data/raw/estimates.csv
columns:
  - nam: study
    type: text
```

Path: `specs/tables/rob.yaml`

```yaml
table: rob
description: One row per study's risk-of-bias rating.
source:
  file: data/raw/rob.csv
columns:
  - name: study_id
    type: text
```

Path: `specs/joins.yaml`

```yaml
joins:
  - adds: variables
    left: estimates
    right: rob
    keys:
      estimates: [study]
      rob: [study_id]
    relationship: one-to-many
    unmatched_ok: false
```

### CASE 7 CALL

```r
audit <- rev_spec_audit(dir = "specs")
```

### CASE 7 EXPECTED

- `estimates.yaml` fails its own checks.
- A dependent joins lookup failure should carry the across-files incomplete-search wording.
- The checker must not continue through the failed table as if it were certified.

### CASE 7 CLAUSE

`spec file estimates.yaml failed its checks, so its table was not available to search`.

## CASE 8 / LENS / duplicate table identity error appears in both reports

### CASE 8 FILES

Path: `specs/tables/estimates.yaml`

```yaml
table: dup_table
description: First dictionary
source:
  file: data/raw/a.csv
columns:
  - name: id
    type: text
```

Path: `specs/tables/rob.yaml`

```yaml
table: dup_table
description: Second dictionary
source:
  file: data/raw/b.csv
columns:
  - name: id
    type: text
```

Path: `specs/joins.yaml`

```yaml
joins: []
```

### CASE 8 CALL

```r
audit <- rev_spec_audit(dir = "specs")
run_result <- tryCatch(rev_spec_run(dir = "specs"), error = identity)
```

### CASE 8 EXPECTED

- Both dictionary files are not certified.
- The duplicate-table-name error appears in both file reports.
- If the sample identifier is implemented, the code is `YX01` in both reports.
- Run still writes and prints the same checking results as audit before the final halt.

### CASE 8 CLAUSE

`the across-dictionary identity check runs over the dictionaries that loaded` and `An error spanning two files (e.g. YX01 duplicate table name) appears in both files' reports`.

## CASE 9 / LENS / absent joins as an input file versus absent joins as a standing error

### CASE 9 FILES

Path: `specs/tables/estimates.yaml`

```yaml
table: estimates
description: One row per extracted estimate.
source:
  file: data/raw/estimates.csv
columns:
  - name: study
    type: text
```

No `specs/joins.yaml`.

### CASE 9 CALL

```r
audit <- rev_spec_audit(dir = "specs", joins = TRUE)
```

### CASE 9 EXPECTED

- `rev_spec_audit()` does not error.
- Overall certification is false because the absent joins file is a standing error.
- `UNDETERMINED`: whether an absent `joins.yaml` counts as an `input spec file` for the per-file-report rule.
- `UNDETERMINED`: whether a missing `joins.txt` report must be written, or whether only existing input files get reports.
- `UNDETERMINED`: whether the console must include a per-file line for `joins.yaml` when the file does not exist, or only an overall failure line.

### CASE 9 CLAUSE

`One plain-text report per input spec file` versus `TRUE (the default) makes an absent <dir>/joins.yaml a standing error`.

## CASE 10 / LENS / single-file return shape is not fully specified

### CASE 10 FILES

Path: `specs/tables/estimates.yaml`

```yaml
table: estimates
description: One row per extracted estimate.
source:
  file: data/raw/estimates.csv
columns:
  - name: study
    type: text
```

Path: `specs/tables/rob.yaml`

```yaml
table: rob
description: One row per study's risk-of-bias rating.
source:
  file: data/raw/rob.csv
columns:
  - name: study_id
    type: text
```

No `specs/joins.yaml`.

### CASE 10 CALL

```r
specs <- rev_spec_run(dir = "specs", file = "estimates.yaml")
```

### CASE 10 EXPECTED

- The run should succeed if `estimates.yaml` certifies under within-file checks.
- The return is invisible.
- `UNDETERMINED`: whether the returned object contains only `estimates`, or both tables discovered in `specs/tables/`, or a one-table `$tables` plus zero-row `$joins`.
- `UNDETERMINED`: whether single-file mode returns the same object shape as full-directory mode or a reduced one-file shape.

### CASE 10 CLAUSE

`A single spec filename to run standalone with within-file checks only` and `Return value: the spec set ... Single-file mode (file =) retained, same presentation`.

## CASE 11 / LENS / filename-only contract does not specify the failure mode for a path

### CASE 11 FILES

Path: `specs/tables/estimates.yaml`

```yaml
table: estimates
description: One row per extracted estimate.
source:
  file: data/raw/estimates.csv
columns:
  - name: study
    type: text
```

Path: `specs/joins.yaml`

```yaml
joins: []
```

### CASE 11 CALL

```r
run_result <- tryCatch(
  rev_spec_run(dir = "specs", file = "tables/estimates.yaml"),
  error = identity
)
```

### CASE 11 EXPECTED

- The brief says `file` is `A filename, never a path`.
- `UNDETERMINED`: whether passing a path-like string is rejected immediately, normalized to a filename, or treated as a missing file.
- `UNDETERMINED`: if rejected, the error class, message, and whether any reports are written before rejection.

### CASE 11 CLAUSE

`A filename, never a path`.

## CASE 12 / LENS / unreadable raw YAML table identity blocks cross-file linking, but fallout is only partly specified

### CASE 12 FILES

Path: `specs/tables/estimates.yaml`

```yaml
table:
description: Broken table header
source:
  file: data/raw/estimates.csv
columns:
  - name: study
    type: text
```

Path: `specs/tables/rob.yaml`

```yaml
table: rob
description: One row per study's risk-of-bias rating.
source:
  file: data/raw/rob.csv
columns:
  - name: study_id
    type: text
```

Path: `specs/joins.yaml`

```yaml
joins:
  - adds: variables
    left: estimates
    right: rob
    keys:
      estimates: [study]
      rob: [study_id]
    relationship: one-to-many
    unmatched_ok: false
```

### CASE 12 CALL

```r
audit <- rev_spec_audit(dir = "specs")
```

### CASE 12 EXPECTED

- `estimates.yaml` does not certify.
- Because the intended table identity is unreadable from raw YAML, the across-files incomplete-search link must not be asserted.
- `UNDETERMINED`: the exact joins-side error inventory once that cross-file link is unavailable.
- `UNDETERMINED`: whether the joins failure is reported purely as a missing table, as a generic dependent failure, or as some other non-linked lookup error.

### CASE 12 CLAUSE

`across files — a join side names the table a failed spec file intended (its table: field, read from raw YAML; if unreadable, no link)`.
