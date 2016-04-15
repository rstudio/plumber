FROM trestletech/plumber
MAINTAINER Jeff Allen <docker@trestletech.com>

EXPOSE 8000

CMD R -e "pr <- plumber::plumb('/examples/06-sessions/sessions.R'); pr\$addGlobalProcessor(sessionCookie('secret', 'cookieName', path='/')); pr\$run(port=8000)"
