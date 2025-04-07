unalias -a
os=$(uname)
user=$(whoami)

#===== ENV configs =====
dev_dir="$HOME/Public/dev"
dev_env_path=$HOME/Public/dev/env
dev_configs_path=$dev_dir/configs
dev_proj_path=$dev_dir/proj
alias dev="cd $dev_dir" proj="cd $dev_proj_path"

#---npm
alias npmlistg='sudo npm -g list --depth=0'
alias npmupg='sudo npm -g upgrade'

#---bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export BUN_STORE=$dev_env_path/bun/store
(mkdir -p $BUN_STORE &)
export BUN_REGISTRY=https://registry.npmjs.org

# bun completions
[ -s "~/.bun/_bun" ] && source "~/.bun/_bun"

#----golang
export GOPROXY=https://goproxy.cn
export GOPATH=$dev_env_path/go #default is ~/go
export PATH=$GOPATH/bin:$PATH
export GOROOT=$(go env GOROOT 2>/dev/null)
(mkdir -p $GOPATH &)
#go telemetry on

#---rust
export RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static
export RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup
export RUSTUP_HOME="$dev_env_path/rust/rustup"
export CARGO_HOME="$dev_env_path/rust/cargo"
export RUSTBINPATH="$CARGO_HOME/bin"
export CARGO_TARGET_DIR="$dev_env_path/rust/build"
alias rustup_dev_config='rustup install stable && rustup default stable && rustup component add rust-analyzer rust-src rustfmt clippy && rustup show'

#---python
alias python=python3 pip=pip3
alias pipmirrorchina='pip config set global.index-url https://mirrors.cloud.tencent.com/pypi/simple' # https://pypi.tuna.tsinghua.edu.cn/simple'
alias pipoutdated='pip list --outdated'
alias pipupgrade='pip install --upgrade $(pip list --outdate 2>/dev/null |sed -n "3,$ p"|cut -d " " -f 1)'
alias pip_install_from_list='pip3 install -r pip.list --no-index --find-links=.'
alias pydev='source ~/.virtualenvs/dev/bin/activate'
alias pyenv='activate_venv(){echo active $@ venv;source ~/.virtualenvs/$1/bin/activate};activate_venv'

#---conda
# if [ -r "/usr/local/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
#   . "/usr/local/Caskroom/miniconda/base/etc/profile.d/conda.sh"
# elif [ -r "/opt/miniconda/etc/profile.d/conda.sh" ]; then
#   source "/opt/miniconda/etc/profile.d/conda.sh"
# fi
# prevent auto active conda env, execute: conda config --set auto_activate_base false
alias condaclean='conda clean -ady'

#---jupyter lab
# show env: jupyter --path
# export JUPYTERLAB_DIR=$dev_dir/jupyter
# export JUPYTER_RUNTIME_DIR=$HOME/.local/share/jupyter/runtime #--runtime-dir
# export JUPYTER_DATA_DIR=$HOME/.local/share/jupyter            #--data-dir
# export JUPYTER_CONFIG_DIR=

#---flutter
# export FLUTTER_HOME=$dev_env_path/flutter
# export PATH=$FLUTTER_HOME/bin:$PATH
# export PUB_HOSTED_URL="https://pub.flutter-io.cn"
# export FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"

#---ansible
export ANSIBLE_CONFIG=$dev_configs_path/ansible/ansible.cfg

#---esp-idf
#if [[ -s /opt/esp-idf/export.sh ]]; then
#  source /opt/esp-idf/export.sh >/dev/null
#elif [[ -s $dev_env_path/esp-idf/export.sh ]]; then
#  source $dev_env_path/esp-idf/export.sh >/dev/null
#fi

#---specify $PATH
if [[ $os == Darwin ]]; then
  export PATH="/usr/local/sbin:/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
fi

#+++++ exit if not interactive shell +++++
[[ $- != *i* ]] && return

#+++++ Interactive shell +++++
#----- starship prompt -----
eval "$(starship init zsh)"
#all preset prompts: starship preset -l
#set preset prompt : starship preset <name> -o $HOME/.config/starship.toml

#===== welcom msg =====
echo -e "+++ $HOST : $(uname -rsm) +++\n\e[1;36m@$(date)\e[0m"

#--- IP info
if [[ $os == Linux && -n $(command -v ip) ]]; then #iproute
  local default_gw=$(ip r | grep default | head -n 1 | grep -Po "(?<=via ).+(?= dev)")
  ip -4 -br a | grep -vE "lo|169.254" | while read ip_info; do
    local interface=$(echo $ip_info | cut -d " " -f 1)
    local ip=$(echo $ip_info | grep -Eow "[0-9.]+/[0-9]{1,2}")
    [[ -z $ip ]] && continue
    local gw=$(ip r | grep $interface | head -n 1 | grep -Po "(?<=via ).+(?= dev)")
    [[ -z $gw ]] && gw="..."
    network_info="$interface: $gw  <--  $ip\n""$network_info"
  done
  echo -e "default gateway: \e[1;35m$default_gw\e[0m"
  echo -e "\e[31m$(echo "$network_info" | column -t)\e[0m"

elif [[ -n $(command -v ifconfig) ]]; then #net-tools (ifconfig)
  local innerips=$(ifconfig | grep inet | grep -vE "inet6|127.0.0.1" | grep -v 169.254 | cut -d " " -f 2)
  for innerip in ${innerips[@]}; do network_info="$network_info""$ip\n"; done
  for interface in $(ifconfig -lu); do
    [[ $interface == lo0 ]] && continue
    local network_info=$(ifconfig $interface | grep -w inet | awk -v interface=$interface '/inet6?/{print interface": "$2}')"\n$network_info"
  done
  local gateway=$(netstat -rn | grep "default" | awk '{print $2}' | head -n 1)
  echo -e "gateway:\e[3;35m" $(echo $gateway)"\e[0m\n\e[31m$(echo "$network_info" | sed -E -e "/^$/d" -e "s/\t/\s/g")\e[0m"
fi

#---fortune
if [[ -n $(command -v fortune) ]]; then
  if [[ $os == Darwin ]]; then
    fortune song100 tang300 2>/dev/null
  elif [[ $os == Linux ]]; then
    fortune chinese-hant song100-hant tang300-hant 2>/dev/null
  fi
fi

#---calendar
if [[ -n $(command -v ccal) ]]; then
  ccal -u
elif [[ -n $(command -v cal) ]]; then
  cal -m
fi

#===== welcome msg end =====

#===== post load scripts =====
test -e ~/.iterm2_shell_integration.zsh && source ~/.iterm2_shell_integration.zsh || true

test -r ~/.shell.env.postload.sh && source ~/.shell.env.postload.sh || true

#=====utility=====
#------ vim & neovim ------
#pacman -S vim-plugin --no-comfirm
alias vimplugup="[[ -f ~/.vim/autoload/plug.vim ]] && vim -c 'PlugUpgrade' -c 'PlugInstall' -c 'PlugUpdate' -c 'q' -c 'q'"
alias vimpluginstall="curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim && \rm -rfv ~/.vim/autoload/plugin.vim.old && vimplugup"

export EDITOR=vim
alias vi=vim

#neovim
alias nvimpluginstall='mkdir /tmp/nvim.bak && mv ~/.config/nvim ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim /mtp/nvim.bak/; git clone https://github.com/NvChad/starter ~/.config/nvim && nvim && \rm -rf ~/.config/nvim/.git'
if [[ -n $(command -v nvim) ]]; then
  export EDITOR=nvim
  alias vim=nvim
  alias vimdiff='exec nvim -d ' # "$@
  alias ex='exec nvim -e '      # "$@"s
  alias rview='exec nvim -RZ '  # "$@"
  alias rvim='exec nvim -Z '    # "$@"
  alias view='exec nvim -R '    # "$@"
  alias nvimupdate='nvim -c "MasonInstallAll" -c "normal U"'
fi

#----- package manager -----
if [[ $os == Darwin ]]; then
  function brew_taps() {
    brew tap beeftornado/rmtree
    brew tap buo/cask-upgrade
    brew tap homebrew/bundle
    brew tap homebrew/cask-fonts
  }

  export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
  export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
  export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
  export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"

  export HOMEBREW_NO_AUTO_UPDATE=true
  alias i="brew install"
  alias r="brew uninstall"
  alias s="brew search"
  alias pkg_query_update='brew outdated'
  alias pkgclean='brew cleanup'
  alias finderplugin='brew install qlcolorcode qlstephen qlmarkdown quicklook-json qlimagesize qlvideo webpquicklook' #suspicious-package suspicious-package quicklook-pat provisionql quicklookase

  alias up='brew cu -ay --no-brew-update ; brew update -v ; brew upgrade -g; zsh_plugins_upgrade' # mas upgrade # && brew doctor
elif [[ $(command -v pacman) ]]; then
  [[ $user != root ]] && alias pacman='sudo pacman'
  alias i="pacman -S"
  alias r="pacman -Rscn"
  alias qs="pacman -Qs"
  command -v yay &>/dev/null && alias s="yay --bottomup" || alias s="pacman -Ss"
  alias orphan='pacman -Rscn $(pacman -Qtdq)'
  alias pkgclean='orphan && paccache -rk 2 2>/dev/null'
  alias pkg_query_update='pacman -Sy && pacman -Qu'
  alias up='if command -v yay; then yay -Syu; else pacman -Syu; fi ; pkgclean ; zsh_plugins_upgrade'
  alias yay='yay --bottomup'
  #makepkg aur
  alias aurinfo='updpkgsums && makepkg --printsrcinfo > .SRCINFO ; git status && echo ----git add -u---'

elif [[ $(command -v apt) ]]; then
  [[ $user != root ]] && alias apt='sudo apt'
  function clean_oprhan_debs() {
    while true; do
      [[ -z $(deborphan) ]] && break
      apt purge $(deborphan)
    done
  }
  alias i="apt install"
  alias r="apt purge"
  alias s="apt search"
  alias qs="apt list -i "
  alias orphan='[[ -n $(command -v deborphan) ]] && clean_oprhan_debs || echo "deborphan not installed"'
  alias pkgclean='apt autoremove && apt autoclean && orphan'
  alias pkg_query_update='apt update && apt list --upgradable'
  alias up='apt update && apt dist-upgrade && zsh_plugins_upgrade'
fi

#---uncategorized commands
alias tmquickly='sudo sysctl debug.lowpri_throttle_enabled=0'
alias tmlistsnap='tmutil listlocalsnapshotdates'
alias tmlistbackups='tmutil listbackups'
alias tmrmsnap=' tmutil deletelocalsnapshots '
alias tmrmbackup='sudo tmutil delete '
alias temp='sudo powermetrics ... --samplers smc'
alias battery='ioreg -rn AppleSmartBattery |\grep -i capacity |grep -iE ".+=.+[0-9]+$"'
alias trim='sudo fstrim -v /home && sudo fstrim -v /'
alias logclean='sudo journalctl --vacuum-time=1weeks'

if [[ $user != root ]]; then
  alias systemctl='sudo systemctl'
  alias firewall-cmd='sudo firewall-cmd'
fi

function cleancache() {
  pkgclean
  id | grep -Ew "wheel|sudo|root" && echo "clean packages cache" && pkgclean
  echo "clean zsh rubbish files..."
  \ls -1 .zcompdump-* | while read line; do
    [[ -z $(echo $line | grep -E "$ZSH_VERSION") ]] && \rm -fv $line
  done
}

#---temporary locale
#localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
alias sc='export LANG=zh_CN.UTF-8 LC_CTYPE=zh_CN.UTF-8 LC_MESSAGES=zh_CN.UTF-8'
alias tc='export LANG=zh_TW.UTF-8 LC_CTYPE=zh_TW.UTF-8 LC_MESSAGES=zh_TW.UTF-8'
alias en='export LANG=en_US.UTF-8 LC_CTYPE=en_US.UTF-8 LC_MESSAGES=en_US.UTF-8'

#---file operations
alias scp='scp -r'
alias ls='ls --color -F'
alias ll='ls -lh'
alias la='ls -flh' #'ls -lah'
alias cp='cp -iv'
[[ -n $(command -v rsync) ]] && alias cp='echo "---cp is directed to an rsync command alias---" && rsync -av --progress --human-readable "$@"'
alias grep='grep --color'
alias tree='tree -C -L 1 --dirsfirst'
alias iconvgbk='iconv -f GBK -t UTF-8'                      #iconv -- file content encoding
alias convmvgbk='convmv -f GBK -t UTF-8 --notest --nosmart' #convmv -- filename encoding

#gio for trash
if [[ -n $(command -v gio) && -n $XDG_CURRENT_DESKTOP ]]; then
  alias trashclean='gio trash --empty'
  alias rm='echo "[tip] rm is an alias for [gio trash], it will move file to Trash" && gio trash '
  alias trash='gio trash '
  alias trashlist='echo "[tip] use gio trash --restore to restore a file" && echo "---~/.local/share/Trash---" && ls ~/.local/share/Trash/files'
  alias trashclean='rm -rf ~/.local/share/Trash/*'
fi

#tar + compress/uncompress
#eg tar -acvf xx.tar.zst xx ,compression type suffix is needed
alias tarc="tar --exclude='.DS_Store' -acvf " tarx='tar -xvf '

function dos2unix_all() {
  local dirpath=${1:-$(pwd)}
  dos2unix $dirpath/*
  \ls -1 | while read line; do
    [[ -d $dirpath/$line ]] && dos2unix_all $dirpath/$line
  done
}

#---.git nosync for icloud
function git_init_nosync_icloud() {
  git init . && mv .git .git.nosync && ln -s .git.nosync .git
  touch .gitignore
  grep ".git.nosync" .gitignore || echo ".git.nosync" >>.gitignore
  grep ".DS_Store" .gitignore || echo ".DS_Store" >>.gitignore
  ls -1a | grep .git
}

function nosync_git_icloud() {
  local dirpath=$1
  if [[ ! -d $dirpath ]]; then
    echo "dirpath $dirpath not exist or not a directory, usage: nosync_git <dirpath>"
    return 1
  fi
  find $dirpath -type d -name ".git" | while read sub_dirpath; do
    mv -v $sub_dirpath{,.nosync}
    ln -s ${sub_dirpath}.nosync $sub_dirpath
  done
  unset sub_dirpath
}

#---git alias
alias gm='git merge '
alias gf='git fetch'
alias gp='git push'
alias gc='git checkout'

#---network---
alias ipv6='curl -s 6.ipw.cn' ipv4='curl -s 4.ipw.cn'
alias ip_4_6_prefer='curl test.ipw.cn'
alias myip='curl cip.cc && echo && echo IPv6: $(ipv6 || echo noIPv6)' #ident.me v6.ident.me
alias myip_json='curl ipinfo.io'
alias ping='ping -c 4'

#---proxy
#alias shell_proxy='export ALL_PROXY="http://127.0.0.1:8010"'
alias shell_proxy='export ALL_PROXY="socks5h://127.0.0.1:1080"'
export NO_PROXY="localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
export PROXYCHAINS_SOCKS5="127.0.0.1:1080"
export PROXYCHAINS_SOCKS5_PORT="1080"

if [[ $os == Darwin ]]; then
  export PROXYCHAINS_CONF_FILE=/usr/local/etc/proxychains.conf
  alias px='proxychains4 -q'
  alias netinfo='/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I'
#  socat -T 600 TCP4-LISTEN:8080,fork TCP4:10.1.5.100:8080
elif [[ $os == Linux ]]; then
  export PROXYCHAINS_CONF_FILE=/etc/proxychains.conf
  alias px='proxychains -q'
  alias netinfo='nmcli con'
fi

#---tmux
#export TMUX_TMPDIR=/tmp #/tmp is default

#---find
alias f='find . -name '
alias rm_macos_ds_store='find . -name "*.DS_Store" -delete'

#---nmap
#scan alive hosts
alias 'nmap-ports'="sudo nmap -sS "
alias 'nmap-hosts'="nmap -sP --system-dns ${gateway%.*}.0/24"
alias 'nmap-os'="sudo nmap -O --system-dns ${gateway%.*}.0/24"

#qrcode -t utf8 -o - $(cat file.txt)
alias qrcode='qrencode -t ansiutf8 -o - ' #qrencode -t ansiutf8 -o - "http://www.bing.com"

#asciinema record terminal
alias rec='asciinema rec -i 5 terminal-`date +%Y%m%d-%H%M%S`' #record
alias play='asciinema play'                                   #play record file

alias starwar='telnet towel.blinkenlights.nl'

#---fzf
if [[ -r /usr/share/fzf/completion.zsh ]]; then
  source /usr/share/fzf/completion.zsh
  source /usr/share/fzf/key-bindings.zsh
elif [[ -r ~/.fzf.zsh ]]; then
  source ~/.fzf.zsh
fi
alias fzfv="fzf --preview 'cat {}'"

#---中文古诗词---
function fortune_gushici() {
  if [[ $(command -v brew) ]]; then
    command -v fortune || brew install fortune
    git clone https://github.com/ruanyf/fortunes.git /tmp/fortune
    \cp -av /tmp/fortune/data/{tang*,song*} /usr/local/Cellar/fortune/9708/share/games/fortunes
  elif [[ $(command -v pacman) ]]; then
    command -v fortune || pacman -S fortune-mod --noconfirm
    # sudo \cp -av /tmp/fortune/data/{tang*,song*} /usr/share/fortune/
    yes | yay -S fortune-mod-zh-hant
  fi
}

#===== functions for config files =====
function create_config_file_symbols() {
  comm_home_backup_dir=~/Documents/it/itnotes/linux/config-backup/userhome
  private_home_backup_dir=~/Documents/os-config/home.config

  confs_in_home_common=(.tmux.conf .condarc .zlogout .zshrc .gitignore_global .vimrc .makepkg.conf)
  confs_in_home_private=(.gitconfig .ssh/id_ed25519 .ssh/id_ed25519.pub .ssh/config)

  for conf in ${confs_in_home_common[*]}; do
    [[ -f $comm_home_backup_dir/$conf ]] && ln -sfv $comm_home_backup_dir/$conf ~/$conf
  done
  for conf in ${confs_in_home_private[*]}; do
    [[ -f $private_home_backup_dir/$conf ]] && ln -sfv $private_home_backup_dir/$conf ~/$conf
  done

  #for starship
  ln -sfv $comm_home_backup_dir/.config/starship.toml ~/.config/starship.toml
}

function backup_pkgs() {
  if [[ -n $(command -v brew) ]]; then
    brew bundle dump --describe --force --file=~/Documents/os-config/macos/brew-bundle-backup
    echo "[tip] reinstall macos apps from backupfile"
    echo -e "1. install brew and 'brew install mas' (optional) \n2. execute "brew bundle --file=$homebrew_backup_file" "
  fi
}

#++++++++++++++++++++++++++++++++++++
#====pkg update check
if [[ -f ~/.cache/pkg_last_update ]]; then
  pkg_last_update=$(cat ~/.cache/pkg_last_update)
  if [[ $(date +%s) -gt $((pkg_last_update + 30 * 24 * 3600)) ]]; then
    pkg_query_update &
    echo $(date +%s) >~/.cache/pkg_last_update
  fi
else
  mkdir ~/.cache
  echo $(date +%s) >~/.cache/pkg_last_update
fi

#only for auto login from bash to prevent load this file looply
alias bash='export onlybash=true;bash '
[[ -n $onlybash ]] && return

#===== ZSH configs =====
function install_z() {
  echo "install z to ~/config/z" && git clone --depth 1 https://github.com/rupa/z.git
  mkdir -p ~/.config/z && mv z/{z.1,z.sh} ~/.config/z/ && mv z /tmp/zsh-z-git && rm -rfv /tmp/zsh-z-git
}
function zsh_plugins_install() {
  if [[ -n $(command -v pacman) ]]; then
    pacman -S --noconfirm zsh starship zsh-autosuggestions zsh-completions zsh-lovers zsh-syntax-highlighting
    echo "!!! install z by aur: z-git" && s z-git
  elif [[ -n $(command -v apt) ]]; then
    apt install -y zsh zsh-autosuggestions zsh-syntax-highlighting
    sudo curl -sS https://starship.rs/install.sh | sh
    install_z
  elif [[ -n $(command -v brew) ]]; then
    brew install zsh starship zsh-autosuggestions zsh-syntax-highlighting
    install_z
  else
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_PLUGINS:-~/.zsh/plugins}/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_PLUGINS:-~/.zsh/plugins}/zsh-syntax-highlighting
    install_z
  fi
}

function zsh_plugins_upgrade() {
  local curdir=$PWD
  if [[ $ZSH == ~/.zsh ]]; then
    cd ~/.zsh/plugins/zsh-syntax-highlighting && git pull &
    cd ~/.zsh/plugins/zsh-autosuggestions && git pull &
  fi
  cd $curdir
}

#--- $ZSH plugins
plugins=(zsh-autosuggestions zsh-syntax-highlighting) #only for MacOS

if [[ $os == Darwin ]]; then
  plugin_parent_dir=/usr/local/share
  [[ $(uname -m) == arm64 ]] && plugin_parent_dir=/usr/local/share #for arm64 mac
  for plugin in ${plugins[*]}; do
    [[ -d $plugin_parent_dir/$plugin ]] && source $plugin_parent_dir/$plugin/$plugin.zsh
  done
  unset plugin_parent_dir
elif [[ -d /usr/share/zsh/plugins ]]; then
  ZSH_PLUGINS=/usr/share/zsh/plugins
elif [[ -d /usr/share/zsh ]]; then #for debian
  plugin_parent_dir=/usr/share
  for plugin in ${plugins[*]}; do
    [[ -d $plugin_parent_dir/$plugin ]] && source $plugin_parent_dir/$plugin/$plugin.zsh
  done
else
  ZSH_PLUGINS=~/.zsh && mkdir -p ~/.zsh
fi

# load plugins.They can be found in $ZSH_PLUGINS/*
if [[ -d $ZSH_PLUGINS ]]; then
  for plugin in ${plugins[*]}; do
    [[ -d $ZSH_PLUGINS/$plugin ]] && source $ZSH_PLUGINS/$plugin/$plugin.zsh
  done
fi

#plugins config
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=cyan,bg=bold,underline" #fg=#ff00ff,bg=cyan,bold,underline
ZSH_AUTOSUGGEST_STRATEGY=(history)                          #completion)

#z - jump
if [[ -r "/usr/share/z/z.sh" ]]; then
  source /usr/share/z/z.sh
elif [[ -r ~/.config/z/z.sh ]]; then
  source ~/.config/z/z.sh
fi

#---shell history
HISTFILE=~/.zsh_history HISTSIZE=2333 SAVEHIST=2333
alias history='history -i' history_all='history -i -$HISTSIZE' #history -15  #in bash: history 15

#=== Compatible with the operation habits of bash
#---shortcus
bindkey \^U backward-kill-line   #ctrl u (tip: ctrl k forwards-kill-line)
bindkey '^[OH' beginning-of-line #ctrl a
bindkey '^[OF' end-of-line       #ctrl e
bindkey '^[[3~' delete-char      #ctrl h

#---operation style compatibility
autoload -U +X bashcompinit && bashcompinit 2>/dev/null
autoload -Uz compinit && compinit 2>/dev/null
autoload -U select-word-style
select-word-style bash
setopt no_nomatch #no error when no match
zstyle ':completion:*:scp:*' tag-order '! users'

#---ssh-agent
# function check_ssh_agent() {
#   if [[ -z $(ps -eo pid,user,command | grep -w $USER | grep "ssh-agent" | grep -v grep) ]]; then
#     eval $(ssh-agent -s)
#     echo "export SSH_AGENT_PID=$SSH_AGENT_PID" >~/.ssh-agent.env
#     echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" >>~/.ssh-agent.env
#     [[ -f ~/.ssh/id_rsa ]] && ssh-add ~/.ssh/id_rsa
#   else
#     [[ -f ~/.ssh-agent.env ]] && source ~/.ssh-agent.env
#   fi
# }
# Added by Windsurf
export PATH="/Users/levin/.codeium/windsurf/bin:$PATH"
