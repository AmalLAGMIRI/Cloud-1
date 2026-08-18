
FROM debian:bullseye

RUN apt update && apt upgrade -y

RUN  apt-get install mariadb-server -y

RUN sed -i 's/^bind-address\s*=.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

RUN service mariadb start \
&& mariadb -e "\
CREATE DATABASE IF NOT EXISTS wordpress;\
CREATE USER amal IDENTIFIED BY '12345';\
GRANT ALL PRIVILEGES ON wordpress.* TO amal;\
FLUSH PRIVILEGES;"\
&& service mariadb stop

CMD [ "mariadbd"]
