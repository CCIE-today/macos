#!/bin/bash

# 系度偏好设置 / 共享 / 屏幕共享

KPWD=P@33w0rd
KCMD=/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart


# 用于开启屏幕共享
sudo $KCMD -activate -configure -access -on -clientopts -setvnclegacy -vnclegacy yes -clientopts -setvncpw -vncpw $KPWD -restart -agent -privs -all
# 授权用于,设置为允许所有用户连接
sudo $KCMD -activate -configure -access -off -restart -agent -privs -all -allowAccessFor -allUsers

# 为了安全起见,用完后,建议关闭远程连接
sudo $KCMD -deactivate -configure -access -off