#!/bin/bash
version="v1.0.0"

eb_install_path="/opt/eb-docker"
eb_main_path="/opt/eb-docker/main"

eb_latest_version="1.4.0-f36ec"
eb_main_package_name="easybot-linux-x64-$eb_latest_version.zip"
eb_install_url="https://files.inectar.cn/d/ftp/easybot/1.4.0-f36ec/linux-x64/easybot-linux-x64-$eb_latest_version.zip"

echo_cyan() {
  printf '\033[1;36m%b\033[0m\n' "$@"
}
echo_red() {
  printf '\033[1;31m%b\033[0m\n' "$@"
}
echo_green() {
  printf '\033[1;32m%b\033[0m\n' "$@"
}
echo_yellow() {
  printf '\033[1;33m%b\033[0m\n' "$@"
}

if [ "$EUID" -ne 0 ]; then
    echo_red "
✘ 权限不足，请使用 Root 用户执行该脚本
"
    exit 1
fi

if ! command -v curl &> /dev/null
then
    echo_red "
✘ curl 未安装，请先安装 curl 程序
"
    exit 1
fi

if ! command -v unzip &> /dev/null
then
    echo_red "
✘ unzip 未安装，请先安装 unzip 程序
"
    exit 1
fi

echo_cyan "
+---------------------------------------------------
 | EasyBot Docker 安装脚本（$verison）

 - 作者: Metcord
 - 特别鸣谢: MCSManager 安装脚本, @zkhssb, @zzh4141
+---------------------------------------------------
"


if [ ! -d "$eb_main_path" ]; then
    mkdir -p "$eb_main_path"
fi

curl -L -o "$eb_install_path/docker-compose.yml" "https://raw.githubusercontent.com/Dongyanmio/eb-docker-script/main/docker-compose.yml"
curl -L -o "$eb_install_path/Dockerfile" "https://raw.githubusercontent.com/Dongyanmio/eb-docker-script/main/Dockerfile"

Install_Docker() {
    echo_yellow "温馨提醒: 建议使用 清华源 安装 Docker CE，Docker Registry 建议使用 1Panel 镜像仓库"
    sleep 3
    bash <(curl -sSL https://linuxmirrors.cn/docker.sh)
}

Install_DOTNET_SDK_8() {
    docker pull mcr.microsoft.com/dotnet/sdk:8.0
}

Install_EBMain() {
    curl -L -o /tmp/eb-main.zip "$eb_install_url"
    unzip -qq -o /tmp/eb-main.zip -d "$eb_main_path"/
    chmod +x "$eb_main_path"/EasyBot
}

Install_Chrome() {
    chrome_install_url="https://easydl.bioc.fun/d/EasyBot/Liunxchrome/Chrome.zip"
    curl -L -o /tmp/eb-chrome.zip "$chrome_install_url"
    unzip -qq -o /tmp/eb-chrome.zip -d "$eb_main_path"/PuppeteerSharp/
}

if ! command -v docker &> /dev/null
then
    echo_yellow "未检测到 Docker 环境，开始自动安装 Docker"
    Install_Docker
    clear
else
    echo_green "检测到 Docker 已安装，自动跳过 Docker 安装步骤"
fi

# 询问用户端口并修改 docker-compose.yml
read -p "请输入 EasyBot 桥接端口（默认26990）: " eb_bridge_port
eb_bridge_port=${eb_bridge_port:-26990}
read -p "请输入 EasyBot WebUI 端口（默认5000）: " eb_webui_port
eb_webui_port=${eb_webui_port:-5000}

# 修改 docker-compose.yml 端口配置
sed -i "s|\"\${EB_BRIDGE_PORT:-26990}:26990\"|\"${eb_bridge_port}:26990\"|g" "$eb_install_path/docker-compose.yml"
sed -i "s|\"\${EB_WEBUI_PORT:-5000}:5000\"|\"${eb_webui_port}:5000\"|g" "$eb_install_path/docker-compose.yml"

read -p "是否需要安装 Chrome？(y/n, 默认n, 更新版本可直接跳过): " install_chrome
install_chrome=${install_chrome:-n}

echo_cyan "
准备工作就绪，开始安装 EasyBot 主程序"

Install_EBMain

echo_green "
 √ EasyBot 主程序安装完成
"

if [[ "$install_chrome" == "y" || "$install_chrome" == "Y" ]]; then
    echo_cyan "
正在安装 Chrome 程序及 ChromeHeadlessShell 插件"
    Install_Chrome
    echo_green "
 √ Chrome 程序及 ChromeHeadlessShell 插件安装完成
"
fi

echo_cyan "
正在启动 EasyBot Docker 容器..."
docker compose -f "$eb_install_path/docker-compose.yml" up -d
echo_green "
 √ EasyBot Docker 容器已启动
"