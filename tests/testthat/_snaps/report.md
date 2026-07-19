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

