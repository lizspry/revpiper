good_path <- function() {
  test_path("fixtures", "specs-good", "tables", "estimates.yaml")
}

# A zero-problem dictionary the matrix mutates one aspect at a time.
minimal_dict <- function() {
  list(
    table = "estimates",
    source = list(file = "data/raw/estimates.csv"),
    columns = list(
      list(name = "study", type = "text"),
      list(name = "mean_age", type = "decimal")
    )
  )
}

# Set a field, including explicitly to NULL (list [[<- NULL would delete).
set_field <- function(x, field, value) {
  if (is.null(value)) {
    x[field] <- list(NULL)
  } else {
    x[[field]] <- value
  }
  x
}

# Place one field of one kind into a minimal dictionary. For the level kind
# the baseline entry satisfies every OTHER field's rules (separator needs a
# combine beside it), so only the placed field's own problem surfaces.
place_field <- function(d, kind, field, value) {
  if (kind == "file") {
    return(set_field(d, field, value))
  }
  if (kind == "source") {
    d$source <- set_field(d$source, field, value)
    return(d)
  }
  if (kind == "column") {
    d$columns[[1]] <- set_field(d$columns[[1]], field, value)
    return(d)
  }
  base <- switch(
    field,
    separator = list(combine = c("study", "mean_age")),
    within = list(keys = "study"),
    list()
  )
  d$levels <- list(l1 = set_field(base, field, value))
  d
}

# Round-trip a dictionary list through a temp yaml file.
read_dict <- function(dict) {
  tmp <- tempfile(fileext = ".yaml")
  on.exit(unlink(tmp))
  yaml::write_yaml(dict, tmp)
  rev_read_dictionary(tmp)
}

problems_of <- function(dict) {
  spec_problems(read_dict(dict))
}

codes_of <- function(dict) {
  spec_codes(problems_of(dict))
}

# ---- Layer 1: property matrix, generated from the schema ----

test_that("the minimal dictionary is problem-free (matrix baseline)", {
  expect_identical(codes_of(minimal_dict()), character(0))
})

test_that("required: absence flags YE02 exactly for schema-required fields", {
  base <- minimal_dict()
  for (f in c("table", "source", "columns")) {
    row <- field_schema("file")[field_schema("file")$field == f, ]
    d <- base
    d[[f]] <- NULL
    if (row$required) {
      expect_true("YE02" %in% codes_of(d), info = f)
    }
  }
  d <- base
  d$source$file <- NULL
  expect_identical(codes_of(d), "YE02")
  for (f in c("name", "type")) {
    d <- base
    d$columns[[1]][[f]] <- NULL
    expect_true("YE02" %in% codes_of(d), info = f)
  }
  # not-apply side: every optional field is already absent from the baseline
  optional <- field_schema("column")$field[!field_schema("column")$required]
  expect_true(length(optional) > 0)
  expect_identical(codes_of(base), character(0))
})

test_that("vocabulary: unknown fields flag YE01 for every kind of entry", {
  base <- minimal_dict()
  d <- base
  d$bogus <- "x"
  expect_identical(codes_of(d), "YE01")
  d <- base
  d$source$bogus <- "x"
  expect_identical(codes_of(d), "YE01")
  d <- base
  d$columns[[1]]$bogus <- "x"
  expect_identical(codes_of(d), "YE01")
})

test_that("empty: a NULL value flags YF01 unless the schema says empty_ok", {
  base <- minimal_dict()
  for (kind in c("file", "source", "column", "level")) {
    schema <- field_schema(kind)
    for (i in seq_len(nrow(schema))) {
      row <- schema[i, ]
      d <- place_field(base, kind, row$field, NULL)
      got <- codes_of(d)
      if (row$empty_ok) {
        expect_identical(got, character(0), info = paste(kind, row$field))
      } else {
        expect_identical(got, "YF01", info = paste(kind, row$field))
      }
    }
  }
})

test_that("shape and cardinality violations flag YF02, without cascade", {
  base <- minimal_dict()
  bad_for <- list(
    string = 5L,
    boolean = "banana",
    scalar = list(list("nested", "pair")),
    mapping = "not a mapping",
    list_of_mappings = "not mappings"
  )
  for (kind in c("file", "source", "column", "level")) {
    schema <- field_schema(kind)
    for (i in seq_len(nrow(schema))) {
      row <- schema[i, ]
      d <- place_field(base, kind, row$field, bad_for[[row$shape]])
      expect_identical(codes_of(d), "YF02", info = paste(kind, row$field))
    }
  }
  # cardinality: one rejects many; two rejects one and three; empty list rejects
  d <- base
  d$columns[[1]]$name <- c("a", "b")
  expect_identical(codes_of(d), "YF02")
  for (rng in list(list(10), list(10, 20, 30), list())) {
    d <- base
    d$columns[[2]]$range <- rng
    expect_identical(codes_of(d), "YF02", info = length(rng))
  }
})

test_that("domain: off-domain values flag YF03; on-domain are silent", {
  d <- minimal_dict()
  d$columns[[1]]$type <- "wrongtype"
  expect_identical(codes_of(d), "YF03")
  for (t in schema_types()) {
    d <- minimal_dict()
    d$columns[[1]]$type <- t
    expect_identical(codes_of(d), character(0), info = t)
  }
})

test_that("permitted_types: every constraint x type lands YE03 or silence", {
  good_content <- list(
    text = c("a", "b"),
    integer = c(1L, 9L),
    decimal = c(1.5, 9.5),
    date = c("2026-01-01", "2026-06-30"),
    boolean = c(TRUE, FALSE)
  )
  for (f in c("values", "range", "units")) {
    row <- field_schema("column")[field_schema("column")$field == f, ]
    for (t in schema_types()) {
      d <- minimal_dict()
      d$columns[[1]]$type <- t
      d$columns[[1]][[f]] <- if (f == "units") "mg" else good_content[[t]]
      got <- codes_of(d)
      if (t %in% row$permitted_types[[1]]) {
        expect_identical(got, character(0), info = paste(f, t))
      } else {
        expect_identical(got, "YE03", info = paste(f, t))
      }
    }
  }
})

test_that("content_typed: entries not matching the declared type flag YE05", {
  d <- minimal_dict()
  d$columns[[1]]$type <- "integer"
  d$columns[[1]]$values <- c("a", "b")
  expect_identical(codes_of(d), "YE05")
  d <- minimal_dict()
  d$columns[[1]]$type <- "integer"
  d$columns[[1]]$values <- list(1L, "two")
  expect_identical(codes_of(d), "YE05")
  d <- minimal_dict()
  d$columns[[2]]$range <- c("a", "b")
  expect_identical(codes_of(d), "YE05")
  d <- minimal_dict()
  d$columns[[1]]$type <- "date"
  d$columns[[1]]$range <- c("15/01/2026", "2026-06-30")
  expect_identical(codes_of(d), "YE05")
})

test_that("ordered: descending ranges flag YF05, numeric and chronological", {
  d <- minimal_dict()
  d$columns[[2]]$range <- c(60, 10)
  expect_identical(codes_of(d), "YF05")
  d <- minimal_dict()
  d$columns[[1]]$type <- "date"
  d$columns[[1]]$range <- c("2026-06-30", "2026-01-15")
  expect_identical(codes_of(d), "YF05")
  d <- minimal_dict()
  d$columns[[2]]$range <- c(10, 60)
  expect_identical(codes_of(d), character(0))
})

test_that("excludes: co-occurrence flags YE04 exactly once", {
  d <- minimal_dict()
  d$columns[[2]]$values <- c(10, 20)
  d$columns[[2]]$range <- c(10, 60)
  problems <- problems_of(d)
  expect_identical(unique(problems$code), "YE04")
  expect_identical(nrow(problems), 1L)
})

test_that("unique_entries: duplicates flag YF04; scalars normalise silently", {
  d <- minimal_dict()
  d$columns[[1]]$values <- c("RCT", "RCT")
  expect_identical(codes_of(d), "YF04")
  d <- minimal_dict()
  d$columns[[1]]$missing <- c("NR", "NR")
  expect_identical(codes_of(d), "YF04")
  # one_or_many: scalar and list are both accepted
  d <- minimal_dict()
  d$columns[[1]]$missing <- "NR"
  expect_identical(codes_of(d), character(0))
  d <- minimal_dict()
  d$columns[[1]]$missing <- c("NR", "n/a")
  expect_identical(codes_of(d), character(0))
  d <- minimal_dict()
  d$columns[[1]]$values <- "onlyone"
  expect_identical(codes_of(d), character(0))
})

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
  dict <- rev_read_dictionary(good_path())
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

test_that("rev_read_dictionaries returns a table-named list of dictionaries", {
  dicts <- rev_read_dictionaries(
    test_path("fixtures", "specs-good", "tables")
  )
  expect_named(dicts, c("estimates", "rob"))
  expect_s3_class(dicts$estimates, "rev_dictionary")
  expect_s3_class(dicts$rob, "rev_dictionary")
})

test_that("duplicate table names across files flag YX01", {
  expect_error(
    rev_read_dictionaries(bad_path("yx01-duplicate-table")),
    class = "revpiper_spec_error"
  )
  expect_snapshot(
    error = TRUE,
    rev_read_dictionaries(bad_path("yx01-duplicate-table"))
  )
})

# ---- Layer 2: curated fixtures — wording and routing ----

test_that("rev_read_dictionary parses a valid dictionary into every slot", {
  dict <- rev_read_dictionary(good_path())

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
    rev_read_dictionary("no/such/dictionary.yaml"),
    class = "revpiper_spec_error"
  )
  expect_snapshot(error = TRUE, rev_read_dictionary("no/such/dictionary.yaml"))
})

test_that("the classed abort carries the problems table as data", {
  err <- tryCatch(
    rev_read_dictionary(bad_path("many-defects.yaml")),
    error = \(e) e
  )
  expect_s3_class(err, "revpiper_spec_error")
  expect_s3_class(err$problems, "tbl_df")
  expect_setequal(err$problems$code, c("YE01", "YF03", "YF05"))
})

test_that("each single-defect dictionary aborts naming its problem", {
  read_bad <- function(fixture) rev_read_dictionary(bad_path(fixture))

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
    rev_read_dictionary(bad_path("many-defects.yaml"))
  )
})

test_that("shape_phrase wording is grammatical for every shape x cardinality", {
  expect_snapshot({
    for (shape in c("string", "boolean", "scalar")) {
      for (cardinality in c("one", "one_or_many", "two")) {
        cat(sprintf(
          "%-8s %-12s -> %s\n",
          shape,
          cardinality,
          shape_phrase(shape, cardinality)
        ))
      }
    }
    for (shape in c("mapping", "list_of_mappings")) {
      cat(sprintf("%-21s -> %s\n", shape, shape_phrase(shape, "one")))
    }
  })
})
