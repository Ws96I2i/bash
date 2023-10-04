#!/bin/zsh
################################################################ 
# Copyright 2023,
# All rights reserved.
# FileName:    dns_test.zsh
# Time ：2023-10-03 21:40 PDT
# Updated ： 2023-10-03 21:40 PDT
# Description: 针对于MacBook DNS批量测试，不适用Windows
# Author:ROOT_Challenger
# https://twitter.com/ROOT_Challenger
# https://www.threads.net/@root_challenger
# https://www.tumblr.com/blog/rootchallenger
# https://mastodon.social/@Root_Challenger
# Revision: 1.0.1
###############################################################
#README
#本来是写bash的，后来改成zsh，因为Mac自带的bash版本太老了,这样对于移植到其他的Mac不利,所以走zsh.减少出错几率
#Change log
#删除了无效的DNS服务

if [[ $EUID -ne 0 ]]; then
   echo "请使用sudo权限运行此脚本." 
   exit 1
fi

test_dns() {
    local server=$1
    local result=$(dig @$server example.com | grep "Query time:" | awk '{print $4}')
    [ -z "$result" ] && echo 999999 || echo $result
}

typeset -A dns_groups
dns_groups=(
    "Google Public DNS" "8.8.8.8 8.8.4.4"      # Google 提供的公共DNS
    "Cloudflare" "1.1.1.1 1.0.0.1"              # 用于加速和保护网站的DNS
    "OpenDNS" "208.67.222.222 208.67.220.220"  # 由Cisco提供的DNS服务
    "Quad9" "9.9.9.9 149.112.112.112"          # 集成了安全功能的DNS
    "Verisign" "64.6.64.6 64.6.65.6"            # 提供DDoS保护和速度加速的DNS
    "Comodo Secure DNS" "8.26.56.26 8.20.247.20" # 安全的DNS服务
    "UncensoredDNS" "91.239.100.100 89.233.43.71" # 不审查的DNS
    "Freenom World" "80.80.80.80 80.80.81.81"     # 公共DNS
    "SafeDNS" "195.46.39.39 195.46.39.40"         # 提供网络安全功能的DNS
    "Neustar" "156.154.70.1 156.154.71.1"         # 提供DDoS保护和速度加速
    "AdGuard DNS" "94.140.14.14 94.140.15.15"     # 广告拦截功能
    "AdGuard 广告和成人内容过滤" "94.140.14.15 94.140.15.16" # 广告拦截、成人内容过滤
    "CleanBrowsing" "185.228.168.168 185.228.169.168"#阻止訪問所有成人、色情和露骨網站。它還會阻止用於繞過過濾器的代理程式和 VPN 網域。混合內容網站（如 Reddit）也被封鎖。Google、Bing 和 Youtube 設定為安全模式。惡意和網路釣魚域被封鎖。
    "Alternate DNS" "76.76.19.19 76.223.122.150"  # 广告拦截和恶意软件保护功能的DNS
)

echo "\n测试中，请稍候...\n"
results=()
dns_test_results=()
for provider in "${(@k)dns_groups}"; do
    for ip in ${(s: :)dns_groups[$provider]}; do
        query_time=$(test_dns "$ip")
        results+=("$query_time|$ip")
        dns_test_results+=("$query_time ms - $provider ($ip)")
    done
done

echo "\n测试结果 (按查询时间排序)："
printf "%s\n" "${dns_test_results[@]}" | sort -n
echo "\n"
