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
      list(
        status = self$status,
        headers = self$headers,
        body = self$body
      )
    }
  )
)
