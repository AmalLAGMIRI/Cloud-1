#!/bin/bash

# Wait for database
sleep 5
wp config create  --dbname=$SQL_DATABASE --dbuser=$MSQL_USER --dbpass=$MSQL_PASSWORD --dbhost=$localhost --allow-root
wp core install --title=$WP_TITLE --admin_user=$WP_ADMIN_USER --admin_password=$WP_ADMIN_PASSWORD --admin_email=$WP_ADMIN_EMAIL --url=$WP_URL --allow-root
wp user create  $WORDP_USER $WORDP_USER_EMAIL --role=author --user_pass=$USER_PASSWORD --allow-root

php-fpm7.4 -F
