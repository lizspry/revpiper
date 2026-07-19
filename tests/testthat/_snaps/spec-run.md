# run success: audit-identical output plus final acts; spec set invisible

    Code
      specs <- rev_spec_run("specs")
    Message
      revpiper spec run: SUCCESS
      v all input files CERTIFIED (3 of 3 files certified)
      v estimates.yaml — CERTIFIED
      v rob.yaml — CERTIFIED
      v joins.yaml — CERTIFIED
      v reports written to output/reports/spec-<runstamp>/
      v spec set returned, ready for the load step

# run failure: all checking completes, reports written, then one abort

    Code
      rev_spec_run("specs")
    Message
      revpiper spec run: NOT CERTIFIED (1 of 3 files certified)
      x estimates.yaml — NOT CERTIFIED (2 errors) — see output/reports/spec-<runstamp>/tables/estimates.yaml.txt
      v rob.yaml — CERTIFIED
      x joins.yaml — NOT CERTIFIED (1 error) — see output/reports/spec-<runstamp>/joins.yaml.txt
    Condition
      Error:
      ! spec set not certified and not returned.

# single-file mode keeps the same presentation

    Code
      one <- rev_spec_run("specs", file = "estimates.yaml")
    Message
      revpiper spec run: SUCCESS
      v all input files CERTIFIED (1 of 1 files certified)
      v estimates.yaml — CERTIFIED
      v reports written to output/reports/spec-<runstamp>/
      v spec set returned, ready for the load step

