# Security Test Suite

## Overview
Test suite สำหรับทดสอบการป้องกันความปลอดภัยของ Apache ตามมาตรฐาน OWASP

## Test Cases

### 1. .env File Protection
- ทดสอบการป้องกันไฟล์ `.env` และตัวแปรต่างๆ
- Files: `.env`, `.env.local`, `.env.production`

### 2. .git Directory Protection
- ทดสอบการป้องกัน Git repository
- Files: `.git/config`, `.git/HEAD`, `.gitignore`

### 3. Composer Files Protection
- ทดสอบการป้องกันไฟล์ Composer
- Files: `composer.json`, `composer.lock`, `package.json`

### 4. Backup Files Protection
- ทดสอบการป้องกันไฟล์ backup
- Extensions: `.bak`, `.backup`, `.old`, `.tmp`, `.sql`

### 5. Config Files Protection
- ทดสอบการป้องกันไฟล์ configuration
- Extensions: `.ini`, `.config`, `.yml`, `.yaml`, `.conf`

### 6. Log Files Protection
- ทดสอบการป้องกันไฟล์ log
- Extensions: `.log`

### 7. Apache Hidden Files Protection
- ทดสอบการป้องกัน Apache files
- Files: `.htaccess`, `.htpasswd`

### 8. Path Traversal Attacks
- ทดสอบการป้องกัน path traversal
- Patterns: `../`, `../../`, etc.

### 9. URL Encoding Bypass
- ทดสอบการป้องกัน URL encoding bypass
- Patterns: `%2e%2e/`, `..%252f`, etc.

### 10. Normal Access
- ทดสอบการเข้าถึงไฟล์ปกติ
- Files: `/`, `index.php`

## วิธีใช้งาน

### 1. Build และ Start Container
```bash
# Build image
docker-compose build

# Start containers
docker-compose up -d

# ตรวจสอบสถานะ
docker-compose ps
```

### 2. รัน Security Tests
```bash
# รัน test script
./tests/security-test.sh

# หรือระบุ URL เอง
BASE_URL=http://localhost:8080 ./tests/security-test.sh
```

### 3. ทดสอบแบบ Manual
```bash
# ทดสอบ .env file (ควรได้ 403)
curl -I http://localhost:8080/.env

# ทดสอบ path traversal (ควรได้ 403)
curl -I http://localhost:8080/../etc/passwd

# ทดสอบ normal access (ควรได้ 200)
curl -I http://localhost:8080/
```

### 4. ดู Logs
```bash
# Apache access logs
docker-compose logs app

# Apache error logs
docker exec php_legacy_dev cat /var/log/apache2/error.log
```

### 5. Stop และ Cleanup
```bash
# Stop containers
docker-compose down

# Remove volumes
docker-compose down -v
```

## Expected Results

### ✅ PASS - ควรได้ HTTP Status Code:
- `403 Forbidden` - สำหรับไฟล์ sensitive ที่ถูกบล็อก
- `404 Not Found` - สำหรับไฟล์ที่ไม่มีอยู่
- `200 OK` - สำหรับไฟล์ปกติที่เข้าถึงได้

### ❌ FAIL - ถ้าได้ HTTP Status Code:
- `200 OK` - สำหรับไฟล์ sensitive (หมายความว่าสามารถเข้าถึงได้)
- `301/302 Redirect` - อาจมีปัญหาการ redirect

## Test Files Structure
```
tests/
├── security-test.sh          # Main test script
├── test-files/               # Test files directory
│   ├── .env                  # Should be blocked
│   ├── composer.json         # Should be blocked
│   ├── config.ini            # Should be blocked
│   ├── backup.sql            # Should be blocked
│   ├── error.log             # Should be blocked
│   └── index.php             # Should be accessible
└── README.md                 # This file
```

## Security Configurations

การตั้งค่าความปลอดภัยที่ทดสอบ:

1. **PHP Security** (php.ini)
   - `expose_php = Off`
   - `display_errors = Off`
   - `log_errors = On`

2. **Apache Security** (security-hardening.conf)
   - FilesMatch directives
   - DirectoryMatch directives
   - RewriteRules for path traversal
   - Security headers

3. **HTTP Security Headers**
   - `X-Content-Type-Options: nosniff`
   - `X-Frame-Options: SAMEORIGIN`
   - `X-XSS-Protection: 1; mode=block`

## Troubleshooting

### Test ล้มเหลว
```bash
# ตรวจสอบ Apache config
docker exec php_legacy_dev apache2ctl -t

# ตรวจสอบ security config
docker exec php_legacy_dev cat /etc/apache2/conf-available/security-hardening.conf

# ตรวจสอบว่า config ถูก enable
docker exec php_legacy_dev ls -la /etc/apache2/conf-enabled/
```

### Container ไม่ start
```bash
# ดู logs
docker-compose logs app

# Build ใหม่
docker-compose build --no-cache
docker-compose up -d
```
