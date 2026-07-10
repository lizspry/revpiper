spec_types <- c("text", "integer", "decimal", "boolean", "date")
dict_fields <- c("table", "description", "source", "roles", "levels", "columns")
source_fields <- c("file", "sheet", "reader")
column_fields <- c(
  "name",
  "type",
  "values",
  "range",
  "units",
  "required",
  "unique",
  "missing",
  "constant_within_level",
  "description"
)

#' Read and validate one table dictionary
#'
#' Parses `specs/tables/<table>.yaml` into a `rev_dictionary`, collecting
#' every spec problem before aborting so the user sees all of them at once.
#'
#' @param path Path to a single table's dictionary YAML file.
#' @return A `rev_dictionary` object.
#' @export
rev_read_dictionary <- function(path) {
  rlang::check_string(path)
  if (!file.exists(path)) {
    cli::cli_abort(
      "Dictionary file {.file {path}} does not exist.",
      class = "revpiper_spec_error",
      call = NULL
    )
  }
  raw <- yaml::read_yaml(path)
  problems <- rbind(
    check_known_fields(raw, dict_fields, path, "top level"),
    check_required_fields(raw, c("table", "source", "columns"), path),
    check_source_block(raw$source, path),
    check_columns_block(raw$columns, path)
  )
  if (nrow(problems) > 0) {
    stop_spec(problems)
  }
  new_dictionary(raw, path)
}

# Zero-row problems table: the rbind seed guaranteeing a stable shape.
no_problems <- function() {
  spec_problem(
    character(0),
    character(0),
    character(0),
    character(0),
    suggestion = character(0)
  )
}

bind_problems <- function(problem_list) {
  do.call(rbind, c(list(no_problems()), problem_list))
}

check_known_fields <- function(x, known, file, entry) {
  bad <- setdiff(names(x), known)
  bind_problems(lapply(bad, \(f) {
    spec_problem(
      file,
      entry,
      "Y001",
      sprintf("unknown field '%s'", f),
      suggestion = suggest_name(f, known)
    )
  }))
}

check_required_fields <- function(x, required, file, entry = "top level") {
  absent <- setdiff(required, names(x))
  bind_problems(lapply(absent, \(f) {
    spec_problem(file, entry, "Y017", sprintf("missing required field '%s'", f))
  }))
}

# A field written in the yaml but left without a value parses to NULL;
# that is an error, not a silent absence (description exempt: draft
# skeletons carry empty descriptions by design).
check_empty_fields <- function(x, file, entry, exempt = "description") {
  present <- names(x)
  empty <- present[vapply(x, is.null, logical(1))]
  empty <- setdiff(empty, exempt)
  bind_problems(lapply(empty, \(f) {
    spec_problem(
      file,
      entry,
      "Y020",
      sprintf("field '%s' is declared but has no value", f)
    )
  }))
}

check_source_block <- function(source, file) {
  if (is.null(source)) {
    return(no_problems()) # absence is already Y017 at the top level
  }
  problems <- check_known_fields(source, source_fields, file, "source block")
  if (is.null(source$file)) {
    problems <- rbind(
      problems,
      spec_problem(
        file,
        "source block",
        "Y019",
        "missing required field 'file'"
      )
    )
  }
  problems
}

check_columns_block <- function(columns, file) {
  if (is.null(columns)) {
    return(no_problems()) # absence is already Y017 at the top level
  }
  problems <- bind_problems(lapply(columns, check_column, file = file))

  names_vec <- vapply(
    columns,
    \(col) {
      if (is.null(col$name)) NA_character_ else as.character(col$name)
    },
    character(1)
  )
  unnamed <- which(is.na(names_vec) | !nzchar(names_vec))
  problems <- rbind(
    problems,
    bind_problems(lapply(unnamed, \(i) {
      spec_problem(
        file,
        "columns block",
        "Y012",
        sprintf("column entry %d has no name", i)
      )
    }))
  )
  duplicates <- unique(names_vec[duplicated(names_vec) & !is.na(names_vec)])
  rbind(
    problems,
    bind_problems(lapply(duplicates, \(d) {
      spec_problem(
        file,
        "columns block",
        "Y012",
        sprintf("duplicate column name '%s'", d)
      )
    }))
  )
}

check_column <- function(col, file) {
  entry <- sprintf("column '%s'", col$name %||% "<unnamed>")
  problems <- rbind(
    check_known_fields(col, column_fields, file, entry),
    check_required_fields(col, "type", file, entry),
    check_empty_fields(col, file, entry)
  )
  # Y003 is type-independent, so it reports even when the type is missing.
  if (!is.null(col$values) && !is.null(col$range)) {
    problems <- rbind(
      problems,
      spec_problem(
        file,
        entry,
        "Y003",
        "'values' and 'range' are mutually exclusive"
      )
    )
  }
  if (is.null(col$type)) {
    return(problems) # type-dependent checks need a type
  }
  if (!col$type %in% spec_types) {
    problems <- rbind(
      problems,
      spec_problem(
        file,
        entry,
        "Y002",
        sprintf("unknown type '%s'", col$type),
        suggestion = suggest_name(col$type, spec_types)
      )
    )
  }
  if (!is.null(col$values) && isTRUE(col$type %in% c("boolean", "date"))) {
    problems <- rbind(
      problems,
      spec_problem(
        file,
        entry,
        "Y004",
        sprintf("'values' is not allowed on type '%s'", col$type)
      )
    )
  }
  if (!is.null(col$range) && isTRUE(col$type %in% c("text", "boolean"))) {
    problems <- rbind(
      problems,
      spec_problem(
        file,
        entry,
        "Y005",
        sprintf("'range' is not allowed on type '%s'", col$type)
      )
    )
  }
  if (!is.null(col$units) && !isTRUE(col$type %in% c("integer", "decimal"))) {
    problems <- rbind(
      problems,
      spec_problem(
        file,
        entry,
        "Y006",
        "'units' is only allowed on integer/decimal"
      )
    )
  }
  rbind(problems, check_values_range_types(col, file, entry))
}

# Do the values/range declarations cohere with the declared type?
# Spec-internal only: nothing here reads data.
check_values_range_types <- function(col, file, entry) {
  problems <- no_problems()
  if (!is.null(col$values)) {
    vals <- as.list(col$values)
    classes <- unique(vapply(vals, \(v) class(v)[1], character(1)))
    if (length(vals) == 0) {
      problems <- rbind(
        problems,
        spec_problem(file, entry, "Y007", "'values' must not be empty")
      )
    } else if (length(classes) > 1) {
      problems <- rbind(
        problems,
        spec_problem(
          file,
          entry,
          "Y007",
          "'values' entries must all be of one type"
        )
      )
    } else if (
      isTRUE(col$type %in% c("text", "integer", "decimal")) &&
        !values_match_type(vals, col$type)
    ) {
      problems <- rbind(
        problems,
        spec_problem(
          file,
          entry,
          "Y007",
          sprintf("'values' entries do not match declared type '%s'", col$type)
        )
      )
    }
  }
  if (!is.null(col$range)) {
    rng <- as.list(col$range)
    if (length(rng) != 2) {
      problems <- rbind(
        problems,
        spec_problem(
          file,
          entry,
          "Y007",
          "'range' must have exactly two entries"
        )
      )
    } else if (isTRUE(col$type %in% c("integer", "decimal"))) {
      if (!values_match_type(rng, col$type)) {
        problems <- rbind(
          problems,
          spec_problem(
            file,
            entry,
            "Y007",
            sprintf("'range' entries do not match declared type '%s'", col$type)
          )
        )
      } else if (rng[[1]] > rng[[2]]) {
        problems <- rbind(
          problems,
          spec_problem(
            file,
            entry,
            "Y008",
            sprintf("'range' is descending (%s > %s)", rng[[1]], rng[[2]])
          )
        )
      }
    }
  }
  problems
}

values_match_type <- function(vals, type) {
  ok <- switch(
    type,
    text = vapply(vals, is.character, logical(1)),
    integer = vapply(
      vals,
      \(v) is.numeric(v) && isTRUE(v %% 1 == 0),
      logical(1)
    ),
    decimal = vapply(vals, is.numeric, logical(1))
  )
  all(ok)
}

new_dictionary <- function(raw, path) {
  columns <- do.call(
    rbind,
    lapply(raw$columns, \(col) {
      tibble::tibble(
        name = col$name,
        type = col$type,
        values = list(col$values),
        range = list(col$range),
        units = col$units %||% NA_character_,
        required = col$required %||% FALSE,
        unique = col$unique %||% FALSE,
        missing = list(col$missing %||% character(0)),
        constant_within_level = col$constant_within_level %||% NA_character_,
        description = col$description %||% NA_character_
      )
    })
  )
  structure(
    list(
      table = raw$table,
      description = raw$description %||% NA_character_,
      source = list(
        file = raw$source$file,
        sheet = raw$source$sheet,
        reader = raw$source$reader
      ),
      roles = raw$roles %||% list(),
      levels = raw$levels %||% list(),
      columns = columns,
      path = path
    ),
    class = "rev_dictionary"
  )
}
