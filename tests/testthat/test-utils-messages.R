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

test_that("problems carry a related column, NA by default", {
  p <- new_problem("f.yaml", "column entry 1", "YE01", "unknown field 'x'")
  expect_named(
    p,
    c("file", "entry", "code", "message", "suggestion", "related")
  )
  expect_identical(p$related, NA_character_)
  expect_identical(
    new_problem(
      "f",
      "e",
      "C",
      "m",
      related = "other error in this entry"
    )$related,
    "other error in this entry"
  )
  expect_identical(nrow(no_problems()), 0L)
  expect_true("related" %in% names(no_problems()))
})

test_that("relate_same_entry links co-located errors deterministically", {
  p <- rbind(
    new_problem("a.yaml", "column entry 4", "YE01", "unknown field 'nam'"),
    new_problem("a.yaml", "column entry 4", "YE02", "field 'name' missing"),
    new_problem("a.yaml", "column entry 2", "YF01", "empty")
  )
  out <- relate_same_entry(p)
  expect_identical(
    out$related,
    c("other error in this entry", "other error in this entry", NA)
  )
  # already-set related (rule 2 is more specific) is never overwritten
  p$related[1] <- "spec file b.yaml has standing errors"
  expect_identical(
    relate_same_entry(p)$related[1],
    "spec file b.yaml has standing errors"
  )
  # zero-row input passes through
  expect_identical(nrow(relate_same_entry(no_problems())), 0L)
})
