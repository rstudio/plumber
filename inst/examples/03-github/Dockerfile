FROM trestletech/plumber
MAINTAINER Jeff Allen <docker@trestletech.com>

EXPOSE 8000

CMD R -e "pr <- plumber::plumb('/examples/03-github/github.R'); pr\$run(port=8000)"
