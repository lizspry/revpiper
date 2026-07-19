write_spec_file <- function(path, lines) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path)
}

new_spec_sandbox <- function() {
  root <- file.path(tempdir(), paste0("revpiper-spec-test-", as.integer(Sys.time()), "-", sample.int(1000000, 1)))
  dir.create(file.path(root, "specs", "tables"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(root, "work"), recursive = TRUE, showWarnings = FALSE)
  root
}

capture_stdout <- function(expr) {
  expr <- substitute(expr)
  output <- character()
  value <- NULL
  visible <- NULL
  error <- NULL

  output <- capture.output(
    tryCatch({
      result <- withVisible(eval(expr, envir = parent.frame()))
      value <- result$value
      visible <- result$visible
    }, error = function(err) {
      error <<- err
    }),
    type = "output"
  )

  list(output = output, value = value, visible = visible, error = error)
}

latest_report_dir <- function(work_dir) {
  report_root <- file.path(work_dir, "output", "reports")
  expect_true(dir.exists(report_root))
  dirs <- list.dirs(report_root, full.names = TRUE, recursive = FALSE)
  expect_true(length(dirs) >= 1)
  dirs[order(file.info(dirs)$mtime)][[length(dirs)]]
}

report_text <- function(report_dir, name) {
  path <- file.path(report_dir, name)
  expect_true(file.exists(path), info = paste("Missing report", path))
  paste(readLines(path, warn = FALSE), collapse = "\n")
}

with_work_dir <- function(work_dir, code) {
  old <- setwd(work_dir)
  on.exit(setwd(old), add = TRUE)
  force(code)
}

test_that("missing joins is a standing error by default but not when joins is FALSE", {
  root <- new_spec_sandbox()
  specs_dir <- file.path(root, "specs")
  work_dir <- file.path(root, "work")

  write_spec_file(file.path(specs_dir, "tables", "estimates.yaml"), c(
    "table: estimates",
    "description: One row per extracted estimate.",
    "source:",
    "  file: data/raw/estimates.csv",
    "levels:",
    "  study: study",
    "columns:",
    "  - name: study",
    "    type: text",
    "    required: true"
  ))

  with_work_dir(work_dir, {
    audit_default <- capture_stdout(rev_spec_audit(dir = specs_dir))
    expect_null(audit_default$error)
    expect_false(isTRUE(audit_default$value$certified))

    run_default <- capture_stdout(rev_spec_run(dir = specs_dir))
    expect_null(run_default$value)
    expect_false(is.null(run_default$error))
    expect_match(conditionMessage(run_default$error), "spec set not certified and not returned\\.")
    expect_false(is.null(run_default$error$outcome))

    audit_skip <- capture_stdout(rev_spec_audit(dir = specs_dir, joins = FALSE))
    expect_null(audit_skip$error)
    expect_true(isTRUE(audit_skip$value$certified))

    run_skip <- capture_stdout(rev_spec_run(dir = specs_dir, joins = FALSE))
    expect_null(run_skip$error)
    expect_false(run_skip$visible)
    expect_true(is.list(run_skip$value))
    expect_true("tables" %in% names(run_skip$value))
    expect_true("joins" %in% names(run_skip$value))
    expect_equal(nrow(run_skip$value$joins), 0)

    report_dir <- latest_report_dir(work_dir)
    expect_true(file.exists(file.path(report_dir, "estimates.txt")))
  })
})

test_that("single-file mode applies within-file checks only and overrides joins", {
  root <- new_spec_sandbox()
  specs_dir <- file.path(root, "specs")
  work_dir <- file.path(root, "work")

  write_spec_file(file.path(specs_dir, "tables", "estimates.yaml"), c(
    "table: estimates",
    "description: One row per extracted estimate.",
    "source:",
    "  file: data/raw/estimates.csv",
    "levels:",
    "  study: study",
    "columns:",
    "  - name: study",
    "    type: text",
    "    required: true"
  ))

  with_work_dir(work_dir, {
    run_single <- capture_stdout(rev_spec_run(dir = specs_dir, file = "estimates.yaml", joins = TRUE))
    expect_null(run_single$error)
    expect_false(run_single$visible)
    expect_true(is.list(run_single$value))

    report_dir <- latest_report_dir(work_dir)
    expect_true(file.exists(file.path(report_dir, "estimates.txt")))
    expect_false(file.exists(file.path(report_dir, "joins.txt")))
  })
})

test_that("run checks every input before halting and writes per-file reports", {
  root <- new_spec_sandbox()
  specs_dir <- file.path(root, "specs")
  work_dir <- file.path(root, "work")

  write_spec_file(file.path(specs_dir, "tables", "estimates.yaml"), c(
    "table: estimates",
    "description: One row per extracted estimate.",
    "source:",
    "  file: data/raw/estimates.csv",
    "levels:",
    "  study: study",
    "columns:",
    "  - nam: study",
    "    type: text"
  ))

  write_spec_file(file.path(specs_dir, "tables", "rob.yaml"), c(
    "table: rob",
    "description: One row per study's risk-of-bias rating.",
    "source:",
    "  file: data/raw/rob.csv",
    "columns:",
    "  - name: study_id",
    "    type: text"
  ))

  write_spec_file(file.path(specs_dir, "joins.yaml"), c(
    "joins:",
    "  - adds: variables",
    "    left: estimates",
    "    right: rob",
    "    keys:",
    "      estimates: [study]",
    "      rob: [study_id]",
    "    relationship: one-to-many",
    "    unmatched_ok: false"
  ))

  with_work_dir(work_dir, {
    audit <- capture_stdout(rev_spec_audit(dir = specs_dir))
    expect_null(audit$error)
    expect_false(isTRUE(audit$value$certified))

    run <- capture_stdout(rev_spec_run(dir = specs_dir))
    expect_false(is.null(run$error))
    expect_match(conditionMessage(run$error), "spec set not certified and not returned\\.")

    report_dir <- latest_report_dir(work_dir)
    expect_true(file.exists(file.path(report_dir, "estimates.txt")))
    expect_true(file.exists(file.path(report_dir, "rob.txt")))
    expect_true(file.exists(file.path(report_dir, "joins.txt")))
  })
})

test_that("same-entry and incomplete-search related text appear only when promised", {
  root_a <- new_spec_sandbox()
  specs_a <- file.path(root_a, "specs")
  work_a <- file.path(root_a, "work")

  write_spec_file(file.path(specs_a, "tables", "estimates.yaml"), c(
    "table: estimates",
    "description: One row per extracted estimate.",
    "source:",
    "  file: data/raw/estimates.csv",
    "columns:",
    "  - nam: study",
    "    type: text",
    "  - name: mean_age",
    "    type: decimal",
    "    constant_within_level: study"
  ))
  write_spec_file(file.path(specs_a, "joins.yaml"), "joins: []")

  with_work_dir(work_a, {
    audit_a <- capture_stdout(rev_spec_audit(dir = specs_a))
    expect_null(audit_a$error)
    report_dir_a <- latest_report_dir(work_a)
    estimates_report_a <- report_text(report_dir_a, "estimates.txt")

    expect_match(estimates_report_a, "unknown field 'nam'")
    expect_match(estimates_report_a, "missing required field 'name'")
    expect_match(estimates_report_a, "another error sits in this entry")
    expect_match(estimates_report_a, "incomplete list")
  })

  root_b <- new_spec_sandbox()
  specs_b <- file.path(root_b, "specs")
  work_b <- file.path(root_b, "work")

  write_spec_file(file.path(specs_b, "tables", "estimates.yaml"), c(
    "table: estimates",
    "description: One row per extracted estimate.",
    "source:",
    "  file: data/raw/estimates.csv",
    "columns:",
    "  - name: study_id",
    "    type: text",
    "  - name: mean_age",
    "    type: decimal",
    "    constant_within_level: study"
  ))
  write_spec_file(file.path(specs_b, "joins.yaml"), "joins: []")

  with_work_dir(work_b, {
    audit_b <- capture_stdout(rev_spec_audit(dir = specs_b))
    expect_null(audit_b$error)
    report_dir_b <- latest_report_dir(work_b)
    estimates_report_b <- report_text(report_dir_b, "estimates.txt")

    expect_match(estimates_report_b, "study")
    expect_no_match(estimates_report_b, "incomplete list")
  })
})

test_that("cross-file duplicate table errors are reported in both dictionary reports", {
  root <- new_spec_sandbox()
  specs_dir <- file.path(root, "specs")
  work_dir <- file.path(root, "work")

  write_spec_file(file.path(specs_dir, "tables", "estimates.yaml"), c(
    "table: dup_table",
    "description: First dictionary",
    "source:",
    "  file: data/raw/a.csv",
    "columns:",
    "  - name: id",
    "    type: text"
  ))

  write_spec_file(file.path(specs_dir, "tables", "rob.yaml"), c(
    "table: dup_table",
    "description: Second dictionary",
    "source:",
    "  file: data/raw/b.csv",
    "columns:",
    "  - name: id",
    "    type: text"
  ))

  write_spec_file(file.path(specs_dir, "joins.yaml"), "joins: []")

  with_work_dir(work_dir, {
    audit <- capture_stdout(rev_spec_audit(dir = specs_dir))
    expect_null(audit$error)
    expect_false(isTRUE(audit$value$certified))

    report_dir <- latest_report_dir(work_dir)
    estimates_report <- report_text(report_dir, "estimates.txt")
    rob_report <- report_text(report_dir, "rob.txt")

    expect_match(estimates_report, "dup_table")
    expect_match(rob_report, "dup_table")
  })
})