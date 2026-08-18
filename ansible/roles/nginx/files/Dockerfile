FROM debian:bullseye

RUN apt update && apt upgrade -y

RUN apt install -y nginx openssl 

RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout localhost.key -out localhost.crt \-subj "/CN=localhost"

RUN cp localhost.crt ./etc/ssl/certs/localhost.crt

RUN cp localhost.key ./etc/ssl/private/localhost.key

COPY conf/default /etc/nginx/sites-available/

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]