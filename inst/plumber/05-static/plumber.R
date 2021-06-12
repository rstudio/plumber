#* @assets ./files
list()

#* @assets ./files /static
list()

#* @get /
#* @serializer json list(auto_unbox = TRUE)
function() {
  "static file server at './files'"
}
