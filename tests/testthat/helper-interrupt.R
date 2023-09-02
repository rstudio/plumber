
with_interrupt <- function(expr, delay = 0) {
  # Causes pr_run() to immediately exit
  later::later(httpuv::interrupt, delay = delay)
  force(expr)
}
