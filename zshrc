#!/bin/zsh

# define var
PATH=$PATH:/Volumes/DATA/OneDrive/EXrpm:/usr/local/Cellar/httrack/3.49.2_1/bin/httrack/usr/local/Cellar/sshpass/1.06/bin
PS1="%n@%{%F{magenta}%}%M %{%F{blue}%}%1~ %{%F{white}%}% %% "

# syntax-highlighting
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# zsh can use # for comment
setopt interactivecomments

# brew install zsh-completions 
autoload -U compinit
compinit
