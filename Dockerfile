# Extract memcache.so from webdevops image
FROM webdevops/php-nginx:ubuntu-12.04 AS memcache-source

FROM drupalci/php-5.3.29-apache:production AS base

# Copy memcache extension and config from webdevops image
COPY --from=memcache-source /usr/lib/php5/20090626/memcache.so /usr/local/lib/php/extensions/no-debug-non-zts-20090626/memcache.so
COPY --from=memcache-source /etc/php5/conf.d/memcache.ini /usr/local/etc/php/conf.d/memcache.ini

ENV SESSION_SAVE_HANDLER=memcache \
    SESSION_SAVE_PATH="tcp://memcached:11211"

# Configure PHP settings (OWASP security hardening)
RUN { \
    echo "short_open_tag = On"; \
    echo "expose_php = Off"; \
    echo "error_reporting = E_ALL"; \
    echo "display_errors = Off"; \
    echo "display_startup_errors = Off"; \
    echo "log_errors = On"; \
    echo "ignore_repeated_errors = Off"; \
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

# Start Apache
CMD ["apache2-foreground"]