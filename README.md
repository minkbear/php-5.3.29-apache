# PHP 5.3.29 Apache Docker Image

🐘 Legacy PHP 5.3.29 with Apache 2.x, Memcache extension, and OWASP security hardening

[![Docker Hub](https://img.shields.io/badge/docker-minkbear%2Fphp--5.3.29--apache-blue)](https://hub.docker.com/r/minkbear/php-5.3.29-apache)
[![Security](https://img.shields.io/badge/security-OWASP-green)](https://owasp.org/)

## 📋 Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Security Features](#security-features)
- [Usage](#usage)
- [Building](#building)
- [Testing](#testing)
- [Configuration](#configuration)
- [Docker Hub](#docker-hub)

## ✨ Features

### Core Components
- **PHP 5.3.29** - Legacy PHP version for old applications
- **Apache 2.x** - HTTP server
- **Memcache Extension** - Session storage and caching
- **Composer 1.10.27** - Dependency management

### Security Hardening (OWASP Compliant)
- ✅ **PHP Security Configuration**
  - `expose_php = Off` - Hide PHP version
  - `display_errors = Off` - Don't show errors to users
  - `log_errors = On` - Log errors for debugging
  - `register_globals = Off` - Prevent security vulnerabilities

- ✅ **Apache Security Features**
  - Sensitive file protection (.env, .git, composer files)
  - Path traversal attack prevention
  - Directory listing disabled
  - Security headers (X-Content-Type-Options, X-Frame-Options, X-XSS-Protection)
  - URL encoding bypass protection

### Session Management
- Configurable session handler (memcache/files)
- Environment-based configuration
- Memcached integration ready

## 🚀 Quick Start

### Pull from Docker Hub

```bash
# Pull latest version
docker pull minkbear/php-5.3.29-apache:latest

# Pull specific version
docker pull minkbear/php-5.3.29-apache:20251016

# Run container
docker run -d -p 8080:80 \
  -v $(pwd)/app:/var/www/html \
  minkbear/php-5.3.29-apache:latest
```

### Using Docker Compose

```yaml
version: '3.8'

services:
  app:
    image: minkbear/php-5.3.29-apache:20251016
    ports:
      - "8080:80"
    volumes:
      - ./app:/var/www/html
    environment:
      - SESSION_SAVE_HANDLER=memcache
      - SESSION_SAVE_PATH=tcp://memcached:11211
    depends_on:
      - memcached

  memcached:
    image: memcached:1.6-alpine
    ports:
      - "11211:11211"
```

Then run:
```bash
docker-compose up -d
```

Access your application at: http://localhost:8080

## 🛡️ Security Features

### Protected Files and Directories

The following are automatically blocked by Apache configuration:

| Category | Files/Extensions | HTTP Status |
|----------|------------------|-------------|
| Environment | `.env`, `.env.*` | 403 Forbidden |
| Version Control | `.git/`, `.gitignore` | 403 Forbidden |
| Package Managers | `composer.json`, `package.json` | 403 Forbidden |
| Backups | `.bak`, `.backup`, `.old`, `.sql` | 403 Forbidden |
| Configuration | `.ini`, `.conf`, `.yml`, `.yaml` | 403 Forbidden |
| Logs | `.log` files | 403 Forbidden |
| Apache | `.htaccess`, `.htpasswd` | 403 Forbidden |

### Attack Prevention

- **Path Traversal**: `../` patterns blocked
- **URL Encoding Bypass**: Malformed URLs rejected (HTTP 400)
- **Directory Listing**: Disabled
- **Sensitive Headers**: Set automatically

### Security Headers

```
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 1; mode=block
```

## 📖 Usage

### Basic PHP Application

```bash
# Create your application directory
mkdir -p app
echo "<?php phpinfo(); ?>" > app/index.php

# Run container
docker run -d -p 8080:80 \
  -v $(pwd)/app:/var/www/html \
  minkbear/php-5.3.29-apache:latest

# Visit http://localhost:8080
```

### With Memcached Session

```bash
docker-compose up -d
```

Your sessions will be stored in Memcached automatically.

### Custom PHP Configuration

Create a custom PHP ini file:

```bash
# custom-php.ini
upload_max_filesize = 50M
post_max_size = 50M
memory_limit = 256M
max_execution_time = 300
```

Mount it in your container:

```yaml
services:
  app:
    image: minkbear/php-5.3.29-apache:20251016
    volumes:
      - ./app:/var/www/html
      - ./custom-php.ini:/usr/local/etc/php/conf.d/custom.ini
```

## 🔨 Building

### Prerequisites

- Docker installed
- Docker Hub account (for pushing)

### Build Locally

```bash
# Clone or navigate to repository
cd /path/to/mb-php-5.3.29-apache

# Build image
docker build -t minkbear/php-5.3.29-apache:20251016 .

# Test the build
docker run -d -p 8080:80 minkbear/php-5.3.29-apache:20251016
```

### Build and Push to Docker Hub

#### Quick Start

```bash
# Login to Docker Hub
docker login

# Build and push (default: current date as version tag)
./build-and-push.sh

# Build with specific version
./build-and-push.sh --version 20251016
```

#### Advanced Options

```bash
# Build without pushing (testing)
./build-and-push.sh --no-push

# Build with multiple tags
./build-and-push.sh \
  --version 20251016 \
  --tags stable,production

# Build without cache
./build-and-push.sh --no-cache

# View all options
./build-and-push.sh --help
```

#### Using Configuration File

```bash
# Copy and edit config
cp .env.docker .env.docker.local
nano .env.docker.local

# Run with config
./build-and-push.sh
```

**Example .env.docker.local:**
```bash
DOCKER_USERNAME=minkbear
IMAGE_NAME=php-5.3.29-apache
VERSION_TAG=20251016
BUILD_NO_CACHE=false
ADDITIONAL_TAGS=stable,production
```

For detailed build instructions, see [BUILD.md](BUILD.md)

## 🧪 Testing

### Security Tests

Run comprehensive security tests:

```bash
# Start test environment
docker-compose up -d

# Run security tests
./tests/security-test.sh

# Or use automated test runner
./tests/run-tests.sh
```

**Test Coverage:**
- ✅ .env file protection (4 tests)
- ✅ .git directory protection (4 tests)
- ✅ Composer files protection (4 tests)
- ✅ Backup files protection (5 tests)
- ✅ Config files protection (5 tests)
- ✅ Log files protection (3 tests)
- ✅ Apache hidden files (2 tests)
- ✅ Path traversal attacks (5 tests)
- ✅ URL encoding bypass (3 tests)
- ✅ Normal access validation (2 tests)

**Total: 37 security tests**

### Manual Testing

```bash
# Test sensitive file blocking
curl -I http://localhost:8080/.env          # Should return 403
curl -I http://localhost:8080/.git/config   # Should return 403
curl -I http://localhost:8080/composer.json # Should return 403

# Test path traversal protection
curl -I http://localhost:8080/../etc/passwd # Should return 403

# Test normal access
curl -I http://localhost:8080/              # Should return 200
curl -I http://localhost:8080/index.php     # Should return 200
```

## ⚙️ Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SESSION_SAVE_HANDLER` | `memcache` | Session handler (files/memcache) |
| `SESSION_SAVE_PATH` | `tcp://memcached:11211` | Session save path |

### PHP Configuration

Custom PHP settings are in `/usr/local/etc/php/conf.d/00-php.ini`:

```ini
short_open_tag = Off
expose_php = Off
error_reporting = E_ALL
display_errors = Off
display_startup_errors = Off
log_errors = On
ignore_repeated_errors = Off
register_globals = Off
```

### Apache Configuration

Security configuration at `/etc/apache2/conf-available/security-hardening.conf`

To view configuration:
```bash
docker exec <container-id> cat /etc/apache2/conf-available/security-hardening.conf
```

## 🐳 Docker Hub

### Image Tags

| Tag | Description |
|-----|-------------|
| `latest` | Latest stable build |
| `20251016` | Version dated 2025-10-16 |
| `stable` | Stable release (if tagged) |
| `production` | Production-ready (if tagged) |

### Pull Commands

```bash
# Latest version
docker pull minkbear/php-5.3.29-apache:latest

# Specific version
docker pull minkbear/php-5.3.29-apache:20251016

# View on Docker Hub
open https://hub.docker.com/r/minkbear/php-5.3.29-apache
```

## 📂 Project Structure

```
.
├── Dockerfile                      # Main Docker image definition
├── docker-compose.yml              # Docker Compose configuration
├── build-and-push.sh              # Build and push script
├── .env.docker                    # Build configuration
├── README.md                      # This file
├── BUILD.md                       # Detailed build instructions
└── tests/
    ├── security-test.sh           # Security test suite
    ├── run-tests.sh               # Automated test runner
    ├── README.md                  # Testing documentation
    └── test-files/                # Test files
        ├── .env
        ├── composer.json
        ├── config.ini
        ├── error.log
        └── index.php
```

## 🔧 Troubleshooting

### Container won't start

```bash
# Check logs
docker-compose logs app

# Check Apache config
docker exec <container-id> apache2ctl -t

# Rebuild without cache
docker-compose build --no-cache
```

### Security tests failing

```bash
# Ensure container is running
docker-compose ps

# Wait for Apache to start
sleep 5

# Run tests with verbose mode
VERBOSE=1 ./tests/security-test.sh

# Check Apache error log
docker exec <container-id> cat /var/log/apache2/error.log
```

### Permission issues

```bash
# Fix file permissions
chmod -R 755 app/
chown -R $USER:$USER app/

# Or run container with user
docker run -u $(id -u):$(id -g) ...
```

### Memcached connection issues

```bash
# Check memcached is running
docker-compose ps memcached

# Test connection
docker exec <app-container> telnet memcached 11211

# Check network
docker network inspect php_legacy_network
```

## 📝 Notes

### ⚠️ Legacy PHP Warning

PHP 5.3.29 is **extremely outdated** and **no longer supported**. It has known security vulnerabilities. Use this image only for:

- Legacy application maintenance
- Migration testing
- Development environments (never production)

**Recommendations:**
- Migrate to PHP 7.4+ or PHP 8.x as soon as possible
- Keep this image isolated from the internet
- Use only in controlled environments
- Apply all available security measures

### Security Considerations

Even with OWASP hardening:
- Keep the container isolated
- Use behind reverse proxy (nginx/traefik)
- Implement additional WAF if needed
- Monitor logs regularly
- Don't expose directly to internet

## 📄 License

This Docker image configuration is provided as-is for legacy application support.

## 🤝 Contributing

Issues and pull requests are welcome for:
- Security improvements
- Documentation updates
- Bug fixes
- Test enhancements

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [PHP Security Best Practices](https://www.php.net/manual/en/security.php)
- [Apache Security Tips](https://httpd.apache.org/docs/2.4/misc/security_tips.html)

## 📞 Support

For issues and questions:
- GitHub Issues: [Create an issue](#)
- Docker Hub: https://hub.docker.com/r/minkbear/php-5.3.29-apache

---

**Built with ❤️ for legacy PHP applications**

⚠️ Remember: This is a legacy image. Please migrate to modern PHP versions!
