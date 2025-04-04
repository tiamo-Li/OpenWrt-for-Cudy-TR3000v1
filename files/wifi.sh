#!/bin/sh

# OpenWrt多SSID专业配置脚本
# 检查参数
if [ $# -lt 1 ]; then
    echo "错误：必须指定一个大于0的整数作为参数" >&2
    echo "用法: $0 <SSID数量> [SSID前缀] [密码]" >&2
    exit 1
fi

SSID_COUNT=$1
SSID_PREFIX=${2:-"5G"}  # 默认前缀为"5G"
PASSWORD=${3:-"12345678"}  # 默认密码为"12345678"
BASE_IP=${4:-191}  # 默认IP后缀为191

# 常量定义
RADIO="radio1"
PHY="phy1"

# 检查环境
[ "$(id -u)" -ne 0 ] && {
    echo "错误：必须使用root权限运行" >&2
    exit 1
}

! uci -q get wireless.$RADIO >/dev/null && {
    echo "错误：无线设备$RADIO不存在" >&2
    exit 1
}

# 设置国家代码、删除默认wifi
uci set wireless.$RADIO.country='CN'
uci del wireless.default_radio0
uci del wireless.default_radio1

# 设置无线参数
uci set wireless.radio1.cell_density='2'
uci set wireless.radio1.channel='48'
uci set wireless.radio1.htmode='HE40'

# 防火墙配置
uci del firewall.cfg01e63d.syn_flood
uci set firewall.cfg01e63d.synflood_protect='1'
uci set firewall.cfg01e63d.input='ACCEPT'
uci set firewall.cfg01e63d.flow_offloading='1'
uci set firewall.cfg01e63d.flow_offloading_hw='1'
uci set firewall.cfg02dc81.forward='REJECT'

#关闭wan6、配置lan口
uci -q delete network.wan6
uci set network.lan.ipaddr='192.168.188.1'
uci del network.lan.ip6assign
uci del dhcp.lan.dhcpv6
uci del dhcp.lan.ra_flags
uci del dhcp.lan.ra_slaac
uci del dhcp.lan.ra


for i in $(seq 1 $SSID_COUNT); do
    # 格式化数字
    interface_num=$(printf "%03d" $i)
    ap_num=$((i-1))
    
    ###以下为WiFi配置###
    # 创建无线接口
    section="wifinet${i}"
    uci set wireless.$section=wifi-iface
    uci set wireless.$section.device="$RADIO"
    uci set wireless.$section.mode="ap"
    uci set wireless.$section.network="$interface_num"
    uci set wireless.$section.ssid="${SSID_PREFIX}_$interface_num"
    uci set wireless.$section.encryption="psk2"
    uci set wireless.$section.key="$PASSWORD"
    
    # 关键配置：客户端隔离和低ACK处理
    uci set wireless.$section.isolate='1'
    uci set wireless.$section.disassoc_low_ack='0'
    
    # 创建网络接口
    uci set network.$interface_num=interface
    uci set network.$interface_num.proto="static"
    uci set network.$interface_num.device="$PHY-ap$ap_num"
    uci set network.$interface_num.ipaddr="192.168.$BASE_IP.1"
    uci set network.$interface_num.netmask="255.255.255.0" 
    
    # 禁用IPv6
    for option in ip6assign ip6addr ip6gw; do
        uci -q delete network.$interface_num.$option
    done
    uci set network.$interface_num.dhcpv6="0"
    uci set network.$interface_num.ra="0"
    
    # DHCP配置
    uci set dhcp.$interface_num=dhcp
    uci set dhcp.$interface_num.interface="$interface_num"
    uci set dhcp.$interface_num.start="100"
    uci set dhcp.$interface_num.limit="150"
    uci set dhcp.$interface_num.leasetime="12h"
    uci set dhcp.$interface_num.dhcpv6="disabled"
    uci set dhcp.$interface_num.ra="disabled"
    
    # 防火墙配置
    uci add_list firewall.@zone[0].network="$interface_num"
done

# 提交所有变更
uci commit wireless
uci commit network
uci commit dhcp
uci commit firewall
wifi up $RADIO
