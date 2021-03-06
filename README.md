# preplish

Perl REPL in Shell: a simple REPL for Perl 5 written in Bash with grep, sed, and awk. 

It runs wherever Perl, Bash, grep, sed, and awk run. (That's... everywhere.)

This project aims to be a good REPL. Low barrier to entry, quick productivity. You may find it useful as well as easy to understand.

### Project Status: Active

## Features:
* you can start the REPL and add valid Perl statements line-by-line
* a new subroutine or for loop can be on entirely on a single line or multi-line; if multi-line, close the scope with "}##"
* run current code with parameters (must be handled as @ARGV)
* run a specific function with or without parameters
* the code is checked (perl -I . -c $file) after every statement (subroutines and loops must be completed before they are checked)
* you can import an existing Perl file (see the sample template)
* ls dir, grep $somefile for "sub" and "package"
* list valid REPL commands, command history, and list the current code 
* create checkpoint files
* on exit, the code is saved to a file named using a date-stamp
* if perldoc is detected, you can search (Perldoc is a separate installation)
* if perltidy is detected, it is used to improve the display of code 

## Known Problems and Planned Features
* add search highlight for given string
* add feature to append __DATA__ section to a file so the result is a complete "notebook"

= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =  
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =  

### Inspiration for this Project
* Bash, Perl, grep, sed, awk
* other REPLs, from simple (Python) to complex (Jupyter)
* Readline vi Mode https://www.gnu.org/software/bash/manual/html_node/Readline-vi-Mode.html
* This post by Mike Stroyan:

Subject: 	Re: Readline history and bash's read -e

Date: 	Sun, 2 Sep 2007 16:36:20 -0600

https://lists.gnu.org/archive/html/bug-bash/2007-09/msg00004.html

= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =  
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =  

### Other Perl REPLs
If Preplish doesn't meet your needs, there are alternatives.

Some Perl folks use the Perl debugger:

perl -de 0

If you need more features, this Perl REPL is a good alternative:

https://metacpan.org/pod/Reply


