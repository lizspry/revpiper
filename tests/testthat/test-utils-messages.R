test_that("suggest_name finds near misses and refuses far ones", {
  expect_equal(
    suggest_name("descrption", c("description", "type")),
    "description"
  )
  expect_equal(suggest_name("VALUES", c("values", "range")), "values")
  expect_identical(
    suggest_name("zebra", c("description", "type")),
    NA_character_
  )
})

test_that("stop_spec reports every problem with file, entry, and code", {
  p <- rbind(
    new_problem(
      "specs/tables/estimates.yaml",
      "column 'mean_age'",
      "YE01",
      "unknown field 'rnge'",
      suggestion = "range"
    ),
    new_problem(
      "specs/joins.yaml",
      "join 1",
      "YX02",
      "unknown table 'robb'",
      suggestion = "rob"
    )
  )
  expect_error(stop_spec(p), class = "revpiper_spec_error")
  expect_snapshot(error = TRUE, stop_spec(p))
})

# The footer's promise must not go silently stale: system.file returns ""
# for a missing path rather than erroring, so a rename of the packaged
# examples would otherwise break the pointer without failing anything.
test_that("the canonical examples the spec-error footer points to exist", {
  path <- system.file("extdata", "specs-example", package = "revpiper")
  expect_true(nzchar(path))
  expect_true(file.exists(file.path(path, "joins.yaml")))
  expect_gt(length(list.files(file.path(path, "tables"))), 0)
})
