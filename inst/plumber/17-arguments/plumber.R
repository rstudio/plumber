#* Works with query string aruguments
#* @serializer print
#* @post /named/<a>/<b>
function(a, b) {
  list(a = a, b = b)
}



#* Can have conflicting path, query, and post body arugments
#* @serializer print
#* @post /args/<a>/<b>
function(req, res) {
  list(
    all = req$args,
    query = req$argsQuery,
    path = req$argsPath,
    postBody = req$argsPostBody
  )
}

if (FALSE) {
  # Example of failure to call a function with multiple named arguments
  do.call(function(a, ...) {list(a, ...)}, list(a = 1, b = 2, a = 3))
  #> Error in (function (a, ...)  :
  #> formal argument "a" matched by multiple actual arguments
}



# Test this api...

### In an R session...
### Run plumber API
# plumb_api("plumber", "17-arguments") %>% print() %>% pr_run(port = 1234)


### In a terminal...
### Curl API

## Works
# curl --data '' '127.0.0.1:1234/named/1/2'
#> $a
#> [1] "1"
#>
#> $b
#> [1] "2"

## Works (but missing variable `d`)
# curl --data '' '127.0.0.1:1234/named/1/2?d=3'
#> $a
#> [1] "1"
#>
#> $b
#> [1] "2"

## Works (but missing variable `d`)
# curl --data 'd=3' '127.0.0.1:1234/named/1/2'
#> $a
#> [1] "1"
#>
#> $b
#> [1] "2"

## Fails (conflicting variable `a`)
# curl --data '' '127.0.0.1:1234/named/1/2?a=3'
# curl --data 'a=3' '127.0.0.1:1234/named/1/2'
# curl --data 'a=4' '127.0.0.1:1234/named/1/2?a=3'


## Safe endpoint setup
# curl --data 'a=5&b=6' '127.0.0.1:1234/args/3/4?a=1&b=2&d=10'
#> $all
#> $all$req
#> <environment>
#>
#> $all$res
#> <PlumberResponse>
#>
#> $all$a
#> [1] "1"
#>
#> $all$b
#> [1] "2"
#>
#> $all$d
#> [1] "10"
#>
#> $all$a
#> [1] "3"
#>
#> $all$b
#> [1] "4"
#>
#> $all$a
#> [1] "5"
#>
#> $all$b
#> [1] "6"
#>
#>
#> $query
#> $query$a
#> [1] "1"
#>
#> $query$b
#> [1] "2"
#>
#> $query$d
#> [1] "10"
#>
#>
#> $path
#> $path$a
#> [1] "3"
#>
#> $path$b
#> [1] "4"
#>
#>
#> $postBody
#> $postBody$a
#> [1] "5"
#>
#> $postBody$b
#> [1] "6"
