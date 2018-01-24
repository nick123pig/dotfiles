syntax enable
set background=dark
colorscheme cobalt

set runtimepath^=~/.vim/bundle/ctrlp.vim

"set number
set relativenumber
set cursorline

" Make tabs 2 spaces
set smartindent
inoremap # X#
set softtabstop=2
set shiftwidth=2
set expandtab

" Highlight search results
set hlsearch

" Status bar settings
set laststatus=2                             " always show statusbar  
set statusline=  
set statusline+=%-10.3n\                     " buffer number  
set statusline+=%f\                          " filename   
set statusline+=%h%m%r%w                     " status flags  
set statusline+=\[%{strlen(&ft)?&ft:'none'}] " file type  
set statusline+=%-14(%l,%c%V%)               " line, character  
set statusline+=%<%P                         " file position

" Disable bell
set noerrorbells 
set novisualbell
set t_vb=
autocmd! GUIEnter * set vb t_vb=

" Treat .md like .markdown
au BufRead,BufNewFile *.md set filetype=markdown

" Add support for typescript
set runtimepath^=~/.vim/bundle/typescript-vim
au BufRead,BufNewFile *.ts set filetype=typescript

autocmd Filetype html setlocal ts=4 sw=4 expandtab
autocmd Filetype typescript setlocal ts=4 sw=4 expandtab
