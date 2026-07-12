# Closest of `known` within edit distance 2 (case-insensitive), or NA.
suggest_name <- function(name, known) {
  if (length(known) == 0) {
    return(NA_character_)
  }
  d <- utils::adist(tolower(name), tolower(known))[1, ]
  if (min(d) <= 2) known[which.min(d)] else NA_character_
}

# One problem, one row: the raw constructor for the fixed problem schema.
new_problem <- function(file, entry, code, message, suggestion = NULL) {
  tibble::tibble(
    file = file,
    entry = entry,
    code = code,
    message = message,
    suggestion = suggestion %||% NA_character_
  )
}

# Throw once, listing every accumulated problem with its fix route.
stop_spec <- function(problems) {
  hint <- ifelse(
    is.na(problems$suggestion),
    "",
    sprintf(" (did you mean '%s'?)", problems$suggestion)
  )
  lines <- sprintf(
    "%s %s / %s: %s%s",
    problems$code,
    problems$file,
    problems$entry,
    problems$message,
    hint
  )
  names(lines) <- rep("x", length(lines))
  cli::cli_abort(
    c("Spec validation failed ({nrow(problems)} problem{?s}):", lines),
    class = "revpiper_spec_error",
    call = NULL,
    problems = problems
  )
}

# Abort (spec-error class) when a required input file is absent; `what`
# names the file's role in the message.
stop_missing_file <- function(what, path) {
  if (file.exists(path)) {
    return(invisible(NULL))
  }
  cli::cli_abort(
    "{what} {.file {path}} does not exist.",
    class = "revpiper_spec_error",
    call = NULL
  )
}
