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
    spec_problem(
      "specs/tables/estimates.yaml",
      "column 'mean_age'",
      "YE01",
      "unknown field 'rnge'",
      suggestion = "range"
    ),
    spec_problem(
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
