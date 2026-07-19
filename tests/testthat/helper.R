bad_path <- function(fixture) {
  test_path("fixtures", "specs-bad", fixture)
}

# A reader result's problems (readers return list(value, problems) and
# never throw on spec problems — design 2026-07-19).
spec_problems <- function(result) {
  result$problems
}

spec_codes <- function(problems) {
  if (is.null(problems)) character(0) else sort(unique(problems$code))
}
