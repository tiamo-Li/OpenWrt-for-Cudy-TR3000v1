#!/bin/sh

# OpenWrt多SSID专业配置脚本
# 检查参数
if [ $# -lt 1 ]; then
    echo "错误：必须指定一个大于0的整数作为参数" >&2
    exit 1
fi

SSID_COUNT=$1
BASE_IP=190
APPNAME="passwall2"

# 检查环境
[ "$(id -u)" -ne 0 ] && {
    echo "错误：必须使用root权限运行" >&2
    exit 1
}

# 启用passwall访问控制
uci set "$APPNAME.@global[0].acl_enable=1"

for i in $(seq 1 $SSID_COUNT); do
    # 格式化数字
    interface_num=$(printf "%03d" $i)
    ip_last=$((BASE_IP + i))

    # passwall常量
    rule_id="acl_rule_$interface_num"
    remark="$interface_num"
    source="192.168.${ip_last}.0/24"
    
    # 创建ACL规则段落
    uci add passwall2 acl_rule
    uci set passwall2.@acl_rule[-1].enabled='1'
    uci set passwall2.@acl_rule[-1].remarks=$remark
    uci set passwall2.@acl_rule[-1].interface=$remark
    uci set passwall2.@acl_rule[-1].sources=$source
    uci set passwall2.@acl_rule[-1].remote_dns='8.8.8.8'

    uci commit "$APPNAME"
done
