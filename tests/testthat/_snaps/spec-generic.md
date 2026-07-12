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

