" Minimal syntax highlighting for cligen/clixon CLI spec files (*.cli)
" ex: tabstop=8 shiftwidth=4 softtabstop=4

if exists("b:current_syntax")
    finish
endif

syn region cligenComment start="^\s*#" end="$" contains=@Spell
syn region cligenString start=+"+ skip=+\\"+ end=+"+
syn region cligenVar start="<" end=">" contains=cligenVarType
syn match cligenVarType contained ":[a-zA-Z0-9_]\+"
syn match cligenKeyword contained "\<CLICON_[A-Z_]\+\>"
syn region cligenMeta start="CLICON_" end="=" contains=cligenKeyword

" cligen callbacks used by TNSR (tnsr_cli_*) and common clixon functions
syn match cligenFunc "\<[a-zA-Z_][a-zA-Z0-9_]*_cli_[a-z_]\+\ze("
syn match cligenFunc "\<CLICON_MODE\|CLICON_PLUGIN\|CLICON_HOOK\|CLICON_VALIDATE\>"
syn keyword cligenStmt no set enable disable
syn match cligenNumber "\<[0-9]\+\>"
syn match cligenRange /range\[[0-9:]*\]/

hi def link cligenComment Comment
hi def link cligenString String
hi def link cligenVar Identifier
hi def link cligenVarType Type
hi def link cligenKeyword PreProc
hi def link cligenFunc Function
hi def link cligenStmt Statement
hi def link cligenNumber Number
hi def link cligenRange Number

setlocal matchpairs+=<:>

let b:current_syntax = "cligen"
