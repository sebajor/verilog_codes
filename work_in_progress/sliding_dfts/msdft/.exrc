if &cp | set nocp | endif
noremap  rd :call rtags#Diagnostics()
noremap  rc :call rtags#FindSubClasses()
noremap  rC :call rtags#FindSuperClasses()
noremap  rh :call rtags#ShowHierarchy()
noremap  rb :call rtags#JumpBack()
noremap  rv :call rtags#FindVirtuals()
noremap  rw :call rtags#RenameSymbolUnderCursor()
noremap  rl :call rtags#ProjectList()
noremap  rr :call rtags#ReindexFile()
noremap  rs :call rtags#FindSymbols(input("Pattern? ", "", "customlist,rtags#CompleteSymbols"))
noremap  rn :call rtags#FindRefsByName(input("Pattern? ", "", "customlist,rtags#CompleteSymbols"))
noremap  rF :call rtags#FindRefsCallTree()
noremap  rf :call rtags#FindRefs()
noremap  rp :call rtags#JumpToParent()
noremap  rT :call rtags#JumpTo(g:NEW_TAB)
noremap  rV :call rtags#JumpTo(g:V_SPLIT)
noremap  rS :call rtags#JumpTo(g:H_SPLIT)
noremap  rJ :call rtags#JumpTo(g:SAME_WINDOW, { '--declaration-only' : '' })
noremap  rj :call rtags#JumpTo(g:SAME_WINDOW)
noremap  ri :call rtags#SymbolInfo()
nnoremap  . @@
nnoremap <silent>  - :vertical resize -5
nnoremap <silent>  + :vertical resize +5
nnoremap  pv :NERDTree | :vertical resize 20
nnoremap  u :UndotreeShow
nnoremap  l :wincmd l
nnoremap  k :wincmd k
nnoremap  j :wincmd j
nnoremap  h :wincmd h
nnoremap  I :VerilogFollowPort
nnoremap  i :VerilogFollowInstance
let s:cpo_save=&cpo
set cpo&vim
noremap   <Nop>
vmap gx <Plug>NetrwBrowseXVis
nmap gx <Plug>NetrwBrowseX
vnoremap <silent> <Plug>NetrwBrowseXVis :call netrw#BrowseXVis()
nnoremap <silent> <Plug>NetrwBrowseX :call netrw#BrowseX(expand((exists("g:netrw_gx")? g:netrw_gx : '<cfile>')),netrw#CheckIfRemote())
nnoremap <silent> <Plug>(Tman) :call man#get_page_from_cword('tab',        v:count)
nnoremap <silent> <Plug>(Vman) :call man#get_page_from_cword('vertical',   v:count)
nnoremap <silent> <Plug>(Sman) :call man#get_page_from_cword('horizontal', v:count)
nnoremap <silent> <Plug>(Man) :call man#get_page_from_cword('horizontal', v:count)
let &cpo=s:cpo_save
unlet s:cpo_save
set background=dark
set backspace=indent,eol,start
set completefunc=RtagsCompleteFunc
set expandtab
set fileencodings=ucs-bom,utf-8,default,latin1
set helplang=en
set incsearch
set nomodeline
set printoptions=paper:letter
set ruler
set runtimepath=~/.vim,~/.vim/plugged/gruvbox,~/.vim/plugged/vim-ripgrep,~/.vim/plugged/typescript-vim,~/.vim/plugged/vim-man,~/.vim/plugged/vim-rtags,~/.vim/plugged/nerdtree,~/.vim/plugged/undotree,~/.vim/plugged/verilog_systemverilog.vim,~/.vim/plugged/systemverilog.vim,~/.vim/plugged/vim-xdc-syntax,~/.vim/plugged/vim-xtcl-syntax,/var/lib/vim/addons,/usr/share/vim/vimfiles,/usr/share/vim/vim80,/usr/share/vim/vimfiles/after,/var/lib/vim/addons/after,~/.vim/after
set shiftwidth=4
set smartcase
set smartindent
set softtabstop=4
set suffixes=.bak,~,.swp,.o,.info,.aux,.log,.dvi,.bbl,.blg,.brf,.cb,.ind,.idx,.ilg,.inx,.out,.toc
set noswapfile
set tabstop=4
set undodir=~/.vim/undodir
set undofile
" vim: set ft=vim :
