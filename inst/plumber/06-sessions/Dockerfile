FROM rstudio/plumber:next

ENTRYPOINT R \
  -e "pr <- plumber::plumb(system.file('examples/06-sessions/plumber.R', package = 'plumber'))" \
  -e "pr\$registerHooks(plumber::sessionCookie('pleasechangeme', 'cookieName'))" \
  -e "pr\$run(host='0.0.0.0', port=8000)"
