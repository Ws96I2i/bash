#!/bin/bash
################################################################ 
# Copyright 2023,
# All rights reserved.
# FileName:    auto_lock.sh
# time ：2023-09-20 01:02:51 PDT
# Description: 针对于MacBook 进行上传任务时避免休眠和无人状态下自动锁屏
# Author:观察者
# https://twitter.com/ROOT_Challenger
# https://www.threads.net/@root_challenger
# https://www.tumblr.com/blog/rootchallenger
# https://mastodon.social/@Root_Challenger
# Revision: 1.0.0
#特别说明
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
# 在此之前你可以先试一下 osascript -e 'tell application "System Events" to keystroke "q" using {control down, command down}' 锁屏 
# 此脚本仅适用于macOS环境
###############################################################
sudo pmset -a sleep 0
sudo pmset -a hibernatemode 0
trap "sudo pmset -a sleep 1; sudo pmset -a hibernatemode 3" EXIT
IDLE_TIMEOUT=300 #可自行更改
NETWORK_TIMEOUT=3600 #可自行更改

lock_screen() {
    echo "由于长时间无操作，正在锁定屏幕..."
    osascript -e 'tell application "System Events" to keystroke "q" using {control down, command down}'
}

is_screen_locked() {
    pgrep -x "ScreenSaverEngine" > /dev/null
    return $?
}

check_network() {
    result=$(sudo iftop -i en0 -t -s 5 2>/dev/null)
    echo "$result" | grep -q "=>\|<="
    return $?
}

while true; do
    if ! is_screen_locked; then
        idle_time=$(ioreg -c IOHIDSystem | sed -e '/HIDIdleTime/ !{ d' -e 't' -e '}' | awk -F = '{print $NF/1000000000 }' | cut -d '.' -f 1)
        if [ "$idle_time" -gt $IDLE_TIMEOUT ]; then
            lock_screen
        fi
    fi

    if check_network; then
        no_network_counter=0
        echo "检测到网络活动..."
    else
        ((no_network_counter++))
        if [ "$no_network_counter" -gt $NETWORK_TIMEOUT ]; then
            echo "长时间无网络活动，准备使计算机进入休眠状态..."
            sudo pmset -a sleep 1
            sudo pmset -a hibernatemode 3
            osascript -e 'tell app "System Events" to sleep'
        fi
    fi

    sleep 60
done
