# Parse specs/joins.yaml against the loaded dictionaries — the
# across-source validation step: data-free and composable, so each
# dictionary still validates standalone and a table certification never
# depends on it. A missing joins file is a valid single-table project and
# returns the zero-row tibble. `dictionaries = NULL` runs within-file
# checks only (no reference resolution), for single-file selection.
# Returns list(value, problems): the joins tibble (one row per declared
# join) exactly when zero problems stand, else NULL.
read_joins <- function(
  path,
  dictionaries = NULL,
  failed_tables = character(0)
) {
  rlang::check_string(path)
  if (!is.null(dictionaries)) {
    is_dictionary_list <- is.list(dictionaries) &&
      all(vapply(dictionaries, inherits, logical(1), "rev_dictionary"))
    if (!is_dictionary_list) {
      cli::cli_abort(
        "{.arg dictionaries} must be a list of {.cls rev_dictionary}
         objects."
      )
    }
  }
  if (!file.exists(path)) {
    return(list(value = no_joins(), problems = no_problems()))
  }
  parsed <- parse_spec_yaml(path)
  if (nrow(parsed$problems) > 0) {
    return(list(value = NULL, problems = parsed$problems))
  }
  # Parsed-but-empty flows into the checks (battery B1): the required
  # joins field is then stated missing rather than silently certifying.
  raw <- if (is_mapping(parsed$raw)) parsed$raw else list()
  problems <- rbind(
    run_entry_checks(raw, "join_file", path, root_entry_label),
    run_contents_checks(raw, "join_file", path),
    check_join_sides(raw, path),
    check_join_coverage(raw, path),
    if (!is.null(dictionaries)) {
      resolve_join_references(raw, path, dictionaries, failed_tables)
    }
  )
  list(
    value = if (nrow(problems) == 0) new_joins(raw$joins) else NULL,
    problems = problems
  )
}

# The joins tibble: the one home for its shape.
no_joins <- function() {
  tibble::tibble(
    adds = character(0),
    left = character(0),
    right = character(0),
    keys_left = list(),
    keys_right = list(),
    relationship = character(0),
    unmatched_ok = logical(0)
  )
}

new_joins <- function(joins) {
  schema <- field_schema("join")
  default_unmatched <- field_default("join", "unmatched_ok")
  # A field applies to a join exactly where validation permits it: derived
  # from the schema's permitted_adds, never restated here.
  applies <- function(field, join) {
    is_permitted_adds(schema$permitted_adds[[match(field, schema$field)]], join)
  }
  do.call(
    rbind,
    c(
      list(no_joins()),
      lapply(joins, \(join) {
        tibble::tibble(
          adds = join$adds,
          left = join$left,
          right = join$right,
          keys_left = list(as.character(unlist(join$keys[[join$left]]))),
          keys_right = list(as.character(unlist(join$keys[[join$right]]))),
          relationship = if (applies("relationship", join)) {
            join$relationship
          } else {
            NA_character_
          },
          unmatched_ok = if (applies("unmatched_ok", join)) {
            join$unmatched_ok %||% default_unmatched
          } else {
            NA
          }
        )
      })
    )
  )
}

# YE09: a join relates two different tables — left == right is flagged
# with or without dictionaries loaded (battery decision, Liz 2026-07-19:
# self-joins are illegal).
check_join_sides <- function(raw, file) {
  if (!is_list_of_mappings(raw$joins)) {
    return(no_problems())
  }
  bind_problems(lapply(seq_along(raw$joins), \(i) {
    join <- raw$joins[[i]]
    if (
      is_string(join$left) &&
        is_string(join$right) &&
        identical(join$left, join$right)
    ) {
      flag_problem(
        file,
        entry_label(NA_character_, i, "join"),
        "YE09",
        table = join$left
      )
    } else {
      no_problems()
    }
  }))
}

# YE10: keys must cover both sides — recoded from YX03 (Liz,
# 2026-07-19): by the deletion test its verdict reads only the entry,
# so it belongs to the entry series and fires in standalone joins mode
# too (the old cross-source placement wrongly prevented that).
check_join_coverage <- function(raw, file) {
  if (!is_list_of_mappings(raw$joins)) {
    return(no_problems())
  }
  bind_problems(lapply(seq_along(raw$joins), \(i) {
    join <- raw$joins[[i]]
    sides <- unlist(Filter(is_string, list(join$left, join$right)))
    if (length(sides) != 2 || !is_mapping(join$keys)) {
      return(no_problems())
    }
    covered <- vapply(
      sides,
      \(side) length(unlist(join$keys[[side]])) > 0,
      logical(1)
    )
    if (all(covered)) {
      return(no_problems())
    }
    flag_problem(
      file,
      entry_label(NA_character_, i, "join"),
      "YE10",
      left = join$left,
      right = join$right
    )
  }))
}

# YX02: across-source resolution — sides against the loaded tables,
# keys' own names against the join's sides, key columns against the named
# side's key pool (declared plus virtual columns). Every pool resolves
# through check_reference (YS02's engine, cross-source code). Only
# well-shaped values are resolved: their shape problems are already
# reported.
resolve_join_references <- function(
  raw,
  file,
  dictionaries,
  failed_tables = character(0)
) {
  if (!is_list_of_mappings(raw$joins)) {
    return(no_problems())
  }
  tables <- names(dictionaries)
  # A side naming the table a FAILED spec file intended (its raw table:
  # field) is an incomplete search, stated as the checked fact (design
  # 2026-07-19); an unreadable table field asserts no link.
  related_for <- function(v) {
    if (v %in% names(failed_tables)) {
      sprintf(
        related_phrases$incomplete_file,
        paste(failed_tables[[v]], collapse = ", ")
      )
    }
  }
  bind_problems(lapply(seq_along(raw$joins), \(i) {
    join <- raw$joins[[i]]
    entry <- entry_label(NA_character_, i, "join")
    sides <- unlist(Filter(is_string, list(join$left, join$right)))
    problems <- check_reference(
      sides,
      tables,
      "the loaded tables",
      file,
      entry,
      code = "YX02",
      related_for = related_for
    )
    if (!is_mapping(join$keys)) {
      return(problems)
    }
    key_values <- lapply(join$keys, \(v) as.character(unlist(v)))
    problems <- rbind(
      problems,
      check_reference(
        names(key_values),
        sides,
        "the join's sides",
        file,
        entry,
        code = "YX02"
      )
    )
    for (side in intersect(names(key_values), intersect(sides, tables))) {
      problems <- rbind(
        problems,
        check_reference(
          key_values[[side]],
          dictionary_key_columns(dictionaries[[side]]),
          sprintf("the key columns of '%s'", side),
          file,
          entry,
          code = "YX02"
        )
      )
    }
    problems
  }))
}
