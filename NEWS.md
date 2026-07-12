# revpiper 0.0.0.9000

* `rev_spec_run()` runs the spec step: reads and validates every table
  dictionary and (by default, `joins = TRUE`) the joins spec, returning
  the validated spec objects — or errors listing every spec problem at
  once. `file =` runs a single spec file standalone. First member of the
  per-step command family: every step gets `rev_<step>_audit` (check and
  report) and `rev_<step>_run` (execute and produce output).
* Project bootstrapped: package skeleton, conventions, CI.
