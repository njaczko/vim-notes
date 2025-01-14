﻿" Vim syntax script
" Author: Peter Odding <peter@peterodding.com>
" Last Change: March 15, 2015
" URL: http://peterodding.com/code/vim/notes/

" Note: This file is encoded in UTF-8 including a byte order mark so
" that Vim loads the script using the right encoding transparently.

" Quit when a syntax file was already loaded.
if exists('b:current_syntax')
  finish
endif

" Tell Vim to start redrawing by rescanning all previous text. This isn't
" exactly optimal for performance but it enables accurate syntax highlighting.
" Ideally we'd find a way to get accurate syntax highlighting without the
" nasty performance implications, but for now I'll accept the performance
" impact in order to have accurate highlighting. For more discussion please
" refer to https://github.com/xolox/vim-notes/issues/2.
syntax sync fromstart

" Check for spelling errors in all text.
syntax spell toplevel

" Inline elements. {{{1

" Cluster of elements which never contain a newline character.
syntax cluster notesInline contains=notesName

" Default highlighting style for notes syntax markers.
highlight def link notesHiddenMarker Ignore

" Highlight list bullets and numbers. {{{2
execute 'syntax match notesListBullet /' . escape(xolox#notes#leading_bullet_pattern(), '/') . '/'
highlight def link notesListBullet Comment
syntax match notesListNumber /^\s*\zs\d\+[[:punct:]]\?\ze\s/
highlight def link notesListNumber Comment

" Highlight quoted fragments. {{{2
if xolox#notes#unicode_enabled()
  syntax match notesDoubleQuoted /\w\@<!“.\{-}”\w\@!/
  syntax match notesSingleQuoted /\w\@<!‘.\{-}’\w\@!/
else
  syntax match notesDoubleQuoted /\w\@<!".\{-}"\w\@!/
  syntax match notesSingleQuoted /\w\@<!`.\{-}'\w\@!/
endif
highlight def link notesSingleQuoted Special
highlight def link notesDoubleQuoted String

" Highlight inline code fragments (same as Markdown syntax). {{{2
syntax region notesInlineCode matchgroup=notesInlineCodeMarker start=/`/ end=/`/ concealends
highlight link notesItalicMarker notesInlineCodeMarker

syntax cluster notesInline add=notesInlineCode
highlight def link notesInlineCode Special

" Highlight text emphasized in italic font. {{{2
syntax region notesItalic matchgroup=notesItalicMarker start=/\<_\k\@=/ end=/_\>\|\n/ contains=@Spell concealends
highlight link notesItalicMarker notesHiddenMarker

syntax cluster notesInline add=notesItalic
highlight notesItalic gui=italic cterm=italic

" Highlight text emphasized in bold font. {{{2
syntax region notesBold matchgroup=notesBoldMarker start=/\*\k\@=/ end=/\S\@<=\*/ contains=@Spell concealends
highlight link notesBoldMarker notesHiddenMarker

syntax cluster notesInline add=notesBold
highlight notesBold gui=bold cterm=bold ctermfg=DarkRed

" New BLOCKED marker
syntax match notesBlockedItem /^\(\s\+\).*\<BLOCKED\>.*\(\n\1\s.*\)*/ contains=@notesInline
syntax match notesBlockedMarker /\<BLOCKED\>/ containedin=notesBlockedItem
highlight def link notesBlockedItem Comment
highlight def link notesBlockedMarker Directory

" Updated XXX marker
syntax match notesXXXItem /^\(\s\+\).*\<XXX\>.*\(\n\1\s.*\)*/ contains=@notesInline
syntax match notesXXXMarker /\<XXX\>/ containedin=notesXXXItem
highlight def link notesXXXItem Comment
highlight def link notesXXXMarker WarningMsg


" Highlight TODO, DONE, and FIXME markers. {{{2
syntax match notesTodo /\<TODO\>/
syntax match notesFixMe /\<FIXME\>/
syntax match notesInProgress /\<\(CURRENT\|INPROGRESS\|STARTED\|WIP\)\>/
syntax match notesDoneItem /^\(\s\+\).*\<DONE\>.*\(\n\1\s.*\)*/ contains=@notesInline
syntax match notesDoneMarker /\<DONE\>/ containedin=notesDoneItem
highlight def link notesTodo WarningMsg
highlight def link notesFixMe WarningMsg
highlight def link notesDoneItem Comment
highlight def link notesDoneMarker Question
highlight def link notesInProgress Directory

" Highlight Vim command names in :this notation. {{{2
syntax match notesVimCmd /\w\@<!:\w\+\(!\|\>\)/ contains=ALLBUT,@Spell
syntax cluster notesInline add=notesVimCmd
highlight def link notesVimCmd Special

" Block level elements. {{{1

" The first line of each note contains the title. {{{2
syntax match notesTitle /^.*\%1l.*$/ contains=@notesInline
highlight def link notesTitle ModeMsg

" Short sentences ending in a colon are considered headings. {{{2
syntax match notesShortHeading /^\s*\zs\u.\{1,50}\k:\ze\(\s\|$\)/ contains=@notesInline
highlight def link notesShortHeading Title

" Atx style headings are also supported. {{{2
syntax match notesAtxHeading /^#\+.*/ contains=notesAtxMarker,@notesInline
highlight def link notesAtxHeading Title
syntax match notesAtxMarker /^#\+/ contained
highlight def link notesAtxMarker Comment

" E-mail style block quotes are highlighted as comments. {{{2
syntax match notesBlockQuote /\(^\s*>.*\n\)\+/ contains=@notesInline
highlight def link notesBlockQuote Comment

" Horizontal rulers. {{{2
syntax match notesRule /\(^\s\+\)\zs\*\s\*\s\*$/
highlight def link notesRule Comment

" Highlight embedded blocks of source code, log file messages, basically anything Vim can highlight. {{{2
" NB: I've escaped these markers so that Vim doesn't interpret them when editing this file…
syntax match notesCodeStart /```\w*/
syntax match notesCodeEnd /```\W/
syntax match notesCodeStart /{{[{]\w*/
syntax match notesCodeEnd /}}[}]/
highlight def link notesCodeStart Ignore
highlight def link notesCodeEnd Ignore
call xolox#notes#highlight_sources(1)

" }}}1

" Set the currently loaded syntax mode.
let b:current_syntax = 'notes'

" vim: ts=2 sw=2 et bomb fdl=1
