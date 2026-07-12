#' Read and validate the joins spec
#'
#' Parses `specs/joins.yaml` against the loaded dictionaries. This is the
#' across-source validation step: data-free and composable, so each
#' dictionary still validates standalone and a table certification never
#' depends on it. A missing joins file is a valid single-table project and
#' returns the zero-row tibble.
#'
#' @param path Path to the joins YAML file.
#' @param dictionaries Named list of `rev_dictionary` objects, as returned
#'   by [rev_read_dictionaries()].
#' @return A tibble with one row per declared join: `adds`, `left`,
#'   `right`, `keys_left` and `keys_right` (list columns), `relationship`
#'   and `unmatched_ok` (both `NA` on observation appends, where they do
#'   not apply).
#' @export
rev_read_joins <- function(path, dictionaries) {
  rlang::check_string(path)
  is_dictionary_list <- is.list(dictionaries) &&
    all(vapply(dictionaries, inherits, logical(1), "rev_dictionary"))
  if (!is_dictionary_list) {
    cli::cli_abort(
      "{.arg dictionaries} must be a list of {.cls rev_dictionary} objects,
       as returned by {.fun rev_read_dictionaries}."
    )
  }
  if (!file.exists(path)) {
    return(no_joins())
  }
  raw <- yaml::read_yaml(path)
  problems <- rbind(
    run_entry_checks(raw, "join_file", path, "file entry"),
    run_contents_checks(raw, "join_file", path),
    resolve_join_references(raw, path, dictionaries)
  )
  if (nrow(problems) > 0) {
    stop_spec(problems)
  }
  new_joins(raw$joins)
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
  do.call(
    rbind,
    c(
      list(no_joins()),
      lapply(joins, \(join) {
        variables <- join$adds == "variables"
        tibble::tibble(
          adds = join$adds,
          left = join$left,
          right = join$right,
          keys_left = list(as.character(unlist(join$keys[[join$left]]))),
          keys_right = list(as.character(unlist(join$keys[[join$right]]))),
          relationship = if (variables) join$relationship else NA_character_,
          unmatched_ok = if (variables) {
            join$unmatched_ok %||% field_default("join", "unmatched_ok")
          } else {
            NA
          }
        )
      })
    )
  )
}

# YX02/YX03: across-source resolution — sides against the loaded tables,
# key columns against the named side's key pool (declared plus virtual
# columns), keys' own names against the join's sides. Only well-shaped
# values are resolved: their shape problems are already reported.
resolve_join_references <- function(raw, file, dictionaries) {
  if (!is_list_of_mappings(raw$joins)) {
    return(no_problems())
  }
  tables <- names(dictionaries)
  bind_problems(lapply(seq_along(raw$joins), \(i) {
    join <- raw$joins[[i]]
    entry <- entry_label(NA_character_, i, "join")
    problems <- no_problems()

    sides <- unlist(Filter(is_string, list(join$left, join$right)))
    for (side in setdiff(sides, tables)) {
      problems <- rbind(
        problems,
        flag_problem(
          file,
          entry,
          "YX02",
          value = side,
          section = "the loaded tables",
          suggestion = suggest_name(side, tables)
        )
      )
    }

    if (!is_mapping(join$keys)) {
      return(problems)
    }
    for (key_table in setdiff(names(join$keys), sides)) {
      problems <- rbind(
        problems,
        flag_problem(
          file,
          entry,
          "YX02",
          value = key_table,
          section = "the join's sides",
          suggestion = suggest_name(key_table, sides)
        )
      )
    }
    for (key_table in intersect(names(join$keys), intersect(sides, tables))) {
      pool <- dictionary_key_columns(dictionaries[[key_table]])
      values <- as.character(unlist(join$keys[[key_table]]))
      for (value in setdiff(values, pool)) {
        problems <- rbind(
          problems,
          flag_problem(
            file,
            entry,
            "YX02",
            value = value,
            section = sprintf("the key columns of '%s'", key_table),
            suggestion = suggest_name(value, pool)
          )
        )
      }
    }
    covered <- vapply(
      sides,
      \(side) length(as.character(unlist(join$keys[[side]]))) > 0,
      logical(1)
    )
    if (length(sides) == 2 && !all(covered)) {
      problems <- rbind(
        problems,
        flag_problem(
          file,
          entry,
          "YX03",
          left = join$left,
          right = join$right
        )
      )
    }
    problems
  }))
}
