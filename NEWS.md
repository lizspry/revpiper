# revpiper 0.0.0.9000

* `rev_spec_audit()` audits the spec step, per file: every dictionary is
  checked standalone with problems gathered across all files, the joins
  spec is checked against the dictionaries that loaded, and one
  plain-text report per input spec file is written to a fresh run folder
  under `output/reports/` — a summary of the file's contents when it
  certifies, its error log when it does not. The console states each
  file's certification and points at the log of any file that failed.
  It never errors on spec problems and returns certification information
  only — never a usable spec object. Data-free: a spec set certifies
  before any data exists.
* `rev_spec_run()` runs the spec step: it performs, writes, and prints
  exactly what the audit does, then returns the validated spec set
  invisibly when every file certifies — or, after all checking has
  completed, halts with one classed error: nothing returned, so no later
  pipeline step executes on an unsound spec. `file =` runs a single spec
  file standalone. First member of the per-step command family: every
  step gets `rev_<step>_audit` (check and report) and `rev_<step>_run`
  (execute and produce output).
* Error reports gained a deterministic `related` column that records
  checked facts, never guessed causes: an error sharing its entry with
  other errors says so ("fixing it may clear this one"), and a failed
  name lookup whose search list was provably incomplete — a column entry
  with an unreadable name, or a join naming a failed file's table —
  says why. Empty `related` means the error stands alone; the
  `suggestion` column keeps the did-you-mean hints.
* Report files are plain text with plainly aligned columns, replacing
  the xlsx workbook and separate certificate (the writexl dependency is
  dropped); every run writes into its own timestamped folder that mirrors the
  spec folder's layout, so no run and no two input files ever share a
  report path.
* Spec-error messages end with a help pointer (`?rev_spec_run`, whose
  docs describe the spec layout and the shipped examples) instead of a
  `system.file()` incantation.
* From the first adversarial spec-only test battery: an unparseable
  spec file is reported as a spec problem with the YAML parser's message
  embedded, never a raw error (YS05); a `combine` level may not collide
  with a declared column name (YS06).
* Project bootstrapped: package skeleton, conventions, CI.
