library(plumber)

pr <- plumber$new()
pr$addAssets("www", "/", list())

pr$run()
