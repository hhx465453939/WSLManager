#1.windows部分子系统管理
#开启子系统
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart 
#开启虚拟机平台
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
##无法安装ubuntu的话管理员打开powershell：其实是必要步骤
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux

#这里去windows商店下载ubuntu，去开始菜单打开后自动安装，并配置用户名
#Ubuntu 24.04.1 LTS

#安装好以后powershell管理员权限下更改默认为wsl 1模式
##这时可选项，注意WSL1无法使用 systemd，但是win 10 + WSL2的ssh服务配置老是出错比较麻烦，因为WSL多出来了一个独立的虚拟机ip，没有特殊原因的话这里默认先用WSL1玩
###此外win10即使设置为wsl --set-default-version 2也不影响wsl --list --verbose得到version1的结果，因为wsl --list --verbose得到的是wsl.exe的配置，而wsl --set-default-version 2是更改wsl.exe的默认启动版本
wsl --set-default-version 1
wsl --list --verbose
#在 /etc/wsl.conf（文件不存在则创建）添加如下内容,打开 WSL 1 的systemd功能：
sudo nano /etc/wsl.conf
[boot]
systemd=true
#重启WSL
#powershell 
wsl --shutdown
wsl
#用snap测试一下
snap version

###如果要设置WSL2，则
wsl --set-default-version 2
wsl --list --verbose
#直接设定特定版本ubuntu WSL2，以Ubuntu-24.04为例
wsl --set-version Ubuntu-24.04 2
#--------------------------------------------------------
sudo apt update
sudo apt install software-properties-common
sudo apt update

#2.安装ssh服务
sudo apt purge openssh-server
sudo apt install openssh-server

sudo service ssh stop
sudo service ssh start
sudo service ssh restart
#配置文档
sudo nano /etc/ssh/sshd_config
Port 22
ListenAddress 0.0.0.0
ListenAddress ::
PermitRootLogin no
PasswordAuthentication yes
Subsystem sftp internal-sftp

#重启服务
sudo service ssh start
##开机启动ssh
sudo systemctl enable ssh

#--------------------------------------------------------
#3.修改用户名并添加到root
sudo adduser damncheater
sudo passwd damncheater
#如果有旧用户名可以这样操作
sudo cp -r /home/old_username /home/damncheater
sudo deluser old_username
#添加最高权限到新用户名
sudo chown -R damncheater:damncheater /home/damncheater
#编辑配置文件
sudo nano /etc/sudoers
#增加配置, 在打开的配置文件中，找到root ALL=(ALL) ALL, 在下面添加一行
#其中xxx是你要加入的用户名称
damncheater ALL=(ALL) ALL
#保存退出，重启服务
sudo service ssh restart
#--------------------------------------------------------
#3.1这里开始就可以使用finalshell之类的进行连接了
ip a
#选一个以太网或者无线ip到转发端口上，cmd管理员命令
netsh interface portproxy add v4tov4 listenport=2222 connectaddress=169.254.10.67 connectport=22
#--------------------------------------------------------
#4.配置肉鸡WSL的开机自启
#这一步在肉鸡wsl界面用root权限完成
cd /etc
sudo chmod 777 init.wsl
sudo nano /etc/init.wsl

#! /bin/sh
#填写任意服务，rstudio-server之类的也可以
service ssh restart
#service rstudio-server start
#service redis-server start
#service mysql start
#service nginx start
#保存退出

#powershell命令，这个ubuntu版本看自己的实际版本号填写
wsl -d Ubuntu-24.04 -u root /etc/init.wsl start

#还没完，这里再进windows写一个自启脚本
##win+r: shell:startup 进入开机自启文件夹
###新建文件wsl2run_Ubuntu_redis.vbs（文件名自命名，扩展名是vbs就行）
####填写注意ubuntu版本号别输错了，自己从store下载的版本是多少记住，或者开始菜单输入ubuntu就可以查到安装的版本
rem Msgbox "Win10开机自动启动wsl2的Ubuntu，并由其启动redis"
Set ws = CreateObject("Wscript.Shell")
ws.run "wsl -d Ubuntu-24.04 -u root /etc/init.wsl start", vbhide
#保存好以后重启一下电脑就好，后面应该可以直接从finalshell开机直连
