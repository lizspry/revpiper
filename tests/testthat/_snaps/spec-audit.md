# the certified audit: status line and certificate

    Code
      print(rev_spec_audit())
    Message
      v Spec step CERTIFIED — certificate written to
      'output/reports/spec-<runstamp>-certificate.txt'.
    Output
      revpiper spec report
      Status: CERTIFIED
      Standing items: 0
      Dictionary: estimates.yaml — table 'estimates'
      Dictionary: rob.yaml — table 'rob'
      Joins: included

# the not-certified audit: status line and certificate

    Code
      print(rev_spec_audit())
    Message
      x Spec step NOT CERTIFIED (1 standing problem)
      — report written to 'output/reports/spec-<runstamp>.xlsx'.
    Output
      revpiper spec report
      Status: NOT CERTIFIED
      Standing items: 1
      Dictionary: estimates.yaml — table 'estimates'
      Dictionary: rob.yaml — table 'rob'
      Joins: included

# joins expected but absent is a standing item, not an error

    Code
      as.data.frame(report$items[, c("code", "message")])
    Output
        code
      1 YX04
                                                                                                      message
      1 expected spec file 'specs/joins.yaml' does not exist; set joins = FALSE to audit without a joins spec

