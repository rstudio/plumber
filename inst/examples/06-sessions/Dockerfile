FROM trestletech/plumber
MAINTAINER Jeff Allen <docker@trestletech.com>

RUN R -e "install.packages('PKI')"

ENTRYPOINT R -e "pr <- plumber::plumb('/examples/06-sessions/sessions.R'); pr\$addGlobalProcessor(plumber::sessionCookie('secret', 'cookieName', path='/')); pr\$run(port=8000)"
