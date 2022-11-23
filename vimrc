syntax on 


set noerrorbells
set tabstop=4 softtabstop=4
set shiftwidth=4
set expandtab
set smartindent
set nu
set nowrap
set smartcase
set noswapfile
set nobackup
set undodir=~/.vim/undodir
set undofile
set incsearch

set foldmethod=syntax

"set the makeprg of verilog files.. to use with VerilogErrorFormat command
"autocmd BufNewFile,BufRead *.v setlocal makeprg=iverilog\ -o\ %:r\ %
autocmd BufNewFile,BufRead *.v setlocal makeprg=iverilog\ -o\ %:r.del\ %

autocmd BufRead *.py set makeprg=python\ -c\ \"import\ py_compile,sys;\ sys.stderr=sys.stdout;\ py_compile.compile(r'%')\"
autocmd BufRead *.py set efm=%C\ %.%#,%A\ \ File\ \"%f\"\\,\ line\ %l%.%#,%Z%[%^\ ]%\\@=%m

set colorcolumn=80
"highlight ColorColumn ctermbg=0 guibg=lightgrey


call plug#begin('~/.vim/plugged')
Plug 'morhetz/gruvbox'
Plug 'jremmen/vim-ripgrep'
Plug 'leafgarland/typescript-vim'
Plug 'vim-utils/vim-man'
Plug 'lyuts/vim-rtags'
Plug 'preservim/nerdtree'
Plug 'mbbill/undotree'
"Plug 'Valloric/YouCompleteMe', { 'do': './install.py' }
"Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'vhda/verilog_systemverilog.vim'
Plug 'nachumk/systemverilog.vim'
Plug 'amal-khailtash/vim-xdc-syntax'
Plug 'amal-khailtash/vim-xtcl-syntax'
call plug#end()


colorscheme gruvbox
set background=dark

"let g:ycm_autoclose_preview_window_after_insertion = 1
"let g:ycm_autoclose_preview_window_after_completion = 1

noremap <SPACE> <Nop>
let mapleader = " "

nnoremap <leader>i :VerilogFollowInstance<CR>
nnoremap <leader>I :VerilogFollowPort<CR>
nnoremap <leader>h :wincmd h<CR>
nnoremap <leader>j :wincmd j<CR>
nnoremap <leader>k :wincmd k<CR>
nnoremap <leader>l :wincmd l<CR>
nnoremap <leader>u :UndotreeShow<CR>
"nnoremap <leader>pv :wincmd v<bar> :Ex <bar> :vertical resize 30<CR>
nnoremap <leader>pv :NERDTree <bar> :vertical resize 20<CR>
nnoremap <silent> <Leader>+ :vertical resize +5<CR>
nnoremap <silent> <Leader>- :vertical resize -5<CR>

"nnoremap <silent> <Leader>gd :YcmCompleter GoTo<CR>
"nnoremap <silent> <Leader>gf :YcmCompleter FixIt<CR>
nnoremap <leader>. @@

