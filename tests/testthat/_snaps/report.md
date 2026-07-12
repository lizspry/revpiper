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

