" ex: tabstop=4 shiftwidth=4 softtabstop=4 expandtab

" vim-polyglot tries to be smart with indent and fails miserably
"let g:polyglot_disabled = ['autoindent']
"autocmd BufEnter * set indentexpr=

" Fix for an odd bug that prints some garbage when using it on iTerm2
set t_RV=

set nocompatible

call plug#begin()

Plug 'cohama/lexima.vim'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'dense-analysis/ale'
Plug 'fatih/vim-go'
Plug 'mhinz/vim-startify'
Plug 'neoclide/coc.nvim', { 'branch': 'release' }
Plug 'preservim/nerdcommenter'
Plug 'rafi/awesome-vim-colorschemes'
Plug 'ryanoasis/vim-devicons'
Plug 'scrooloose/nerdtree'
Plug 'sheerun/vim-polyglot'
Plug 'shime/vim-livedown'
Plug 'stsewd/sphinx.nvim'
Plug 'tpope/vim-fugitive'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'vim-scripts/taglist.vim'

call plug#end()

" Enable syntax
syntax on

" Enable filetype plugins
filetype plugin indent on

set autoread			" autom. read file when changed outside of Vim
set background=dark		" set background
if !has('nvim')
    set clipboard=autoselect	" yank to clipboard
endif
set colorcolumn=80		" Show vertical line at column 80
set cursorline			" Highlight current line
set encoding=utf8		" set default encoding to utf8
set hlsearch			" highlight search pattern matches
set ignorecase			" ignore case in search patterns
set incsearch			" do incremental searching
set lazyredraw			" don't redraw while executing macros
set magic			" for regex turn magic on
set modeline			" Allow to define options inside file
set mps+=<:>			" Make % work with <>
set noerrorbells		" ring the bell for error messages
set nostartofline		" commands move cursor to first blank in line
set noshowmode			" Do not show current mode on status line
set novisualbell		" use visual bell instead of beeping
set number			" show line number
set ruler			" show the cursor position all the time
set shortmess=a			" no 'Hit ENTER to continue'
set showcmd			" display incomplete commands
set showmatch			" briefly jump to matching bracket if insert one
set smartcase			" no ignore case when pattern has uppercase
set smartindent			" do smart indenting
set t_Co=256			" use 256 colors
set mouse=v			" Enable mouse only in visual mode

if !exists("g:os")
    let g:os = substitute(system('uname'), '\n', '', '')
endif

" Always display statusline
set laststatus=2
let g:airline#extensions#tabline#enabled=1
let g:airline_powerline_fonts = 1
let g:airline_statusline_ontop=0
let g:airline_theme='base16_twilight'
let g:airline#extensions#tabline#formatter = 'default'

" Set extra options when running in GUI mode
if has("gui_running")
    set guioptions+=a
    set guioptions-=e
    set guioptions-=L
    set guifont=MesloLGMDZ\ Nerd\ Font\ Mono:h16
endif

" Navigate through buffers
nnoremap <M-Right> :bn<cr>
nnoremap <M-Left> :bp<cr>
nnoremap <c-x> :bp\|bd #<cr>

" Define colorscheme
colorscheme gruvbox

" Configure taglist
let Tlist_Exit_OnlyWindow = 1
let Tlist_GainFocus_On_ToggleOpen = 1
let Tlist_WinWidth = 60
let Tlist_Close_On_Select = 1
let Tlist_Sort_Type = 'name'
let Tlist_Display_Prototype = 1
set tags=.git/tags

" Add specific params for specific filetypes
au BufNewFile,BufRead *.inc set filetype=php
au BufNewFile,BufRead *.php,*.inc,*.c call Load_FreeBSD_Style()
au BufNewFile,BufRead *.c,*.h set cindent cinoptions=(0 tabstop=8 shiftwidth=8 softtabstop=8 noexpandtab
au BufNewFile,BufRead dpinger.c set tabstop=4 shiftwidth=4 softtabstop=4 expandtab
au BufNewFile,BufRead *.hcl set tabstop=2 shiftwidth=2 softtabstop=2 expandtab
au BufNewFile,BufRead *.cli,*.yang set tabstop=8 softtabstop=4 shiftwidth=4
au BufNewFile,BufRead *.ex set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
au BufNewFile,BufRead *.sh set tabstop=8 softtabstop=8 shiftwidth=8 noexpandtab nocindent smartindent

" List trailing chars
set list
set listchars=tab:▸\ ,trail:·,precedes:…,extends:…,nbsp:‗
map <c-k>i :set invlist<cr>
map <c-k>n :set invnumber<cr>

" Map a key for Nerdtree toggle
map <C-n> :NERDTreeToggle<cr>

" Insert current filename on cursor position
inoremap \fn <C-R>=expand("%:t")<CR>

" This unsets the "last search pattern" register by hitting return
nnoremap <CR> :noh<CR><CR>

" Make CtrlP start searching on project's root dir
let g:ctrlp_working_path_mode = 'ra'
" Other CtrlP config items
let g:ctrlp_custom_ignore = '\v[\/]\.(swp|zip)$'
let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files -co --exclude-standard']
let g:ctrlp_show_hidden = 1

let g:NERDSpaceDelims = 1
let g:NERDDefaultAlign = 'left'
map cc <Plug>NERDCommenterInvert

let g:ale_linters = {'python': ['flake8', 'pylint'], 'javascript': ['eslint']}
let g:ale_completion_enabled = 0
let g:ale_fixers = {}
let g:ale_fixers.python = ['black']
let g:ale_fix_on_save = 1

" Uncomment the following to have Vim jump to the last position when
" reopening a file
if has("autocmd")
    au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
        \| exe "normal! g'\"" | endif
endif

function! Load_FreeBSD_Style()
    if filereadable(expand("~/work/freebsd/head/tools/tools/editing/freebsd.vim"))
        source ~/work/freebsd/head/tools/tools/editing/freebsd.vim
        call FreeBSD_Style()
    elseif filereadable(expand("~/.vim/freebsd.vim"))
        source ~/.vim/freebsd.vim
        call FreeBSD_Style()
    endif
endfun

" Preferred indent rules
set tabstop=8 shiftwidth=8 softtabstop=8 noexpandtab

" Insert sponsored by netgate
map ,p CRubicon Communications, LLC ("Netgate")<ESC>

nmap gm :LivedownToggle<CR>

source ~/.vim/coc.vimrc
