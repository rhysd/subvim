if (exists('g:loaded_subvim') && g:loaded_subvim) || &cp
    finish
endif

command! -bang -nargs=0 SubvimStartServer call subvim#start_server(<bang>0)
command! -bang -nargs=0 SubvimForeground call subvim#foreground()
command! -complete=file -nargs=* SubvimOpen call subvim#open([<f-args>], 1, g:subvim#full_screen)
command! -complete=file -nargs=* SubvimOpenBg call subvim#open([<f-args>], 0, g:subvim#full_screen)
command! -nargs=0 SubvimQuit call subvim#quit()

let g:loaded_subvim = 1
