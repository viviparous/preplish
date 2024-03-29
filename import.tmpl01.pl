#! /usr/bin/perl
use strict;
use warnings;
use feature 'say';
use Data::Dumper;
use Digest::SHA qw(sha256_hex);
use Scalar::Util qw(looks_like_number);
use Time::Local qw( timelocal_posix );
use List::Util qw( 
head tail uniqstr uniqnum uniq pairs any all none notall first max maxstr min minstr product sum sum0 pairs pairkeys pairvalues shuffle 
);

=pod
PREPLISH template file. 
Import and use. Make your own!
=cut


