set runtimepath^=~/.vim/bundle/ctrlp.vim-master
set runtimepath^=~/.vim/bundle/delimitMate-master
set runtimepath^=~/.vim/bundle/brackets-indent-guides-master
set runtimepath^=~/.vim/bundle/vscode-youcompleteme-master
set runtimepath^=~/.vim/bundle/cscope.vim
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

fun! ShowFuncName()
  let lnum = line(".")
  let col = col(".")
  echohl ModeMsg
  echo getline(search("^[^ \t#/]\\{2}.*[^:]\s*$", 'bW'))
  echohl None
  call search("\\%" . lnum . "l" . "\\%" . col . "c")
endfun
map f :call ShowFuncName() <CR>
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
"----------------------escope-----------------------------------
cs add $CSCOPE_DB
set cscopequickfix=s-,c-,d-,i-,t-,e-
	" use both cscope and ctag for 'ctrl-]', ':ta', and 'vim -t'
	"set cscopetag
	" check cscope for definition of a symbol before checking ctags: set to 1
	" if you want the reverse search order.
    set csto=0
	" show msg when any other cscope db added
    set cscopeverbose  
    " To do the first type of search, hit 'CTRL-\', followed by one of the
    " cscope search types above (s,g,c,t,e,f,i,d).  The result of your cscope
    " search will be displayed in the current window.  You can use CTRL-T to
    " go back to where you were before the search.  
    "

    nmap <C-\>s :cs find s <C-R>=expand("<cword>")<CR><CR>	
    nmap <C-\>g :cs find g <C-R>=expand("<cword>")<CR><CR>	
    nmap <C-\>c :cs find c <C-R>=expand("<cword>")<CR><CR>	
    nmap <C-\>t :cs find t <C-R>=expand("<cword>")<CR><CR>	
    nmap <C-\>e :cs find e <C-R>=expand("<cword>")<CR><CR>	
    nmap <C-\>f :cs find f <C-R>=expand("<cfile>")<CR><CR>	
    nmap <C-\>i :cs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
    nmap <C-\>d :cs find d <C-R>=expand("<cword>")<CR><CR>	


    " Using 'CTRL-spacebar' (intepreted as CTRL-@ by vim) then a search type
    " makes the vim window split horizontally, with search result displayed in
    " the new window.
    "
    " (Note: earlier versions of vim may not have the :scs command, but it
    " can be simulated roughly via:
    "    nmap <C-@>s <C-W><C-S> :cs find s <C-R>=expand("<cword>")<CR><CR>	

    nmap <C-@>s :scs find s <C-R>=expand("<cword>")<CR><CR>	
    nmap <C-@>g :scs find g <C-R>=expand("<cword>")<CR><CR>	
    nmap <C-@>c :scs find c <C-R>=expand("<cword>")<CR><CR>	
    nmap <C-@>t :scs find t <C-R>=expand("<cword>")<CR><CR>	
    nmap <C-@>e :scs find e <C-R>=expand("<cword>")<CR><CR>	
    nmap <C-@>f :scs find f <C-R>=expand("<cfile>")<CR><CR>	
    nmap <C-@>i :scs find i ^<C-R>=expand("<cfile>")<CR>$<CR>	
    nmap <C-@>d :scs find d <C-R>=expand("<cword>")<CR><CR>	


    " Hitting CTRL-space *twice* before the search type does a vertical 
    " split instead of a horizontal one (vim 6 and up only)
    "
    " (Note: you may wish to put a 'set splitright' in your .vimrc
    " if you prefer the new window on the right instead of the left

    nmap <C-@><C-@>s :vert scs find s <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@><C-@>g :vert scs find g <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@><C-@>c :vert scs find c <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@><C-@>t :vert scs find t <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@><C-@>e :vert scs find e <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@><C-@>f :vert scs find f <C-R>=expand("<cfile>")<CR><CR>	
    nmap <C-@><C-@>i :vert scs find i ^<C-R>=expand("<cfile>")<CR>$<CR>	
    nmap <C-@><C-@>d :vert scs find d <C-R>=expand("<cword>")<CR><CR>