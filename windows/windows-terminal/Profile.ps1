# $HOME/Documents/PowerShell/Profile.ps1

# if your powershel version is lower than 6.0, you need to upgrade it first (Recommended):
#     winget install Microsoft.PowerShell
# and then and open the new version of powershell
# you can also set the new version of powershell as the default shell.

# ===== Modules

Invoke-Expression (&starship init powershell)

#====== Aliases
function ps_plugin_install { 
    winget install --id Starship.Starship

    Install-Module -Name ZLocation -Scope CurrentUser -Force

    echo "Please restart your terminal to see the changes, or run . $PROFILE to reload the profile"

    echo "----"
    echo "a nerd font is required for the theme to work properly, you can download it from: https://www.nerdfonts.com/font-downloads"
    echo ""
    echo "after installing the font, you need to set it as the default font in your terminal"

    echo "!!! use the gruvbox-rainbow theme. To get more preset themes by: starship preset list"
    starship preset gruvbox-rainbow -o $HOME/.config/starship.toml
 }

#nvim nvchad: git clone https://github.com/NvChad/starter $ENV:USERPROFILE\AppData\Local\nvim && nvim
# ===== Alias
Set-Alias vim nvim

# ====== Bindkeys
#ctrl a to move to the beginning of the line
Set-PSReadLineKeyHandler -Chord "Ctrl+a" -Function BeginningOfLine
#ctrl e to move to the end of the line
Set-PSReadLineKeyHandler -Chord "Ctrl+e" -Function EndOfLine
#ctrl k to delete from cursor to the end of the line
Set-PSReadLineKeyHandler -Chord "Ctrl+k" -Function KillLine
#ctrl u to delete from cursor to the beginning of the line
Set-PSReadLineKeyHandler -Chord "Ctrl+u" -Function BackwardKillLine

#ctrl d to exit the shell
Set-PSReadLineKeyHandler -Chord "Ctrl+d" -Function ViExit

# some PSReadLine default key bindings
# #使用历史命令记录来应用自动补全
# Set-PSReadLineOption -PredictionSource History

# # 每次回溯输入历史，光标定位于输入内容末尾
# Set-PSReadLineOption -HistorySearchCursorMovesToEnd

# # 设置 Tab 为补全的快捷键
# Set-PSReadLineKeyHandler -Key "Tab" -Function MenuComplete

# # 设置 Ctrl + Z 为撤销
# Set-PSReadLineKeyHandler -Key "Ctrl+z" -Function Undo

# # 设置向上键为后向搜索历史记录
# Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward

# # 设置向下键为前向搜索历史纪录
# Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward