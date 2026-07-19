# a nonexistent dictionary path aborts with the classed error

    Code
      read_dictionary("no/such/dictionary.yaml")
    Condition
      Error:
      ! Dictionary file 'no/such/dictionary.yaml' does not exist.
      i See `?rev_spec_run` for the expected spec layout, with correctly formatted examples.

# each single-defect dictionary aborts naming its problem

    Code
      read_bad("ye01-file-entry.yaml")
    Output
             entry code                    message  suggestion related
      1 file entry YE01 unknown field 'descrption' description    <NA>

---

    Code
      read_bad("ye02-missing-type.yaml")
    Output
                       entry code                       message suggestion related
      1 column 'extra_notes' YE02 missing required field 'type'       <NA>    <NA>

---

    Code
      read_bad("ye03-range-on-text.yaml")
    Output
                      entry code                               message suggestion
      1 column 'notes_temp' YE03 'range' is not allowed on type 'text'       <NA>
        related
      1    <NA>

---

    Code
      read_bad("ye04-values-and-range.yaml")
    Output
                    entry code                                     message suggestion
      1 column 'mean_age' YE04 'range' and 'values' are mutually exclusive       <NA>
        related
      1    <NA>

---

    Code
      read_bad("ye05-mixed-values.yaml")
    Output
                     entry code                                               message
      1 column 'rob_score' YE05 'values' entries do not match declared type 'integer'
        suggestion related
      1       <NA>    <NA>

---

    Code
      read_bad("ye05-date-range-not-iso.yaml")
    Output
                           entry code
      1 column 'extraction_date' YE05
                                                  message suggestion related
      1 'range' entries do not match declared type 'date'       <NA>    <NA>

---

    Code
      read_bad("yf01-empty-field.yaml")
    Output
                    entry code                                    message suggestion
      1 column 'mean_age' YF01 field 'range' is declared but has no value       <NA>
        related
      1    <NA>

---

    Code
      read_bad("yf02-name-list.yaml")
    Output
                 entry code                                  message suggestion
      1 column entry 1 YF02 field 'name' must be a single text value       <NA>
        related
      1    <NA>

---

    Code
      read_bad("yf03-bad-type.yaml")
    Output
                    entry code               message suggestion related
      1 column 'mean_age' YF03 unknown type 'decmal'    decimal    <NA>

---

    Code
      read_bad("yf04-duplicate-values.yaml")
    Output
                  entry code                                     message suggestion
      1 column 'design' YF04 field 'values' has duplicate entries: 'RCT'       <NA>
        related
      1    <NA>

---

    Code
      read_bad("yf05-descending-range.yaml")
    Output
                    entry code                         message suggestion related
      1 column 'mean_age' YF05 'range' is descending (60 > 10)       <NA>    <NA>

---

    Code
      read_bad("ys01-duplicate-column.yaml")
    Output
                  entry code                       message suggestion related
      1 columns section YS01 duplicate column name 'study'       <NA>    <NA>

---

    Code
      read_bad("ye06-level-number.yaml")
    Output
                 entry code
      1 levels section YE06
                                                                             message
      1 level 'study_id' must be a column name or a mapping with 'keys' or 'combine'
        suggestion related
      1       <NA>    <NA>

---

    Code
      read_bad("ye07-separator-without-combine.yaml")
    Output
                entry code                        message suggestion related
      1 level 'study' YE07 'separator' requires 'combine'       <NA>    <NA>

---

    Code
      read_bad("ys02-key-unknown-column.yaml")
    Output
                entry code                                                message
      1 level 'study' YS02 'studyy' does not name one of the declared key columns
        suggestion related
      1      study    <NA>

---

    Code
      read_bad("ys02-combine-part-unknown.yaml")
    Output
                   entry code                                            message
      1 level 'study_id' YS02 'studdy' does not name one of the declared columns
        suggestion related
      1      study    <NA>

---

    Code
      read_bad("ys02-cwl-unknown-level.yaml")
    Output
                    entry code                                         message
      1 column 'mean_age' YS02 'wave' does not name one of the declared levels
        suggestion related
      1       <NA>    <NA>

---

    Code
      read_bad("ys02-within-unknown-level.yaml")
    Output
                   entry code                                          message
      1 level 'substudy' YS02 'study' does not name one of the declared levels
        suggestion related
      1       <NA>    <NA>

---

    Code
      read_bad("ys04-within-cycle.yaml")
    Output
                 entry code
      1 levels section YS04
                                                            message suggestion
      1 level nesting is circular: 'study' -> 'substudy' -> 'study'       <NA>
        related
      1    <NA>

---

    Code
      read_bad("yf04-duplicate-combine-parts.yaml")
    Output
                   entry code                                        message
      1 level 'study_id' YF04 field 'combine' has duplicate entries: 'study'
        suggestion related
      1       <NA>    <NA>

# every problem in a broken dictionary is reported at once

    Code
      as.data.frame(spec_problems(read_dictionary(bad_path("many-defects.yaml"))))
    Output
                                        file              entry code
      1 fixtures/specs-bad/many-defects.yaml         file entry YE01
      2 fixtures/specs-bad/many-defects.yaml  column 'mean_age' YF03
      3 fixtures/specs-bad/many-defects.yaml column 'rob_score' YF05
                              message  suggestion related
      1    unknown field 'descrption' description    <NA>
      2         unknown type 'decmal'     decimal    <NA>
      3 'range' is descending (9 > 1)        <NA>    <NA>

# a file that does not parse reports a spec problem, not rawly

    Code
      as.data.frame(problems)
    Output
                                            file      entry code
      1 fixtures/specs-bad/ys05-unparseable.yaml file entry YS05
                                                                                                                              message
      1 the file couldn't be processed as there is a YAML error: (fixtures/specs-bad/ys05-unparseable.yaml) Duplicate map key: 'type'
        suggestion related
      1       <NA>    <NA>

# a combine level may not collide with a declared column

    Code
      as.data.frame(spec_problems(read_dictionary(bad_path(
        "ys06-virtual-collision.yaml"))))
    Output
                                                  file         entry code
      1 fixtures/specs-bad/ys06-virtual-collision.yaml level 'study' YS06
                                                                                               message
      1 the combine level 'study' would create a virtual column named like the declared column 'study'
        suggestion related
      1       <NA>    <NA>

