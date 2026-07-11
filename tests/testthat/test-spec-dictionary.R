good_path <- function() {
  test_path("fixtures", "specs-good", "tables", "estimates.yaml")
}

bad_path <- function(fixture) {
  test_path("fixtures", "specs-bad", fixture)
}

test_that("rev_read_dictionary parses a valid dictionary into every slot", {
  dict <- rev_read_dictionary(good_path())

  expect_s3_class(dict, "rev_dictionary")
  expect_equal(dict$table, "estimates")
  expect_equal(dict$description, "One row per extracted estimate.")
  expect_equal(dict$source$file, "data/raw/estimates.csv")
  expect_null(dict$source$sheet)
  expect_null(dict$source$reader)
  expect_equal(dict$roles$study_id, "study")
  expect_equal(dict$levels$study, "study")
  expect_equal(dict$path, good_path())

  cols <- dict$columns
  expect_equal(
    cols$name,
    c("study", "design", "mean_age", "rob_score", "notes_temp")
  )
  expect_equal(cols$type, c("text", "text", "decimal", "integer", "text"))
  expect_true(cols$required[cols$name == "study"])
  expect_false(cols$required[cols$name == "design"])
  expect_false(any(cols$unique))
  expect_equal(cols$values[[2]], c("RCT", "Cohort"))
  expect_equal(cols$values[[4]], c(1L, 2L, 9L))
  expect_null(cols$values[[1]])
  expect_equal(cols$range[[3]], c(10, 60))
  expect_equal(cols$units[3], "years")
  expect_equal(cols$constant_within_level[3], "study")
  expect_equal(cols$missing[[3]], "NR")
  expect_equal(cols$missing[[1]], character(0))
})

test_that("a nonexistent dictionary path aborts with the classed error", {
  expect_error(
    rev_read_dictionary("no/such/dictionary.yaml"),
    class = "revpiper_spec_error"
  )
  expect_snapshot(error = TRUE, rev_read_dictionary("no/such/dictionary.yaml"))
})

test_that("each single-defect dictionary aborts naming its problem", {
  read_bad <- function(fixture) rev_read_dictionary(bad_path(fixture))

  expect_snapshot(error = TRUE, read_bad("y001-top-level.yaml"))
  expect_snapshot(error = TRUE, read_bad("y001-column-field.yaml"))
  expect_snapshot(error = TRUE, read_bad("y002-bad-type.yaml"))
  expect_snapshot(error = TRUE, read_bad("y003-values-and-range.yaml"))
  expect_snapshot(error = TRUE, read_bad("y004-values-on-date.yaml"))
  expect_snapshot(error = TRUE, read_bad("y005-range-on-text.yaml"))
  expect_snapshot(error = TRUE, read_bad("y006-units-on-text.yaml"))
  expect_snapshot(error = TRUE, read_bad("y007-mixed-values.yaml"))
  expect_snapshot(error = TRUE, read_bad("y007-date-range-not-iso.yaml"))
  expect_snapshot(error = TRUE, read_bad("y008-descending-range.yaml"))
  expect_snapshot(error = TRUE, read_bad("y008-descending-date-range.yaml"))
  expect_snapshot(error = TRUE, read_bad("y012-duplicate-column.yaml"))
  expect_snapshot(error = TRUE, read_bad("y012-missing-name.yaml"))
  expect_snapshot(error = TRUE, read_bad("y017-missing-type.yaml"))
  expect_snapshot(error = TRUE, read_bad("y017-missing-source.yaml"))
  expect_snapshot(error = TRUE, read_bad("y019-missing-source-file.yaml"))
  expect_snapshot(error = TRUE, read_bad("y020-empty-field.yaml"))
})

test_that("every problem in a broken dictionary is reported at once", {
  err <- tryCatch(
    rev_read_dictionary(bad_path("many-defects.yaml")),
    error = \(e) e
  )
  expect_s3_class(err, "revpiper_spec_error")
  expect_snapshot(
    error = TRUE,
    rev_read_dictionary(bad_path("many-defects.yaml"))
  )
})
