# Copy a fixture spec folder into a fresh temp project as <project>/specs.
# Callers setwd() to the returned root (the audit writes output/reports
# relative to the project) and restore via on.exit.
spec_project <- function(fixture) {
  root <- tempfile("project")
  dir.create(root)
  file.copy(test_path("fixtures", fixture), root, recursive = TRUE)
  file.rename(file.path(root, fixture), file.path(root, "specs"))
  root
}

# Runstamps make report paths nondeterministic; scrub them in snapshots.
scrub_runstamp <- function(lines) {
  gsub("[0-9]{8}-[0-9]{6}", "<runstamp>", lines)
}

test_that("a clean spec set audits CERTIFIED, data-free, files written", {
  old <- setwd(spec_project("specs-good"))
  on.exit(setwd(old))
  expect_false(dir.exists("data")) # no data anywhere: the audit is data-free
  report <- suppressMessages(rev_spec_audit())
  expect_s3_class(report, "rev_report")
  expect_true(is_certified(report))
  specs <- attr(report, "specs")
  expect_named(specs, c("tables", "joins"))
  expect_named(specs$tables, c("estimates", "rob"))
  written <- list.files("output/reports")
  expect_length(written, 2)
  expect_match(written, "^spec-", all = TRUE)
})

test_that("the audit returns the report visibly", {
  old <- setwd(spec_project("specs-good"))
  on.exit(setwd(old))
  expect_visible(suppressMessages(rev_spec_audit()))
})

test_that("the certified audit: status line and certificate", {
  old <- setwd(spec_project("specs-good"))
  on.exit(setwd(old))
  expect_snapshot(print(rev_spec_audit()), transform = scrub_runstamp)
})

test_that("problems accumulate across every broken dictionary", {
  root <- spec_project("specs-good")
  file.copy(
    test_path("fixtures", "specs-bad", "ys01-duplicate-column.yaml"),
    file.path(root, "specs", "tables")
  )
  file.copy(
    test_path("fixtures", "specs-bad", "ye02-missing-type.yaml"),
    file.path(root, "specs", "tables")
  )
  old <- setwd(root)
  on.exit(setwd(old))
  report <- suppressMessages(rev_spec_audit())
  expect_false(is_certified(report))
  expect_null(attr(report, "specs"))
  # Both files' codes present: neither abort stopped the audit.
  expect_true(all(c("YS01", "YE02") %in% report$items$code))
  expect_length(list.files("output/reports"), 2)
})

test_that("the not-certified audit: status line and certificate", {
  root <- spec_project("specs-good")
  file.copy(
    test_path("fixtures", "specs-bad", "ye02-missing-type.yaml"),
    file.path(root, "specs", "tables")
  )
  old <- setwd(root)
  on.exit(setwd(old))
  expect_snapshot(print(rev_spec_audit()), transform = scrub_runstamp)
})

test_that("joins = FALSE audits without the joins spec and says so", {
  old <- setwd(spec_project("specs-good"))
  on.exit(setwd(old))
  report <- suppressMessages(rev_spec_audit(joins = FALSE))
  expect_true(is_certified(report))
  expect_match(format(report), "excluded", all = FALSE)
  expect_identical(nrow(attr(report, "specs")$joins), 0L)
})

test_that("joins expected but absent is a standing item, not an error", {
  old <- setwd(spec_project("specs-nojoins"))
  on.exit(setwd(old))
  report <- suppressMessages(rev_spec_audit())
  expect_false(is_certified(report))
  expect_identical(report$items$code, "YX04")
  expect_match(format(report), "expected but absent", all = FALSE)
  expect_snapshot(as.data.frame(report$items[, c("code", "message")]))
})
