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

"重置clipboard，让y p等可直接操作"+寄存器（系统剪切板）而无需使用"+y "+p等命令
"需要支持+clipboard 查看vim --version|grep +clipboard
set clipboard^=unnamed

"语法高亮 syntax highlight
syntax on
syntax enable
"代码折叠 code folding
set foldenable
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
"高亮当前行 cursorline cul
autocmd InsertEnter * set cursorline
set cursorline
"设置高亮行的配色 cterm-原生vim ctermfg和cterbg终端vim guifg和guibg是gui的vim  取值为NONE表示自动
"颜色可搭配light或dark，颜色：red（红），white（白），black（黑），green（绿），yellow（黄），blue（蓝），purple（紫），gray（灰），brown（棕），tan(褐色)，cyan(青色)
"highlight CursorLine   cterm=NONE ctermbg=NONE ctermfg=NONE guibg=NONE guifg=NONE
"highlight CursorColumn   cterm=NONE ctermbg=lightyellow  ctermfg=red guibg=NONE guifg=NONE
"高亮选中的区块visual block
highlight Visual ctermbg=white ctermfg=brown gui=none

"文件类型识别
filetype on
"根据文件类型开启相关插件
filetype plugin on

"括号匹配
set showmatch
"显示行号
set number

"历史条目数量
set history=999
"没有保存或文件只读时弹出确认
set confirm
set backspace=2

"自动读取(自动检测外部更改)
set autoread
"自动写入(自动保存)
"禁止生成临时文件
set nobackup
"允许鼠标操作
set mouse=a

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
"显示输入的命令
set showcmd
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

"去除vi的一致性
set nocompatible

"新建文件的编码格式
set fileencoding=utf-8
"打开文件后可识别的编码格式
set fileencodings=utf-8,gb18030,gb2312,gbk,big5

"背景色
"set background=dark
"颜色 256真彩色
set t_Co=256

"===vim-plug 插件管理==="
"pacman -S vim-plug
"curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

call plug#begin('~/.vim/plugged')
"~~~插件列表~~~

"开屏界面
Plug 'mhinz/vim-startify'

"主题
Plug 'w0ng/vim-hybrid'
Plug 'tomasr/molokai'

"底部状态栏
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

"缩进线
Plug 'yggdroot/indentLine'

"成对编辑
"ds(delete arrounding) cs(change arrounding) ys(you add a surrounding)
Plug 'tpope/vim-surround'

"目录树
Plug 'scrooloose/nerdtree'

"模糊搜索
"Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
"Plug 'sharkdp/fd', { 'dir': '~/.fd', 'do': './install --all' }
"set rtp+=~/.fzf/bin/fzf
set rtp+=/usr/local/opt/fzf
Plug 'junegunn/fzf.vim'

"快速移动
Plug 'easymotion/vim-easymotion'

"git工具
Plug 'tpope/vim-fugitive'

"快速注释
"注释gc 取消注释gcgc
Plug 'tpope/vim-commentary'

"语法检查
Plug 'w0rp/ale'

"代码格式化
Plug 'sbdchd/neoformat'

"代码补全
"pacman -S python-pynvim " pip install pynvim 
"if has('nvim')
"  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
"else
"  Plug 'Shougo/deoplete.nvim'
"  Plug 'roxma/nvim-yarp'
"  Plug 'roxma/vim-hug-neovim-rpc'
"endif

"语言助手
"python
Plug 'python-mode/python-mode', { 'for': 'python', 'branch': 'develop' }

call plug#end()
"===插件列表结束===

"===插件设置===
"--启用配色主题
"colorscheme hybrid
"--molokai
"let g:molokai_original = 1
"let g:rehash256 = 1

"--vim-startify

"--airline
"-need install powerline fonts:
"- git clone https://github.com/powerline/fonts.git ~/.fonts
"- sh ~/.fonts/install.sh
"let g:airline_powerline_fonts = 1  " 支持 powerline 字体
let g:airline#extensions#tabline#enabled = 1 "显示窗口tab和buffer

"--indentLine
let g:indentLine_char_list = ['¦', '┆', '┊']

"--easymotion
"按下ss
nmap ss <Plug>(easymotion-s2)

"--nerdtree
"autocmd StdinReadPre * let s:std_in=1
"autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
"ctrl+n打开侧边目录栏
map <C-n> :NERDTreeToggle<CR>
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
let NERDTreeQuitOnOpen=1
let NERDTreeShowBookmarks=1

"--ctrlp
map <C-p> :Files<CR> "文件搜索
map <C-f> :Rg<CR> "文本搜索

"--commentary

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
map <C-S-i> :Neoformat<CR>
