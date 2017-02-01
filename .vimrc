" vim:set ts=2 sts=2 sw=2 expandtab:
call pathogen#infect()
call pathogen#helptags()

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
" REFRESH CTAGS FROM BUNDLER GEM PATH
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
map <Leader>rft :!ctags -e --exclude=.git --exclude='*.log *.js *.css *.sass' -R * `bundle show --paths` <CR><CR>

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
" MAPS TO JUMP TO SPECIFIC COMMAND-T TARGETS AND FILES
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! ShowRoutes()
  " Requires 'scratch' plugin
  :topleft 100 :split __Routes__
  " Make sure Vim doesn't write __Routes__ as a file
  :set buftype=nofile
  " Delete everything
  :normal 1GdG
  " Put routes output in buffer
  :0r! bundle exec rake -s routes
  " Size window to number of lines (1 plus rake output length)
  :exec ":normal " . line("$") . _ "
  " Move cursor to bottom
  :normal 1GG
  " Delete empty trailing line
  :normal dd
endfunction

function! ListControllers()
  :CtrlPClearAllCaches
  if isdirectory("app/scripts/controllers")
    :CtrlP app/scripts/controllers
  else
    :CtrlP app/controllers
  endif
endfunction

function! ListServices()
  :CtrlPClearAllCaches
  if isdirectory("app/scripts/services")
    :CtrlP app/scripts/services
  elseif isdirectory("app/services")
    :CtrlP app/services
  else
    :CtrlP app/lib/services
  endif
endfunction

function! ListViews()
  :CtrlPClearAllCaches
  :CtrlP app/views
endfunction

function! ListModels()
  :CtrlPClearAllCaches
  if isdirectory("app/scripts/models")
    :CtrlP app/scripts/models
  else
    :CtrlP app/models
  endif
endfunction

function! ListStyles()
  :CtrlPClearAllCaches
  if isdirectory("app/styles")
    :CtrlP app/styles
  else
    :CtrlP app/assets/stylesheets
  endif
endfunction

function! ListDirectives()
  :CtrlPClearAllCaches
  :CtrlP app/scripts/directives
endfunction

function! ListScripts()
  :CtrlPClearAllCaches
  if isdirectory("app/scripts")
    :CtrlP app/scripts
  else
    :CtrlP app/assets/javascripts
  endif
endfunction

" Rails specific
au FileType ruby nmap <leader>gr :topleft :split config/routes.rb<cr>
au FileType ruby map <leader>gR :call ShowRoutes()<cr>
au FileType ruby nmap <leader>gc :call ListControllers()<cr>
au FileType ruby nmap <leader>gv :call ListViews()<cr>
au FileType ruby nmap <leader>gm :call ListModels()<cr>
au FileType ruby nmap <leader>gss :call ListStyles()<cr>
au FileType ruby nmap <leader>gsv :call ListServices()<cr>
au FileType ruby nmap <leader>gj :call ListScripts()<cr>
au FileType ruby nmap <leader>gh :CtrlPClearAllCaches<cr>\|:CtrlP app/helpers<cr>
au FileType ruby nmap <leader>gl :CtrlPClearAllCaches<cr>\|:CtrlP lib<cr>
au FileType ruby nmap <leader>gf :CtrlPClearAllCaches<cr>\|:CtrlP spec/features<cr>
au FileType ruby nmap <leader>gg :topleft 100 :split Gemfile<cr>
au FileType ruby nmap <leader>f :CtrlPClearAllCaches<cr>\|:CtrlP<cr>
au FileType ruby nmap <leader>F :CtrlPClearAllCaches<cr>\|:CtrlP %%<cr>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" SWITCH BETWEEN TEST AND PRODUCTION CODE
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! OpenTestAlternate()
  if &filetype == "go"
    exec ':e ' .  AlternateForCurrentFile_go()
  elseif &filetype == "ruby"
    exec ':e ' . AlternateForCurrentFile()
  endif
endfunction

" switches between <current_file>.go and <current_file>_test.go
function! AlternateForCurrentFile_go()
  let current_file = expand("%")
  let new_file = current_file
  " check if the current file is a test file
  let in_test = match(current_file, '_test.go') != -1
  if in_test
    return substitute(new_file, '_test\.go$', '.go', '')
  else
    return substitute(new_file, '\.go$', '_test.go', '')
  endif
endfunction

function! AlternateForCurrentFile()
  let current_file = expand("%")
  let new_file = current_file
  let in_spec = match(current_file, '^spec/') != -1
  let going_to_spec = !in_spec
  let in_app = match(current_file, '\<controllers\>') != -1 || match(current_file, '\<models\>') != -1 || match(current_file, '\<views\>') != -1 || match(current_file, '\<helpers\>') != -1 ||  match(current_file, '\<workers\>')
  if going_to_spec
    if in_app
      let new_file = substitute(new_file, '^app/', '', '')
    end
    let new_file = substitute(new_file, '\.rb$', '_spec.rb', '')
    let new_file = 'spec/' . new_file
  else
    let new_file = substitute(new_file, '_spec\.rb$', '.rb', '')
    let new_file = substitute(new_file, '^spec/', '', '')
    if in_app
      let new_file = 'app/' . new_file
    end
  endif
  return new_file
endfunction

nnoremap <leader>. :call OpenTestAlternate()<cr>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" RUNNING TESTS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
map <leader>t :call RunTestFile()<cr>
map <leader>T :call RunNearestTest()<cr>
map <leader>a :call RunTests('')<cr>
map <leader>c :w\|:!script/features<cr>
map <leader>w :w\|:!script/features --profile wip<cr>

function! RunTestFile(...)
    if a:0
        let command_suffix = a:1
    else
        let command_suffix = ""
    endif

    " Run the tests for the previously-marked file.
    let in_test_file = match(expand("%"), '\(.feature\|_spec.rb\)$') != -1
    if in_test_file
        call SetTestFile()
    elseif !exists("t:grb_test_file")
        return
    end
    call RunTests(t:grb_test_file . command_suffix)
endfunction

function! RunNearestTest()
    let spec_line_number = line('.')
    call RunTestFile(":" . spec_line_number . " -b")
endfunction

function! SetTestFile()
    " Set the spec file that tests will be run for.
    let t:grb_test_file=@%
endfunction

function! RunTests(filename)
    " Write the file and run tests for the given filename
    :w
    :silent !echo;echo;echo;echo;echo;echo;echo;echo;echo;echo
    :silent !echo;echo;echo;echo;echo;echo;echo;echo;echo;echo
    :silent !echo;echo;echo;echo;echo;echo;echo;echo;echo;echo
    :silent !echo;echo;echo;echo;echo;echo;echo;echo;echo;echo
    :silent !echo;echo;echo;echo;echo;echo;echo;echo;echo;echo
    :silent !echo;echo;echo;echo;echo;echo;echo;echo;echo;echo
    if match(a:filename, '\.feature$') != -1
        exec ":!script/features " . a:filename
    else
        if filereadable("script/test")
            exec ":!script/test " . a:filename
        elseif filereadable("Gemfile")
          if filereadable("bin/spring")
            exec ":!bin/spring rspec --color " . a:filename
          else
            exec ":!bundle exec rspec --color " . a:filename
          end
        else
            exec ":!rspec --color " . a:filename
        end
    end
endfunction


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" MISC
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
map <leader>vp :call VagrantProvision()<cr>

function! VagrantProvision()
  exec ":!vagrant provision"
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Terraform
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
map <leader>tp :call TerraformPlan()<cr>
map <leader>ta :call TerraformApply()<cr>

function! TerraformPlan() 
  exec ":!terraform get && terraform plan -module-depth=1 -input=false"
endfunction

function! TerraformApply() 
  exec ":!terraform get && terraform apply -input=false"
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" GO
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! GoTest() 
  let pkgname = substitute(expand("%:p:h"),getcwd(),'','')
  let pkgname = substitute(pkgname,"\/src\/",'','')
  exec ":!gb test -v " . pkgname
endfunction

" " Alternative go test with gb support
au FileType go nmap <leader>t :call GoTest()<cr>

" " vim-go mappings
" au FileType go nmap <leader>r <Plug>(go-run)
" "au FileType go nmap <leader>b <Plug>(go-build)
au FileType go nmap <leader>gt <Plug>(go-test)
" au FileType go nmap <leader>c <Plug>(go-coverage)

" au FileType go nmap <Leader>ds <Plug>(go-def-split)
" au FileType go nmap <Leader>dv <Plug>(go-def-vertical)
" au FileType go nmap <Leader>dt <Plug>(go-def-tab)
" au FileType go nmap <Leader>gd <Plug>(go-doc)
" au FileType go nmap <Leader>gv <Plug>(go-doc-vertical)
" au FileType go nmap <Leader>gb <Plug>(go-doc-browser)
" au FileType go nmap <Leader>s <Plug>(go-implements)
" au FileType go nmap <Leader>i <Plug>(go-info)
" au FileType go nmap <Leader>ge <Plug>(go-rename)

" " vim-go settings
" let g:go_fmt_command = "goimports"
" "let g:go_fmt_fail_silently = 1

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

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" NeoComplete config
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:neocomplete#enable_at_startup = 1
