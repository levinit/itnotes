unalias -a
os=$(uname)
user=$(whoami)
arch=$(uname -m)

#---specify $PATH
if [[ $os == Darwin ]]; then
	homebrew_dir=$(brew --prefix)
	export PATH="$homebrew_dir/bin:$homebrew_dir/sbin:$homebrew_dir/opt/gnu-sed/libexec/gnubin:$PATH"
fi

#===== ENV configs =====
dev_dir="$HOME/Public/dev"
dev_env_path=$HOME/Public/dev/env
dev_configs_path=$dev_dir/configs
dev_proj_path=$dev_dir/proj
alias dev="cd $dev_dir" proj="cd $dev_proj_path"

export PATH="$dev_env_path/bin:$PATH"

#---nvm
export NVM_DIR=$dev_env_path/nvm
[ -s "$homebrew_dir/opt/nvm/nvm.sh" ] && \. "$homebrew_dir/opt/nvm/nvm.sh"
[ -s "$homebrew_dir/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$homebrew_dir/opt/nvm/etc/bash_completion.d/nvm"
export PNPM_HOME=$dev_env_path/pnpm
[ -d $PNPM_HOME ] && export PATH=$PNPM_HOME:$PATH
#nvm install node && npm install -g pnpm && pnpm config set store-dir $dev_env_path/pnpm

export BUN_STORE=$dev_env_path/bun/store
(command -v bun &>/dev/null && (test -d $BUN_STORE || mkdir -p $BUN_STORE) &)
export BUN_REGISTRY=https://registry.npmjs.org

#----golang
export GOPROXY=https://goproxy.cn
export GOPATH=$dev_env_path/go #default is ~/go
export PATH=$GOPATH/bin:$PATH
export GOROOT=$(go env GOROOT 2>/dev/null)
(command -v go &>/dev/null && (test -d $GOPATH || mkdir -p $GOPATH) &)
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
alias pipupgrade='pip install --upgrade $(pip list --outdate 2>/dev/null |sed -n "3,$ p"|cut -d " " -f 1)'
alias pip_install_from_list='pip3 install -r pip.list --no-index --find-links=.'

#---miniconda/miniforge
if [ -f "$homebrew_dir/Caskroom/miniforge/base/etc/profile.d/conda.sh" ]; then
	. "$homebrew_dir/Caskroom/miniforge/base/etc/profile.d/conda.sh"
	alias conda="echo mamba is a alias for miniforge && echo && mamba"
	eval "$(mamba shell hook --shell zsh)"
fi
# prevent auto active conda env, execute: conda config --set auto_activate_base false

#---uv
export UV_CACHE_DIR=$dev_env_path/uv/cache
alias uvenv="envname=$(basename $PWD) && uv venv $dev_env_path/uv/venvs/$envname && ln -sfv $dev_env_path/uv/venvs/$envname .venv"

#---ansible
export ANSIBLE_CONFIG=$dev_configs_path/ansible/ansible.cfg

#---ollama
#export OLLAMA_MODELS="~/Public/llm/ollama/models"
#export OLLAMA_LOGFILE="~/Public/llm/ollama/ollama.log"
export OLLAMA_HOST="0.0.0.0:11434"
export OLLAMA_ORIGINS="*"
export OLLAMA_FLASH_ATTENTION=1
#export OLLAMA_KV_CACHE_TYPE=q8_0
#export OLLAMA_CONTEXT_LENGTH=8192

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

	elif command -v ifconfig &>/dev/null; then #BSD
		local innerips=$(ifconfig | grep inet | grep -vE "inet6|127.0.0.1" | grep -v 169.254 | cut -d " " -f 2)
		for innerip in ${innerips[@]}; do network_info="$network_info""$ip\n"; done
		for interface in $(ifconfig -lu); do
			[[ $interface == lo0 ]] && continue
			local network_info=$(ifconfig $interface | grep -w inet | awk -v interface=$interface '/inet6?/{print interface": "$2}')"\n$network_info"
		done
		local gateway=$(netstat -rn | grep "default" | awk '{print $2}' | head -n 1)
		echo -e "gateway:\e[3;35m" $(echo $gateway)"\e[0m\n\e[31m$(echo "$network_info" | sed -E -e "/^$/d" -e "s/\t/\s/g")\e[0m"
	fi
}

show_ip && unset show_ip network_info gateway innerips

#---fortune
if command -v fortune &>/dev/null; then
	case $os in
	Darwin)
		fortune song100 tang300 2>/dev/null
		;;
	Linux)
		fortune chinese-hant song100-hant tang300-hant 2>/dev/null
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
#pacman -S vim-plugin --no-comfirm
alias vimplugup="[[ -f ~/.vim/autoload/plug.vim ]] && vim -c 'PlugUpgrade' -c 'PlugInstall' -c 'PlugUpdate' -c 'q' -c 'q'"
alias vimpluginstall="curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim && \rm -rfv ~/.vim/autoload/plugin.vim.old && vimplugup"

export EDITOR=vim
alias vi=vim

#neovim
if command -v nvim &>/dev/null; then
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
	alias r="brew uninstall"
	alias s="brew search"
	alias list="brew list"
	alias pkg_query_update='brew outdated'
	alias pkgclean='brew cleanup'
	alias up='brew cu -ay --no-brew-update ; brew update -v ; brew upgrade -g' # mas upgrade # && brew doctor
	;;
Linux)
	if command -v pacman &>/dev/null; then
		package_manager="pacman"
		[[ $user != root ]] && alias pacman='sudo pacman'
		alias i="pacman -S"
		alias r="pacman -Rscn"
		alias qs="pacman -Qs"
		alias s="yay --bottomup" || alias s="pacman -Ss"
		alias orphan='pacman -Rscn $(pacman -Qtdq)'
		alias pkgclean='orphan && paccache -rk 2 2>/dev/null'
		alias pkg_query_update='pacman -Sy && pacman -Qu'
		alias up='if command -v yay; then yay -Syu; else pacman -Syu; fi ; pkgclean'
		alias yay='yay --bottomup'
		#makepkg aur
		alias aurinfo='updpkgsums && makepkg --printsrcinfo > .SRCINFO ; git status && echo ----git add -u---'
	elif command -v apt &>/dev/null; then
		package_manager="apt"
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
		alias up='apt update && apt dist-upgrade'
	fi
	;;
esac

#---uncategorized commands
alias tmlistsnap='tmutil listlocalsnapshotdates'
alias tmlistbackups='tmutil listbackups'
alias tmrmsnap=' tmutil deletelocalsnapshots '
alias tmrmbackup='sudo tmutil delete '
alias temp='sudo powermetrics ... --samplers smc'

alias trim='sudo fstrim -v /home && sudo fstrim -v /'
alias logclean='sudo journalctl --vacuum-time=1weeks'

if [[ $user != root ]]; then
	alias systemctl='sudo systemctl'
	alias firewall-cmd='sudo firewall-cmd'
fi

cleancache() {
	pkgclean
	id | grep -Ew "wheel|sudo|root" && echo "clean packages cache" && pkgclean
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
alias l='ls -lhAF'
alias ll='ls -lhAF'
alias la='ls -lhAF' #'ls -lah'
alias ..='cd ../'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cp='cp -iv'
[[ -n $(command -v rsync) ]] && alias cp='echo "---cp is directed to an rsync command alias---" && rsync -av --progress --human-readable -- "$@"'
alias grep='grep --color'
alias tree='tree -C -L 1 --dirsfirst'
alias iconvgbk='iconv -f GBK -t UTF-8'                      #iconv -- file content encoding
alias convmvgbk='convmv -f GBK -t UTF-8 --notest --nosmart' #convmv -- filename encoding

#gio for trash
if [[ $os == Linux ]]; then
	if command -v gio &>/dev/null; then # && -n $XDG_CURRENT_DESKTOP ]]; then
		alias trashclean='gio trash --empty'
		alias rm='echo "[tip] rm is an alias for [gio trash], it will move file to Trash" && gio trash '
		alias trash='gio trash '
		alias trashlist='echo "[tip] use gio trash --restore to restore a file" && echo "---~/.local/share/Trash---" && ls ~/.local/share/Trash/files'
		alias open='gio open'
	fi
fi
#alias open='xdg-open'

#tar + compress/uncompress
#eg tar -acvf xx.tar.zst xx ,compression type suffix is needed
alias tarc="tar --exclude='.DS_Store' -acvf " tarx='tar -xvf '

dos2unix_all() {
	find "${1:-$(pwd)}" -type f -print0 | xargs -0 -n 8 dos2unix
}

#--- git
alias gitgc='git gc --aggressive --prune=now'
alias gitrmlog='git reflog expire --expire=now --all && git gc --aggressive --prune=now'
alias git_force_pull_main="git branch -D atmp1 ; git fetch && git checkout -b atmp1 && git branch -D main && git switch main && git branch -D atmp1"
alias gm='git merge '
alias gf='git fetch'
alias gp='git push'
alias gs='git switch'

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
alias shell_proxy='export ALL_PROXY="socks5h://127.0.0.1:1080"' no_proxy='unset ALL_PROXY'

#---find
alias f='find . -name '
alias rm_mac_ds='find . -name "*.DS_Store" -name "._*" -delete'

#---nmap
alias 'nmap-ports'="sudo nmap -sS "
alias 'nmap-hosts'="nmap -sP --system-dns ${gateway%.*}.0/24"
alias 'nmap-os'="sudo nmap -O --system-dns ${gateway%.*}.0/24"

#asciinema record terminal
alias rec='asciinema rec -i 5 terminal-`date +%Y%m%d-%H%M%S`' #record
alias play='asciinema play'                                   #play record file

alias fzfv="fzf --preview 'cat {}'"

#---中文古诗词---
fortune_gushici() {
	if [[ $package_manager == "brew" ]]; then
		command -v fortune || brew install fortune
		git clone https://github.com/ruanyf/fortunes.git /tmp/fortune
		\cp -av /tmp/fortune/data/{tang*,song*} $homebrew_dir/Cellar/fortune/9708/share/games/fortunes
	elif [[ $package_manager == "pacman" ]]; then
		command -v fortune || pacman -S fortune-mod --noconfirm
		# sudo \cp -av /tmp/fortune/data/{tang*,song*} /usr/share/fortune/
		yes | yay -S fortune-mod-zh-hant
	fi
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
	local common_confs_in_home_config=(dconf/backup-dconf.sh dconf/dconf.conf startship.toml)

	for conf in ${common_confs_in_home[*]}; do
		[[ -f $comm_home_backup_dir/$conf ]] && ln -sfv $comm_home_backup_dir/$conf ~/$conf
	done

	for conf in ${private_confs_in_home[*]}; do
		[[ -f $private_home_backup_dir/$conf ]] && ln -sfv $private_home_backup_dir/$conf ~/$conf
	done

	for conf in ${common_confs_in_home_config[*]}; do
		[[ -f $common_home_config_backup_dir/$conf ]] && ln -sfv $common_home_config_backup_dir/$conf ~/$conf
	done
	unset conf
}

#++++++++++++++++++++++++++++++++++++
#====pkg update check
if [[ -f ~/.cache/pkg_last_update ]]; then
	pkg_last_update=$(cat ~/.cache/pkg_last_update)
	pkg_list_backup_dir=~/Documents/os-config/home.config
	if [[ $(date +%s) -gt $((pkg_last_update + 30 * 24 * 3600)) ]]; then
		pkg_query_update &
		echo $(date +%s) >~/.cache/pkg_last_update
		case $package_manager in
		pacman)
			pacman -Qqe >$pkg_list_backup_dir/pacman.packagelist
			;;
		apt)
			dpkg --get-selections >$pkg_list_backup_dir/apt.packagelist
			;;
		brew)
			brew list >$pkg_list_backup_dir/brew.packagelist
			;;
		esac
	fi
	unset pkg_last_update pkg_list_backup_dir
else
	mkdir ~/.cache && echo $(date +%s) >~/.cache/pkg_last_update
fi

#===== ZSH configs =====
zsh_plugins=(zsh-autosuggestions zsh-syntax-highlighting)

shell_plugins() {
	if [[ $package_manager == "pacman" ]]; then
		pacman -S --noconfirm zsh starship zoxide ${zsh_plugins[@]} zsh-completions
	elif [[ $package_manager == "apt" ]]; then
		apt install -y zsh zoxide starship ${zsh_plugins[@]} zsh-completions
	elif [[ $package_manager == "brew" ]]; then
		brew install zsh starship zoxide ${zsh_plugins[@]} zsh-completions
	else
		git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_PLUGINS:-~/.zsh/plugins}/zsh-autosuggestions
		git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_PLUGINS:-~/.zsh/plugins}/zsh-syntax-highlighting
		git clone --depth 1 https://github.com/rupa && mkdir -p ~/.config/z && mv z/{z.1,z.sh} ~/.config/z/ && mv z /tmp/zsh-z-git && rm -rfv /tmp/zsh-z-git
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

# load plugins.They can be found in $ZSH_PLUGINS/*
for plugin in ${zsh_plugins[*]}; do
	[[ -d $ZSH_PLUGINS_DIR/$plugin ]] && source $ZSH_PLUGINS_DIR/$plugin/$plugin.zsh
done
unset plugin
test -d $ZSH_PLUGINS_DIR/zsh-completions && FPATH=$ZSH_PLUGINS_DIR/zsh-completions:$FPATH
unset ZSH_PLUGINS_DIR zsh_plugins

#plugins config
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=cyan,bg=bold,underline" #fg=#ff00ff,bg=cyan,bold,underline
ZSH_AUTOSUGGEST_STRATEGY=(history)                          #completion)

#z-jump: zoxide
command -v zoxide &>/dev/null && eval "$(zoxide init --cmd z zsh)"

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
autoload -Uz compinit 2>/dev/null
autoload -U select-word-style
select-word-style bash
setopt no_nomatch #no error when no match
zstyle ':completion:*:scp:*' tag-order '! users'

#---ssh-agent
function active_ssh_agent() {
	if [[ -z $(ps -eo pid,user,command | grep -w $USER | grep "ssh-agent" | grep -v grep) ]]; then
		eval $(ssh-agent -s)
		echo "export SSH_AGENT_PID=$SSH_AGENT_PID" >~/.cache/.ssh-agent.env
		echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" >>~/.cache/.ssh-agent.env
		ssh-add
	else
		[[ -f ~/.ssh-agent.env ]] && source ~/.ssh-agent.env
	fi
}

active_ssh_agent

#===== post load scripts =====
test -r ~/.shell.env.postload.sh && source ~/.shell.env.postload.sh || true
