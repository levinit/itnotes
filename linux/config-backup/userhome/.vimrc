
"load other vim script file exapmle: source /path/to/file

"=======VIM base settings=======
"leader用于自定义快捷键，默认值为\
"set mapleader=\

"tab宽度
set tabstop=2
"格式化时制表符占用空格数
set shiftwidth=2
"将制表符扩展为空格
set expandtab
"智能tab
set smarttab

"自动缩进
set autoindent
"智能缩进
set smartindent
"C语言自动缩进
set cindent
"根据类型格式缩进
filetype indent on

"允许鼠标操作
" 操作系统剪切板方法1： 鼠标选择的复制粘贴，按住shift并使用鼠标选中内容后即会复制，在其他可输入地方使用鼠标中间粘贴(无中键可同时按下鼠标左右键)
" 操作系统剪切板方法2 （适用性最佳）：按下shift或ctrl+shift并使用鼠标选中内容后即会复制，在其他可输入地方使用普通方式粘贴即可。
"    shift键表示vim把鼠标的活动交给X，单shift针对整个window, 而加ctrl针对整个buffer
set mouse=a

"让y p等可直接操作+ * 寄存器（系统剪切板）而无需使用"+y +p等命令
"需要支持+clipboard 查看vim --version|grep +clipboard
"方法：
" visual模式选中内容后按下y复制(开启了mouse也可使用鼠标选中），在其他可输入地方使用普通放置粘贴即可。
set clipboard^=unnamed,unnamedplus
"unamed +寄存器，对应系统剪贴板，*寄存器代表当前选择区

"重新打开文件时光标定位到上次关闭时的位置（cursor position to last position when reopen file）
if has("autocmd")
    au BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif
endif

"拼写
"set spell
"语法高亮 syntax highlight
syntax enable

"折叠方式 folding style
"根据语法syntax|手动manual|根据表达式epxr|根据未更改内容diff|根据标志marker|根据缩进indent
set foldmethod=syntax
"启动 vim 时关闭折叠 folding when vim launch
set nofoldenable
"设置键盘映射，通过空格设置折叠 folding keymap
"nnoremap <space> @=((foldclosed(line('.')) < 0) ? 'zc' : 'zo')<CR>

"浅色显示当前列 cursorcolumn cuc
"autocmd InsertLeave * set cursorcolumn
set cursorcolumn
"高亮当前行 cursorline 缩写 cul
autocmd InsertEnter * set cursorline
"当前行添加下划线
set cursorline
"设置高亮行的配色 cterm-原生vim ctermfg和cterbg终端vim guifg和guibg是gui的vim  取值为NONE表示自动
"颜色可搭配light或dark，颜色：red（红），white（白），black（黑），green（绿），yellow（黄），blue（蓝），purple（紫），gray（灰），brown（棕），tan(褐色)，cyan(青色)
"highlight CursorLine   cterm=NONE ctermbg=NONE ctermfg=NONE guibg=NONE guifg=NONE
"highlight CursorColumn   cterm=NONE ctermbg=lightyellow  ctermfg=red guibg=NONE guifg=NONE
"高亮选中的区块visual block
highlight Visual ctermbg=white ctermfg=brown gui=none

"theme
"colorscheme desert

"文件类型识别
filetype on
"根据文件类型开启相关插件
filetype plugin on

"括号匹配
set showmatch

"显示行号
set number
map <C-l> <Esc> :set invnumber<CR>

"历史条目数量
set history=999
"没有保存或文件只读时弹出确认
set confirm
set backspace=2  "indent,eol,start

"自动读取(自动检测外部更改)
set autoread
"自动写入(自动保存)
"禁止生成临时文件
set nobackup

"魔术 (设置元字符要加反斜杠进行转义)
"magic(\m模式)除了 $ . * ^ 之外其他元字符都要加反斜杠
"nomagic(\M模式) 除了 $ ^ 之外其他元字符都要加反斜杠
"\v （即 very magic 之意）：任何元字符都不用加反斜杠
"\V （即 very nomagic 之意）：任何元字符都必须加反斜杠
set magic

"启动显示状态行
set laststatus=1
"状态栏信息
"set statusline=[FORMAT=%{&ff}]\ [TYPE=%Y]\ [ASCII=\%03.3b]\ [HEX=\%02.2B]\ [POS=%04l,%04v][%p%%]

"显示标尺 在右下角显示光标位置
set ruler
"光标移动到buffer的顶部和底部时保持n行距离
set scrolloff=3

"输入搜索内容时就显示搜索结果
set incsearch
"高亮查找的匹配结果
set hlsearch
"搜索时忽略大小写 但在有一个或以上大写字母时仍保持对大小写敏感
set ignorecase smartcase
set gdefault

"新建文件的编码格式
set fileencoding=utf-8
"打开文件后可识别的编码格式
set fileencodings=utf-8,gb18030,gb2312,gbk,big5

"背景色
"set background=dark
"颜色 256真彩色
set t_Co=256

"行补全
"autocmd InsertEnter * let save_cwd = getcwd() | set autochdir
"文件名补全
"autocmd InsertLeave * set noautochdir | execute 'cd' fnameescape(save_cwd)
"ctrl x ctrl f

"omni补全
set omnifunc=syntaxcomplete#Complete
if has("autocmd") && exists("+omnifunc")
autocmd Filetype *
\ if &omnifunc == "" |
\ setlocal omnifunc=syntaxcomplete#Complete |
\ endif
endif

"===vim-plug 插件管理==="
"show plugin path :set runtimepath?
"set runtimepath+=~/.local/share/nvim/site or set rpt+=/path/to/
"pacman -S vim-plug
"or
"curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
"neovim
"sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

if !filereadable($HOME . "/.vim/autoload/plug.vim")
  finish "vim-plug not found, stop loading"
endif

call plug#begin('~/.vim/plugged')

"~~~插件列表 plugin list~~~

"开屏界面
Plug 'mhinz/vim-startify'

"主题
Plug 'ku1ik/vim-monokai'
Plug 'arcticicestudio/nord-vim'
Plug 'NLKNguyen/papercolor-theme'

"底部状态栏
Plug 'vim-airline/vim-airline'
"Plug 'vim-airline/vim-airline-themes'

"缩进线
Plug 'yggdroot/indentLine'

"成对编辑
"ds(delete arrounding) cs(change arrounding) ys(you add a surrounding)
Plug 'tpope/vim-surround'

"目录树
Plug 'scrooloose/nerdtree'

"模糊搜索
"set rtp+=~/.fzf/bin/fzf
"set rtp+=/usr/local/opt/fzf
"Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
"or Plug '/usr/local/opt/fz'
"Plug 'sharkdp/fd', { 'dir': '~/.fd', 'do': './install --all' }

"快速移动
Plug 'easymotion/vim-easymotion'

"git工具
Plug 'tpope/vim-fugitive'

"语法检查
Plug 'w0rp/ale'

"代码格式化
Plug 'sbdchd/neoformat'

"自动补全 deoplete
set pyxversion=3
"vim: pacman -S python-pynvim  或 pip install pynvim
if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif
 
"自动补全 copilot
"Plug 'github/copilot.vim'

call plug#end()
"===插件列表结束===

"===插件设置===
"--启用配色主题
"built-in colorscheme : <install dir>/share/vim/vim<ver>/colors
colorscheme monokai "nord

"---paperColor light scheme
"set background=light
"colorscheme PaperColor

"--airline
let g:airline#extensions#tabline#enabled = 1
"let g:airline#extensions#tabline#left_alt_sep = '|'  "default is |

"--airline them
"install powerline fonts: git clone https://github.com/powerline/fonts.git ~/.fonts && sh ~/.fonts/install.sh
"let g:airline_powerline_fonts = 1  "powerline 
"let g:airline_them='soda'

"--indentLine
let g:indentLine_char_list = ['¦', '┆', '┊']

"--easymotion
" <Leader>f{char} to move to {char}
map  <Leader>f <Plug>(easymotion-bd-f)
nmap <Leader>f <Plug>(easymotion-overwin-f)

" s{char}{char} to move to {char}{char}
nmap s <Plug>(easymotion-overwin-f2)

" Move to line
map <Leader>L <Plug>(easymotion-bd-jk)
nmap <Leader>L <Plug>(easymotion-overwin-line)

" Move to word
nmap  <Leader>w <Plug>(easymotion-bd-w)
nmap <Leader>w <Plug>(easymotion-overwin-w)

"--nerdtree
"autocmd StdinReadPre * let s:std_in=1
"autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
"ctrl+n打开侧边目录栏
map <C-n> :NERDTreeToggle<CR>
map <C-f> :NERDTreeFind<CR>
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
let NERDTreeQuitOnOpen=1
let NERDTreeShowBookmarks=1

"--fzf
nmap <C-p> :Files<CR>
nmap <C-e> :Buffers<CR>
let g:fzf_action = { 'ctrl-e': 'edit' }

"--ale"
let g:ale_set_highlights = 0
"自定义error和warning图标
let g:ale_sign_error = '✗'
let g:ale_sign_warning = '⚡'
"在vim自带的状态栏中整合ale
let g:ale_statusline_format = ['✗ %d', '⚡ %d', '✔ OK']
"显示Linter名称,出错或警告等相关信息
let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
"普通模式下，sp前往上一个错误或警告，sn前往下一个错误或警告
nmap sp <Plug>(ale_previous_wrap)
nmap sn <Plug>(ale_next_wrap)
"<Leader>s触发/关闭语法检查
nmap <Leader>s :ALEToggle<CR>
"<Leader>d查看错误或警告的详细信息
nmap <Leader>d :ALEDetail<CR>

"--deoplete
let g:deoplete#enable_at_startup = 1

"--neoformat
augroup fmt
  autocmd!
  autocmd BufWritePre * undojoin | Neoformat
augroup END

map <C-i> :Neoformat<CR>
