#* @plumber
function(pr){
  pr$handle("GET", "/avatartare", function(raw) {raw}, serializer = serializer_json)
}
