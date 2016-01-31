make_req <- function(verb, path, cookie){
  req <- new.env()
  req$REQUEST_METHOD <- toupper(verb)
  req$PATH_INFO <- path
  req$rook.input <- list(read_lines = function(){ "" })
  if (!missing(cookie)){
    req$HTTP_COOKIE <- cookie
  }
  req
}

test_that("cookies are set", {
  r <- plumber$new()

  expr <- expression(function(req, res){ req$session <- list(abc=123); TRUE })

  r$addEndpoint("GET", "/", expr)

  sc <- sessionCookie("mysecret", name="plcook")

  r$addGlobalProcessor(sc)

  res <- PlumberResponse$new()
  r$serve(make_req("GET", "/"), res)

  key <- PKI:::PKI.digest(charToRaw("mysecret"), "SHA256")
  cook <- res$headers[["Set-Cookie"]]
  expect_true(grepl("^plcook=", cook, perl=TRUE))
  cook <- gsub("^plcook=", "", cook, perl=TRUE)
  de <- PKI:::PKI.decrypt(base64decode(cook), key, "aes256")

  expect_equal(rawToChar(de), '{"abc":[123]}')
})

test_that("cookies are read", {
  r <- plumber$new()

  expr <- expression(function(req, res){ req$session$abc })

  r$addEndpoint("GET", "/", expr)

  sc <- sessionCookie("mysecret", name="plcook")

  r$addGlobalProcessor(sc)

  res <- PlumberResponse$new()

  key <- PKI:::PKI.digest(charToRaw("mysecret"), "SHA256")
  data <- '{"abc":[123]}'
  enc <- PKI:::PKI.encrypt(charToRaw(data), key, "aes256")
  r$serve(make_req("GET", "/", paste0('plcook=', base64encode(enc))), res)

  de <- PKI:::PKI.decrypt(charToRaw(res$body), key, "aes256")
  expect_equal(res$body, jsonlite::toJSON(123))
})
