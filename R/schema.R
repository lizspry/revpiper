# The package schema: inst/schema/fields.yaml is the single source of truth
# for spec-field validation. Loaded once per session, cached.
the_schema <- local({
  cache <- NULL
  function() {
    if (is.null(cache)) {
      path <- system.file("schema", "fields.yaml", package = "revpiper")
      raw <- yaml::read_yaml(path)
      cache <<- do.call(
        rbind,
        lapply(raw$fields, \(f) {
          tibble::tibble(
            field = f$field,
            level = list(unlist(f$level)),
            required = f$required,
            shape = f$shape,
            cardinality = f$cardinality,
            empty_ok = f$empty_ok,
            domain = list(unlist(f$domain)),
            permitted_types = list(unlist(f$permitted_types)),
            excludes = list(unlist(f$excludes)),
            content_typed = f$content_typed,
            ordered = f$ordered %||% NA_character_,
            unique_entries = f$unique_entries,
            refers_to = f$refers_to %||% NA_character_,
            identity = f$identity,
            default = list(f$default)
          )
        })
      )
    }
    cache
  }
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
