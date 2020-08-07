return_inputs <- function(...) {
  ret <- list(...)
  ret$req <- NULL
  ret$res <- NULL
  ret
}


#* @post /default
return_inputs

#* @post /json
#* @parser json
return_inputs

#* @post /mixed
#* @parser form
#* @parser json
return_inputs

#* @post /repeated
#* @parser json
#* @parser json
return_inputs

#* @post /none
#* @parser none
return_inputs

#* @post /all
#* @parser all
return_inputs
