#!/bin/bash

# define function
function iterm2_Trigger {
    cat < EOF
1. profiles -> default -> Advanced -> Trigger
2. 添加两条 trigger
2.1
        Regular expression: rz waiting to receive.\*\*B0100
        Action: Run Silent Coprocess
        Parameters: /usr/local/bin/iterm2-send-zmodem.sh
        Instant: checked
2.2
        Regular expression: \*\*B00000000000000
        Action: Run Silent Coprocess
        Parameters: /usr/local/bin/iterm2-recv-zmodem.sh
        Instant: checked
EOF
}

# Main area
brew install lrzsz
git clone https://github.com/aikuyun/iterm2-zmodem.git
sudo cp iterm2-zmodem/*.sh /usr/local/bin
sudo chmod a+x /usr/local/bin/iterm2-*
echo
