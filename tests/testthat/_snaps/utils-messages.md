# stop_spec reports every problem with file, entry, and code

    Code
      stop_spec(p)
    Condition
      Error:
      ! Spec validation failed (2 problems):
      x YE01 specs/tables/estimates.yaml / column 'mean_age': unknown field 'rnge' (did you mean 'range'?)
      x YX02 specs/joins.yaml / join 1: unknown table 'robb' (did you mean 'rob'?)
      i Canonical spec examples ship with the package: `system.file("extdata", "specs-example", package = "revpiper")`

