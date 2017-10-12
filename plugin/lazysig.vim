" =============================================================================
" File:          plugin/lazysig.vim
" Description:   Fuzzy file, buffer, mru, tag, etc finder.
" Author:        Kien Nguyen <github.com/kien>
" =============================================================================
" GetLatestVimScripts: 3736 1 :AutoInstall: lazysig.zip

if ( exists('g:loaded_lazysig') && g:loaded_lazysig ) || v:version < 700 || &cp
	fini
en
let g:loaded_lazysig = 1

let [g:lazysig_lines, g:lazysig_allfiles, g:lazysig_alltags, g:lazysig_alldirs,
	\ g:lazysig_allmixes, g:lazysig_buftags, g:lazysig_ext_vars, g:lazysig_builtins]
	\ = [[], [], [], [], {}, {}, [], 2]

if !exists('g:lazysig_map') | let g:lazysig_map = '<Leader>]' | en
if !exists('g:lazysig_imap') | let g:lazysig_imap = '<c-]>' | en

" if !exists('g:lazysig_cmd') | let g:lazysig_cmd = 'FPrompt' | en

let s:lazysig_cmd = 'FPrompt'
let s:lazysig_cmd_i = 'FPromptI'

com! -n=? FPrompt         cal lazysig#init()
com! -n=? FPromptI         cal lazysig#init({'restore_insert': 1})

com! -bar FPromptClearCache     cal lazysig#clr()
com! -bar FPromptClearAllCaches cal lazysig#clra()

com! -bar ClearFPromptCache     cal lazysig#clr()
com! -bar ClearAllFPromptCaches cal lazysig#clra()

" exe 'nn <silent> <plug>(lazysig) :<c-u>'.g:lazysig_cmd.'<cr>'

exe 'nn <silent> <plug>(lazysig) :<c-u>'.s:lazysig_cmd.'<cr>'
exe 'nn <silent> <plug>(lazysig_i) :<c-u>'.s:lazysig_cmd_i.' "i"<cr>'

if g:lazysig_map != '' && !hasmapto('<plug>(lazysig)')
	exe 'map' g:lazysig_map '<plug>(lazysig)'
	exe 'imap' g:lazysig_imap '<plug>(lazysig_i)'
en

" vim:ts=2:sw=2:sts=2
