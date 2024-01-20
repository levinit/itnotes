# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# Enable the subsequent settings only in interactive sessions
case $- in
*i*)
  [[ $onlybash == true ]] && return
  [[ -n $@ ]] && return

  # use zsh if available in interactive sessions
  if [[ -d /share/apps/zsh ]]; then
    export PATH=/share/apps/zsh/bin:$PATH
    export LD_LIBRARY_PATH=/share/apps/zsh/lib:$LD_LIBRARY_PATH
    export MANPATH=/share/apps/zsh/share/man:$MANPATH
    export SHELL=/share/apps/zsh/bin/zsh

    export ZSH_DISABLE_COMPFIX=true
    export DISABLE_AUTO_UPDATE=true

    export ZSH=/share/apps/zsh/oh-my-zsh
    export ZSH_CUSTOM=/share/apps/zsh/oh-my-zsh/custom

    exec /share/apps/zsh/bin/zsh
  fi
  ;;
*) return ;;
esac
