# The package schema. inst/schema/fields.yaml is the single source of truth
# for spec-field validation; inst/schema/checks.yaml is the check registry
# (codes, meanings, message templates). Both are loaded once per session and
# cached. The loaders are generic: property names and their handling come
# from the schema's own properties section, not from this code.

schema_yaml <- function(file) {
  yaml::read_yaml(system.file("schema", file, package = "revpiper"))
}

cached <- function(load) {
  cache <- NULL
  function() {
    if (is.null(cache)) {
      cache <<- load()
    }
    cache
  }
}

# The property vocabulary: one row per property of a field-schema row.
# Registry entries are keyed by name (duplicates fail at parse); the key
# supplies the row's name column.
schema_properties <- cached(function() {
  properties <- schema_yaml("fields.yaml")$properties
  do.call(
    rbind,
    lapply(names(properties), \(name) {
      p <- properties[[name]]
      tibble::tibble(
        property = name,
        meaning = p$meaning,
        type = p$type,
        allowed = list(unlist(p$allowed))
      )
    })
  )
})

# One field per row, one property per column; every cell read from the yaml
# and converted per its property's declared loading type. Fields are grouped
# under their kind, so the entry key supplies the field property and the
# group header supplies the kind property.
schema_fields <- cached(function() {
  props <- schema_properties()
  kinds <- schema_yaml("fields.yaml")$fields
  do.call(
    rbind,
    lapply(names(kinds), \(kind) {
      fields <- kinds[[kind]]
      do.call(
        rbind,
        lapply(names(fields), \(name) {
          f <- c(list(field = name, kind = kind), fields[[name]])
          cells <- lapply(seq_len(nrow(props)), \(i) {
            value <- f[[props$property[i]]]
            switch(
              props$type[i],
              string = value %||% NA_character_,
              boolean = value,
              list_of_strings = list(unlist(value)),
              verbatim = list(value)
            )
          })
          names(cells) <- props$property
          do.call(tibble::tibble, cells)
        })
      )
    })
  )
})

# The closed set of entry kinds, read from the schema's kinds list.
schema_kinds <- function() {
  unlist(schema_yaml("fields.yaml")$kinds)
}

# The check registry: one row per code, keyed by code.
check_registry <- cached(function() {
  checks <- schema_yaml("checks.yaml")$checks
  do.call(
    rbind,
    lapply(names(checks), \(code) {
      ch <- checks[[code]]
      tibble::tibble(
        code = code,
        scope = ch$scope,
        property = ch$property,
        meaning = ch$meaning,
        message_template = ch$message_template,
        params = list(unlist(ch$params)),
        fix = ch$fix,
        implemented = ch$implemented,
        phrases = list(ch$phrases)
      )
    })
  )
})

# Schema rows for one kind of entry ("file", "source", "column", "level", ...).
field_schema <- function(kind) {
  s <- schema_fields()
  s[s$kind == kind, ]
}

# The type universe, read from the type row's inline domain.
schema_types <- function() {
  s <- schema_fields()
  s$domain[[which(s$field == "type")]]
}

# Render a registered check's message: placeholders replaced verbatim,
# never evaluated.
render_message <- function(code, ...) {
  registry <- check_registry()
  i <- which(registry$code == code)
  if (length(i) != 1) {
    cli::cli_abort("Internal error: unregistered check code {.val {code}}.")
  }
  message <- registry$message_template[i]
  args <- list(...)
  for (nm in names(args)) {
    message <- gsub(
      paste0("{", nm, "}"),
      as.character(args[[nm]]),
      message,
      fixed = TRUE
    )
  }
  message
}

# A check flags a problem: the code's registry template renders the message.
flag_problem <- function(file, entry, code, ..., suggestion = NULL) {
  new_problem(
    file,
    entry,
    code,
    render_message(code, ...),
    suggestion = suggestion
  )
}

# Phrases for YF02's {expected}: enumerated in YF02's own registry entry,
# never composed.
shape_phrases <- function() {
  registry <- check_registry()
  registry$phrases[[which(registry$code == "YF02")]]
}

shape_phrase <- function(shape, cardinality) {
  entry <- shape_phrases()[[shape]]
  if (is.character(entry)) entry else entry[[cardinality]]
}
