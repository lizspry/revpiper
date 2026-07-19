# duplicate table names across files flag YX01, snapshotted

    Code
      as.data.frame(check_table_identity(names(dicts), files)$problems)
    Output
                                      file          entry code
      1 estimates-a.yaml, estimates-b.yaml dictionary set YX01
                                                                                  message
      1 duplicate table name 'estimates' — declared by estimates-a.yaml, estimates-b.yaml
        suggestion related
      1       <NA>    <NA>

# zero dictionaries is a standing problem, never vacuous (battery)

    Code
      as.data.frame(record(out, "tables")$problems[-1])
    Output
           entry code                                 message suggestion related
      1 spec set YX05 no dictionaries found in 'specs/tables'       <NA>    <NA>

