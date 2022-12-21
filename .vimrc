set undodir=~/.vim/undodir
set undofile
set incsearch
set hlsearch            " Enable highlight search
set syntax=on

set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab

set splitbelow          " Always split below"
set termwinsize=12x0    " Set terminal size
set mouse=a             " Enable mouse drag on window splits

set relativenumber
set noerrorbells
set autoindent
set smartindent
set nowrap
set smartcase
set nu 

set laststatus=2
set noshowmode

set colorcolumn=80
set clipboard=unnamedplus

" Install vim-plug if not found
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
endif
" Run PlugInstall if there are missing plugins
autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \| PlugInstall --sync | source $MYVIMRC
  \| endif

call plug#begin('~/.vim/plugged')
"    Plug 'gkeep/iceberg.vim'
"    Plug 'gkeep/iceberg-dark'
    Plug 'cocopon/iceberg.vim'
    Plug 'itchyny/lightline.vim'
call plug#end()

" You might have to force true color when using regular vim inside tmux as the
" colorscheme can appear to be grayscale with "termguicolors" option enabled.
if !has('gui_running') && &term =~ '^\%(screen\|tmux\)'
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
endif

syntax on
set termguicolors

set background=dark     " Set background 
colorscheme iceberg     " Set color scheme

let g:lightline = { 'colorscheme': 'iceberg' }

nmap <leader>l :set list!<CR>
set listchars=tab:▸\ ,eol:¬
set list
