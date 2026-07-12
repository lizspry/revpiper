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
  read_dictionary(tmp)
}

problems_of <- function(dict) {
  spec_problems(read_dict(dict))
}

codes_of <- function(dict) {
  spec_codes(problems_of(dict))
}
