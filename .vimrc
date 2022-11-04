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

set colorcolumn=80
highlight ColorColumn ctermbg=0 guibg=lightgrey

set laststatus=2
set noshowmode

set background=dark     " Set background 
colorscheme iceberg     " Set color scheme

let g:lightline = {
	        \ 'colorscheme': 'iceberg',
        \ }

nmap <leader>l :set list!<CR>
set listchars=tab:▸\ ,eol:¬
set list

" Set tabstop, softtabstop and shiftwidth to the same value
command! -nargs=* Stab call Stab()
function! Stab()
  let l:tabstop = 1 * input('set tabstop = softtabstop = shiftwidth = ')
  if l:tabstop > 0
    let &l:sts = l:tabstop
    let &l:ts = l:tabstop
    let &l:sw = l:tabstop
  endif
  call SummarizeTabs()
endfunction

function! SummarizeTabs()
  try
    echohl ModeMsg
    echon 'tabstop='.&l:ts
    echon ' shiftwidth='.&l:sw
    echon ' softtabstop='.&l:sts
    if &l:et
      echon ' expandtab'
    else
      echon ' noexpandtab'
    endif
  finally
    echohl None
  endtry
endfunction
