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
run_entry_checks <- function(x, kind, file, entry) {
  schema <- field_schema(kind)

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

  problems <- rbind(
    problems,
    check_excludes(x, schema, file, entry),
    check_requires(x, schema, file, entry),
    check_permitted_adds(x, schema, file, entry)
  )

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

# Recurse into container fields - those whose schema row says what kind of
# entry they contain (source holds a source entry; columns holds column
# entries). Container fields with no contains kind have user-chosen keys -
# data, not schema vocabulary.
run_contents_checks <- function(x, kind, file) {
  schema <- field_schema(kind)
  problems <- no_problems()
  for (i in seq_len(nrow(schema))) {
    row <- schema[i, ]
    if (is.na(row$contains)) {
      next
    }
    value <- x[[row$field]]
    if (row$shape == "mapping" && is_mapping(value)) {
      problems <- rbind(
        problems,
        run_entry_checks(
          value,
          row$contains,
          file,
          sprintf("%s section", row$field)
        )
      )
    }
    if (row$shape == "list_of_mappings") {
      problems <- rbind(
        problems,
        run_list_checks(value, row$contains, file)
      )
    }
  }
  problems
}

# Validate each mapping in a list as its kind, then police identity
# across the list.
run_list_checks <- function(entries, kind, file) {
  if (!is_list_of_mappings(entries)) {
    return(no_problems()) # absence/shape already reported by the container
  }
  ids <- entry_names(entries, kind)
  problems <- bind_problems(lapply(seq_along(entries), \(i) {
    run_entry_checks(
      entries[[i]],
      kind,
      file,
      entry_label(ids[[i]], i, kind)
    )
  }))
  rbind(problems, check_identity(ids, kind, file))
}

# The entries' names where sound, else NA: an entry's name is the value of
# the field its schema marks identity, looked up once for the whole list.
entry_names <- function(entries, kind) {
  kind_schema <- field_schema(kind)
  id_field <- kind_schema$field[kind_schema$identity]
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
entry_label <- function(id, i, kind) {
  if (is.na(id)) {
    sprintf("%s entry %d", kind, i)
  } else {
    sprintf("%s '%s'", kind, id)
  }
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

# YE02: required field absent. Requiredness applies only where the field
# is permitted: a variables-only field is not demanded of an observations
# join (amendment 7).
check_required <- function(x, schema, file, entry) {
  demanded <- schema$required &
    vapply(schema$permitted_adds, is_permitted_adds, logical(1), x)
  absent <- setdiff(schema$field[demanded], names(x))
  bind_problems(lapply(absent, \(f) {
    flag_problem(file, entry, "YE02", field = f)
  }))
}

# Whether a field's permitted_adds admits this entry's declared adds.
is_permitted_adds <- function(permitted, x) {
  identical(permitted, "any") ||
    (is_string(x[["adds"]]) && x[["adds"]] %in% permitted)
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

# YE08: a field appears on a join type outside its permitted set. Gated on
# a valid adds value: an off-domain adds is its own root cause (YF03).
check_permitted_adds <- function(x, schema, file, entry) {
  restricted <- !vapply(schema$permitted_adds, identical, logical(1), "any")
  adds <- x[["adds"]]
  if (!any(restricted) || !is_string(adds)) {
    return(no_problems())
  }
  if (!adds %in% schema$domain[[match("adds", schema$field)]]) {
    return(no_problems())
  }
  rows <- schema[restricted, ]
  bind_problems(lapply(seq_len(nrow(rows)), \(i) {
    if (
      is.null(x[[rows$field[i]]]) ||
        is_permitted_adds(rows$permitted_adds[[i]], x)
    ) {
      return(no_problems())
    }
    flag_problem(file, entry, "YE08", field = rows$field[i], adds = adds)
  }))
}

# YE07: a field present without the field it requires
check_requires <- function(x, schema, file, entry) {
  rows <- schema[!is.na(schema$requires), ]
  bind_problems(lapply(seq_len(nrow(rows)), \(i) {
    if (is.null(x[[rows$field[i]]]) || !is.null(x[[rows$requires[i]]])) {
      return(no_problems())
    }
    flag_problem(
      file,
      entry,
      "YE07",
      field = rows$field[i],
      required_field = rows$requires[i]
    )
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

# YS01: two sibling entries claim the same name
check_identity <- function(ids, kind, file) {
  dupes <- unique(ids[duplicated(ids) & !is.na(ids)])
  bind_problems(lapply(dupes, \(d) {
    flag_problem(
      file,
      sprintf("%ss section", kind),
      "YS01",
      kind = kind,
      name = d
    )
  }))
}

# YS02 (within one file) / YX02 (across sources): a value does not name
# something its declared pool contains.
check_reference <- function(
  values,
  declared,
  section,
  file,
  entry,
  code = "YS02"
) {
  bad <- setdiff(values, declared)
  bind_problems(lapply(bad, \(v) {
    flag_problem(
      file,
      entry,
      code,
      value = v,
      section = section,
      suggestion = suggest_name(v, declared)
    )
  }))
}

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
