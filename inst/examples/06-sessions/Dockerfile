FROM trestletech/plumber
MAINTAINER Jeff Allen <docker@trestletech.com>

# rforge required because of some recent instability in PKI... disconcerting.
# https://stat.ethz.ch/pipermail/r-help/2016-December/443572.html
RUN R -e "install.packages('PKI',,'https://www.rforge.net/')"

ENTRYPOINT R -e "pr <- plumber::plumb('/examples/06-sessions/sessions.R'); pr\$addGlobalProcessor(plumber::sessionCookie('secret', 'cookieName', path='/')); pr\$run(host='0.0.0.0', port=8000)"
