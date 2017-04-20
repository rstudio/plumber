FROM nginx:1.9 
MAINTAINER Jeff Allen <docker@trestletech.com>

ADD privkey.pem /etc/certs/plumber/privkey.pem
ADD cert.pem /etc/certs/plumber/cert.pem
RUN chown -R nginx /etc/certs/plumber
RUN chmod -R 700 /etc/certs/plumber

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
