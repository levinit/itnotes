# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

PS1="\[\e[37;1m\][\[\e[31;1m\]\u \[\e[36;1m\]@ \[\e[33;1m\]\h \[\e[35m\]\w\[\e[37;1m\]]\[\e[0m\] \[\e[1m\]\\$\[\e[0m\] "

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

[[ -r ~/.shell.env.postload.sh ]] && . ~/.shell.env.postload.sh