test_that("run success: audit-identical output plus final acts; spec set invisible", {
  root <- spec_project("specs-good")
  withr::local_dir(root)
  expect_snapshot(specs <- rev_spec_run("specs"), transform = scrub_runstamp)
  expect_named(specs, c("tables", "joins"))
  expect_named(specs$tables, c("estimates", "rob"))
  expect_s3_class(specs$tables[[1]], "rev_dictionary")
  expect_identical(nrow(specs$joins), 1L)
  expect_invisible(suppressMessages(rev_spec_run("specs")))
  written <- list.files("output/reports", recursive = TRUE)
  expect_true(length(written) >= 3) # run writes everything audit writes
})

test_that("run failure: all checking completes, reports written, then one abort", {
  root <- spec_project("specs-good")
  break_file(root, "estimates.yaml")
  withr::local_dir(root)
  expect_snapshot(
    error = TRUE,
    rev_spec_run("specs"),
    transform = scrub_runstamp
  )
  written <- list.files("output/reports", recursive = TRUE)
  expect_setequal(
    basename(written),
    c("estimates.yaml.txt", "rob.yaml.txt", "joins.yaml.txt")
  )
  e <- tryCatch(
    suppressMessages(rev_spec_run("specs")),
    revpiper_spec_error = identity
  )
  expect_match(conditionMessage(e), "not certified and not returned")
  expect_s3_class(e$outcome, "rev_report")
  expect_false(e$outcome$certified)
})

test_that("single-file mode keeps the same presentation", {
  root <- spec_project("specs-good")
  withr::local_dir(root)
  expect_snapshot(
    one <- rev_spec_run("specs", file = "estimates.yaml"),
    transform = scrub_runstamp
  )
  expect_named(one$tables, "estimates")
  joins_only <- suppressMessages(rev_spec_run("specs", file = "joins.yaml"))
  expect_identical(nrow(joins_only$joins), 1L)
  expect_length(joins_only$tables, 0)
})

test_that("usage errors still abort before any checking", {
  root <- spec_project("specs-good")
  withr::local_dir(root)
  expect_error(
    rev_spec_run("specs", file = "tables/estimates.yaml"),
    class = "revpiper_spec_error"
  )
  expect_error(rev_spec_run("no/such/dir"), class = "revpiper_spec_error")
})

test_that("single-file joins mode skips reference resolution (review gap)", {
  root <- spec_project("specs-good")
  writeLines(
    paste0(
      "joins:\n  - {adds: variables, left: ghost, right: phantom, ",
      "keys: {ghost: [a], phantom: [b]}, relationship: one-to-many}"
    ),
    file.path(root, "specs", "joins.yaml")
  )
  withr::local_dir(root)
  one <- suppressMessages(rev_spec_run("specs", file = "joins.yaml"))
  expect_identical(nrow(one$joins), 1L)
  expect_length(one$tables, 0)
})
