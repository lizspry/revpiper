test_that("field_schema returns rows for every level, shaped by properties", {
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
    field_schema("top")$field,
    c("table", "description", "source", "roles", "levels", "columns")
  )
  expect_setequal(field_schema("source")$field, c("file", "sheet", "reader"))
  expect_setequal(field_schema("combine")$field, c("combine", "separator"))
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
  # excludes targets are fields that exist
  for (targets in s$excludes) {
    if (!is.null(targets)) {
      expect_true(all(targets %in% s$field))
    }
  }
  # context only on mapping shapes
  expect_true(all(
    is.na(s$context) | s$shape %in% c("mapping", "list_of_mappings")
  ))
  # exactly one identity field per scope: table (set), name (file)
  expect_identical(s$field[s$identity], c("table", "name"))
  # domain is inline and lives only on type
  expect_identical(s$field[!vapply(s$domain, is.null, logical(1))], "type")
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
  snaps <- readLines(test_path("_snaps", "spec-dictionary.md"))
  registry <- check_registry()
  for (code in registry$code[registry$implemented]) {
    expect_true(any(grepl(code, snaps, fixed = TRUE)), info = code)
  }
  # and no snapshot exercises a code the registry does not know
  emitted <- regmatches(snaps, gregexpr("Y[FESX][0-9]{2}", snaps))
  expect_true(all(unlist(emitted) %in% registry$code))
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
