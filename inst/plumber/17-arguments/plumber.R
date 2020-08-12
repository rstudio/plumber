#* Plumber allows for things like URI paths to be accessed via named R function arguments, but this is generally considered bad practice (see the examples below)
#* @serializer print
#* @post /bad-practice/<a>/<b>
function(a, b) {
  list(a = a, b = b)
}



#* Since URI paths, query params, and post body arguments can have conflicting names, it's better practice to access arguments via the request object
#* @serializer print
#* @post /good-practice/<a>/<b>
function(req, res) {
  list(
    all = req$args,
    query = req$argsQuery,
    path = req$argsPath,
    postBody = req$argsPostBody
  )
}


# Test this api...

### In an R session...
### Run plumber API
# plumb_api("plumber", "17-arguments") %>% print() %>% pr_run(port = 1234)


### In a terminal...
### Curl API

## Fails (conflicting variable `a`)
# curl --data '' '127.0.0.1:1234/bad-practice/1/2?a=3'
# curl --data 'a=3' '127.0.0.1:1234/bad-practice/1/2'
# curl --data 'a=4' '127.0.0.1:1234/bad-practice/1/2?a=3'

## Works (but missing variable `d`)
# curl --data '' '127.0.0.1:1234/bad-practice/1/2?d=3'
#> $a
#> [1] "1"
#>
#> $b
#> [1] "2"

## Works (but missing variable `d`)
# curl --data 'd=3' '127.0.0.1:1234/bad-practice/1/2'
#> $a
#> [1] "1"
#>
#> $b
#> [1] "2"



## Safe endpoint setup
# curl --data 'a=5&b=6' '127.0.0.1:1234/good-practice/3/4?a=1&b=2&d=10'
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
