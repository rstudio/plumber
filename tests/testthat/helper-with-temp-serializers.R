
with_tmp_serializers <- function(expr) {
  ## Do not _actually_ register test-only serializers
  cur_serializers <- .globals$serializers
  on.exit({
    .globals$serializers <- cur_serializers
  }, add = TRUE)

  force(expr)
}
