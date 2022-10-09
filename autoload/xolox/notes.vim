" Vim auto-load script
" Author: Peter Odding <peter@peterodding.com>
" Last Change: November 4, 2015
" URL: http://peterodding.com/code/vim/notes/

" Note: This file is encoded in UTF-8 including a byte order mark so
" that Vim loads the script using the right encoding transparently.

let g:xolox#notes#version = '0.33.4'
let g:xolox#notes#url_pattern = '\<\(mailto:\|javascript:\|\w\{3,}://\)\(\S*\w\)\+/\?'
let s:scriptdir = expand('<sfile>:p:h')

" TODO remove all the conditionals.
function! xolox#notes#init() " {{{1
  " Unicode is enabled by default if Vim's encoding is set to UTF-8.
  if !exists('g:notes_unicode_enabled')
    let g:notes_unicode_enabled = (&encoding == 'utf-8')
  endif
  " Tab/Shift-Tab is used to indent/dedent list items by default.
  if !exists('g:notes_tab_indents')
    let g:notes_tab_indents = 1
  endif
  " Symbols used to denote list items with increasing nesting levels.
  let g:notes_unicode_bullets = ['•', '◦', '▸', '▹', '▪', '▫']
  let g:notes_ascii_bullets = ['*', '-', '+']
  if !exists('g:notes_list_bullets')
    if xolox#notes#unicode_enabled()
      let g:notes_list_bullets = g:notes_unicode_bullets
    else
      let g:notes_list_bullets = g:notes_ascii_bullets
    endif
  endif
endfunction


" TODO remove this - assume unicode is enabled everywhere this is called
function! xolox#notes#unicode_enabled() " {{{1
  " Check if the `g:notes_unicode_enabled` option is set to true (1) and Vim's
  " encoding is set to UTF-8.
  return g:notes_unicode_enabled && &encoding == 'utf-8'
endfunction


" TODO definitely some stuff here we want to keep
function! xolox#notes#save() abort " {{{1
  " TODO remove this renaming stuff
  " When the current note's title is changed, automatically rename the file.
  if xolox#notes#filetype_is_note(&ft)
    let title = xolox#notes#current_title()
    let oldpath = expand('%:p')
    let newpath = xolox#notes#title_to_fname(title)
    if newpath == ''
      echoerr "Invalid note title"
      return
    endif

    " Format the bullets
    call xolox#notes#fix_all_bullet_levels()

    " Trigger the BufWritePre automatic command event because it provides
    " a very unobtrusive way for users to extend the vim-notes plug-in.
    execute 'doautocmd BufWritePre' fnameescape(newpath)
    " Actually save the user's buffer to the file.
    let bang = v:cmdbang ? '!' : ''
    execute 'saveas' . bang fnameescape(newpath)
    " XXX If {oldpath} and {newpath} end up pointing to the same file on disk
    " yet xolox#misc#path#equals() doesn't catch this, we might end up
    " deleting the user's one and only note! One way to circumvent this
    " potential problem is to first delete the old note and then save the new
    " note. The problem with this approach is that :saveas might fail in which
    " case we've already deleted the old note...
    if !xolox#misc#path#equals(oldpath, newpath)
      if !filereadable(newpath)
        let message = "The notes plug-in tried to rename your note but failed to create %s so won't delete %s or you could lose your note! This should never happen... If you don't mind me borrowing some of your time, please contact me at peter@peterodding.com and include the old and new filename so that I can try to reproduce the issue. Thanks!"
        call confirm(printf(message, string(newpath), string(oldpath)))
        return
      endif
      call delete(oldpath)
    endif
    " Update the tags index on disk and in-memory.
    call xolox#notes#tags#forget_note(xolox#notes#fname_to_title(oldpath))
    call xolox#notes#tags#scan_note(title, join(getline(1, '$'), "\n"))
    call xolox#notes#tags#save_index()
    " Update in-memory list of all notes.
    call xolox#notes#cache_del(oldpath)
    call xolox#notes#cache_add(newpath, title)

    " Trigger the BufWritePost automatic command event because it provides
    " a very unobtrusive way for users to extend the vim-notes plug-in.
    execute 'doautocmd BufWritePost' fnameescape(newpath)
  endif
endfunction

" Miscellaneous functions. {{{1

" TODO we may need to keep this. inline the #misc stuff
function! xolox#notes#autocmd_pattern(directory, use_extension) " {{{2
  " Generate a normalized automatic command pattern. First we resolve the path
  " to the directory with notes (eliminating any symbolic links) so that the
  " automatic command also applies to symbolic links pointing to notes (Vim
  " matches filename patterns in automatic commands after resolving
  " filenames).
  let directory = xolox#misc#path#absolute(a:directory)
  " Escape the directory but not the trailing "*".
  let pattern = fnameescape(directory) . '/*'
  if a:use_extension && !empty(g:notes_suffix)
    let pattern .= g:notes_suffix
  endif
  " On Windows the pattern won't match if it contains repeating slashes.
  return substitute(pattern, '/\+', '/', 'g')
endfunction

" TODO keep this?
function! xolox#notes#filetype_is_note(ft) " {{{2
  " Check whether the given file type value refers to the notes.vim plug-in.
  return index(split(a:ft, '\.'), 'notes') >= 0
endfunction

" TODO can probably get rid of this after we refactor the `save` stuff
function! xolox#notes#current_title() " {{{2
  " Get the title of the current note.
  let title = getline(1)
  let trimmed = xolox#misc#str#trim(title)
  if title != trimmed
    call setline(1, trimmed)
  endif
  return trimmed
endfunction

" Functions called by the file type plug-in and syntax script. {{{2



function! xolox#notes#insert_left_arrow() " {{{3
  " Change ASCII left arrow (<-) to Unicode arrow (←) as it is typed.
  return (xolox#notes#unicode_enabled() && !xolox#notes#currently_inside_snippet()) ? '←' : "<-"
endfunction

function! xolox#notes#insert_right_arrow() " {{{3
  " Change ASCII right arrow (->) to Unicode arrow (→) as it is typed.
  return (xolox#notes#unicode_enabled() && !xolox#notes#currently_inside_snippet()) ? '→' : '->'
endfunction

function! xolox#notes#insert_bidi_arrow() " {{{3
  " Change bidirectional ASCII arrow (->) to Unicode arrow (→) as it is typed.
  return (xolox#notes#unicode_enabled() && !xolox#notes#currently_inside_snippet()) ? '↔' : "<->"
endfunction

function! xolox#notes#insert_bullet(chr) " {{{3
  " Insert a UTF-8 list bullet when the user types "*".
  if !xolox#notes#currently_inside_snippet()
    if getline('.')[0 : max([0, col('.') - 2])] =~ '^\s*$'
      return xolox#notes#get_bullet(a:chr)
    endif
  endif
  return a:chr
endfunction

function! xolox#notes#get_bullet(chr)
  return xolox#notes#unicode_enabled() ? '•' : a:chr
endfunction

function! xolox#notes#indent_list(direction, line1, line2) " {{{3
  " Change indent of list items from {line1} to {line2} using {command}.
  let indentstr = repeat(' ', &tabstop)
  if a:line1 == a:line2 && getline(a:line1) == ''
    call setline(a:line1, indentstr)
  else
    " Regex to match a leading bullet.
    let leading_bullet = xolox#notes#leading_bullet_pattern()
    for lnum in range(a:line1, a:line2)
      let line = getline(lnum)
      " Calculate new nesting level, should not result in < 0.
      let level = max([0, xolox#notes#get_list_level(line) + a:direction])
      if a:direction == 1
        " Indent the line.
        let line = indentstr . line
      else
        " Unindent the line.
        let line = substitute(line, '^' . indentstr, '', '')
      endif
      " Replace the bullet.
      let bullet = g:notes_list_bullets[level % len(g:notes_list_bullets)]
      call setline(lnum, substitute(line, leading_bullet, xolox#misc#escape#substitute(bullet), ''))
    endfor
    " Regex to match a trailing bullet.
    if getline('.') =~ xolox#notes#trailing_bullet_pattern()
      " Restore trailing space after list bullet.
      call setline('.', getline('.') . ' ')
    endif
  endif
  normal $
endfunction

function! xolox#notes#leading_bullet_pattern()
  " Return a regular expression pattern that matches any leading list bullet.
  let escaped_bullets = copy(g:notes_list_bullets)
  call map(escaped_bullets, 'xolox#misc#escape#pattern(v:val)')
  return '\(\_^\s*\)\@<=\(' . join(escaped_bullets, '\|') . '\)'
endfunction

function! xolox#notes#trailing_bullet_pattern()
  " Return a regular expression pattern that matches any trailing list bullet.
  let escaped_bullets = copy(g:notes_list_bullets)
  call map(escaped_bullets, 'xolox#misc#escape#pattern(v:val)')
  return '\(' . join(escaped_bullets, '\|') . '\|\*\)$'
endfunction

function! xolox#notes#get_comments_option()
  " Get the value for the &comments option including user defined list bullets.
  let items = copy(g:notes_list_bullets)
  call map(items, '": " . v:val . " "')
  call add(items, ':> ') " <- e-mail style block quotes.
  return join(items, ',')
endfunction

function! xolox#notes#get_list_level(line)
  " Get the nesting level of the list item on the given line. This will only
  " work with the list item indentation style expected by the notes plug-in
  " (that is, top level list items are indented with one space, each nested
  " level below that is indented by pairs of three spaces).
  return (len(matchstr(a:line, '^\s*')) - 1) / 3
endfunction

function! xolox#notes#cleanup_list() " {{{3
  " Automatically remove empty list items on Enter.
  if getline('.') =~ (xolox#notes#leading_bullet_pattern() . '\s*$')
    let s:sol_save = &startofline
    setlocal nostartofline " <- so that <C-u> clears the complete line
    return "\<C-o>0\<C-o>d$\<C-o>o"
  else
    if exists('s:sol_save')
      let &l:startofline = s:sol_save
      unlet s:sol_save
    endif
    return "\<CR>"
  endif
endfunction

function! s:words_to_pattern(words)
  " Quote regex meta characters, enable matching of hard wrapped words.
  return substitute(xolox#misc#escape#pattern(a:words), '\s\+', '\\_s\\+', 'g')
endfunction

function! s:sort_longest_to_shortest(a, b)
  " Sort note titles by length, starting with the shortest.
  return len(a:a) < len(a:b) ? 1 : -1
endfunction

function! xolox#notes#highlight_sources(force) " {{{3
  " Syntax highlight source code embedded in notes.
  " Look for code blocks in the current note.
  let filetypes = {}
  for line in getline(1, '$')
    let ft = matchstr(line, '\({{[{]\|```\)\zs\w\+\>')
    if ft !~ '^\d*$' | let filetypes[ft] = 1 | endif
  endfor
  " Don't refresh the highlighting if nothing has changed.
  if !a:force && exists('b:notes_previous_sources') && b:notes_previous_sources == filetypes
    return
  else
    let b:notes_previous_sources = filetypes
  endif
  " Now we're ready to actually highlight the code blocks.
  if !empty(filetypes)
    let startgroup = 'notesCodeStart'
    let endgroup = 'notesCodeEnd'
    for ft in keys(filetypes)
      let group = 'notesSnippet' . toupper(ft)
      let include = s:syntax_include(ft)
      for [startmarker, endmarker] in [['{{{', '}}}'], ['```', '```']]
        let conceal = has('conceal') && xolox#misc#option#get('notes_conceal_code', 1)
        let command = 'syntax region %s matchgroup=%s start="%s%s \?" matchgroup=%s end="%s" keepend contains=%s%s'
        execute printf(command, group, startgroup, startmarker, ft, endgroup, endmarker, include, conceal ? ' concealends' : '')
      endfor
    endfor
  endif
endfunction

function! s:syntax_include(filetype)
  " Include the syntax highlighting of another {filetype}.
  let grouplistname = '@' . toupper(a:filetype)
  " Unset the name of the current syntax while including the other syntax
  " because some syntax scripts do nothing when "b:current_syntax" is set.
  if exists('b:current_syntax')
    let syntax_save = b:current_syntax
    unlet b:current_syntax
  endif
  try
    execute 'syntax include' grouplistname 'syntax/' . a:filetype . '.vim'
    execute 'syntax include' grouplistname 'after/syntax/' . a:filetype . '.vim'
  catch /E403/
    " Ignore errors about syntax scripts that can't be loaded more than once.
    " See also: https://github.com/xolox/vim-notes/issues/68
  catch /E484/
    " Ignore missing scripts.
  endtry
  " Restore the name of the current syntax.
  if exists('syntax_save')
    let b:current_syntax = syntax_save
  elseif exists('b:current_syntax')
    unlet b:current_syntax
  endif
  return grouplistname
endfunction

function! xolox#notes#inside_snippet(lnum, col) " {{{3
  " Check if the given line and column position is inside a snippet (a code
  " block enclosed by triple curly brackets or triple back ticks). This
  " function temporarily changes the cursor position in the current buffer in
  " order to search backwards efficiently.
  let pos_save = getpos('.')
  try
    call setpos('.', [0, a:lnum, a:col, 0])
    let matching_subpattern = search('{{{\|\(}}}\)\|```\w\|\(```\)', 'bnpW')
    return matching_subpattern == 1
  finally
    call setpos('.', pos_save)
  endtry
endfunction

" TODO keep!!
function! xolox#notes#currently_inside_snippet() " {{{3
  " Check if the current cursor position is inside a snippet (a code block
  " enclosed by triple curly brackets).
  return xolox#notes#inside_snippet(line('.'), col('.'))
endfunction

function! xolox#notes#foldtext() " {{{3
  " Replace atx style "#" markers with "-" fold marker.
  let line = getline(v:foldstart)
  if line == ''
    let line = getline(v:foldstart + 1)
  endif
  let matches = matchlist(line, '^\(#\+\)\s*\(.*\)$')
  if len(matches) >= 3
    let prefix = repeat('-', len(matches[1]))
    return prefix . ' ' . matches[2] . ' '
  else
    return line
  endif
endfunction

" TODO KEEP THIS
function! xolox#notes#fix_bullet_level(level, char) " {{{3
    execute '%s/\(^ ' . repeat("   ", a:level) . '\)\(•\|◦\|▸\|▹\|▪\|▫\)/' repeat("   ", a:level) . a:char . "/ge"
endfunction

" TODO KEEP THIS
function! xolox#notes#fix_all_bullet_levels() " {{{3
  " set a mark so we can return to this location when we're done fixing
  mark x
  silent call xolox#notes#fix_bullet_level(0, "•")
  silent call xolox#notes#fix_bullet_level(1, "◦")
  silent call xolox#notes#fix_bullet_level(2, "▸")
  silent call xolox#notes#fix_bullet_level(3, "▹")
  silent call xolox#notes#fix_bullet_level(4, "▪")
  silent call xolox#notes#fix_bullet_level(5, "▫")
  normal 'x
endfunction


" }}}1

" Make sure the plug-in configuration has been properly initialized before
" any of the auto-load functions in this Vim script can be called.
call xolox#notes#init()

" vim: ts=2 sw=2 et bomb
