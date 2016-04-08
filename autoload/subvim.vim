let s:is_windows = has('win32') || has('win64')
let s:is_mac = !s:is_windows && (
                \       has('mac') || has('macunix') || has('gui_macvim') ||
                \       (!isdirectory('/proc') && executable('sw_vers'))
                \   )

let s:SERVER_NAME = 'SUBVIM_SERVER'

let g:subvim#i_am_subvim = get(g:, 'subvim#vim_cmd', 0)
let g:subvim#vim_cmd = get(g:, 'subvim#vim_cmd', 'vim')

function! s:echo_error(...) abort
    echohl ErrorMsg
    try
        for msg in a:000
            execute 'echomsg' string(msg)
        endfor
        return 0
    finally
        echohl None
    endtry
endfunction

function! subvim#server_running() abort
    let servers = split(serverlist(), "\n")
    for s in servers
        if s ==# s:SERVER_NAME
            return 1
        endif
    endfor
    return 0
endfunction

function! subvim#is_valid_server() abort
    if v:servername !=# s:SERVER_NAME
        return 'This Vim did not start as a subvim'
    endif

    if subvim#server_running()
        return 'Server is already running'
    endif

    return ''
endfunction

function! subvim#check_myself() abort
    let err = subvim#is_valid_server()
    if err !=# ''
        call s:echo_error(err)
    endif
endfunction

" TODO:
" Ensure to open subvim on a workspace in sub-display
function! subvim#start_server(force) abort
    if !a:force && subvim#server_running()
        return s:echo_error('Server is already running')
    endif

    if s:is_mac || has('unix')
        let cmd = printf("%s -g -n --servername %s '+call subvim#check_myself()' '+let g:subvim#i_am_subvim = 1'", g:subvim#vim_cmd, s:SERVER_NAME)
        let cmd_result = system(cmd)
    else
        return s:echo_error('This OS is currently not supported.')
    endif

    if v:shell_error
        return s:echo_error('Starting server failed: ' + cmd_result)
    endif

    return 1
endfunction

function! subvim#ensure_server() abort
    if !subvim#server_running()
        let success = subvim#start_server(0)
        if !success
            return
        endif
        echo 'Waiting for starting server...'
        sleep 1
    endif
endfunction

function! subvim#foreground() abort
    call subvim#ensure_server()
    call remote_foreground(s:SERVER_NAME)
endfunction

function! subvim#open(paths, ...) abort
    let paths = a:paths
    if paths == []
        let paths += [expand('%:p')]
    endif

    call subvim#ensure_server()

    let cmd = printf("%s -g --servername %s --remote '+set readonly'", g:subvim#vim_cmd, s:SERVER_NAME)
    for p in paths
        let cmd .= printf(" '%s'", fnamemodify(p, ':p'))
    endfor
    let cmd_result = system(cmd)
    if v:shell_error
        return s:echo_error("Opening files in subvim failed.", cmd_result, 'Command: ' + cmd)
    endif

    let fg = a:0 == 0 || a:1 == 1
    if fg
        call remote_foreground(s:SERVER_NAME)
    endif
endfunction

function! subvim#quit() abort
    if g:subvim#i_am_subvim
        quitall!
    else
        if subvim#server_running()
            try
                call remote_expr(s:SERVER_NAME, 'subvim#quit()', 'g:unused')
            catch
                " Ignore 'no response from server' error
            endtry
        else
            call s:echo_error('No subvim running')
        endif
    endif
endfunction
