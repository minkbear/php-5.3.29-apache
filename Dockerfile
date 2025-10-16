# Extract memcache.so from webdevops image
FROM webdevops/php-nginx:ubuntu-12.04 AS memcache-source

FROM drupalci/php-5.3.29-apache:production AS base

# Copy memcache extension and config from webdevops image
COPY --from=memcache-source /usr/lib/php5/20090626/memcache.so /usr/local/lib/php/extensions/no-debug-non-zts-20090626/memcache.so
COPY --from=memcache-source /etc/php5/conf.d/memcache.ini /usr/local/etc/php/conf.d/memcache.ini

ENV SESSION_SAVE_HANDLER=memcache \
    SESSION_SAVE_PATH="tcp://memcached:11211"

# Configure PHP settings
RUN { \
    echo "short_open_tag = On"; \
    echo "error_reporting = E_ERROR"; \
    echo "register_globals = On"; \
    echo "session.save_handler = \${SESSION_SAVE_HANDLER}"; \
    echo "session.save_path = \${SESSION_SAVE_PATH}"; \
    echo "session.gc_probability = 1"; \
    } >> /usr/local/etc/php/conf.d/00-php.ini

# Configure Apache DocumentRoot
RUN sed -i 's|/var/www/html|/var/www/html|g' /etc/apache2/sites-available/000-default.conf && \
    echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Enable Apache rewrite module
RUN a2enmod rewrite

# Install composer
COPY --from=composer:1.10.27 /usr/bin/composer /usr/local/bin/composer
RUN composer --version

WORKDIR /var/www/html

# Expose Apache port
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]