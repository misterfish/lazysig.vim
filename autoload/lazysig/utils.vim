" =============================================================================
" Author:        Allen Haim <allen@netherrealm.net>
" BasedOn:       CtrlP <github/ctrlpvim/ctrlp.vim>
" OriginalAuthors:  CtrlP Dev team, Kien Nguyen <github.com/kien>
" =============================================================================

fu! lazysig#utils#lash()
	retu &ssl || !exists('+ssl') ? '/' : '\'
endf

fu! s:lash(...)
	retu ( a:0 ? a:1 : getcwd() ) !~ '[\/]$' ? s:lash : ''
endf

fu! lazysig#utils#opts()
	let s:lash = lazysig#utils#lash()
	let usrhome = $HOME . s:lash( $HOME )
	let cahome = exists('$XDG_CACHE_HOME') ? $XDG_CACHE_HOME : usrhome.'.cache'
	let cadir = isdirectory(usrhome.'.lazysig_cache')
		\ ? usrhome.'.lazysig_cache' : cahome.s:lash(cahome).'lazysig'
	if exists('g:lazysig_cache_dir')
		let cadir = expand(g:lazysig_cache_dir, 1)
		if isdirectory(cadir.s:lash(cadir).'.lazysig_cache')
			let cadir = cadir.s:lash(cadir).'.lazysig_cache'
		en
	en
	let s:cache_dir = cadir
endf
cal lazysig#utils#opts()

let s:wig_cond = v:version > 702 || ( v:version == 702 && has('patch051') )

fu! lazysig#utils#cachedir()
	retu s:cache_dir
endf

fu! lazysig#utils#cachefile(...)
	let [tail, dir] = [a:0 == 1 ? '.'.a:1 : '', a:0 == 2 ? a:1 : getcwd()]
	let cache_file = substitute(dir, '\([\/]\|^\a\zs:\)', '%', 'g').tail.'.txt'
	retu a:0 == 1 ? cache_file : s:cache_dir.s:lash(s:cache_dir).cache_file
endf

fu! lazysig#utils#readfile(file)
	if filereadable(a:file)
		let data = readfile(a:file)
		if empty(data) || type(data) != 3
			unl data
			let data = []
		en
		retu data
	en
	retu []
endf

fu! lazysig#utils#mkdir(dir)
	if exists('*mkdir') && !isdirectory(a:dir)
		sil! cal mkdir(a:dir, 'p')
	en
	retu a:dir
endf

fu! lazysig#utils#writecache(lines, ...)
	if isdirectory(lazysig#utils#mkdir(a:0 ? a:1 : s:cache_dir))
		sil! cal writefile(a:lines, a:0 >= 2 ? a:2 : lazysig#utils#cachefile())
	en
endf

fu! lazysig#utils#glob(...)
	let path = lazysig#utils#fnesc(a:1, 'g')
	retu s:wig_cond ? glob(path, a:2) : glob(path)
endf

fu! lazysig#utils#globpath(...)
	retu call('globpath', s:wig_cond ? a:000 : a:000[:1])
endf

fu! lazysig#utils#fnesc(path, type, ...)
	if exists('*fnameescape')
		if exists('+ssl')
			if a:type == 'c'
				let path = escape(a:path, '%#')
			elsei a:type == 'f'
				let path = fnameescape(a:path)
			elsei a:type == 'g'
				let path = escape(a:path, '?*')
			en
			let path = substitute(path, '[', '[[]', 'g')
		el
			let path = fnameescape(a:path)
		en
	el
		if exists('+ssl')
			if a:type == 'c'
				let path = escape(a:path, '%#')
			elsei a:type == 'f'
				let path = escape(a:path, " \t\n%#*?|<\"")
			elsei a:type == 'g'
				let path = escape(a:path, '?*')
			en
			let path = substitute(path, '[', '[[]', 'g')
		el
			let path = escape(a:path, " \t\n*?[{`$\\%#'\"|!<")
		en
	en
	retu a:0 ? escape(path, a:1) : path
endf

