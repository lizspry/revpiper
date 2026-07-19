test_that("audit prints per-file certification, returns invisibly, specs stripped", {
  root <- spec_project("specs-good")
  break_file(root, "estimates.yaml")
  withr::local_dir(root)
  expect_snapshot(out <- rev_spec_audit("specs"), transform = scrub_runstamp)
  expect_s3_class(out, "rev_report")
  expect_identical(out$verb, "audit")
  expect_false(out$certified)
  expect_null(out$specs)
  expect_invisible(suppressMessages(rev_spec_audit("specs")))
})

test_that("audit success: reports written, specs still not returned", {
  root <- spec_project("specs-good")
  withr::local_dir(root)
  expect_snapshot(out <- rev_spec_audit("specs"), transform = scrub_runstamp)
  expect_true(out$certified)
  expect_null(out$specs)
  written <- list.files("output/reports", recursive = TRUE)
  expect_setequal(
    basename(written),
    c("estimates.yaml.txt", "rob.yaml.txt", "joins.yaml.txt")
  )
})

test_that("printing the returned outcome repeats the console lines", {
  root <- spec_project("specs-good")
  withr::local_dir(root)
  out <- suppressMessages(rev_spec_audit("specs"))
  expect_snapshot(print(out), transform = scrub_runstamp)
})

test_that("an expected-but-absent joins spec decertifies via YX04", {
  root <- spec_project("specs-good")
  unlink(file.path(root, "specs", "joins.yaml"))
  withr::local_dir(root)
  out <- suppressMessages(rev_spec_audit("specs"))
  expect_false(out$certified)
  expect_identical(record(out, "joins.yaml")$problems$code, "YX04")
  expect_snapshot(as.data.frame(record(out, "joins.yaml")$problems))
  out2 <- suppressMessages(rev_spec_audit("specs", joins = FALSE))
  expect_true(out2$certified)
})

test_that("the audit is data-free: certifies before any data exists", {
  root <- spec_project("specs-good")
  withr::local_dir(root)
  expect_false(dir.exists("data"))
  out <- suppressMessages(rev_spec_audit("specs"))
  expect_true(out$certified)
})

test_that("joins = FALSE is stated wherever the summary appears (review)", {
  root <- spec_project("specs-good")
  withr::local_dir(root)
  expect_snapshot(
    out <- rev_spec_audit("specs", joins = FALSE),
    transform = scrub_runstamp
  )
  report <- readLines(out$paths$files[["estimates.yaml"]])
  expect_true(
    "joins excluded (joins = FALSE) and therefore not audited/run" %in% report
  )
  expect_snapshot(print(out), transform = scrub_runstamp)
})

test_that("filenames with braces never crash the console (review)", {
  root <- spec_project("specs-good")
  file.rename(
    file.path(root, "specs", "tables", "rob.yaml"),
    file.path(root, "specs", "tables", "rob{1}.yaml")
  )
  withr::local_dir(root)
  expect_no_error(out <- suppressMessages(rev_spec_audit("specs")))
  expect_true(out$certified)
})
