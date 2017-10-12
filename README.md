# lazysig.vim

Vim plugin for lazysig

# Installation

# parser binary

You will need to compile the parser, for which you will need a working ghc
(and perhaps cabal).

You will also need the Text.ParserCombinators.Parsec module.

On debian you can get it via libghc-parsec3-dev.

Or else you can do `cabal install parsec`.

Then:

    cd <plugin directory> # e.g. ~/.vim/bundle/lazysig.vim
    lazysig/bin/build-parser

# plugin

In normal / insert mode, try 'Leader key + ]' or 'Control-]' respectively to
bring up the prompt.

If all is properly installed, typing `i i i` in the prompt will show `Int -> Int -> Int`.

You can override the default keyboard mappings using:

    let g:lazysig_map = '<Leader>]'
    let g:lazysig_imap = '<c-]>'
