test_that("refers_to: every referring field flags YS02 or resolves silently", {
  # Place a value for one referring field inside a minimal dictionary. The
  # switch is the matrix's gap alarm: a schema row this builder cannot place
  # fails loudly instead of passing silently.
  with_reference <- function(field, value) {
    d <- minimal_dict()
    switch(
      field,
      levels = {
        d$levels <- list(study = value)
        d
      },
      keys = {
        d$levels <- list(study = list(keys = value))
        d
      },
      combine = {
        d$levels <- list(study_id = list(combine = value, separator = "_"))
        d
      },
      within = {
        d$levels <- list(
          study = "study",
          substudy = list(keys = "mean_age", within = value)
        )
        d
      },
      constant_within_level = {
        d$levels <- list(study = "study")
        d$columns[[2]]$constant_within_level <- value
        d
      },
      stop(sprintf("refers_to matrix has no builder for field '%s'", field))
    )
  }
  resolving <- list(
    levels = "study",
    keys = "study",
    combine = c("study", "mean_age"),
    within = "study",
    constant_within_level = "study"
  )
  broken <- list(
    levels = "no_such_column",
    keys = "no_such_column",
    combine = c("no_such_column", "mean_age"),
    within = "no_such_level",
    constant_within_level = "no_such_level"
  )
  s <- schema_fields()
  referring <- s$field[!is.na(s$refers_to)]
  expect_true(length(referring) > 0)
  for (f in referring) {
    expect_true(f %in% names(resolving), info = f)
    expect_identical(
      codes_of(with_reference(f, resolving[[f]])),
      character(0),
      info = f
    )
    expect_identical(codes_of(with_reference(f, broken[[f]])), "YS02", info = f)
  }
})

test_that("every refers_to vocabulary value has declared names", {
  props <- schema_properties()
  allowed <- props$allowed[[which(props$property == "refers_to")]]
  expect_true(length(allowed) > 0)
  for (name in allowed) {
    expect_no_error(declared_names(minimal_dict(), name))
  }
})

test_that("level entries dispatch: string, keys, combination, else YE06", {
  d <- minimal_dict()
  d$levels <- list(study = "study")
  expect_identical(codes_of(d), character(0))
  d$levels <- list(study = list(keys = c("study", "mean_age")))
  expect_identical(codes_of(d), character(0))
  d$levels <- list(
    study_id = list(combine = c("study", "mean_age"), separator = "_")
  )
  expect_identical(codes_of(d), character(0))
  for (bad in list(7, TRUE, c("study", "mean_age"))) {
    d$levels <- list(study_id = bad)
    expect_identical(codes_of(d), "YE06", info = class(bad))
  }
  # a mapping that neither names nor builds its key columns
  d$levels <- list(study = "study", sub = list(within = "study"))
  expect_identical(codes_of(d), "YE06")
})

test_that("a combination without separator is legal (direct concatenation)", {
  d <- minimal_dict()
  d$levels <- list(study_key = list(combine = c("study", "mean_age")))
  expect_identical(codes_of(d), character(0))
})

test_that("a malformed level mapping reports battery codes precisely", {
  d <- minimal_dict()
  d$levels <- list(
    study_id = list(combyne = c("study", "mean_age"), separator = "_")
  )
  expect_setequal(codes_of(d), c("YE01", "YE06", "YE07"))
  d$levels <- list(
    study_id = list(combine = c("study", "study"), separator = "_")
  )
  expect_identical(codes_of(d), "YF04")
  d$levels <- list(
    study_id = list(keys = "study", combine = c("study", "mean_age"))
  )
  expect_identical(codes_of(d), "YE04")
  d$levels <- list(study_id = list(keys = "study", separator = "_"))
  expect_identical(codes_of(d), "YE07")
})

test_that("within nests levels, tolerating forward references", {
  d <- minimal_dict()
  d$levels <- list(
    study = "study",
    substudy = list(keys = "mean_age", within = "study")
  )
  expect_identical(codes_of(d), character(0))
  d$levels <- list(
    substudy = list(keys = "mean_age", within = "study"),
    study = "study"
  )
  expect_identical(codes_of(d), character(0))
})

test_that("circular within nesting flags YS04 exactly once per cycle", {
  d <- minimal_dict()
  d$levels <- list(
    a = list(keys = "study", within = "b"),
    b = list(keys = "mean_age", within = "a")
  )
  problems <- problems_of(d)
  expect_identical(unique(problems$code), "YS04")
  expect_identical(nrow(problems), 1L)
  d$levels <- list(a = list(keys = "study", within = "a"))
  expect_identical(codes_of(d), "YS04")
})

test_that("a level's keys may reference another level's virtual column", {
  d <- minimal_dict()
  d$levels <- list(
    study_key = list(combine = c("study", "mean_age"), separator = "_"),
    substudy = list(keys = "study_key")
  )
  expect_identical(codes_of(d), character(0))
  expect_identical(
    dictionary_key_columns(read_dict(d)),
    c("study", "mean_age", "study_key")
  )
})

test_that("dictionary_key_columns returns declared plus virtual columns", {
  dict <- read_dictionary(good_path())
  expect_identical(
    dictionary_key_columns(dict),
    c("study", "design", "mean_age", "rob_score", "notes_temp")
  )
  # good variant: a combine level parses and registers its virtual column
  d <- minimal_dict()
  d$levels <- list(
    study_id = list(combine = c("study", "mean_age"), separator = "_")
  )
  expect_identical(
    dictionary_key_columns(read_dict(d)),
    c("study", "mean_age", "study_id")
  )
})

test_that("read_dictionaries returns a table-named list of dictionaries", {
  dicts <- read_dictionaries(
    test_path("fixtures", "specs-good", "tables")
  )
  expect_named(dicts, c("estimates", "rob"))
  expect_s3_class(dicts$estimates, "rev_dictionary")
  expect_s3_class(dicts$rob, "rev_dictionary")
})

test_that("duplicate table names across files flag YX01", {
  expect_error(
    read_dictionaries(bad_path("yx01-duplicate-table")),
    class = "revpiper_spec_error"
  )
  expect_snapshot(
    error = TRUE,
    read_dictionaries(bad_path("yx01-duplicate-table"))
  )
})

# ---- Layer 2: curated fixtures — wording and routing ----

test_that("read_dictionary parses a valid dictionary into every slot", {
  dict <- read_dictionary(good_path())

  expect_s3_class(dict, "rev_dictionary")
  expect_equal(dict$table, "estimates")
  expect_equal(dict$description, "One row per extracted estimate.")
  expect_equal(dict$source$file, "data/raw/estimates.csv")
  expect_null(dict$source$sheet)
  expect_null(dict$source$reader)
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

test_that("boundary-legal declarations parse cleanly (permissive rule)", {
  d <- minimal_dict()
  d$columns[[1]] <- list(
    name = "wave_date",
    type = "date",
    values = c("2019-03-01", "2021-03-01"),
    description = "collection wave"
  )
  d$columns[[2]] <- list(
    name = "dose_text",
    type = "text",
    units = "mg",
    unique = TRUE,
    missing = "NR"
  )
  expect_identical(codes_of(d), character(0))
  dict <- read_dict(d)
  expect_equal(dict$columns$values[[1]], c("2019-03-01", "2021-03-01"))
  expect_true(dict$columns$unique[2])
  expect_equal(dict$columns$missing[[2]], "NR")
})

test_that("a nonexistent dictionary path aborts with the classed error", {
  expect_error(
    read_dictionary("no/such/dictionary.yaml"),
    class = "revpiper_spec_error"
  )
  expect_snapshot(error = TRUE, read_dictionary("no/such/dictionary.yaml"))
})

test_that("the classed abort carries the problems table as data", {
  err <- tryCatch(
    read_dictionary(bad_path("many-defects.yaml")),
    error = \(e) e
  )
  expect_s3_class(err, "revpiper_spec_error")
  expect_s3_class(err$problems, "tbl_df")
  expect_setequal(err$problems$code, c("YE01", "YF03", "YF05"))
})

test_that("each single-defect dictionary aborts naming its problem", {
  read_bad <- function(fixture) read_dictionary(bad_path(fixture))

  expect_snapshot(error = TRUE, read_bad("ye01-file-entry.yaml"))
  expect_snapshot(error = TRUE, read_bad("ye02-missing-type.yaml"))
  expect_snapshot(error = TRUE, read_bad("ye03-range-on-text.yaml"))
  expect_snapshot(error = TRUE, read_bad("ye04-values-and-range.yaml"))
  expect_snapshot(error = TRUE, read_bad("ye05-mixed-values.yaml"))
  expect_snapshot(error = TRUE, read_bad("ye05-date-range-not-iso.yaml"))
  expect_snapshot(error = TRUE, read_bad("yf01-empty-field.yaml"))
  expect_snapshot(error = TRUE, read_bad("yf02-name-list.yaml"))
  expect_snapshot(error = TRUE, read_bad("yf03-bad-type.yaml"))
  expect_snapshot(error = TRUE, read_bad("yf04-duplicate-values.yaml"))
  expect_snapshot(error = TRUE, read_bad("yf05-descending-range.yaml"))
  expect_snapshot(error = TRUE, read_bad("ys01-duplicate-column.yaml"))
  expect_snapshot(error = TRUE, read_bad("ye06-level-number.yaml"))
  expect_snapshot(error = TRUE, read_bad("ye07-separator-without-combine.yaml"))
  expect_snapshot(error = TRUE, read_bad("ys02-key-unknown-column.yaml"))
  expect_snapshot(error = TRUE, read_bad("ys02-combine-part-unknown.yaml"))
  expect_snapshot(error = TRUE, read_bad("ys02-cwl-unknown-level.yaml"))
  expect_snapshot(error = TRUE, read_bad("ys02-within-unknown-level.yaml"))
  expect_snapshot(error = TRUE, read_bad("ys04-within-cycle.yaml"))
  expect_snapshot(error = TRUE, read_bad("yf04-duplicate-combine-parts.yaml"))
})

test_that("every problem in a broken dictionary is reported at once", {
  expect_snapshot(
    error = TRUE,
    read_dictionary(bad_path("many-defects.yaml"))
  )
})

test_that("a file that does not parse aborts as a spec problem, not rawly", {
  expect_snapshot(
    read_dictionary(bad_path("ys05-unparseable.yaml")),
    error = TRUE
  )
  problems <- spec_problems(read_dictionary(bad_path("ys05-unparseable.yaml")))
  expect_identical(spec_codes(problems), "YS05")
})

# Adopted from the adversarial battery (hostile-10): YAML reads an
# unquoted 007 as a number; the table identity must be a single text
# value.
test_that("a non-text table identity is a shape problem", {
  d <- set_field(minimal_dict(), "table", 7L)
  expect_identical(codes_of(d), "YF02")
})

# Adopted from the adversarial battery (hostile-15): the smallest cycle.
test_that("a level nested within itself is a cycle", {
  d <- minimal_dict()
  d$levels <- list(study = list(keys = "study", within = "study"))
  expect_true("YS04" %in% codes_of(d))
})

# From the adversarial battery (lawyer-18) and the 2026-07-13 ruling:
# a combine level registers a virtual column named by the level, so the
# name may not collide with a declared column.
test_that("a combine level may not collide with a declared column", {
  expect_snapshot(
    read_dictionary(bad_path("ys06-virtual-collision.yaml")),
    error = TRUE
  )
  d <- minimal_dict()
  d$levels <- list(study = list(combine = c("study", "mean_age")))
  expect_identical(codes_of(d), "YS06")
})
