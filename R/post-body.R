postBodyParser <- function(req, res){
  qs <- req$rook.input$read_lines()
  parseQS(qs)
}
