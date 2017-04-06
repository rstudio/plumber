context("htmlwidgets serializer")

# Render a simple HTML widget using the visNetwork package
renderWidget <- function(){
  library(visNetwork)
  nodes <- data.frame(id = 1:6, title = paste("node", 1:6),
                      shape = c("dot", "square"),
                      size = 10:15, color = c("blue", "red"))
  edges <- data.frame(from = 1:5, to = c(5, 4, 6, 3, 3))
  visNetwork::visNetwork(nodes, edges) %>%
    visNetwork::visOptions(highlightNearest = TRUE, nodesIdSelection = TRUE)
}

test_that("htmlwidgets serialize properly", {
  w <- renderWidget()
  val <- htmlwidgetSerializer()(w, list(), PlumberResponse$new(), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$headers$`Content-Type`, "text/html; charset=utf-8")
  # Check that content is encoded
  expect_match(val$body, "<script src=\"data:application/x-javascript;base64")
})

test_that("Errors call error handler", {
  errors <- 0
  errHandler <- function(req, res, err){
    errors <<- errors + 1
  }

  expect_equal(errors, 0)
  htmlwidgetSerializer()(parse(text="hi"), list(), PlumberResponse$new("htmlwidget"), err = errHandler)
  expect_equal(errors, 1)
})
