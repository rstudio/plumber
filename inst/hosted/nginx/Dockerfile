FROM nginx:1.9 
MAINTAINER Jeff Allen <docker@trestletech.com>

RUN mkdir -p /certs && \
	chown -R nginx /certs/ && \
	chmod -R 600 /certs/

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
