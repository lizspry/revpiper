# audit prints per-file certification, returns invisibly, specs stripped

    Code
      out <- rev_spec_audit("specs")
    Message
      revpiper spec audit: NOT CERTIFIED (1 of 3 files certified)
      x estimates.yaml — NOT CERTIFIED (2 errors) — see output/reports/spec-<runstamp>/tables/estimates.yaml.txt
      v rob.yaml — CERTIFIED
      x joins.yaml — NOT CERTIFIED (1 error) — see output/reports/spec-<runstamp>/joins.yaml.txt

# audit success: reports written, specs still not returned

    Code
      out <- rev_spec_audit("specs")
    Message
      revpiper spec audit: SUCCESS
      v all input files CERTIFIED (3 of 3 files certified)
      v estimates.yaml — CERTIFIED
      v rob.yaml — CERTIFIED
      v joins.yaml — CERTIFIED
      v reports written to output/reports/spec-<runstamp>/

# printing the returned outcome repeats the console lines

    Code
      print(out)
    Output
      revpiper spec audit: SUCCESS
      ✔ all input files CERTIFIED (3 of 3 files certified)
      ✔ estimates.yaml — CERTIFIED
      ✔ rob.yaml — CERTIFIED
      ✔ joins.yaml — CERTIFIED
      ✔ reports written to output/reports/spec-<runstamp>/

# an expected-but-absent joins spec decertifies via YX04

    Code
      as.data.frame(record(out, "joins.yaml")$problems)
    Output
                    file    entry code
      1 specs/joins.yaml spec set YX04
                                                                                                                  message
      1 expected spec file 'specs/joins.yaml' does not exist; set joins = FALSE to run the spec step without a joins spec
        suggestion related
      1       <NA>    <NA>

# joins = FALSE is stated wherever the summary appears (review)

    Code
      out <- rev_spec_audit("specs", joins = FALSE)
    Message
      revpiper spec audit: SUCCESS
      v all input files CERTIFIED (2 of 2 files certified)
      v estimates.yaml — CERTIFIED
      v rob.yaml — CERTIFIED
      v reports written to output/reports/spec-<runstamp>/
      i joins excluded (joins = FALSE) and therefore not audited/run

---

    Code
      print(out)
    Output
      revpiper spec audit: SUCCESS
      ✔ all input files CERTIFIED (2 of 2 files certified)
      ✔ estimates.yaml — CERTIFIED
      ✔ rob.yaml — CERTIFIED
      ✔ reports written to output/reports/spec-<runstamp>/
      ℹ joins excluded (joins = FALSE) and therefore not audited/run

