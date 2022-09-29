
#* @get /
#* @preempt __first__
function(){
  "first"
}

#* @get /abc
function(){
  "abc get"
}

#* @post /abc
function(){
  "abc post"
}

#* @filter filt1
function(req, res){
  forward()
}

#* @filter filt2
function(req, res){
  forward()
}

#* @use /dog
#* @preempt filt2
function(){
  "dog use"
}

#* @get /dog
#* @preempt filt1
function(){
  "dog get"
}

#* @get /error
function(){
  stop("ERROR")
}

#* @get /response123
function(res){
  res$body <- "overridden"
  res$status <- 123
  res
}

#* @get /response200
function(res){
  res$body <- "overridden"
  res$status <- 200
  res
}

#* @get /path1
#* @get /path2
function(){
  "dual path"
}

#* @plumber
function(pr) {
  mnt_1 <-
    pr() %>%
    pr_get("/hello", function() "say hello")
  mnt_2 <-
    pr() %>%
    pr_get("/world", function() "say hello world")

  pr %>%
    pr_mount("/say", mnt_1) %>%
    pr_mount("/say/hello", mnt_2)
}
