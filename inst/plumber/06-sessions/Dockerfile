FROM rstudio/plumber:next

ENTRYPOINT R \
  -e "library(plumber)" \
  -e "plumb_api('plumber', '06-sessions') %>% pr_run(host='0.0.0.0', port=8000)"
