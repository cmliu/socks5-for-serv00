#!/bin/bash

# 介绍信息
echo -e "\e[32m
  ____   ___   ____ _  ______ ____  
 / ___| / _ \ / ___| |/ / ___| ___|  
 \___ \| | | | |   | ' /\___ \___ \ 
  ___) | |_| | |___| . \ ___) |__) |           不要直连
 |____/ \___/ \____|_|\_\____/____/            没有售后   
 缝合怪：cmliu 原作者们：RealNeoMan、k0baya、eooce
\e[0m"

# 获取当前用户名
USER=$(whoami)
WORKDIR="/home/${USER}/.nezha-agent"
FILE_PATH="/home/${USER}/.s5"

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

# config.js文件
  cat > ${FILE_PATH}/config.json << EOF
{
  "log": {
    "access": "/dev/null",
    "error": "/dev/null",
    "loglevel": "none"
  },
  "inbounds": [
    {
      "port": "$SOCKS5_PORT",
      "protocol": "socks",
      "tag": "socks",
      "settings": {
        "auth": "password",
        "udp": false,
        "ip": "0.0.0.0",
        "userLevel": 0,
        "accounts": [
          {
            "user": "$SOCKS5_USER",
            "pass": "$SOCKS5_PASS"
          }
        ]
      }
    }
  ],
  "outbounds": [
    {
      "tag": "direct",
      "protocol": "freedom"
    }
  ]
}
EOF
}

install_socks5(){
  socks5_config
  if [ ! -e "${FILE_PATH}/s5" ]; then
    curl -L -sS -o "${FILE_PATH}/s5" "https://github.com/eooce/test/releases/download/freebsd/web"
  else
    read -p "socks5 程序已存在，是否重新下载覆盖？(Y/N 回车N)" downsocks5
    downsocks5=${downsocks5^^} # 转换为大写
    if [ "$downsocks5" == "Y" ]; then
      if pgrep s5 > /dev/null; then
        pkill s5
        echo "socks5 进程已被终止"
      fi
      curl -L -sS -o "${FILE_PATH}/s5" "https://github.com/eooce/test/releases/download/freebsd/web"
    else
      echo "使用已存在的 socks5 程序"
    fi
  fi

  if [ -e "${FILE_PATH}/s5" ]; then
    chmod 777 "${FILE_PATH}/s5"
    nohup ${FILE_PATH}/s5 -c ${FILE_PATH}/config.json >/dev/null 2>&1 &
	  sleep 2
    pgrep -x "s5" > /dev/null && echo -e "\e[1;32ms5 is running\e[0m" || { echo -e "\e[1;35ms5 is not running, restarting...\e[0m"; pkill -x "s5" && nohup "${FILE_PATH}/s5" -c ${FILE_PATH}/config.json >/dev/null 2>&1 & sleep 2; echo -e "\e[1;32ms5 restarted\e[0m"; }
    CURL_OUTPUT=$(curl -s 4.ipw.cn --socks5 $SOCKS5_USER:$SOCKS5_PASS@localhost:$SOCKS5_PORT)
    if [[ $CURL_OUTPUT =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "代理创建成功，返回的IP是: $CURL_OUTPUT"
      SERV_DOMAIN=$CURL_OUTPUT
      # 查找并列出包含用户名的文件夹
      found_folders=$(find "/home/${USER}/domains" -type d -name "*${USER,,}*")
      if [ -n "$found_folders" ]; then
          if echo "$found_folders" | grep -q "serv00.net"; then
              #echo "找到包含 'serv00.net' 的文件夹。"
              SERV_DOMAIN="${USER,,}.serv00.net"
          elif echo "$found_folders" | grep -q "ct8.pl"; then
              #echo "未找到包含 'ct8.pl' 的文件夹。"
              SERV_DOMAIN="${USER,,}.ct8.pl"
          fi
      fi

      echo "socks://${SOCKS5_USER}:${SOCKS5_PASS}@${SERV_DOMAIN}:${SOCKS5_PORT}"
    else
      echo "代理创建失败，请检查自己输入的内容。"
    fi
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

  # 如果 start.sh 文件不存在，则生成运行代理的脚本
  if [ ! -e "${WORKDIR}/start.sh" ]; then
    generate_run_agent
  else
    read -p "nezha-agent 配置信息已存在，是否重新配置？(Y/N 回车N)" nezhaagentyn
    nezhaagentyn=${nezhaagentyn^^} # 转换为大写
    if [ "$nezhaagentyn" == "Y" ]; then
      generate_run_agent
    fi
  fi

  # 如果 nezha-agent 文件不存在，则下载并解压代理文件，然后进行安装
  if [ ! -e "${WORKDIR}/nezha-agent" ]; then
    download_agent
    decompression "${ZIP_FILE}"
    install_agent
  else
    read -p "nezha-agent 文件已存在，是否重新下载最新版本？(Y/N 回车N)" nezhaagentd
    nezhaagentd=${nezhaagentd^^} # 转换为大写
    if [ "$nezhaagentd" == "Y" ]; then
      rm -rf "${ZIP_FILE}"
      if pgrep nezha-agent > /dev/null; then
        pkill nezha-agent
        echo "nezha-agent 进程已被终止"
      fi
      rm -rf "${WORKDIR}/nezha-agent"
      download_agent
      decompression "${ZIP_FILE}"
      install_agent
    fi
  fi

  # 删除临时目录
  rm -rf "${TMP_DIRECTORY}"

  # 如果 start.sh 文件存在，则运行代理
  if [ -e "${WORKDIR}/start.sh" ]; then
      run_agent
  fi

}

########################梦开始的地方###########################

read -p "是否安装 socks5 (Y/N 回车N): " socks5choice
socks5choice=${socks5choice^^} # 转换为大写
if [ "$socks5choice" == "Y" ]; then
  # 检查socks5目录是否存在
  if [ -d "$FILE_PATH" ]; then
    install_socks5
  else
    # 创建socks5目录
    echo "正在创建 socks5 目录..."
    mkdir -p "$FILE_PATH"
    install_socks5
  fi
else
  echo "不安装 socks5"
fi

read -p "是否安装 nezha-agent (Y/N 回车N): " choice
choice=${choice^^} # 转换为大写
if [ "$choice" == "Y" ]; then
  echo "正在安装 nezha-agent..."
  install_nezha_agent
else
  echo "不安装 nezha-agent"
fi

read -p "是否添加 crontab 守护进程的计划任务(Y/N 回车N): " crontabgogogo
crontabgogogo=${crontabgogogo^^} # 转换为大写
if [ "$crontabgogogo" == "Y" ]; then
  echo "添加 crontab 守护进程的计划任务"
  curl -s https://raw.githubusercontent.com/cmliu/socks5-for-serv00/main/check_cron.sh | bash
else
  echo "不添加 crontab 计划任务"
fi

echo "脚本执行完成。致谢：RealNeoMan、k0baya、eooce"
