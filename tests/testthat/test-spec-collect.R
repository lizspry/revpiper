test_that("collector checks every file and certifies per file", {
  root <- spec_project("specs-good")
  break_file(root, "estimates.yaml")
  out <- collect_spec_step(file.path(root, "specs"))
  expect_s3_class(out, "rev_report")
  expect_named_records(out, c("estimates.yaml", "rob.yaml", "joins.yaml"))
  expect_false(record(out, "estimates.yaml")$certified)
  expect_true(record(out, "rob.yaml")$certified)
  expect_false(out$certified)
  expect_null(out$specs)
})

test_that("rule 1 lands in the assembled records: nameless entry's pair linked", {
  root <- spec_project("specs-good")
  break_file(root, "estimates.yaml")
  out <- collect_spec_step(file.path(root, "specs"))
  problems <- record(out, "estimates.yaml")$problems
  expect_setequal(problems$code, c("YE01", "YE02"))
  expect_identical(unique(problems$related), related_phrases$same_entry)
})

test_that("cross-file related reaches the joins record", {
  root <- spec_project("specs-good")
  break_file(root, "estimates.yaml")
  out <- collect_spec_step(file.path(root, "specs"))
  joins_problems <- record(out, "joins.yaml")$problems
  expect_true(
    sprintf(related_phrases$incomplete_file, "estimates.yaml") %in%
      joins_problems$related
  )
})

test_that("a clean set certifies and releases the spec set", {
  out <- collect_spec_step(file.path(spec_project("specs-good"), "specs"))
  expect_true(out$certified)
  expect_named(out$specs, c("tables", "joins"))
  expect_named(out$specs$tables, c("estimates", "rob"))
  expect_identical(nrow(out$specs$joins), 1L)
})

test_that("joins = FALSE: no joins record, zero-row joins in specs", {
  root <- spec_project("specs-good")
  unlink(file.path(root, "specs", "joins.yaml"))
  out <- collect_spec_step(file.path(root, "specs"), joins = FALSE)
  expect_named_records(out, c("estimates.yaml", "rob.yaml"))
  expect_identical(nrow(out$specs$joins), 0L)
})

test_that("missing joins.yaml when expected is a YX04 record, not an abort", {
  root <- spec_project("specs-good")
  unlink(file.path(root, "specs", "joins.yaml"))
  out <- collect_spec_step(file.path(root, "specs"))
  expect_identical(record(out, "joins.yaml")$problems$code, "YX04")
  expect_false(out$certified)
})

test_that("single-file mode collects one record, within-file checks only", {
  root <- spec_project("specs-good")
  out <- collect_spec_step(file.path(root, "specs"), file = "estimates.yaml")
  expect_named_records(out, "estimates.yaml")
  expect_true(out$certified)
  expect_named(out$specs$tables, "estimates")
})

test_that("usage errors still abort: file must be a filename, not a path", {
  root <- spec_project("specs-good")
  expect_error(
    collect_spec_step(file.path(root, "specs"), file = "tables/estimates.yaml"),
    class = "revpiper_spec_error"
  )
})

test_that("duplicate table names across files flag YX01, snapshotted", {
  files <- list.files(bad_path("yx01-duplicate-table"), full.names = TRUE)
  dicts <- read_dicts(bad_path("yx01-duplicate-table"))
  expect_snapshot(
    as.data.frame(check_table_identity(names(dicts), files)$problems)
  )
})

test_that("zero dictionaries is a standing problem, never vacuous (battery)", {
  root <- spec_project("specs-good")
  unlink(file.path(root, "specs", "tables", c("estimates.yaml", "rob.yaml")))
  withr::local_dir(root) # relative dir keeps the snapshot deterministic
  out <- collect_spec_step("specs", joins = FALSE)
  expect_false(out$certified)
  expect_identical(record(out, "tables")$problems$code, "YX05")
  expect_snapshot(as.data.frame(record(out, "tables")$problems[-1]))
})

test_that("YX01 lands only on the involved files, never substring matches (review)", {
  root <- spec_project("specs-good")
  tables <- file.path(root, "specs", "tables")
  writeLines(
    sub(
      "table: estimates",
      "table: estimates",
      readLines(
        file.path(tables, "estimates.yaml")
      )
    ),
    file.path(tables, "estimates2.yaml")
  )
  writeLines(
    c(
      "table: solo",
      "source: {file: s.csv}",
      "columns:",
      "  - {name: a, type: text}"
    ),
    file.path(tables, "s.yaml")
  )
  out <- collect_spec_step(file.path(root, "specs"), joins = FALSE)
  expect_true(record(out, "s.yaml")$certified)
  expect_true(record(out, "rob.yaml")$certified)
  expect_identical(record(out, "estimates.yaml")$problems$code, "YX01")
  expect_identical(record(out, "estimates2.yaml")$problems$code, "YX01")
})

test_that("joins = FALSE skips an EXISTING joins spec too (review gap)", {
  root <- spec_project("specs-good")
  out <- collect_spec_step(file.path(root, "specs"), joins = FALSE)
  expect_true(out$certified)
  expect_named_records(out, c("estimates.yaml", "rob.yaml"))
  expect_identical(nrow(out$specs$joins), 0L)
})

test_that("two FAILED files claiming one table: YX01 on both, related names both (Liz)", {
  root <- spec_project("specs-good")
  tables <- file.path(root, "specs", "tables")
  broken <- c(
    "table: estimates",
    "source: {file: a.csv}",
    "columns:",
    "  - {nam: study, type: text}"
  )
  writeLines(broken, file.path(tables, "estimates.yaml"))
  writeLines(broken, file.path(tables, "estimates-old.yaml"))
  out <- collect_spec_step(file.path(root, "specs"))
  expect_true("YX01" %in% record(out, "estimates.yaml")$problems$code)
  expect_true("YX01" %in% record(out, "estimates-old.yaml")$problems$code)
  joins_related <- record(out, "joins.yaml")$problems$related
  expect_true(any(grepl(
    "estimates-old.yaml, estimates.yaml",
    joins_related,
    fixed = TRUE
  )))
})
