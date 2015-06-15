postBodyFilter <- function(req){
  qs <- req$rook.input$read_lines()
  args <- parseQS(qs)
  req$args <- c(req$args, args)
  forward()
}
