#!/bin/bash
################################################################ 
# Copyright 2023,
# All rights reserved.
# FileName:    kill_nsurlsessiond.sh
# Update time ：2023-09-20 01:02:51 PDT
# Description: 检测nsurlsessiond上传并杀掉
# Author:观察者
# https://twitter.com/ROOT_Challenger
# https://www.threads.net/@root_challenger
# https://www.tumblr.com/blog/rootchallenger
# https://mastodon.social/@Root_Challenger
# Revision: 1.0.0
#################################################################

while true; do
    PID=$(pgrep nsurlsessiond)

    if [ ! -z "$PID" ]; then
        echo "结束 nsurlsessiond 进程 PID $PID"
        kill -9 $PID
    else
        echo "nsurlsessiond 没有执行"
    fi

    sleep 1
done
