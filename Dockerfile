# Extract memcache.so from webdevops image
FROM webdevops/php-nginx:ubuntu-12.04 AS memcache-source

FROM drupalci/php-5.3.29-apache:production AS base

# Copy memcache extension and config from webdevops image
COPY --from=memcache-source /usr/lib/php5/20090626/memcache.so /usr/local/lib/php/extensions/no-debug-non-zts-20090626/memcache.so
COPY --from=memcache-source /etc/php5/conf.d/memcache.ini /usr/local/etc/php/conf.d/memcache.ini

ENV SESSION_SAVE_HANDLER=memcache \
    SESSION_SAVE_PATH="tcp://memcached:11211" \
    LOG_OUTPUT_LEVEL=error \
    PHP_DISPLAY_ERRORS=off \
    PHP_ERROR_REPORTING="E_ALL"

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Configure Apache DocumentRoot and Logging
RUN sed -i 's|/var/www/html|/var/www/html|g' /etc/apache2/sites-available/000-default.conf && \
    echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
    { \
        echo ""; \
        echo "# CustomLog directive to conditionally log requests"; \
        echo "LogFormat \"%l %u %t %v %a \\\"%r\\\" %>s %b\" comonvhost"; \
        echo "CustomLog /dev/stdout comonvhost env=!dontlog"; \
        echo ""; \
        echo "# Configure Log Settings"; \
        echo "ErrorLog /dev/stderr"; \
        echo "LogLevel error"; \
        echo ""; \
        echo "# Disable Server Signature for increased security"; \
        echo "ServerSignature Off"; \
    } >> /etc/apache2/apache2.conf

# Enable Apache rewrite module
RUN a2enmod rewrite

# Configure Apache security settings (OWASP protection)
RUN { \
    echo "<Directory /var/www/html>"; \
    echo "    Options -Indexes +FollowSymLinks"; \
    echo "    AllowOverride All"; \
    echo "    Require all granted"; \
    echo ""; \
    echo "    # Prevent path traversal attacks"; \
    echo "    RewriteEngine On"; \
    echo "    RewriteCond %{REQUEST_URI} \\.\\./"; \
    echo "    RewriteRule .* - [F,L]"; \
    echo ""; \
    echo "    # Block access to sensitive files"; \
    echo "    <FilesMatch \"^\\.(env|git|htaccess|htpasswd)\">"; \
    echo "        Require all denied"; \
    echo "    </FilesMatch>"; \
    echo ""; \
    echo "    <FilesMatch \"\\.(env|log|sql|bak|backup|old|tmp|conf|config|ini|yml|yaml)$\">"; \
    echo "        Require all denied"; \
    echo "    </FilesMatch>"; \
    echo ""; \
    echo "    # Block access to composer and package files"; \
    echo "    <FilesMatch \"(composer\\.(json|lock)|package(-lock)?\\.json)\">"; \
    echo "        Require all denied"; \
    echo "    </FilesMatch>"; \
    echo "</Directory>"; \
    echo ""; \
    echo "# Deny access to .git directory"; \
    echo "<DirectoryMatch \"/\\.git\">"; \
    echo "    Require all denied"; \
    echo "</DirectoryMatch>"; \
    echo ""; \
    echo "# Security headers"; \
    echo "Header set X-Content-Type-Options \"nosniff\""; \
    echo "Header set X-Frame-Options \"SAMEORIGIN\""; \
    echo "Header set X-XSS-Protection \"1; mode=block\""; \
    } > /etc/apache2/conf-available/security-hardening.conf && \
    a2enconf security-hardening && \
    a2enmod headers

# Install composer
COPY --from=composer:1.10.27 /usr/bin/composer /usr/local/bin/composer
RUN composer --version

WORKDIR /var/www/html

# Expose Apache port
EXPOSE 80

# Set entrypoint and default command
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]