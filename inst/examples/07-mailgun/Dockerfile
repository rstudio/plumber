FROM trestletech/plumber
MAINTAINER Jeff Allen <docker@trestletech.com>

RUN R -e "install.packages('htmltools')"

EXPOSE 8000

CMD R -e "pr <- plumber::plumb('/examples/07-mailgun/mailgun.R'); pr\$run(port=8000)"
