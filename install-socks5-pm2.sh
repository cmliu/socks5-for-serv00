#!/bin/bash

# 介绍信息
echo -e "\e[32m
  ____   ___   ____ _  ______ ____  
 / ___| / _ \ / ___| |/ / ___| ___|  
 \___ \| | | | |   | ' /\___ \___ \ 
  ___) | |_| | |___| . \ ___) |__) |           不要直连
 |____/ \___/ \____|_|\_\____/____/            没有售后   
 缝合怪：cmliu 原作者们：RealNeoMan、k0baya
\e[0m"

# 获取当前用户名
USER=$(whoami)
SOCKS5_DIR=/home/${USER,,}/socks5
SOCKS5_JS="$SOCKS5_DIR/socks5.js"
WORKDIR="/home/${USER,,}/.nezha-agent"

###################################################

socks5_config(){
# 提示用户输入socks5端口号
read -p "请输入socks5端口号: " SOCKS5_PORT

# 提示用户输入用户名和密码
read -p "请输入socks5用户名: " SOCKS5_USER

while true; do
  read -p "请输入socks5密码（不能包含@和:）：" SOCKS5_PASS
  echo
  if [[ "$SOCKS5_PASS" == *"@"* || "$SOCKS5_PASS" == *":"* ]]; then
    echo "密码中不能包含@和:符号，请重新输入。"
  else
    break
  fi
done

# 生成socks5.js文件
cat <<EOF > $SOCKS5_JS
'use strict';

const socks5 = require('node-socks5-server');

const users = {
  '$SOCKS5_USER': '$SOCKS5_PASS',
};

const userPassAuthFn = (user, password) => {
  if (users[user] === password) return true;
  return false;
};

const server = socks5.createServer({
  userPassAuthFn,
});
server.listen($SOCKS5_PORT);
EOF
}

install_socks5(){
  cd "$SOCKS5_DIR"

  # 检查node-socks5-server是否已安装
  if npm list node-socks5-server > /dev/null 2>&1; then
    echo "node-socks5-server已安装，跳过安装步骤。"
  else
    # 初始化npm项目
    echo "正在初始化npm项目..."
    npm init -y

    # 安装node-socks5-server
    echo "正在安装node-socks5-server，请稍候..."
    npm install node-socks5-server

    if [ $? -ne 0 ]; then
      echo "node-socks5-server安装失败，请检查网络连接或稍后再试。"
      exit 1
    fi
    echo "node-socks5-server安装成功。"
  fi

  # 检查socks5.js文件是否存在
  
  if [ -f "$SOCKS5_JS" ]; then
    read -p "当前目录下已经有socks5.js文件，是否要覆盖？(输入Y覆盖): " OVERWRITE_FILE
    OVERWRITE_FILE=${OVERWRITE_FILE^^} # 转换为大写
    if [ "$OVERWRITE_FILE" != "Y" ]; then
      echo "文件不覆盖。"
      #exit 1
    else
      echo "配置socks5.js文件"
      socks5_config
    fi
  else
    echo "配置socks5.js文件"
    socks5_config
  fi

  # 检查并删除已存在的同名pm2进程
  if pm2 list | grep -q socks_proxy; then
    pm2 stop socks_proxy
    pm2 delete socks_proxy
  fi

  # 启动socks5.js代理
  echo "正在启动socks5代理..."
  # pm2 start /home/$(whoami)/socks5/socks5.js --name socks_proxy
  pm2 start $SOCKS5_JS --name socks_proxy

  # 延迟检测以确保代理启动
  echo "等待代理启动..."
  sleep 5

  # 检查pm2中进程的运行状态
  PM2_STATUS=$(pm2 show socks_proxy | grep status | awk '{print $4}')
  if [ "$PM2_STATUS" == "online" ]; then
    echo "代理服务已启动。正在检查代理运行状态..."
    CURL_OUTPUT=$(curl -s ip.sb --socks5 $SOCKS5_USER:$SOCKS5_PASS@localhost:$SOCKS5_PORT)
    if [[ $CURL_OUTPUT =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "代理创建成功，返回的IP是: $CURL_OUTPUT"
      #echo "代理工作正常，脚本结束。"
    else
      echo "代理创建失败，请检查自己输入的内容。"
      pm2 stop socks_proxy
      pm2 delete socks_proxy
      exit 1
    fi
  else
    echo "代理服务启动失败，请检查配置。"
    exit 1
  fi
}

download_agent() {
    DOWNLOAD_LINK="https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_freebsd_amd64.zip"
    if ! wget -qO "$ZIP_FILE" "$DOWNLOAD_LINK"; then
        echo 'error: Download failed! Please check your network or try again.'
        return 1
    fi
    return 0
}

decompression() {
    unzip "$1" -d "$TMP_DIRECTORY"
    EXIT_CODE=$?
    if [ ${EXIT_CODE} -ne 0 ]; then
        rm -r "$TMP_DIRECTORY"
        echo "removed: $TMP_DIRECTORY"
        exit 1
    fi
}

install_agent() {
    install -m 755 ${TMP_DIRECTORY}/nezha-agent ${WORKDIR}/nezha-agent
}

generate_run_agent(){
    echo "关于接下来需要输入的三个变量，请注意："
    echo "Dashboard 站点地址可以写 IP 也可以写域名（域名不可套 CDN）;但是请不要加上 http:// 或者 https:// 等前缀，直接写 IP 或者域名即可；"
    echo "面板 RPC 端口为你的 Dashboard 安装时设置的用于 Agent 接入的 RPC 端口（默认 5555）；"
    echo "Agent 密钥需要先在管理面板上添加 Agent 获取。"
    printf "请输入 Dashboard 站点地址："
    read -r NZ_DASHBOARD_SERVER
    printf "请输入面板 RPC 端口："
    read -r NZ_DASHBOARD_PORT
    printf "请输入 Agent 密钥: "
    read -r NZ_DASHBOARD_PASSWORD
    printf "是否启用针对 gRPC 端口的 SSL/TLS加密 (--tls)，需要请按 [Y]，默认是不需要，不理解的用户可回车跳过: "
    read -r NZ_GRPC_PROXY
    echo "${NZ_GRPC_PROXY}" | grep -qiw 'Y' && ARGS='--tls'

    if [ -z "${NZ_DASHBOARD_SERVER}" ] || [ -z "${NZ_DASHBOARD_PASSWORD}" ]; then
        echo "error! 所有选项都不能为空"
        return 1
        rm -rf ${WORKDIR}
        exit
    fi

    cat > ${WORKDIR}/start.sh << EOF
#!/bin/bash
pgrep -f 'nezha-agent' | xargs -r kill
cd ${WORKDIR}
TMPDIR="${WORKDIR}" exec ${WORKDIR}/nezha-agent -s ${NZ_DASHBOARD_SERVER}:${NZ_DASHBOARD_PORT} -p ${NZ_DASHBOARD_PASSWORD} --report-delay 4 --disable-auto-update --disable-force-update ${ARGS} >/dev/null 2>&1
EOF
    chmod +x ${WORKDIR}/start.sh
}

run_agent(){
    nohup ${WORKDIR}/start.sh >/dev/null 2>&1 &
    printf "nezha-agent已经准备就绪，请按下回车键启动\n"
    read
    printf "正在启动nezha-agent，请耐心等待...\n"
    sleep 3
    if pgrep -f "nezha-agent -s" > /dev/null; then
        echo "nezha-agent 已启动！"
        echo "如果面板处未上线，请检查参数是否填写正确，并停止 agent 进程，删除已安装的 agent 后重新安装！"
        echo "停止 agent 进程的命令：pgrep -f 'nezha-agent' | xargs -r kill"
        echo "删除已安装的 agent 的命令：rm -rf ~/.nezha-agent"
        #echo
        #echo "如果你想使用 pm2 管理 agent 进程，请执行：pm2 start ~/.nezha-agent/start.sh --name nezha-agent"
        pm2 start /home/$(whoami)/.nezha-agent/start.sh --name nezha-agent
    else
        rm -rf "${WORKDIR}"
        echo "nezha-agent 启动失败，请检查参数填写是否正确，并重新安装！"
    fi
}

install_nezha_agent(){
  mkdir -p ${WORKDIR}
  cd ${WORKDIR}
  TMP_DIRECTORY="$(mktemp -d)"
  ZIP_FILE="${TMP_DIRECTORY}/nezha-agent_freebsd_amd64.zip"

  [ ! -e ${WORKDIR}/start.sh ] && generate_run_agent
  [ ! -e ${WORKDIR}/nezha-agent ] && download_agent \
  && decompression "${ZIP_FILE}" \
  && install_agent
  rm -rf "${TMP_DIRECTORY}"
  [ -e ${WORKDIR}/start.sh ] && run_agent
}

install_pm2(){
  echo "清理 npm 安装目录"
  rm -rf ~/.npm*
  
  echo "创建一个名为 .npm-global 的目录，用于存放全局安装的 npm 包。"
  mkdir -p ~/.npm-global 

  echo "设置 npm 的全局安装路径为 ~/.npm-global，这样全局安装的包会放在这个目录下。"
  npm config set prefix '~/.npm-global'

  echo "将 ~/.npm-global/bin 添加到系统的 PATH 环境变量中，这样可以在终端中直接运行全局安装的 npm 包命令。"
  echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.profile

  echo "重新加载 .profile 文件，使刚才添加的 PATH 环境变量立即生效。"
  source ~/.profile

  echo "全局安装 pm2，这是一个用于管理和监控 Node.js 应用的工具。"
  npm install -g pm2

  echo "再次重新加载 .profile 文件，确保所有的环境变量和路径配置都生效。"
  source ~/.profile
}

########################梦开始的地方###########################

# 检查pm2是否已安装并可用
if command -v pm2 > /dev/null 2>&1 && [[ $(which pm2) == "/home/${USER,,}/.npm-global/bin/pm2" ]]; then
  echo "pm2已安装且可用，跳过安装步骤。"
else
  # 安装pm2
  echo "正在安装pm2，请稍候..."
  #curl -s https://raw.githubusercontent.com/k0baya/alist_repl/main/serv00/install-pm2.sh | bash
  install_pm2
  if [ $? -ne 0 ]; then
    echo "pm2安装失败，请检查网络连接或稍后再试。"
    exit 1
  fi
  echo "pm2安装成功。按任意键断开后重新连接SSH后再运行此脚本。"
  read -n 1 -s -r -p ""  # 等待用户按任意键
    
  echo -e "\n断开SSH连接..."
  exit  # 断开SSH连接
  
  # 检查pm2路径
  if [[ $(which pm2) != "/home/${USER,,}/.npm-global/bin/pm2" ]]; then
    echo "pm2未正确配置。请断开并重新连接SSH后再运行此脚本。"
    exit 1
  fi
fi

read -p "是否安装socks5(Y/N): " socks5choice
socks5choice=${socks5choice^^} # 转换为大写
if [ "$socks5choice" == "Y" ]; then
  # 检查socks5目录是否存在
  
  if [ -d "$SOCKS5_DIR" ]; then
    read -p "目录$SOCKS5_DIR已经存在，是否继续安装？(Y/N): " CONTINUE_INSTALL
    CONTINUE_INSTALL=${CONTINUE_INSTALL^^} # 转换为大写
    if [ "$CONTINUE_INSTALL" != "Y" ]; then
      echo "安装已取消。"
      #exit 1
    else
      install_socks5
    fi
  else
    # 创建socks5目录
    echo "正在创建socks5目录..."
    mkdir -p "$SOCKS5_DIR"
    install_socks5
  fi
fi

read -p "是否安装nezha-agent(Y/N): " choice
choice=${choice^^} # 转换为大写
if [ "$choice" == "Y" ]; then
  echo "正在安装nezha-agent..."
  install_nezha_agent
else
  echo "不安装nezha-agent"
fi

read -p "是否保存当前pm2进程列表(Y/N)不理解的用户回车即可: " pm2save
pm2save=${pm2save^^} # 转换为大写
if [ "$pm2save" != "N" ]; then
  echo "保存当前pm2进程列表"
  pm2 save
  read -p "是否使用crontab守护pm2进程(Y/N)不理解的用户回车即可: " crontabpm2
  crontabpm2=${crontabpm2^^} # 转换为大写
  if [ "$crontabpm2" != "N" ]; then
    echo "添加crontab守护pm2进程"
    curl -s https://raw.githubusercontent.com/cmliu/socks5-for-serv00/main/check_cron.sh | bash
  fi
fi

pm2 list
echo "脚本执行完成。致谢：RealNeoMan、k0baya"
