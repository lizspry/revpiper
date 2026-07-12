# duplicate table names across files flag YX01

    Code
      rev_read_dictionaries(bad_path("yx01-duplicate-table"))
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x YX01 estimates-a.yaml, estimates-b.yaml / dictionary set: duplicate table name 'estimates'

# a nonexistent dictionary path aborts with the classed error

    Code
      rev_read_dictionary("no/such/dictionary.yaml")
    Condition
      Error:
      ! Dictionary file 'no/such/dictionary.yaml' does not exist.

# each single-defect dictionary aborts naming its problem

    Code
      read_bad("ye01-file-entry.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x YE01 fixtures/specs-bad/ye01-file-entry.yaml / file entry: unknown field 'descrption' (did you mean 'description'?)

---

    Code
      read_bad("ye02-missing-type.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x YE02 fixtures/specs-bad/ye02-missing-type.yaml / column 'extra_notes': missing required field 'type'

---

    Code
      read_bad("ye03-range-on-text.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x YE03 fixtures/specs-bad/ye03-range-on-text.yaml / column 'notes_temp': 'range' is not allowed on type 'text'

---

    Code
      read_bad("ye04-values-and-range.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x YE04 fixtures/specs-bad/ye04-values-and-range.yaml / column 'mean_age': 'range' and 'values' are mutually exclusive

---

    Code
      read_bad("ye05-mixed-values.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x YE05 fixtures/specs-bad/ye05-mixed-values.yaml / column 'rob_score': 'values' entries do not match declared type 'integer'

---

    Code
      read_bad("ye05-date-range-not-iso.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x YE05 fixtures/specs-bad/ye05-date-range-not-iso.yaml / column 'extraction_date': 'range' entries do not match declared type 'date'

---

    Code
      read_bad("yf01-empty-field.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x YF01 fixtures/specs-bad/yf01-empty-field.yaml / column 'mean_age': field 'range' is declared but has no value

---

    Code
      read_bad("yf02-name-list.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x YF02 fixtures/specs-bad/yf02-name-list.yaml / column entry 1: field 'name' must be a single text value

---

    Code
      read_bad("yf03-bad-type.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x YF03 fixtures/specs-bad/yf03-bad-type.yaml / column 'mean_age': unknown type 'decmal' (did you mean 'decimal'?)

---

    Code
      read_bad("yf04-duplicate-values.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x YF04 fixtures/specs-bad/yf04-duplicate-values.yaml / column 'design': field 'values' has duplicate entries: 'RCT'

---

    Code
      read_bad("yf05-descending-range.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x YF05 fixtures/specs-bad/yf05-descending-range.yaml / column 'mean_age': 'range' is descending (60 > 10)

---

    Code
      read_bad("ys01-duplicate-column.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x YS01 fixtures/specs-bad/ys01-duplicate-column.yaml / columns section: duplicate column name 'study'

---

    Code
      read_bad("ye06-level-number.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x YE06 fixtures/specs-bad/ye06-level-number.yaml / levels section: level 'study_id' must be a column name or a mapping with 'keys' or 'combine'

---

    Code
      read_bad("ye07-separator-without-combine.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x YE07 fixtures/specs-bad/ye07-separator-without-combine.yaml / level 'study': 'separator' requires 'combine'

---

    Code
      read_bad("ys02-key-unknown-column.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x YS02 fixtures/specs-bad/ys02-key-unknown-column.yaml / level 'study': 'studyy' does not name one of the declared key columns (did you mean 'study'?)

---

    Code
      read_bad("ys02-combine-part-unknown.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x YS02 fixtures/specs-bad/ys02-combine-part-unknown.yaml / level 'study_id': 'studdy' does not name one of the declared columns (did you mean 'study'?)

---

    Code
      read_bad("ys02-cwl-unknown-level.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x YS02 fixtures/specs-bad/ys02-cwl-unknown-level.yaml / column 'mean_age': 'wave' does not name one of the declared levels

---

    Code
      read_bad("ys02-within-unknown-level.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x YS02 fixtures/specs-bad/ys02-within-unknown-level.yaml / level 'substudy': 'study' does not name one of the declared levels

---

    Code
      read_bad("ys04-within-cycle.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x YS04 fixtures/specs-bad/ys04-within-cycle.yaml / levels section: level nesting is circular: 'study' -> 'substudy' -> 'study'

---

    Code
      read_bad("yf04-duplicate-combine-parts.yaml")
    Condition
      Error:
      ! Spec validation failed (1 problem):
      x YF04 fixtures/specs-bad/yf04-duplicate-combine-parts.yaml / level 'study_id': field 'combine' has duplicate entries: 'study'

# every problem in a broken dictionary is reported at once

    Code
      rev_read_dictionary(bad_path("many-defects.yaml"))
    Condition
      Error:
      ! Spec validation failed (3 problems):
      x YE01 fixtures/specs-bad/many-defects.yaml / file entry: unknown field 'descrption' (did you mean 'description'?)
      x YF03 fixtures/specs-bad/many-defects.yaml / column 'mean_age': unknown type 'decmal' (did you mean 'decimal'?)
      x YF05 fixtures/specs-bad/many-defects.yaml / column 'rob_score': 'range' is descending (9 > 1)

# shape_phrase wording is grammatical for every shape x cardinality

    Code
      for (shape in c("string", "boolean", "scalar")) {
        for (cardinality in c("one", "one_or_many", "two")) {
          cat(sprintf("%-8s %-12s -> %s\n", shape, cardinality, shape_phrase(shape,
            cardinality)))
        }
      }
    Output
      string   one          -> a single text value
      string   one_or_many  -> one or more text values
      string   two          -> exactly two text values
      boolean  one          -> a single true/false value
      boolean  one_or_many  -> one or more true/false values
      boolean  two          -> exactly two true/false values
      scalar   one          -> a single value
      scalar   one_or_many  -> one or more values
      scalar   two          -> exactly two values
    Code
      for (shape in c("mapping", "list_of_mappings")) {
        cat(sprintf("%-21s -> %s\n", shape, shape_phrase(shape, "one")))
      }
    Output
      mapping               -> a group of key: value fields
      list_of_mappings      -> a list of entries

