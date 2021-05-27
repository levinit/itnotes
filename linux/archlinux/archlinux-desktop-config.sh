#!/bin/sh

#repo

echo '
[archlinuxcn]
#Server = http://repo.archlinuxcn.org/$arch
Server = https://mirrors.ustc.edu.cn/archlinuxcn/$arch
[blackarch]
SigLevel = Optional TrustAll
Server = https://mirrors.ustc.edu.cn/blackarch/$repo/os/$arch' >>/etc/pacman.conf

sed -i "s/^#Color/Color/" /etc/pacman.conf
[[ $(grep ILoveCandy /etc/pacman.conf) ]] || sed -i "/Color/ a ILoveCandy" /etc/pacman.conf
sed -i "s/^#VerbosePkgLists/VerbosePkgLists/" /etc/pacman.conf

pacman -Syy --noconfirm

pacman -S archlinuxcn-keyring --noconfirm

#zsh oh-my-zsh
pacman -S zsh oh-my-zsh-git

pacman -S pacman-contrib yay  tmux ntfs-3g exfat-utils man-pages-zh_cn --noconfirm #autojump bash-completion

# fonts && input
pacman -S --noconfirm otf-fira-code wqy-microhei noto-fonts-emoji
pacman -S --noconfirm fcitx fcitx-gtk3 fcitx-qt5 fcitx-cloudpinyin fcitx-configtool --noconfirm #adobe-source-han-sans-otc-fonts ttf-dejavu

echo "
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
" >/etc/environment

# gnome
pacman -S baobab cheese eog evince file-roller gdm gedit gnome-backgrounds gnome-calculator gnome-characters gnome-color-manager gnome-control-center gnome-disk-utility gnome-font-viewer gnome-keyring gnome-screenshot gnome-session gnome-settings-daemon gnome-shell gnome-system-monitor gnome-terminal gnome-user-share gvfs gvfs-mtp gvfs-nfs gvfs-smb mousetweaks mutter nautilus networkmanager sushi tracker tracker-miners xdg-user-dirs-gtk rygel gnome-tweaks gnome-code-assistance --noconfirm

systemctl enable gdm NetworkManager

echo -e '
XDG_DESKTOP_DIR="$HOME/Desktop"
XDG_DOWNLOAD_DIR="$HOME/Downloads"
XDG_TEMPLATES_DIR="$HOME/Templates"
XDG_PUBLICSHARE_DIR="$HOME/Public"
XDG_DOCUMENTS_DIR="$HOME/Documents"
XDG_MUSIC_DIR="$HOME/Music"
XDG_PICTURES_DIR="$HOME/Pictures"
XDG_VIDEOS_DIR="$HOME/Videos"
' >.config/user-dirs.dirs

# relevant gnome more about
pacman -S gnome-tweaks alacarte dconf-editor --noconfirm

# tools
pacman -S gpaste --noconfirm

# network
pacman -S wget axel firefox chromium proxychains openssh vinagre teamviewer darkttpd filezilla aria2 uget --noconfirm

# communication
pacman -S geary telegram-desktop --noconfirm

# photo/music/video
pacman -S shotwell gimp rhythmbox spotify totem gst-plugins-ugly gst-libav grilo-plugins shotwell gimp gimp-help-zh_cn gimp-plugin-fblur peek --noconfirm

# software manager
pacman -S gnome-software gnome-software-packagekit-plugin gnome-packagekit --noconfirm

# themes
#pacman -S arc-gtk-theme materia-gtk-theme numix-circle-icon-theme-git papirus-icon-theme capitaine-cursors --noconfirm
# yay -S xcursor-numix

# yay -S canta-gtk-theme-git

# shell extensions
pacman -S gnome-shell-extensions gnome-shell-extension-topicons-plus-git gnome-shell-extension-dash-to-dock-git --noconfirm

# arhive
pacman -S expect --noconfirm
pacman -S p7zip unrar --noconfirm
expect -c "
  spawn pacman -S unzip-iconv
  expect "y/N"
  send y\r
  expect "Y/n"
  send y\r
  expect eof
"

# trans code
pacman -S convmv --noconfirm

# coding
pacman -S typora gedit gedit-plugins dconf-editor git gitg code nodejs npm python-pip meld --noconfirm

# office
pacman -S archlinuxcn/ttf-wps-fonts archlinuxcn/wps-office-mui-zh-cn archlinuxcn/wps-office-mime-cn archlinuxcn/wps-office-cn
 --noconfirm


# neofetch
pacman -S neofetch --noconfirm
neofetch

function plasma() {
  pacman -S --noconfirm plasma-meta
  #for kde discover (software center)
  pacman -S --noconfirm packagekit-qt5

  pacman -S --noconfirm powerdevil konsole dolphin

  #wayland
  pacman -S --noconfirm plasma-wayland-session

  systemctl enable sddm

}
