" TODO mauybe we can nuke all of this....

" Don't source the plug-in when it's already been loaded or &compatible is set.
if &cp || exists('g:loaded_notes')
  finish
endif

" Initialize the configuration defaults.
call xolox#notes#init()

" Make sure the plug-in is only loaded once.
let g:loaded_notes = 1

" vim: ts=2 sw=2 et
