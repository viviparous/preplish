# preplish

Perl REPL in Shell: a simple REPL for Perl 5 written in Bash. 

You may find it useful as well as easy to understand. It's Bash. ^_^

Features:

= you can start the REPL and add valid Perl statements line-by-line

= a new subroutine must be on entirely on a single line

= the code is checked (perl -I . -c $file) after every statement

= you can import an existing Perl file, ls dir, grep $somefile for "sub" and "package"

= list valid REPL commands, command history, and list the current code 

= on exit, the code is saved to a file named using a date-stamp

Planned features:

= if Perldoc is detected, you can search (Perldoc is a separate installation, of course)

= add new multi-line subroutine

= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =  
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =  

If Preplish doesn't meet your needs, there are alternatives.

Some Perl folks use the Perl debugger:

perl -de 0

If you need more features, this Perl REPL is a good alternative:

https://metacpan.org/pod/Reply


