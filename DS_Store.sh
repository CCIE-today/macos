#!/bin/zsh

function delete_ds {
    # 删除文件 2>/dev/null
    find / -name '*.DS_Store' -type f -delete 2>/dev/null
}
function disable_ds {
    # 禁止生成 2>/dev/null
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool TRUE
}

function enalbe_ds {
    # 恢复生成 2>/dev/null
    defaults delete com.apple.desktopservices DSDontWriteNetworkStores
}

# Main Area 2>/dev/null
delete_ds
disable_ds
echo
