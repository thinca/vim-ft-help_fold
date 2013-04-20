" Folding setting for help.
" Version: 1.0
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

setlocal foldmethod=expr foldexpr=HelpFold(v:lnum)
setlocal foldtext=HelpFoldText()

if exists('b:undo_ftplugin')
  let b:undo_ftplugin .= ' | '
else
  let b:undo_ftplugin = ''
endif
let b:undo_ftplugin .= 'setl fdm< fde< fdt<'


if exists('*HelpFold')
  finish
endif

function! HelpFold(lnum)
  let line = getline(a:lnum)
  let next = getline(a:lnum + 1)
  let prev = getline(a:lnum - 1)
  if line =~# '^=\{78}$'
    return 1
  elseif next =~# '^=\{78,}$'
    return '<1'
  elseif line =~# '^-\{78,}$'
    return 2
  elseif next =~# '^-\{78,}$'
    return '<2'
  elseif s:is_tag_line(line) && !s:is_tag_line(prev) && prev !~# '\v^(\S)\1+$'
    return 3
  elseif s:is_tag_line(next) && !s:is_tag_line(line)
    return '<3'
  endif
  return '='
endfunction

function! HelpFoldText()
  let base = matchstr(foldtext(), '^.\{-}:')

  let tags_pat = '\%(\s*\*\S\+\*\)\+$'
  let lnum = v:foldstart
  let line = s:getline(lnum)
  while line =~# '^\(.\)\1\+$'
    let lnum += 1
    let line = s:getline(lnum)
  endwhile
  let tags = []
  while line =~# '^' . tags_pat
    let tags += split(line, '\s\+')
    let lnum += 1
    let line = s:getline(lnum)
  endwhile
  let line = s:getline(lnum)

  if line =~# tags_pat
    let match_pat = '^\(.\{-}\)\s*\(' . tags_pat . '\)$'
    let [line, tail] = matchlist(line, match_pat)[1 : 2]
    let tags += split(tail, '\s\+')
  endif

  if !empty(tags)
    if line =~# '^\S.*\t'
      let line = matchstr(line, '^[^\t]\+')
    endif
    let line = substitute(line, '\t\+', '  ', 'g')
    let limit = &l:textwidth != 0 ? &l:textwidth : 78
    let tags_text = ' ' . join(tags, ' ')
    let base_width = strdisplaywidth(base)
    let tags_width = strdisplaywidth(tags_text)
    let spaces = limit - (base_width + strdisplaywidth(line) + tags_width)
    if spaces < 0
      let line_limit = limit - base_width - tags_width
      let line = s:truncate(line, line_limit, '...')
      let spaces = 0
    endif
    let line = line . repeat(' ', spaces) . tags_text
  endif
  return base . line
endfunction

function! s:is_tag_line(line)
  return a:line =~# '\*\S\+\*$'
endfunction

function! s:getline(lnum)
  return substitute(getline(a:lnum), '^<', '', '')
endfunction

function! s:truncate(str, width, tail)
  let limit = a:width - strwidth(a:tail)
  if a:str =~# '^[\x00-\x7f]*$'
    return len(a:str) < limit ? printf('%-' . limit . 's', a:str)
    \                         : strpart(a:str, 0, limit) . a:tail
  endif

  let ret = a:str
  let width = strwidth(a:str)
  if width > limit
    let ret = s:strwidthpart(ret, limit) . a:tail
    let width = strwidth(ret)
  endif

  if width < a:width
    let ret .= repeat(' ', a:width - width)
  endif

  return ret
endfunction

function! s:strwidthpart(str, width)
  if a:width <= 0
    return ''
  endif
  let ret = a:str
  let width = strwidth(a:str)
  while width > a:width
    let char = matchstr(ret, '.$')
    let ret = ret[: -1 - len(char)]
    let width -= strwidth(char)
  endwhile

  return ret
endfunction
