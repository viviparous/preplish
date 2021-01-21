# preplish

Perl REPL in Shell: a simple REPL for Perl 5 written in Bash. 

You may find it useful as well as easy to understand. It's Bash. ^_^

Features:

= you can start the REPL and add valid Perl statements line-by-line

= a new subroutine can be on entirely on a single line or multi-line; if multi-line, close the subroutine scope with "}##"

= the code is checked (perl -I . -c $file) after every statement (subroutines and loops must be completed before they are checked)

= you can import an existing Perl file, ls dir, grep $somefile for "sub" and "package"

= list valid REPL commands, command history, and list the current code 

= on exit, the code is saved to a file named using a date-stamp

= if Perldoc is detected, you can search (Perldoc is a separate installation)

Planned features:

= run current code with parameters

= CRUD functions for checkpoint files

Inspiration for this project

= Bash and Perl (of course)

= other REPLs, from simple (Python) to complex (Jupyter)

= This post by Mike Stroyan:

Subject: 	Re: Readline history and bash's read -e

Date: 	Sun, 2 Sep 2007 16:36:20 -0600

https://lists.gnu.org/archive/html/bug-bash/2007-09/msg00004.html

= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =  
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =  

If Preplish doesn't meet your needs, there are alternatives.

Some Perl folks use the Perl debugger:

perl -de 0

If you need more features, this Perl REPL is a good alternative:

https://metacpan.org/pod/Reply


