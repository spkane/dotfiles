" Sean Kane

" Keymaps --------------------------------------------------------------------
let mapleader=","      " change the mapleader from \ to ,
set timeoutlen=500     " lower leader+command timeout
" use jk for escape
inoremap jk <esc>
" turn off search highlight
nnoremap <leader><space> :nohlsearch<CR>
nnoremap <F2> :set invpaste paste?<CR>
set pastetoggle=<F2>   " Key to switch paste mode on/off
set showmode

" General --------------------------------------------------------------------
syntax on                       " enable code syntax colorization
set background=dark             " Tell vim that we have a dark background
set wildmenu                    " visual autocomplete for command menu
set wildmode=list:longest
"set completeopt=longest,menuone
set ruler                       " statusbar ruler enabled
set nocompatible                    " Forget compatibility with Vi. Who cares.
set list listchars=tab:\|_,trail:·  " Show some invisible characters
set backspace=indent,eol,start      " backspace through everything with insert
set encoding=utf-8                  " Set default encoding to UTF-8
set guifont=Source\ Code\ Variable\ Normal\ 18  " GUI Font
set showcmd                     " Show command in bottom right of screen
set laststatus=2                " Always show the status line
set nonumber                    " Hide line numbers
set showmatch                   " Show matching brackets
"set mouse=a                     " enable mouse support
set clipboard=unnamed           " Yank into Mac clipboard

" Line wrapping --------------------------------------------------------------
"set wrap
"set textwidth=79
"set formatoptions=qrn1
"set formatoptions+=w

" Filetypes ------------------------------------------------------------------
filetype on
filetype plugin on
filetype indent on
syntax on

" Indentation ----------------------------------------------------------------
set expandtab
set shiftwidth=4
set tabstop=4
set autoindent
filetype indent on      " load filetype-specific indent files
" DO NOT set smartindent - interferes with file type based indentation
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
let g:indentLine_char = '⦙'

" Searching ------------------------------------------------------------------
set incsearch           " search as characters are entered
set hlsearch            " highlight matches
set ignorecase
set smartcase
set rtp+=/usr/local/opt/fzf

" Safety ---------------------------------------------------------------------
set backup
set backupdir=~/.vim/tmp,~/.tmp,~/tmp,/var/tmp,/tmp " Backup files
set backupskip=/tmp/*,/private/tmp/*
set directory=~/.vim/tmp,~/.tmp,~/tmp,/var/tmp,/tmp " Swap files
set writebackup
set autowrite        " Write the old file out when switching between files.


