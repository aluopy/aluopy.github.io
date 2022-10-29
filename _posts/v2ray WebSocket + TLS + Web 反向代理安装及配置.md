# v2ray WebSocket + TLS + Web 反向代理安装及配置

## 业务背景

随着项目出海，我们经常要访问外部资源，但是大部分情况下我们访问是非常缓慢的，为了提高工作效率的提升和数据安全性，我对公司整体的访问方案做了优化，在内网部署 openWRT 旁路网关（[ 企业 OpenWRT 软路由硬件旁路网关](https://cajvl75mma.feishu.cn/docs/doccnoOw4jnL42DHEjWu0X8g5dh)）让伙伴访问国内数据的时候使用默认出口，访问外部数据的时候通过我们的 V2ray 代理访问，从而实现资源的快速访问。

> 温馨提醒：
>
> 作为祖国公民与企业，请不要利用互联网做危害国家安全的事情！

## 业务原理

![](https://aluopy.github.io/assets/images/v2ray-01.png)

> B 的 dokodemo-door 改成 VMess，然后 C 需要安装 V2Ray 连接 B 的 VMess。最终的效果就是 C 通过 V2Ray 连接 B，B 反向代理给 A，就相当于 C 使用 V2Ray 通过 A 代理上网。

地址位置：

A：出口服务器 A --- 腾讯云香港

B：入口服务器 B --- 腾讯云广州

C：企业实际所在地

实际效果：

C 访问海外业务的实际出口是 A，全程数据加密。

## 系统初始化

本文以 腾讯云 CentOS 7.9 系统为例

### 服务器初始化

```bash
sudo -i
vi centos7-init.sh
```

初始化脚本文件 `centos7-init.sh`：

```bash
#!/bin/bash
#################################################
#  --Info
#      Panda Initialization CentOS 7.x script
#################################################
#   File: centos7-init.sh
#
#   Usage: sh centos7-init.sh
#
#   Auther: PandaMan ( i[at]davymai.com )
#
#   Link: https://cajvl75mma.feishu.cn/docs/doccn7SQI8269guTB7AO9yyXE4d
#
#   Version: 3.1
#
#   Update: 2022-04-03
#################################################
# set parameter
export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
clear

function INFO() {
    echo -e "\e[$1;49;1m $3 \033[39;49;0m"
    sleep "$2"
    echo ""
}
#安装目录
ENV_PATH="/usr/local"
#源码包存放目录
SOURCE_PATH="$(cd $(dirname -- $0); pwd)/install_tar"
#LNMP配置文件的目录
CONF_PATH="$(cd $(dirname -- $0); pwd)/conf"
#逻辑CPU个数
THREAD=$(grep 'processor' /proc/cpuinfo | sort -u | wc -l)
#IP地址
#ipadd=$(ifconfig eth0 | awk '/inet/ {print $2}' | cut -f2 -d ":" | awk 'NR==1 {print $1}')
ipadd=$(ifconfig eth0 | awk '{print $2}' | awk 'NR==2 {print $1}')
#网关地址
gateway=$(netstat -rn | awk '{print $2}' | awk 'NR==3 {print $1}')
#子网掩码
#netmask=$(ifconfig eth0 | awk '/inet/ {print $4}' | cut -f2 -d ":" | awk 'NR==1 {print $1}')
netmask=$(ifconfig eth0 | awk '{print $4}' | awk 'NR==2 {print $1}')
#DNS1
dns1=$(cat /etc/resolv.conf | awk '/nameserver/ {print $2}' | awk 'NR==1 {print $1}')
#DNS2
dns2=$(cat /etc/resolv.conf | awk '/nameserver/ {print $2}' | awk 'NR==2 {print $1}')
printf "
 +------------------------------------------------------------------------+
 |                      熊猫 CentOS 7.x 初始化脚本                        |
 |       To initialization the system for security and performance        |
 |                     初始化系统以提高安全性和性能                       |
 +------------------------------------------------------------------------+
                           version: 3.1
                      updated date: 2022-04-03

        Initialization begin after \e[31;1m5 \e[32;0mseconds, press Ctrl C to cancel.
                 初始化脚本 \e[31;1m5 \e[32;0m秒后开始, 按 ctrl C 取消。
"
echo ""

# Check if user is root
if [ $(id -u) != "0" ]; then
    INFO 31 1 "Error: You must be root to run this script, please use root to initialization OS.\n 错误: 您必须是 root 用户才能运行此脚本，请使用 root 用户身份来初始化操作系统。"
    exit 1
fi
sleep 5

# start Time
startTime=$(date +%s)

# 更新系统并安装软件包
system_update() {
    INFO 35 2 "*** Starting update system && install tools pakeage... ***\n        *** 正在启动更新系统 && 安装工具包... ***"
    curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
    yum -y upgrade
    command -v lsb_release > /dev/null 2>&1 || {
        [ -e "/etc/euleros-release" ] && yum -y install euleros-lsb || yum -y install redhat-lsb-core
    }
    command -v gcc > /dev/null 2>&1 || yum -y install gcc
    # install openssh-server openssh-clients
    yum -y install openssh-server openssh-clients
    # install vim authconfig libselinux-utils initscripts net-tools
    yum install -y vim authconfig libselinux-utils initscripts net-tools
    rm -rf /var/cache/yum/*
    [ $? -eq 0 ] && INFO 36 2 "System upgrade && install pakeages complete.\n 系统升级和程序安装完成。"
}

# 删除无用的用户和组
user_del() {
    INFO 35 2 "Delete useless user\n 删除无用的用户和组"
    userdel -r adm
    userdel -r lp
    userdel -r games
    userdel -r ftp
    groupdel adm
    groupdel lp
    groupdel games
    groupdel video
    groupdel ftp
    echo ""
    INFO 36 2 "Delete useless user is successful...\n 删除无用的用户完成。"
}

# 配置DNS服务器
config_nameserver() {
    nameserver=$(grep nameserver /etc/resolv.conf | wc -l)
    if [ $nameserver -ge 1 ]; then
        INFO 31 2 "nameserver is exist.\n DNS服务器已存在。"
    else
        INFO 32 2 "add nameserver in /etc/resolv.conf"
        echo "nameserver 223.5.5.5" >> /etc/resolv.conf
        INFO 36 2 "nameserver config complete.\n DNS服务器配置完成。"
    fi
}

# 设置时区同步
timezone_config() {
    INFO 35 2 "Setting timezone: Asia/Shanghai...\n 设置时区为: Asia/Shanghai"
    /usr/bin/timedatectl | grep "Asia/Shanghai"
    if [ $? -eq 0 ]; then
        INFO 33 1 "System timezone is Asia/Shanghai.\n 系统时区为Asia/Shanghai。"
    else
        timedatectl set-local-rtc 0 && timedatectl set-timezone Asia/Shanghai
    fi
    # config chrony
    #yum -y install chrony
    #sed -i '/server 3.centos.pool.ntp.org iburst/a\\server ntp1.aliyun.com iburst\nserver ntp2.aliyun.com iburst\nserver ntp3.aliyun.com iburst\nserver ntp4.aliyun.com iburst\nserver ntp5.aliyun.com iburst\nserver ntp6.aliyun.com iburst\nserver ntp7.aliyun.com iburst' /etc/chrony.conf
    #systemctl enable chronyd.service && systemctl start chronyd.service
    INFO 36 2 "Setting timezone & Sync network time complete.\n 设置时区和同步网络时间完成。"
}



# 禁用 selinux
selinux_config() {
    if [ -e "/etc/selinux/config" ]; then
        INFO 31 2 "selinux not installed.\n 未安装selinux。"
    else
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
        INFO 36 2 "Dsiable selinux complete.\n 禁用selinux完成。"
    fi
}

# 配置 ulimit
ulimit_config() {
    INFO 35 2 "Starting config ulimit...\n 开始配置ulimit..."
    if [ ! -z "$(grep ^ulimit /etc/rc.local)" -a "$(grep ^ulimit /etc/rc.local | awk '{print $3}' | head -1)" != '655360' ]; then
        sed -i 's@^ulimit.*@ulimit -SHn 655360@' /etc/rc.local
    else
        sed -i '$ a\ulimit -SHn 655360' /etc/rc.local
    fi
    cat > /etc/security/limits.conf << EOF
* soft nproc 102400
* hard nproc 102400
* soft nofile 102400
* hard nofile 102400
EOF
    ulimit -n 102400
    [ $? -eq 0 ] && INFO 36 2 "Ulimit config complete!\n Ulimit配置完成！"
}

# 配置 bashrc
bashrc_config() {
    INFO 35 2 "Starting bashrc config...\n 开始配置系统变量..."
    cp -f /etc/bashrc /etc/bashrc-bak
    echo "export PS1='\[\e[37;1m\][\[\e[35;49;1m\]\u\[\e[32;1m\]@\[\e[34;1m\]\h \[\e[37;1m\]➜ \[\e[31;1m\]\w \[\e[33;1m\]\t\[\e[37;1m\]]\[\e[32;1m\]$\[\e[m\] '" >> /etc/bashrc
    sed -i '$ a\set -o vi\nalias vi="vim"\nalias ll="ls -ahlF --color=auto --time-style=long-iso"\nalias ls="ls --color=auto --time-style=long-iso"\nalias grep="grep --color=auto"\nalias fgrep="fgrep --color=auto"\nalias egrep="egrep --color=auto"' /etc/bashrc
    INFO 36 2 "bashrc set OK!!\n 系统变量设在完成！！"
}

# 配置 sshd
sshd_config() {
    INFO 35 2 "Starting config sshd...\n 开始配置系统权限..."
    sed -i '/^#Port/s/#Port 22/Port '$sshp'/g' /etc/ssh/sshd_config
    sed -i '/^#UseDNS/s/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
    #禁用密码登陆
    sed -i '/^PasswordAuthentication yes/s/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
    sed -i '/^#PubkeyAuthentication/s/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
    sed -i "s/UsePAM.*/UsePAM yes/g" /etc/ssh/sshd_config
    sed -i '/^GSSAPIAuthentication/s/GSSAPIAuthentication yes/GSSAPIAuthentication no/g' /etc/ssh/sshd_config
    sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/g' /etc/ssh/sshd_config
    #if you do not want to allow root login,please open below
    sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
    systemctl restart sshd
    [ $? -eq 0 ] && INFO 36 2 "SSH port $sshp config complete.\n SSH 端口: $sshp 设置完毕。"
}

# 配置 firewalld
config_firewalld() {
    INFO 35 2 "Starting config firewalld...\n 开始配置firewallD防火墙..."
    rpm -qa | grep firewalld >> /dev/null
    if [ $? -eq 0 ]; then
        systemctl start firewalld && systemctl enable firewalld
        firewall-cmd --permanent --add-port=$sshp/tcp
        # 开启 NAT 转发 默认关闭
        firewall-cmd --permanent --add-masquerade
        firewall-cmd --rel
        firewall-cmd --list-all
        [ $? -eq 0 ] && INFO 36 2 "Config firewalld complete.\n 防火墙配置完成。"
    else
        INFO 35 2 "Firewalld not install.\n 没有安装FirewallD。"
    fi
}

# 配置vim
vim_config() {
    INFO 35 2 "Starting vim config...\n 开始配置vim..."
    /usr/bin/egrep pastetoggle /etc/vimrc >> /dev/null
    if [ $? -eq 0 ]; then
        INFO 35 2 "vim already config\n vim已经配置"
    else
        sed -i '$ a\set pastetoggle=<F9>\nsyntax on\nset nu!\nset tabstop=4\nset softtabstop=4\nset shiftwidth=4\nset expandtab\nset bg=dark\nset ruler\ncolorscheme ron' /etc/vimrc
        INFO 36 2 "vim configuration is successful...\n vim配置完成..."
    fi
}

# 配置sysctl
config_sysctl() {
    INFO 35 2 "Staring config sysctl...\n 开始配置sysctl..."
    cp -f /etc/sysctl.conf /etc/sysctl.conf.bak
    cat /dev/null > /etc/sysctl.conf
    cat > /etc/sysctl.conf << EOF
fs.file-max = 655350
vm.swappiness = 0
vm.dirty_ratio = 20
vm.dirty_background_ratio = 5
fs.suid_dumpable = 0
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 262144
# 开启SYN洪水攻击保护
net.ipv4.tcp_syncookies = 1
# 开启重用。允许将TIME-WAIT sockets 重新用于新的TCP 连接
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_fin_timeout = 30
# 当keepalive 起用的时候，TCP 发送keepalive 消息的频度。缺省是2 小时
net.ipv4.tcp_keepalive_time = 600
# timewait的数量，默认18000
net.ipv4.tcp_max_tw_buckets = 8000
# 开启反向路径过滤
net.ipv4.conf.all.rp_filter = 1
# IP 转发 默认关闭
net.ipv4.ip_forward=1
EOF
    INFO 36 2 "sysctl config complete.\n sysctl 配置完成。"
}

# 禁用IPv6
disable_ipv6() {
    INFO 35 2 "Starting disable IPv6...\n 开始禁用IPv6..."
    sed -i '$ a\net.ipv6.conf.all.disable_ipv6 = 1\nnet.ipv6.conf.default.disable_ipv6 = 1' /etc/sysctl.conf
    sed -i '$ a\AddressFamily inet' /etc/ssh/sshd_config
    systemctl restart sshd
    /usr/sbin/sysctl -p
    sleep 3
    INFO 36 2 "disable IPv6 complete.\n IPv6禁用完成。"
}

# 密码配置
password_config() {
    INFO 35 2 "Starting config password rule...\n 启动配置密码规则..."
    # /etc/login.defs  /etc/security/pwquality.conf
    sed -i '/PASS_MIN_LEN/s/5/8/g' /etc/login.defs
    #at least 8 character
    authconfig --passminlen=8 --update
    #at least 2 kinds of Character class
    authconfig --passminclass=2 --update
    #at least 1 Lowercase letter
    authconfig --enablereqlower --update
    #at least 1 Capital letter
    authconfig --enablerequpper --update
    INFO 36 2 "Config password rule complete(8 characters, must contain uppercase and lowercase letters).\n密码规则设置完成 (8个字符，必须包含大小写字母)。"
}

# 禁用不使用服务
disable_serivces() {
    INFO 35 2 "Disable postfix service.\n 禁用 postfix 服务。"
    systemctl stop postfix && systemctl disable postfix
    INFO 36 2 "Disable postfix service complete.\n 禁用postfix服务完成。"
}

# 创建新用户
user_create() {
    INFO 35 2 "Create User\n 创建新用户"
    sleep 1
    read -p "输入用户名: " name
    printf "输入密码: \n"
    read -s -r pass
    printf "再次确认密码: \n"
    read -s -r passwd
    if [ $pass != $passwd ]; then
        printf "两次密码输入有误, 请重新输入\n"
        user_create
    else
    printf "输入您的公钥(*重启后仅允许密钥登陆，禁止root用户登陆): \n"
    read rsa
    printf "输入ssh端口号: \n"
    read sshp
    useradd -G wheel $name && echo $Password | passwd --stdin $name &> /dev/null
    cd /home/$name && mkdir .ssh && chown $name:$name .ssh && chmod 700 .ssh && cd .ssh
    echo "$rsa" >> authorized_keys && chown $name:$name authorized_keys && chmod 600 authorized_keys
    echo "$name ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    history -cw
    sleep 3
    echo ""
    INFO 36 2 "User: \e[33;1m$name \e[36;1mcreate is successful...\n 用户: \e[33;1m$name \e[36;1m创建完成！"
    echo ""
fi
}

# 设置IP地址
config_ipaddr() {
    INFO 35 2 "Configure the IP address\n 配置 IP 地址"
    sleep 1
    read -p "输入IP地址 (默认地址: $ipadd): \n" IPADDR
    read -p "输入网关地址 (默认地址: $gateway): \n" GATEWAY
    read -p "输入子网掩码 (默认地址: $netmask): \n" NETMASK
    read -p "输入主要DNS服务器 (默认地址1: $dns1): \n" DNS1
    read -p "输入辅助DNS服务器 (默认地址2: $dns2): \n" DNS2
    sed -i 's/BOOTPROTO="dhcp"/BOOTPROTO="static"/g' /etc/sysconfig/network-scripts/ifcfg-eth0
    if [ $IPADDR == '' ]; then
        sed -i '$ a\IPADDR='$ipadd'' /etc/sysconfig/network-scripts/ifcfg-eth0
    else
        sed -i '$ a\IPADDR='$IPADDR'' /etc/sysconfig/network-scripts/ifcfg-eth0
    fi
    if [ $GATEWAY == '' ]; then
        sed -i '$ a\GATEWAY='$gateway'' /etc/sysconfig/network-scripts/ifcfg-eth0
    else
        sed -i '$ a\GATEWAY='$GATEWAY'' /etc/sysconfig/network-scripts/ifcfg-eth0
    fi
    if [ $NETMASK == '' ]; then
        sed -i '$ a\NETMASK='$netmask'' /etc/sysconfig/network-scripts/ifcfg-eth0
    else
        sed -i '$ a\NETMASK='$NETMASK'' /etc/sysconfig/network-scripts/ifcfg-eth0
    fi
    if [ $DNS1 == '' ]; then
        sed -i '$ a\DNS1='$dns1'' /etc/sysconfig/network-scripts/ifcfg-eth0
    else
        sed -i '$ a\DNS1='$DNS1'' /etc/sysconfig/network-scripts/ifcfg-eth0
    fi
    if [ $DNS2 == '' ]; then
        sed -i '$ a\DNS2='$dns2'' /etc/sysconfig/network-scripts/ifcfg-eth0
    else
        sed -i '$ a\DNS2='$DNS2'' /etc/sysconfig/network-scripts/ifcfg-eth0
    fi
    sleep 3
    echo ""
    INFO 36 2 "IP address configuration is successful...\n IP地址配置完成..."
}

other() {
    # Record command
    # lock user when enter wrong password root 10s others 180s
    sed -i '1aauth       required     pam_tally2.so deny=3 unlock_time=180 even_deny_root root_unlock_time=10' /etc/pam.d/sshd
    yum clean all
    sleep 3
}

#main function
main() {
    user_create
    user_del
    system_update
    config_nameserver
    timezone_config
    selinux_config
    ulimit_config
    sshd_config
    config_firewalld
    bashrc_config
    vim_config
    config_sysctl
    disable_ipv6
    password_config
    disable_serivces
    #config_ipaddr
    other
}
# execute main functions
main

endTime=$(date +%s)
((installTime = (endTime - startTime) / 60))
printf "
 Total initialization Install Time: \e[35;1m${installTime} \e[32;0mminutes
 +------------------------------------------------------------------------+
 |               To initialization system all completed !                 |
 |                        系统初始化全部完成 ！                           |
 +------------------------------------------------------------------------+
"
IPA=$(ifconfig eth0 | awk '{print $2}' | awk 'NR==2 {print $1}')
INFO 32 1 "Initialization is complete, please \e[31;1mreboot \e[32;1mthe system!!\n 系统初始化完成，请确认无误之后执行 \e[31;1mreboot \e[32;1m重启系统！\n================================\nssh端口号: \e[33;1m$sshp\n\e[32;1m服务器IP: \e[33;1m$IPA\n\e[32;1m用户名: \e[33;1m$name\n\e[32;1m密码: \e[33;1m$passwd\n\e[32;1m请牢记您的密码!!!\n================================\n远程访问: \e[33;1mssh -p $sshp -i ~/.ssh/私钥文件 $name@$IPA"
cat /dev/null > ~/.bash_history && history -c
```

本初始化文件禁用系统 root 用户及普通用户密码登录并启用密钥，密钥请自行创建。想使用密码登录的请自行参照注释内容修改，有任何问题也欢迎随时交流。

### 重启完成初始化

```bash
reboot
```

### 使用证书登录

```bash
ssh -p 初始化设置的端口号 -i ~/.ssh/私钥文件 用户名@ip
```

### 时间校准

对于 V2Ray，它的验证方式包含时间，就算是配置没有任何问题，如果时间不正确，也无法连接 V2Ray 服务器的，服务器会认为你这是不合法的请求。所以系统时间一定要正确，只要保证时间误差在**90 秒**之内就没问题。

对于 VPS(Linux) 可以执行命令 `date -R` 查看时间：

```bash
date -R
```

> 如果时间不准确，可以使用 `date --set` 修改时间。

### 使用 root 账户

为了方便后续脚本的执行安装，在此，我们切换成 root 账户。

执行命令：`sudo -i`  直接切换为 root 用户。

```bash
sudo -i
```

## 安装 v2ray 服务

### 下载脚本

下载主程序安装脚本：

```bash
curl -O https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh
```

### 执行安装

安装 v2ray 主程序：

```bash
bash install-release.sh
```

```
Downloading verification file for V2Ray archive: https://github.com/v2fly/v2ray-core/releases/download/v4.44.0/v2ray-linux-64.zip.dgst
info: Extract the V2Ray package to /tmp/tmp.k1v7oAXcNt and prepare it for installation.
info: Systemd service files have been installed successfully!
warning: The following are the actual parameters for the v2ray service startup.
warning: Please make sure the configuration file path is correctly set.
[Unit]
Description=V2Ray Service
Documentation=https://www.v2fly.org/
After=network.target nss-lookup.target

[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/v2ray -config /usr/local/etc/v2ray/config.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
# In case you have a good reason to do so, duplicate this file in the same directory and make your customizes there.
# Or all changes you made will be lost!  # Refer: https://www.freedesktop.org/software/systemd/man/systemd.unit.html
[Service]
ExecStart=
ExecStart=/usr/local/bin/v2ray -config /usr/local/etc/v2ray/config.json
warning: The systemd version on the current operating system is too low.
warning: Please consider to upgrade the systemd or the operating system.
installed: /usr/local/bin/v2ray
installed: /usr/local/bin/v2ctl
installed: /usr/local/share/v2ray/geoip.dat
installed: /usr/local/share/v2ray/geosite.dat
installed: /usr/local/etc/v2ray/config.json
installed: /var/log/v2ray/
installed: /var/log/v2ray/access.log
installed: /var/log/v2ray/error.log
installed: /etc/systemd/system/v2ray.service
installed: /etc/systemd/system/v2ray@.service
removed: /tmp/tmp.k1v7oAXcNt
info: V2Ray v4.44.0 is installed.
You may need to execute a command to remove dependent software: yum remove curl unzip
Please execute the command: systemctl enable v2ray; systemctl start v2ray
```

看到类似于这样的提示就算安装成功了。如果安装不成功脚本会有提示语句，这个时候你应当按照提示除错，除错后再重新执行一遍脚本安装 V2Ray。对于错误提示如果看不懂，使用翻译软件翻译一下就好。

### 错误处理

安装失败的话请修改一下服务器的 DNS 为 Google DNS：

```bash
vi /etc/resolv.conf
```

把文件内容修改成：

```bash
nameserver 8.8.4.4
```

重启网卡：

```bash
systemctl restart network
```

重新启动 V2ray 安装程序：

```bash
bash install-release.sh
```

## 运行 v2ray 服务

安装完之后，使用以下命令启动 V2Ray：

```bash
systemctl start v2ray
```

> 在首次安装完成之后，V2Ray 不会自动启动，需要手动运行上述启动命令。

设置开机自启动 V2Ray：

```bash
systemctl enable v2ray 
```

查看 v2ray 运行状态：

```bash
$ systemctl status v2ray
● v2ray.service - V2Ray Service
   Loaded: loaded (/etc/systemd/system/v2ray.service; enabled; vendor preset: disabled)
  Drop-In: /etc/systemd/system/v2ray.service.d
           └─10-donot_touch_single_conf.conf
   Active: active (running) since 日 2022-04-03 21:13:22 CST; 2s ago
     Docs: https://www.v2fly.org/
 Main PID: 10901 (v2ray)
   CGroup: /system.slice/v2ray.service
           └─10901 /usr/local/bin/v2ray -config /usr/local/etc/v2ray/config.json

4月 03 21:13:22 VM-0-13-centos systemd[1]: Started V2Ray Service.
4月 03 21:13:22 VM-0-13-centos v2ray[10901]: V2Ray 4.44.0 (V2Fly, a community-driven edition of V2Ray.) Custom (go1.17.3 linux/amd64)
4月 03 21:13:22 VM-0-13-centos v2ray[10901]: A unified platform for anti-censorship.
4月 03 21:13:22 VM-0-13-centos v2ray[10901]: 2022/04/03 21:13:22 [Info] main/jsonem: Reading config: /usr/local/etc/v2ray/config.json
```

> 看到类似于这样的提示就算启动成功了。

## 系统配置

### 出口服务器 A 配置

#### 防火墙配置

放通 UDP: 1024-65535 端口，放通 tcp: 18920 端口

```bash
firewall-cmd --permanent --add-port=1024-65535/udp
firewall-cmd --permanent --add-port=18920/tcp
firewall-cmd --rel
```

确认防火墙端口已正常打开

```bash
firewall-cmd --list-all
```

#### 编辑 V2ray 配置文件

```bash
vi /usr/local/etc/v2ray/config.json
```

配置文件

```json
{ //# 出口服务器 A Games HK 
  "reverse": { // 这是 A 的反向代理设置，必须有下面的 bridges 对象
    "bridges": [{
      "tag": "bridge", // 关于 A 的反向代理标签，在路由中会用到
      "domain": "any.private" // 一个域名，用于标识反向代理的流量，不必真实存在，但必须跟下面 B 中的 reverse 配置的域名一致
    }]
  },
  "outbounds": [{ //A 连接 B 的outbound
    "tag": "tunnel", // A 连接 B 的 outbound 的标签，在路由中会用到
    "protocol": "vmess",
    "settings": {
      "vnext": [{
        "address": "davymai.com", // B 地址，IP 或 实际的域名
        "port": 18920,
        "users": [{
          "id": "6aaa86e3-3539-416f-ba22-491ee5aa26f2",
          "alterId": 0
        }]
      }]
    }
  }, { // 另一个 outbound，最终连接私有网络
    "protocol": "freedom",
    "settings": {},
    "tag": "out"
  }],
  "routing": {
    "rules": [{ // 配置 A 主动连接 B 的路由规则
      "type": "field",
      "inboundTag": [
        "bridge"
      ],
      "domain": [ // 将指定域名的请求发给 A，如果希望将全部流量发给 A，这里可以不设置域名规则。
        "full:any.private"
      ],
      "outboundTag": "tunnel"
    }, { // 反向连接访问私有网络的规则
      "type": "field",
      "inboundTag": [
        "bridge"
      ],
      "outboundTag": "out"
    }]
  }
}
```

检查配置文件是否有错：

```shell
$ v2ray -test -config /usr/local/etc/v2ray/config.json
V2Ray 4.44.0 (V2Fly, a community-driven edition of V2Ray.) Custom (go1.17.3 linux/amd64)
A unified platform for anti-censorship.
2022/04/03 20:48:25 [Info] main/jsonem: Reading config: /usr/local/etc/v2ray/config.json
Configuration OK.
```

看到以上内容说明配置文件正确无误。

> 提示：`-bash: v2ray: 未找到命令：`
>
> ```bash
> ln -s /usr/local/bin/v2ray /usr/bin/v2ray
> ```

#### 重启 v2ray 服务

```bash
systemctl restart v2ray
```

### 入口服务器 B 配置

> v2ray 安装过程与上方「安装 v2ray 服务」内容一致。

#### 防火墙设置

入口服务器比出口服务器多增加 80 和 443 端口

```bash
firewall-cmd --permanent --add-port=1024-65535/udp
firewall-cmd --permanent --add-port=18920/tcp
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --rel
```

确认防火墙端口已正常打开

```bash
firewall-cmd --list-all
```

#### 编辑 V2ray 配置文件

```bash
vi /usr/local/etc/v2ray/config.json
```

配置文件

```json
{ //# B 服务器 Games GZ 入口服务器
  "log": {
    "loglevel": "warning",
    "access": "/var/log/v2ray/access.log", // 日志路径
    "error": "/var/log/v2ray/error.log"
  },
  "routing": {
    "rules": [{ //路由规则，接收 C 的请求后发给 A
      "type": "field",
      "inboundTag": [
        "interconn"
      ],
      "outboundTag": "portal"
    }, { //路由规则，让 B 能够识别这是 A 主动发起的反向代理连接
      "type": "field",
      "inboundTag": [
        "tunnel"
      ],
      "domain": [ // 将指定域名的请求发给 A，如果希望将全部流量发给 A，这里可以不设置域名规则。
        "full:any.private"
      ],
      "outboundTag": "portal"
    }]
  },
  "policy": {
    "levels": {
      "0": {
        "handshake": 4,
        "connIdle": 300,
        "uplinkOnly": 2,
        "downlinkOnly": 5,
        "statsUserUplink": false,
        "statsUserDownlink": false,
        "bufferSize": 4096
      }
    }
  },
  "inbounds": [{ // 接受 C 的inbound
    "tag": "tunnel",
    "port": 10246, // 服务器监听端口
    "listen": "127.0.0.1", //只监听 127.0.0.1，避免除本机外的机器探测到开放了 18915 端口
    "protocol": "vmess", // 主传入协议
    "settings": {
      "clients": [{
        "id": "782a2380-ac0d-427d-a217-fe9a77e94ccc", // 用户 ID，客户端与服务器必须相同
        "alterId": 0,
        "security": "auto"
      }]
    },
    "streamSettings": {
      "network": "ws",
      "wsSettings": {
        "path": "/alone" //与 nginx 的 location 保持一致
      }
    }
  }, { // 另一个 inbound，接受 A 主动发起的请求
    "tag": "interconn", // 标签，路由中用到
    "port": 18920,
    "protocol": "vmess",
    "settings": {
      "clients": [{
        "id": "6aaa86e3-3539-416f-ba22-491ee5aa26f2",
        "alterId": 0,
        "security": "auto"
      }]
    }
  }],
  "reverse": { //这是 B 的反向代理设置，必须有下面的 portals 对象
    "portals": [{
      "tag": "portal",
      "domain": "any.private" // 必须和上面 A 设定的域名一样
    }]
  }
}
```

检查配置文件是否有错：

```bash
$ v2ray -test -config /usr/local/etc/v2ray/config.json
V2Ray 4.44.0 (V2Fly, a community-driven edition of V2Ray.) Custom (go1.17.3 linux/amd64)
A unified platform for anti-censorship.
2022/04/03 20:48:25 [Info] main/jsonem: Reading config: /usr/local/etc/v2ray/config.json
Configuration OK.
```

看到以上内容说明配置文件正确无误。

#### 重启 v2ray 服务

```bash
systemctl restart v2ray
```

## 安装 Web 代理服务器

Web 代理服务器只需要在入口服务器 B 安装即可！

### 安装

```bash
yum -y install nginx socat
```

### 配置

下载 Nginx 配置文件

```bash
cd /etc/nginx && mv nginx.conf nginx.conf.bak
wget https://raw.githubusercontent.com/mack-a/v2ray-agent/master/config/nginx.conf
```

修改 Nginx 配置文件

```bash
vi /etc/nginx/nginx.conf
```

文件行注释部分，请根据实际情况修改自己的

```nginx
# For more information on configuration, see:
#   * Official English Documentation: http://nginx.org/en/docs/
#   * Official Russian Documentation: http://nginx.org/ru/docs/

user root;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

# Load dynamic modules. See /usr/share/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    # include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/nginx/conf.d/*.conf;

   server {
        listen       80;
        listen       [::]:80;
        # server_name 这里需要修改为你的
        server_name  davymai.com;
        root         /usr/share/nginx/html;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        # HTTP 访问 301 重定向为 HTTPS
        #return      301 https://$server_name$request_uri;
        location / {
        }
            location ~ /.well-known {
                allow all;
        }
        error_page 404 /404.html;
            location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
   }
    server {
        # 开放 443 端口监听
        #listen 443 ssl http2;
        # 域名证书及密钥位置
        #ssl_certificate /etc/v2ray/v2ray.crt;
        #ssl_certificate_key /etc/v2ray/v2ray.key;

        ssl_protocols SSLv2 SSLv3 TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
        ssl_prefer_server_ciphers on;

        # server_name 这里需要修改为你的
        server_name davymai.com; 
        location / {
        }

        # 请确保 location 目录与 V2Ray 配置中的 path 保持一致
        location /alone {
        
            if ($http_upgrade != "websocket") { # WebSocket协商失败时返回404
                return 404;
            }
            proxy_redirect off;

            # 端口号需要与 服务器 B 的 v2ray 配置文件的监听端口号保持一直
            proxy_pass http://127.0.0.1:31299;

            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}
```

### 启动并设置开机启动

```bash
systemctl enable nginx --now
```

### Web 证书配置

#### 安装 acme.sh 服务

```bash
curl https://get.acme.sh | sh
```

> 使用 acme.sh 命令需要重启终端

#### 注册 acme.sh

```bash
acme.sh --register-account -m 你的邮箱@qq.com
```

#### 证书生成

> 注意: 如果你有的 VPS 上有架设网页，请使用 webroot 模式生成证书而不是 TLS 小节中提到的 standalone 模式。以下仅就两种模式的些微不同举例，相同部分参照 TLS 小节。本例中使用的是 ECC 证书，若要生成 RSA 证书，删去 `--keylength ec-256` 或 `--ecc` 参数即可。详细请参考 [acmesh-official/acme.sh](https://github.com/acmesh-official/acme.sh/wiki)

这里直接用安装 Nginx 生成的页面进行域名验证

```bash
acme.sh --issue -d davymai.com --webroot /usr/share/nginx/html --standalone --keylength ec-256 --force
```

#### 创建证书文件夹

```bash
mkdir -p /etc/v2ray
```

#### 安装证书和密钥

```bash
acme.sh --installcert -d davymai.com --ecc --fullchain-file /etc/v2ray/v2ray.crt --key-file /etc/v2ray/v2ray.key
```

证书和密钥安装完毕后，重启 Nginx 之前请务必把「**Nginx 配置文件**」注释的位置修改好！

#### 重启 Nginx

修改完毕后重启 Nginx 启用 https 代理

```bash
systemctl restart nginx
```

## 进阶设置

![](https://aluopy.github.io/assets/images/v2ray-02.png)

```
地址位置：
A：北美
B：香港
C：境内
D：机构
实际效果：
D 访问海外业务的实际出口是 A，全程数据加密。
```

入口服务器 C 配置：

```json
{ // C 服务器 广州
  "log": {
    "loglevel": "warning",
    "access": "/var/log/v2ray/access.log", // 日志路径
    "error": "/var/log/v2ray/error.log"
  },
  "inbounds": [
    {
      "port": 443,
      "protocol": "vmess",
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      },
      "settings": {
        "clients": [{
        "id": "782a2380-ac0d-427d-a217-fe9a77e94ccc", // 用户 ID，客户端与服务器必须相同
        "alterId": 0,
        "security": "auto"
      }]，
        "auth": "noauth",
        "udp": false
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "davymai.com",
            "port": 443,
            "users": [
              {
                "id": "0464bcd8-7e63-4638-a4bd-a0fe89495ddf",
                "alterId": 0,
                "security": "chacha20-poly1305"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "serverName": "davymai.com"
        },
        "wsSettings": {
          "headers": {
            "Host": "davymai.com"
          },
          "path": "/alone"
        }
      }
    }
  ]
}
```

## 注意事项

- V2Ray 自 4.18.1 后支持 TLS1.3，如果开启并强制 TLS1.3 请注意 v2ray 客户端版本.

- 较低版本的 nginx 的 location 需要写为 /alone/ 才能正常工作

- 如果在设置完成之后不能成功使用，可能是由于 SElinux 机制（如果你是 CentOS 7 的用户请特别留意 SElinux 这一机制）阻止了 Nginx 转发向内网的数据。如果是这样的话，在 V2Ray 的日志里不会有访问信息，在 Nginx 的日志里会出现大量的 "Permission Denied" 字段，要解决这一问题需要在终端下键入以下命令：

  ```
  setsebool -P httpd_can_network_connect 1
  ```

- 请保持服务器和客户端的 wsSettings 严格一致，对于 V2Ray，`/alone` 和 `/alone/` 是不一样的

- 较低版本的系统/浏览器可能无法完成握手. 如 Chrome 49/XP SP3, Safari 8/iOS 8.4, Safari 8/OS X 10.10 及更低的版本. 如果你的设备比较旧, 则可以通过在配置中添加较旧的 TLS 协议以完成握手。

## 其他的话

1. 开启了 TLS 之后 path 参数是被加密的，GFW 看不到；
2. 主动探测一个 path 产生 Bad request 不能证明是 V2Ray；
3. 不安全的因素在于人，自己的问题就不要甩锅，哪怕我把示例中的 path 改成一个 UUID；
4. 使用 Header 分流并不比 path 安全， 不要迷信。

## 关于作者

[Blog (feishu.cn)](https://cajvl75mma.feishu.cn/wiki/wikcnqHZbWXVp9syNGbC8O5kNud)