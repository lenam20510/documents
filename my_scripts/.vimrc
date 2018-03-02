set runtimepath^=~/.vim/bundle/ctrlp.vim-master
set runtimepath^=~/.vim/bundle/delimitMate-master
set runtimepath^=~/.vim/bundle/brackets-indent-guides-master
set runtimepath^=~/.vim/bundle/vscode-youcompleteme-master
"AutoComplPop does not support this version of vim (701).
"set runtimepath^=~/.vim/bundle/AutoComplPop-master

"----------------------General setup-----------------------------------
autocmd QuickFixCmdPost [^l]* nested cwindow
autocmd QuickFixCmdPost    l* nested lwindow
syntax on
colorscheme desert
set number
set cursorline
set tabstop=4 "number of visual spaces per TAB
set softtabstop=4   " number of spaces in tab when editing
"set expandtab       " tabs are spaces
" :e ++enc=sjis
" set fileencodings=iso-2022-jp,euc-jp,cp932,utf8,default,latin1
set encoding=sjis
set nowrap
"set listchars=eol:$,tab:>-,trail:~,extends:>,precedes:<
"set list
"set wrap
set linebreak
hi StatusLine                  ctermfg=4   "  ctermbg=8     cterm=NONE
hi StatusLineNC                ctermfg=2     ctermbg=8     cterm=NONE
set shellcmdflag=-ic "Using alias in Vim

set wildmenu " visual autocomplete for command menu"
set showmatch           " highlight matching [{()}]}]"
set incsearch           " search as characters are entered
set hlsearch            " highlight matches
"set foldenable          " enable folding^
"set foldmethod=indent   " fold based on indent level
" highlight last inserted text
nnoremap gV `[v`]
set ignorecase
set smartcase
"----------------------TAB setting-----------------------------------
"To create a new tab
"nnoremap <C-t> :tabnew<Enter>
"inoremap <C-t> <Esc>:tabnew<Space>
nnoremap tn  :tabnew<Enter>
nnoremap tj  :tabnext<Enter>
nnoremap tk  :tabprev<Enter>
"----------------------CtrlP setting-----------------------------------
let g:vim_tags_auto_generate = 1
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_match_window = 'bottom,order:ttb'
let g:ctrlp_switch_buffer = 0
let g:ctrlp_working_path_mode = 0
let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/]\.(git|hg|svn)$',
  \ 'file': '\v(\.cpp|\.h|\.hh|\.cxx)@<!$',
  \ 'link': 'some_bad_symbolic_links',
  \ }
"let g:ctrlp_prompt_mappings = {
    \ 'AcceptSelection("e")': ['<2-LeftMouse>'],
    \ 'AcceptSelection("t")': ['<cr>'],
    \ }
"----------------------Tag_list setting-----------------------------------
"nnoremap <silent> <F8> :TlistOpen<CR>
nnoremap <silent> <F8> :TlistToggle<CR>
nnoremap <silent> <F9> :TlistShowPrototype<CR>
" actionscript language
let tlist_actionscript_settings = 'actionscript;c:class;f:method;p:property;v:variable'
let tlist_tex_settings   = 'latex;s:sections;g:graphics;l:labels'
let tlist_make_settings  = 'make;m:makros;t:targets'
let Tlist_Use_Right_Window = 1
let Tlist_WinWidth = 50
let Tlist_Use_SingleClick = 1
"let Tlist_Show_One_File = 1
"let Tlist_Display_Prototype = 1
"let Tlist_Process_File_Always = 1
:set statusline=%<%f%=%([%{Tlist_Get_Tagname_By_Line()}]%)
"----------------------Explore in Vim-----------------------------------
"let g:netrw_liststyle = 3
let g:netrw_banner = 0
