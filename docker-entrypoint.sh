#!/bin/bash
set -e

# Generate PHP configuration at runtime from environment variables
cat > /usr/local/etc/php/conf.d/00-php.ini <<EOF
short_open_tag = On
expose_php = Off
error_reporting = ${PHP_ERROR_REPORTING:-E_ALL}
display_errors = ${PHP_DISPLAY_ERRORS:-off}
display_startup_errors = Off
log_errors = On
error_log = /dev/stderr
ignore_repeated_errors = Off
register_globals = On
date.timezone = Asia/Bangkok
session.save_handler = ${SESSION_SAVE_HANDLER:-memcache}
session.save_path = ${SESSION_SAVE_PATH:-tcp://memcached:11211}
session.gc_probability = 1
EOF

# Update Apache log level at runtime
sed -i "s/LogLevel .*/LogLevel ${LOG_OUTPUT_LEVEL:-error}/" /etc/apache2/apache2.conf

# Execute the main command (apache2-foreground)
exec "$@"
