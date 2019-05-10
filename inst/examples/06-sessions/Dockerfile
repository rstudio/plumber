FROM trestletech/plumber
MAINTAINER Jeff Allen <docker@trestletech.com>

ENTRYPOINT R -e "pr <- plumber::plumb('/examples/06-sessions/sessions.R'); pr\$registerHooks(plumber::sessionCookie('secret', 'cookieName', path='/')); pr\$run(host='0.0.0.0', port=8000)"
