# The package schema. inst/schema/fields.yaml is the single source of truth
# for spec-field validation; inst/schema/checks.yaml is the check registry
# (codes, meanings, message templates). Both are loaded once per session and
# cached. The loaders are generic: property names and their handling come
# from the schema's own properties block, not from this code.

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
the_properties <- cached(function() {
  do.call(
    rbind,
    lapply(schema_yaml("fields.yaml")$properties, \(p) {
      tibble::tibble(
        property = p$property,
        meaning = p$meaning,
        type = p$type,
        allowed = list(unlist(p$allowed))
      )
    })
  )
})

# One field per row, one property per column; every cell read from the yaml
# and converted per its property's declared loading type.
the_schema <- cached(function() {
  props <- the_properties()
  do.call(
    rbind,
    lapply(schema_yaml("fields.yaml")$fields, \(f) {
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

# The check registry: one row per code.
the_checks <- cached(function() {
  do.call(
    rbind,
    lapply(schema_yaml("checks.yaml")$checks, \(ch) {
      tibble::tibble(
        code = ch$code,
        scope = ch$scope,
        property = ch$property,
        meaning = ch$meaning,
        message_template = ch$message_template,
        params = list(unlist(ch$params)),
        fix = ch$fix,
        implemented = ch$implemented
      )
    })
  )
})

# Schema rows legal at one context level ("top", "source", "column", "combine").
field_schema <- function(level) {
  s <- the_schema()
  s[vapply(s$level, \(l) level %in% l, logical(1)), ]
}

# The type universe, read from the type row's inline domain.
schema_types <- function() {
  s <- the_schema()
  s$domain[[which(s$field == "type")]]
}

# Render a registered check's message: placeholders replaced verbatim,
# never evaluated.
render_message <- function(code, ...) {
  registry <- the_checks()
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

# One registered problem: the code's template renders the message.
problem <- function(file, entry, code, ..., suggestion = NULL) {
  spec_problem(
    file,
    entry,
    code,
    render_message(code, ...),
    suggestion = suggestion
  )
}
