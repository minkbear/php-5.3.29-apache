# Docker Build and Push Guide

คู่มือการ build และ push Docker image ไปยัง Docker Hub

## 📦 Build Script

**`build-and-push.sh`** - Script สำหรับ build และ push Docker image
- รองรับ command-line options
- Load config จากไฟล์
- สร้าง multiple tags
- Build แบบ --no-cache
- Test container startup
- --no-push สำหรับ test build
- Validation และ error handling

## 🚀 วิธีใช้งาน

### Quick Start

```bash
# ใช้ค่า default (version = วันที่ปัจจุบัน)
./build-and-push.sh

# กำหนด version
./build-and-push.sh --version 20251016

# Build อย่างเดียว ไม่ push
./build-and-push.sh --no-push

# Build แบบ no cache
./build-and-push.sh --no-cache

# เพิ่ม tags เพิ่มเติม
./build-and-push.sh --tags stable,production,v1.0.0

# กำหนด username และ version
./build-and-push.sh --username myuser --version v1.0.0

# ดู help
./build-and-push.sh --help
```

### ใช้ Environment Variables

```bash
# กำหนด version tag
VERSION_TAG=20251016 ./build-and-push.sh

# กำหนด username
DOCKER_USERNAME=myusername ./build-and-push.sh

# กำหนดหลายค่าพร้อมกัน
DOCKER_USERNAME=myuser VERSION_TAG=v1.0.0 ./build-and-push.sh
```

## ⚙️ Configuration

### ใช้ไฟล์ config (.env.docker)

```bash
# Copy ไฟล์ config
cp .env.docker .env.docker.local

# แก้ไขค่าตามต้องการ
nano .env.docker.local
```

**ตัวอย่าง .env.docker.local:**
```bash
DOCKER_USERNAME=myusername
IMAGE_NAME=php-5.3.29-apache
VERSION_TAG=20251016
BUILD_NO_CACHE=true
ADDITIONAL_TAGS=stable,production
```

Script จะโหลดไฟล์ตามลำดับ:
1. `.env.docker.local` (ถ้ามี - สำหรับ local override)
2. `.env.docker` (default config)

## 🔐 Docker Hub Authentication

### Login ครั้งแรก

```bash
docker login
# Username: minkbear
# Password: [your-token]
```

### ใช้ Access Token (แนะนำ)

1. ไปที่ Docker Hub → Account Settings → Security → New Access Token
2. สร้าง token และ copy
3. Login ด้วย token:

```bash
docker login -u minkbear
# Password: [paste-your-token]
```

## 📋 Command-Line Options

| Option | Description | Example |
|--------|-------------|---------|
| `-u, --username` | Docker Hub username | `--username myuser` |
| `-v, --version` | Version tag | `--version 20251016` |
| `--no-cache` | Build without cache | `--no-cache` |
| `--quiet` | Quiet build output | `--quiet` |
| `--no-push` | Build only, don't push | `--no-push` |
| `--tags` | Additional tags (comma-separated) | `--tags stable,prod` |
| `-h, --help` | Show help message | `--help` |

## 🎯 Use Cases

### Development Build (ไม่ push)
```bash
./build-and-push.sh --no-push
```

### Production Release
```bash
./build-and-push.sh \
  --version 20251016 \
  --tags stable,production \
  --no-cache
```

### Quick Test Build
```bash
./build-and-push.sh \
  --version test \
  --no-push \
  --quiet
```

### Multi-tag Release
```bash
./build-and-push.sh \
  --version 1.0.0 \
  --tags 1.0,1,stable,latest
```

### Daily Build with Date Tag
```bash
# ใช้วันที่เป็น tag (auto)
./build-and-push.sh

# หรือระบุเอง
./build-and-push.sh --version $(date +%Y%m%d)
```

## 🔍 Verification

### ตรวจสอบ local images
```bash
docker images minkbear/php-5.3.29-apache
```

### ทดสอบรัน image
```bash
docker run -d -p 8080:80 minkbear/php-5.3.29-apache:20251016
curl http://localhost:8080/
```

### ดูบน Docker Hub
```
https://hub.docker.com/r/minkbear/php-5.3.29-apache
```

## 📊 Build Process

Script จะทำตามลำดับดังนี้:

1. **[1/6] Authentication** - ตรวจสอบ Docker login
2. **[2/6] Build** - Build Docker image
3. **[3/6] Tagging** - สร้าง tags ต่างๆ
4. **[4/6] Info** - แสดงข้อมูล image
5. **[5/6] Push** - Push ไป Docker Hub (ถ้าไม่ใช้ --no-push)
6. **[6/6] Test** - ทดสอบ start container

## 🛡️ Security Best Practices

1. **ใช้ Access Token แทน Password**
   - สร้าง token ที่ Docker Hub
   - ตั้งค่า scope ให้เหมาะสม (Read & Write)

2. **ไม่ commit credentials**
   - `.env.docker.local` อยู่ใน .gitignore
   - ไม่ hard-code username/password ใน script

3. **ตรวจสอบ image ก่อน push**
   - ใช้ `--no-push` เพื่อ build และ test ก่อน
   - Scan vulnerabilities ด้วย `docker scan`

## 🔧 Troubleshooting

### Error: denied: requested access to the resource is denied
```bash
# ต้อง login ก่อน
docker login
```

### Error: unauthorized: authentication required
```bash
# Token หมดอายุ หรือไม่ถูกต้อง
docker logout
docker login
```

### Build ช้า
```bash
# ใช้ cache (default)
./build-and-push.sh

# หรือถ้าต้องการ fresh build
./build-and-push.sh --no-cache
```

### Image ใหญ่เกินไป
```bash
# ดูขนาด layers
docker history minkbear/php-5.3.29-apache:20251016

# ทำ cleanup
docker system prune -a
```

### Script ไม่สามารถรันได้
```bash
# ตรวจสอบ permission
ls -la build-and-push.sh

# ถ้ายังไม่ executable
chmod +x build-and-push.sh
```

## 📝 Examples

### Example 1: Simple Daily Build
```bash
# ใช้ default (tag = วันที่ปัจจุบัน)
./build-and-push.sh
```

**ผลลัพธ์:**
- Tag: `minkbear/php-5.3.29-apache:20251016` (วันที่ปัจจุบัน)
- Tag: `minkbear/php-5.3.29-apache:latest`
- Push ทั้ง 2 tags

### Example 2: Version Release
```bash
./build-and-push.sh \
  --version 1.0.0 \
  --tags 1.0,1,stable \
  --no-cache
```

**ผลลัพธ์:**
- Tag: `minkbear/php-5.3.29-apache:1.0.0`
- Tag: `minkbear/php-5.3.29-apache:1.0`
- Tag: `minkbear/php-5.3.29-apache:1`
- Tag: `minkbear/php-5.3.29-apache:stable`
- Tag: `minkbear/php-5.3.29-apache:latest`
- Push ทั้งหมด

### Example 3: Test Build
```bash
./build-and-push.sh \
  --version test-$(date +%H%M) \
  --no-push
```

**ผลลัพธ์:**
- Build แต่ไม่ push
- Tag: `minkbear/php-5.3.29-apache:test-1947`
- เก็บไว้ที่ local เท่านั้น

### Example 4: CI/CD Pipeline
```bash
#!/bin/bash
set -e

# Get version from git tag
VERSION=$(git describe --tags --always)

# Build and push
./build-and-push.sh \
  --version "$VERSION" \
  --tags latest \
  --quiet

echo "✓ Build completed: $VERSION"
```

### Example 5: Multi-environment Release
```bash
# Production
./build-and-push.sh \
  --version 2.0.0 \
  --tags production,stable,latest \
  --no-cache

# Staging
./build-and-push.sh \
  --version 2.0.0-rc1 \
  --tags staging \
  --no-push  # Build only, manual push later
```

## 🌐 Pull Image from Docker Hub

หลังจาก push แล้ว คนอื่นสามารถ pull ได้:

```bash
# Pull specific version
docker pull minkbear/php-5.3.29-apache:20251016

# Pull latest
docker pull minkbear/php-5.3.29-apache:latest

# Pull with tag
docker pull minkbear/php-5.3.29-apache:stable
```

### ใช้ใน docker-compose.yml
```yaml
services:
  app:
    image: minkbear/php-5.3.29-apache:20251016
    ports:
      - "80:80"
    volumes:
      - ./app:/var/www/html
```

### ใช้ใน Dockerfile
```dockerfile
FROM minkbear/php-5.3.29-apache:20251016

# Add your customizations
COPY app/ /var/www/html/
```

## 💡 Tips & Tricks

### 1. Auto-versioning
```bash
# ใช้ git tag
VERSION=$(git describe --tags --always)
./build-and-push.sh --version "$VERSION"

# ใช้ git commit hash
VERSION=$(git rev-parse --short HEAD)
./build-and-push.sh --version "$VERSION"
```

### 2. Conditional Push
```bash
# Push เฉพาะ branch main
if [ "$GIT_BRANCH" == "main" ]; then
  ./build-and-push.sh --version production
else
  ./build-and-push.sh --no-push
fi
```

### 3. Build Matrix
```bash
# Build หลาย version
for version in v1.0.0 v1.1.0 v2.0.0; do
  ./build-and-push.sh --version "$version"
done
```

### 4. Dry Run
```bash
# ดูว่าจะทำอะไรบ้าง โดยไม่ push จริง
./build-and-push.sh --no-push --version test
```

## 📚 Additional Resources

- Docker Hub: https://hub.docker.com/r/minkbear/php-5.3.29-apache
- Docker Documentation: https://docs.docker.com/
- Best Practices: https://docs.docker.com/develop/dev-best-practices/
- Docker Build Reference: https://docs.docker.com/engine/reference/commandline/build/
- Docker Push Reference: https://docs.docker.com/engine/reference/commandline/push/

## 🎓 Learning Resources

- [Docker Build Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Docker Image Tagging](https://docs.docker.com/engine/reference/commandline/tag/)
- [CI/CD with Docker](https://docs.docker.com/ci-cd/)
- [Docker Security](https://docs.docker.com/engine/security/)
