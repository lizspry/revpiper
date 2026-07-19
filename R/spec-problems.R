# Closest of `known` within edit distance 2 (case-insensitive), or NA.
suggest_name <- function(name, known) {
  if (length(known) == 0) {
    return(NA_character_)
  }
  d <- utils::adist(tolower(name), tolower(known))[1, ]
  if (min(d) <= 2) known[which.min(d)] else NA_character_
}

# One problem, one row: the raw constructor for the fixed problem schema.
new_problem <- function(
  file,
  entry,
  code,
  message,
  suggestion = NULL,
  related = NULL
) {
  tibble::tibble(
    file = file,
    entry = entry,
    code = code,
    message = message,
    suggestion = suggestion %||% NA_character_,
    related = related %||% NA_character_
  )
}

# Zero-row problems table: the rbind seed guaranteeing a stable shape.
no_problems <- function() {
  new_problem(
    character(0),
    character(0),
    character(0),
    character(0),
    suggestion = character(0),
    related = character(0)
  )
}

bind_problems <- function(problem_list) {
  do.call(rbind, c(list(no_problems()), problem_list))
}

# Rule 1 of the related column (design 2026-07-19): a plain fact of
# location, never causation. Rule 2 (set at flag time) wins where present.
relate_same_entry <- function(problems) {
  key <- paste(problems$file, problems$entry, sep = "\r")
  shared <- key %in% key[duplicated(key)]
  fill <- shared & is.na(problems$related)
  problems$related[fill] <- "other error in this entry"
  problems
}

# Every spec-error abort ends with the same pointer (decision 2026-07-13):
# the one home for the footer's wording.
spec_error_footer <- c(
  i = "Canonical spec examples ship with the package:
       {.code system.file(\"extdata\", \"specs-example\",
       package = \"revpiper\")}"
)

# Abort (spec-error class) when a required input path is absent; `what`
# names the path's role in the message, `found` its existence test
# (dir.exists(path) for directories).
stop_missing_path <- function(what, path, found = file.exists(path)) {
  if (found) {
    return(invisible(NULL))
  }
  cli::cli_abort(
    c("{what} {.file {path}} does not exist.", spec_error_footer),
    class = "revpiper_spec_error",
    call = NULL
  )
}
