#!/bin/bash
set -e

killpids() {
    trap '' INT TERM STOP   # ignore INT and TERM while shutting down
    echo "**** Shutting down... ****"     # added double quotes
    kill -TERM $@        # fixed order, send TERM not INT
    wait
    echo DONE
}

echo $(date)": start.sh started"

# PATH
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/openresty/bin
export PATH

# Location of the files
PHP=/var/tmp/php.ini
FPMCONFIG=/var/tmp/fpm.conf
CONFIG=/var/tmp/nginx.conf
TEMPLATE_DIR=/var/tmp/templates

# Generate the config files
erubis $TEMPLATE_DIR/php.ini.erb > $PHP
erubis $TEMPLATE_DIR/fpm.conf.erb > $FPMCONFIG
erubis $TEMPLATE_DIR/nginx_or.conf.erb > $CONFIG

# Start the NGINX and PHP-FPM processes
php-fpm --fpm-config $FPMCONFIG -c $PHP --nodaemonize &
pids=$!

openresty -c $CONFIG -t
openresty -c $CONFIG &
pids="$pids $!"


trap "killpids $pids" INT KILL TERM STOP QUIT EXIT

echo $(date)": start.sh completed"

wait $pids
