plumber::register_serializer("fake", function(){
  function(val, req, res, errorHandler){
    tryCatch({
      json <- jsonlite::toJSON(val)

      res$setHeader("Content-Type", "application/json")
      res$body <- paste0("FAKE", json)

      return(res$toResponse())
    }, error=function(e){
      errorHandler(req, res, e)
    })
  }
})

plumber$new("./plumber.R")
