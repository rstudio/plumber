FROM trestletech/plumber
MAINTAINER Jeff Allen <docker@trestletech.com>

EXPOSE 8000

CMD R -e "pr <- plumber::plumb('/examples/08-identity/identity.R'); pr\$run(port=8000)"
