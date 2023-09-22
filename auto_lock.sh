#!/bin/bash
################################################################ 
# Copyright 2023,
# All rights reserved.
# FileName:    auto_lock.sh
# time ：2023-09-20 01:02:51 PDT
# Updated ： 2023-09-22 00:05 PDT
# Description: 针对于MacBook 进行上下传任务时避免休眠和无人状态下自动锁屏
# Author:ROOT_Challenger
# https://twitter.com/ROOT_Challenger
# https://www.threads.net/@root_challenger
# https://www.tumblr.com/blog/rootchallenger
# https://mastodon.social/@Root_Challenger
# Revision: 2.0.0
###############################################################
#README
#在终端中赋予脚本执行权限：chmod +x auto_lock.sh
#使用 sudo 权限运行脚本：sudo ./auto_lock.sh
#需要依赖于iftop命令。MacOS需要额外安装。脚本未集成
#请在这里手动安装：
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# echo 'eval "$(/usr/local/bin/brew shellenv)"' >> /Users/你的用户名/.zprofile
# eval "$(/usr/local/bin/brew shellenv)"
# brew help
# brew update
# brew install iftop 
# 安装完毕后，需要找到你的网卡
# ifconfig -a 
# 一般是en0但是你需要查看一下 不对的话 你自己需要找到正确的
# 另外你的终端机需要macOS 辅助使用的权限
# 不然不能实现锁屏。
# 在此之前你可以先试一下 osascript -e 'tell application "System Events" to key code 12 using {control down, command down}'锁屏 
# 此脚本仅适用于macOS环境
#Change log 更新日志
#2023-09-22 00:05 PDT
#由于macOS执行需要管理员密码
#脚本命令多涉及到各种管理员操作所以进行重新调整
#定义密码输入变量，确保休眠停用和下载完毕后恢复休眠命令可以执行
#修复休眠不起作用的BUG
#新增了命令行显示速率
#将idle_check_process、network_check_process函数调用后台
#control+c终止脚本后自动退出所有后台脚本
#定义了IDLE_TIMEOUT、NETWORK_TIMEOUT变量以便于每个循环逐步调整 
#修复了其他问题

PASSWORD="YOURPASSWORD"

# 修改电源管理设置以阻止计算机进入休眠
echo $PASSWORD | sudo -S pmset -a sleep 0 disksleep 0
echo $PASSWORD | sudo -S pmset -a hibernatemode 0

cleanup() {
    echo "Exiting script..."
    echo $PASSWORD | sudo -S pmset -a sleep 1
    echo $PASSWORD | sudo -S pmset -a hibernatemode 3
    echo $PASSWORD | sudo -S pmset -a disksleep 1
    [ ! -z "$idle_pid" ] && echo $PASSWORD | sudo -S kill -9 $idle_pid
    [ ! -z "$network_pid" ] && echo $PASSWORD | sudo -S kill -9 $network_pid
}

trap cleanup EXIT


idle_check_process() {
    IDLE_TIMEOUT=30 #定义锁屏秒数

    while true; do
        idle_time=$(ioreg -c IOHIDSystem | sed -e '/HIDIdleTime/ !{ d' -e 't' -e '}' | awk -F = '{print $NF/1000000000 }' | cut -d '.' -f 1)
        if [ -n "$idle_time" ] && [ "$idle_time" -gt $IDLE_TIMEOUT ]; then
            echo "由于长时间无操作，正在锁定屏幕..."
            osascript -e 'tell application "System Events" to key code 12 using {control down, command down}'
        fi
        sleep 30
    done
}

、
parse_iftop_output() {
    local iftop_output="$1"
    local upload_rate=$(echo "$iftop_output" | awk '/Total send rate:/ {print $4}')
    local download_rate=$(echo "$iftop_output" | awk '/Total receive rate:/ {print $4}')
    echo "$upload_rate $download_rate"
}


network_check_process() {
    NETWORK_TIMEOUT=7200  #定义无网络活动时间
    LOW_UPLOAD_THRESHOLD=10 #定义上传速度kb
    LOW_DOWNLOAD_THRESHOLD=20 #定义下传速度kb
    no_network_counter=0

    while true; do
        IFTOP_OUTPUT=$(echo $PASSWORD | sudo -S iftop -i en0 -t -s 5 2>/dev/null)
        read upload_rate download_rate <<< $(parse_iftop_output "$IFTOP_OUTPUT")

        upload_value=$(echo "$upload_rate" | sed 's/[^0-9.]//g')
        download_value=$(echo "$download_rate" | sed 's/[^0-9.]//g')

        if [ -n "$upload_value" ] && [ -n "$download_value" ]; then
            echo "------------------------"
            echo "当前网络活动中:"
            echo "上传速率: $upload_rate"
            echo "下载速率: $download_rate"
            echo "------------------------"

            if [ $(echo "$download_value < $LOW_DOWNLOAD_THRESHOLD" | bc -l) -eq 1 ] && [ $(echo "$upload_value < $LOW_UPLOAD_THRESHOLD" | bc -l) -eq 1 ]; then
                ((no_network_counter++))
            else
                no_network_counter=0
            fi

            if [ "$no_network_counter" -gt $NETWORK_TIMEOUT ]; then
                echo "长时间无网络活动，准备使计算机进入休眠状态..."
                echo $PASSWORD | sudo -S pmset -a sleep 10 disksleep 10
                echo $PASSWORD | sudo -S pmset -a hibernatemode 3

                osascript -e 'tell app "System Events" to sleep'
            fi
        fi
        sleep 3
    done
}


idle_check_process & 
idle_pid=$!

network_check_process &
network_pid=$!

wait

