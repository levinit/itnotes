# Path to your oh-my-bash installation.
export OSH=~/.oh-my-bash

# Set name of the theme to load.
OSH_THEME="mairan" #mbriggs"  #random

# use case-sensitive completion.
CASE_SENSITIVE="true"

# use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# change how often to auto-update (in days).
export UPDATE_OSH_DAYS=33

# disable colors in ls.
# DISABLE_LS_COLORS="true"

# disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# enable command auto-correction.
# ENABLE_CORRECTION="true"

# display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# disable marking untracked files under VCS as dirty.
# This makes repository status check for large repositories much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# command execution time stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="yyyy-mm-dd"

# Would you like to use another custom folder than $OSH/custom?
# OSH_CUSTOM=/path/to/new-custom-folder

# completions (can be found in ~/.oh-my-bash/completions/*)
completions=(git ssh)

# aliases (can be found in ~/.oh-my-bash/aliases/*)
aliases=()

# plugins (can be found in ~/.oh-my-bash/plugins/*)
plugins=(battery)

source $OSH/oh-my-bash.sh

#++++bash basic settings
unalias -a

export BASH_SILENCE_DEPRECATION_WARNING=1

bind Space:magic-space

#--history
shopt -s histappend
# HISTTIMEFORMAT='%F %T '
HISTSIZE="5000"
# HISTFILESIZE=  #bytes

#+++++

#+++++welcom msg

os=$(uname)
innerip=$(ip a | grep -Eo 'inet [0-9.]+/[0-9]+' | cut -d ' ' -f 2)
gateway=$(ip r | grep default | cut -d ' ' -f 3)

if [[ $os == Linux ]]; then #iproute
  innerip=$(ip addr | grep -o -P '1[^2]?[0-9]?(\.[0-9]{1,3}){3}(?=\/)')
  gateway=$(ip route | grep 'via' | cut -d ' ' -f 3 | uniq)
elif [[ $os == Darwin ]]; then #net-tools (ifconfig)
  export HOSTNAME=$HOST
  innerip=$(ifconfig | grep inet | grep -vE "inet6|127.0.0.1" | cut -d " " -f 2)
  gateway=$(netstat -rn | grep "default" | awk '{print $2}' | head -n 1)
  # gateway=$(route -n get default | grep gateway | grep -oE '[0-9.]+')
fi

echo -e "+++ $(uname -rsnm) +++
\e[1;36m$(date)\e[0m
\e[1;32m$gateway\e[0m <-- \e[1;31m$innerip\e[0m"

#+++++files backup and restore
configs_files=(.ssh/config .condarc .bashrc .gitignore_global .gitconfig .vimrc) #makepkg.conf
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
  function brew_install_config() {
    brewinstall='/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" && '
    #使用ustc源
    cd "$(brew --repo)"
    git remote set-url origin https://mirrors.ustc.edu.cn/brew.git
    # brew core git
    cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core"
    git remote set-url origin https://mirrors.ustc.edu.cn/homebrew-core.git
    # brew cask git
    cd "$(brew --repo)"/Library/Taps/homebrew/homebrew-cask
    git remote set-url origin https://mirrors.ustc.edu.cn/homebrew-cask.git
    #
    cd
    brew tap beeftornado/rmtree
    echo "use 'brew rmtree'  instead of 'brew uninstall' "
    echo "rmtree will remove package and dependcies (only for formulas)."
    brew tap buo/cask-upgrade
    echo "run 'brew cu' to check and upgrade packages in for formula and cask "
    #mas
    brew install mas
  }

  export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.aliyun.com/homebrew/homebrew-bottles

  alias up='mas upgrade && brew update && brew outdated && brew upgrade && brew cu -ay --no-brew-update' # && brew doctor'
  alias pkgclean='brew cleanup'
  alias finderplugin='brew install qlcolorcode qlstephen qlmarkdown quicklook-json qlimagesize qlvideo webpquicklook'
  #suspicious-package suspicious-package quicklook-pat provisionql quicklookase
fi

#---system commands alias for different os---
if [[ $os == Linux ]]; then
  alias trim='sudo fstrim -v /home && sudo fstrim -v /'
  # clear 2 weeks ago logs
  alias logclean='sudo journalctl --vacuum-time=1weeks'
  alias systemctl='sudo systemctl'

  [[ -d $HOME/.local/share/Trash/files ]] && alias rm='mv -f --target-directory=$HOME/.local/share/Trash/files/'

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
elif [[ $os == Darwin ]]; then
  export PROXYCHAINS_SOCKS5=1086
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
#libvirtd
alias virtstart='sudo modprobe virtio && sudo systemctl start libvirtd ebtables dnsmasq'

#---vim plugin---
#pacman -S vim-plugin --no-comfirm
alias vimpluginstall="curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

#asciinema record terminal
alias rec='asciinema rec -i 5 terminal-`date +%Y%m%d-%H%M%S`' #record
alias play='asciinema play'                                   #play record file

#---中文古诗词---
function fortune_gushici() {
  git clone git@github.com:ruanyf/fortunes.git
  if [[ $os = Darwin ]]; then
    command -v fortune || brew install fortune
    cp -av fortunes/data/* /usr/local/Cellar/fortune/9708/share/games/fortunes
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
alias npmtaobao='npm config set registry https://registry.npm.taobao.org'

#python
alias python=python3
alias pip=pip3
alias pipoutdated='pip list --outdated'
alias pipupgrade='pip install --upgrade $(echo $(pip list --outdate|sed -n "3,$ p"|cut -d " " -f 1))'

#-Golang |only gopath need set. default gopath is ~/go
export GOPROXY=https://mirrors.aliyun.com/goproxy/,direct
gopath=$HOME/Public/dev/go
[[ -d $gopath ]] || mkdir -p $gopath && export GOPATH=$gopath

#openblas
if [[ $os == Darwin && -d /usr/local/opt/openblas ]]; then
  export LDFLAGS="-L/usr/local/opt/openblas/lib"
  export CPPFLAGS="-I/usr/local/opt/openblas/include"
  export PKG_CONFIG_PATH="/usr/local/opt/openblas/lib/pkgconfig"
fi

#conda
[ -r "/usr/local/Caskroom/miniconda/base/etc/profile.d/conda.sh" ] && . "/usr/local/Caskroom/miniconda/base/etc/profile.d/conda.sh"
#prevent auto active conda env, execute:
#conda config --set auto_activate_base false
alias condaclean='conda clean -ady'

#ansible
ANSIBLE_CONFIG=~/.ansible.cfg

#---macos PATH
if [[ $os == Darwin ]]; then
  export PATH="/usr/local/sbin:$PATH"
  #sshfs
  alias sshfsvps='sshfs vps:/root /tmp/vps -o follow_symlinks && open /tmp/vps'
  alias sshfscvml='sshfs vps:/root /tmp/vps -o follow_symlinks && open /tmp/cvml'
fi

#bash-completion
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"
#autojump
[[ -f /usr/local/etc/profile.d/autojump.sh ]] && source /usr/local/etc/profile.d/autojump.sh
