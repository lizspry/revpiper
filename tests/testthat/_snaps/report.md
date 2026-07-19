# the certificate renders both statuses

    Code
      print(new_stage_report("spec", no_problems()))
    Output
      revpiper spec report
      Status: CERTIFIED
      Standing items: 0

---

    Code
      print(new_stage_report("spec", one_item()))
    Output
      revpiper spec report
      Status: NOT CERTIFIED
      Standing items: 1

# annex lines render verbatim after the standing count

    Code
      print(report)
    Output
      revpiper spec report
      Status: CERTIFIED
      Standing items: 0
      first stage-specific annex line
      second one, verbatim

# certified reports: status, summary, no errors

    Code
      writeLines(format_file_report(record(out, "estimates.yaml")))
    Output
      revpiper spec report — estimates.yaml
      Status: CERTIFIED
      
      Table:   estimates
      Source:  data/raw/estimates.csv
      Columns: 5 — study, design, mean_age, rob_score, notes_temp
      Levels:  study
      
      Errors: none.

---

    Code
      writeLines(format_file_report(record(out, "joins.yaml")))
    Output
      revpiper spec report — joins.yaml
      Status: CERTIFIED
      
      Joins: 1
        estimates <-> rob — adds variables
      
      Errors: none.

# uncertified report: error table only, aligned per contents

    Code
      writeLines(lines)
    Output
      revpiper spec report — estimates.yaml
      Status: NOT CERTIFIED (2 errors)
      
      Errors:
      entry            code   message                         suggestion   related
      column entry 5   YE01   unknown field 'nam'             name         other error in this entry
      column entry 5   YE02   missing required field 'name'                other error in this entry

