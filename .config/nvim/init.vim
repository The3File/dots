" vim: fdm=marker
" Plugins
call plug#begin('~/.config/nvim/plugged')
call plug#begin()
Plug 'ap/vim-css-color'
Plug 'rrethy/vim-hexokinase', { 'do': 'make hexokinase' }
Plug 'junegunn/goyo.vim'
Plug 'junegunn/limelight.vim'
Plug 'lervag/vimtex'
"Plug 'dylanaraps/wal.vim'
Plug 'AlphaTechnolog/pywal.nvim', { 'as': 'pywal' }
Plug 'gioele/vim-autoswap'
Plug 'sheerun/vim-polyglot'
Plug 'neomake/neomake'
Plug 'kovetskiy/sxhkd-vim'
Plug 'plasticboy/vim-markdown'
Plug 'udalov/kotlin-vim'
Plug 'itchyny/lightline.vim'
Plug 'itchyny/vim-gitbranch'
Plug 'chrisbra/Colorizer'
Plug 'tanvirtin/monokai.nvim'
Plug 'ellisonleao/gruvbox.nvim'
Plug 'xiyaowong/transparent.nvim'
"Plug 'jamespwilliams/bat.vim'
"Plug 'gabrielelana/vim-markdown'
"Plug '<++>'
call plug#end()
" Options
"
filetype plugin indent on
syntax enable
set title titlestring=nvim
set clipboard=unnamedplus
set nohlsearch
set number
set relativenumber
set linebreak
set autoindent
set smartindent
"set noexpandtab
autocmd BufNewFile,BufRead * set noexpandtab
set tabstop=3
set shiftwidth=3
set grepprg=grep\ -nH\ $*
set nofoldenable

colorscheme pywal
"colorscheme zellner
"colorscheme default
"colorscheme gruvbox
"colorscheme delek

"autocmd BufNewFile,BufRead *.{md,mdwn,mkd,mkdn,mark*} set filetype=markdown
autocmd BufNewFile,BufRead *.bulkrename set filetype=bulkrename
autocmd BufNewFile,BufRead *.bulkrename source ~/.config/nvim/after/syntax/br.vim
" Bindings

" GLOBAL

inoremap <C-Space> <ESC>/<++><Enter>"_c4l
nnoremap <C-Space> <ESC>/<++><Enter>"_c4l

nnoremap ,n :next<CR>
nnoremap ,p :previous<CR>
nnoremap ;s" ciW""<esc>P
vnoremap ;s" c""<esc>P

"nnoremap ;s<++> ciW<++><esc>P
" BASH

autocmd FileType sh nnoremap ,c :!shellcheck %<CR>
autocmd FileType sh nnoremap ,f i<CR>(){<CR>}<CR><ESC>2ki
autocmd FileType sh inoremap ;e printf '' "<++>"<ESC>F'i

" LATEX

autocmd FileType tex nnoremap mp :w<CR>:! mdtopdf -t %<CR><CR>
"autocmd FileType tex nnoremap mp :w<CR>:! pdflatex -shell-escape %<CR>
autocmd FileType tex nnoremap md :w<CR>:! mdtopdf -d %<CR><CR>
autocmd FileType tex nnoremap mo :! mdtopdf -o %<CR><CR>
autocmd FileType tex nnoremap ;S i\section{}<CR><CR><++><ESC>2kf}i
autocmd FileType tex nnoremap ;s i\subsection{}<CR><CR><++><ESC>2kf}i
autocmd FileType tex inoremap ;i <ESC>o\item<Space>
autocmd FileType tex nnoremap ;b i\begin{}<CR>\end{}<ESC>kf}i
autocmd FileType tex nnoremap ;e i\begin{enumerate}<CR>\item <++><CR>\end{enumerate}<ESC>2k0f=a
autocmd FileType tex nnoremap ;a i\begin{enumerate}[label=\textbf{\alph*)}]<CR>\end{enumerate}<ESC>O\item 
autocmd FileType tex nnoremap ;i o\begin{itemize}<CR>\end{itemize}<ESC>O\item 
autocmd FileType tex nnoremap ;t i\begin{table}[h]<CR>\centering<CR>\setlength{\tabcolsep}{1.0em}<CR>\renewcommand{\arraystretch}{1.5}<CR>\begin{tabular}{}<CR>\end{tabular}<CR>\end{table}<ESC>
autocmd FileType tex inoremap ;r \ref{}<++><ESC>T{i

autocmd FileType tex inoremap ;m \[\]<ESC>hi
autocmd FileType tex inoremap $$ $$<++><ESC>F$i
autocmd FileType tex inoremap __ _{}<++><ESC>F}i
autocmd FileType tex inoremap ;lr \Leftrightarrow
autocmd FileType tex inoremap ;e \begin{equation}<ESC>o\end{equation}<ESC>O\label{eq:<++>}<ESC>o
autocmd FileType tex inoremap ;E \begin{align}<ESC>o\end{align}<ESC>O\label{eq:<++>}<ESC>o
autocmd FileType tex inoremap ;a \begin{align*}<ESC>o\end{align*}<ESC>O
autocmd FileType tex inoremap ;t \cdot
autocmd FileType tex inoremap ;d \div
autocmd FileType tex inoremap ;f \frac{}{<++>}<++><ESC>Fcf}i
autocmd FileType tex inoremap ;s \sqrt{}<++><ESC>Ftf}i

" GNUPLOT

autocmd FileType tex nnoremap ;g i\begin{figure}[h!]<Enter>\caption{<++>}<Enter>\label{fig:<++>}<ENTER>\begin{gnuplot}[terminal=epslatex]<CR>set key box top left<CR>set size 1.1,1.0<CR>set tics out<CR>set grid ytics mytics<CR>set grid xtics mytics<CR>set mytics 1<CR>set grid<CR><CR>set yr [<++>:<++>]<CR>set xr [<++>:<++>]<CR><CR>plot <++> w l title '<++>'<CR><CR>\end{gnuplot}<ENTER>\end{figure}<ESC>17k/<+*+><Enter>"_c4l

" MARKDOWN

" surrounding
autocmd FileType markdown nnoremap ;s* ciW**<esc>P

" math
autocmd FileType markdown inoremap ;m $$$$<++><ESC>5hi
autocmd FileType markdown inoremap ;f \frac{}{<++>}<++><ESC>Fcf}i
autocmd FileType markdown inoremap ;t \times
autocmd FileType markdown inoremap ;s \sqrt{}<++><ESC>Ftf}i
autocmd FileType markdown inoremap $$ $$<++><ESC>F$i
autocmd FileType markdown nnoremap mo :w<CR>:! mdtopdf -o %<CR><CR>
autocmd FileType markdown nnoremap mp :w<CR>:! mdtopdf %<CR><CR>
autocmd FileType markdown nnoremap md :w<CR>:! mdtopdf -d %<CR><CR>

" HTML
autocmd FileType html inoremap ;html <!DOCTYPE html><ENTER><html><ENTER><head><ENTER><title><++></title><ENTER></head><ENTER><body><ENTER><++><ENTER></body><ENTER></html><ESC>gg
autocmd FileType html inoremap ;ln <link rel="stylesheet" type="text/css" href=""><ESC>hi
autocmd FileType html inoremap ;id <div id=""><++></div><ESC>F"i
autocmd FileType html inoremap ;cl <div class=""><++></div><ESC>F"i
autocmd FileType html inoremap ;bo <b></b><Space><++><Esc>FbT>i
autocmd FileType html inoremap ;br <br>
autocmd FileType html inoremap ;it <em></em><Space><++><Esc>FeT>i
autocmd FileType html inoremap ;1 <h1></h1><Enter><Enter><++><Esc>2kf<i
autocmd FileType html inoremap ;2 <h2></h2><Enter><Enter><++><Esc>2kf<i
autocmd FileType html inoremap ;3 <h3></h3><Enter><Enter><++><Esc>2kf<i
autocmd FileType html inoremap ;p <p></p><Enter><Enter><++><Esc>02kf>a
autocmd FileType html inoremap ;a <a<Space>href=""><++></a><Space><++><Esc>14hi
autocmd FileType html inoremap ;e <a<Space>target="_blank"<Space>href=""><++></a><Space><++><Esc>14hi
autocmd FileType html inoremap ;ul <ul><Enter><li></li><Enter></ul><Enter><Enter><++><Esc>03kf<i
autocmd FileType html inoremap ;li <Esc>o<li></li><Esc>F>a
autocmd FileType html inoremap ;ol <ol><Enter><li></li><Enter></ol><Enter><Enter><++><Esc>03kf<i
autocmd FileType html inoremap ;im <img src="" alt="<++>"><++><esc>Fcf"a
autocmd FileType html inoremap ;td <td></td><++><Esc>Fdcit
autocmd FileType html inoremap ;tr <tr></tr><Enter><++><Esc>kf<i
autocmd FileType html inoremap ;th <th></th><++><Esc>Fhcit
autocmd FileType html inoremap ;tab <table><Enter></table><Esc>O
autocmd FileType html inoremap ;dt <dt></dt><Enter><dd><++></dd><Enter><++><esc>2kcit
autocmd FileType html inoremap ;dl <dl><Enter><Enter></dl><enter><enter><++><esc>3kcc

" Plugins
let g:Hexokinase_highlighters = ['foregroundfull']
"VimTex
   let g:tex_flavor = 'latex'
   let g:vimtex_view_method = 'mupdf'
   let g:vimtex_fold_enabled = 0
   let g:vimtex_fold_types = {
	 \ 'comments' : {},
	 \}
"NeoVim Airline
   let g:airline_theme='fairyfloss'
   let g:airline_powerline_fonts = 1

"Goyo
   nnoremap gf :!bspc node -t ~fullscreen<CR><CR>:G<ENTER>
   nnoremap g<ESC> :G<CR>:<ESC>:<BACKSPACE>
   
   let g:goyo_width = 100
   let g:goyo_margin_top = 0
   let g:goyo_margin_bottom = 0

autocmd! User GoyoEnter nested call <SID>goyo_enter()
" Goyo enter
function! s:goyo_enter()
   "silent ![[ $TERM =~ "screen" ]] && tmux set status off
   "silent ![[ $TERM =~ "screen" ]] && tmux list-panes -F '\#F' | grep -q Z || tm
   set noshowmode
   set noshowcmd
   "set scrolloff=999
   "Limelight
endfunction
autocmd! User GoyoLeave nested call <SID>goyo_leave()"
" Goyo leave
function! s:goyo_leave()
   "silent !tmux set status on
   "silent !tmux list-panes -F '\#F' | grep -q Z && tm
   set showmode
   set showcmd
   "set scrolloff=5
   "Limelight!
endfunction"
 
"LimeLight
let g:limelight_conceal_ctermfg = 'gray'
let g:limelight_conceal_ctermfg = 240
let g:limelight_priority = -1
let g:limelight_default_coefficient = 1.7
let g:is_bash = 1

"Lightline
let g:lightline = {
      \ 'colorscheme': 'powerline',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'gitbranch', 'readonly', 'filename', 'modified' ] ]
      \ },
      \ 'component_function': {
      \   'gitbranch': 'gitbranch#name'
      \ },
      \ }
