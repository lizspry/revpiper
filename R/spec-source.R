# Parse one specs/tables/<table>.yaml into a rev_dictionary, collecting
# every spec problem before aborting. Complete for a single source: one
# file validates with zero knowledge of any other source.
read_dictionary <- function(path) {
  rlang::check_string(path)
  stop_missing_path("Dictionary file", path)
  raw <- parse_spec_yaml(path)
  problems <- rbind(
    run_entry_checks(raw, "file", path, root_entry_label),
    run_contents_checks(raw, "file", path),
    check_level_entries(raw, path),
    check_virtual_collisions(raw, path),
    resolve_references(raw, path)
  )
  if (nrow(problems) > 0) {
    stop_spec(problems)
  }
  new_dictionary(raw, path)
}

# Load every dictionary in dir standalone via read_dictionary(), then run
# the data-free set-level check: no two files may claim the same table
# name. Returns the list named by table.
read_dictionaries <- function(dir) {
  rlang::check_string(dir)
  files <- dictionary_files(dir)
  dicts <- name_by_table(lapply(files, read_dictionary))
  problems <- check_table_identity(names(dicts), files)
  if (nrow(problems) > 0) {
    stop_spec(problems)
  }
  dicts
}

# Name a list of dictionaries by their tables: the one home for how a
# tables list is keyed.
name_by_table <- function(dicts) {
  stats::setNames(dicts, vapply(dicts, \(d) d$table, character(1)))
}

# How the spec step enumerates dictionary files: the one home for the
# glob, the ordering, and the missing-directory guard.
dictionary_files <- function(dir) {
  stop_missing_path("Dictionary directory", dir, dir.exists(dir))
  sort(list.files(dir, pattern = "\\.ya?ml$", full.names = TRUE))
}

# Label a level entry: the one home for the phrase every level check uses.
level_label <- function(level) {
  sprintf("level '%s'", level)
}

# YE06: a level entry neither names a column nor declares keys or combine.
# A string resolves as a reference (YS02); a mapping validates as a level
# entry, and one with a combine registers a virtual column named by the
# level. Dispatch is by field NAME, so a declared-but-broken keys or combine
# reports its own root cause once instead of YE06 on top.
check_level_entries <- function(raw, file) {
  if (!is_mapping(raw$levels)) {
    return(no_problems()) # absence/shape already reported
  }
  problems <- bind_problems(lapply(names(raw$levels), \(level) {
    value <- raw$levels[[level]]
    if (is_string(value)) {
      return(no_problems())
    }
    if (is_mapping(value)) {
      battery <- run_entry_checks(value, "level", file, level_label(level))
      if (!any(c("keys", "combine") %in% names(value))) {
        battery <- rbind(
          battery,
          flag_problem(file, section_label("levels"), "YE06", level = level)
        )
      }
      return(battery)
    }
    flag_problem(file, section_label("levels"), "YE06", level = level)
  }))
  rbind(problems, check_level_nesting(raw$levels, file))
}

# YS: source checks (across entries within one file)

# YS04: level nesting via within is circular. Chains walk only through
# mapping entries (a string level has no within); each cycle is reported
# once, rotated to start at its alphabetically first level.
check_level_nesting <- function(levels, file) {
  entries <- Filter(is_mapping, levels)
  parents <- vapply(
    entries,
    \(e) if (is_string(e$within)) e$within else NA_character_,
    character(1)
  )
  cycles <- list()
  for (start in names(parents)) {
    path <- character(0)
    current <- start
    while (
      !is.na(current) && current %in% names(parents) && !(current %in% path)
    ) {
      path <- c(path, current)
      current <- parents[[current]]
    }
    if (!is.na(current) && current %in% path) {
      nodes <- path[seq(which(path == current), length(path))]
      anchor <- match(min(nodes), nodes)
      rotated <- c(
        nodes[seq(anchor, length(nodes))],
        nodes[seq_len(anchor - 1)]
      )
      # each level has one parent at most, so cycles are node-disjoint:
      # the anchor node alone identifies the cycle
      cycles[[rotated[[1]]]] <- rotated
    }
  }
  bind_problems(lapply(cycles, \(nodes) {
    flag_problem(
      file,
      section_label("levels"),
      "YS04",
      cycle = paste0("'", c(nodes, nodes[[1]]), "'", collapse = " -> ")
    )
  }))
}

# One resolver for every schema row with a refers_to: gather that field's
# instances from the raw dictionary and resolve each value against what the
# named section declares. NULL declared names mean only that the section is
# malformed - that root cause is already reported, so resolution skips
# rather than cascading.
resolve_references <- function(raw, file) {
  s <- schema_fields()
  referring <- s[!is.na(s$refers_to), ]
  sections <- unique(referring$refers_to)
  declared <- lapply(sections, \(section) declared_names(raw, section))
  names(declared) <- sections
  problems <- no_problems()
  for (i in seq_len(nrow(referring))) {
    row <- referring[i, ]
    known <- declared[[row$refers_to]]
    if (is.null(known)) {
      next
    }
    for (instance in reference_instances(raw, row$field)) {
      problems <- rbind(
        problems,
        check_reference(
          instance$values,
          known,
          row$refers_to,
          file,
          instance$entry
        )
      )
    }
  }
  problems
}

# Where each referring field's values live in a raw dictionary. Instances
# are gathered only from well-shaped containers: a malformed container's
# own problem is already reported. An unlisted field is the loud gap alarm
# for future refers_to schema rows.
reference_instances <- function(raw, field) {
  switch(
    field,
    levels = {
      if (!is_mapping(raw$levels)) {
        return(list())
      }
      strings <- Filter(is_string, raw$levels)
      lapply(names(strings), \(level) {
        list(values = strings[[level]], entry = level_label(level))
      })
    },
    keys = ,
    combine = ,
    within = level_field_instances(raw, field),
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
    cli::cli_abort(
      "Internal error: reference_instances() cannot place field {.val {field}}."
    )
  )
}

# Instances of one field across the well-shaped mapping entries of levels.
level_field_instances <- function(raw, field) {
  if (!is_mapping(raw$levels)) {
    return(list())
  }
  instances <- lapply(names(raw$levels), \(level) {
    entry <- raw$levels[[level]]
    if (!is_mapping(entry)) {
      return(NULL)
    }
    values <- unlist(entry[[field]])
    if (!is.character(values)) {
      return(NULL)
    }
    list(values = values, entry = level_label(level))
  })
  Filter(Negate(is.null), instances)
}

# The names a section declares, by section. The unknown-section abort is
# the loud gap alarm for future refers_to vocabulary: a new section must
# be wired here deliberately, never skipped silently.
declared_names <- function(raw, section) {
  switch(
    section,
    columns = declared_columns(raw),
    levels = declared_levels(raw),
    "key columns" = {
      columns <- declared_columns(raw)
      if (is.null(columns)) NULL else c(columns, virtual_columns(raw))
    },
    cli::cli_abort(
      "Internal error: no section named {.val {section}} declares names."
    )
  )
}

# YS06: a combine level registers a virtual column named by the level, so
# the name may not collide with a declared column (Liz, 2026-07-13, from
# the adversarial battery).
check_virtual_collisions <- function(raw, file) {
  collisions <- intersect(virtual_columns(raw), declared_columns(raw))
  bind_problems(lapply(collisions, \(level) {
    flag_problem(file, level_label(level), "YS06", level = level)
  }))
}

# The virtual columns combine levels register, each named by its level.
virtual_columns <- function(x) {
  if (!is_mapping(x$levels)) {
    return(character(0))
  }
  combines <- Filter(
    \(entry) is_mapping(entry) && !is.null(entry$combine),
    x$levels
  )
  names(combines) %||% character(0)
}

# Declared column names, or NULL when the columns section is malformed.
declared_columns <- function(raw) {
  if (!is_list_of_mappings(raw$columns)) {
    return(NULL)
  }
  ids <- entry_names(raw$columns, "column")
  ids[!is.na(ids)]
}

# Declared level names: absent levels legally declares nothing, but a
# malformed section is NULL (skip, root cause already reported).
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

# YX02 (cross-source references) arrives with read_joins() in Task 5.

# Constructor

new_dictionary <- function(raw, path) {
  defaults <- list(
    required = field_default("column", "required"),
    unique = field_default("column", "unique"),
    missing = field_default("column", "missing")
  )
  columns <- do.call(
    rbind,
    lapply(raw$columns, \(col) {
      tibble::tibble(
        name = col$name,
        type = col$type,
        values = list(if (is.null(col$values)) NULL else unlist(col$values)),
        range = list(if (is.null(col$range)) NULL else unlist(col$range)),
        units = col$units %||% NA_character_,
        required = col$required %||% defaults$required,
        unique = col$unique %||% defaults$unique,
        missing = list(as.character(unlist(
          col$missing %||% defaults$missing
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
      levels = raw$levels %||% list(),
      columns = columns,
      path = path
    ),
    class = "rev_dictionary"
  )
}

# Columns usable as keys: every declared column, plus the virtual column
# each combine level registers (named by its level).
dictionary_key_columns <- function(dict) {
  c(dict$columns$name, virtual_columns(dict))
}
