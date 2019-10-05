" vim:set ts=2 sts=2 sw=2 expandtab:

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" DEIN CONFIG
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if &compatible
  set nocompatible               
endif

" Add the dein installation directory into runtimepath
set runtimepath+=~/.vim/.cache/dein/repos/github.com/Shougo/dein.vim

" Required:
if dein#load_state('~/.vim/.cache/dein')
  call dein#begin('~/.vim/.cache/dein')
  call dein#add('~/.vim/.cache/dein')

  call dein#add('ctrlpvim/ctrlp.vim')       " ctrlp: file browser
  call dein#add('tpope/vim-dispatch')       " vim-dispatch: asynchronous build and test dispatcher 
  call dein#add('tpope/vim-fugitive.git')   " vim-fugitive: git wapper
  call dein#add('tpope/vim-surround.git')   
  call dein#add('scrooloose/nerdcommenter') " nerdcommenter: commenting plugin

  " call dein#add('Shougo/deoplete.nvim')
  " if !has('nvim')
  "   call dein#add('roxma/nvim-yarp')
  "   call dein#add('roxma/vim-hug-neovim-rpc')
  " endif
  " let g:deoplete#enable_at_startup = 1
  " call dein#add('Shougo/neosnippet.vim')
  " call dein#add('Shougo/neosnippet-snippets')
  " if has('nvim')
  "   call dein#add('zchee/deoplete-go')
  " end

  " GOLANG plugins
  call dein#add('fatih/vim-go')
  call dein#add('AndrewRadev/splitjoin.vim')
  call dein#add('SirVer/ultisnips')

  " RUBY Plugins
  call dein#add('vim-ruby/vim-ruby')
  call dein#add('tpope/vim-rails')
  call dein#add('kchmck/vim-coffee-script')

  " MISC
  call dein#add('fatih/vim-hclfmt')
  call dein#add('mattn/emmet-vim')
  call dein#add('godlygeek/tabular')
  call dein#add('vim-airline/vim-airline')
  call dein#add('tpope/vim-commentary')

  " Required:
  call dein#end()
  call dein#save_state()
endif

filetype plugin indent on
syntax enable

" install not installed plugins on startup.
if dein#check_install()
  call dein#install()
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" BASIC EDITING CONFIGURATION
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set nocompatible
" allow unsaved background buffers and remember marks/undo for them
set hidden
" remember more commands and search history
set history=10000
set expandtab
set tabstop=2
set shiftwidth=2
set softtabstop=2
set autoindent
set laststatus=2
set showmatch
set incsearch
set hlsearch
" make searches case-sensitive only if they contain upper-case characters
set ignorecase smartcase
" highlight current line
" set cursorline
set cmdheight=2
set switchbuf=useopen
set numberwidth=5
set showtabline=2
set winwidth=79
set number
" This makes RVM work inside Vim. I have no idea why.
set shell=bash
" Prevent Vim from clobbering the scrollback buffer. See
" http://www.shallowsky.com/linux/noaltscreen.html
set t_ti= t_te=
" keep more context when scrolling off the end of a buffer
set scrolloff=3
" Store temporary files in a central spot
set backup
set backupdir=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
set directory=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
" allow backspacing over everything in insert mode
set backspace=indent,eol,start
" display incomplete commands
set showcmd
" Enable highlighting for syntax
syntax on
" Enable file type detection.
" Use the default filetype settings, so that mail gets 'tw' set to 72,
" 'cindent' is on in C files, etc.
" Also load indent files, to automatically do language-dependent indenting.
filetype plugin indent on
" use emacs-style tab completion when selecting files, etc
set wildmode=longest,list
" make tab completion for files/buffers act like bash
set wildmenu
" recognize file types from file
set modelines=5

let mapleader=","

" Exit normal mode using <Ctrl>-[
inoremap <C-[> <esc>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Automatically set paste mode in Vim when pasting in insert mode
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let &t_SI .= "\<Esc>[?2004h"
let &t_EI .= "\<Esc>[?2004l"
inoremap <special> <expr> <Esc>[200~ XTermPasteBegin()

function! XTermPasteBegin()
  set pastetoggle=<Esc>[201~
  set paste
  return ""
endfunction


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" CUSTOM AUTOCMDS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
augroup vimrcEx
  " Clear all autocmds in the group
  autocmd!
  autocmd FileType text setlocal textwidth=78
  " Jump to last cursor position unless it's invalid or in an event handler
  autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif

  "for ruby, autoindent with two spaces, always expand tabs
  autocmd FileType ruby,haml,eruby,yaml,html,javascript,sass,cucumber,coffeescript set ai sw=2 sts=2 et
  autocmd FileType python set sw=4 sts=4 et

  autocmd! BufRead,BufNewFile *.sass setfiletype sass 

  autocmd BufRead *.mkd  set ai formatoptions=tcroqn2 comments=n:&gt;
  autocmd BufRead *.markdown  set ai formatoptions=tcroqn2 comments=n:&gt;

  " Indent p tags
  autocmd FileType html,eruby if g:html_indent_tags !~ '\\|p\>' | let g:html_indent_tags .= '\|p\|li\|dt\|dd' | endif

  " Don't syntax highlight markdown because it's often wrong
  autocmd! FileType mkd setlocal syn=off

  " Leave the return key alone when in command line windows, since it's used
  " to run commands there.
  autocmd! CmdwinEnter * :unmap <cr>
  autocmd! CmdwinLeave * :call MapCR()
augroup END


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" DISABLE ARROW KEYS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
map <Left> <Nop>
map <Right> <Nop>
map <Up> <Nop>
map <Down> <Nop>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" OPEN FILES IN DIRECTORY OF CURRENT FILE
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
cnoremap %% <C-R>=expand('%:h').'/'<cr>
map <leader>e :edit %%
map <leader>v :view %%

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" RENAME CURRENT FILE
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! RenameFile()
    let old_name = expand('%')
    let new_name = input('New file name: ', expand('%'), 'file')
    if new_name != '' && new_name != old_name
        exec ':saveas ' . new_name
        exec ':silent !rm ' . old_name
        redraw!
    endif
endfunction
map <leader>n :call RenameFile()<cr>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" COLOR
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set t_Co=256 " 256 colors
set background=dark


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" PROTO BUF
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
augroup filetype
  au! BufRead,BufNewFile *.proto setfiletype proto
augroup end

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" FOR EDITING CRON TABS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
au BufEnter /private/tmp/crontab.* setl backupcopy=yes

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" OVERRIDE READ-ONLY FILES
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
cmap w!! %!sudo tee > /dev/null %

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" OVERRIDE CTRL-P FILE
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists("g:ctrl_user_command")
  unlet g:ctrlp_user_command
endif
set wildignore+=Godeps,*.a,vendor

nmap <Leader>b :CtrlPBuffer<cr>

au BufRead,BufNewFile *.bats setfiletype sh

let g:tagbar_type_go = {
    \ 'ctagstype' : 'go',
    \ 'kinds'     : [
        \ 'p:package',
        \ 'i:imports:1',
        \ 'c:constants',
        \ 'v:variables',
        \ 't:types',
        \ 'n:interfaces',
        \ 'w:fields',
        \ 'e:embedded',
        \ 'm:methods',
        \ 'r:constructor',
        \ 'f:functions'
    \ ],
    \ 'sro' : '.',
    \ 'kind2scope' : {
        \ 't' : 'ctype',
        \ 'n' : 'ntype'
    \ },
    \ 'scope2kind' : {
        \ 'ctype' : 't',
        \ 'ntype' : 'n'
    \ },
    \ 'ctagsbin'  : 'gotags',
    \ 'ctagsargs' : '-sort -silent'
\ }


" vim-go settings
" If using neovim `:GoTest` will run in a new terminal or run asynchronously
" in the background according to |'g:go_term_enabled'|. You can set the mode
" of the new terminal with |'g:go_term_mode'|.
"
" run :GoBuild or :GoTestCompile based on the go file
function! s:build_go_files()
  let l:file = expand('%')
  if l:file =~# '^\f\+_test\.go$'
    call go#test#Test(0, 1)
  elseif l:file =~# '^\f\+\.go$'
    call go#cmd#Build(0)
  endif
endfunction

autocmd FileType go nmap <leader>gb :<C-u>call <SID>build_go_files()<CR>
autocmd FileType go nmap <leader>r  <Plug>(go-run)
autocmd FileType go nmap <leader>t  <Plug>(go-test)
autocmd FileType go nmap <Leader>i <Plug>(go-info)
autocmd FileType go nmap <Leader>c <Plug>(go-callers)
autocmd FileType go nmap <Leader>ge <Plug>(go-rename)

autocmd Filetype go command! -bang A call go#alternate#Switch(<bang>0, 'edit')
autocmd Filetype go command! -bang AV call go#alternate#Switch(<bang>0, 'vsplit')
autocmd Filetype go command! -bang AS call go#alternate#Switch(<bang>0, 'split')
autocmd Filetype go command! -bang AT call go#alternate#Switch(<bang>0, 'tabe')

if has('nvim')
  "let g:go_term_enabled = 1
  let g:go_term_mode = "split"
  let g:go_term_height = 10
  let g:go_term_width = 30
end

" set autowrite
let g:go_fmt_command = "goimports"
let g:go_test_timeout= '30s'
let g:go_auto_type_info = 1
let g:go_list_type = "quickfix"
let g:go_auto_type_info = 1
let g:go_auto_sameids = 1

let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_build_constraints = 1

" go lint
" let g:go_metalinter_enabled = ['errcheck', 'vet']
" let g:go_metalinter_autosave = 1
" let g:go_metalinter_autosave_enabled = ['vet', 'golint']
" let g:go_metalinter_deadline = "10s"
