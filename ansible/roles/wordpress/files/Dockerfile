FROM debian:bullseye

RUN apt update && apt upgrade -y

RUN apt install -y curl php-fpm php-mysql

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

RUN chmod +x wp-cli.phar

RUN mv wp-cli.phar /usr/local/bin/wp

RUN sed -i 's/^listen = \/run\/php\/php7.4-fpm\.sock/listen = 0.0.0.0:9000/' /etc/php/7.4/fpm/pool.d/www.conf

WORKDIR /var/www/html/

RUN wp --allow-root core download

RUN mkdir -p /run/php

COPY ./script.sh /

RUN chmod +x /script.sh

CMD ["bash", "/script.sh"]