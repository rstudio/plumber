#* Plumber allows for things like URI paths to be accessed via named R function arguments, but this is generally considered bad practice (see the examples below)
#* @serializer print
#* @post /bad-practice/<a>/<b>
function(a, b) {
  list(a = a, b = b)
}



#* Since URI paths, query params, and body arguments can have conflicting names, it's better practice to access arguments via the request object
#* If more information is needed from the body (such as filenames), inspect `req$body` for more information
#* @serializer print
#* @post /good-practice/<a>/<b>
function(req, res) {
  list(
    args = req$args,
    argsQuery = req$argsQuery,
    argsPath = req$argsPath,
    argsBody = req$argsBody,
    body = req$body
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
#> $args
#> $args$req
#> <environment>
#>
#> $args$res
#> <PlumberResponse>
#>
#> $args$a
#> [1] "1"
#>
#> $args$b
#> [1] "2"
#>
#> $args$d
#> [1] "10"
#>
#> $args$a
#> [1] "3"
#>
#> $args$b
#> [1] "4"
#>
#> $args$a
#> [1] "5"
#>
#> $args$b
#> [1] "6"
#>
#>
#> $argsQuery
#> $argsQuery$a
#> [1] "1"
#>
#> $argsQuery$b
#> [1] "2"
#>
#> $argsQuery$d
#> [1] "10"
#>
#>
#> $argsPath
#> $argsPath$a
#> [1] "3"
#>
#> $argsPath$b
#> [1] "4"
#>
#>
#> $argsBody
#> $argsBody$a
#> [1] "5"
#>
#> $argsBody$b
#> [1] "6"
#>
#>
#> $body
#> $body$a
#> [1] "5"
#>
#> $body$b
#> [1] "6"
