#! /usr/bin/perl
use strict;
use warnings;
use feature 'say';
use Data::Dumper;
use Digest::SHA qw(sha256_hex);
use Scalar::Util qw(looks_like_number blessed);
use Time::Local qw( timelocal_posix );
use ExtUtils::Installed;
use List::Util qw( 
head tail uniqstr uniqnum uniq pairs any all none notall first max maxstr min minstr product sum sum0 pairs pairkeys pairvalues shuffle 
);

=pod
PREPLISH template file. 
Import and use. Make your own!
=cut


my $giENTRPY= 1 + int rand(time);

my %gdKVp=(); #global arg dict

my %gdAppParms=( appVerbose=>1 );

my $gbDbg=0;

$Data::Dumper::Sortkeys=1;

# list args
if (scalar(@ARGV)==0){ if($gbDbg==1){ say "( ".__LINE__." No command-line args received. )"; } }
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
	
	if(scalar(@aArgs)%2==0) { # even number of args, store as K-V pairs
		my %dKVp=();
		my $iToggle=0;
		while ( my ($idx,$a)=each @aArgs) {
			if($iToggle==0) {
			 $gdKVp{$a}=0; $iToggle=1;
		}
			else { $gdKVp{$aArgs[$idx-1]}=$a; $iToggle=0; }
		}
		say mksqbracks(__LINE__). "KVP args: ". join(" ;; ", map { $_ ." = ". $gdKVp{$_} } keys %gdKVp);
	}
}

package cTypeBox { #simple box object for types
	sub new {
		my ($class,$value)=@_;

		my %dTypes=( null=>0, number=>1, string=>2 , ref=>3);
		for my $t (keys %dTypes) { $dTypes{ $dTypes{$t} }=$t; } #provide look-ups like enum

		my $boxtype=$dTypes{null};

		my $fteval=sub { 
			my $inval=shift; if(length($inval)==0){ return $dTypes{null}; } 
			elsif(ref($inval)) { return $dTypes{ref};  } 
			elsif(::looks_like_number($value)) { return $dTypes{number};  }
			elsif(length($inval)>0) { return $dTypes{string}; } 
		};
	
		$boxtype=&$fteval($value);
		
				
		my $self={
			uic=>$class ."_". ::getUIC(__LINE__), 
			value=>$value,
			type=>$boxtype,
			hrfdtypes=>\%dTypes,
			functeval=>$fteval,
		};

		my $obj=bless $self,$class;
		return $obj;
	}
	
	sub settype { my ($p,$t)=@_; my $hrf=$p->{hrfdtypes}; if(exists $hrf->{$t}) { $p->{type}=$t; } else { say "unknown type $t"; } }
	sub gettypei { my $p=shift; return $p->{type}; }
	sub gettypen { my $p=shift; my $hrf=$p->{hrfdtypes}; return $hrf->{$p->{type}}; }
	sub getval { my $p=shift; return $p->{value}; }
	sub getuic { my $p=shift; return $p->{uic}; }
	sub setval { my ($p,$v)=@_; my $hrf=$p->{hrfdtypes}; my $f=$p->{functeval}; my $t=&$f($v); $p->{value}=$v; $p->{type}=$t; }
	
};




package cZipCols { #combine two arrays of equal length

	sub new {
	 my ($class,$col1,$col2)=@_;
	 my @cols=();
	 if ( scalar(@$col1)==scalar(@$col2) ) { push @cols, $col1; push @cols, $col2;  }
	 else { say "$class error, arrays of unequal size.";  return 0; } 
	 my $self = {  cols=>\@cols , colsize=> scalar(@$col1) , cTrue=>1, cFalse=>0  };
	 my $obj=bless $self,$class; 
	 return $obj;
	}
	
	
	sub sTrue { my $s=shift; return $s->{cTrue}; }
	sub sFalse { my $s=shift; return $s->{cFalse}; }
	sub getLength { my $s=shift; return $s->{colsize}; }
	sub addColArf { my ($s,$arf)=@_; 
		if (scalar(@$arf) != $s->{colsize}) { 
		say "Array size ". scalar(@$arf)." does not match ". $s->{colsize}; return;
		} 
		else { my $arfCols=$s->{cols}; push @$arfCols, $arf; }
	}
	sub getNthTuple { #human nth, 
	 my ($s, $nth)=@_;
	 my @aRVtuple=();
	 if($nth > 0 && $nth <= $s->{colsize}) {
		$nth -= 1; #adjust to zero-based nth
		my $colArf=$s->{cols};
		for my $COL (@$colArf) { push @aRVtuple, $COL->[$nth]; }		 
	 }
	 return \@aRVtuple; 
	}
	
	sub getArfOfValTuples {    
	 my $s=shift; 
	 my @rvAry=();
	 for my $idx (0..$s->{colsize}-1) { 
		my @aTuple=();
		my $colArf=$s->{cols};
		for my $COL (@$colArf) { push @aTuple, $COL->[$idx]; }
		push @rvAry, \@aTuple; 
	 }
	 return \@rvAry;
	 
	}

};


package cOrdict { #ordered associative array
	sub new { 
		my $class=shift; my @aKeys=(); my %dKeysVals=(); my %dRefData=(); my @aHdrNyms=();
		my $uicInt = ::getSHA(::getEntropyVal() + int rand(__LINE__) + int rand(time));
		my $self = { oClass=>$class, uic=>$class."-".$uicInt , aKeys=>\@aKeys , dRefData=>\%dRefData , dKeysVals=>\%dKeysVals , aHdrNyms=>\@aHdrNyms, bDbg=>0 };
		return bless $self, $class;
	}
	
	sub dbgOff { my $self=shift; $self->{bDbg}=0; }
	sub dbgOn { my $self=shift; $self->{bDbg}=1; }
	
	sub identify { my $self=shift; say $self->{oClass}. " ". substr($self->{uic}, 0, int (length($self->{uic})/2) ) . "... ";}	
	sub identifyLong { my $self=shift; say $self->{oClass}. " ". $self->{uic};}

	sub addKV { my ($self,$key,$value)=@_; 
		if($self->{bDbg}==1){ say $self->{uic}." addKV $key , $value" ; }
		
		my $arfHdrNyms=$self->{aHdrNyms};
		push @$arfHdrNyms, $key;
		
		my $arf=$self->{aKeys}; my $pkcount=scalar(@$arf); my $pck=$pkcount."-".$key; push @$arf, $pck; 
		if($self->{bDbg}==1){ say $self->{uic}." kcount was $pkcount, now ". scalar(@$arf); }
		
		my $hrf=$self->{dKeysVals}; my $phkcount=scalar(keys %$hrf);
		$hrf->{$pck}=$value; 
		if($self->{bDbg}==1){ say $self->{uic}." hkcount was $phkcount, now ". scalar(keys %$hrf); }
		
	}
	sub setKV { my ($self,$key,$value)=@_; 
		if($self->{bDbg}==1){ say $self->{uic}." setKV $key , $value" ; }
		my $hrf=$self->{dKeysVals}; my $phkcount=scalar(keys %$hrf);
		

		if( exists $hrf->{$key} ) { 
			my $preVal=$hrf->{$key}; 
			$hrf->{$key}=$value;
			if($self->{bDbg}==1){ say $self->{uic}." key $key was $preVal, now $value"; }        
		}
		
		else { say "key $key not found in ". $self->{uic}; }        
	}

	sub setRefData { my ($self, $refdata)=@_; $self->{dRefData}=$refdata; }
	sub getRefData { my $self=shift; return $self->{dRefData}; }
	
	sub getVofK { my ($self,$key)=@_; my $hrf=$self->{dKeysVals}; return $hrf->{$key}; }
	sub getKeysArf { my $self=shift; return $self->{aKeys};  }
	sub getValsArf { my $self=shift; my $arf=$self->{aKeys}; my $drf=$self->{dKeysVals}; my @aRV = map { $drf->{$_} } @$arf ; return \@aRV; }
	
	sub delKey { my ($self,$keydel)=@_; 
		my $hrf=$self->{dKeysVals}; my $arf=$self->{aKeys};
		my @aNew=();
		if (exists $hrf->{$keydel}){
			for my $k (@$arf) { 
				if($k eq $keydel) {   
					delete $hrf->{$keydel}; 
				}
				else { push @aNew, $k; } 
			}
			$self->{aKeys}=\@aNew;
		}
		else { say __LINE__. " ordAssocArry $hrf->{uic} cannot delete key $keydel . No such key."; }
	}
	
	sub listHdrKeys { my $self=shift; my $arf=$self->{aHdrNyms}; say $self->identify()." header keys: ". join(" ;; ", @$arf); }	
	sub listKeys { my $self=shift; my $arf=$self->{aKeys}; say $self->identify()." keys: ". join(" ;; ", @$arf); }
	sub listValues { my $self=shift; my $arf=$self->{aKeys}; my $drf=$self->{dKeysVals}; say $self->identify()." values: ". join(" ;; ", map { $drf->{$_} } @$arf ); }
	
	sub getNthColArf { #return Nth value of all columns (key-arfs); adjust Nth for zero-based array
		my ($self,$nth)=@_; my @aRV=(); my $arfKeys=$self->{aKeys}; my $hrfKcols=$self->{dKeysVals};
		if($self->{bDbg}==1){ say $self->{uic}." getNthCol $nth" ; }
		my @abErrors=();
		if($nth==0){ push @abErrors,"Need a column value greater than zero.";}

		if(scalar(@abErrors)==0){
			my $Nth0B=$nth-1;
			
			for my $aK (@$arfKeys){ #check length for all columns
				my $arfCol=$hrfKcols->{$aK};
				if(scalar(@$arfCol)<$nth){ push @abErrors,"Need a column value greater than zero.";} 
				else { push @aRV, $arfCol->[$Nth0B]; }
			}
		}
		
		if(scalar(@abErrors)>0){ @aRV=(); say "Errors: ". join(" ;; ", @abErrors); }

		return \@aRV;
	}
};



package cCounter { #counter object
	sub new { 
		my $class=shift; my @aKeys=(); my %dKeysVals=(); my %dRefData=(); my @aHdrNyms=();
		my $uicInt = ::getSHA(::getEntropyVal() + int rand(__LINE__) + int rand(time));
		my $self = { oClass=>$class, uic=>$class."-".$uicInt , aKeys=>\@aKeys , dRefData=>\%dRefData , dKeysVals=>\%dKeysVals , aHdrNyms=>\@aHdrNyms, bDbg=>0 };
		return bless $self, $class;
	}
	
	sub dbgOff { my $self=shift; $self->{bDbg}=0; }
	sub dbgOn { my $self=shift; $self->{bDbg}=1; }
	
	sub identify { my $self=shift; say $self->{oClass}. " ". substr($self->{uic}, 0, int (length($self->{uic})/2) ) . "... ";}	
	sub identifyLong { my $self=shift; say $self->{oClass}. " ". $self->{uic};}

	sub count { my ($self,$key)=@_; 
		if($self->{bDbg}==1){ say $self->{uic}." count $key" ; }
		
		my $harf=$self->{dKeysVals};
		
		if(exists $harf->{$key}){ $harf->{$key}++ ; }
		else { 
			my $arf=$self->{aKeys};
			push @$arf, $key;
			$harf->{$key}=1;
		}		
	}

	sub setRefData { my ($self, $refdata)=@_; $self->{dRefData}=$refdata; }
	sub getRefData { my $self=shift; return $self->{dRefData}; }
	
	sub getVofK { my ($self,$key)=@_; my $hrf=$self->{dKeysVals}; return $hrf->{$key}; }
	sub getKeysArf { my $self=shift; return $self->{aKeys};  }
	sub getValsArf { my $self=shift; my $arf=$self->{aKeys}; my $drf=$self->{dKeysVals}; my @aRV = map { $drf->{$_} } @$arf ; return \@aRV; }
	
	
	sub listHdrKeys { my $self=shift; my $arf=$self->{aHdrNyms}; say $self->identify()." header keys: ". join(" ;; ", @$arf); }	
	sub listKeys { my $self=shift; my $arf=$self->{aKeys}; say $self->identify()." keys: ". join(" ;; ", @$arf); }
	sub listValues { my $self=shift; my $arf=$self->{aKeys}; my $drf=$self->{dKeysVals}; say $self->identify()." values: ". join(" ;; ", map { $drf->{$_} } @$arf ); }
	sub listByCountAsc {
		my $self=shift; my $karf=$self->{aKeys}; 
		my %d01=();
		map { $d01{$_}=$self->getVofK($_) } @$karf;
		
		say $self->identify()." keys: ". join(" ;; ", map { $_."=".$d01{$_} } sort {$d01{$a}<=>$d01{$b}} keys %d01); 
	}



};

package cMatrix { #matrix object 

	sub new {my ($class,$name)=@_;
		my @ary=();
		my @aryHdrs=();
		my $self={
		uic=>($name||$class) ."_". ::getUIC(__LINE__),
		type=>$name||$class,
		amain=>\@ary,
		ahdrs=>\@aryHdrs,
		width=>-1,
		bStrict=>0,
		bIsValidState=>1,
		datasrcref=>"",
		};
	my $obj=bless $self,$class;
	$obj->showDocu; 
	return $obj;
	}
	sub	showDocu { my $p=shift; if( $gdAppParms{appVerbose} > 0 ){ say "This is a " . $p->{type} . " object. Use method importFileData to add data."; } }
	sub head { my $sdoc="Show first n rows";
		my ($p, $n)=@_;
		if(! defined($n)){ $n=5; } 
		my $marf=$p->{amain};
		say $p->{uic} ." $sdoc"; 
		while (my ($idx,$val)=each @$marf) { 
			my $arf =$marf->[$idx]; 
			#say __LINE__ x 60 ." ".__LINE__."\ndbg\n". join(" ;; ", @$arf); 
			say join(" ;; ", @$arf);
			if($idx>$n){ last; } 
		}		 
	}
	sub getType { my $p=shift; return $p->{type}; }
	sub setHdrs {my ($p,$rarf)=@_; my $marf=$p->{ahdrs}; my @aTmp=(); if(scalar(@$rarf)==0){ return; } for my $val (@$rarf) { push @aTmp, $val; } push @$marf, \@aTmp; $p->shape(); }
	sub setDataSrc { 
		my ($p,$srcref)=@_; my $prev=$p->{datasrcref}; $p->{datasrcref}=$srcref; 
		say "Set data source ref.\nprev: \"$prev\"\ncurr: ".$p->{datasrcref}; }
	sub getDataSrc { my $p=shift; return $p->{datasrcref}; }
	sub bIsEmpty {my $p=shift; my $marf=$p->{amain}; my $rv=0; if( scalar(@$marf)==0){ $rv=1; } return $rv; }
	sub addRow {
		my ($p,$rarf)=@_;  my $marf=$p->{amain}; my @aTmp=(); if(scalar(@$rarf)==0){ return; } 
		$p->setWidth($rarf); 
		for my $val (@$rarf) { push @aTmp, $val; } 
		push @$marf, \@aTmp; #$p->shape(); 
	}
	sub addCol { 
		my ($p,$carf)=@_; my $marf=$p->{amain}; 
		if (scalar(@$carf)==scalar(@$marf) || scalar(@$marf)==0 ) { 
			my @cnew=@$carf;
			if( scalar(@$marf)==0 ) { 
				for my $col (@cnew){
					my @aTmp=();
					push @aTmp, $col;
					push @$marf, \@aTmp;
				}
			}
			else { for my $arf (@$marf) { push @$arf, shift @cnew; } 
				say "Added column ".join(" _ ", @$carf); $p->shape(); 
			}
		} 
		else { say "Error: input size, col=".scalar(@$carf)." rows=".scalar(@$marf); $p->shape(); } 
	}
	sub addIndex { my $sdoc="add index column";
	 my ($p,$n)=@_; 
	 if(! defined($n)){ $n=0; }
	 my $c=$p->getRowCount;if($n==0){$c--;}elsif($n>1){$c=$n+$c;} 
	 my @aC=map { $_ } $n .. $c; $p->addCol(\@aC); 
	}
	
	sub getRowsArf { my $p=shift; return $p->{amain}; }
	sub setRowsArf { my ($p,$arfM)=@_; # check shape, set valid
		my %dChk=();
		my $iErrors=0;
		while ( my ($idxR, $rarf)=each @$arfM) { # struct "@ of \@"
			$dChk{$idxR}=scalar(@$rarf);
			for my $val (@$rarf) { 
				if(! ::numtest($val) ){ $iErrors++; } ;
			} 
		}
		my @aMinMax=sort { $a<=>$b } values %dChk;
		#say ::mkstr([ __LINE__,"dbg:",join(" ;; ",@aMinMax)]);
		if($iErrors==0 && $aMinMax[0] == $aMinMax[ $#aMinMax  ]) { 
			say "matrix well-formed"; $p->{amain}=$arfM; $p->{bStateIsValid}=1; 
			$p->{width}=$aMinMax[0];
		}
		else { 
			say "matrix not well-formed, not saving. (errors=$iErrors)";
			say "Row sizes: ". join(" , ", @aMinMax);  
		} 
	} 
	sub getCol { 
		my ($p,$c)=@_; 
		my $carf=$p->getColsArf;
		my @aRV=();
		my $cwidth=scalar(@$carf);
		my $errors=0;
		if( $cwidth==0 || $c<1 || $c>$cwidth) { say "Problem with value $c . Column count is $cwidth ."; $errors++; }

		if($errors==0){ @aRV= @{$carf->[$c-1]}; }
		return \@aRV;  		
	} 

	sub getColsArf { 
		my $p=shift; my %dRows=(); my @aRV=(); my $marf=$p->{amain};
		my %dCols=();
		while (my ($idxR,$arfR)=each @$marf) { #for each row
			while (my ($idxC, $val)=each @$arfR) { #for each field in row
				::addDictKeyIfNot(\%dCols,$idxC,$val);
			}
		}
		@aRV=map { $dCols{$_} } sort { $a<=>$b } keys %dCols;
		return \@aRV;  		
	} 
	sub getRowCount { my $sdoc="yield row count";
	 my $p=shift; my $marf=$p->{amain}; return scalar(@$marf); 
	}
	sub getWidth { my $p=shift; my $rv=$p->{width}; my $marf=$p->{amain}; if(scalar(@$marf)>0){ my $arfw=$marf->[0] ; $rv=scalar(@$arfw); $p->setWidth($arfw); } return $rv; }
	sub _getRowNarf { my $sdoc="return arf at row number";
	 my ($p,$rn)=@_; my $marf=$p->{amain}; my $rvArf=$marf->[$rn];  return $rvArf; 
	}
	sub _getColNarf { my $sdoc="return arf at col number";
	 my ($p,$cn)=@_; my $marf=$p->{amain}; my @aRV=(); 
	 for my $arfR (@$marf) {
		while ( my ($idx,$val)=each @$arfR){ if($idx == $cn) { push @aRV,$val;  } }
	 }
	 return \@aRV; 
	}
	
	sub shape { my $p=shift; my $marf=$p->{amain}; say "Shape ".substr($p->{uic},0,14)."... "; $p->prHdrs(); say "Rows: ".scalar(@$marf); say "Width: ".$p->getWidth; }	
	sub mulx { my $sdoc="multiply by a scalar x";
		my ($p,$mxv)=@_; if( ! ::numtest($mxv)){ say "NAN $mxv"; return; }  
		my $marf=$p->{amain}; my @aTmp=();
		for my $rw (@$marf) { for my $vv (@$rw){ if( ::numtest($vv) ) { $vv *= $mxv; } } }
		$p->show();
	}
	sub mulcolxi { my $sdoc="multiply column by a scalar x, insert";
		my ($p,$cidx,$mxv)=@_;
		my $marf=$p->{amain}; my @aTmp=();
		if( scalar(@$marf)==0){ say "Empty matrix"; return; }  
		elsif( ! ::numtest($mxv)){ say "NAN $mxv"; return; }  
		for my $rw (@$marf) { 
			while ( my ($idxC,$vv)=each @$rw){ 
				if( $idxC==$cidx-1 && ::numtest($vv) ) { push @aTmp, $vv * $mxv; } 
			}
		}
		$p->addCol(\@aTmp);
		$p->show;
	}	
	sub mulrowxi { my $sdoc="multiply row by a scalar x, insert";
		my ($p,$ridx, $mxv)=@_; 
		my $marf=$p->{amain}; my @aTmp=();
		if( scalar(@$marf)==0){ say "Empty matrix"; return; }  
		elsif( ! ::numtest($mxv)){ say "NAN $mxv"; return; }  
		while (my ($idxR, $rw)=each @$marf) { 
			if($idxR==$ridx-1){ 
				for my $vv (@$rw){ if( ::numtest($vv) ) { push @aTmp, $vv * $mxv; } }
				$p->addRow(\@aTmp);
				last;
			}			 
		}
		$p->show;
	}
	
	sub calcStdvOfCol {  my $sdoc="insert STDV of column";
		
		my ($p,$cidx)=@_;
		my $marf=$p->{amain}; my @aTmp=();
		if( scalar(@$marf)==0){ say "Empty matrix"; return; }    
		for my $rw (@$marf) { 
			while ( my ($idxC,$vv)=each @$rw){ 
				if( $idxC==$cidx-1 ) { push @aTmp, $vv; } 
			}
		}
		my $stdv= ::roundXtoYdecimals( ::computeStnDev(\@aTmp) , 3) ;
		my @aSTDVs=map { $_ <= $stdv ? "-".$stdv/$_ : $_/$stdv } @aTmp ;
		my @aFinalMsgs=();
		push @aFinalMsgs, "STDV=$stdv";
		push @aFinalMsgs, "STDV values: ". join(" ;; ", @aSTDVs);
		
		for my $rw (@$marf) { 
			#say __LINE__." ". join(" ;; ", @$rw);			
			push @$rw, ::roundXtoYdecimals( shift @aSTDVs , 3 ); 
			#say __LINE__." ". say join(" ;; ", @$rw);
		}

		
		$p->show;
		if( scalar(@aFinalMsgs)>0 ){ say join(" ;; ", @aFinalMsgs) ; }
		
	}
	
			
	sub togStrict { my $p=shift; $p->{bStrict}==0 ? $p->{bStrict}=1 : $p->{bStrict}=0; say $p->{uic}." strict mode = ". $p->{bStrict}; }
	sub isStrict { my $p=shift; return $p->{bStrict}==0 ? 0 : 1; }
	sub setWidth { #take an arf, set width; no change if value invalid
		my ($p,$arf)=@_; $p->{width}= scalar(@$arf); 
	}
	sub setIsValid { my ($p,$val)=@_; $p->{bIsValidState}= $val; } 
	sub chkTypes { my ($p,$charf)=@_; my %dTypes=(i=>0,s=>0,o=>0); $p->msgWIP();  }	
	sub exportToFile { my $sdoc="Save matrix data to a file. Arg1=str|empty|_ , Arg1=_ Arg2=sepchar";
		my ($p,$fn,$fsep)=@_;
		
		my $fnshort=substr($p->{uic},0,14)."-";
		
		if(! defined($fn) || $fn eq "_") { $fn=$fnshort.::getDTPrefix();  }
		else { $fn=~s/ +/-/g ; $fn=$fnshort.::getDTPrefix().$fn."_"; }
				
		if($fn eq "_" && ! defined($fsep)){ $fsep=','; }
		elsif($fn eq "_" && defined($fsep)){ say "Export using fsep $fsep"; }		

		my %dExts=( txt=>"_export.txt", csv=>"_export.csv.txt", scsv=>"_export.scsv.txt" );
		my $ext=$dExts{txt};
		if($fsep eq ','){  $ext=$dExts{csv}; }
		elsif($fsep eq ';'){  $ext=$dExts{scsv}; }

		my $iC=0;			
		my $fnout=$fn.$iC.$ext;
		while ( -e $fnout ) { $iC++; $fnout=$fn.$iC.$ext ; }
		
		my $marf=$p->{amain};
		
		if(scalar(@$marf)>0) {
			open(my $fh, '>', $fnout);
			if(length($p->{datasrcref}) > 0 ) { say $fh "#datasrcref _ " . $p->{datasrcref}; }
			#for my $arfR (@$marf){ say $fh join(",", @$arfR); }
			for my $arfR (@$marf){ say $fh join("$fsep", map{ if(::numtest($_)){ $_ } else { $_=~s/\s+/_/gr } } @$arfR); }			
			for my $arfR (@$marf){ say "Export: ". join("$fsep", map{ if(::numtest($_)){ "(n) ". $_ } else { "(s) " . $_=~s/\s+/_/gr } } @$arfR); }

			close($fh);
			say "Data exported to file $fnout as csv.";
		}
		else { say __LINE__. " Nothing exported, ". $p->{type} . " is empty."; }
	}
	
	sub _mvOrswap {
		my ($p,$movorswp,$Cn,$Pn)=@_; #mov 1 swp 2 col pos

		my $rarf=$p->{amain};
		my $carf=$p->getColsArf;
		if($Pn > scalar(@$carf)) { $Pn =scalar(@$carf); }
				
		$Cn--; $Pn--; #ab USERPOV

		if(scalar(@$rarf)==0 || scalar(@$carf)==0){ $p->msgStatusEmpty; return; }
		elsif($Cn==$Pn || $Cn<0 || $Pn<0 ){ return; }
		
		my %dRefs=();

		while ( my ($idx,$arf)=each @$carf) {
			
			if($idx==$Cn){ $dRefs{$Pn}=$arf; } #in either case,$Cn moves to $Pn
			elsif($movorswp==2){ #swap
				if($idx==$Pn){ $dRefs{$Cn}=$arf; } 			
				else{ $dRefs{$idx}=$arf; } 							
			}
			elsif($movorswp==1){
				if($idx==$Pn){ $dRefs{$Pn+1}=$arf; }#insert
				elsif($idx>$Pn){ $dRefs{$idx+1}=$arf; }#swap
				else{ $dRefs{$idx}=$arf; } 							
			}
		}
		
		for my $arfkey (sort {$a<=>$b} keys %dRefs){ my $arf=$dRefs{$arfkey}; say 'X' x 60 . " ". __LINE__. "\ndbgDump\n". join(" ;; ", @$arf); }
				
		my %dNewRows=();
		for my $colkey (sort {$a<=>$b} keys %dRefs) {
		 my $colref = $dRefs{$colkey};	
		 while (my ($idx, $fieldval)=each @$colref){ 
			 
			 if(! exists $dNewRows{$idx}){my @aTmp=(); push @aTmp, $fieldval; $dNewRows{$idx}=\@aTmp;}
			 else { my $arf=$dNewRows{$idx}; push @$arf, $fieldval;  } 
		 } 			
		}
		my @aNewData= map { $dNewRows{$_} } sort {$a<=>$b} keys %dNewRows;
		for my $arf (@aNewData){ say '=' x 60 . " ". __LINE__. "\ndbgDump\n". join(" ;; ", @$arf); }
		$p->{amain}=\@aNewData;
		$p->show();
				
	}
	
	sub mvColToPos { my $sdoc="move col to pos";
		my ($p,$Cn,$Pn)=@_; 
		$p->_mvOrswap(1,$Cn,$Pn);
		
	}

	sub swapColToPos { my $sdoc="swap columns"; 
		my ($p,$Cn,$Pn)=@_; 
		$p->_mvOrswap(2,$Cn,$Pn);
				
	}
	sub mvRowToPos { my $sdoc="Move row to new position"; 
		my ($p,$Rn,$Pn)=@_; my $marf=$p->{amain}; 
		if($Rn==$Pn){ return; }
		elsif($Rn>scalar(@$marf) || $Pn>scalar(@$marf)){ return; }

		my %dRows=();
		while ( my ($idxR,$arf)=each @$marf) {
			$dRows{$idxR}=$arf; 
		}
		my $arfTmp=$dRows{$Pn};
		$dRows{$Pn}=$dRows{$Rn};
		$dRows{$Rn}=$arfTmp;
		my @aTmp= map { $dRows{$_} } sort {$a<=>$b} keys %dRows ;
		$p->{amain}=\@aTmp;  
	}
	sub	shwRow { my $sdoc="show row n";
	 my ($p,$rowwant)=@_; #n is the human non-zero index 
	 my $marf=$p->{amain}; 
	 if(! ::numtest($rowwant) || $rowwant <= 0 || $rowwant > scalar(@$marf) ) { say $p->{uic}." \"$rowwant\" not found"; }
	 else { my $rarf= $marf->[$rowwant-1] ; my $fc=1; say $p->{uic}." \"$rowwant\"\n" . join(" ;; ", map {"[".$fc++."] ".$_} @$rarf); }
	}
	sub shwCol { my $sdoc="shows column n";
		my ($p,$colwant,$bSort)= @_; my $marf=$p->{amain}; 
		my $width=$p->{width};
		my %dCols=();
		#build and use cols from rows	
		while ( my ($idxR,$arf)=each @$marf) {
			while ( my ($idxC,$val)=each @$arf ) {
				if($idxC!=$colwant-1){ next; } 
				$dCols{$idxR} = $val;
			}
		}
		my $srtType=0;
		if( defined($bSort) && ::numtest($bSort) && $bSort==1 ){ $srtType=1; }
		say "Sort type $srtType";
		if ($srtType==1){
			say join("\n", map {$_."=".$dCols{$_} } sort { $dCols{$a}<=>$dCols{$b} } keys %dCols);
		} else { say join("\n", map {$_."=".$dCols{$_} } sort { $a<=>$b } keys %dCols); }
	}
	sub shwSpcfCols { my $sdoc="Show specific columns"; #take int arf
		my $p=shift; $p->msgWIP; }
	sub shwSpcfRows { my $sdoc="Show specific rows"; #take int arf 
		my $p=shift; $p->msgWIP; }
	sub getRowSigs { my $sdoc="Return a UID for each row";
		my $p=shift; my $marf=$p->{amain};
		my %hRV=();  
		while ( my ($idxR,$arf)=each @$marf) {
			$hRV{$idxR}=::getSHA($idxR.join("",@$arf));
		}		
		return \%hRV; 
	}

	
	sub shwDecilesColi { my $sdoc="show deciles for column i";
		#select column; map values to deciles
		my ($p,$ci)=@_;
		my %dCstats=();
		my $col=$p->getCol($ci); $dCstats{cmax}= ::max(@$col); $dCstats{cmin}= ::min(@$col);
		my ($hSgToVal, $hSgToRow)=$p->_getMtxMapColi($ci);

		my @aNewRowSigOrd= map { $_ } sort { $hSgToVal->{$a}<=>$hSgToVal->{$b} } keys %$hSgToVal; 
		
		my %dDecGrps=();
				
		for my $RSIG (@aNewRowSigOrd){
			my $cval=$hSgToVal->{$RSIG};
			my $pcval=::roundXtoYdecimals( ( $cval/$dCstats{cmax} ) * 100, 2);
			my $decile=1;
			for my $dec (-9..1) { my $cmpv=-1*$dec*10; if( $pcval >= $cmpv ){ $decile= -1*$dec+1; $dDecGrps{$decile}++; last; } } 
			say substr($RSIG,0,7) ."... (col=$ci : pc=$pcval dcl=$decile) ". $hSgToVal->{$RSIG} ." , ". join(" _ ", @{$hSgToRow->{$RSIG}});
		}
		my $iTotPartcips=0; map { $iTotPartcips += $dDecGrps{$_}  } keys %dDecGrps;
		say "\nGroup size: $iTotPartcips // Decile counts: ". join(" -- ", map { "D".$_ ."=". $dDecGrps{$_}  } sort {$a<=>$b} keys %dDecGrps );
	}
	sub _getMtxMapColi { 
		my ($p,$colwant)=@_;
		my $marf=$p->{amain};
		my %dSigtoVal=();
		my %dSigtoRow=();		
		my $hMap=$p->getRowSigs();
		#build and use cols from rows	
		while ( my ($idxR,$arf)=each @$marf) {
			while ( my ($idxC,$val)=each @$arf ) {
				if($idxC!=$colwant-1){ next; } 
				$dSigtoVal{$hMap->{$idxR}}=$val;
				$dSigtoRow{$hMap->{$idxR}}=$arf;
			}
		}
		return ( \%dSigtoVal , \%dSigtoRow );
	}
	

	
	sub srtMtxByCol { my $sdoc="sort matrix by column (nth). 0|1 asc|des";
		my ($p,$colwant,$bSort)= @_; my $marf=$p->{amain}; 
		
		my $carf=$p->getColsArf;
		my %dCoLn=();
		
		while( my ($idxC,$arfC)=each @$carf) {
			$dCoLn{$idxC}= ::max ( map { length($_) } @$arfC );			
		}
		
		
		my %dSigtoVal=();
		my %dSigtoRow=();
		my $hMap=$p->getRowSigs();
		#build and use cols from rows	
		while ( my ($idxR,$arf)=each @$marf) {
			while ( my ($idxC,$val)=each @$arf ) {
				if($idxC!=$colwant-1){ next; } 
				$dSigtoVal{$hMap->{$idxR}}=$val;
				$dSigtoRow{$hMap->{$idxR}}=$arf;
			}
		}
		
		my $srtType=0;
		if( defined($bSort) && ::numtest($bSort) && $bSort==1 ){ $srtType=1; }
		say "Sort type $srtType";
		
		my @aNewRowSigOrd=();
		
		if($srtType==0) { 
			@aNewRowSigOrd= map { $_ } sort { $dSigtoVal{$a}<=>$dSigtoVal{$b} } keys %dSigtoVal; 
		}
		elsif($srtType==1) { 
			@aNewRowSigOrd= map { $_ } sort { $dSigtoVal{$b}<=>$dSigtoVal{$a} } keys %dSigtoVal; 
		}
				
		
		for my $RSIG (@aNewRowSigOrd){
			my @aRw=@{$dSigtoRow{$RSIG}};
			my @aJ= map { (length($aRw[$_]) < $dCoLn{$_} ) ? "*" x ( $dCoLn{$_} - length($aRw[$_]) ) . $aRw[$_] : $aRw[$_]  } 0..$#aRw ;
			my $selVal=  ( length($dSigtoVal{$RSIG}) < $dCoLn{$colwant-1} ) ? "*" x ( $dCoLn{$colwant-1} - length($dSigtoVal{$RSIG}) ) . $dSigtoVal{$RSIG} : $dSigtoVal{$RSIG}; 			
			say substr($RSIG,0,7) ."... ($colwant) $selVal , ". join(" _ ", @aJ);
		}	
	}
	
	sub mulxVuntilXYcond { my $p=shift; my $sdoc="ToDo: document"; $p->msgWIP(); }		
	
	sub delFrstRow { my $p=shift; my $marf=$p->{amain}; if( $p->bIsEmpty ) { return; } $p->delRow(1);  }
	sub delLastRow { my $p=shift; my $marf=$p->{amain}; if( $p->bIsEmpty ) { return; } $p->delRow(scalar(@$marf)); }		
	sub delRow { my $sdoc="Delete row i";
		my ($p,$idxD)=@_; my $marf=$p->{amain}; my @aRV=(); 
		while ( my ($idx,$arf)=each @$marf ){ 
			if($idx!=$idxD-1){ push @aRV, $arf; }
			else { say "Delete row $idxD: ". join(" _ ", @$arf); }
			$p->{amain}=\@aRV;
		}
	}
	sub delCol { my $sdoc="Delete column i";
	 my ($p,$colnum)=@_;
		my $marf=$p->{amain}; 
		if( scalar(@$marf)==0){ say "Empty matrix"; return; }  
		elsif( ! ::numtest($colnum)){ say "NAN $colnum"; return; }  
		my @aNew=();
		for my $rw (@$marf) { 
			my @aTmp=();
			while ( my ($idxC,$vv)=each @$rw){ 
				if( $idxC!=$colnum-1 ) { push @aTmp, $vv; } 
			}
			push @aNew, \@aTmp;			
		}
		$p->{amain}=\@aNew;
		$p->show();
	}
		
	sub shwMinMax { my $p=shift; my $marf=$p->{amain};  
		my @aAccum=(); 
		for my $R (@$marf){ 
		 my @aVals= sort { $a<=>$b } @$R;
		 push @aAccum, $aVals[0];
		 push @aAccum, $aVals[$#aVals]; 
		}
		@aAccum=sort { $a<=>$b } @aAccum;
		say "Min _ ". $aAccum[0];
		say "Max _ ". $aAccum[$#aAccum];
	}

	sub addColSums {   	#sum all COLUMNS as bottom row 
	 my $p=shift; my $marf=$p->{amain}; 
	 if(scalar(@$marf)==0){ return; }
	 my $carf=$p->getColsArf;
	 my @aColSums=();
	 for my $arfC (@$carf) { push @aColSums, ::sum(@$arfC); }
	 $p->addRow(\@aColSums);		
	 $p->show;
	
	}
	sub addRowSums {    #sum all ROWS on the right as column 
	 my $p=shift; my $marf=$p->{amain}; 
	 if(scalar(@$marf)==0){ return; }
	 my @aSumCol=();
	 for my $arfR (@$marf) { push @aSumCol, ::sum(@$arfR); }
	 $p->addCol(\@aSumCol);	
	 $p->show;	
	}
	
	sub msgStatusEmpty { my $p=shift; say $p->{uic}." Structure has no data."; }				
	sub msgWIP { my $p=shift; say $p->{uic}." not yet implemented."; }	
	sub prHdrs { my $p=shift; if($p->{width}<=0){ return; } my @ah=(); my $hdarf=$p->{ahdrs}; if(scalar(@$hdarf)==0){ @ah=@$hdarf;  } else { @ah=map{ $_ } 1..($p->{width}); say join( " _ ", @ah);}  }	
	sub show { my $p=shift; my $bDbg=0; my $marf=$p->{amain}; 
		say '='x13; $p->prHdrs(); 
		my $carf=$p->getColsArf;
		my %dCoLn=();
		
		while( my ($idxC,$arfC)=each @$carf) {
			$dCoLn{$idxC}= ::max ( map { length($_) } @$arfC );			
		}
		
		if($bDbg){ say ::Dumper(\%dCoLn); }
		
		for my $arfR (@$marf) { 
			my @ary=@$arfR;
			my @aJ= map { (length($ary[$_]) < $dCoLn{$_} ) ? "*" x ( $dCoLn{$_} - length($ary[$_]) ) . $ary[$_] : $ary[$_]  } 0..$#ary ;
			say join(" _ ", @aJ);
		} 
		$p->shape(); say '='x13; 
	}

	sub cloneCol {
		my ($p,$colN)=@_;
		my $carf=$p->getCol($colN);
		$p->addCol($carf);
	}
	
	sub cnvColToNum { #strip non-num chars, assign 0 where the result is invalid
		my ($p,$colN)=@_;
		my @aCnvCol=();
		my $cntCNV=0;
		my $carf=$p->getCol($colN);
		for my $iv (@$carf){ 
			if($iv =~ /\D+/ ){ #|| ! ::numtest($iv) ) { 
				$iv =~ tr/0-9.-//cd; $cntCNV++; 
			} 
			push @aCnvCol, $iv;
		}
		$p->addCol(\@aCnvCol);
		#$p->swapColToPos($p->getWidth , $colN); #TODO delete after swap
		say "cnvColToNum done ($cntCNV converted)"; 
	}

	sub importFileData { my $sdoc="data = rows of comma-separated values";
		
		say $sdoc;  
		my ($p,$fname)=@_; 
		if ( ! -e $fname ) { say "$fname not found."; return; }
		my $marf=$p->{amain};
		open(my $fh, '<', $fname);
		my @aFL=<$fh>;
		chomp(@aFL);
		my %dStats=(); 
		while ( my ($idx,$L)=each @aFL) {
			if(length($L)==0 || $L=~/^\s+$/){ say "empty line in data ($idx) ."; next; } 
			my @aPcs=split(/\s*,\s*/,$L); $dStats{$idx}=\@aPcs; 
			if( $p->{width} <1 ){ $p->setWidth(\@aPcs);   } 
			elsif( $p->{width}!= scalar(@aPcs) ){ say "import warning, row $idx"; }		
			push @$marf,\@aPcs; 
		}
		
		my @aValsToAvg=();
		for my $k (sort { $a<=>$b} keys %dStats){
			push @aValsToAvg , scalar( @{$dStats{$k}} );
		} 
		my $avgVal=::mathGetIntegral(::computeMean(\@aValsToAvg));
		 
		say "Import statistics (average segments=$avgVal)"; 
		for my $k (sort { $a<=>$b} keys %dStats){
			my $LNG=scalar( @{$dStats{$k}} );
			if($LNG==$avgVal) { print "Length $k=".scalar( @{$dStats{$k}} )." "; }
			else{ say "\n".'x'x20 . "> Length $k $LNG != avg $avgVal"; } 
		}
		$p->shwRow(1);
	 }

};

#subroutines 
#friendly subroutine interfaces
sub help {
 my @aFuncs=("getColFromFile" , "doSummaryCalcs");	
 say "Use the friendly subroutines to perform basic operations with data.";	
 say "@aFuncs";	
}

sub getColFromFile { #params: colnum, filename // colnum is human ordinal; split on space; excludes #cmt and empty lines

	my ($colnum, $fname)=@_;
	say "Open $fname , return column $colnum"; 
	my $arfdata=openFileRetArf( $fname );
	say "@$arfdata";
	
	my @aVals=();
	for my $L (@$arfdata) { chomp($L); say $L; }

	for my $L (@$arfdata) { 
		chomp($L); if($L=~/^#/ || length($L)==0 ) { next; } 
		my @aParts=split(/\s+/,$L); push @aVals,$aParts[$colnum-1];
	}
	say "Column stored: ".join(" ;; ", @aVals);
	return \@aVals;
}

sub mksqbracks { my $v=shift; return "[ $v ] " ; }
sub mkDivider { my $val=shift; say "\n". 'x' x 80 . "_$val\n"; }
sub getkbinput { my $msg=shift; say $msg; my $kbStr=<STDIN>;chomp($kbStr); return $kbStr; } 
sub getUIC { my $arg=shift; return getSHA($arg ."_". (getEntropyVal() + int rand(__LINE__) + int rand(time)) ); }
sub getSHA { my $arg=shift; return sha256_hex($arg); }
sub getEntropyVal { my $rv=$giENTRPY; $giENTRPY++; return $rv; }
sub numtest { my $n=shift; my $rv=0; if(looks_like_number($n)){ $rv=1; } return $rv; }
sub bAreAllNumbers { my $arf; my $nint=0; my $bRV=0; map { $nint++ if(! numtest($_) ) } @$arf; $nint > 0 ? $bRV=0 : $bRV=1; return $bRV; }  
sub sortArfAscDes {
	my ($arf , $mode)=@_; # 0 asc 1 desc
	$mode = 0 if(! defined $mode);
	my @aRV=();
	if( bAreAllNumbers($arf) ){ 
		if( $mode==0 ) { @aRV = sort { $a<=>$b } @$arf; } 
		else { @aRV = sort { $b<=>$a } @$arf; } }
	else { 
		if( $mode==0 ) { @aRV = sort {"\L$a" cmp "\L$b"} @$arf; } 
		else { @aRV = sort {"\L$b" cmp "\L$a"} @$arf; } }
	return \@aRV; 
}
sub addDictKeyIfNot { my $sdoc="Add/update key to dict of arrays";
	my ($hrf,$key,$val)=@_;				
	if( exists $hrf->{$key}) { my $arf=$hrf->{$key}; push @$arf, $val; }
	else { my @aTmp=(); push @aTmp, $val; $hrf->{$key}=\@aTmp; }
}
sub mkstr { my $arf=shift; return join(" ", @$arf); }
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
sub gettypeinfo { 
	my ($var, $hint)=@_; #hint based on string match of sigil # 0=UNK , 1=SCALAR, 2=ARRAY , 3=DICT , 4=REF
	my %dRV=( bSuccess=>0 , type=>0 , msg=>"none"); # 0=UNK , 1=SCALAR, 2=ARRAY , 3=DICT , 4=REF
	if(! ref($var)) { 
		$dRV{bSuccess}=1; $dRV{type}=1; $dRV{msg}="scalar $var ";  
		$dRV{msg}.=" numeric" if(looks_like_number($var)); 
		$dRV{msg}.=" hint=$hint"; 
	}
	elsif(ref($var)) {  
		$dRV{bSuccess}=1; $dRV{type}=4; $dRV{msg}="ref $var\n".encode_json $var;  
	}
	else { $dRV{msg}=encode_json $var; }
	#else { say Dumper ($var); }
	return \%dRV; 
}	
sub dec2hex { my $d=shift; return sprintf( "%x" , $d ); }
sub padint { my $i=shift; if ($i<10){ return "  ".$i;} elsif ( $i < 100) { return " ".$i} else {return $i;} }


sub getHrfModsFromINC {	
	my %dRV=();
	my @aINCpaths=(); #push @aINCpaths, $_ foreach (@INC);
	for my $incp (@INC){ 
		push @aINCpaths, $incp;
		my $stoutINC= qx/find $incp -type f -iname "*.pm"/ ;  	
		my @aLines=split('\n',$stoutINC);
		for my $L (@aLines){ 
			my $fK=$L;
			$dRV{$fK}=1;
			$L=~s/$incp//i;
			$L=~s/^\///;
			$L=~s/\.pm$//i;
			$L=~s/\//::/g;
			$dRV{$fK}=$L;
		}
	}
	return \%dRV;
	
}

sub getModsCpanHrf {
	my %dRV=();
	my $stoutCpan=qx/cpan -l/;
	my @aLines=split('\n',$stoutCpan);
	for my $L (@aLines) { my @aPcs=split(/\s+/,$L); my @aTmp=(); push @aTmp,$aPcs[1]; $dRV{$aPcs[0]}=\@aTmp; }
	return \%dRV;
}
sub getCpanmModsHrf {
	my %dRV=();
	my $oMD = ExtUtils::Installed->new();

	for my $module (sort $oMD->modules()) {
		if(exists $dRV{$module}){  
		 my $arf=$dRV{$module};
		 push @$arf, $oMD->version($module);	
		}
		else {  
			my @aVers=();
			push @aVers, $oMD->version($module);
			$dRV{$module}=\@aVers;
		}
	}
	return \%dRV;
}
sub listModulesCpanm {
	my $hrfRV=getCpanmModsArf();
	for my $k (sort keys %$hrfRV){
		my $arf=$hrfRV->{$k};
		say $k ." versions: " . join (" ;; ", sort @$arf);
	}
	say "Done! ". scalar(keys %$hrfRV)." modules (cpanm).";
}

sub listAllModules { my $sdoc="List all modules, compare versions";
 my $p=shift;
 my $hrf=_reportModulesRetRef();
 for my $k ( sort keys %$hrf) { say '*' x 60 . "\n$k=\n". join("\n", @{$hrf->{$k}}); }
}

sub _reportModulesRetRef {
	my $bDbg=0;
	my %dCounts=();
	my %dRV=();
	my ($onever, $samever, $diffver)= ("_1ver", "_samever", "_diffver");
	for my $key ( $onever, $samever, $diffver ) { my @aTmp=(); $dRV{$key}=\@aTmp; }
	for my $key ( $onever, $samever, $diffver ) { $dCounts{$key}=0; }
	
	my $dhrfCPAN=getModsCpanHrf;
	say join(" ;; ", sort keys %$dhrfCPAN)  if($bDbg==1);
	my $dhrfCPANM=getCpanmModsHrf;
	say join(" ;; ", sort keys %$dhrfCPANM)  if($bDbg==1);
	my $dhrfCPANINC=getHrfModsFromINC;
	say join(" ;; ", sort values %$dhrfCPANINC)  if($bDbg==1);

	my %dAllKeys=();
	for my $hrf ( $dhrfCPAN, $dhrfCPANM ) { map { $dAllKeys{$_}++ } keys %$hrf; } 

	for my $k (sort keys %dAllKeys){
		my $matchkeyUsed; #keep as undef;
		my $phrase; #keep as undef
		
		if( $dAllKeys{$k} == 1) {  
			if(exists $dhrfCPAN->{$k}) { 
				$phrase= "=> $k in CPAN: ". join(" ;; ", @{$dhrfCPAN->{$k}} ) ;
				say $phrase  if($bDbg==1);  $matchkeyUsed=$onever;
			}
			elsif( exists $dhrfCPANM->{$k}) { 
				$phrase= "=> $k in CPANM: ". join(" ;; ", @{$dhrfCPANM->{$k}} ) ; }
				say $phrase  if($bDbg==1);  $matchkeyUsed=$onever;
		}
		elsif( $dAllKeys{$k} > 1) {
			if( join("",sort @{$dhrfCPAN->{$k}}) eq join("",sort @{$dhrfCPANM->{$k}}) ) {    
			  $phrase= "=> $k (". __LINE__ .") the same in CPAN, CPANM: ". join(" ;; ", @{$dhrfCPAN->{$k}} ) ." /****/ => $k in CPANM: ". join(" ;; ", @{$dhrfCPANM->{$k}} );
			  say $phrase if($bDbg==1);  $matchkeyUsed=$samever;
			}

			elsif( scalar ( keys %$dhrfCPAN ) == scalar( keys %$dhrfCPANM ) && join("",sort @{$dhrfCPAN->{$k}}) eq join("",sort @{$dhrfCPANM}->{$k}) ) {    
			  $phrase= "=> $k (". __LINE__ .") the same in CPAN, CPANM: ". join(" ;; ", @{$dhrfCPAN->{$k}} ) ." /****/ => $k in CPANM: ". join(" ;; ", @{$dhrfCPANM->{$k}} );   
			  say $phrase  if($bDbg==1);  $matchkeyUsed=$samever;
			}
			else {  
			  $phrase= "=> $k (". __LINE__ .") DIFF in CPAN, CPANM: ". join(" ;; ", @{$dhrfCPAN->{$k}} ) ." /****/ => $k in CPANM: ". join(" ;; ", @{$dhrfCPANM->{$k}} );   
			  say $phrase if($bDbg==1); $matchkeyUsed=$diffver;
				 
			}
		}
		$dCounts{$matchkeyUsed}++;
		addDictKeyIfNot( \%dRV , $matchkeyUsed , $phrase );
		
		my @aINCsearch=grep { $_ =~ /^$k$/ } sort values %$dhrfCPANINC ;  
		if (scalar(@aINCsearch)>0) {
			my $indent="__**"; 
			my @aReverseKeys = grep{ $dhrfCPANINC->{$_} eq $k } keys %$dhrfCPANINC;		 
			$phrase= "$indent $k in \@INC:\n$indent ". join("\n$indent " , @aReverseKeys); 
			say $phrase if($bDbg==1);
			addDictKeyIfNot( \%dRV , $matchkeyUsed , $phrase );			
			
		} 
	}
	say "Field counts: ".join(" ;; ", map { "$_ => ". $dCounts{$_} } sort keys %dCounts);	
	say "Dictionary keys are: ".join(" ;; ", sort keys %dRV);
	return \%dRV;
}


sub mulmxm { my $sDoc="multiply one matrix by another matrix, yield a matrix";
	my $bDBG=0;
	say mkstr([__LINE__,$sDoc]);
	my ($oM1,$oM2)=@_;
	my $oRVM=cMatrix->new; 
	if($oM1->getType() ne $oM2->getType() ) { 
		say mkstr( [__LINE__, "Error:", $oM1->getType()." ne ".$oM2->getType()]); 
		return $oRVM;
	}
	my $arfM1=$oM1->getRowsArf;
	my $arfM1asCols=$oM1->getColsArf;
	
	my $arfM2asRows=$oM2->getRowsArf;
	my $arfM2=$oM2->getColsArf;
	my %dRV=();
	my $iErrors=0;
#	say mkstr([__LINE__,"section:checks"]);
	
	#invariant: compare arfM1, arfM2
	my ($cmpLARF1, $cmpLARF2)=( scalar(@$arfM1asCols), scalar(@$arfM2asRows) );
#	my ($cmpLARF1, $cmpLARF2)=( scalar(@$arfM1asCols), scalar(@$arfM2) );

	if($cmpLARF1 != $cmpLARF2){ say mkstr([__LINE__,"Error,","m1 row length $cmpLARF1 :=: m2 column height $cmpLARF2"   ]); $iErrors++; }
	
	
	my %dM1=();
	while (my($idxM1R,$rarfM1)=each @$arfM1){ $dM1{$idxM1R}=scalar(@$rarfM1);} 
	my @aRcountsM1=sort { $a<=>$b } values %dM1 ;
#	say __LINE__." checks: ". join(" , ", @aRcountsM1);
	if($aRcountsM1[0] ne $aRcountsM1[$#aRcountsM1]){ $iErrors++; } 
	
	my %dM2=();
	while (my($idxM2C,$rarfM2)=each @$arfM1){ $dM2{$idxM2C}=scalar(@$rarfM2);} 
	my @aRcountsM2=sort { $a<=>$b } values %dM2 ;
#	say "checks: ". join(" , ", @aRcountsM2);
	if($aRcountsM2[0] ne $aRcountsM2[$#aRcountsM2]){ $iErrors++; } 
	if($iErrors==0 && $aRcountsM1[0] ne $aRcountsM2[0]){ $iErrors++; } 
	if($iErrors>0){ say mkstr( [__LINE__, "Errors $iErrors", $oM1->getType()." and ".$oM2->getType()]); }
	else { say mkstr( [__LINE__, "Checked!", $oM1->getType()." and ".$oM2->getType()]); }
	
	if(scalar(@$arfM1)!=scalar(@$arfM2)){ $iErrors++; }
	
	#section:multiply
	if($iErrors==0){
		#for each M1row create an MRVcol => =DEF for each M2col create an MRVrow 
#		for my $rowrfM1 (@$arfM1){#for each M1 row
		while( my ($idxRARF, $rowrfM1)=each @$arfM1){#for each M1 row
			my $rwSzZrB=scalar(@$rowrfM1)-1;
			#say mkstr([ __LINE__,"Rsz",scalar(@$rowrfM1)]); 			
			while ( my ($idxCARF,$carf)=each @$arfM2){ #take each colarf
				my @aAccum=();
				for my $rc (0..$rwSzZrB){ 
					#say mkstr([ __LINE__,"R=$rc","C=$idxCARF",$rowrfM1->[$rc]." x ". $carf->[$rc] , "L(aAccum)=".scalar(@aAccum)]); 
					push @aAccum, $rowrfM1->[$rc] * $carf->[$rc];
				}
				addDictKeyIfNot(\%dRV,$idxRARF,sum(@aAccum));

			} 

		}
#		say mkstr( [ __LINE__, "DBG:", join(" ;; ",sort { $a<=>$b } keys %dRV) ]);
		my @aRV=map { $dRV{$_} } sort { $a<=>$b } keys %dRV;
		$oRVM->setRowsArf(\@aRV);		
	}
	else { 	
		say mkstr( [__LINE__, "Errors $iErrors", $oM1->getType()." and ".$oM2->getType()]);
		$oM1->show; $oM2->show; 
	} 
		

	return $oRVM;	
}
sub getDTPrefix {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime;
	$mon = $mon +1; #0 based
	if($mon < 10){$mon = "0".$mon;}
	if($mday < 10){$mday = "0".$mday;}
	if($hour < 10){$hour = "0".$hour;}
	if($min < 10){$min = "0".$min;}
	if($sec < 10){$sec = "0".$sec;}
	my $tst = $year+1900 . "-" . $mon . "-" . $mday . "_" . $hour . $min . "-" .  $sec;
	return $tst;	
}

sub getDayOfWeekNumExYMDarf { # return number of day of week from arf YYYY, MM, DD
 my $bDbg=0;
 my $arfYMD=shift;
 my %dRV=(brvgood=>0,rv=>0);
# sec min hours dd mm yyyy
 my @LT=localtime( timelocal_posix(0,0,0,$arfYMD->[2],$arfYMD->[1]-1,$arfYMD->[0]-1900)) ;
 if($bDbg==1) { say join(" ;; ",@LT); }
 my $rv = $LT[6];
 if($bDbg==1) { say "rv=$rv"; }
 $dRV{brvgood}=1; $dRV{rv}=$rv;
 return \%dRV;
}


sub getNumDaysInYear { # return the number of days in year from YYYY
 my $yyyy=shift;
 my %dRV=(brvgood=>0,rv=>0);
 my $rv = (localtime(timelocal_posix(0,0,0,31,11,$yyyy-1900)) )[7];
 $rv++; #increment zeroth day for count
 $dRV{brvgood}=1; $dRV{rv}=$rv;
 return \%dRV;
}


sub roundXtoYdecimals { my ($f , $dp) = @_; return sprintf("%.".$dp."f", $f); }
sub mathround { my ($n, $p) = @_; return sprintf("%.${p}f", $n);} #arg array: float, precision
sub mathfloor { my $n = shift; return mathGetIntegral($n); }
sub mathceiling { my $n = shift;
	if(mathHasDecimal($n)) {
		if(mathGetFractional($n) > 0) { return mathGetIntegral($n) + 1; }
	}
	return $n;
}
sub mathGetIntegral { my $n = shift; if($n=~/\./) { $n =~ s/\.\d*//;} return  $n ; }
sub mathGetFractional { my $n = shift; if($n=~/\./) { $n =~ s/.*\.//;} return  $n ; }
sub mathHasDecimal { my $n = shift; if($n=~/\./){return 1; } else { return 0;} }
sub computeMinMax { #arg is a REFERENCE to an array of numbers;
	my $r = shift;
	my @arySrt=sort { $a <=> $b }  (@$r); 
	return  ( $arySrt[0],$arySrt[ $#arySrt  ] );
}

sub computeMedian { #arg is a REFERENCE to an array of numbers; to do: test values from POSIX implementation of ceil and floor
	my $r = shift;  my $c =scalar( @$r);
	my @as = sort { $a <=> $b } @$r;
	my $rv = -1;

#	if($c % 2) { my $iv = floor($c/2) + 1 ; return $as[$iv];} #odd range
	#handle case of all values being the same
	my %kvariance=();
	$kvariance{$_}++ for (@as);

	if ( scalar ( keys %kvariance) == 1) { my @arKys= keys %kvariance; $rv = $arKys[0]; }
	elsif($c % 2) { my $iv = mathfloor($c/2) + 1 ; $rv =  $as[$iv];} #odd range
#	else { my $n1 = $as[floor($c/2)] + $as[ceil($c/2)]; return ($n1/2); } #even range
	else { my $n1 = $as[mathfloor($c/2)] + $as[mathceiling($c/2)]; $rv =  ($n1/2); } #even range
	return $rv;
}
sub computeSum { #arg is a REFERENCE to an array of numbers;
	my $r = shift;
	my $t=0;
	for my $val (@$r){ $t += $val }; #assume valid numbers
	return $t;
}
sub computeMean { #arg is a REFERENCE to an array of numbers;
	my $r = shift;
	my $t=computeSum($r);
	return $t/scalar(@$r);
}

sub computeStnDev { #arg is a REFERENCE to an array of numbers;
	my $r = shift;
	my $m=computeMean($r);
	my @aSqV=();
	for my $inval (@$r) { my $d=$inval-$m; push @aSqV,$d*$d; }
	$m = computeMean(\@aSqV);
	return sqrt($m);
}

###do integers differ by At Least One Order Of Magnitude
sub isXgtYbyALOOM {
	my ($x,$y)=@_;
	return 0 if ($x <= $y);
	return 1 if ($x/$y >= 10);
	return 0 if ( $x-$y < $y);
	return 1 ;
}
sub FOOMFOI{ #Find Orders Of Magnitude From Ordered Integers
	my $aR = shift;
	my @a = @$aR;
	my @rv=();
	for (my $i=0; $i<= $#a-1; $i++) {
		if ( isXgtYbyALOOM( $a[$i] , $a[$i+1]) ) { push @rv , $i; }
	}
	say "@rv";
	return \@rv;
}

sub computeFrequency { 
	my $bDbg=1;
	my $arf = shift;
	my %rvH=();
	my %freqH=();
	for my $i (@$arf) {
		if (exists $freqH{$i}) { $freqH{$i}++; }
		else { $freqH{$i} = 1; }
	}
	say "@$arf";
	#determine output order
	my $orderMode=0; 
	my @minmax=computeMinMax( [ values %freqH ] ); 
	if( $minmax[0] == $minmax[1] ) { $orderMode=1; } #use original order
	
	my @orderedKeys=();
	my @aSrtVals= reverse uniq sort { $a<=>$b } values %freqH; #note uniq sort 
	
	if($bDbg==1){ say "@aSrtVals";}
	
	for my $Val (@aSrtVals){ 
		for my $vorig (uniq @$arf) { #note uniq
		 if ($freqH{$vorig}==$Val) { push @orderedKeys, $vorig; }				
		}
	}
	
	$rvH{akorder}=\@orderedKeys;
	if ($orderMode==1) { $rvH{akorder}=$arf; }
	
	$rvH{hdata}=\%freqH;

	return \%rvH;
}

sub doSummaryCalcs { #arg1 = arf of numbers ; arg2 = description of data
	
		my ($arfNums,$taskdesc)=@_;
		if( ! defined($taskdesc) ){ $taskdesc="summary calculations"; }
		mkDivider(mksqbracks(__LINE__));
		say mksqbracks(__LINE__). " begin $taskdesc array size ". scalar(@$arfNums) ;
		my $hResponse = computeFrequency($arfNums);
		my $hData = $hResponse->{hdata};
		for my $k ( @{$hResponse->{akorder}} ){
			say "count $k = freq $hData->{$k}"
		}
		
 		mkDivider(mksqbracks(__LINE__));
 		my $sum=computeSum($arfNums);
 		say "sum _ $sum = ". join(" + ",@$arfNums) ;
  		mkDivider(mksqbracks(__LINE__));		
 		my %dPCG=();
 		say "% values in place _ ". join(" ;; ", map { "$_ (". ($_/$sum)*100 .")"  } @$arfNums) ;
  		mkDivider(mksqbracks(__LINE__));		
 		map { $dPCG{$_}=($_/$sum)*100 } @$arfNums ;
 		say "% values sorted _ ". join(" ;; ", map { "$_ (". $dPCG{$_} .")"  } sort {$dPCG{$b}<=>$dPCG{$a}} keys %dPCG );  

 		mkDivider(mksqbracks(__LINE__)); 		
		my @amnmx=computeMinMax( [  keys %$hData ] );

		say "minmax _ ". join( " ;; ", @amnmx);	
		say "mean _ ". computeMean([ keys %$hData ]);
		say "median _ ". computeMedian([ keys %$hData ]);
		say "standev _ " . computeStnDev([ keys %$hData ]);		

		say mksqbracks(__LINE__) . " end $taskdesc array size ". scalar(@$arfNums);
		mkDivider(mksqbracks(__LINE__));
		return $hResponse;
	
}	


sub openFileRetArf { my $f=shift; my @ary=(); 
	if(! -e $f) { unshift @ary, mksqbracks(__LINE__); unshift @ary, "File $f not found."; doMsgArf(\@ary);}
	else { open( my $SF, "<", $f ); @ary=<$SF>; close($SF); 
	 chomp(@ary);
	 say "Read \"$f\" , line count ". scalar(@ary); 
	 say "Tip: next you might try\nfor my \$L (\@\$arf) { say \$L; }\nor\nsay join(\"\\n\",map{ \$fdata->[\$_] } 0..5);";
	 return \@ary; 
	}
}

sub listDATA { #list data appended as __DATA__
	my $data_start = tell DATA;
	while (my $inline=<DATA>) { 
		chomp($inline); next if not length $inline;  

		if ($inline =~ /^#/) { say "Comment: $inline" ; }
		else {
			  my @aLwhspc=();
			  @aLwhspc=split(/\s+/,$inline); 
			  my @aLcomma=();
			  @aLcomma=split(/,/,$inline); 			  
#			  say __LINE__." $inline __ has ". scalar(@aLwhspc) ." pieces split on spaces, ". scalar(@aLcomma) ." pieces split on commas.";
			  say "Listing: $inline __ has ". scalar(@aLwhspc) ." pieces split on spaces, ". scalar(@aLcomma) ." pieces split on commas.";

		}
	}
	seek DATA, $data_start, 0;
}
sub readDATA { #read data appended as DATA , return HRF; param01: split on space "0" or split on comma "1" ;; param02: 2=rv No ARF , 3=rv yield ARF
	my $data_start = tell DATA;
	my @args=@_;

	my $modesplt=0;
	my $moderv=0;
	my @aRV=();
	my %dRVSet=();
	$dRVSet{arf}=\@aRV;
	$dRVSet{arfsz}=0;

	if(scalar(@args)){ say "Args for processing __DATA__ : ". join(" ;; ", @args); }
	for my $arg (@args){
		if ($arg < 2) { if($arg == 1){ $modesplt=$arg; } } 
		elsif($arg==2 || $arg==3){ if($arg == 3){ $moderv=$arg; } }
	}

	
	while (my $inline=<DATA>) { 
		chomp($inline); next if not length $inline;  


		if ($inline =~ /^#/) { say "Comment: $inline" ; }
		else {
			  my @aL=();
			  if($modesplt==0) { @aL=split(/\s+/,$inline); }
			  elsif($modesplt==1) { @aL=split(/,/,$inline); }			  
#			  say __LINE__." $inline __ has ". scalar(@aL) ." pieces, mode=$modesplt";
			  say "Reading: $inline __ has ". scalar(@aL) ." pieces, mode=$modesplt";
			  
			  if( $moderv==3 ){ push @aRV, \@aL; }
			
		}
	}
	seek DATA, $data_start, 0;
	$dRVSet{arfsz}=scalar(@aRV);
	return \%dRVSet;
}

sub checkIPtype {
	my $Linf = shift;
	my @aMsgs=();
	
	my %dRV=( bSuccess=>0 , bRV=>0 , arfMsgs=> \@aMsgs , inVal=>$Linf ); 
	
	say __LINE__. " Checking $Linf";
		
	my $ipaddrtype=0; #1 = ipv4 , 2 = ipv6 , 3 = local/private

	my @arrIP=split /\./,$Linf;
	
	if ( scalar(@arrIP) == 4 && defined $Linf) { 
		push @aMsgs,  __LINE__ . " $Linf type $ipaddrtype scalar=".scalar(@arrIP);
		$ipaddrtype=1;
		$dRV{bSuccess}=1; 
		$dRV{bRV}=$ipaddrtype;		
	}
	elsif ( $Linf =~ /:/ ) { 
		$ipaddrtype=2;	
		push @aMsgs,  __LINE__ . " TODO: improve IPV6 check. $Linf type $ipaddrtype scalar=".scalar(@arrIP);			
	}
	

	#if private or localhost
	
	#10.0.0.0 - 10.255.255.255
	#172.16.0.0 - 172.31.255.255
	#192.168.0.0 - 192.168.255.255
	#169.254.0.1 through 169.254.255.254 APIPA M-Windows

	
	if($dRV{bSuccess}==1 && $ipaddrtype==1){
	  if( $arrIP[0]==10 || ( $arrIP[0]==172 && $arrIP[1]>=16 && $arrIP[1]<=31 ) || (  $arrIP[0]==192 && $arrIP[1]==168 ) || ( $arrIP[0]==169 && $arrIP[1]==254  )  ) {  
		push @aMsgs,  __LINE__ . " $Linf type $ipaddrtype is non-routable"; 
		$dRV{bSuccess}=0 ; $ipaddrtype=3 ;	$dRV{bRV}=$ipaddrtype;
	  }
	}

	if($dRV{bSuccess}!=1){ 
		say join(" ;; ", map { $_ ." => ". $dRV{$_} } sort keys %dRV  ) ;
		say join(" ;; " , @aMsgs); 
	}


	return \%dRV;
}

sub getCIDRrange {

	my $cidrStr=shift;
	my ($ipaddr,$sz)=split("/", $cidrStr);
	my %dRVcidr=( bSuccess=>1 , invalue=>$cidrStr, intIPV4stt=>0, intIPV4end=>0 , froctIPV4stt=>0, froctIPV4end=>0 );	
	
	my $hrfRV=checkIPtype( $ipaddr );
	if( $hrfRV->{bSuccess} != 1 ) { 
		say "Error: ". join(" ;; ", map { $_ ." => ". $hrfRV->{$_} } keys %$hrfRV );
		$dRVcidr{bSuccess}=0;
	} 
	elsif( $sz > 32  ) { 
		say "Error: check value $cidrStr";
		$dRVcidr{bSuccess}=0;
	} 
	
	if(	$dRVcidr{bSuccess}==1 ) {

		my @bytes = split /\./, $ipaddr;
		my $start_decimal = $bytes[0] * 2**24 + $bytes[1] * 2**16 + $bytes[2] * 2**8 + $bytes[3];
		my $bits_remaining = 32 - $sz;
		my $end_decimal = $start_decimal + 2 ** $bits_remaining - 1;
		@bytes = unpack 'CCCC', pack 'N', $end_decimal;
		my $end_ipv4 = join '.', @bytes; 
		$dRVcidr{intIPV4stt}= $start_decimal ;
		$dRVcidr{intIPV4end}= $end_decimal ;
		$dRVcidr{froctIPV4stt}= cnvIntToIPV4($start_decimal) ;
		$dRVcidr{froctIPV4end}= cnvIntToIPV4($end_decimal) ;
		say "RV keys: ". join(" ;; ", sort keys %dRVcidr ) ; 

	}
	return \%dRVcidr;
	
}

sub cnvIPV4toInt {
	my $ipaddr=shift;
	my $hrfRV=checkIPtype( $ipaddr );
	my $iRV=-1; #type Long
	
	if( $hrfRV->{bSuccess} != 1 ) { 
		say "Error: ". join(" ;; ", map { $_ ." => ". $hrfRV->{$_} } keys %$hrfRV );
	} 
	else {
		my @arrIP=split /\./,$ipaddr;		
		my $iLong= $arrIP[0]*256**3 + $arrIP[1]*256**2 + $arrIP[2]*256 + $arrIP[3];
		$iRV=$iLong; 

	# 	(first octet * 256³) + (second octet * 256²) + (third octet * 256) + (fourth octet)
	#= 	(first octet * 16777216) + (second octet * 65536) + (third octet * 256) + (fourth octet)
	#= 	(142 * 16777216) + (127 * 65536) + (180 * 256) + (149)
	#= 	2390733973
	
	}	

	return $iRV;

}

sub cnvIntToIPV4 {
	my $iLong=shift;
	my $int=$iLong;

	if( ! looks_like_number($iLong) ) { #must be a decimal number
		say "Error: Not a number? $iLong";
		exit(0);
	} 

	my $quad4       = $int % 256; $int      = int($int/256);
	my $quad3       = $int % 256; $int      = int($int/256);
	my $quad2       = $int % 256; $int      = int($int/256);
	my $quad1       = $int % 256;

	return "$quad1.$quad2.$quad3.$quad4";

}

sub sortAsVersInt { #versint is 2020.01.30 or 2020.2021.2022 &c
 my $bDbg=1;
 my ( $lside, $rside ) = @_;
 if($bDbg){ say mksqbracks(__LINE__). " cmp $lside // $rside"; }
 
 my @aryMsgs=();
 my %dData= ( rvint=>0, lspcs=>0, rspcs=>0, arfmsgs=>\@aryMsgs );

 my @lpcs=split(/\./,$lside); 
 my @rpcs=split(/\./,$rside);
 $dData{lspcs}=scalar(@lpcs); $dData{rspcs}=scalar(@rpcs);
 if($bDbg){ say mksqbracks(__LINE__). " cmp $dData{lspcs} // $dData{rspcs}"; }
 
 
 if($bDbg){ 
  say mksqbracks(__LINE__). "dump array values:"; 
  say "L ary = " . $dData{lspcs}; say join(" ;; ", @lpcs); 
  say "R ary = " . $dData{rspcs}; say join(" ;; ", @rpcs); 
  }
 
 
 if( $dData{lspcs} == $dData{rspcs} ) {
  if($bDbg){ say mksqbracks(__LINE__). " cmp equal sizes"; }
  for (my $i=0; $i<=$#lpcs; $i++) {
   if($lpcs[$i] < $rpcs[$i]) { $dData{rvint}=-1; last; }
   elsif($lpcs[$i] > $rpcs[$i]) { $dData{rvint}=1; last; }
  } # close for loop

  if($bDbg){ say mksqbracks(__LINE__). "rv = $dData{rvint} , $lside , $rside"; }
 }# close if test

 elsif ( $dData{lspcs} > $dData{rspcs} ) {
	 if($bDbg){ say mksqbracks(__LINE__). " cmp L > R"; }
  for (my $i=0; $i<=$#rpcs; $i++) { # test up to end of rpcs
   if($lpcs[$i] < $rpcs[$i]) { $dData{rvint}=-1; last; }
   elsif($lpcs[$i] > $rpcs[$i]) { $dData{rvint}=1; last; }
  }#close for loop
 #test remaining values of lpcs IFF rvint==0
  if($dData{rvint}==0) { for(my $i=scalar(@rpcs);$i<=$#lpcs;$i++){ if($lpcs[$i] > 0){$dData{rvint}=1; last;} } }
  if($bDbg){ say mksqbracks(__LINE__). "rv = $dData{rvint} , $lside , $rside"; }
 }#close elsif

 elsif ( $dData{lspcs} < $dData{rspcs} ) {
	 if($bDbg){ say mksqbracks(__LINE__). " cmp L < R"; }
  for (my $i=0; $i<=$#lpcs; $i++) { # test up to end of lpcs
   if($lpcs[$i] < $rpcs[$i]) { $dData{rvint}=-1; last; }
   elsif($lpcs[$i] > $rpcs[$i]) { $dData{rvint}=1; last; }
  }#close for loop
#test remaining values of rpcs IFF rvint==0
 if($dData{rvint}==0) { for(my $i=scalar(@lpcs);$i<=$#rpcs;$i++){ if($rpcs[$i] > 0){$dData{rvint}=1; last;} } }
 if($bDbg){ say mksqbracks(__LINE__). "rv = $dData{rvint} , $lside , $rside"; }

 }#close elsif
 
 if($bDbg){ say mksqbracks(__LINE__). "rv = $dData{rvint} , $lside , $rside"; }
 return $dData{rvint}; #return the int decision required by sort
}##

sub getLongestSeq { #for each line in arf, split the characters and count occurrences
	my $arfL=shift;
	for my $L (@$arfL) { 
	 my @aA=split(//,$L); say "$L = ". scalar(@aA); 
	 my $oLO=cOrdict->new();
	 
	 #$oLO->dbgOn();

	 while ( my ($idx,$aLttr)=each @aA) {
		 $oLO->addKV($idx, $aLttr); #key is unq idx, val is char; char space is sha256
	 }
	 $oLO->identify();
	 $oLO->listKeys();
	 $oLO->listValues();
	 my @aUSeq=(); my @aCurrSeq=();
	 my $arfVals=$oLO->getValsArf();
	 my %dSeen=();
	 for my $Vchar (@$arfVals) {
		 if(exists $dSeen{$Vchar}){ #drop seq if contains repeated symbol 
			 if(scalar(@aCurrSeq) > scalar(@aUSeq)) { #capture seq if longest
				 @aUSeq=@aCurrSeq; 
			 }
			 @aCurrSeq=(); #start new search
			 push @aCurrSeq, $Vchar; #add first character
			 %dSeen=(); #blank the list of seen
		 } 
		 else { push @aCurrSeq, $Vchar; }
		 $dSeen{$Vchar}=1; 
	 }
	 say mksqbracks(__LINE__)." full sequence = ". join(" ;; ", @$arfVals);	
	 say mksqbracks(__LINE__)." longest unique sequence = (". scalar(@aUSeq) .") ". join(" ;; ", @aUSeq);
	 

	}##
}


