" Tslime.vim. Send portion of buffer to tmux instance
" Maintainer: C.Coutinho <kikijump [at] gmail [dot] com>
" Licence:    DWTFYWTPL

if exists("g:loaded_tslime") && g:loaded_tslime
  finish
endif

let g:loaded_tslime = 1

" Main function.
" Use it in your script if you want to send text to a tmux session.
function! Send_to_Tmux(text)
  if !exists("g:tslime")
    call <SID>Tmux_Vars()
  end

  let oldbuffer = system(shellescape("tmux show-buffer"))
  call <SID>set_tmux_buffer(a:text)
  call system("tmux paste-buffer -t " . s:tmux_target())
  call <SID>set_tmux_buffer(oldbuffer)
endfunction

function! Send_Keys_to_Tmux(text)
  if !exists("g:tslime")
    call <SID>Tmux_Vars()
  end

  let oldbuffer = system(shellescape("tmux show-buffer"))
  call <SID>set_tmux_buffer(a:text)
  call system("tmux send-keys -t " . s:tmux_target() . " '" . substitute(a:text, "'", "'\\\\''", 'g') . "'")
  call <SID>set_tmux_buffer(oldbuffer)
endfunction

function! s:tmux_target()
  return '"' . g:tslime['session'] . '":' . g:tslime['window'] . "." . g:tslime['pane']
endfunction

function! s:set_tmux_buffer(text)
  call system("tmux set-buffer '" . substitute(a:text, "'", "'\\\\''", 'g') . "'" )
endfunction

function! SendToTmux(text)
  call Send_to_Tmux(a:text)
endfunction

" Session completion
function! Tmux_Session_Names(A,L,P)
  return <SID>TmuxSessions()
endfunction

" Window completion
function! Tmux_Window_Names(A,L,P)
  return <SID>TmuxWindows()
endfunction

" Pane completion
function! Tmux_Pane_Numbers(A,L,P)
  return <SID>TmuxPanes()
endfunction

function! s:TmuxSessions()
  let sessions = system("tmux list-sessions | sed -e 's/:.*$//'")
  return sessions
endfunction

function! s:TmuxWindows()
  return system('tmux list-windows -t "' . g:tslime['session'] . '" | grep -e "^\w:" | sed -e "s/\s*([0-9].*//g"')
endfunction

function! s:TmuxPanes()
  return system('tmux list-panes -t "' . g:tslime['session'] . '":' . g:tslime['window'] . " | sed -e 's/:.*$//'")
endfunction

" set tslime.vim variables
function! s:Tmux_Vars()
  let names = split(s:TmuxSessions(), "\n")
  let defsession = ''
  let g:tslime = {}
  if len(names) == 1
    let g:tslime['session'] = names[0]
    let defsession = names[0]
  endif

  let g:tslime['session'] = input("session name: ", defsession, "custom,Tmux_Session_Names")

  let windows = split(s:TmuxWindows(), "\n")
  let defwindow = ''
  if len(windows) == 1
    let defwindow = windows[0]
  endif

  let window = input("window name: ", defwindow, "custom,Tmux_Window_Names")
  let g:tslime['window'] =  substitute(window, ":.*$" , '', 'g')

  let panes = split(s:TmuxPanes(), "\n")
  let defpane = ''
  if len(panes) == 1
    let defpane = panes[0]
  endif

  let g:tslime['pane'] = input("pane number: ", defpane, "custom,Tmux_Pane_Numbers")
endfunction

function! ResetTmuxVars()
  call <SID>Tmux_Vars()
endfunction
command ResetTmuxVars call ResetTmuxVars()

vmap <unique> <Plug>SendSelectionToTmux "ry :call Send_to_Tmux(@r)<CR>
nmap <unique> <Plug>NormalModeSendToTmux vip <Plug>SendSelectionToTmux

nmap <unique> <Plug>SetTmuxVars :call <SID>Tmux_Vars()<CR>

command! -nargs=* Tx call Send_to_Tmux('<Args><CR>')
