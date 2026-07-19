test_that("certified reports: status, summary, no errors", {
  root <- spec_project("specs-good")
  out <- collect_spec_step(file.path(root, "specs"))
  expect_snapshot(writeLines(format_file_report(record(out, "estimates.yaml"))))
  expect_snapshot(writeLines(format_file_report(record(out, "joins.yaml"))))
})

test_that("uncertified report: error table only, aligned per contents", {
  root <- spec_project("specs-good")
  break_file(root, "estimates.yaml")
  out <- collect_spec_step(file.path(root, "specs"))
  lines <- format_file_report(record(out, "estimates.yaml"))
  expect_snapshot(writeLines(lines))
  header <- grep("^entry", lines, value = TRUE)
  expect_identical(substr(header, 1, 5), "entry")
})

test_that("export writes one txt per input file in a per-run folder", {
  withr::local_dir(spec_project("specs-good"))
  out <- collect_spec_step("specs")
  paths <- export_spec_reports(out)
  expect_true(dir.exists(paths$dir))
  expect_match(paths$dir, "^output/reports/spec-\\d{8}-\\d{6}$")
  expect_setequal(
    basename(paths$files),
    c("estimates.txt", "rob.txt", "joins.txt")
  )
  expect_true(all(file.exists(paths$files)))
})
