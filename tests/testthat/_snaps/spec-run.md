# rev_spec_run(joins = TRUE) errors when no joins spec exists

    Code
      rev_spec_run(specs_path("specs-nojoins"))
    Condition
      Error:
      ! `joins` is TRUE but 'fixtures/specs-nojoins/joins.yaml' does not exist.
      i Set `joins = FALSE` to run a spec set without joins.
      i Canonical spec examples ship with the package: `system.file("extdata", "specs-example", package = "revpiper")`

# rev_spec_run() rejects a path where a filename is expected

    Code
      rev_spec_run(specs_path("specs-good"), file = "tables/estimates.yaml")
    Condition
      Error:
      ! `file` must be a filename, not a path.
      i Dictionary filenames resolve in 'fixtures/specs-good/tables'.
      i Canonical spec examples ship with the package: `system.file("extdata", "specs-example", package = "revpiper")`

