joins_path <- function(fixture) {
  test_path("fixtures", "specs-good", fixture)
}

good_dictionaries <- function() {
  read_dictionaries(test_path("fixtures", "specs-good", "tables"))
}

# A zero-problem join the matrix mutates one aspect at a time.
minimal_join <- function() {
  list(
    adds = "variables",
    left = "estimates",
    right = "rob",
    keys = list(estimates = "study", rob = "study_id"),
    relationship = "one-to-many"
  )
}

# Round-trip a joins list through a temp yaml file.
joins_from_list <- function(joins, dictionaries = good_dictionaries()) {
  tmp <- tempfile(fileext = ".yaml")
  on.exit(unlink(tmp))
  yaml::write_yaml(list(joins = joins), tmp)
  read_joins(tmp, dictionaries)
}

join_problems_of <- function(joins) {
  spec_problems(joins_from_list(joins))
}

join_codes_of <- function(joins) {
  spec_codes(join_problems_of(joins))
}

# ---- Layer 1: matrix over the join schema rows ----

test_that("the minimal join is problem-free (matrix baseline)", {
  expect_identical(join_codes_of(list(minimal_join())), character(0))
})

test_that("required: absence flags YE02 only where the field is demanded", {
  for (f in c("adds", "left", "right", "keys")) {
    j <- minimal_join()
    j[[f]] <- NULL
    expect_true("YE02" %in% join_codes_of(list(j)), info = f)
  }
  # relationship is demanded when a join adds variables ...
  j <- minimal_join()
  j$relationship <- NULL
  expect_identical(join_codes_of(list(j)), "YE02")
  # ... and not demanded (indeed banned) when it adds observations
  j <- minimal_join()
  j$adds <- "observations"
  j$relationship <- NULL
  expect_identical(join_codes_of(list(j)), character(0))
})

test_that("domains: adds and relationship flag YF03 off-domain", {
  j <- minimal_join()
  j$adds <- "rows"
  expect_identical(join_codes_of(list(j)), "YF03")
  j <- minimal_join()
  j$relationship <- "one-to-lots"
  expect_identical(join_codes_of(list(j)), "YF03")
  for (r in c("one-to-one", "one-to-many", "many-to-one", "many-to-many")) {
    j <- minimal_join()
    j$relationship <- r
    expect_identical(join_codes_of(list(j)), character(0), info = r)
  }
})

test_that("permitted_adds: variables-only fields flag YE08 on observations", {
  j <- minimal_join()
  j$adds <- "observations"
  expect_identical(join_codes_of(list(j)), "YE08")
  j$relationship <- NULL
  j$unmatched_ok <- TRUE
  expect_identical(join_codes_of(list(j)), "YE08")
  # an off-domain adds reports itself alone: no YE08 cascade, nothing demanded
  j <- minimal_join()
  j$adds <- "rows"
  expect_identical(join_codes_of(list(j)), "YF03")
})

test_that("shapes: keys must be a mapping; duplicate key columns flag YF04", {
  j <- minimal_join()
  j$keys <- "study"
  expect_identical(join_codes_of(list(j)), "YF02")
  j <- minimal_join()
  j$keys <- list(estimates = c("study", "study"), rob = "study_id")
  expect_identical(join_codes_of(list(j)), "YF04")
})

test_that("unknown fields in a join entry flag YE01", {
  j <- minimal_join()
  j$granularity <- "study"
  expect_identical(join_codes_of(list(j)), "YE01")
})

test_that("YX02: sides resolve against tables, keys against the side's pool", {
  j <- minimal_join()
  j$right <- "robb"
  j$keys <- list(estimates = "study", robb = "study_id")
  expect_identical(join_codes_of(list(j)), "YX02")
  j <- minimal_join()
  j$keys$rob <- "study_yd"
  expect_identical(join_codes_of(list(j)), "YX02")
  j <- minimal_join()
  j$keys$robb <- "study_id"
  expect_identical(join_codes_of(list(j)), "YX02")
})

test_that("YX03: keys must cover both sides", {
  j <- minimal_join()
  j$keys$rob <- NULL
  expect_identical(join_codes_of(list(j)), "YX03")
})

test_that("a join key may be another table's virtual column", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE))
  yaml::write_yaml(
    list(
      table = "estimates",
      source = list(file = "data/raw/estimates.csv"),
      levels = list(
        study_key = list(combine = c("author", "year"), separator = "_")
      ),
      columns = list(
        list(name = "author", type = "text"),
        list(name = "year", type = "integer")
      )
    ),
    file.path(dir, "estimates.yaml")
  )
  yaml::write_yaml(
    list(
      table = "rob",
      source = list(file = "data/raw/rob.csv"),
      columns = list(list(name = "study_id", type = "text"))
    ),
    file.path(dir, "rob.yaml")
  )
  dicts <- read_dictionaries(dir)
  j <- minimal_join()
  j$keys$estimates <- "study_key"
  joins <- joins_from_list(list(j), dicts)
  expect_identical(joins$keys_left[[1]], "study_key")
})

# ---- Layer 2: parsing, defaults, and curated fixtures ----

test_that("the good joins file parses into the tibble, defaults applied", {
  joins <- read_joins(joins_path("joins.yaml"), good_dictionaries())
  expect_identical(nrow(joins), 1L)
  expect_identical(joins$adds, "variables")
  expect_identical(joins$left, "estimates")
  expect_identical(joins$right, "rob")
  expect_identical(joins$keys_left[[1]], "study")
  expect_identical(joins$keys_right[[1]], "study_id")
  expect_identical(joins$relationship, "one-to-many")
  expect_false(joins$unmatched_ok)
  # the default: a join declaring no unmatched_ok gets FALSE
  j <- minimal_join()
  expect_false(joins_from_list(list(j))$unmatched_ok)
})

test_that("an observations join parses; relationship and unmatched_ok are NA", {
  joins <- read_joins(
    joins_path("joins-observations.yaml"),
    good_dictionaries()
  )
  expect_identical(joins$adds, "observations")
  expect_identical(joins$relationship, NA_character_)
  expect_identical(joins$unmatched_ok, NA)
})

test_that("a missing joins file is a valid single-table project: zero rows", {
  joins <- read_joins("no/such/joins.yaml", good_dictionaries())
  expect_identical(nrow(joins), 0L)
  expect_named(
    joins,
    c(
      "adds",
      "left",
      "right",
      "keys_left",
      "keys_right",
      "relationship",
      "unmatched_ok"
    )
  )
})

test_that("dictionaries must be rev_dictionary objects", {
  expect_error(
    read_joins(joins_path("joins.yaml"), list(1)),
    "rev_dictionary"
  )
})

test_that("each single-defect joins file aborts naming its problem", {
  dicts <- good_dictionaries()
  read_bad <- function(fixture) {
    read_joins(bad_path(fixture), dicts)
  }

  expect_snapshot(error = TRUE, read_bad("joins-yx02-unknown-table.yaml"))
  expect_snapshot(error = TRUE, read_bad("joins-yx02-unknown-key.yaml"))
  expect_snapshot(error = TRUE, read_bad("joins-yx02-keys-non-side.yaml"))
  expect_snapshot(error = TRUE, read_bad("joins-yx03-keys-missing-side.yaml"))
  expect_snapshot(error = TRUE, read_bad("joins-yf03-bad-relationship.yaml"))
  expect_snapshot(
    error = TRUE,
    read_bad("joins-ye08-relationship-on-observations.yaml")
  )
})

test_that("read_joins() distinguishes no dictionaries from zero dictionaries", {
  # NULL = within-file scope, references unchecked; an empty dictionary
  # set = resolve against nothing, every reference fails. Load-bearing.
  j <- minimal_join()
  expect_null(spec_problems(joins_from_list(list(j), NULL)))
  expect_identical(
    spec_codes(spec_problems(joins_from_list(list(j), list()))),
    "YX02"
  )
})

# Adopted from the adversarial battery (lawyer-16): the spec was silent,
# the determination is recorded in spec 5.4 - relationship is required
# on a variables join.
test_that("relationship is required on a variables join", {
  j <- minimal_join()
  j$relationship <- NULL
  expect_true("YE02" %in% join_codes_of(list(j)))
})
