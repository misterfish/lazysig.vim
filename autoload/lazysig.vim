" =============================================================================
" Author:        Allen Haim <allen@netherrealm.net>
" BasedOn:       CtrlP <github/ctrlpvim/ctrlp.vim>
" OriginalAuthors:  CtrlP Dev team, Kien Nguyen <github.com/kien>
" =============================================================================

let s:scriptpath = expand('<sfile>:h:p')
let s:parserbin = s:scriptpath."/../lazysig/parser/lazysig"
let s:debug = 0

let [s:pref, s:bpref, s:opts, s:new_opts, s:lc_opts] =
	\ ['g:lazysig_', 'b:lazysig_', {
	\ 'abbrev':                ['s:abbrev', {}],
	\ 'arg_map':               ['s:argmap', 0],
	\ 'dont_split':            ['s:nosplit', 'netrw'],
	\ 'dotfiles':              ['s:showhidden', 0],
	\ 'extensions':            ['s:extensions', []],
	\ 'follow_symlinks':       ['s:folsym', 0],
	\ 'highlight_match':       ['s:mathi', [1, 'FPromptMatch']],
	\ 'jump_to_buffer':        ['s:jmptobuf', 'Et'],
	\ 'key_loop':              ['s:keyloop', 0],
	\ 'match_func':            ['s:matcher', {}],
	\ 'max_depth':             ['s:maxdepth', 40],
	\ 'max_files':             ['s:maxfiles', 10000],
	\ 'max_height':            ['s:mxheight', 10],
	\ 'max_history':           ['s:maxhst', exists('+hi') ? &hi : 20],
	\ 'mruf_default_order':    ['s:mrudef', 0],
	\ 'open_func':             ['s:openfunc', {}],
	\ 'open_multi':            ['s:opmul', '1v'],
	\ 'open_new_file':         ['s:newfop', 'v'],
	\ 'split_window':          ['s:splitwin', 0],
	\ 'tabpage_position':      ['s:tabpage', 'ac'],
	\ 'line_prefix':           ['s:lineprefix', '> '],
	\ 'brief_prompt':          ['s:brfprt', 0],
	\ 'match_current_file':    ['s:matchcrfile', 0],
	\ 'match_natural_name':    ['s:matchnatural', 0],
	\ 'compare_lim':           ['s:compare_lim', 3000],
	\ 'bufname_mod':           ['s:bufname_mod', ':t'],
	\ 'bufpath_mod':           ['s:bufpath_mod', ':~:.:h'],
	\ 'user_command_async':    ['s:usrcmdasync', 0],
	\ }, {
	\ 'open_multiple_files':   's:opmul',
	\ 'reuse_window':          's:nosplit',
	\ 'show_hidden':           's:showhidden',
	\ 'switch_buffer':         's:jmptobuf',
	\ }, {
	\ }]

" Global options
let s:glbs = { 'magic': 1, 'to': 1, 'tm': 0, 'sb': 1, 'hls': 0, 'im': 0,
	\ 'report': 9999, 'sc': 0, 'ss': 0, 'siso': 0, 'mfd': 200, 'ttimeout': 0,
	\ 'gcr': 'a:blinkon0', 'ic': 1, 'lmap': '', 'mousef': 0, 'imd': 1 }

" Keymaps
let [s:lcmap, s:prtmaps] = ['nn <buffer> <silent>', {
	\ 'PrtBS()':              ['<bs>', '<c-]>'],
	\ 'PrtDelete()':          ['<del>'],
	\ 'PrtDeleteWord()':      ['<c-w>'],
	\ 'PrtClear()':           ['<c-u>'],
	\ 'PrtSelectMove("j")':   ['<c-j>', '<down>'],
	\ 'PrtSelectMove("k")':   ['<c-k>', '<up>'],
	\ 'PrtSelectMove("t")':   ['<Home>', '<kHome>'],
	\ 'PrtSelectMove("b")':   ['<End>', '<kEnd>'],
	\ 'PrtSelectMove("u")':   ['<PageUp>', '<kPageUp>'],
	\ 'PrtSelectMove("d")':   ['<PageDown>', '<kPageDown>'],
	\ 'PrtHistory(-1)':       ['<c-n>'],
	\ 'PrtHistory(1)':        ['<c-p>'],
	\ 'AcceptSelection()':    ['<cr>', '<2-LeftMouse>'],
	\ 'ToggleFocus()':        ['<s-tab>'],
	\ 'PrtCurStart()':        ['<c-a>'],
	\ 'PrtCurEnd()':          ['<c-e>'],
	\ 'PrtCurLeft()':         ['<c-h>', '<left>', '<c-^>'],
	\ 'PrtCurRight()':        ['<c-l>', '<right>'],
	\ 'PrtExit()':            ['<esc>', '<c-c>', '<c-g>'],
	\ }]

if !has('gui_running')
	cal add(s:prtmaps['PrtBS()'], remove(s:prtmaps['PrtCurLeft()'], 0))
en

let s:ficounts = {}

" Regexp
let s:fpats = {
	\ '^\(\\|\)\|\(\\|\)$': '\\|',
	\ '^\\\(zs\|ze\|<\|>\)': '^\\\(zs\|ze\|<\|>\)',
	\ '^\S\*$': '\*',
	\ '^\S\\?$': '\\?',
	\ }

let s:has_conceal = has('conceal')
let s:bufnr_width = 3

" Keypad
let s:kprange = {
	\ 'Plus': '+',
	\ 'Minus': '-',
	\ 'Divide': '/',
	\ 'Multiply': '*',
	\ 'Point': '.',
	\ }

" Highlight groups
let s:hlgrps = {
	\ 'NoEntries': 'Error',
	\ 'Mode1': 'Character',
	\ 'Mode2': 'LineNr',
	\ 'Stats': 'Function',
	\ 'Match': 'Identifier',
	\ 'PrtBase': 'Comment',
	\ 'PrtText': 'Normal',
	\ 'PrtCursor': 'Constant',
	\ 'BufferNr':      'Constant',
	\ 'BufferInd':     'Normal',
	\ 'BufferHid':     'Comment',
	\ 'BufferHidMod':  'String',
	\ 'BufferVis':     'Normal',
	\ 'BufferVisMod':  'Identifier',
	\ 'BufferCur':     'Question',
	\ 'BufferCurMod':  'WarningMsg',
	\ 'BufferPath':    'Comment',
	\ }

" lname, sname of the basic(non-extension) modes
let s:types = ['fil', 'buf']
if !exists('g:lazysig_types')
	let g:lazysig_types = s:types
el
	call filter(g:lazysig_types, "index(['fil', 'buf'], v:val)!=-1")
en
let g:lazysig_builtins = len(g:lazysig_types)-1

let s:coretype_names = {
	\ 'fil' : 'files',
	\ 'buf' : 'buffers',
	\ }

let s:coretypes = map(copy(g:lazysig_types), '[s:coretype_names[v:val], v:val]')

" Get the options 
fu! s:opts(...)
	for each in ['extensions'] | if exists('s:'.each)
		let {each} = s:{each}
	en | endfo
	for [ke, va] in items(s:opts)
		let {va[0]} = exists(s:pref.ke) ? {s:pref.ke} : va[1]
	endfo
	unl va
	for [ke, va] in items(s:new_opts)
		let {va} = {exists(s:pref.ke) ? s:pref.ke : va}
	endfo
	unl va
	for [ke, va] in items(s:lc_opts)
		if exists(s:bpref.ke)
			unl {va}
			let {va} = {s:bpref.ke}
		en
	endfo
	" One-time values
	if a:0 && a:1 != {}
		unl va
		for [ke, va] in items(a:1)
			let opke = substitute(ke, '\(\w:\)\?lazysig_', '', '')
			if has_key(s:lc_opts, opke)
				let sva = s:lc_opts[opke]
				unl {sva}
				let {sva} = va
			en
		endfo
	en
	if !exists('g:lazysig_tilde_homedir') | let g:lazysig_tilde_homedir = 0 | en
	if !exists('g:lazysig_newcache') | let g:lazysig_newcache = 0 | en
	let s:maxdepth = min([s:maxdepth, 100])
	let s:glob = s:showhidden ? '.*\|*' : '*'
	let s:lash = lazysig#utils#lash()
	if s:keyloop
		let s:glbs['imd'] = 0
	en
	" Extensions
	if !( exists('extensions') && extensions == s:extensions )
		for each in s:extensions
			exe 'ru autoload/lazysig/'.each.'.vim'
		endfo
	en
endf

" * Open & Close 
fu! s:Open()
	cal s:log(1)
	cal s:getenv()
	cal s:execextvar('enter')
	sil! exe 'keepa' ( 'bo' ) '1new ControlP'
	let [s:bufnr, s:winw] = [bufnr('%'), winwidth(0)]
	let [s:focus, s:prompt] = [1, ['', '', '']]
	abc <buffer>
	if !exists('s:hstry')
		let hst = filereadable(s:gethistloc()[1]) ? s:gethistdata() : ['']
		let s:hstry = empty(hst) || !s:maxhst ? [''] : hst
	en
	for [ke, va] in items(s:glbs) | if exists('+'.ke)
		sil! exe 'let s:glb_'.ke.' = &'.ke.' | let &'.ke.' = '.string(va)
	en | endfo
	if s:opmul != '0' && has('signs')
		sign define lazysigmark text=+> texthl=FPromptMark
		hi def link FPromptMark Search
	en
	cal s:setupblank()
endf

fu! s:Close()
	if winnr('$') == 1
		bw!
	el
		try | bun!
		cat | clo! | endt
	en
	for key in keys(s:glbs) | if exists('+'.key)
		sil! exe 'let &'.key.' = s:glb_'.key
	en | endfo
	if exists('s:glb_acd') | let &acd = s:glb_acd | en
	let g:lazysig_lines = []
	if s:winres[1] >= &lines && s:winres[2] == winnr('$')
		exe s:winres[0].s:winres[0]
	en
	unl! s:focus s:hisidx s:hstgot s:statypes s:init s:savestr
		\ s:did_exp
	cal lazysig#recordhist()
	cal s:execextvar('exit')
	cal s:log(0)
	let v:errmsg = s:ermsg
	ec
endf

fu! s:Reset()
	cal call('s:opts', [])
	cal s:autocmds()
	cal lazysig#utils#opts()
	cal s:execextvar('opts')
endf

" --- achtung, failures here are silent.
fu! s:Render(lines)
    " --- ma = modifiable
	let [&ma, lines, s:lines_count] = [1, a:lines, len(a:lines)]
	let height = min([s:lines_count, s:winmaxh])
	let cur_cmd = 'keepj norm! gg1|'

	sil! exe '%d _ | res' height

	if empty(lines)
		let [s:matched, s:lines] = [[], []]
		let lines = []
		cal setline(1, s:add_offset(lines))
		setl noma nocul
		exe cur_cmd
		if s:dohighlight() | cal clearmatches() | en
		retu
	en
	let s:matched = copy(lines)
	let s:lines = copy(lines)
	cal setline(1, s:add_offset(lines))

    " --- cul: show cursor line.
    setl noma
" 	setl noma cul
	exe cur_cmd
endf

fu! s:Update()
	let lines = copy(g:lazysig_lines)
	cal s:Render(lines)
" 	return []
endf

fu! s:ForceUpdate()
	let pos = exists('*getcurpos') ? getcurpos() : getpos('.')
	sil! cal s:Update(escape(s:getinput(), '\'))
	cal setpos('.', pos)
endf

" --- execute and rebuild.
fu! s:BuildPrompt(upd)
	let base = '> '
    let s:matches = 3
    let s:did_exp = 'blah'
	if a:upd && ( s:matches || exists('s:did_exp')
		\ || str =~ '\(\\\(<\|>\)\|[*|]\)\|\(\\\:\([^:]\|\\:\)*$\)' )
        cal lazysig#setlines()
		sil! cal s:Update()
	en
    let &l:stl  = '  '
	" Toggling
	let [hiactive, hicursor, base] = s:focus
		\ ? ['FPromptPrtText', 'FPromptPrtCursor', base]
		\ : ['FPromptPrtBase', 'FPromptPrtBase', tr(base, '>', '-')]
	let hibase = 'FPromptPrtBase'
	" Build it
	redr
	let prt = copy(s:prompt)
	cal map(prt, 'escape(v:val, ''"\'')')
	exe 'echoh' hibase '| echon "'.base.'"
		\ | echoh' hiactive '| echon "'.prt[0].'"
		\ | echoh' hicursor '| echon "'.prt[1].'"
		\ | echoh' hiactive '| echon "'.prt[2].'" | echoh None'
	" Append the cursor at the end
	if empty(prt[1]) && s:focus
		exe 'echoh' hibase '| echon "_" | echoh None'
	en
endf

fu! s:PrtClear()
	if !s:focus | retu | en
	unl! s:hstgot
	let [s:prompt, s:matches] = [['', '', ''], 1]
	cal s:BuildPrompt(1)
endf

fu! s:PrtAdd(char)
	unl! s:hstgot
	let s:act_add = 1
	let s:prompt[0] .= a:char
	cal s:BuildPrompt(1)
	unl s:act_add
endf

fu! s:PrtBS()
	if !s:focus | retu | en
	if empty(s:prompt[0]) && s:brfprt != 0
		cal s:PrtExit()
		retu
	en
	unl! s:hstgot
	let [s:prompt[0], s:matches] = [substitute(s:prompt[0], '.$', '', ''), 1]
	cal s:BuildPrompt(1)
endf

fu! s:PrtDelete()
	if !s:focus | retu | en
	unl! s:hstgot
	let [prt, s:matches] = [s:prompt, 1]
	let prt[1] = matchstr(prt[2], '^.')
	let prt[2] = substitute(prt[2], '^.', '', '')
	cal s:BuildPrompt(1)
endf

fu! s:PrtDeleteWord()
	if !s:focus | retu | en
	unl! s:hstgot
	let [str, s:matches] = [s:prompt[0], 1]
	let str = str =~ '\W\w\+$' ? matchstr(str, '^.\+\W\ze\w\+$')
		\ : str =~ '\w\W\+$' ? matchstr(str, '^.\+\w\ze\W\+$')
		\ : str =~ '\s\+$' ? matchstr(str, '^.*\S\ze\s\+$')
		\ : str =~ '\v^(\S+|\s+)$' ? '' : str
	let s:prompt[0] = str
	cal s:BuildPrompt(1)
endf

fu! s:PrtCurLeft()
	if !s:focus | retu | en
	let prt = s:prompt
	if !empty(prt[0])
		let s:prompt = [substitute(prt[0], '.$', '', ''), matchstr(prt[0], '.$'),
			\ prt[1] . prt[2]]
	en
	cal s:BuildPrompt(0)
endf

fu! s:PrtCurRight()
	if !s:focus | retu | en
	let prt = s:prompt
	let s:prompt = [prt[0] . prt[1], matchstr(prt[2], '^.'),
		\ substitute(prt[2], '^.', '', '')]
	cal s:BuildPrompt(0)
endf

fu! s:PrtCurStart()
	if !s:focus | retu | en
	let str = join(s:prompt, '')
	let s:prompt = ['', matchstr(str, '^.'), substitute(str, '^.', '', '')]
	cal s:BuildPrompt(0)
endf

fu! s:PrtCurEnd()
	if !s:focus | retu | en
	let s:prompt = [join(s:prompt, ''), '', '']
	cal s:BuildPrompt(0)
endf

fu! s:PrtSelectMove(dir)
	let wht = winheight(0)
	let dirs = {'t': 'gg','b': 'G','j': 'j','k': 'k','u': wht.'k','d': wht.'j'}
	exe 'keepj norm!' dirs[a:dir]
	let pos = exists('*getcurpos') ? getcurpos() : getpos('.')
	cal s:BuildPrompt(0)
	cal setpos('.', pos)
endf

" Misc
fu! s:PrtFocusMap(char)
    if s:focus
        cal s:PrtAdd(a:char)
    en
endf

fu! s:PrtExit()
	let bw = bufwinnr('%')
	exe bufwinnr(s:bufnr).'winc w'
	if bufnr('%') == s:bufnr && bufname('%') == 'ControlP'
		noa cal s:Close()
		noa winc p
	els
		exe bw.'winc w'
	en
endf

fu! s:PrtHistory(...)
	if !s:focus || !s:maxhst | retu | en
	let [str, hst, s:matches] = [join(s:prompt, ''), s:hstry, 1]
	" Save to history if not saved before
	let [hst[0], hslen] = [exists('s:hstgot') ? hst[0] : str, len(hst)]
	let idx = exists('s:hisidx') ? s:hisidx + a:1 : a:1
	" Limit idx within 0 and hslen
	let idx = idx < 0 ? 0 : idx >= hslen ? hslen > 1 ? hslen - 1 : 0 : idx
	let s:prompt = [hst[idx], '', '']
	let [s:hisidx, s:hstgot, s:force] = [idx, 1, 1]
	cal s:BuildPrompt(1)
	unl s:force
endf

" * Mappings 
fu! s:MapNorms()
	if exists('s:nmapped') && s:nmapped == s:bufnr | retu | en
	let pcmd = "nn \<buffer> \<silent> \<k%s> :\<c-u>cal \<SID>%s(\"%s\")\<cr>"
	let cmd = substitute(pcmd, 'k%s', 'char-%d', '')
	let pfunc = 'PrtFocusMap'
	let ranges = [32, 33, 125, 126] + range(35, 91) + range(93, 123)
	for each in [34, 92, 124]
		exe printf(cmd, each, pfunc, escape(nr2char(each), '"|\'))
	endfo
	for each in ranges
		exe printf(cmd, each, pfunc, nr2char(each))
	endfo
	for each in range(0, 9)
		exe printf(pcmd, each, pfunc, each)
	endfo
	for [ke, va] in items(s:kprange)
		exe printf(pcmd, ke, pfunc, va)
	endfo
	let s:nmapped = s:bufnr
endf

fu! s:MapSpecs()
	if !( exists('s:smapped') && s:smapped == s:bufnr )
		" Correct arrow keys in terminal
		if ( has('termresponse') && v:termresponse =~ "\<ESC>" )
			\ || &term =~? '\vxterm|<k?vt|gnome|screen|linux|ansi|tmux|st(-[-a-z0-9]*)?$'
			for each in ['\A <up>','\B <down>','\C <right>','\D <left>']
				exe s:lcmap.' <esc>['.each
			endfo
		en
	en
	for [ke, va] in items(s:prtmaps) | for kp in va
		exe s:lcmap kp ':<c-u>cal <SID>'.ke.'<cr>'
	endfo | endfo
	let s:smapped = s:bufnr
endf

fu! s:KeyLoop()
	let [t_ve, guicursor] = [&t_ve, &guicursor]
	wh exists('s:init') && s:keyloop
		try
			set t_ve=
			if guicursor != ''
				set guicursor=a:NONE
			en
			let nr = getchar()
		fina
			let &t_ve = t_ve
			let &guicursor = guicursor
		endt
		let chr = !type(nr) ? nr2char(nr) : nr
		if nr >=# 0x20
			cal s:PrtFocusMap(chr)
		el
			let cmd = matchstr(maparg(chr), ':<C-U>\zs.\+\ze<CR>$')
			try
				exe ( cmd != '' ? cmd : 'norm '.chr )
			cat
			endt
		en
	endw
endf
" * Toggling 
fu! s:ToggleFocus()
	let s:focus = !s:focus
	cal s:BuildPrompt(0)
endf

fu! s:ToggleKeyLoop()
	let s:keyloop = !s:keyloop
	if exists('+imd')
        " --- imdisable.
		let &imd = !s:keyloop
	en
	if s:keyloop
        " --- update time for swap write and CursorHold au.
		let &ut = 0
		cal s:KeyLoop()
	elsei has_key(s:glbs, 'ut')
		let &ut = s:glbs['ut']
	en
endf

fu! s:PrtSwitcher()
	let [s:force, s:matches] = [1, 1]
	cal s:BuildPrompt(1)
	unl s:force
endf

fu! s:AcceptSelection()
"     cal s:Close()
    cal s:PrtExit()
    cal s:insertinsource(s:lines)

    let l:godown = s:lines_count - 1
    let l:l = repeat('j', l:godown)
    let l:e = l:godown ? 'normal '.l:l : ''

    if s:insert_mode | exe l:e | startinsert! | en

endf

fu! s:insertinsource(lines)
    let linenr = getpos('.')[1]
    if empty(a:lines) | retu | en

    let lines = copy(a:lines)
    let cur = getline(linenr)
    let lines[0] = cur . lines[0]
    cal setline(linenr, lines)
endf

fu! s:formatline(str)
	retu s:lineprefix.a:str
endf

fu! s:add_offset(lines)
	let s:offset = 0
	retu s:offset > 0 ? ( repeat([''], s:offset) + a:lines ) : a:lines
endf

fu! s:dircompl(be, sd)
	if a:sd == '' | retu [] | en
	if a:be == ''
		let [be, sd] = [s:dyncwd, a:sd]
	el
		let be = a:be.s:lash(a:be)
		let sd = be.a:sd
	en
	let dirs = split(globpath(s:fnesc(be, 'g', ','), a:sd.'*/'), "\n")
	if a:be == ''
		let dirs = lazysig#rmbasedir(dirs)
	en
	cal filter(dirs, '!match(v:val, escape(sd, ''~$.\''))'
		\ . ' && v:val !~ ''\v(^|[\/])\.{1,2}[\/]$''')
	retu dirs
endf

fu! s:findcommon(items, seed)
	let [items, id, cmn, ic] = [copy(a:items), strlen(a:seed), '', 0]
	cal map(items, 'strpart(v:val, id)')
	for char in split(items[0], '\zs')
		for item in items[1:]
			if item[ic] != char | let brk = 1 | brea | en
		endfo
		if exists('brk') | brea | en
		let cmn .= char
		let ic += 1
	endfo
	retu cmn
endf
" Misc 
fu! s:headntail(str)
	let parts = split(a:str, '[\/]\ze[^\/]\+[\/:]\?$')
	retu len(parts) == 1 ? ['', parts[0]] : len(parts) == 2 ? parts : []
endf

fu! s:lash(...)
	retu ( a:0 ? a:1 : s:dyncwd ) !~ '[\/]$' ? s:lash : ''
endf

fu! lazysig#rmbasedir(items)
	if a:items == []
		retu a:items
	en
	let cwd = s:dyncwd.s:lash()
	let first = a:items[0]
	if has('win32') || has('win64')
		let cwd = tr(cwd, '\', '/')
		let first = tr(first, '\', '/')
	en
	if !stridx(first, cwd)
		let idx = strlen(cwd)
		retu map(a:items, 'strpart(v:val, idx)')
	en
	retu a:items
endf
" Working directory 
fu! s:getparent(item)
	let parent = substitute(a:item, '[\/][^\/]\+[\/:]\?$', '', '')
	if parent == '' || parent !~ '[\/]'
		let parent .= s:lash
	en
	retu parent
endf

fu! lazysig#setdir(path, ...)
	let cmd = a:0 ? a:1 : 'lc!'
	sil! exe cmd s:fnesc(a:path, 'c')
	let [s:crfilerel, s:dyncwd] = [fnamemodify(s:crfile, ':.'), getcwd()]
endf
" Fallbacks 
fu! s:glbpath(...)
	retu call('lazysig#utils#globpath', a:000)
endf

fu! s:fnesc(...)
	retu call('lazysig#utils#fnesc', a:000)
endf

fu! lazysig#setlcdir()
	if exists('*haslocaldir')
		cal lazysig#setdir(getcwd(), haslocaldir() ? 'lc!' : 'cd!')
	en
endf
" Highlighting 
fu! lazysig#syntax()
	if lazysig#nosy() | retu | en
	for [ke, va] in items(s:hlgrps) | cal lazysig#hicheck('FPrompt'.ke, va) | endfo
	let bgColor=synIDattr(synIDtrans(hlID('Normal')), 'bg')
	if bgColor !~ '^-1$\|^$'
		sil! exe 'hi FPromptLinePre guifg='.bgColor.' ctermfg='.bgColor
	en
	if hlexists('FPromptLinePre')
		exe "sy match FPromptLinePre '^".escape(get(g:, 'lazysig_line_prefix', '>'),'^$.*~\')."'"
	en
endf

fu! s:highlight(pat, grp)
	if s:matcher != {} | retu | en
	cal clearmatches()
endf

fu! s:dohighlight()
	retu s:mathi[0] && exists('*clearmatches') && !lazysig#nosy()
endf
" Prompt history 
fu! s:gethistloc()
	let utilcadir = lazysig#utils#cachedir()
	let cache_dir = utilcadir.s:lash(utilcadir).'hist'
	retu [cache_dir, cache_dir.s:lash(cache_dir).'cache.txt']
endf

fu! s:gethistdata()
	retu lazysig#utils#readfile(s:gethistloc()[1])
endf

fu! lazysig#recordhist()
	let str = join(s:prompt, '')
	if empty(str) || !s:maxhst | retu | en
	let hst = s:hstry
	if len(hst) > 1 && hst[1] == str | retu | en
	cal extend(hst, [str], 1)
	if len(hst) > s:maxhst | cal remove(hst, s:maxhst, -1) | en
	cal lazysig#utils#writecache(hst, s:gethistloc()[0], s:gethistloc()[1])
endf

" Lists & Dictionaries 
fu! s:ifilter(list, str)
	let [rlist, estr] = [[], substitute(a:str, 'v:val', 'each', 'g')]
	for each in a:list
		try
			if eval(estr)
				cal add(rlist, each)
			en
		cat | con | endt
	endfo
	retu rlist
endf

fu! s:dictindex(dict, expr)
	for key in keys(a:dict)
		if a:dict[key] == a:expr | retu key | en
	endfo
	retu -1
endf

fu! s:vacantdict(dict)
	retu filter(range(1, max(keys(a:dict))), '!has_key(a:dict, v:val)')
endf

fu! s:sublist(l, s, e)
	retu v:version > 701 ? a:l[(a:s):(a:e)] : s:sublist7071(a:l, a:s, a:e)
endf

fu! s:sublist7071(l, s, e)
	let [newlist, id, ae] = [[], a:s, a:e == -1 ? len(a:l) - 1 : a:e]
	wh id <= ae
		cal add(newlist, get(a:l, id))
		let id += 1
	endw
	retu newlist
endf
" Buffers 
fu! s:buftab(bufnr, md)
	for tabnr in range(1, tabpagenr('$'))
		if tabpagenr() == tabnr && a:md == 't' | con | en
		let buflist = tabpagebuflist(tabnr)
		if index(buflist, a:bufnr) >= 0
			for winnr in range(1, tabpagewinnr(tabnr, '$'))
				if buflist[winnr - 1] == a:bufnr | retu [tabnr, winnr] | en
			endfo
		en
	endfo
	retu [0, 0]
endf

fu! s:bufwins(bufnr)
	let winns = 0
	for tabnr in range(1, tabpagenr('$'))
		let winns += count(tabpagebuflist(tabnr), a:bufnr)
	endfo
	retu winns
endf

fu! s:isabs(path)
	if (has('win32') || has('win64'))
		return a:path =~ '^\([a-zA-Z]:\)\{-}[/\\]'
	el
		return a:path =~ '^[/\\]'
	en
endf

fu! s:bufnrfilpath(line)
  if s:isabs(a:line) || a:line =~ '^\~[/\\]' || a:line =~ '^\w\+:\/\/'
		let filpath = a:line
	el
		let filpath = s:dyncwd.s:lash().a:line
	en
	let filpath = fnamemodify(filpath, ':p')
	let bufnr = bufnr('^'.filpath.'$')
	if (!filereadable(filpath) && bufnr < 1)
		if (a:line =~ '[\/]\?\[\d\+\*No Name\]$')
			let bufnr = str2nr(matchstr(a:line, '[\/]\?\[\zs\d\+\ze\*No Name\]$'))
			let filpath = bufnr
		els
			let bufnr = bufnr(a:line)
			retu [bufnr, a:line]
		en
	en
	retu [bufnr, filpath]
endf

fu! lazysig#normcmd(cmd, ...)
	let buftypes = [ 'quickfix', 'help' ]
	if a:0 < 2 && s:nosplit() | retu a:cmd | en
	let norwins = filter(range(1, winnr('$')),
		\ 'index(buftypes, getbufvar(winbufnr(v:val), "&bt")) == -1 || s:isneovimterminal(winbufnr(v:val))')
	for each in norwins
		let bufnr = winbufnr(each)
		if empty(bufname(bufnr)) && empty(getbufvar(bufnr, '&ft'))
			let fstemp = each | brea
		en
	endfo
	let norwin = empty(norwins) ? 0 : norwins[0]
	if norwin
		if index(norwins, winnr()) < 0
			exe ( exists('fstemp') ? fstemp : norwin ).'winc w'
		en
		retu a:cmd
	en
	retu a:0 ? a:1 : 'bo vne'
endf

fu! lazysig#modfilecond(w)
	retu &mod && !&hid && &bh != 'hide' && s:bufwins(bufnr('%')) == 1 && !&cf &&
		\ ( ( !&awa && a:w ) || filewritable(fnamemodify(bufname('%'), ':p')) != 1 )
endf

fu! s:nosplit()
	retu !empty(s:nosplit) && match([bufname('%'), &l:ft, &l:bt], s:nosplit) >= 0
endf

fu! s:setupblank()
	setl noswf nonu nobl nowrap nolist nospell nocuc wfh
	setl fdc=0 fdl=99 tw=0 bt=nofile bh=unload
	if v:version > 702
		setl nornu noudf cc=0
	en
	if s:has_conceal
		setl cole=2 cocu=nc
	en
endf

fu! s:leavepre()
	if exists('s:bufnr') && s:bufnr == bufnr('%') | bw! | en
endf

fu! s:checkbuf()
	if !exists('s:init') && exists('s:bufnr') && s:bufnr > 0
		exe s:bufnr.'bw!'
	en
endf

fu! s:iscmdwin()
	let [ermsg, v:errmsg] = [v:errmsg, '']
	sil! noa winc p
	sil! noa winc p
	let [v:errmsg, ermsg] = [ermsg, v:errmsg]
	retu ermsg =~ '^E11:'
endf

fu! s:insertstr()
	let str = 'Insert: c[w]ord/c[f]ile/[s]earch/[v]isual/[c]lipboard/[r]egister? '
	retu s:choices(str, ['w', 'f', 's', 'v', 'c', 'r'], 's:insertstr', [])
endf

fu! s:textdialog(str)
	redr | echoh MoreMsg | echon a:str | echoh None
	retu nr2char(getchar())
endf

fu! s:choices(str, choices, func, args)
	let char = s:textdialog(a:str)
	if index(a:choices, char) >= 0
		retu char
	elsei char =~# "\\v\<Esc>|\<C-c>|\<C-g>|\<C-u>|\<C-w>|\<C-[>"
		cal s:BuildPrompt(0)
		retu 'cancel'
	elsei char =~# "\<CR>" && a:args != []
		retu a:args[0]
	en
	retu call(a:func, a:args)
endf

fu! s:getregs()
	let char = s:textdialog('Insert from register: ')
	if char =~# "\\v\<Esc>|\<C-c>|\<C-g>|\<C-u>|\<C-w>|\<C-[>"
		cal s:BuildPrompt(0)
		retu -1
	elsei char =~# "\<CR>"
		retu s:getregs()
	en
	retu s:regisfilter(char)
endf

fu! s:regisfilter(reg)
	retu substitute(getreg(a:reg), "[\t\n]", ' ', 'g')
endf
" Misc 
fu! s:modevar()
	let s:matchtype = s:mtype()
endf

fu! s:getinput(...)
	let [prt, spi] = [s:prompt, ( a:0 ? a:1 : '' )]
	if s:abbrev != {}
		let gmd = has_key(s:abbrev, 'gmode') ? s:abbrev['gmode'] : ''
		let str = ( gmd =~ 't' && !a:0 ) || spi == 'c' ? prt[0] : join(prt, '')
		if gmd =~ 't' && gmd =~ 'k' && !a:0 && matchstr(str, '.$') =~ '\k'
			retu join(prt, '')
		en
		let [pf, rz] = ['p', 'z']
		for dict in s:abbrev['abbrevs']
			let dmd = has_key(dict, 'mode') ? dict['mode'] : ''
			let pat = escape(dict['pattern'], '~')
			if ( dmd == '' || ( dmd =~ pf && dmd =~ rz && !a:0 )
				\ || dmd =~ '['.spi.']' ) && str =~ pat
				let [str, s:did_exp] = [join(split(str, pat, 1), dict['expanded']), 1]
			en
		endfo
		if gmd =~ 't' && !a:0
			let prt[0] = str
		el
			retu str
		en
	en
	retu spi == 'c' ? prt[0] : join(prt, '')
endf

fu! s:strwidth(str)
	retu exists('*strdisplaywidth') ? strdisplaywidth(a:str) : strlen(a:str)
endf

fu! lazysig#j2l(nr)
	exe 'norm!' a:nr.'G'
	sil! norm! zvzz
endf

fu! s:maxf(len)
	retu s:maxfiles && a:len > s:maxfiles
endf

fu! s:walker(m, p, d)
	retu a:d >= 0 ? a:p < a:m ? a:p + a:d : 0 : a:p > 0 ? a:p + a:d : a:m
endf

fu! s:delbufcond(bufnr)
	retu getbufvar(a:bufnr, "&mod") || a:bufnr == s:crbufnr
endf

fu! s:isneovimterminal(buf)
	retu has('nvim') && getbufvar(a:buf, "&bt") == "terminal"
endf
" Entering & Exiting 
fu! s:getenv()
	let [s:cwd, s:winres] = [getcwd(), [winrestcmd(), &lines, winnr('$')]]
	let [s:crword, s:crnbword] = [expand('<cword>', 1), expand('<cWORD>', 1)]
	let [s:crgfile, s:crline] = [expand('<cfile>', 1), getline('.')]
	let [s:winmaxh, s:crcursor] = [&lines, getpos('.')]
	let [s:crbufnr] = [bufnr('%')]
	let s:crfile = bufname('%') == ''
		\ ? '['.s:crbufnr.'*No Name]' : expand('%:p', 1)
	let s:crfpath = expand('%:p:h', 1)
endf

fu! s:log(m)
	if exists('g:lazysig_log') && g:lazysig_log | if a:m
		let cadir = lazysig#utils#cachedir()
		let apd = g:lazysig_log > 1 ? '>' : ''
		sil! exe 'redi! >'.apd cadir.s:lash(cadir).'lazysig.log'
	el
		sil! redi END
	en | en
endf

" Extensions 
fu! s:mtype()
	retu s:itemtype >= len(s:coretypes) ? s:getextvar('type') : 'path'
endf

fu! s:execextvar(key)
	if !empty(g:lazysig_ext_vars)
		cal map(filter(copy(g:lazysig_ext_vars),
			\ 'has_key(v:val, a:key)'), 'eval(v:val[a:key])')
	en
endf

fu! s:getextvar(key)
	if s:itemtype >= len(s:coretypes) && len(g:lazysig_ext_vars) > 0
		let vars = g:lazysig_ext_vars[s:itemtype - len(s:coretypes)]
		if has_key(vars, a:key)
			retu vars[a:key]
		en
	en
	retu get(g:, 'lazysig_' . s:matchtype . '_' . a:key, -1)
endf

fu! lazysig#exit()
	cal s:PrtExit()
endf

fu! lazysig#prtclear()
	cal s:PrtClear()
endf

fu! lazysig#nosy()
	retu !( has('syntax') && exists('g:syntax_on') )
endf

fu! lazysig#hicheck(grp, defgrp)
	if !hlexists(a:grp)
		exe 'hi link' a:grp a:defgrp
	en
endf

fu! lazysig#call(func, ...)
	retu call(a:func, a:000)
endf

fu! lazysig#getvar(var)
	retu {a:var}
endf

" --- public because used to be called by extensions.
fu! lazysig#setlines()
    let lines = s:executequery()
	let s:itemtype = 0
	cal s:modevar()
	let g:lazysig_lines = lines
endf

fu! s:executequery()
    let prompt = s:prompt[0]
    if prompt == '' | retu [] | en
    let killerr = s:debug ? '' : ' 2>/dev/null'
    let cmd = shellescape(s:parserbin).l:killerr
    sil let res = systemlist(cmd, prompt) " --- stdin.
    if empty(res) | retu ['✘'] | el | retu res | en
endf

" Returns [lname, sname]
fu! s:CurTypeName()
    return filter(copy(s:coretypes), 'v:val[1]==g:lazysig_types[s:itemtype]')[0]
endfu

fu! lazysig#init(...)
    let opts = a:0 ? a:1 : {'insert_mode': 0}
    let s:insert_mode = opts['insert_mode']
	if exists('s:init') || s:iscmdwin() | retu | en
	let [s:ermsg, v:errmsg] = [v:errmsg, '']
	let [s:matches, s:init] = [1, 1]
	cal s:Reset()
	noa cal s:Open()
	cal s:MapNorms()
	cal s:MapSpecs()
	if empty(g:lazysig_types) && empty(g:lazysig_ext_vars)
		call lazysig#exit()
		retu
	en
	cal lazysig#setlines()
	cal lazysig#syntax()
	let curName = s:CurTypeName()
	cal s:BuildPrompt(1)
	if s:keyloop | cal s:KeyLoop() | en
	return 1
endf
" - Autocmds 
if has('autocmd')
	aug FPromptAug
		au!
		au BufEnter ControlP cal s:checkbuf()
		au BufLeave ControlP noa cal s:Close()
		au VimLeavePre * cal s:leavepre()
	aug END
en

fu! s:autocmds()
	if !has('autocmd') | retu | en
endf
