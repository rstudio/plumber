FROM trestletech/plumber
MAINTAINER Jeff Allen <docker@trestletech.com>

EXPOSE 8000

RUN R -e "install.packages('PKI')"

CMD R -e "pr <- plumber::plumb('/examples/06-sessions/sessions.R'); pr\$addGlobalProcessor(plumber::sessionCookie('secret', 'cookieName', path='/')); pr\$run(port=8000)"
