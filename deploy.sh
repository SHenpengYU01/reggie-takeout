#!/bin/bash

# 瑞吉外卖系统部署脚本
# 适用于阿里云服务器 Docker 部署

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 脚本帮助信息
usage() {
    echo -e "${BLUE}瑞吉外卖系统部署脚本${NC}"
    echo -e "用法: $0 {build|deploy|start|stop|restart|status|logs}"
    echo -e ""
    echo -e "选项:"
    echo -e "  build    编译并构建项目"
    echo -e "  deploy   完整部署流程(编译+构建+启动)"
    echo -e "  start    启动所有服务"
    echo -e "  stop     停止所有服务"
    echo -e "  restart  重启所有服务"
    echo -e "  status   查看服务状态"
    echo -e "  logs     查看应用日志"
    echo -e ""
}

# 检查 Docker 和 Docker Compose
check_requirements() {
    echo -e "${BLUE}检查 Docker 和 Docker Compose...${NC}"

    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker 未安装，请先安装 Docker${NC}"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}Docker Compose 未安装，请先安装 Docker Compose${NC}"
        exit 1
    fi

    echo -e "${GREEN}Docker 版本: $(docker --version)${NC}"
    echo -e "${GREEN}Docker Compose 版本: $(docker-compose --version)${NC}"
}

# 编译项目
build_project() {
    echo -e "${BLUE}编译项目...${NC}"

    if [ ! -f "pom.xml" ]; then
        echo -e "${RED}pom.xml 文件未找到，请在项目根目录执行此脚本${NC}"
        exit 1
    fi

    # 编译项目
    mvn clean package -DskipTests

    if [ $? -ne 0 ]; then
        echo -e "${RED}项目编译失败${NC}"
        exit 1
    fi

    echo -e "${GREEN}项目编译成功！${NC}"
}

# 启动服务
start_services() {
    echo -e "${BLUE}启动服务...${NC}"

    # 启动所有服务
    docker-compose up -d

    if [ $? -ne 0 ]; then
        echo -e "${RED}服务启动失败${NC}"
        exit 1
    fi

    echo -e "${GREEN}服务启动成功！${NC}"
    echo -e ""

    # 等待服务启动
    echo -e "${BLUE}等待服务初始化...${NC}"
    sleep 30

    # 检查服务状态
    show_status
}

# 停止服务
stop_services() {
    echo -e "${BLUE}停止服务...${NC}"

    docker-compose down

    if [ $? -ne 0 ]; then
        echo -e "${RED}服务停止失败${NC}"
        exit 1
    fi

    echo -e "${GREEN}服务停止成功！${NC}"
}

# 重启服务
restart_services() {
    echo -e "${BLUE}重启服务...${NC}"

    docker-compose restart

    if [ $? -ne 0 ]; then
        echo -e "${RED}服务重启失败${NC}"
        exit 1
    fi

    echo -e "${GREEN}服务重启成功！${NC}"
    echo -e ""

    # 检查服务状态
    show_status
}

# 查看服务状态
show_status() {
    echo -e "${BLUE}服务状态:${NC}"

    docker-compose ps

    echo -e ""
    echo -e "${BLUE}容器日志(前20行):${NC}"
    echo -e "-------------------"
    docker-compose logs --tail 20
}

# 查看应用日志
show_logs() {
    echo -e "${BLUE}查看应用日志...${NC}"

    docker-compose logs takeout-app -f
}

# 完整部署流程
deploy_full() {
    echo -e "${BLUE}开始完整部署流程...${NC}"

    check_requirements
    build_project
    start_services
}

# 主函数
main() {
    if [ $# -eq 0 ]; then
        usage
        exit 1
    fi

    case "$1" in
        build)
            check_requirements
            build_project
            ;;
        deploy)
            deploy_full
            ;;
        start)
            check_requirements
            start_services
            ;;
        stop)
            check_requirements
            stop_services
            ;;
        restart)
            check_requirements
            restart_services
            ;;
        status)
            check_requirements
            show_status
            ;;
        logs)
            check_requirements
            show_logs
            ;;
        *)
            echo -e "${RED}无效选项: $1${NC}"
            usage
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
