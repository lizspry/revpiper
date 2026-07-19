bad_path <- function(fixture) {
  test_path("fixtures", "specs-bad", fixture)
}

# Problems collected from a spec-reading call, or NULL when it succeeds.
spec_problems <- function(expr) {
  tryCatch(
    {
      expr
      NULL
    },
    revpiper_spec_error = \(e) e$problems
  )
}

spec_codes <- function(problems) {
  if (is.null(problems)) character(0) else sort(unique(problems$code))
}
