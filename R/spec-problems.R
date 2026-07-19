# Closest of `known` within edit distance 2 (case-insensitive), or NA.
suggest_name <- function(name, known) {
  # An NA value can reach here via a reference list containing YAML .na
  # (review finding, 2026-07-19): no suggestion, never a raw error.
  if (is.na(name) || length(known) == 0) {
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

# The related column's phrases: the one home (Liz, 2026-07-19). Every
# phrase is self-contained — a checked fact plus what fixing it may do,
# never a guessed cause. A future rule adds its phrase here. Lines run
# long because a phrase lives whole (never composed from fragments,
# conventions §Style) — the one rule outranks the other here.
# nolint start: line_length_linter.
related_phrases <- list(
  same_entry = "another error sits in this entry \u2014 fixing it may clear this one",
  incomplete_columns = "a column entry's name cannot be read, so this search ran against an incomplete list \u2014 fixing it may clear this one",
  incomplete_file = "spec file %s failed its checks, so its table was not available to search"
)
# nolint end

# Rule 1 of the related column (design 2026-07-19): a plain fact of
# location, never causation. Rule 2 (set at flag time) wins where present.
relate_same_entry <- function(problems) {
  key <- paste(problems$file, problems$entry, sep = "\r")
  shared <- key %in% key[duplicated(key)]
  fill <- shared & is.na(problems$related)
  problems$related[fill] <- related_phrases$same_entry
  problems
}

# Every usage-error abort ends with the same pointer (reworded per the
# 2026-07-19 UX design): the one home for the footer's wording. Spec
# problems carry no footer — they are report rows, not errors.
spec_error_footer <- c(
  i = "See {.code ?rev_spec_run} for the expected spec layout,
       with correctly formatted examples."
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
