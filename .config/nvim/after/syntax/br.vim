" Vim syntax file
" Language:		configure.in script: M4 with sh
" Former Maintainer:	Christian Hammesr <ch@lathspell.westend.com>
" Last Change:	2018 Feb 03
" 				(patch from Yngve Inntjore Levinsen to detect AC_MSG)
" 				(patch from Khym Chanur to add @Spell)
" 				(patch from James McCoy to fix paren matching)

" Well, I actually even do not know much about m4. This explains why there
" is probably very much missing here, yet !
" But I missed good highlighting when editing my GNU autoconf/automake
" script, so I wrote this quick and dirty patch.


" quit when a syntax file was already loaded
if exists("b:current_syntax")
  finish
endif

" define the config syntax
set conceallevel=2
"syn match Directory /d.*/
"syn match Special /x.*/
"syn match xString /f.*/
syntax region Directory start=/d / end=/$/ concealends
syntax region Special start=/x / end=/$/ concealends
syntax region String start=/f / end=/$/ concealends
"syntax region h start=/^/ end=/ / conceal


let b:current_syntax = "bulkrename"

" vim: ts=4
