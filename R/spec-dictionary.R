#' Read and validate one table dictionary
#'
#' Parses `specs/tables/<table>.yaml` into a `rev_dictionary`, collecting
#' every spec problem before aborting so the user sees all of them at once.
#' Validation is complete for a single source: one file validates with zero
#' knowledge of any other source.
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
    check_entry(raw, "top", path, "top level"),
    check_contexts(raw, "top", path)
  )
  if (nrow(problems) > 0) {
    stop_spec(problems)
  }
  new_dictionary(raw, path)
}

# Recurse into fields whose schema row names a context: their contents are
# themselves entries to validate (source block, column entries). Fields
# without a context have user-chosen keys - data, not schema vocabulary.
check_contexts <- function(x, level, file) {
  schema <- field_schema(level)
  problems <- no_problems()
  for (i in seq_len(nrow(schema))) {
    row <- schema[i, ]
    if (is.na(row$context)) {
      next
    }
    value <- x[[row$field]]
    if (row$shape == "mapping" && is_mapping(value)) {
      problems <- rbind(
        problems,
        check_entry(value, row$context, file, sprintf("%s block", row$field))
      )
    }
    if (row$shape == "list_of_mappings") {
      problems <- rbind(
        problems,
        check_mapping_list(value, row$context, file)
      )
    }
  }
  problems
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

is_mapping <- function(x) {
  is.list(x) && !is.null(names(x)) && all(nzchar(names(x)))
}

# ---- The per-context battery: every check is one definition; the schema ----
# ---- declares its instances. Gates: later checks assume earlier ones.  ----

check_entry <- function(x, level, file, entry) {
  schema <- field_schema(level)

  problems <- rbind(
    check_vocabulary(x, schema, file, entry), # YE01
    check_required(x, schema, file, entry) # YE02
  )

  # Per-field form: empty (YF01), shape/cardinality (YF02), domain (YF03),
  # unique entries (YF04). Records which fields are well-formed.
  present <- intersect(names(x), schema$field)
  ok <- logical(0)
  for (f in present) {
    row <- schema[schema$field == f, ]
    res <- check_field_form(x[[f]], row, file, entry)
    problems <- rbind(problems, res$problems)
    ok[[f]] <- res$ok
  }

  problems <- rbind(problems, check_excludes(x, schema, file, entry)) # YE04

  # Type-dependent checks: permission (YE03), then content (YE05) and order
  # (YF05), each gated on the previous — a banned or malformed constraint
  # never has its content inspected (root cause reported once).
  type <- if (isTRUE(ok["type"])) x[["type"]] else NULL
  type_valid <- !is.null(type) && type %in% schema_types()
  for (f in present) {
    row <- schema[schema$field == f, ]
    permitted <- row$permitted_types[[1]]
    if (identical(permitted, "any") || !isTRUE(ok[[f]]) || !type_valid) {
      next
    }
    if (!type %in% permitted) {
      problems <- rbind(
        problems,
        spec_problem(
          file,
          entry,
          "YE03",
          sprintf("'%s' is not allowed on type '%s'", f, type)
        )
      )
      next
    }
    entries <- as.list(x[[f]])
    if (row$content_typed && !values_match_type(entries, type)) {
      problems <- rbind(
        problems,
        spec_problem(
          file,
          entry,
          "YE05",
          sprintf("'%s' entries do not match declared type '%s'", f, type)
        )
      )
      next
    }
    if (identical(row$ordered, "ascending") && is_descending(entries, type)) {
      problems <- rbind(
        problems,
        spec_problem(
          file,
          entry,
          "YF05",
          sprintf(
            "'%s' is descending (%s > %s)",
            f,
            entries[[1]],
            entries[[2]]
          )
        )
      )
    }
  }
  problems
}

check_vocabulary <- function(x, schema, file, entry) {
  bad <- setdiff(names(x), schema$field)
  bind_problems(lapply(bad, \(f) {
    spec_problem(
      file,
      entry,
      "YE01",
      sprintf("unknown field '%s'", f),
      suggestion = suggest_name(f, schema$field)
    )
  }))
}

check_required <- function(x, schema, file, entry) {
  absent <- setdiff(schema$field[schema$required], names(x))
  bind_problems(lapply(absent, \(f) {
    spec_problem(file, entry, "YE02", sprintf("missing required field '%s'", f))
  }))
}

check_excludes <- function(x, schema, file, entry) {
  pairs <- list()
  for (i in seq_len(nrow(schema))) {
    f <- schema$field[i]
    targets <- schema$excludes[[i]]
    if (is.null(targets) || is.null(x[[f]])) {
      next
    }
    for (target in targets) {
      if (!is.null(x[[target]])) {
        pairs[[length(pairs) + 1]] <- sort(c(f, target))
      }
    }
  }
  pairs <- unique(pairs)
  bind_problems(lapply(pairs, \(p) {
    spec_problem(
      file,
      entry,
      "YE04",
      sprintf("'%s' and '%s' are mutually exclusive", p[1], p[2])
    )
  }))
}

# One field's own form: empty (YF01), shape and cardinality (YF02), domain
# (YF03), duplicate entries (YF04). Returns problems plus whether the field
# is sound enough for cross-field checks to read.
check_field_form <- function(value, row, file, entry) {
  f <- row$field
  if (is.null(value)) {
    if (row$empty_ok) {
      return(list(problems = no_problems(), ok = FALSE))
    }
    return(list(
      problems = spec_problem(
        file,
        entry,
        "YF01",
        sprintf("field '%s' is declared but has no value", f)
      ),
      ok = FALSE
    ))
  }
  if (!shape_ok(value, row$shape, row$cardinality)) {
    return(list(
      problems = spec_problem(
        file,
        entry,
        "YF02",
        sprintf(
          "field '%s' must be %s",
          f,
          shape_phrase(row$shape, row$cardinality)
        )
      ),
      ok = FALSE
    ))
  }
  problems <- no_problems()
  domain <- row$domain[[1]]
  if (!is.null(domain) && !value %in% domain) {
    problems <- rbind(
      problems,
      spec_problem(
        file,
        entry,
        "YF03",
        sprintf("unknown %s '%s'", f, value),
        suggestion = suggest_name(value, domain)
      )
    )
  }
  if (row$unique_entries) {
    entry_lists <- if (row$shape == "mapping") value else list(value)
    for (l in entry_lists) {
      flat <- unlist(l)
      dupes <- unique(flat[duplicated(flat)])
      if (length(dupes) > 0) {
        problems <- rbind(
          problems,
          spec_problem(
            file,
            entry,
            "YF04",
            sprintf(
              "field '%s' has duplicate entries: %s",
              f,
              paste0("'", dupes, "'", collapse = ", ")
            )
          )
        )
      }
    }
  }
  list(problems = problems, ok = TRUE)
}

shape_ok <- function(value, shape, cardinality) {
  if (shape == "mapping") {
    return(is_mapping(value))
  }
  if (shape == "list_of_mappings") {
    return(
      is.list(value) &&
        length(value) >= 1 &&
        all(vapply(value, is_mapping, logical(1)))
    )
  }
  entries <- if (is.list(value)) value else as.list(value)
  n_ok <- switch(
    cardinality,
    one = length(entries) == 1,
    one_or_many = length(entries) >= 1,
    two = length(entries) == 2
  )
  if (!n_ok) {
    return(FALSE)
  }
  element_ok <- switch(
    shape,
    string = \(e) is.character(e) && length(e) == 1 && !is.na(e),
    boolean = \(e) is.logical(e) && length(e) == 1 && !is.na(e),
    scalar = \(e) is.atomic(e) && length(e) == 1 && !is.na(e)
  )
  all(vapply(entries, element_ok, logical(1)))
}

shape_phrase <- function(shape, cardinality) {
  if (shape %in% c("mapping", "list_of_mappings")) {
    return(switch(
      shape,
      mapping = "a group of key: value fields",
      list_of_mappings = "a list of entries"
    ))
  }
  kind <- switch(
    shape,
    string = "text value",
    boolean = "true/false value",
    scalar = "value"
  )
  switch(
    cardinality,
    one = paste("a single", kind),
    one_or_many = paste0("one or more ", kind, "s"),
    two = paste0("exactly two ", kind, "s")
  )
}

check_mapping_list <- function(entries, ctx, file) {
  if (
    !is.list(entries) ||
      length(entries) == 0 ||
      !all(vapply(entries, is_mapping, logical(1)))
  ) {
    return(no_problems()) # absence/shape already reported one level up
  }
  ctx_schema <- field_schema(ctx)
  id_field <- ctx_schema$field[ctx_schema$identity]
  id_of <- function(e) {
    id <- if (length(id_field) == 1) e[[id_field]] else NULL
    if (is.character(id) && length(id) == 1) id else NA_character_
  }
  problems <- bind_problems(lapply(seq_along(entries), \(i) {
    id <- id_of(entries[[i]])
    label <- if (is.na(id)) {
      sprintf("%s entry %d", ctx, i)
    } else {
      sprintf("%s '%s'", ctx, id)
    }
    check_entry(entries[[i]], ctx, file, label)
  }))

  # YS01 - identity at file scope: duplicate identities within the list.
  ids <- vapply(entries, id_of, character(1))
  dupes <- unique(ids[duplicated(ids) & !is.na(ids)])
  rbind(
    problems,
    bind_problems(lapply(dupes, \(d) {
      spec_problem(
        file,
        sprintf("%ss block", ctx),
        "YS01",
        sprintf("duplicate %s name '%s'", ctx, d)
      )
    }))
  )
}

# Do a constraint's entries cohere with the declared column type?
# Spec-internal only: nothing here reads data.
values_match_type <- function(entries, type) {
  ok <- switch(
    type,
    text = vapply(entries, is.character, logical(1)),
    integer = vapply(
      entries,
      \(v) is.numeric(v) && isTRUE(v %% 1 == 0),
      logical(1)
    ),
    decimal = vapply(entries, is.numeric, logical(1)),
    date = vapply(
      entries,
      \(v) is.character(v) && is_iso_date(v),
      logical(1)
    )
  )
  all(ok)
}

# Strict ISO YYYY-MM-DD: must parse AND survive the round trip (decision 5).
is_iso_date <- function(x) {
  parsed <- as.Date(x, format = "%Y-%m-%d")
  !is.na(parsed) && format(parsed, "%Y-%m-%d") == x
}

is_descending <- function(entries, type) {
  if (type == "date") {
    as.Date(entries[[1]], format = "%Y-%m-%d") >
      as.Date(entries[[2]], format = "%Y-%m-%d")
  } else {
    entries[[1]] > entries[[2]]
  }
}

new_dictionary <- function(raw, path) {
  col_schema <- field_schema("column")
  default_of <- function(f) col_schema$default[[which(col_schema$field == f)]]
  columns <- do.call(
    rbind,
    lapply(raw$columns, \(col) {
      tibble::tibble(
        name = col$name,
        type = col$type,
        values = list(if (is.null(col$values)) NULL else unlist(col$values)),
        range = list(if (is.null(col$range)) NULL else unlist(col$range)),
        units = col$units %||% NA_character_,
        required = col$required %||% default_of("required"),
        unique = col$unique %||% default_of("unique"),
        missing = list(as.character(unlist(
          col$missing %||% default_of("missing")
        ))),
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
