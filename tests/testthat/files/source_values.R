#* @get /count
{
  if (!exists("count")) {
    count <- 0
  }
  # will not init if variable exists,
  # testing against sourcing an endpoint twice in the same envir
  count <- count + 1
  function() {
    count
  }
}

#* @get /static_count
function() {
  static_count
}

# will not init if variable exists,
# testing against sourcing a script twice in the same envir
if (!exists("static_count")) {
  static_count <- 0
}
static_count <- static_count + 1
