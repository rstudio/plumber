#Defining an array parameter
pr <- plumber$new()

swagger <- function(pr_, spec) {
  spec$paths[["/sum"]]$get$summary <- "Sum numbers"
  spec$paths[["/sum"]]$get$parameters <- list(list(
    "description" = "numbers",
    "required" = "true",
    "in" = "query",
    "name" = "num",
    "schema" = list("type" = "array", "items" = list("type" = "integer"), "minItems" = 1),
    "style" = "form",
    "explode" = "false"
  ))
  spec
}

handler <- function(num) { sum(as.integer(num)) }

pr$handle("GET", "/sum", handler, serializer = serializer_json())

# pr$run(swagger = swagger) # TODO-barret make function for this


# Dealing with a file parameter
pr <- plumber$new()

swagger <- function(pr_, spec) {
  spec$paths[["/upload"]]$post$requestBody$content$`multipart/form-data` <- list(
    "schema" = list(
      "type" = "object",
      "properties" = list(
        "somefile" = list(
          "type" = "string",
          "format" = "binary"))))
  spec
}

handler <- function(req) {
  multipart <- mime::parse_multipart(req)
  list("name" = multipart$somefile$name,
       "tmp_name" = multipart$somefile$datapath,
       "size" = file.size(multipart$somefile$datapath))
}

pr$handle("POST", "/upload", handler, serializer = serializer_json())

# pr$run(swagger = swagger) # TODO-barret make function for this

#In case you have have problems, insert a `browser()` in your swagger function

pr
