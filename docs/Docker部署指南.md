# 瑞吉外卖系统 Docker 部署指南

## 目录

- [项目概述](#项目概述)
- [部署架构](#部署架构)
- [环境准备](#环境准备)
- [部署步骤](#部署步骤)
- [访问验证](#访问验证)
- [常用命令](#常用命令)
- [常见问题](#常见问题)

---

## 项目概述

瑞吉外卖系统是一个完整的外卖平台，包含：
- **管理后台**（商家端）：用于餐厅管理、菜单管理、订单管理等
- **用户端**（C端）：用于用户浏览、下单、支付等
- **API文档**：Knife4j 接口文档

**技术栈**：
- 后端：Spring Boot 2.4.5 + MyBatis Plus
- 数据库：MySQL 8.0 + Redis 7.0
- 前端：HTML + CSS + JavaScript
- 部署：Docker + Docker Compose

---

## 部署架构

```
阿里云服务器（单节点）
┌─────────────────────────────────────────────────────┐
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │  Docker Compose                                │ │
│  │                                               │ │
│  │  ┌─────────────┐  ┌─────────────┐          │ │
│  │  │   Nginx     │  │  takeout-   │          │ │
│  │  │  (80/443)   │  │   app       │          │ │
│  │  │  反向代理    │  │  (9001)     │          │ │
│  │  └─────────────┘  └─────────────┘          │ │
│  │         │                │                    │ │
│  │  ┌──────▼────────────────▼──────┐           │ │
│  │  │                              │           │ │
│  │  │  ┌───────────────────────┐  │           │ │
│  │  │  │  MySQL (3306)        │  │           │ │
│  │  │  │  ruiji数据库          │  │           │ │
│  │  │  └───────────────────────┘  │           │ │
│  │  │                              │           │ │
│  │  │  ┌───────────────────────┐  │           │ │
│  │  │  │  Redis (6379)         │  │           │ │
│  │  │  └───────────────────────┘  │           │ │
│  │  └──────────────────────────────┘           │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## 环境准备

### 1. 阿里云服务器配置

**推荐配置（个人学习）**：
- 操作系统：CentOS 7.9 或 Ubuntu 20.04+
- CPU：2核及以上
- 内存：4GB及以上
- 磁盘：40GB及以上

**安全组配置**（阿里云控制台）：
```
入方向规则：
- 80端口（HTTP）：允许0.0.0.0/0访问
- 443端口（HTTPS）：允许0.0.0.0/0访问
- 22端口（SSH）：仅允许你的IP访问（安全考虑）

出方向规则：
- 全部端口：允许
```

### 2. 安装 Docker

```bash
# CentOS/RHEL 安装 Docker
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun

# Ubuntu 安装 Docker
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun

# 启动 Docker
systemctl start docker
systemctl enable docker

# 验证安装
docker --version
docker info
```

### 3. 安装 Docker Compose

```bash
# 下载 Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# 赋予执行权限
chmod +x /usr/local/bin/docker-compose

# 验证安装
docker-compose --version
```

### 4. 配置 Docker 镜像加速（可选但推荐）

```bash
# 创建 Docker 配置目录
mkdir -p /etc/docker

# 配置镜像加速器（使用阿里云镜像加速）
cat > /etc/docker/daemon.json << 'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ]
}
EOF

# 重启 Docker
systemctl daemon-reload
systemctl restart docker
```

---

## 部署步骤

### 1. 上传项目到服务器

```bash
# 方式一：使用 Git 克隆
git clone <你的项目地址>
cd takeout-system

# 方式二：使用 scp 上传本地项目到服务器
# 在本地终端执行：
scp -r /path/to/takeout-system root@your_server_ip:/root/
```

### 2. 检查项目文件

```bash
cd /root/takeout-system

# 确保以下文件存在：
ls -la
# - docker-compose.yml
# - Dockerfile
# - deploy.sh
# - src/main/resources/application-prod.yml
# - SQL文件/ruiji.sql
# - pom.xml
```

### 3. 配置权限

```bash
# 赋予部署脚本执行权限
chmod +x deploy.sh

# 创建必要的目录
mkdir -p mysql/data mysql/conf redis/data redis/conf \
         nginx/conf.d nginx/html nginx/logs \
         app/logs app/pic
```

### 4. 检查 Maven 是否安装（可选，如果服务器已编译过可以跳过）

```bash
# 如果服务器没有 Maven，可以在本地编译好 jar 包后再上传
# 本地编译：
mvn clean package -DskipTests

# 然后上传 target 目录下的 jar 包
```

### 5. 开始部署

#### 方式一：使用一键部署脚本（推荐）

```bash
# 完整部署流程（编译+构建+启动）
./deploy.sh deploy
```

#### 方式二：手动分步部署

```bash
# 1. 编译项目
mvn clean package -DskipTests

# 2. 启动服务
docker-compose up -d

# 3. 查看状态
docker-compose ps

# 4. 查看日志
docker-compose logs -f takeout-app
```

### 6. 验证部署

部署完成后，等待约 1-2 分钟让服务完全启动，然后验证：

```bash
# 检查容器状态
docker-compose ps

# 查看应用日志
docker-compose logs --tail 50 takeout-app
```

---

## 访问验证

### 1. 获取服务器公网IP

在阿里云控制台查看 ECS 实例的公网 IP，例如：`47.100.100.100`

### 2. 访问地址

| 服务 | 地址 | 说明 |
|------|------|------|
| 管理后台 | `http://47.100.100.100/backend/page/login/login.html` | 账号：admin / 密码：admin |
| 用户端 | `http://47.100.100.100/front/index.html` | 用户登录页面 |
| API文档 | `http://47.100.100.100/doc.html` | Knife4j 接口文档 |

### 3. 登录测试

#### 管理后台登录
- 访问：http://你的IP/backend/page/login/login.html
- 账号：admin
- 密码：admin

#### 用户端登录
- 访问：http://你的IP/front/index.html
- 需要使用手机号 + 验证码登录（验证码在日志中查看）

查看用户端验证码：
```bash
docker-compose logs takeout-app | grep -i "验证码"
```

---

## 常用命令

### 1. 服务管理命令

```bash
# 启动所有服务
docker-compose up -d

# 停止所有服务
docker-compose stop

# 重启所有服务
docker-compose restart

# 停止并删除容器
docker-compose down

# 查看服务状态
docker-compose ps
```

### 2. 查看日志

```bash
# 查看所有服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f takeout-app
docker-compose logs -f mysql
docker-compose logs -f redis

# 查看最近 100 行日志
docker-compose logs --tail 100 takeout-app
```

### 3. 进入容器

```bash
# 进入应用容器
docker-compose exec takeout-app sh

# 进入 MySQL 容器
docker-compose exec mysql bash

# 进入 Redis 容器
docker-compose exec redis sh

# 进入 Nginx 容器
docker-compose exec nginx sh
```

### 4. 数据库操作

```bash
# 连接 MySQL
docker-compose exec mysql mysql -uroot -ptakeout123! ruiji

# 备份数据库
docker-compose exec mysql mysqldump -uroot -ptakeout123! ruiji > backup_$(date +%Y%m%d).sql

# 恢复数据库
docker-compose exec -T mysql mysql -uroot -ptakeout123! ruiji < backup.sql
```

### 5. Redis 操作

```bash
# 连接 Redis
docker-compose exec redis redis-cli -a takeout123!

# 查看 Redis 数据
docker-compose exec redis redis-cli -a takeout123! KEYS *
```

### 6. 使用部署脚本（推荐）

```bash
# 查看帮助
./deploy.sh

# 完整部署
./deploy.sh deploy

# 启动服务
./deploy.sh start

# 停止服务
./deploy.sh stop

# 重启服务
./deploy.sh restart

# 查看状态
./deploy.sh status

# 查看日志
./deploy.sh logs
```

---

## 常见问题

### 1. Docker 服务无法启动

```bash
# 检查 Docker 状态
systemctl status docker

# 查看 Docker 日志
journalctl -u docker -n 50

# 重启 Docker
systemctl restart docker
```

### 2. 容器启动失败

```bash
# 查看容器日志
docker-compose logs takeout-app

# 查看容器详细信息
docker-compose ps -a

# 重新构建并启动
docker-compose up -d --build
```

### 3. MySQL 连接失败

```bash
# 检查 MySQL 容器状态
docker-compose ps mysql

# 查看 MySQL 日志
docker-compose logs mysql

# 测试 MySQL 连接
docker-compose exec mysql mysql -uroot -ptakeout123!
```

### 4. Redis 连接失败

```bash
# 检查 Redis 容器状态
docker-compose ps redis

# 查看 Redis 日志
docker-compose logs redis

# 测试 Redis 连接
docker-compose exec redis redis-cli -a takeout123! ping
```

### 5. 端口被占用

```bash
# 检查端口占用
netstat -tulpn | grep -E ':(80|443|3306|6379|9001)'

# 修改 docker-compose.yml 中的端口映射
# 例如将 80 改为 8080
# ports:
#   - "8080:80"
```

### 6. 应用无法访问

```bash
# 检查 Nginx 状态
docker-compose ps nginx

# 查看 Nginx 日志
docker-compose logs nginx

# 测试 Nginx 配置
docker-compose exec nginx nginx -t

# 检查应用服务
docker-compose logs takeout-app

# 测试应用服务是否正常
curl http://localhost:9001/doc.html
```

### 7. 数据库初始化问题

```bash
# 删除 MySQL 数据卷并重新初始化
docker-compose down
rm -rf mysql/data
docker-compose up -d

# 或者手动执行 SQL
docker-compose exec -T mysql mysql -uroot -ptakeout123! ruiji < SQL文件/ruiji.sql
```

### 8. 图片上传失败

```bash
# 检查目录权限
ls -la app/pic

# 修改权限
chmod 777 app/pic

# 查看应用配置
cat src/main/resources/application-prod.yml | grep fileLocaltion
```

---

## 数据备份与恢复

### 1. MySQL 数据备份

```bash
# 创建备份脚本
cat > backup_mysql.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/root/takeout-system/backup"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

docker-compose exec -T mysql mysqldump -uroot -ptakeout123! ruiji > $BACKUP_DIR/ruiji_$DATE.sql

# 保留最近 7 天的备份
find $BACKUP_DIR -name "ruiji_*.sql" -type f -mtime +7 -delete

echo "备份完成: ruiji_$DATE.sql"
EOF

chmod +x backup_mysql.sh

# 手动执行备份
./backup_mysql.sh

# 设置定时备份（每天凌晨 2 点）
crontab -e
# 添加以下内容：
0 2 * * * /root/takeout-system/backup_mysql.sh >> /root/takeout-system/backup/backup.log 2>&1
```

### 2. 数据恢复

```bash
# 恢复数据库
docker-compose exec -T mysql mysql -uroot -ptakeout123! ruiji < backup/ruiji_20240101_020000.sql
```

---

## 性能优化（可选）

### 1. JVM 参数优化

修改 `Dockerfile` 中的启动命令：

```dockerfile
ENTRYPOINT ["java", "-Xms512m", "-Xmx1024m", "-XX:MetaspaceSize=128m", "-XX:MaxMetaspaceSize=256m", "-jar", "app.jar", "--spring.profiles.active=prod"]
```

### 2. MySQL 配置优化

创建 `mysql/conf/my.cnf`：

```ini
[mysqld]
innodb_buffer_pool_size = 512M
innodb_log_file_size = 128M
max_connections = 200
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
```

### 3. Redis 配置优化

已在 `redis/conf/redis.conf` 中配置：
```
maxmemory 512mb
maxmemory-policy allkeys-lru
```

---

## 安全建议

### 1. 修改默认密码

修改 `docker-compose.yml` 中的密码：
- MySQL root 密码
- MySQL takeout 用户密码
- Redis 密码

同时修改 `application-prod.yml` 中的对应密码。

### 2. 限制端口暴露

不要直接暴露 MySQL 和 Redis 端口到公网，只在 Docker 内部网络访问。

### 3. 配置防火墙

```bash
# 安装 firewalld
yum install firewalld -y
systemctl start firewalld
systemctl enable firewalld

# 开放必要端口
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --reload
```

### 4. 定期更新镜像

```bash
# 拉取最新镜像
docker-compose pull

# 重新构建并启动
docker-compose up -d --build
```

---

## 总结

通过本指南，你应该能够成功在阿里云服务器上使用 Docker 部署瑞吉外卖系统。

如有问题，请查看：
1. 容器日志：`docker-compose logs`
2. 应用日志：`docker-compose logs takeout-app`
3. 常见问题章节

祝你学习愉快！
