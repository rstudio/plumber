library(plumber)

# Create a new router
router <- plumber::plumber$new()

# An expression that defines the behavior of the filter
logFilter <- expression(
  function(req){
    print(paste0(date(), " - ", req$REMOTE_ADDR, " - ",
            req$REQUEST_METHOD, " ", req$PATH_INFO))
    forward()
  }
)
# addFilter() accepts the following parameters:
#   @param name The name of the filter
#   @param expr The expression encapsulating the
#     filter's logic
#   @param serializer (optional) A custom serializer
#     to use when writing out data from this filter.
#   @param processors The \code{\link{PlumberProcessor}}s
#     to apply to this filter.
router$addFilter(name="logger", expr=logFilter)

# An expression that defines the behavior of the endpoint
endExpr <- expression(
  function(){
    return("response here")
  }
)

# addEndpoint() accepts the following parameters:
#  @param verbs The verb(s) which this endpoint supports
#  @param path The path for the endpoint
#  @param expr The expression encapsulating the
#   endpoint's logic
#  @param serializer The name of the serializer to
#    use (if not the default)
#  @param processors Any \code{PlumberProcessors} to
#    apply to this endpoint
#  @param preempt The name of the filter before which
#    this endpoint should be inserted. If not specified
#    the endpoint will be added after all the filters.
router$addEndpoint(verbs=c("GET", "POST"), path="/",
                   expr = endExpr)

router$run(port=8000)
