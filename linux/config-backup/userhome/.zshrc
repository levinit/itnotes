unalias -a

# Path to your oh-my-zsh installation.
if [[ -d $HOME/.oh-my-zsh ]]; then
  export ZSH=$HOME/.oh-my-zsh
elif [[ -d /usr/share/oh-my-zsh ]]; then
  export ZSH=/usr/share/oh-my-zsh
fi

# theme
ZSH_THEME="ys" #ys robbyrussell"
#ZSH_THEME='random' #enable ZSH_THEME_RANDOM_CANDIDATES
#ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# case-sensitive completion.
# CASE_SENSITIVE="true"

# use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# disable bi-weekly auto-update checks.
#DISABLE_AUTO_UPDATE="true"

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
#ENABLE_CORRECTION="true"

# display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# disable marking untracked files under VCS as dirty. This makes repository status check for large repositories much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# command execution time stamp shown in the history command output.
# optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications, see 'man strftime' for details.
HIST_STAMPS="yyyy-mm-dd"

# load plugins.They can be found in ~/.oh-my-zsh/plugins/*
plugins=(z zsh-interactive-cd zsh-syntax-highlighting zsh-autosuggestions gitignore)

ZSH_CACHE_DIR=$HOME/.oh-my-zsh-cache
# [[ -d $ZSH_CACHE_DIR ]] || mkdir $ZSH_CACHE_DIR

source $ZSH/oh-my-zsh.sh

###++++shell basic settings++

HISTSIZE=2333
SAVEHIST=2333
alias history='history -i'

#++++like bash style++++
#---shortcuts
#ctrl u : del chars from beginnig to cursor
bindkey \^U backward-kill-line
bindkey '^[OH' beginning-of-line
bindkey '^[OF' end-of-line
bindkey '^[[3~' delete-char


#auto complete git
autoload -Uz compinit && compinit
#ctrl w : delete front word
autoload -U select-word-style
select-word-style bash
setopt no_nomatch #通配符不用引号
#scp completion not need quote '' 无需引号也能scp补全
zstyle ':completion:*:scp:*' tag-order '! users'

alias zsh_upgrade='cd ~/.oh-my-zsh/ && git stash && cd - && omz update && cd $ZSH_CUSTOM/plugins/zsh-syntax-highlighting && git pull && cd $ZSH_CUSTOM/plugins/zsh-autosuggestions && git pull && cd -'

#+++++welcom msg
os=$(uname)
if [[ $os == Linux ]]; then #iproute
  innerip=$(ip addr | grep -o -P '1[^2]?[0-9]?(\.[0-9]{1,3}){3}(?=\/)')
  gateway=$(ip route | grep 'via' | cut -d ' ' -f 3 | uniq)
elif [[ $os == Darwin ]]; then #net-tools (ifconfig)
  innerip=$(ifconfig | grep inet | grep -vE "inet6|127.0.0.1" | cut -d " " -f 2)
  gateway=$(netstat -rn | grep "default" | awk '{print $2}' | head -n 1)
  HOSTNAME=$HOST
fi

echo -e "+++ $HOSTNAME : $(uname -rsm) +++
\e[1;36m$(date)\e[0m
\e[1;32m$gateway\e[0m <-- \e[1;31m$innerip\e[0m"
# cal

#+++++files backup and restore
configs_files=(.ssh/config .tmux.conf .condarc .zshrc .gitignore_global .gitconfig .vimrc) #makepkg.conf
path_for_bakcup=~/Documents/it/itnotes/linux/config-backup/userhome

ssh_backup_dir=$HOME/Documents/it/server-configs/ssh

function backupconfigs() {
  cd $HOME
  for config in ${configs_files[*]}; do
    [[ -f $config ]] || continue
    if [[ $config == .ssh/config ]]; then
      cp -av $config $ssh_backup_dir/
    else
      cp -av ~/$config $path_for_bakcup/
    fi
  done
}

function restoreconfigs() {
  for config in ${configs_files[*]}; do
    if [[ $config == .ssh/config ]]; then
      cp -av $ssh_backup_dir/config ~/.ssh/config
    else
      cp -av $path_for_bakcup/$config ~/
    fi
  done
}

#+++++ setting & alias +++++
#---default editor---
alias vi=vim
export EDITOR='vim'

#---temporary locale---
alias sc='export LANG=zh_CN.UTF-8 LC_CTYPE=zh_CN.UTF-8 LC_MESSAGES=zh_CN.UTF-8'
alias tc='export LANG=zh_TW.UTF-8 LC_CTYPE=zh_TW.UTF-8 LC_MESSAGES=zh_TW.UTF-8'
alias en='export LANG=en_US.UTF-8 LC_CTYPE=en_US.UTF-8 LC_MESSAGES=en_US.UTF-8'

#---package manager---
if [[ $os == Linux ]]; then
  if [[ $(command -v pacman) ]]; then
    alias pacman='sudo pacman'
    alias orphan='sudo pacman -Rscn $(pacman -Qtdq)'
    alias pkgclean='sudo paccache -rk 2 2>/dev/null'
    alias up='yay || pkgclean -rk 2 && orphan'
    #makepkg aur
    alias aurinfo='updpkgsums && makepkg --printsrcinfo > .SRCINFO ; git status'

  elif [[ $(command -v apt) ]]; then
    alias apt='sudo apt'
    alias orphan='sudo apt purge $(deborphan)'
    alias up='sudo apt update && sudo apt dist-upgrade'
    alias pkgclean='sudo apt autoremove && sudo apt autoclean'
  fi
elif [[ $os == Darwin ]]; then
  #  brew tap beeftornado/rmtree
  #  brew tap buo/cask-upgrade
  #  brew tap homebrew/homebrew-cask
  ## export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles/bottles
  # export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
  export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.sjtug.sjtu.edu.cn/homebrew-bottles/bottles

  export HOMEBREW_NO_AUTO_UPDATE=true

  alias up='brew update && brew upgrade && brew cu -ay --no-brew-update' # && brew doctor'
  alias pkgclean='brew cleanup'
  alias finderplugin='brew install qlcolorcode qlstephen qlmarkdown quicklook-json qlimagesize qlvideo webpquicklook'  #suspicious-package suspicious-package quicklook-pat provisionql quicklookase
fi

#---system commands alias for different os---
if [[ $os == Linux ]]; then
  alias trim='sudo fstrim -v /home && sudo fstrim -v /'
  alias logclean='sudo journalctl --vacuum-time=1weeks'
  alias systemctl='sudo systemctl'
  alias rb='systemctl reboot'

  if [[ -d $HOME/.local/share/Trash/files ]] 
  then
    alias rm='mv -f --target-directory=$HOME/.local/share/Trash/files/'
    alias trashclean='\rm -rf $HOME/.local/share/Trash/files/*' 
  fi
elif [[ $os == Darwin ]]; then
  #sudo gem install iStats
  alias tmquickly='sudo sysctl debug.lowpri_throttle_enabled=0'
  alias tmlistsnap='tmutil listlocalsnapshotdates'
  alias tmlistbackups='tmutil listbackups'
  alias tmrmsnap=' tmutil deletelocalsnapshots '
  alias tmrmbackup='sudo tmutil delete '
fi

#---file operation---
alias ll='ls -lh'
alias la='ls -lah'
alias cp='cp -i'
alias grep='grep --color'
alias tree='tree -C -L 1 --dirsfirst'

#iconv -- file content encoding
alias iconvgbk='iconv -f GBK -t UTF-8'
#convmv -- filename encoding
alias convmvgbk='convmv -f GBK -T UTF-8 --notest --nosmart'

#---network---
alias ping='ping -c 4'

if [[ $os == Linux ]]; then
  export PROXYCHAINS_SOCKS5=1080
  export PROXYCHAINS_CONF_FILE=/etc/proxychains.conf
elif [[ $os == Darwin ]]; then
  export PROXYCHAINS_SOCKS5=1086
  export PROXYCHAINS_CONF_FILE=/usr/local/etc/proxychains.conf
fi
alias px='proxychains4'

# nmap
#scan alive hosts
alias 'nmap-ports'="sudo nmap -sS ${gateway%.*}.0/24"
alias 'nmap-hosts'="nmap -sP ${gateway%.*}.0/24"
alias 'nmap-os'="sudo nmap -O ${gateway%.*}.0/24"

#---virt-tools---
#docker
alias dockerstart='sudo systemctl start docker && docker ps -a'
alias dockerclean="docker images|grep none|awk '{print \$3}'|xargs docker rmi"

#libvirtd
alias virtstart='sudo modprobe virtio && sudo systemctl start libvirtd ebtables dnsmasq'

#---vim plugin---
#pacman -S vim-plugin --no-comfirm
#alias vimpluginstall="curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

#asciinema record terminal
alias rec='asciinema rec -i 5 terminal-`date +%Y%m%d-%H%M%S`' #record
alias play='asciinema play'                                   #play record file

#---中文古诗词---
function fortune_gushici() {
  git clone git@github.com:ruanyf/fortunes.git
  if [[ $os = Darwin ]]; then
    command -v fortune || brew install fortune
    cp -av fortunes/data/* /usr/local/Cellar/fortune/9708/share/games/fortunes
    cp -av fortune-zh
  elif [[ $(command -v pacman) ]]; then
    sudo pacman -S fortunes --noconfirm
    sudo cp -av fortunes/data/* /usr/share/fortunes/
  fi
}
command -v fortune >/dev/null && fortune -e tang300 song100 2>/dev/null #先秦 两汉 魏晋 南北朝 隋代 唐代 五代 宋代 #金朝 元代 明代 清代

#---dev tool---
#export SSLKEYLOGFILE=~/Desktop/ssl.log

#npm
alias npmlistg='npm -g list --depth=0'
alias npmupg='npm -g upgrade'
alias npmtaobao='npm config set registry https://registry.npm.taobao.org'

#python
alias python=python3
alias pip=pip3
alias pipoutdated='pip list --outdated'
alias pipupgrade='pip install --upgrade $(echo $(pip list --outdate|sed -n "3,$ p"|cut -d " " -f 1))'

#-Golang |only gopath need set. default gopath is ~/go
export GOPROXY=https://goproxy.cn
export GOPATH=$HOME/Public/dev/go

#conda
#[ -r "/usr/local/Caskroom/miniconda/base/etc/profile.d/conda.sh" ] && . "/usr/local/Caskroom/miniconda/base/etc/profile.d/conda.sh"
#prevent auto active conda env, execute:
#conda config --set auto_activate_base false
alias condaclean='conda clean -ady'

#environment module
#if [ -d /usr/share/modules/init ]
#then
#  source /usr/share/modules/init/zsh
#elif [ -d /usr/local/opt/modules/init ]
#then
#  source /usr/local/opt/modules/init/zsh
#fi

#ansible
ANSIBLE_CONFIG=~/.ansible.cfg

#---macos PATH
if [[ $os == Darwin ]]; then
  PATH="/usr/local/sbin:$PATH"
  [[ -d /usr/local/opt/gnu-sed/libexec/gnubin ]] && PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
  export PATH
  #sshfs
  alias sshfsvps='sshfs vps:/root /tmp/vps -o follow_symlinks && open /tmp/vps'
  alias sshfscvml='sshfs vps:/root /tmp/vps -o follow_symlinks && open /tmp/cvml'
fi


[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
alias fzfbat="fzf --preview 'bat {}'"
