# revpiper 0.0.0.9000

* `rev_spec_audit()` audits the spec step: every dictionary is checked
  with problems gathered across all files, the joins spec is checked
  against them, and the result is a spec report plus certificate written
  under `output/reports/` — CERTIFIED exactly when zero problems stand.
  It never errors on spec problems, states the outcome in one status
  line, and the certificate names each dictionary and the joins
  disposition. Data-free: a spec set certifies before any data exists.
* `rev_spec_run()` runs the spec step: reads and validates every table
  dictionary and (by default, `joins = TRUE`) the joins spec, returning
  the validated spec objects — or errors listing every spec problem at
  once. `file =` runs a single spec file standalone. First member of the
  per-step command family: every step gets `rev_<step>_audit` (check and
  report) and `rev_<step>_run` (execute and produce output).
* Project bootstrapped: package skeleton, conventions, CI.
