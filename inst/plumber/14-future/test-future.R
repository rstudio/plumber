# Instructions:
# 1. `plumb` API - `plumb_api("plumber", "14-future") %>% pr_run(port = 1234)`
# 2. In separate R session, source the test file - `source(system.file("plumber/14-future/test-future.R", package = "plumber"))`

local(withAutoprint({ # print when sourced

read_url <- function(...) {
  try(readLines(..., warn = FALSE))
}

# example
read_url("http://127.0.0.1:1234/divide?a=6&b=3") # 2
read_url("http://127.0.0.1:1234/divide-catch?a=6&b=3") # 2

# missing 'b' param
read_url("http://127.0.0.1:1234/divide?a=6") # fails
read_url("http://127.0.0.1:1234/divide-catch?a=6") # handles error; returns Inf

# missing 'a' param
read_url("http://127.0.0.1:1234/divide?b=3") # fails
read_url("http://127.0.0.1:1234/divide-catch?b=3") # fails

}))

# --------------------------
# --------------------------

local(withAutoprint({ # print when sourced

counter <- 1
log_file <- "_timings.log"
cat_file <- function(..., append = TRUE) {
  Sys.sleep(0.5) # for clean logging purposes only
  cat(..., "\n", file = log_file, append = append)
}
curl_route <- function(route) {
  Sys.sleep(0.5) # for clean logging purposes only
  local_counter <- counter
  counter <<- counter + 1
  system(
    paste0("curl 127.0.0.1:1234/", route, " >> ", log_file, " && echo ' - ", local_counter, "' >> ", log_file),
    wait = FALSE
  )
}


# Serially call each route
cat_file("--START route requests", append = FALSE)
curl_route("sync")
curl_route("future")
curl_route("sync")
curl_route("sync")
curl_route("sync")
curl_route("future")
curl_route("future") # will wait to execute if only two future processes allowed
curl_route("future")
curl_route("sync")
curl_route("sync")
curl_route("sync")
cat_file("--END route requests\n")


Sys.sleep(21) # wait for everything to finish

# display curl'ed output
cat(readLines(log_file), sep = "\n")


}))
# --------------------------

## Sample output using future::plan(future::multisession(workers = 2)) # only two workers
# --START route requests
# "/sync; 2019-10-07 13:11:06; pid:82424" - 1
# "/sync; 2019-10-07 13:11:07; pid:82424" - 3
# "/sync; 2019-10-07 13:11:07; pid:82424" - 4
# "/sync; 2019-10-07 13:11:08; pid:82424" - 5
# --END route requests
#
# "/sync; 2019-10-07 13:11:19; pid:82424" - 9
# "/sync; 2019-10-07 13:11:19; pid:82424" - 10
# "/sync; 2019-10-07 13:11:19; pid:82424" - 11
# "/future; 2019-10-07 13:11:16; pid:37135" - 2
# "/future; 2019-10-07 13:11:18; pid:37148" - 6
# "/future; 2019-10-07 13:11:27; pid:37272" - 7
# "/future; 2019-10-07 13:11:29; pid:37273" - 8


# --------------------------

## Sample output using future::plan("multisession") # a worker for each core
# --START route requests
# "/sync; 2019-10-07 13:16:22; pid:82424" - 1
# "/sync; 2019-10-07 13:16:23; pid:82424" - 3
# "/sync; 2019-10-07 13:16:24; pid:82424" - 4
# "/sync; 2019-10-07 13:16:25; pid:82424" - 5
# "/sync; 2019-10-07 13:16:27; pid:82424" - 9
# "/sync; 2019-10-07 13:16:27; pid:82424" - 10
# "/sync; 2019-10-07 13:16:28; pid:82424" - 11
# --END route requests
#
# "/future; 2019-10-07 13:16:33; pid:40613" - 2
# "/future; 2019-10-07 13:16:35; pid:40626" - 6
# "/future; 2019-10-07 13:16:36; pid:40630" - 7
# "/future; 2019-10-07 13:16:36; pid:40634" - 8
