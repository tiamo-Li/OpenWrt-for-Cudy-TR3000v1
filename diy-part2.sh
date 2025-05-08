#!/bin/bash

# Modify default IP
sed -i 's/192.168.1.1/192.168.188.1/g' package/base-files/files/bin/config_generate

# Modify default theme
# sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname and time zones
sed -i 's/ImmortalWrt/KG101s/g' package/base-files/files/bin/config_generate
sed -i 's/UTC/Asia\/Shanghai/g' package/base-files/files/bin/config_generate

# add Argon theme
git clone https://github.com/jerrykuku/luci-theme-argon.git ./package/luci-theme-argon
git clone https://github.com/jerrykuku/luci-app-argon-config.git ./package/luci-app-argon-config
