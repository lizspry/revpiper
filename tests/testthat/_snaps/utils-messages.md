# stop_spec reports every problem with file, entry, and code

    Code
      stop_spec(p)
    Condition
      Error:
      ! Spec validation failed (2 problems):
      x Y001 specs/tables/estimates.yaml / column 'mean_age': unknown field 'rnge' (did you mean 'range'?)
      x Y014 specs/joins.yaml / join 1: unknown table 'robb' (did you mean 'rob'?)

