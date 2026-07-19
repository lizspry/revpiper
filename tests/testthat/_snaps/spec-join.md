# each single-defect joins file aborts naming its problem

    Code
      read_bad("joins-yx02-unknown-table.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x YX02 fixtures/specs-bad/joins-yx02-unknown-table.yaml / join entry 1: 'robb' does not resolve against the loaded tables (did you mean 'rob'?)
      i Canonical spec examples ship with the package: `system.file("extdata", "specs-example", package = "revpiper")`

---

    Code
      read_bad("joins-yx02-unknown-key.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x YX02 fixtures/specs-bad/joins-yx02-unknown-key.yaml / join entry 1: 'study_yd' does not resolve against the key columns of 'rob' (did you mean 'study_id'?)
      i Canonical spec examples ship with the package: `system.file("extdata", "specs-example", package = "revpiper")`

---

    Code
      read_bad("joins-yx02-keys-non-side.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x YX02 fixtures/specs-bad/joins-yx02-keys-non-side.yaml / join entry 1: 'robb' does not resolve against the join's sides (did you mean 'rob'?)
      i Canonical spec examples ship with the package: `system.file("extdata", "specs-example", package = "revpiper")`

---

    Code
      read_bad("joins-yx03-keys-missing-side.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x YX03 fixtures/specs-bad/joins-yx03-keys-missing-side.yaml / join entry 1: keys must name both sides ('estimates' and 'rob')
      i Canonical spec examples ship with the package: `system.file("extdata", "specs-example", package = "revpiper")`

---

    Code
      read_bad("joins-yf03-bad-relationship.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x YF03 fixtures/specs-bad/joins-yf03-bad-relationship.yaml / join entry 1: unknown relationship 'one-to-lots'
      i Canonical spec examples ship with the package: `system.file("extdata", "specs-example", package = "revpiper")`

---

    Code
      read_bad("joins-ye08-relationship-on-observations.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x YE08 fixtures/specs-bad/joins-ye08-relationship-on-observations.yaml / join entry 1: 'relationship' is not allowed when a join adds observations
      i Canonical spec examples ship with the package: `system.file("extdata", "specs-example", package = "revpiper")`

