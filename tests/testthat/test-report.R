one_item <- function() {
  new_problem(
    "specs/tables/estimates.yaml",
    "column 'mean_age'",
    "YF03",
    "type 'decimals' is not a known type",
    suggestion = "decimal"
  )
}

test_that("a stage report certifies exactly at zero standing items", {
  certified <- new_stage_report("spec", no_problems())
  expect_s3_class(certified, "rev_report")
  expect_true(is_certified(certified))
  expect_false(is_certified(new_stage_report("spec", one_item())))
})

test_that("the certificate renders both statuses", {
  expect_snapshot(print(new_stage_report("spec", no_problems())))
  expect_snapshot(print(new_stage_report("spec", one_item())))
})

# The annex is caller-supplied text rendered verbatim: these lines are
# deliberately fake — the real certificate content is composed by each
# step's audit and snapshot-tested there (test-spec-audit.R).
test_that("annex lines render verbatim after the standing count", {
  report <- new_stage_report(
    "spec",
    no_problems(),
    annex = c("first stage-specific annex line", "second one, verbatim")
  )
  expect_snapshot(print(report))
})

test_that("printing returns the report invisibly", {
  report <- new_stage_report("spec", no_problems())
  expect_invisible(print(report))
})

test_that("export_report writes the report and certificate files", {
  dir <- file.path(tempfile(), "output", "reports")
  on.exit(unlink(dirname(dirname(dir)), recursive = TRUE))
  report <- new_stage_report("spec", one_item())
  paths <- export_report(report, dir)
  expect_named(paths, c("report", "certificate"))
  expect_true(all(file.exists(paths)))
  expect_match(basename(paths[["report"]]), "^spec-\\d{8}-\\d{6}\\.xlsx$")
  expect_match(
    basename(paths[["certificate"]]),
    "^spec-\\d{8}-\\d{6}-certificate\\.txt$"
  )
  expect_identical(readLines(paths[["certificate"]]), format(report))
})

test_that("export_report returns its paths invisibly", {
  report <- new_stage_report("spec", no_problems())
  expect_invisible(export_report(report, tempfile()))
})
