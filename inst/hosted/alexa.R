#* @get /
#* @html
function(){
  "<html><body><h1>plumber is alive 2!</h1></body></html>"
}

alexaResponse <- list(
  version = "1.0",
  #  sessionAttributes = list(),
  response = list(
    outputSpeech = list(
      type="PlainText",
      text=""
    )
    #card/reprompt/shouldEndSession
  )
)

#* @post /
#* @serializer jsonUnboxed
function(req, res) {
  # TODO: validate

  #print(names(req$args))
  #print(req$args$session)
  #print(req$args$request)

  alexaReq <- req$args$request

  if (alexaReq$type == "IntentRequest"){
    if (alexaReq$intent$name == "tellfact") {
      # Clone
      myres <- c(list(), alexaResponse)
      myres$response$outputSpeech$text <- "Jeff Leek knows how many digits are in pi."
      return(myres)
    }
  }

  stop("I don't know how to do what you want.")
}

# jsonUnboxedSerializer <- function(){
#   function(val, req, res, errorHandler){
#     tryCatch({
#       json <- jsonlite::toJSON(val, auto_unbox = TRUE)
#
#       res$setHeader("Content-Type", "application/json")
#       res$body <- json
#
#       return(res$toResponse())
#     }, error=function(e){
#       errorHandler(req, res, e)
#     })
#   }
# }
# plumber::addSerializer("jsonUnboxed", jsonUnboxedSerializer)
#

