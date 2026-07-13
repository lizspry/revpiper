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

# Adopted from the adversarial battery (hostile-08/09): unquoted yes/no
# are YAML booleans, not text - the coercion must be caught, and the
# quoted twin must pass.
test_that("YAML type coercion inside values is caught by content typing", {
  tmps <- character(0)
  on.exit(unlink(tmps))
  write_spec <- function(values_line) {
    tmp <- tempfile(fileext = ".yaml")
    tmps <<- c(tmps, tmp)
    writeLines(
      c(
        "table: estimates",
        "source:",
        "  file: data/raw/estimates.csv",
        "columns:",
        "  - name: answer",
        "    type: text",
        paste0("    values: ", values_line)
      ),
      tmp
    )
    tmp
  }
  coerced <- spec_problems(read_dictionary(write_spec("[yes, no]")))
  expect_identical(spec_codes(coerced), "YE05")
  expect_null(spec_problems(read_dictionary(write_spec('["yes", "no"]'))))
})
