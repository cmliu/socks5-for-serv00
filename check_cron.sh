#!/bin/bash

echo "定义要添加的cron任务"
CRON_JOB="*/12 * * * * /home/$(whoami)/.npm-global/lib/node_modules/pm2/bin/pm2 resurrect >> /home/$(whoami)/pm2_resurrect.log 2>&1"
COMMAND_PATH="/home/$(whoami)/.npm-global/lib/node_modules/pm2/bin/pm2 resurrect"

echo "检查 crontab 是否已存在该任务"
(crontab -l | grep -F "$COMMAND_PATH") || (crontab -l; echo "$CRON_JOB") | crontab -