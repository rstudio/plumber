#Defining an array parameter
pr <- Plumber$new()

openapi_func <- function(spec) {
  spec$paths[["/sum"]]$get$summary <- "Sum numbers"
  spec$paths[["/sum"]]$get$parameters <- list(list(
    "description" = "numbers",
    "required" = TRUE,
    "in" = "query",
    "name" = "num",
    "schema" = list("type" = "array", "items" = list("type" = "integer"), "minItems" = 1),
    "style" = "form",
    "explode" = FALSE
  ))
  spec
}

handler <- function(num) {
  sum(as.integer(num))
}

pr$handle("GET", "/sum", handler, serializer = serializer_json())

pr$setApiSpec(api = openapi_func)

pr$getApiSpec()

# return Plumber object
pr
