# duplicate table names across files flag YX01, snapshotted

    Code
      as.data.frame(check_table_identity(names(dicts), files))
    Output
                                      file          entry code
      1 estimates-a.yaml, estimates-b.yaml dictionary set YX01
                                 message suggestion related
      1 duplicate table name 'estimates'       <NA>    <NA>

