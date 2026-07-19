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
    paths$files,
    file.path(
      paths$dir,
      c("tables/estimates.yaml.txt", "tables/rob.yaml.txt", "joins.yaml.txt")
    )
  )
  expect_true(all(file.exists(paths$files)))
})

test_that("reports mirror the spec tree: same-stem inputs never collide (battery)", {
  root <- spec_project("specs-good")
  yml <- file.path(root, "specs", "tables", "estimates.yml")
  writeLines(
    sub(
      "table: estimates",
      "table: estimatez",
      readLines(
        file.path(root, "specs", "tables", "estimates.yaml")
      )
    ),
    yml
  )
  withr::local_dir(root)
  out <- collect_spec_step("specs", joins = FALSE)
  paths <- export_spec_reports(out)
  expect_setequal(
    basename(paths$files),
    c("estimates.yaml.txt", "estimates.yml.txt", "rob.yaml.txt")
  )
  expect_true(all(file.exists(paths$files)))
})

test_that("console pointers survive duplicate record names (review, battery B6)", {
  root <- spec_project("specs-good")
  writeLines(
    c(
      "table: joinsdict",
      "source: {file: x.csv}",
      "columns:",
      "  - {name: a, type: text}"
    ),
    file.path(root, "specs", "tables", "joins.yaml")
  )
  writeLines(
    paste0(
      "joins:\n  - {adds: variables, left: nope, right: rob, ",
      "keys: {nope: [a], rob: [study_id]}, relationship: one-to-many}"
    ),
    file.path(root, "specs", "joins.yaml")
  )
  withr::local_dir(root)
  out <- collect_spec_step("specs")
  out$verb <- "audit"
  out$paths <- export_spec_reports(out)
  lines <- report_lines(out)
  joins_line <- lines$per_file[[length(lines$per_file)]]
  expect_match(joins_line, "spec-[0-9-]+/joins\\.yaml\\.txt")
  expect_no_match(joins_line, "tables/joins\\.yaml\\.txt")
})
