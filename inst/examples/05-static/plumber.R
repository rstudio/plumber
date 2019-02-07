#* @assets ./files
list()

#* @assets ./files /static
list()

#* @get /
#* @json(auto_unbox = TRUE)
function() {
  "static file server at './files'"
}
