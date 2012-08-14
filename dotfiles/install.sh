#!/usr/bin/zsh

# get the dotfiles.
cp -r dotfiles/.* ~/

# clone out all these bundles
cd ~/.vim/bundle
git clone git@github.com:nwertzberger/javacomplete.git
git clone git@github.com:nwertzberger/syntastic.git
git clone git@github.com:nwertzberger/snipmate.vim.git
git clone https://github.com/kien/ctrlp.vim.git
git clone https://github.com/scrooloose/nerdtree.git
git clone https://github.com/altercation/vim-colors-solarized.git


