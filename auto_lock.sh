#!/bin/bash
################################################################ 
# Copyright 2023,
# All rights reserved.
# FileName:    auto_lock.sh
# Update time ：2023-09-20 01:02:51 PDT
# Description: 针对于MacBook 进行上传任务时避免休眠和无人状态下自动锁屏
# Author:观察者
# https://twitter.com/ROOT_Challenger
# https://www.threads.net/@root_challenger
# https://www.tumblr.com/blog/rootchallenger
# https://mastodon.social/@Root_Challenger
# Revision: 1.0.0
###############################################################
sudo pmset -a sleep 0
sudo pmset -a hibernatemode 0
trap "sudo pmset -a sleep 1; sudo pmset -a hibernatemode 3" EXIT
IDLE_TIMEOUT=300
NETWORK_TIMEOUT=3600

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
