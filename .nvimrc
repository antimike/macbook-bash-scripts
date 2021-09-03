version 6.0
let s:cpo_save=&cpo
set cpo&vim
nmap <silent> % <Plug>(MatchitNormalForward)
xmap <silent> % <Plug>(MatchitVisualForward)
omap <silent> % <Plug>(MatchitOperationForward)
nmap <silent> [% <Plug>(MatchitNormalMultiBackward)
xmap <silent> [% <Plug>(MatchitVisualMultiBackward)
omap <silent> [% <Plug>(MatchitOperationMultiBackward)
nmap <silent> ]% <Plug>(MatchitNormalMultiForward)
xmap <silent> ]% <Plug>(MatchitVisualMultiForward)
omap <silent> ]% <Plug>(MatchitOperationMultiForward)
xmap a% <Plug>(MatchitVisualTextObject)
nmap <silent> g% <Plug>(MatchitNormalBackward)
xmap <silent> g% <Plug>(MatchitVisualBackward)
omap <silent> g% <Plug>(MatchitOperationBackward)
nmap gx <Plug>NetrwBrowseX
vmap gx <Plug>NetrwBrowseXVis
nnoremap <silent> <Plug>(fzf-insert) i
nnoremap <silent> <Plug>(fzf-normal) <Nop>
tnoremap <silent> <Plug>(fzf-insert) i
tnoremap <silent> <Plug>(fzf-normal) 
nnoremap <silent> <Plug>(MatchitNormalForward) :call matchit#Match_wrapper('',1,'n')
nnoremap <silent> <Plug>(MatchitNormalBackward) :call matchit#Match_wrapper('',0,'n')
xnoremap <silent> <Plug>(MatchitVisualForward) :call matchit#Match_wrapper('',1,'v')m'gv``
xnoremap <silent> <Plug>(MatchitVisualBackward) :call matchit#Match_wrapper('',0,'v')m'gv``
onoremap <silent> <Plug>(MatchitOperationForward) :call matchit#Match_wrapper('',1,'o')
onoremap <silent> <Plug>(MatchitOperationBackward) :call matchit#Match_wrapper('',0,'o')
nnoremap <silent> <Plug>(MatchitNormalMultiBackward) :call matchit#MultiMatch("bW", "n")
nnoremap <silent> <Plug>(MatchitNormalMultiForward) :call matchit#MultiMatch("W",  "n")
xnoremap <silent> <Plug>(MatchitVisualMultiBackward) :call matchit#MultiMatch("bW", "n")m'gv``
xnoremap <silent> <Plug>(MatchitVisualMultiForward) :call matchit#MultiMatch("W",  "n")m'gv``
onoremap <silent> <Plug>(MatchitOperationMultiBackward) :call matchit#MultiMatch("bW", "o")
onoremap <silent> <Plug>(MatchitOperationMultiForward) :call matchit#MultiMatch("W",  "o")
xmap <silent> <Plug>(MatchitVisualTextObject) <Plug>(MatchitVisualMultiBackward)o<Plug>(MatchitVisualMultiForward)
nnoremap <silent> <Plug>NetrwBrowseX :call netrw#BrowseX(netrw#GX(),netrw#CheckIfRemote(netrw#GX()))
vnoremap <silent> <Plug>NetrwBrowseXVis :call netrw#BrowseXVis()
let &cpo=s:cpo_save
unlet s:cpo_save
set expandtab
set helplang=en
set nohlsearch
set runtimepath=~/.config/nvim,/etc/xdg/nvim,~/.local/share/nvim/site,~/.local/share/flatpak/exports/share/nvim/site,/var/lib/flatpak/exports/share/nvim/site,/usr/local/share/nvim/site,/usr/share/nvim/site,/usr/share/nvim/runtime,/usr/share/nvim/runtime/pack/dist/opt/matchit,/usr/lib/nvim,/usr/share/nvim/site/after,/usr/local/share/nvim/site/after,/var/lib/flatpak/exports/share/nvim/site/after,~/.local/share/flatpak/exports/share/nvim/site/after,~/.local/share/nvim/site/after,/etc/xdg/nvim/after,~/.config/nvim/after,/usr/share/vim/vimfiles/
set shiftwidth=4
set softtabstop=4
set tabstop=4
set textwidth=80
set window=21
set winminheight=0
set winminwidth=0
" vim: set ft=vim :
