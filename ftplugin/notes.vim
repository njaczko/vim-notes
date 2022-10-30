" Vim file type plug-in
" Author: Peter Odding <peter@peterodding.com>
" Last Change: September 14, 2014
" URL: http://peterodding.com/code/vim/notes/

if exists('b:did_ftplugin')
  finish
else
  let b:did_ftplugin = 1
endif

" Add dash to keyword characters so it can be used in tags. {{{1
setlocal iskeyword+=-
let b:undo_ftplugin = 'set iskeyword<'

" Copy indent from previous line. {{{1
setlocal autoindent
let b:undo_ftplugin = 'set autoindent<'

" Set &tabstop and &shiftwidth options for bulleted lists. {{{1
setlocal tabstop=3 shiftwidth=3 expandtab
let b:undo_ftplugin .= ' | set tabstop< shiftwidth< expandtab<'

" Automatic formatting for bulleted lists. {{{1
let &l:comments = xolox#notes#get_comments_option()
setlocal formatoptions=tcron
let b:undo_ftplugin .= ' | set comments< formatoptions<'

setlocal foldmethod=manual

" Enable concealing of notes syntax markers? {{{1
if has('conceal')
  setlocal conceallevel=3
  let b:undo_ftplugin .= ' | set conceallevel<'
endif

" Change ASCII style arrows to Unicode arrows. {{{1
inoremap <buffer> <expr> <- xolox#notes#insert_left_arrow()
inoremap <buffer> <expr> -> xolox#notes#insert_right_arrow()
inoremap <buffer> <expr> <-> xolox#notes#insert_bidi_arrow()
let b:undo_ftplugin .= ' | execute "iunmap <buffer> ->"'
let b:undo_ftplugin .= ' | execute "iunmap <buffer> <-"'
let b:undo_ftplugin .= ' | execute "iunmap <buffer> <->"'

" Convert ASCII bullets to Unicode bullets
inoremap <buffer> <expr> * xolox#notes#insert_bullet('*')
inoremap <buffer> <expr> - xolox#notes#insert_bullet('-')
inoremap <buffer> <expr> + xolox#notes#insert_bullet('+')
let b:undo_ftplugin .= ' | execute "iunmap <buffer> *"'
let b:undo_ftplugin .= ' | execute "iunmap <buffer> -"'
let b:undo_ftplugin .= ' | execute "iunmap <buffer> +"'

" Indent list items using <Tab> and <Shift-Tab>? {{{1
inoremap <buffer> <silent> <Tab> <C-o>:call xolox#notes#indent_list(1, line('.'), line('.'))<CR>
snoremap <buffer> <silent> <Tab> <C-o>:<C-u>call xolox#notes#indent_list(1, line("'<"), line("'>"))<CR><C-o>gv
let b:undo_ftplugin .= ' | execute "iunmap <buffer> <Tab>"'
let b:undo_ftplugin .= ' | execute "sunmap <buffer> <Tab>"'
inoremap <buffer> <silent> <S-Tab> <C-o>:call xolox#notes#indent_list(-1, line('.'), line('.'))<CR>
snoremap <buffer> <silent> <S-Tab> <C-o>:<C-u>call xolox#notes#indent_list(-1, line("'<"), line("'>"))<CR><C-o>gv
let b:undo_ftplugin .= ' | execute "iunmap <buffer> <S-Tab>"'
let b:undo_ftplugin .= ' | execute "sunmap <buffer> <S-Tab>"'

" Automatically remove empty list items on Enter. {{{1
inoremap <buffer> <silent> <expr> <CR> xolox#notes#cleanup_list()
let b:undo_ftplugin .= ' | execute "iunmap <buffer> <CR>"'

" vim: ts=2 sw=2 et
