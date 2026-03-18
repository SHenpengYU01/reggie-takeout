FROM adoptopenjdk/openjdk8:jre8u292-b10

# 维护者信息
LABEL maintainer="Claude <clause@example.com>"

# 设置时区
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo 'Asia/Shanghai' >/etc/timezone

# 创建工作目录
WORKDIR /app

# 复制jar包到容器
COPY target/takeOut-1.0-SNAPSHOT.jar app.jar

# 复制配置文件
COPY src/main/resources/application-prod.yml /app/application-prod.yml

# 创建日志和图片目录
RUN mkdir -p /app/logs /app/pic && \
    chmod -R 755 /app

# 暴露端口
EXPOSE 9001

# JVM参数配置
ENV JAVA_OPTS="-Xms512m -Xmx1024m -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=256m"

# 运行应用
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar --spring.profiles.active=prod"]
