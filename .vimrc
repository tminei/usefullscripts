syntax on
set number
set hls
set wrap
set nocp
set scrolloff=3
set nocompatible
set hidden
set numberwidth=4
set mouse=a
set mousehide
set showcmd
set mps+=<:>
set showmatch
set autoread
set t_Co=256
set confirm
autocmd! bufwritepost $MYVIMRC source $MYVIMRC
set noruler
set laststatus=2
hi StatusLine gui=reverse cterm=reverse
color desert
set listchars=tab:··,trail:-
set list
set tabstop=4
set shiftwidth=4
set smarttab
set et
set ai
hi StatusLine ctermfg=Gray
set cin
set showmatch
set hlsearch
set incsearch
set ignorecase
set lz
highlight SpellBad ctermfg=Black ctermbg=Red
au BufWinLeave *.* silent mkview
au BufWinEnter *.* silent loadview
set backspace=indent,eol,start
set sessionoptions=curdir,buffers,tabpages
set statusline=%F%m%r%h%w\ [%{&fileformat},%{&encoding}\]\%=%03v\ %l:%L\ %03p%%
set clipboard=unnamed
set backup
set title
set history=128
set undolevels=2048
set whichwrap=b,<,>,[,],l,h
let c_syntax_for_h=""
set ignorecase
set smartcase
set nohlsearch
set incsearch
autocmd FileType python set omnifunc=pythoncomplete#Complete
autocmd FileType tt2html set omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript set omnifunc=javascriptcomplete#CompleteJS
autocmd FileType html set omnifunc=htmlcomplete#CompleteTags
autocmd FileType css set omnifunc=csscomplete#CompleteCSS
autocmd FileType xml set omnifunc=xmlcomplete#CompleteTags
autocmd FileType php set omnifunc=phpcomplete#CompletePHP
autocmd FileType c set omnifunc=ccomplete#Complete

