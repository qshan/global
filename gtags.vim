" File: gtags.vim
" Author: Tama Communications Corporation
" Version: 0.3
" Last Modified: Mar 5, 2008
"
" Copyright and lisence
" ---------------------
" Copyright (c) 2004, 2008 Tama Communications Corporation
"
" This file is part of GNU GLOBAL.
"
" This program is free software: you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation, either version 3 of the License, or
" (at your option) any later version.
" 
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
" 
" You should have received a copy of the GNU General Public License
" along with this program.  If not, see <http://www.gnu.org/licenses/>.
"
" Overview
" --------
" The gtags.vim plugin script integrates the GNU GLOBAL source code tag system
" with Vim. About the details, see http://www.gnu.org/software/global/.
"
" Installation
" ------------
" Drop the file in your plugin directory or source it from your vimrc.
" To use this script, you need the GNU GLOBAL-5.6.3 or later installed
" in your machine.
"
" Usage
" -----
" First of all, you must execute gtags(1) at the root of source directory
" to make tag files. Assuming that your source directory is '/var/src',
" it is neccessary to execute the following commands.
"
"	$ cd /var/src
"	$ gtags
"
" And you will find four tag files in the directory.
"
" General form of Gtags command is as follows:
"
"	:Gtags [option] pattern
"
" To go to func, you can say
"
"       :Gtags func
"
" Input completion is available. If you forgot function name but recall
" only some characters of the head, please input them and press <TAB> key.
"
"       :Gtags fu<TAB>
"       :Gtags func			<- Vim will append 'nc'.
"
" If you omitted argument, vim ask it like this:
"
"       Gtags for pattern: <current token>
"
" Vim execute `global -x main', parse the output, list located
" objects in quickfix window and load the first entry.  The quickfix
" windows is like this:
"
"      gozilla/gozilla.c|200| main(int argc, char **argv)
"      gtags-cscope/gtags-cscope.c|124| main(int argc, char **argv)
"      gtags-parser/asm_scan.c|2056| int main()
"      gtags-parser/gctags.c|157| main(int argc, char **argv)
"      gtags-parser/php.c|2116| int main()
"      gtags/gtags.c|152| main(int argc, char **argv)
"      [Quickfix List]
"
" You can go to any entry using quickfix command.
"
" :cn'
"      go to the next entry.
"
" :cp'
"      go to the previous entry.
"
" :ccN'
"      go to the N'th entry.
"
" :cl'
"      list all entries.
"
" You can see the help of quickfix like this:
"
"          :h quickfix
"
" Suggested map:
"       map <C-n> :cn<CR>
"       map <C-p> :cp<CR>
"
" You can use POSIX regular expression too. It requires more execution time though.
"
"       :Gtags ^[sg]et_
"
" It will match to both of 'set_value' and 'get_value'.
"
" To go to the referenced point of func, add -r option.
"
"       :Gtags -r func
"
" To go to any symbols which are not defined in GTAGS, try this.
"
"       :Gtags -s func
"
" To go to any string other than symbol, try this.
"
"       :Gtags -g ^[sg]et_
"
" This command accomplishes the same function as grep(1) but is more convenient
" because it retrieves the entire directory structure.
"
" To get list of objects in a file 'main.c', use -f command.
"
"       :Gtags -f main.c
"
" If you are editing `main.c' itself, you can use '%' instead.
"
"       :Gtags -f %
"
" You can browse project files whose path includes specified pattern.
" For example:
"
"       :Gtags -P /vm/			<- all files under 'vm' directory.
"       :Gtags -P \.h$			<- all include files.
"	:Gtags -P init			<- all paths includes 'init'
"
" If you omitted the argument and input only <ENTER> key to the prompt,
" vim shows list of all files in your project.
"
" You can use all options of global(1) except for the -c, -p, -u and
" all long name options. They are sent to global(1) as is.
" For example, if you want to ignore case distinctions in pattern.
"
"       :Gtags -gi paTtern
"
" It will match to both of 'PATTERN' and 'pattern'.
"
" If you want to search a pattern which starts with a hyphen like '-C'
" then you can use the -e option like grep(1).
"
"	:Gtags -ge -C
"
" By default, Gtags command search only in source files. If you want to
" search in both source files and text files, or only in text files then
"
"	:Gtags -go pattern		# both source and text
"	:Gtags -gO pattern		# only text file
"
" See global(1) for other options.
"
" The GtagsCursor command brings you to the definition or reference of
" the current token.
"
"       :GtagsCursor
"
" Suggested map:
"       map <C-]> :GtagsCursor<CR>
"
" If you have the hypertext generated by htags(1) then you can display
" the same place on mozilla browser. Let's load mozilla and try this:
"
"       :Gozilla
"
" Suggested map:
"       map <C-g> :Gozilla<CR>
"
" If you want to load vim with all main()s then following command line is useful.
"
"	% vim '+Gtags main'
"
" Also see the chapter of 'vim editor' of the online manual of GLOBAL.
"
"	% info global
"
if exists("loaded_gtags") || &cp
    finish
endif
let loaded_gtags = 1

" Open the Gtags output window.  Set this variable to zero, to not open
" the Gtags output window by default.  You can open it manually by using
" the :cwindow command.
" (This code was drived from 'grep.vim'.)
if !exists("Gtags_OpenQuickfixWindow")
    let Gtags_OpenQuickfixWindow = 1
endif

" Character to use to quote patterns and filenames before passing to global.
" (This code was drived from 'grep.vim'.)
if !exists("Gtags_Shell_Quote_Char")
    if has("win32") || has("win16") || has("win95")
        let Gtags_Shell_Quote_Char = '"'
    else
        let Gtags_Shell_Quote_Char = "'"
    endif
endif
if !exists("Gtags_Single_Quote_Char")
    if has("win32") || has("win16") || has("win95")
        let Gtags_Single_Quote_Char = "'"
        let Gtags_Double_Quote_Char = '\"'
    else
        let sq = "'"
        let dq = '"'
        let Gtags_Single_Quote_Char = sq . dq . sq . dq . sq
        let Gtags_Double_Quote_Char = '"'
    endif
endif

"
" Display error message.
"
function s:Error(msg)
    echohl WarningMsg |
           \ echomsg 'Error: ' . a:msg |
           \ echohl None
endfunction
"
" Extract pattern or option string.
"
function s:Extract(line, target)
    let option = ''
    let pattern = ''
    let force_pattern = 0
    let length = strlen(a:line)
    let i = 0

    " skip command name.
    if a:line =~ '^Gtags'
        let i = 5
    endif
    while i < length && a:line[i] == ' '
       let i = i + 1
    endwhile 
    while i < length
        if a:line[i] == "-" && force_pattern == 0
            let i = i + 1
            " Ignore long name option like --help.
            if i < length && a:line[i] == '-'
                while i < length && a:line[i] != ' '
                   let i = i + 1
                endwhile 
            else
                while i < length && a:line[i] != ' '
                    let c = a:line[i]
                    let option = option . c
                    let i = i + 1
                endwhile 
                if c == 'e'
                    let force_pattern = 1
                endif
            endif
        else
            let pattern = ''
            " allow pattern includs blanks.
            while i < length
                 if a:line[i] == "'"
                     let pattern = pattern . g:Gtags_Single_Quote_Char
                 elseif a:line[i] == '"'
                     let pattern = pattern . g:Gtags_Double_Quote_Char
                 else
                     let pattern = pattern . a:line[i]
                 endif
                let i = i + 1
            endwhile 
            if a:target == 'pattern'
                return pattern
            endif
        endif
        " Skip blanks.
        while i < length && a:line[i] == ' '
               let i = i + 1
        endwhile 
    endwhile 
    if a:target == 'option'
        return option
    endif
    return ''
endfunction

"
" Trim options to avoid errors.
"
function! s:TrimOption(option)
    let option = ''
    let length = strlen(a:option)
    let i = 0

    while i < length
        let c = a:option[i]
        if c !~ '[cenpquv]'
            let option = option . c
        endif
        let i = i + 1
    endwhile
    return option
endfunction

"
" Execute global and load the result into quickfix window.
"
function! s:ExecLoad(option, long_option, pattern)
    " Execute global(1) command and write the result to a temporary file.
    let tmpfile = tempname()
    let isfile = 0
    let option = ''

    if a:option =~ 'f'
        let isfile = 1
    endif
    if a:long_option != ''
        let option = a:long_option . ' '
    endif
    let option = option . '-qx' . s:TrimOption(a:option)
    if isfile == 1
        let cmd = 'global ' . option . ' ' . a:pattern
    else
        let cmd = 'global ' . option . 'e ' . g:Gtags_Shell_Quote_Char . a:pattern . g:Gtags_Shell_Quote_Char 
    endif
"    let stuff = input(cmd)

    silent execute "!" . cmd . ">" . tmpfile
    if v:shell_error != 0
        if v:shell_error != 0
            if v:shell_error == 2
                call s:Error('invalid arguments. (gtags.vim requires GLOBAL 5.6.3 or later)')
            elseif v:shell_error == 3
                call s:Error('GTAGS not found.')
            else
                call s:Error('global command failed. command line: ' . cmd)
            endif
        endif
        call delete(tmpfile)
        return
    endif
    if getfsize(tmpfile) == 0
        if option =~ 'f'
            call s:Error('Tag not found in ' . a:pattern . '.')
        elseif option =~ 'P'
            call s:Error('Path which matches to ' . a:pattern . ' not found.')
        elseif option =~ 'g'
            call s:Error('Line which matches to ' . a:pattern . ' not found.')
        else
            call s:Error('Tag which matches to ' . g:Gtags_Shell_Quote_Char . a:pattern . g:Gtags_Shell_Quote_Char . ' not found.')
        endif
        call delete(tmpfile)
        return
    endif

    " Parse the output of 'global -x'.
    let efm_org = &efm
    let &efm="%*\\S%*\\s%l%\\s%f%\\s%m"
    execute "silent! cfile " . tmpfile
    let &efm = efm_org

    " Open the quickfix window
    if g:Gtags_OpenQuickfixWindow == 1
"        topleft vertical copen
        botright copen
    endif
    cc
    call delete(tmpfile)
endfunction

"
" RunGlobal()
"
function! s:RunGlobal(line)
    let pattern = s:Extract(a:line, 'pattern')

    if pattern == '%'
        let pattern = expand('%')
    elseif pattern == '#'
        let pattern = expand('#')
    endif
    let option = s:Extract(a:line, 'option')
    if option =~ 's' && option =~ 'r'
        call s:Error('Both of -s and -r are not allowed.')
        return
    endif

    " If no pattern supplied then get it from user.
    if pattern == '' && option !~ 'P'
        if option =~ 'f'
            let line = input("Gtags for file: ", expand('%'))
        else
            let line = input("Gtags for pattern: ", expand('<cword>'))
        endif
        let pattern = s:Extract(line, 'pattern')
        if pattern == ''
            call s:Error('Pattern not specified.')
            return
        endif
    endif
    call s:ExecLoad(option, '', pattern)
endfunction

"
" Execute RunGlobal() depending on the current position.
"
function! s:GtagsCursor()
    let pattern = expand("<cword>")
    let option = "--from-here=" . line('.') . ":" . expand("%")
    call s:ExecLoad('', option, pattern)
endfunction

"
" Show the current position on mozilla.
" (You need to execute htags(1) in your source direcotry.)
"
function! s:Gozilla()
    let lineno = line('.')
    let filename = expand("%")
    let result = system('gozilla +' . lineno . ' ' . filename)
endfunction

"
" Custom completion.
"
function Candidate(lead, line, pos)
    let option = s:Extract(a:line, 'option')
    if option =~ 'P' || option =~ 'f'
        let opt = '-P'
        if option =~ 'O'
            let opt = opt . 'O'
        elseif option =~ 'o'
            let opt = opt . 'o'
        endif
    elseif option =~ 's'
        let opt = '-cs'
    elseif option =~ 'g'
        return ''
    else
        let opt = '-c'
    endif
    return system('global' . ' ' . opt . ' ' . a:lead)
endfunction

" Define the set of Gtags commands
command! -nargs=* -complete=custom,Candidate Gtags call s:RunGlobal(<q-args>)
command! -nargs=0 GtagsCursor call s:GtagsCursor()
command! -nargs=0 Gozilla call s:Gozilla()
" Suggested map:
"map <C-]> :GtagsCursor<CR>
"map <C-g> :Gozilla<CR>
"map <C-n> :cn<CR>
"map <C-p> :cp<CR>
