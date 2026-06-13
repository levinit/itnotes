unalias -a
os=$(uname)
user=$(whoami)
arch=$(uname -m)

#===== dev configs =====
dev_env_dir="$HOME/Public/dev/env"

#---mise https://mise.en.dev
mise_dir=$dev_env_dir/mise
export MISE_DATA_DIR=$mise_dir
export MISE_CACHE_DIR=$mise_dir/cache
# export MISE_GLOBAL_CONFIG_FILE=~/.config/config.toml
command -v mise &>/dev/null && eval "$(mise activate zsh)"
alias miseprune='command -v mise &>/dev/null && mise prune'
alias miseup='command -v mise &>/dev/null && mise upgrade'
export MISE_ENV_SHELL_EXPAND=true # it will be as default since ver 2026.7

#-golang
export GOPROXY="https://goproxy.cn"
export GOPATH="$dev_env_dir/go"
export GOBIN="$GOPATH/bin"
export PATH=$GOBIN:$PATH

#-rust
export RUSTUP_DIST_SERVER="https://mirrors.ustc.edu.cn/rust-static"
#export RUSTUP_UPDATE_ROOT="https://mirrors.ustc.edu.cn/rust-static/rustup"
export RUSTUP_HOME="$dev_env_dir/rust/rustup"
export CARGO_HOME="$dev_env_dir/rust/cargo"
export PATH=$CARGO_HOME/bin:$PATH

#-bun
export BUN_STORE="$dev_env_dir/bun/store"

#-npm
export NPM_CONFIG_CACHE="$dev_env_dir/node/npm_cache"

#-dotnet
export NUGET_PACKAGES="$dev_env_dir/dotnet/nuget/packages"

#---python
export PIP_INDEX_URL="https://mirrors.cloud.tencent.com/pypi/simple" #https://pypi.tuna.tsinghua.edu.cn/simple
export PIP_CACHE_DIR="$dev_env_dir/python/pip_cache"

#---uv
export UV_CACHE_DIR="$dev_env_dir/uv/cache"

#--- only for macos
if command -v brew &>/dev/null; then
	homebrew_dir=/opt/homebrew
	export PATH="$homebrew_dir/opt/gnu-sed/libexec/gnubin:$homebrew_dir/bin:$homebrew_dir/sbin:$PATH"
fi

[[ $- != *i* ]] && return # exit if not interactive shell

#+++++ Interactive shell +++++
#----- starship prompt -----
eval "$(starship init zsh)"
#all preset prompts: starship preset -l
#set preset prompt : starship preset <name> -o $HOME/.config/starship.toml

#===== welcom msg =====
echo -e "+++ $HOST : $(uname -rsm) +++\n\e[1;36m@$(date)\e[0m"

#--- IP info
show_ip() {
	if command -v ifconfig &>/dev/null; then
		ifconfig | grep inet | grep -vE "inet6|127.0.0.1" | grep -v 169.254 | cut -d " " -f 2 | while read innerip; do
			network_info="$network_info""$innerip\n"
		done
		for interface in $(ifconfig -lu); do
			[[ $interface == lo0 ]] && continue
			local network_info=$(ifconfig $interface | grep -w inet | awk -v interface=$interface '/inet6?/{print interface": "$2}')"\n$network_info"
		done
		local gateway=$(netstat -rn | grep "default" | awk '{print $2}' | head -n 1)
		echo -e "gateway:\e[3;35m" $(echo $gateway)"\e[0m\n\e[31m$(echo "$network_info" | sed -E -e "/^$/d" -e "s/\t/\s/g")\e[0m"

	elif command -v ip &>/dev/null; then #iproute
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
	fi
}

show_ip && unset show_ip network_info gateway innerips

#---fortune
FORTUNE_DIR=~/.local/share/fortune
if command -v fortune &>/dev/null; then
#  FORTUNE_DIR=$(fortune -f 2>&1|head -n 1|awk '{print $NF}') 如果要放到fortune默认目录使用该行
	case $os in
	Darwin)
		#fortune song100 tang300 2>/dev/null
		fortune $FORTUNE_DIR/gushici-cht 2>/dev/null
		;;
	Linux)
		#fortune chinese-hant song100-hant tang300-hant 2>/dev/null
		fortune $FORTUNE_DIR/gushici-cht 2>/dev/null
		;;
	esac
fi

#---calendar
if command -v ccal &>/dev/null; then
	ccal -u
elif command -v cal &>/dev/null; then
	cal -m
fi

#===== welcome msg end =====

#=====utility=====
#------ vim & neovim ------
export EDITOR=vim
alias vi=vim
if command -v nvim &>/dev/null; then
	export EDITOR=nvim
	alias vim=nvim
	alias vimdiff='nvim -d ' # "$@
	alias ex='nvim -e '      # "$@"s
	alias rview='nvim -RZ '  # "$@"
	alias rvim='nvim -Z '    # "$@"
	alias view='nvim -R '    # "$@"
fi

#----- package manager -----
package_manager=""
case $os in
Darwin)
	package_manager="brew"
	function brew_taps() {
		brew tap beeftornado/rmtree
		brew tap buo/cask-upgrade
	}

	export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
	export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
	export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
	export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"

	export HOMEBREW_NO_AUTO_UPDATE=true
	alias i="brew install"
	alias r="brew uninstall --zap"
	alias s="brew search"
	alias list="brew list"
	alias pkg_query_update='brew outdated'
	alias pkgclean='brew cleanup ; miseprune'
	alias up='brew cu -ay --no-brew-update ; brew update -v ; brew upgrade -g ; miseup ; pkgclean' # mas upgrade # && brew doctor
	;;

	#---miniforge
	# if [ -f "$homebrew_dir/Caskroom/miniforge/base/etc/profile.d/conda.sh" ]; then
	# 	. "$homebrew_dir/Caskroom/miniforge/base/etc/profile.d/conda.sh"
	# 	alias conda="echo mamba is a alias for miniforge && echo && mamba"
	# 	eval "$(mamba shell hook --shell zsh)"
	# fi
	# prevent auto active conda env, execute: conda config --set auto_activate_base false

Linux)
	if command -v pacman &>/dev/null; then
		package_manager="pacman"
		[[ $user != root ]] && alias pacman='sudo pacman'
		alias i="pacman -S"
		alias r="pacman -Rscn"
		alias qs="pacman -Qs"
		alias s="yay --bottomup"
		alias orphan='pacman -Rscn $(pacman -Qtdq)'
		alias pkgclean='orphan && paccache -rk 2 2>/dev/null ; miseprune'
		alias pkg_query_update='pacman -Sy && pacman -Qu'
		alias up='if command -v yay; then yay -Syu; else pacman -Syu; fi ; miseup ; pkgclean'
		#makepkg aur
		alias aurinfo='updpkgsums && makepkg --printsrcinfo > .SRCINFO ; git status && echo ----git add -u---'
		alias aurdepcheck='namcap PKGBUILD && namcap *.pkg.tar.zst'
	fi
	;;
esac

#---uncategorized commands
alias tmlistsnap='tmutil listlocalsnapshotdates'
alias tmlistbackups='tmutil listbackups'
alias tmrmsnap=' tmutil deletelocalsnapshots '
alias tmrmbackup='sudo tmutil delete '

quit() {
    osascript -e "quit app \"$1\""
    echo -e "Tips: open a GUI app with \e[32;1mopen -a AppName\e[0m"
}

alias trim='sudo fstrim -v /home && sudo fstrim -v /'
alias logclean='command -v journalctl &>/dev/null && sudo journalctl --vacuum-time=1weeks'

if [[ $user != root ]]; then
	alias systemctl='sudo systemctl'
	alias firewall-cmd='sudo firewall-cmd'
fi

#---temporary locale
#localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
alias sc='export LANG=zh_CN.UTF-8 LC_CTYPE=zh_CN.UTF-8 LC_MESSAGES=zh_CN.UTF-8'
alias tc='export LANG=zh_TW.UTF-8 LC_CTYPE=zh_TW.UTF-8 LC_MESSAGES=zh_TW.UTF-8'
alias en='export LANG=en_US.UTF-8 LC_CTYPE=en_US.UTF-8 LC_MESSAGES=en_US.UTF-8'

#---file operations
alias scp='echo -e "\e[1;33m[Tips]\e[0m rsync -avP 效率更高且支持断点续传" >&2 ; \scp'
alias ls='ls --color -F'
alias ll='ls -lF' lh='ls -lhF' la='ls -lAF' lah='ls -lhAF' #'ls -lah'
alias ..='cd ../' ...='cd ../..' ....='cd ../../..'
alias cp='cp -iv'
alias grep='grep --color'
alias tree='tree -C -L 1 --dirsfirst'
alias iconvgbk='iconv -f GBK -t UTF-8'                      #iconv -- file content encoding
alias convmvgbk='convmv -f GBK -t UTF-8 --notest --nosmart' #convmv -- filename encoding

#gio for trash
if command -v gio &>/dev/null; then # && -n $XDG_CURRENT_DESKTOP ]]; then
	alias trashclean='gio trash --empty'
	alias rm='echo "[tip] rm is an alias for [gio trash], it will move file to Trash" >&2 ; gio trash '
	alias trash='gio trash '
	alias trashlist='echo "[tip] use gio trash --restore to restore a file" >&2 ; echo "---~/.local/share/Trash---" >&2 ; ls ~/.local/share/Trash/files'
	alias open='gio open'
fi
#alias open='xdg-open'

#tar + compress/uncompress
#eg tar -acvf xx.tar.zst xx ,compression type suffix is needed
export TAR_OPTIONS='--exclude=.DS_Store --exclude=__MACOSX --exclude=desktop.ini --exclude=thumbs.db --exclude=.tmp'

alias tarc='tar -acvf'
alias tarx='tar -xvf'
alias tarl='\tar -tf'

dos2unix_all() {
	find "${1:-$(pwd)}" -type f -print0 | xargs -0 -n 8 dos2unix
}

#--- git
alias gitgc='git gc --aggressive --prune=now'
alias gitrmlog='git reflog expire --expire=now --all && git gc --aggressive --prune=now'
function gitconfig(){
  git config --global core.autocrlf input
  git config --global core.eol lf
  git config --global core.safecrlf warn
  git config --global core.quotepath false
  git config --global init.defaultBranch main
  git config --global push.autoSetupRemote
  git config --global pull.ff only
  git config --global rerere.enabled
  git config --global push.default
}
alias git_force_pull_main="git branch -D atmp1 ; git fetch && git checkout -b atmp1 && git branch -D main && git switch main && git branch -D atmp1"
alias gme='git merge' gfe='git fetch' gpush='git push' gpull='git pull' gst='git status' gsw='git switch' gbd='git branch -D' gcb='git checkout -b' greset='git reset --hard' gclean='git clean -fd' gcm='git commit -m' 
alias gfix='git commit --amend --no-edit' gam=gfix

# .git nosync for icloud
git_init_nosync_icloud() {
	git init . && mv .git .git.nosync && ln -s .git.nosync .git
	touch .gitignore
	grep ".git.nosync" .gitignore || echo ".git.nosync" >>.gitignore
	grep ".DS_Store" .gitignore || echo ".DS_Store" >>.gitignore
	ls -1a | grep .git
}

nosync_git_icloud() {
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

#---network---
alias ipv6='curl -s 6.ipw.cn' ipv4='curl -s 4.ipw.cn' ip_4_6_prefer='curl test.ipw.cn'
alias myip='curl cip.cc && echo && echo IPv6: $(ipv6 || echo noIPv6)' #ident.me v6.ident.me
alias ping='ping -c 4'

#---proxy
alias shell_proxy='export ALL_PROXY="https://127.0.0.1:7890"' unproxy='unset ALL_PROXY'

#---find
alias f='find . -name '
alias rm_mac_ds='find . \( -name "*.DS_Store" -o -name "._*" \) -delete'

#---nmap
alias 'nmap-ports'="sudo nmap -sS "
alias 'nmap-hosts'='nmap -sP --system-dns $(ip r | grep default | head -n 1 | grep -Po "(?<=via ).+(?= dev)" | sed "s/\.[0-9]*$/.0/")/24'
alias 'nmap-os'='sudo nmap -O --system-dns $(ip r | grep default | head -n 1 | grep -Po "(?<=via ).+(?= dev)" | sed "s/\.[0-9]*$/.0/")/24'

#asciinema record terminal
alias rec='asciinema rec -i 5 terminal-`date +%Y%m%d-%H%M%S`' #record
alias play='asciinema play'                                   #play record file

alias fzfv="fzf --preview 'cat {}'"

#---中文古诗词---
fortune_gushici() {
	if [[ $package_manager == "brew" ]]; then
    #FORTUNE_DIR=$(brew --prefix fortune)
		command -v fortune || brew install fortune || return
	elif [[ $package_manager == "pacman" ]]; then
		command -v fortune || pacman -S fortune-mod --noconfirm || return
#		yes | yay -S fortune-mod-zh-hant
	fi
  #FORTUNE_DIR=$(fortune -f 2>&1|head -n 1|awk '{print $NF}')
	#git clone --depth 1 https://github.com/debiancn/fortune-zh.git /tmp/fortune-zh
	#cd /tmp/fortune-zh && make tang300.dat song100.dat chinese.dat
	#\cp -av /tmp/fortune-zh/{tang*,song*,chinese*} $FORTUNE_DIR/share/games/fortunes
  mkdir -p $FORTUNE_DIR
	git clone --depth 1 https://github.com/levinit/fortune-gushici.git /tmp/fortune-gushici && cp /tmp/fortune-gushici/data/gushici* $FORTUNE_DIR
}

#===== functions for config files =====
create_config_file_symbols() {
	# common config files in ~/
	local comm_home_backup_dir=~/Documents/it/itnotes/linux/config-backup/userhome
	local common_confs_in_home=(.tmux.conf .condarc .zlogout .zshrc .gitignore_global .vimrc .makepkg.conf)

	# private files in ~/
	local private_home_backup_dir=~/Documents/os-config/home.config
	local private_confs_in_home=(.gitconfig .ssh/id_ed25519 .ssh/id_ed25519.pub .ssh/config)

	# common config files in ~/.config
	local common_home_config_backup_dir=$comm_home_backup_dir/.config
	local common_confs_in_home_config=(dconf/backup-dconf.sh dconf/dconf.conf starship.toml mise/config.toml)

	for conf in ${common_confs_in_home[*]}; do
		[[ -f $comm_home_backup_dir/$conf ]] && ln -sfv $comm_home_backup_dir/$conf ~/$conf
	done

	for conf in ${private_confs_in_home[*]}; do
		[[ -f $private_home_backup_dir/$conf ]] && ln -sfv $private_home_backup_dir/$conf ~/$conf
	done

	for conf in ${common_confs_in_home_config[*]}; do
		[[ -r $common_home_config_backup_dir/$conf ]] && ln -sfv $common_home_config_backup_dir/$conf ~/.config/$conf
	done
	unset conf
}

#++++++++++++++++++++++++++++++++++++
#====pkg update check
if [[ -f ~/.cache/pkg_last_update ]]; then
	pkg_last_update=$(cat ~/.cache/pkg_last_update)
	pkg_list_backup_dir=~/Documents/os-config/home.config
	if [[ $(date +%s) -gt $((pkg_last_update + 30 * 24 * 3600)) ]]; then
		(pkg_query_update >/tmp/pkg_update.log 2>&1 &)
		echo $(date +%s) >~/.cache/pkg_last_update
		case $package_manager in
		pacman)
			pacman -Qqen >$pkg_list_backup_dir/pacman.list.txt                  #native pkgs(offical repo)
			pacman -Qqem >~/Documents/os-config/home.config/pacman.aur.list.txt #no official pkgs
			;;
		brew)
			brew list >$pkg_list_backup_dir/brew.list.txt
			;;
		esac
	fi
	unset pkg_last_update pkg_list_backup_dir
else
	mkdir -p ~/.cache && echo $(date +%s) >~/.cache/pkg_last_update
fi

#===== ZSH configs =====
#---plugins
zsh_plugins=(zsh-autosuggestions zsh-syntax-highlighting)

shell_plugins() {
	if [[ $package_manager == "pacman" ]]; then
		pacman -S --noconfirm zsh starship zoxide ${zsh_plugins[@]} zsh-completions
	elif [[ $package_manager == "brew" ]]; then
		brew install zsh starship zoxide ${zsh_plugins[@]} #zsh-completions
	fi
	unset plugin
}

#--- $ZSH plugins
case $os in
Darwin)
	ZSH_PLUGINS_DIR=$homebrew_dir/share
	;;
*)
	if [[ -d /usr/share/zsh/plugins ]]; then
		ZSH_PLUGINS_DIR=/usr/share/zsh/plugins
	elif [[ -d /usr/share/zsh ]]; then #for debian
		ZSH_PLUGINS_DIR=/usr/share/zsh
	else
		ZSH_PLUGINS_DIR=~/.zsh
	fi
	;;
esac

# load plugins.They can be found in $ZSH_PLUGINS/* zsh-completions no need source
for plugin in ${zsh_plugins[*]}; do
	[[ -f $ZSH_PLUGINS_DIR/$plugin/$plugin.zsh ]] && source $ZSH_PLUGINS_DIR/$plugin/$plugin.zsh
done
unset plugin
unset ZSH_PLUGINS_DIR

#plugins config
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=cyan,bg=bold,underline" #fg=#ff00ff,bg=cyan,bold,underline
ZSH_AUTOSUGGEST_STRATEGY=(history)                          #completion)

#z-jump: zoxide
command -v zoxide &>/dev/null && eval "$(zoxide init --cmd z zsh)"

#---shell history
HISTFILE=~/.zsh_history HISTSIZE=23333 SAVEHIST=$HISTSIZE
alias history='history -i' history_all='history -i -$HISTSIZE' #history -15  #in bash: history 15
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY

#=== Compatible with the operation habits of bash
#---shortcus
bindkey \^U backward-kill-line   #ctrl u (tip: ctrl k forwards-kill-line)
bindkey '^[OH' beginning-of-line #ctrl a
bindkey '^[OF' end-of-line       #ctrl e
bindkey '^[[3~' delete-char      #ctrl h

#---operation style compatibility
autoload -U +X bashcompinit && bashcompinit 2>/dev/null
autoload -Uz compinit && compinit
autoload -U select-word-style
select-word-style bash
setopt no_nomatch #no error when no match
zstyle ':completion:*:scp:*' tag-order '! users'

#===== ssh-agent
function active_ssh_agent() {
	if [[ -z $(ps -eo pid,user,command | grep -w $USER | grep "ssh-agent" | grep -v grep) ]]; then
		eval "$(ssh-agent -s)"
		echo "export SSH_AGENT_PID=$SSH_AGENT_PID" >~/.cache/.ssh-agent.env
		echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" >>~/.cache/.ssh-agent.env
		ssh-add
	else
		[[ -f ~/.cache/.ssh-agent.env ]] && source ~/.cache/.ssh-agent.env
	fi
}

[[ $os != Darwin ]] && active_ssh_agent # ssh-agent is not needed in macOS since it has its own keychain management

#===== post load scripts =====
test -r ~/.shell.env.postload.sh && source ~/.shell.env.postload.sh || true
