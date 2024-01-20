unalias -a

os=$(uname)
user=$(whoami)

# Path to your oh-my-zsh installation.
if [[ -n $ZSH ]]; then
  echo "ZSH is already set to $ZSH"
elif [[ -d ~/.oh-my-zsh ]]; then
  export ZSH=~/.oh-my-zsh
  chown -R $USER:$GID $ZSH
elif [[ -d /usr/share/oh-my-zsh ]]; then
  export ZSH=/usr/share/oh-my-zsh
  ZSH_DISABLE_COMPFIX=true
  DISABLE_AUTO_UPDATE="true" # disable bi-weekly auto-update checks.
  [[ -d /usr/share/zsh/plugins ]] && export ZSH_CUSTOM=/usr/share/zsh
fi

ZSH_CACHE_DIR=~/.oh-my-zsh-cache
mkdir -p $ZSH_CACHE_DIR

# theme
ZSH_THEME="ys" #"fino-time" #"random"
#ZSH_THEME_RANDOM_CANDIDATES=(frisk ys re5et tjkirch linuxonly bureau candy fino-time strug steeef dstufft rkj-repos peepcode)

# CASE_SENSITIVE="true"

# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=33

# if pasting URLs and other text is messed up.
DISABLE_MAGIC_FUNCTIONS=true

# disable colors in ls.
# DISABLE_LS_COLORS="true"

# disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"

# enable command auto-correction.
# ENABLE_CORRECTION="true"

# display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# disable marking untracked files under VCS as dirty, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd", see 'man strftime' for details.
HIST_STAMPS="yyyy-mm-dd"

# load plugins.They can be found in $ZSH/plugins/*
plugins=(z zsh-interactive-cd zsh-syntax-highlighting zsh-autosuggestions colored-man-pages)

source $ZSH/oh-my-zsh.sh

#---pre-load env file
[[ -r ~/.shell.env.preload ]] && source ~/.shell.env.preload

###++++shell basic settings++
HISTSIZE=2333
SAVEHIST=2333
alias history='history -i'
alias history_all='history -i -$HISTSIZE' #history -15  #in bash: history 15

#++++like bash style++++
#---shortcus
bindkey \^U backward-kill-line   #ctrl u (tip: ctrl k forwards-kill-line)
bindkey '^[OH' beginning-of-line #ctrl a
bindkey '^[OF' end-of-line       #ctrl e
bindkey '^[[3~' delete-char      #ctrl h

#auto complete git
autoload -U +X bashcompinit && bashcompinit 2>/dev/null
autoload -Uz compinit && compinit 2>/dev/null
autoload -U select-word-style
select-word-style bash
setopt no_nomatch #no error when no match
zstyle ':completion:*:scp:*' tag-order '! users'

#+++++welcom msg
echo -e "+++ $HOST : $(uname -rsm) +++\n\e[1;36m@$(date)\e[0m"

if [[ -n $(command -v ip) ]]; then #iproute
  default_gw=$(ip r | grep default | head -n 1 | grep -Po "(?<=via ).+(?= dev)")

  ip -4 -br a | grep -v lo | grep -v 169.254 | while read ip_info; do
    interface=$(echo $ip_info | cut -d " " -f 1)
    ip=$(echo $ip_info | grep -Eow "[0-9.]+/[0-9]{1,2}")
    [[ -z $ip ]] && continue
    gw=$(ip r | grep $interface | head -n 1 | grep -Po "(?<=via ).+(?= dev)")
    [[ -z $gw ]] && gw="NONE"
    network_info="$interface: $gw  <--  $ip\n""$network_info"
  done
  echo -e "default gateway: \e[1;35m$default_gw\e[0m"
  echo -e "\e[31m$(echo "$network_info" | column -t)\e[0m"

elif [[ -n $(command -v ifconfig) ]]; then #net-tools (ifconfig)
  innerips=$(ifconfig | grep inet | grep -vE "inet6|127.0.0.1" | grep -v 169.254 | cut -d " " -f 2)
  for innerip in ${innerips[@]}; do
    network_info="$network_info""$ip\n"
  done
  for interface in $(ifconfig -lu); do
    [[ $interface == lo0 ]] && continue
    network_info=$(ifconfig $interface | grep -w inet | awk -v interface=$interface '/inet6?/{print interface": "$2}')"\n$network_info"
  done
  gateway=$(netstat -rn | grep "default" | awk '{print $2}' | head -n 1)
  echo -e "gateway:\e[3;35m"  $(echo $gateway)"\e[0m\n\e[31m$(echo "$network_info" | sed -E -e "/^$/d" -e "s/\t/\s/g")\e[0m"
fi

#fortune
if [[ -n $(command -v fortune) ]]; then
  if [[ $os == Darwin ]]; then
    fortune song100 tang300 2>/dev/null
  else
    fortune chinese tang300 song100 2>/dev/null
  fi
fi

echo

if [[ -n $(command -v ccal) ]]; then
  ccal -u
elif [[ -n $(command -v cal) ]]; then
  cal -m
fi
#++++ ohmyzsh++++
function ohmyzsh_install() {
  if [[ -n $(command -v pacman) ]]; then
    pacman -S --noconfirm oh-my-zsh-git zsh zsh-autosuggestions zsh-completions zsh-lovers zsh-syntax-highlighting
  else
    [[ -f ~/.zshrc ]] && cat ~/.zshrc >/tmp/zshrc
    git clone https://mirrors.tuna.tsinghua.edu.cn/git/ohmyzsh.git
    cd ohmyzsh/tools
    REMOTE=https://mirrors.tuna.tsinghua.edu.cn/git/ohmyzsh.git
    sh install.sh
    git -C $ZSH remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/ohmyzsh.git
    git -C $ZSH pull
    \rm -rf ohmyzsh
    #custom plugins
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    cat /tmp/zshrc >~/.zshrc
    cd -
  fi
}

function ohmyzsh_upgrade() {
  local curdir=$PWD
  if [[ $ZSH == ~/.oh-my-zsh ]]; then
    cd $ZSH_CUSTOM/plugins/zsh-syntax-highlighting && git pull &
    cd $ZSH_CUSTOM/plugins/zsh-autosuggestions && git pull &
    omz update &
  fi
  cd $curdir
}

#+++++files backup and restore
#files in ~/
confs_in_home_common=(.tmux.conf .condarc .zlogout .zshrc .gitignore_global .vimrc)
confs_in_home_private=(.gitconfig .ssh/id_rsa* .ssh/config)
home_config_dirs=(.nvim) #~/config

comm_home_backup_dir=~/Documents/it/itnotes/linux/config-backup/userhome
private_home_backup_dir=~/Documents/os-config/home.config

homebrew_backup_file=~/Documents/os-config/macos/brew-bundle-backup

function backupconfigs() {
  echo "+++++ Backup configs +++++"
  mkdir -p $comm_home_backup_dir/.config $private_home_backup_dir/.ssh

  echo "--- Backup common configs in home ---"
  for conf in ${confs_in_home_common[*]}; do
    [[ -e ~/$conf ]] && cp -av ~/$conf $comm_home_backup_dir/
  done

  echo "--- Backup private configs in home ---"
  for conf in ${confs_in_home_private[*]}; do
    [[ -e ~/$conf ]] && cp -av ~/$conf $private_home_backup_dir
  done

  echo "--- Backup configs in ~/.config ---"
  for config_dir in ${home_config_dirs[*]}; do
    [[ -e ~/.config/$config_dir ]] && cp -av ~/.config/$config_dir $comm_home_backup_dir/.config/
  done

  if [[ -d $(dirname $homebrew_backup_file) && $(command -v brew) ]]; then
    echo "++++++ Backup MacOS app list in background ... by homebrew/bundle ++++++"
    echo "backup file is $homebrew_backup_file"
    brew bundle dump --describe --force --file=$homebrew_backup_file &
  fi
}

function restoreconfigs() {
  echo "+++++ Restore configs ++++"
  mkdir -p
  for conf in ${confs_in_home_common[*]}; do
    [[ -f $comm_home_backup_dir/$conf ]] && cp -av $comm_home_backup_dir/$conf ~/
  done

  for conf in ${confs_in_home_private[*]}; do
    [[ -f $private_home_backup_dir/$conf ]] && cp -av $private_home_backup_dir/$conf ~/$conf
  done

  for config_dir in ${home_config_dirs[*]}; do
    [[ -d comm_home_backup_dir/.config/$config_dir ]] && cp -av $comm_home_backup_dir/.config/$config_dir ~/.config/
  done

  if [[ -f $homebrew_backup_file && $(command -v brew) ]]; then
    echo "[tip] reinstall macos apps from backupfile"
    echo -e "1. install brew and 'brew install mas' (optional) \n2. execute "brew bundle --file=$homebrew_backup_file" "
  fi
}

#+++++ setting & alias +++++
#---vim/nvim editor---
command -v vim &>/dev/null && alias vi=vim
command -v nvim &>/dev/null && alias vi=nvim
export EDITOR=vim

#---vim plugins--- (manager: vim-plug)
#pacman -S vim-plugin --no-comfirm
alias vimplugup="[[ -f ~/.vim/autoload/plug.vim ]] && vim -c 'PlugUpgrade' -c 'PlugInstall' -c 'PlugUpdate' -c 'q' -c 'q'"
alias vimpluginstall="curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim && \rm -rfv ~/.vim/autoload/plugin.vim.old && vimplugup"

alias neovimpluginstall="sh -c 'curl -fLo "${XDG_DATA_HOME:-~/.local/share}"/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim' && \rm -rfv ~/.local/share/nvim/site/autoload/plug.vim.old"

#neovim
if [[ -n $(command -v nvim) ]]; then
  alias vim=nvim
  alias vimdiff='exec nvim -d ' # "$@
  alias ex='exec nvim -e '      # "$@"
  alias rview='exec nvim -RZ '  # "$@"
  alias rvim='exec nvim -Z '    # "$@"
  alias view='exec nvim -R '    # "$@"
  alias nvim_init='mkdir -p ~/.local/share/nvim && mkdir -p ~/.config/nvim && \cp -av ~/.vimrc ~/.config/nvim/ && \ln -sf ~/.config/nvim/init.vim ~/.vimrc'
fi

#---temporary locale---
#localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
alias sc='export LANG=zh_CN.UTF-8 LC_CTYPE=zh_CN.UTF-8 LC_MESSAGES=zh_CN.UTF-8'
alias tc='export LANG=zh_TW.UTF-8 LC_CTYPE=zh_TW.UTF-8 LC_MESSAGES=zh_TW.UTF-8'
alias en='export LANG=en_US.UTF-8 LC_CTYPE=en_US.UTF-8 LC_MESSAGES=en_US.UTF-8'

#---package manager---
alias upgrade_tools='vimplugup && ohmyzsh_upgrade'

if [[ $os == Linux ]]; then
  # [[ -s /etc/environment ]] && source /etc/environment
  if [[ $(command -v pacman) ]]; then
    if [[ $user != root ]]; then
      alias pacman='sudo pacman'
      alias firewall-cmd='sudo firewall-cmd'
    fi
    alias i="pacman -S"
    alias r="pacman -Rscn"
    alias s="pacman -Ss"
    alias orphan='pacman -Rscn $(pacman -Qtdq)'
    alias pkgclean='orphan && paccache -rk 2 2>/dev/null'
    alias up='pacman -Syyu && yay && pkgclean && upgrade_tools'
    #makepkg aur
    alias aurinfo='updpkgsums && makepkg --printsrcinfo > .SRCINFO ; git status && echo ----git add -u---'
  elif [[ $(command -v apt) ]]; then
    if [[ $user != root ]]; then
      alias apt='sudo apt'
      alias ufw='sudo ufw'
    fi
    function clean_oprhan_debs() {
      while true; do
        [[ -z $(deborphan) ]] && break
        apt purge $(deborphan)
      done
    }
    alias i="apt install"
    alias r="apt purge"
    alias s="apt search"
    alias orphan='[[ -n $(command -v deborphan) ]] && clean_oprhan_debs || echo "deborphan not installed"'
    alias pkgclean='apt autoremove && apt autoclean && orphan'
    alias up='apt update && apt dist-upgrade && upgrade_tools'

  elif [[ $(command -v yum) ]]; then
    if [[ $user != root ]]; then
      alias yum='sudo yum'
      alias firewall-cmd='sudo firewall-cmd'
    fi
    alias i="yum install"
    alias r="yum remove"
    alias s="yum search"
    alias orphan='package-cleanup --orphans'
    alias oldkernel='package-cleanup --oldkernels --count=1'
    alias up='yum update && upgrade_tools'
    alias pkgclean='yum clean all && orphan'
  fi
elif [[ $os == Darwin ]]; then
  function brew_taps() {
    brew tap --custom-remote --force-auto-update homebrew/cask-versions https://mirrors.ustc.edu.cn/homebrew-cask-versions.git
    brew tap beeftornado/rmtree
    brew tap buo/cask-upgrade
    brew tap homebrew/bundle
    brew tap homebrew/cask-fonts
  }
  export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
  export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
  export HOMEBREW_NO_AUTO_UPDATE=true

  alias i="brew install"
  alias r="brew uninstall"
  alias s="brew search"
  alias pkgclean='brew cleanup'
  alias finderplugin='brew install qlcolorcode qlstephen qlmarkdown quicklook-json qlimagesize qlvideo webpquicklook' #suspicious-package suspicious-package quicklook-pat provisionql quicklookase

  alias up='brew cu -ay --no-brew-update ; brew update -v ; brew upgrade -g; upgrade_tools' # mas upgrade # && brew doctor
fi

#---system commands alias for different os---
# uncategorized commands
if [[ $os == Linux ]]; then
  alias trim='sudo fstrim -v /home && sudo fstrim -v /'
  alias logclean='sudo journalctl --vacuum-time=1weeks'
  [[ $user != root ]] && alias systemctl='sudo systemctl'
  if [[ -n $(command -v gio) && -n $XDG_CURRENT_DESKTOP ]]; then
    alias trashclean='gio trash --empty'
    alias rm='echo "[tip] rm is an alias for [gio trash], it will move file to Trash" && gio trash '
    alias trash='gio trash '
    alias trashlist='echo "[tip] use gio trash --restore to restore a file" && echo "---~/.local/share/Trash---" && ls ~/.local/share/Trash/files'
    alias trashclean='rm -rf ~/.local/share/Trash/*'
  fi
elif [[ $os == Darwin ]]; then
  alias tmquickly='sudo sysctl debug.lowpri_throttle_enabled=0'
  alias tmlistsnap='tmutil listlocalsnapshotdates'
  alias tmlistbackups='tmutil listbackups'
  alias tmrmsnap=' tmutil deletelocalsnapshots '
  alias tmrmbackup='sudo tmutil delete '
  alias temp='sudo powermetrics ... --samplers smc'
  alias battery='ioreg -rn AppleSmartBattery |\grep -i capacity |grep -iE ".+=.+[0-9]+$"'
fi

function clean() {
  pkgclean
  id | grep -Ew "wheel|sudo|root" && echo "clean packages cache" && pkgclean
  echo "clean zsh rubbish files..."
  \ls -1 .zcompdump-* | while read line; do
    [[ -z $(echo $line | grep -E "$ZSH_VERSION") ]] && \rm -fv $line
  done
}

#---file operation---
alias j=z #autojump shortcut is j
alias scp='scp -r'
alias ll='ls -lh'
alias la='ls -lah'
alias cp='cp -iv'
[[ -n $(command -v rsync) ]] && alias cp='echo "---cp is directed to an rsync command alias---" && rsync -av --progress --human-readable "$@"'
alias grep='grep --color'
alias tree='tree -C -L 1 --dirsfirst'
alias iconvgbk='iconv -f GBK -t UTF-8'                      #iconv -- file content encoding
alias convmvgbk='convmv -f GBK -t UTF-8 --notest --nosmart' #convmv -- filename encoding

#---tar + compress/uncompress
alias tarc="tar --exclude='.DS_Store' -acvf " #eg tar -acvf xx.tar.zst xx ,compression type suffix is needed
alias tarx='tar -xvf '

function dos2unix_all() {
  local dirpath=${1:-$(pwd)}
  dos2unix $dirpath/*
  \ls -1 | while read line; do
    [[ -d $dirpath/$line ]] && dos2unix_all $dirpath/$line
  done
}

#---.git nosync for icloud
if [[ $os == Darwin ]]; then
  function git_init() {
    git init . && mv .git .git.nosync && ln -s .git.nosync .git
    touch .gitignore
    grep ".git.nosync" .gitignore || echo ".git.nosync" >>.gitignore
    grep ".DS_Store" .gitignore || echo ".DS_Store" >>.gitignore
    ls -1a | grep .git
  }
  function nosync_git() {
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
fi

#---network---
alias myip='curl cip.cc' #ident.me v6.ident.me
alias ping='ping -c 4'

#---proxy
#alias shell_proxy='export ALL_PROXY="http://127.0.0.1:8010"'
alias shell_proxy='export ALL_PROXY="socks5h://127.0.0.1:1080"'
export NO_PROXY="localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"

export PROXYCHAINS_SOCKS5_HOST="127.0.0.1"
export PROXYCHAINS_SOCKS5_PORT="1080"

if [[ $os == Linux ]]; then
  export PROXYCHAINS_CONF_FILE=/etc/proxychains.conf
  alias px='proxychains -q'
  alias netinfo='nmcli con'
elif [[ $os == Darwin ]]; then
  export PROXYCHAINS_CONF_FILE=/usr/local/etc/proxychains.conf
  alias px='proxychains4 -q'
  alias netinfo='/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I'
#  socat -T 600 TCP4-LISTEN:8080,fork TCP4:10.1.5.100:8080
fi

#tmux
#export TMUX_TMPDIR=/tmp #/tmp is default

#find
alias f='find . -name '
alias rm_macos_ds_store='find . -name "*.DS_Store" -delete'

# nmap
#scan alive hosts
alias 'nmap-ports'="sudo nmap -sS "
alias 'nmap-hosts'="nmap -sP --system-dns ${gateway%.*}.0/24"
alias 'nmap-os'="sudo nmap -O --system-dns ${gateway%.*}.0/24"

#ansible
ANSIBLE_CONFIG=~/.ansible.cfg

#---dev tool---
dev_dir="$HOME/Public/dev"
dev_env_path=$HOME/Public/dev/env
dev_configs_path=$dev_dir/configs
dev_proj_path=$dev_dir/proj
alias dev="cd $dev_dir"
alias proj="cd $dev_proj_path"

#---nvm
export NVM_DIR="$dev_env_path/nvm"
[[ -z "$NVM_DIR" ]] && export NVM_DIR="$HOME/.nvm"

if [[ -s /usr/local/opt/nvm/nvm.sh ]]; then
  source /usr/local/opt/nvm/nvm.sh
  source /usr/local/opt/nvm/etc/bash_completion.d/nvm
elif [[ -s /usr/share/nvm/init-nvm.sh ]]; then
  source /usr/share/nvm/init-nvm.sh
  source /usr/share/nvm/bash_completion
  source /usr/share/nvm/install-nvm-exec
fi

#---npm
alias npmlistg='npm -g list --depth=0'
alias npmupg='npm -g upgrade'
alias npmmirrorchina='npm config set registry https://registry.npm.taobao.org'
#alias npmmirrorchina='npm config set registry=http://mirrors.cloud.tencent.com/npm/'

#-python
alias python=python3
alias pip=pip3
alias pipmirrorchina='pip config set global.index-url https://mirrors.cloud.tencent.com/pypi/simple'
#'pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple'
alias pipoutdated='pip list --outdated'
alias pipupgrade='pip install --upgrade $(pip list --outdate 2>/dev/null |sed -n "3,$ p"|cut -d " " -f 1)'
alias pydev='source ~/.virtualenvs/dev/bin/activate'
alias pip_install_from_list='pip3 install -r pip.list --no-index --find-links=.'

#-conda
if [ -r "/usr/local/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
  . "/usr/local/Caskroom/miniconda/base/etc/profile.d/conda.sh"
elif [ -r "/opt/miniconda/etc/profile.d/conda.sh" ]; then
  source "/opt/miniconda/etc/profile.d/conda.sh"
fi
# prevent auto active conda env, execute:
# conda config --set auto_activate_base false
alias condaclean='conda clean -ady'

#-jupyter lab
# show env: jupyter --path
export JUPYTERLAB_DIR=$dev_dir/jupyter
export JUPYTER_RUNTIME_DIR=$HOME/.local/share/jupyter/runtime #--runtime-dir
export JUPYTER_DATA_DIR=$HOME/.local/share/jupyter            #--data-dir
# export JUPYTER_CONFIG_DIR=

#-Golang |only gopath need set. default gopath is ~/go
export GOPROXY=https://goproxy.cn
export GOPATH=$dev_env_path/go
export PATH=$GOPATH/bin:$PATH
export GOROOT=$(go env GOROOT 2>/dev/null)

#-rust
export RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static
export RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup
export RUSTUP_HOME="$dev_env_path/rust/rustup"
export CARGO_HOME="$dev_env_path/rust/cargo"
export RUSTBINPATH="$CARGO_HOME/bin"

#---PATH
if [[ $os == Darwin ]]; then
  export PATH="/usr/local/sbin:/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
fi

#-fzf
if [[ -r /usr/share/fzf/completion.zsh ]]; then
  source /usr/share/fzf/completion.zsh
  source /usr/share/fzf/key-bindings.zsh
elif [[ -r ~/.fzf.zsh ]]; then
  source ~/.fzf.zsh
fi

alias fzfv="fzf --preview 'cat {}'"

#-environment module
if [[ -r /usr/local/opt/modules/init/zsh ]]; then
  source /usr/local/opt/modules/init/zsh
elif [[ -r /usr/share/modules/init/zsh ]]; then
  source /usr/share/modules/init/zsh
fi

[[ -d $dev_dir/modulefiles && $(command -v module) ]] && module use $dev_dir/modulefiles

#qrcode -t utf8 -o - $(cat file.txt)
alias qrcode='qrencode -t ansiutf8 -o - ' #qrencode -t ansiutf8 -o - "http://www.bing.com"

#asciinema record terminal
alias rec='asciinema rec -i 5 terminal-`date +%Y%m%d-%H%M%S`' #record
alias play='asciinema play'                                   #play record file

alias starwar='telnet towel.blinkenlights.nl'

#---中文古诗词---
function fortune_gushici() {
  if [[ $(command -v brew) ]]; then
    command -v fortune || brew install fortune
    git clone https://github.com/ruanyf/fortunes.git /tmp/fortune
    \cp -av /tmp/fortune/data/{tang*,song*} /usr/local/Cellar/fortune/9708/share/games/fortunes
  elif [[ $(command -v pacman) ]]; then
    command -v fortune || pacman -S fortune-mod --noconfirm
    # sudo \cp -av /tmp/fortune/data/{tang*,song*} /usr/share/fortune/
    yay -S fortune-mod-zh
  fi
}

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
# if [[ -n $(command -v xfce4-session) && -n $(uname -r | grep -E WSL) ]]; then
#   if [[ -n $(ps -ef | grep xfce4-session | grep -v grep) ]]; then
#     echo -e "\nxfce4  already running on display $DISPLAY" && return
#   fi
#   setsid startxfce4 >/tmp/xfce.log &
# fi

alias bash='export onlybash=true;bash '

#---post-load scripts
[[ -r ~/.shell.env.postload.sh ]] && source ~/.shell.env.postload.sh
