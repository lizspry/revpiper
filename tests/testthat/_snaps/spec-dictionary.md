# a nonexistent dictionary path aborts with the classed error

    Code
      rev_read_dictionary("no/such/dictionary.yaml")
    Condition
      Error:
      ! Dictionary file 'no/such/dictionary.yaml' does not exist.

# each single-defect dictionary aborts naming its problem

    Code
      read_bad("y001-top-level.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x Y001 fixtures/specs-bad/y001-top-level.yaml / top level: unknown field 'descrption' (did you mean 'description'?)

---

    Code
      read_bad("y001-column-field.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x Y001 fixtures/specs-bad/y001-column-field.yaml / column 'mean_age': unknown field 'rnge' (did you mean 'range'?)

---

    Code
      read_bad("y002-bad-type.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x Y002 fixtures/specs-bad/y002-bad-type.yaml / column 'mean_age': unknown type 'decmal' (did you mean 'decimal'?)

---

    Code
      read_bad("y003-values-and-range.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x Y003 fixtures/specs-bad/y003-values-and-range.yaml / column 'mean_age': 'values' and 'range' are mutually exclusive

---

    Code
      read_bad("y004-values-on-date.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x Y004 fixtures/specs-bad/y004-values-on-date.yaml / column 'extraction_date': 'values' is not allowed on type 'date'

---

    Code
      read_bad("y005-range-on-text.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x Y005 fixtures/specs-bad/y005-range-on-text.yaml / column 'notes_temp': 'range' is not allowed on type 'text'

---

    Code
      read_bad("y006-units-on-text.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x Y006 fixtures/specs-bad/y006-units-on-text.yaml / column 'notes_temp': 'units' is only allowed on integer/decimal

---

    Code
      read_bad("y007-mixed-values.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x Y007 fixtures/specs-bad/y007-mixed-values.yaml / column 'rob_score': 'values' entries must all be of one type

---

    Code
      read_bad("y008-descending-range.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x Y008 fixtures/specs-bad/y008-descending-range.yaml / column 'mean_age': 'range' is descending (60 > 10)

---

    Code
      read_bad("y012-duplicate-column.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x Y012 fixtures/specs-bad/y012-duplicate-column.yaml / columns block: duplicate column name 'study'

---

    Code
      read_bad("y012-missing-name.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x Y012 fixtures/specs-bad/y012-missing-name.yaml / columns block: column entry 1 has no name

---

    Code
      read_bad("y017-missing-type.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x Y017 fixtures/specs-bad/y017-missing-type.yaml / column 'extra_notes': missing required field 'type'

---

    Code
      read_bad("y017-missing-source.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x Y017 fixtures/specs-bad/y017-missing-source.yaml / top level: missing required field 'source'

---

    Code
      read_bad("y019-missing-source-file.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x Y019 fixtures/specs-bad/y019-missing-source-file.yaml / source block: missing required field 'file'

---

    Code
      read_bad("y020-empty-field.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x Y020 fixtures/specs-bad/y020-empty-field.yaml / column 'mean_age': field 'range' is declared but has no value

