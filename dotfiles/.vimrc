set nocompatible
call pathogen#infect()

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Random Stuff
let mapleader=','
hi ColdFusion ctermfg=red
au BufEnter,BufWrite *.cfm match ColdFusion /\<cf[a-z]*\>/

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Indentation Stuff
"
filetype indent on
filetype plugin on
set ts=4
set sw=4
set et
set ruler
set wrap

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Syntastic config
"
let g:syntastic_cpp_include_dirs = [ 'src/main/cpp' ]
let g:syntastic_mvn_target = 'target'

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"a super duper status bar
set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]\ [ASCII=\%03.3b]\ [HEX=\%02.2B]\ [POS=%04l,%04v][%p%%]\ [LEN=%L]
set laststatus=2

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Colorscheme stuff
syntax on
set background=dark
colo solarized

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocomplete stuff
function! Smart_TabComplete()
    let line = getline('.')                    " current line

    let substr = strpart(line, -1, col('.')+1) " from the start of the current
    " line to one character right
    " of the cursor
    let substr = matchstr(substr, "[^ \t]*$")  " word till cursor
    if (strlen(substr)==0)                     " nothing to match on empty string
        return "\<tab>"
    endif
    let has_period = match(substr, '\.') != -1 " position of period, if any
    let has_slash = match(substr, '\/') != -1  " position of slash, if any
    if (!has_period && !has_slash)
        return "\<C-X>\<C-P>"                  " existing text matching
    elseif ( has_slash )
        return "\<C-X>\<C-F>"                  " file matching
    else
        return "\<C-X>\<C-O>"                  " plugin matching
    endif
endfunction

if has('autocmd')
    autocmd BufEnter *.java set completeopt=menuone,menu,longest,preview
    autocmd BufEnter *.java :setlocal completefunc=javacomplete#CompleteParamsInfo 
    autocmd BufEnter *.java :setlocal omnifunc=javacomplete#Complete
    autocmd BufEnter * imap <C-J> <C-N>
    autocmd BufEnter * imap <C-K> <C-P>
    autocmd BufEnter * inoremap <tab><tab> <C-R>=Smart_TabComplete()<CR>
    autocmd BufEnter *.java inoremap .<tab> .<C-X><C-O>
    autocmd BufEnter *Test.java map <Leader>t <Esc>:!mvn test -Dtest.containerFactory=com.sun.jersey.test.framework.spi.container.inmemory.InMemoryTestContainerFactory \| grep -v INFO<CR>
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" NERDTree related configs
"
map <C-L> <Esc>:NERDTreeToggle<CR>

let g:NERDTreeWinSize = 50 
autocmd WinEnter * call s:CloseIfOnlyNerdTreeLeft()

" Close all open buffers on entering a window if the only
" buffer that's left is the NERDTree buffer
function! s:CloseIfOnlyNerdTreeLeft()
    if exists("t:NERDTreeBufName")
        if bufwinnr(t:NERDTreeBufName) != -1
            if winnr("$") == 1
                q
            endif
        endif
    endif
endfunction

