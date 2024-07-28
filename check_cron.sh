#!/bin/bash

CRON_JOB="*/12 * * * * /home/$(whoami)/.npm-global/lib/node_modules/pm2/bin/pm2 resurrect >> /home/$(whoami)/pm2_resurrect.log 2>&1"
COMMAND_PATH="/home/$(whoami)/.npm-global/lib/node_modules/pm2/bin/pm2 resurrect"
REBOOT_COMMAND="@reboot pkill -kill -u $(whoami) && /home/$(whoami)/.npm-global/lib/node_modules/pm2/bin/pm2 resurrect >> /home/$(whoami)/pm2_resurrect.log 2>&1"

echo "检查并添加 crontab 重启任务"
(crontab -l | grep -F "$REBOOT_COMMAND") || (crontab -l; echo "$REBOOT_COMMAND") | crontab -

echo "检查并添加 crontab 保活任务"
(crontab -l | grep -F "$COMMAND_PATH") || (crontab -l; echo "$CRON_JOB") | crontab -
