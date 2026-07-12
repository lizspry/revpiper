specs_path <- function(dir) {
  test_path("fixtures", dir)
}

test_that("rev_spec_run() reads the whole spec set with joins by default", {
  specs <- rev_spec_run(specs_path("specs-good"))
  expect_named(specs, c("tables", "joins"))
  expect_named(specs$tables, c("estimates", "rob"))
  for (dict in specs$tables) {
    expect_s3_class(dict, "rev_dictionary")
  }
  expect_gt(nrow(specs$joins), 0)
})

test_that("rev_spec_run(joins = FALSE) skips an available joins spec", {
  specs <- rev_spec_run(specs_path("specs-good"), joins = FALSE)
  expect_named(specs$tables, c("estimates", "rob"))
  expect_identical(nrow(specs$joins), 0L)
})

test_that("rev_spec_run(joins = TRUE) errors when no joins spec exists", {
  expect_snapshot(
    rev_spec_run(specs_path("specs-nojoins")),
    error = TRUE
  )
})

test_that("rev_spec_run(file =) runs one dictionary standalone", {
  specs <- rev_spec_run(specs_path("specs-good"), file = "estimates.yaml")
  expect_named(specs, c("tables", "joins"))
  expect_named(specs$tables, "estimates")
  expect_s3_class(specs$tables$estimates, "rev_dictionary")
  expect_identical(nrow(specs$joins), 0L)
})

test_that("rev_spec_run(file = 'joins.yaml') runs within-file checks only", {
  # This joins fixture names a table no dictionary declares: reference
  # resolution would reject it, so succeeding proves within-file scope.
  specs <- rev_spec_run(specs_path("specs-joins-only"), file = "joins.yaml")
  expect_length(specs$tables, 0)
  expect_gt(nrow(specs$joins), 0)
})

test_that("rev_spec_run() rejects a path where a filename is expected", {
  expect_snapshot(
    rev_spec_run(specs_path("specs-good"), file = "tables/estimates.yaml"),
    error = TRUE
  )
})

test_that("rev_spec_run() aborts with the problems of a broken dictionary", {
  problems <- spec_problems(
    rev_spec_run(specs_path("specs-run-bad"), joins = FALSE)
  )
  expect_identical(spec_codes(problems), "YS01")
})
