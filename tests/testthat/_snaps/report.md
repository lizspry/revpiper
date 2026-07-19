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
      column entry 5   YE01   unknown field 'nam'             name         another error sits in this entry — fixing it may clear this one
      column entry 5   YE02   missing required field 'name'                another error sits in this entry — fixing it may clear this one

