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
    run_entry_checks(raw, "top", path, "top level"),
    run_context_checks(raw, "top", path),
    check_identifier_entries(raw, path),
    resolve_references(raw, path)
  )
  if (nrow(problems) > 0) {
    stop_spec(problems)
  }
  new_dictionary(raw, path)
}

#' Read and validate a directory of table dictionaries
#'
#' Loads every dictionary in `dir` standalone via [rev_read_dictionary()]
#' (each file validates with zero knowledge of the others), then runs the
#' data-free set-level check: no two files may claim the same table name.
#'
#' @param dir Directory containing table dictionary YAML files.
#' @return A named list of `rev_dictionary` objects, named by table.
#' @export
rev_read_dictionaries <- function(dir) {
  rlang::check_string(dir)
  if (!dir.exists(dir)) {
    cli::cli_abort(
      "Dictionary directory {.file {dir}} does not exist.",
      class = "revpiper_spec_error",
      call = NULL
    )
  }
  files <- sort(list.files(dir, pattern = "\\.ya?ml$", full.names = TRUE))
  dicts <- lapply(files, rev_read_dictionary)
  tables <- vapply(dicts, \(d) d$table, character(1))
  problems <- check_table_identity(tables, files)
  if (nrow(problems) > 0) {
    stop_spec(problems)
  }
  names(dicts) <- tables
  dicts
}

# Orchestration

# Run one field's form checks in gate order: empty, then shape, then domain
# and unique entries. Reports whether the field is sound enough for
# cross-field checks to read.
run_field_checks <- function(value, row, file, entry) {
  if (is.null(value)) {
    return(list(problems = check_empty(row, file, entry), ok = FALSE))
  }
  shape <- check_shape(value, row, file, entry)
  if (nrow(shape) > 0) {
    return(list(problems = shape, ok = FALSE))
  }
  list(
    problems = rbind(
      check_domain(value, row, file, entry),
      check_unique_entries(value, row, file, entry)
    ),
    ok = TRUE
  )
}

# The per-entry battery. Every check is one definition; the schema declares
# its instances. Gates: later checks assume earlier ones, so a malformed or
# banned field never has its content inspected (root cause reported once).
run_entry_checks <- function(x, level, file, entry) {
  schema <- field_schema(level)

  problems <- rbind(
    check_vocabulary(x, schema, file, entry),
    check_required(x, schema, file, entry)
  )

  present <- intersect(names(x), schema$field)
  ok <- logical(0)
  for (f in present) {
    row <- schema[schema$field == f, ]
    res <- run_field_checks(x[[f]], row, file, entry)
    problems <- rbind(problems, res$problems)
    ok[[f]] <- res$ok
  }

  problems <- rbind(problems, check_excludes(x, schema, file, entry))

  # Type-dependent checks: permission, then content, then order, each gated
  # on the one before.
  type <- if (isTRUE(ok["type"])) x[["type"]] else NULL
  type_valid <- !is.null(type) && type %in% schema_types()
  for (f in present) {
    row <- schema[schema$field == f, ]
    if (
      identical(row$permitted_types[[1]], "any") ||
        !isTRUE(ok[[f]]) ||
        !type_valid
    ) {
      next
    }
    permission <- check_permitted(type, row, file, entry)
    problems <- rbind(problems, permission)
    if (nrow(permission) > 0) {
      next
    }
    entries <- as.list(x[[f]])
    content <- check_content_typed(entries, type, row, file, entry)
    problems <- rbind(problems, content)
    if (nrow(content) > 0) {
      next
    }
    problems <- rbind(problems, check_ordered(entries, type, row, file, entry))
  }
  problems
}

# Recurse into fields whose schema row names a context: their contents are
# themselves entries to validate (source block, column entries). Fields
# without a context have user-chosen keys - data, not schema vocabulary.
run_context_checks <- function(x, level, file) {
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
        run_entry_checks(
          value,
          row$context,
          file,
          sprintf("%s block", row$field)
        )
      )
    }
    if (row$shape == "list_of_mappings") {
      problems <- rbind(
        problems,
        run_list_checks(value, row$context, file)
      )
    }
  }
  problems
}

# Validate each mapping in a list as its context, then police identity
# across the list.
run_list_checks <- function(entries, context, file) {
  if (!is_list_of_mappings(entries)) {
    return(no_problems()) # absence/shape already reported one level up
  }
  ids <- entry_names(entries, context)
  problems <- bind_problems(lapply(seq_along(entries), \(i) {
    run_entry_checks(
      entries[[i]],
      context,
      file,
      entry_label(ids[[i]], i, context)
    )
  }))
  rbind(problems, check_identity(ids, context, file))
}

# The entries' names where sound, else NA: an entry's name is the value of
# the field its schema marks identity, looked up once for the whole list.
entry_names <- function(entries, context) {
  context_schema <- field_schema(context)
  id_field <- context_schema$field[context_schema$identity]
  vapply(
    entries,
    \(entry) {
      id <- if (length(id_field) == 1) entry[[id_field]] else NULL
      if (is_string(id)) id else NA_character_
    },
    character(1)
  )
}

# Label an entry by its identity when sound, else by position.
entry_label <- function(id, i, context) {
  if (is.na(id)) {
    sprintf("%s entry %d", context, i)
  } else {
    sprintf("%s '%s'", context, id)
  }
}

# Label an identifier entry: the one home for the phrase every
# identifier check uses.
identifier_label <- function(identifier) {
  sprintf("identifier '%s'", identifier)
}

# YF: form checks (within one field)

# YF01: field declared with no value
check_empty <- function(row, file, entry) {
  if (row$empty_ok) {
    return(no_problems())
  }
  flag_problem(file, entry, "YF01", field = row$field)
}

# YF02: wrong shape or cardinality
check_shape <- function(value, row, file, entry) {
  if (matches_shape(value, row$shape, row$cardinality)) {
    return(no_problems())
  }
  flag_problem(
    file,
    entry,
    "YF02",
    field = row$field,
    expected = shape_phrase(row$shape, row$cardinality)
  )
}

matches_shape <- function(value, shape, cardinality) {
  if (shape == "mapping") {
    return(is_mapping(value))
  }
  if (shape == "list_of_mappings") {
    return(is_list_of_mappings(value))
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

# YF03: value outside its closed domain
check_domain <- function(value, row, file, entry) {
  domain <- row$domain[[1]]
  if (is.null(domain) || value %in% domain) {
    return(no_problems())
  }
  flag_problem(
    file,
    entry,
    "YF03",
    field = row$field,
    value = value,
    suggestion = suggest_name(value, domain)
  )
}

# YF04: duplicate entries within a list field
check_unique_entries <- function(value, row, file, entry) {
  if (!row$unique_entries) {
    return(no_problems())
  }
  entry_lists <- if (row$shape == "mapping") value else list(value)
  problems <- no_problems()
  for (l in entry_lists) {
    flat <- unlist(l)
    dupes <- unique(flat[duplicated(flat)])
    if (length(dupes) > 0) {
      problems <- rbind(
        problems,
        flag_problem(
          file,
          entry,
          "YF04",
          field = row$field,
          dupes = paste0("'", dupes, "'", collapse = ", ")
        )
      )
    }
  }
  problems
}

# YF05: range descending
check_ordered <- function(entries, type, row, file, entry) {
  if (!identical(row$ordered, "ascending") || !is_descending(entries, type)) {
    return(no_problems())
  }
  flag_problem(
    file,
    entry,
    "YF05",
    field = row$field,
    high = entries[[1]],
    low = entries[[2]]
  )
}

is_descending <- function(entries, type) {
  if (type == "date") {
    as.Date(entries[[1]], format = "%Y-%m-%d") >
      as.Date(entries[[2]], format = "%Y-%m-%d")
  } else {
    entries[[1]] > entries[[2]]
  }
}

# YE: entry checks (across fields within one entry)

# YE01: unknown field name
check_vocabulary <- function(x, schema, file, entry) {
  bad <- setdiff(names(x), schema$field)
  bind_problems(lapply(bad, \(f) {
    flag_problem(
      file,
      entry,
      "YE01",
      field = f,
      suggestion = suggest_name(f, schema$field)
    )
  }))
}

# YE02: required field absent
check_required <- function(x, schema, file, entry) {
  absent <- setdiff(schema$field[schema$required], names(x))
  bind_problems(lapply(absent, \(f) {
    flag_problem(file, entry, "YE02", field = f)
  }))
}

# YE03: constraint on a column type outside its permitted set
check_permitted <- function(type, row, file, entry) {
  if (type %in% row$permitted_types[[1]]) {
    return(no_problems())
  }
  flag_problem(file, entry, "YE03", field = row$field, type = type)
}

# YE04: mutually exclusive fields both present
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
    flag_problem(file, entry, "YE04", field1 = p[1], field2 = p[2])
  }))
}

# YE05: constraint entries do not match the declared type
check_content_typed <- function(entries, type, row, file, entry) {
  if (!row$content_typed || matches_type(entries, type)) {
    return(no_problems())
  }
  flag_problem(file, entry, "YE05", field = row$field, type = type)
}

# Spec-internal only: nothing here reads data.
matches_type <- function(entries, type) {
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

# YE06: identifier entry neither a column name nor a combine block. A string
# resolves as a reference (YS02); a mapping validates as the combine
# context and registers a virtual column named by its identifier.
check_identifier_entries <- function(raw, file) {
  if (!is_mapping(raw$identifiers)) {
    return(no_problems()) # absence/shape already reported
  }
  bind_problems(lapply(names(raw$identifiers), \(identifier) {
    value <- raw$identifiers[[identifier]]
    if (is_string(value)) {
      return(no_problems())
    }
    if (is_mapping(value)) {
      return(run_entry_checks(
        value,
        "combine",
        file,
        identifier_label(identifier)
      ))
    }
    flag_problem(file, "identifiers block", "YE06", identifier = identifier)
  }))
}

# YS: source checks (across entries within one file)

# YS01: duplicate identity within one source file
check_identity <- function(ids, context, file) {
  dupes <- unique(ids[duplicated(ids) & !is.na(ids)])
  bind_problems(lapply(dupes, \(d) {
    flag_problem(
      file,
      sprintf("%ss block", context),
      "YS01",
      context = context,
      id = d
    )
  }))
}

# One resolver for every schema row with a refers_to: gather that field's
# instances from the raw dictionary and resolve each value against the
# declared collection. A NULL collection means only that its declaring
# block is malformed - that root cause is already reported, so resolution
# skips rather than cascading.
resolve_references <- function(raw, file) {
  s <- schema_fields()
  referring <- s[!is.na(s$refers_to), ]
  needed <- unique(referring$refers_to)
  collections <- lapply(needed, \(name) declared_collection(raw, name))
  names(collections) <- needed
  problems <- no_problems()
  for (i in seq_len(nrow(referring))) {
    row <- referring[i, ]
    collection <- collections[[row$refers_to]]
    if (is.null(collection)) {
      next
    }
    for (instance in reference_instances(raw, row$field)) {
      problems <- rbind(
        problems,
        check_reference(
          instance$values,
          collection,
          row$refers_to,
          file,
          instance$entry
        )
      )
    }
  }
  problems
}

# YS02: a value does not name a declared collection member
check_reference <- function(values, collection, collection_name, file, entry) {
  bad <- setdiff(values, collection)
  bind_problems(lapply(bad, \(v) {
    flag_problem(
      file,
      entry,
      "YS02",
      value = v,
      collection = collection_name,
      suggestion = suggest_name(v, collection)
    )
  }))
}

# Where each referring field's values live in a raw dictionary. Instances
# are gathered only from well-shaped containers: a malformed container's
# own problem is already reported. An unlisted field is the loud gap alarm
# for future refers_to schema rows.
reference_instances <- function(raw, field) {
  switch(
    field,
    identifiers = {
      if (!is_mapping(raw$identifiers)) {
        return(list())
      }
      strings <- Filter(is_string, raw$identifiers)
      lapply(strings, \(v) list(values = v, entry = "identifiers block"))
    },
    levels = {
      if (!is_mapping(raw$levels)) {
        return(list())
      }
      keys <- Filter(is.character, lapply(raw$levels, unlist))
      lapply(keys, \(v) list(values = v, entry = "levels block"))
    },
    constant_within_level = {
      if (!is_list_of_mappings(raw$columns)) {
        return(list())
      }
      ids <- entry_names(raw$columns, "column")
      instances <- lapply(seq_along(raw$columns), \(i) {
        value <- raw$columns[[i]]$constant_within_level
        if (!is_string(value)) {
          return(NULL)
        }
        list(values = value, entry = entry_label(ids[[i]], i, "column"))
      })
      Filter(Negate(is.null), instances)
    },
    combine = {
      if (!is_mapping(raw$identifiers)) {
        return(list())
      }
      instances <- lapply(names(raw$identifiers), \(identifier) {
        block <- raw$identifiers[[identifier]]
        if (!is_mapping(block)) {
          return(NULL)
        }
        parts <- unlist(block$combine)
        if (!is.character(parts)) {
          return(NULL)
        }
        list(values = parts, entry = identifier_label(identifier))
      })
      Filter(Negate(is.null), instances)
    },
    cli::cli_abort(
      "Internal error: no reference walker for field {.val {field}}."
    )
  )
}

# A declared collection by its refers_to name. The unknown-name abort is
# the loud gap alarm for future refers_to vocabulary: a new collection must
# be wired here deliberately, never skipped silently.
declared_collection <- function(raw, name) {
  switch(
    name,
    columns = declared_columns(raw),
    levels = declared_levels(raw),
    cli::cli_abort(
      "Internal error: no declared collection named {.val {name}}."
    )
  )
}

# Declared column names, or NULL when the columns block is malformed.
declared_columns <- function(raw) {
  if (!is_list_of_mappings(raw$columns)) {
    return(NULL)
  }
  ids <- entry_names(raw$columns, "column")
  ids[!is.na(ids)]
}

# Declared level names: absent levels is a legal empty collection, but a
# malformed block is NULL (skip, root cause already reported).
declared_levels <- function(raw) {
  if (is.null(raw$levels)) {
    return(character(0))
  }
  if (!is_mapping(raw$levels)) {
    return(NULL)
  }
  names(raw$levels)
}

# YX: cross-source checks (across files)

# YX01: two spec files claim the same table name. Deliberately not
# check_identity: code, params, entry label, and file semantics all differ,
# and set-level tables are never NA (table is required per file).
check_table_identity <- function(tables, files) {
  dupes <- unique(tables[duplicated(tables)])
  bind_problems(lapply(dupes, \(d) {
    flag_problem(
      paste(basename(files[tables == d]), collapse = ", "),
      "dictionary set",
      "YX01",
      table = d
    )
  }))
}

# YX02 (cross-source references) arrives with rev_read_joins() in Task 5.

# Plumbing

# Zero-row problems table: the rbind seed guaranteeing a stable shape.
no_problems <- function() {
  new_problem(
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

is_list_of_mappings <- function(x) {
  is.list(x) && length(x) >= 1 && all(vapply(x, is_mapping, logical(1)))
}

is_string <- function(x) {
  is.character(x) && length(x) == 1
}

# Constructor

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
      identifiers = raw$identifiers %||% list(),
      levels = raw$levels %||% list(),
      columns = columns,
      path = path
    ),
    class = "rev_dictionary"
  )
}

# Columns usable as keys: every declared column, plus the virtual column
# each combine identifier registers (named by its identifier).
dictionary_key_columns <- function(dict) {
  virtual <- names(Filter(is_mapping, dict$identifiers))
  c(dict$columns$name, virtual)
}
