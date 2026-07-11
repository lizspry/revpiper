schema_properties <- c(
  "field",
  "level",
  "required",
  "shape",
  "cardinality",
  "empty_ok",
  "domain",
  "permitted_types",
  "excludes",
  "content_typed",
  "ordered",
  "unique_entries",
  "refers_to",
  "identity",
  "default"
)

test_that("field_schema returns complete rows for every level", {
  col <- field_schema("column")
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
  expect_setequal(names(col), schema_properties)
})

test_that("schema_types returns the five types from type's inline domain", {
  expect_identical(
    schema_types(),
    c("text", "integer", "decimal", "boolean", "date")
  )
})

test_that("the schema validates against its own closed vocabulary", {
  s <- the_schema()

  expect_true(all(
    unlist(s$level) %in% c("top", "source", "column", "combine")
  ))
  expect_true(all(
    s$shape %in%
      c("string", "boolean", "scalar", "block", "named_list", "list_of_blocks")
  ))
  expect_true(all(s$cardinality %in% c("one", "one_or_many", "two")))
  expect_true(is.logical(s$required) && !anyNA(s$required))
  expect_true(is.logical(s$empty_ok) && !anyNA(s$empty_ok))
  expect_true(is.logical(s$content_typed) && !anyNA(s$content_typed))
  expect_true(is.logical(s$unique_entries) && !anyNA(s$unique_entries))
  expect_true(is.logical(s$identity) && !anyNA(s$identity))
  expect_true(all(is.na(s$ordered) | s$ordered == "ascending"))
  expect_true(all(is.na(s$refers_to) | s$refers_to %in% c("columns", "levels")))

  # permitted_types: the sentinel "any", or a subset of the type universe
  expect_true(all(vapply(
    s$permitted_types,
    \(pt) identical(pt, "any") || all(unlist(pt) %in% schema_types()),
    logical(1)
  )))
  # content_typed and ordered only make sense on type-restricted constraints
  restricted <- !vapply(s$permitted_types, identical, logical(1), "any")
  expect_true(all(restricted[s$content_typed]))
  expect_true(all(restricted[!is.na(s$ordered)]))
  # excludes targets are fields that exist and share a level
  for (i in seq_len(nrow(s))) {
    targets <- s$excludes[[i]]
    if (!is.null(targets)) {
      expect_true(all(targets %in% s$field))
    }
  }
  # exactly one identity field per scope: table (set), name (file)
  expect_identical(s$field[s$identity], c("table", "name"))
  # domain is inline and lives only on type
  expect_identical(s$field[!vapply(s$domain, is.null, logical(1))], "type")
})
