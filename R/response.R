RapierResponse <- R6Class(
  "RapierResponse",
  public = list(
    initialize = function(){

    },
    status = 200L,
    body = NULL,
    headers = list(),
    setHeader = function(name, value){
      self$headers[[name]] <- value
    },
    toResponse = function(){
      h <- self$headers
      # httpuv doesn't like empty headers lists, and this is a useful field anyway...
      h$Date <- format(Sys.time(), "%a, %d %b %Y %X %Z", tz="GMT")
      h$`Access-Control-Allow-Origin` <-  "*" # Be permissive with CORS

      list(
        status = self$status,
        headers = h,
        body = self$body
      )
    }
  )
)
