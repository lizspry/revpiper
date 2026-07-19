test_that("field_schema returns rows for every kind, shaped by properties", {
  props <- schema_properties()
  col <- field_schema("column")
  expect_setequal(names(col), props$property)
  expect_setequal(
    col$field,
    c(
      "name",
      "type",
      "values",
      "range",
      "units",
      "required",
      "unique",
      "missing",
      "constant_within_level",
      "description"
    )
  )
  expect_setequal(
    field_schema("file")$field,
    c("table", "description", "source", "levels", "columns")
  )
  expect_setequal(field_schema("source")$field, c("file", "sheet", "reader"))
  expect_setequal(
    field_schema("level")$field,
    c("keys", "combine", "separator", "within")
  )
  expect_setequal(field_schema("join_file")$field, "joins")
  expect_setequal(
    field_schema("join")$field,
    c("adds", "left", "right", "keys", "relationship", "unmatched_ok")
  )
})

test_that("the kinds list closes the schema's kind vocabulary", {
  kinds <- schema_kinds()
  s <- schema_fields()
  expect_true(all(s$kind %in% kinds))
  expect_true(all(s$contains[!is.na(s$contains)] %in% kinds))
})

test_that("same-named fields across kinds agree unless recorded divergent", {
  # Recorded divergences — same name, deliberately different properties per
  # kind. Input to the amendment 7h fact-home review.
  # - keys: a level's keys are column names; a join's keys map each side to
  #   its column names (same concept, kind-specific shape — amendment 7).
  recorded <- "keys"
  s <- schema_fields()
  shared <- setdiff(unique(s$field[duplicated(s$field)]), recorded)
  for (f in shared) {
    rows <- s[s$field == f, setdiff(names(s), "kind")]
    for (j in seq_len(nrow(rows))[-1]) {
      expect_identical(rows[j, ], rows[1, ], info = f)
    }
  }
})

test_that("schema_types returns the five types from type's inline domain", {
  expect_identical(
    schema_types(),
    c("text", "integer", "decimal", "boolean", "date")
  )
})

test_that("every fields row conforms to the declared properties", {
  props <- schema_properties()
  s <- schema_fields()
  for (i in seq_len(nrow(props))) {
    p <- props[i, ]
    column <- s[[p$property]]
    values <- switch(
      p$type,
      string = column[!is.na(column)],
      boolean = {
        expect_true(
          is.logical(column) && !anyNA(column),
          info = p$property
        )
        NULL
      },
      list_of_strings = unlist(column),
      verbatim = NULL
    )
    allowed <- p$allowed[[1]]
    if (!is.null(allowed) && length(values) > 0) {
      expect_true(all(values %in% allowed), info = p$property)
    }
  }
})

test_that("relational meta-rules hold across schema rows", {
  s <- schema_fields()

  # permitted_types: the sentinel "any", or a subset of the type universe
  expect_true(all(vapply(
    s$permitted_types,
    \(pt) identical(pt, "any") || all(pt %in% schema_types()),
    logical(1)
  )))
  # content_typed and ordered only on type-restricted constraints
  restricted <- !vapply(s$permitted_types, identical, logical(1), "any")
  expect_true(all(restricted[s$content_typed]))
  expect_true(all(restricted[!is.na(s$ordered)]))
  # excludes and requires targets are fields of the same kind, never self
  for (i in seq_len(nrow(s))) {
    siblings <- setdiff(s$field[s$kind == s$kind[i]], s$field[i])
    targets <- s$excludes[[i]]
    if (!is.null(targets)) {
      expect_true(all(targets %in% siblings), info = s$field[i])
    }
    if (!is.na(s$requires[i])) {
      expect_true(s$requires[i] %in% siblings, info = s$field[i])
    }
  }
  # contains only on mapping shapes
  expect_true(all(
    is.na(s$contains) | s$shape %in% c("mapping", "list_of_mappings")
  ))
  # exactly one identity field per scope: table (set), name (file)
  expect_identical(s$field[s$identity], c("table", "name"))
  # domain is inline and lives only on the closed-vocabulary fields
  expect_setequal(
    s$field[!vapply(s$domain, is.null, logical(1))],
    c("type", "adds", "relationship")
  )
  # permitted_adds: the sentinel "any", or a subset of adds' own domain
  adds_domain <- s$domain[[match("adds", s$field)]]
  expect_true(all(vapply(
    s$permitted_adds,
    \(pa) identical(pa, "any") || all(pa %in% adds_domain),
    logical(1)
  )))
})

test_that("the check registry is closed and internally consistent", {
  registry <- check_registry()

  # prefixes agree with declared scopes
  prefix_scope <- c(
    YF = "form",
    YE = "entry",
    YS = "source",
    YX = "cross-source"
  )
  expect_identical(
    unname(prefix_scope[substr(registry$code, 1, 2)]),
    registry$scope
  )
  # every template placeholder is a declared param, and vice versa
  for (i in seq_len(nrow(registry))) {
    found <- regmatches(
      registry$message_template[i],
      gregexpr("\\{([a-z0-9_]+)\\}", registry$message_template[i])
    )[[1]]
    found <- gsub("[{}]", "", found)
    expect_setequal(found, registry$params[[i]])
  }
  # rendering an unregistered code is an internal error
  expect_error(render_message("ZZ99"), "unregistered")
})

test_that("every implemented check code is exercised by a snapshot", {
  snaps <- unlist(lapply(
    list.files(test_path("_snaps"), full.names = TRUE),
    readLines
  ))
  registry <- check_registry()
  for (code in registry$code[registry$implemented]) {
    expect_true(any(grepl(code, snaps, fixed = TRUE)), info = code)
  }
  # and no snapshot exercises a code the registry does not know
  emitted <- regmatches(snaps, gregexpr("Y[FESX][0-9]{2}", snaps))
  expect_true(all(unlist(emitted) %in% registry$code))
})

test_that("checks.yaml holds only the check registry", {
  expect_identical(names(schema_yaml("checks.yaml")), "checks")
})

test_that("every shape x cardinality combination has an enumerated phrase", {
  props <- schema_properties()
  shapes <- props$allowed[[which(props$property == "shape")]]
  cardinalities <- props$allowed[[which(props$property == "cardinality")]]
  for (shape in shapes) {
    entry <- shape_phrases()[[shape]]
    expect_false(is.null(entry), info = shape)
    if (!is.character(entry)) {
      expect_setequal(names(entry), cardinalities)
    }
  }
})
