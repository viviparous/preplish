#! /usr/bin/perl
use strict;
use warnings;
use feature 'say';
use Scalar::Util qw(looks_like_number);

=pod
PREPLISH template file. 
Import and use. Make your own!
=cut



# list args
if (scalar(@ARGV)==0){ say __LINE__." No command-line args received."; }
#handle args that may be quoted
else {
	my $bMkStr=0;
	my @aArgs=();
	my @aTmp=();
	my $bDbg=1;
	say mksqbracks(__LINE__). "$0 argc=". scalar(@ARGV).", args: ". join(" ;; ", @ARGV);
	
	my @aSpltARGV=split(/\s+/,join(' ', @ARGV)); 

	say mksqbracks(__LINE__). "$0 rev argc=". scalar(@aSpltARGV).", args: ". join(" ;; ", @aSpltARGV);

	
	for my $arg (@aSpltARGV){

	 if( $arg =~ /^\"/ && $arg =~ /[^\"]$/) { $bMkStr =1; push @aTmp, $arg;	if($bDbg) { say mksqbracks(__LINE__). "start quoted arg $arg"; } }
	 elsif( $arg =~ /\"$/ && $arg =~ /^[^\"]/   ) { 
		$bMkStr = 0; push @aTmp, $arg; push @aArgs, join(" ", @aTmp); @aTmp=(); 
		if($bDbg) { say mksqbracks(__LINE__). "end quoted arg $arg"; }}
	 elsif( $bMkStr==1 ){ push @aTmp, $arg; if($bDbg) { say mksqbracks(__LINE__). "continue quoted arg $arg"; }}
	 else { push @aArgs, $arg; if($bDbg) { say mksqbracks(__LINE__). "add simple arg $arg"; }}	
		
	}
	
	say mksqbracks(__LINE__). "Received command-line args: ". join(" // ", @aArgs);  
	doArgTest01( @aArgs ) ; 
	doArgTest02( @aArgs );
}

#some subroutines
sub mksqbracks { my $v=shift; return "[ $v ] " ; }
sub doMsgArf { my $arf=shift; my @ary=@$arf; say mksqbracks($ary[0]). join(" , ",@ary[1..$#ary]);} #where ary[0] is caller __LINE__, for example
sub doArgTest01 { my @ary=@_; unshift @ary, mksqbracks(__LINE__); unshift @ary, "doArgTest01"; doMsgArf(\@ary);}
sub doArgTest02 { 
	my @ary=@_; 
	my @acmts=();
	#if looks_like_number perform a calculation
	#elsif str provide statistics
	for my $el (@ary) {
		if (looks_like_number($el)) { 
			if($el%2==0) { push @acmts, "arg{$el} is even number"; }
			else { push @acmts, "arg{$el} is odd number"; }
		}
		
		else {
			my %dChars=();
			map { $dChars{$_}++ } split(//,$el);
			my @aChars=();
			for my $k (sort keys %dChars) { push @aChars, "$k ($dChars{$k})"; }
			unshift @aChars, join('',sort keys %dChars); 
			push @acmts, "arg{$el} L=". length($el) . " UNQ=" . join(" ;; ", @aChars ); 
		}
	}
	push @ary, "\n";
	push @ary, @acmts; 
	unshift @ary, mksqbracks(__LINE__); unshift @ary, "doArgTest02"; doMsgArf(\@ary);
}

