#* @post /none
#* @parser none
function(...){
  ret <- list(...)
  ret$req <- NULL
  ret$res <- NULL
  ret
}

#* @post /all
#* @parser all
function(...){
  ret <- list(...)
  ret$req <- NULL
  ret$res <- NULL
  ret
}

#* @post /default
function(...){
  ret <- list(...)
  ret$req <- NULL
  ret$res <- NULL
  ret
}

#* @post /json
#* @parser json
function(...){
  ret <- list(...)
  ret$req <- NULL
  ret$res <- NULL
  ret
}

#* @post /mixed
#* @parser json
#* @parser query
function(...){
  ret <- list(...)
  ret$req <- NULL
  ret$res <- NULL
  ret
}

#* @post /repeated
#* @parser json
#* @parser json
function(...){
  ret <- list(...)
  ret$req <- NULL
  ret$res <- NULL
  ret
}
