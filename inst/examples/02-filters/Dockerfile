FROM trestletech/plumber
MAINTAINER Jeff Allen <docker@trestletech.com>

EXPOSE 8000

CMD R -e "pr <- plumber::plumb('/examples/02-filters/filters.R'); pr\$run(port=8000)"
