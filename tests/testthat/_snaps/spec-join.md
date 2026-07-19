# each single-defect joins file reports naming its problem

    Code
      read_bad("joins-yx02-unknown-table.yaml")
    Output
               entry code                                           message
      1 join entry 1 YX02 'robb' does not resolve against the loaded tables
        suggestion related
      1        rob    <NA>

---

    Code
      read_bad("joins-yx02-unknown-key.yaml")
    Output
               entry code
      1 join entry 1 YX02
                                                             message suggestion
      1 'study_yd' does not resolve against the key columns of 'rob'   study_id
        related
      1    <NA>

---

    Code
      read_bad("joins-yx02-keys-non-side.yaml")
    Output
               entry code                                          message suggestion
      1 join entry 1 YX02 'robb' does not resolve against the join's sides        rob
        related
      1    <NA>

---

    Code
      read_bad("joins-yx03-keys-missing-side.yaml")
    Output
               entry code                                           message
      1 join entry 1 YX03 keys must name both sides ('estimates' and 'rob')
        suggestion related
      1       <NA>    <NA>

---

    Code
      read_bad("joins-yf03-bad-relationship.yaml")
    Output
               entry code                            message suggestion related
      1 join entry 1 YF03 unknown relationship 'one-to-lots'       <NA>    <NA>

---

    Code
      read_bad("joins-ye08-relationship-on-observations.yaml")
    Output
               entry code                                                     message
      1 join entry 1 YE08 'relationship' is not allowed when a join adds observations
        suggestion related
      1       <NA>    <NA>

# a self-join is flagged with or without dictionaries (YE09, battery)

    Code
      as.data.frame(p[c("entry", "code", "message", "suggestion", "related")])
    Output
               entry code                              message suggestion related
      1 join entry 1 YE09 left and right both name 'estimates'       <NA>    <NA>

