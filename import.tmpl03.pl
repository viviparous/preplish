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


my $giENTRPY= 1 + int rand(time);


# list args
if (scalar(@ARGV)==0){ say "( ".__LINE__." No command-line args received. )"; }
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
			 $dKVp{$a}=0; $iToggle=1;
			}
			else { $dKVp{$aArgs[$idx-1]}=$a; $iToggle=0; }
		}
		say mksqbracks(__LINE__). "KVP args: ". join(" ;; ", map { $_ ." = ". $dKVp{$_} } keys %dKVp);
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
		my $self = { uic=>$class."-".$uicInt , aKeys=>\@aKeys , dRefData=>\%dRefData , dKeysVals=>\%dKeysVals , aHdrNyms=>\@aHdrNyms, bDbg=>0 };
		return bless $self, $class;
	}
	
	sub dbgOff { my $self=shift; $self->{bDbg}=0; }
	sub dbgOn { my $self=shift; $self->{bDbg}=1; }
	
	sub identify { my $self=shift; say "cOrdict ". substr($self->{uic}, 0, int (length($self->{uic})/2) ) . "... ";}	
	sub identifyLong { my $self=shift; say "cOrdict ". $self->{uic};}

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
		my $self = { uic=>$class."-".$uicInt , aKeys=>\@aKeys , dRefData=>\%dRefData , dKeysVals=>\%dKeysVals , aHdrNyms=>\@aHdrNyms, bDbg=>0 };
		return bless $self, $class;
	}
	
	sub dbgOff { my $self=shift; $self->{bDbg}=0; }
	sub dbgOn { my $self=shift; $self->{bDbg}=1; }
	
	sub identify { my $self=shift; say "cOrdict ". substr($self->{uic}, 0, int (length($self->{uic})/2) ) . "... ";}	
	sub identifyLong { my $self=shift; say "cOrdict ". $self->{uic};}

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
		};
	my $obj=bless $self,$class;
	return $obj;
	}
	sub getType { my $p=shift; return $p->{type}; }
	sub setHdrs {my ($p,$rarf)=@_; my $marf=$p->{ahdrs}; my @aTmp=(); if(scalar(@$rarf)==0){ return; } for my $val (@$rarf) { push @aTmp, $val; } push @$marf, \@aTmp; $p->shape(); }
	sub addRow {
		my ($p,$rarf)=@_;  my $marf=$p->{amain}; my @aTmp=(); if(scalar(@$rarf)==0){ return; } 
		$p->setWidth($rarf); 
		for my $val (@$rarf) { push @aTmp, $val; } 
		push @$marf, \@aTmp; $p->shape(); 
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
	sub getWidth { my $p=shift; return $p->{width} ; }
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
	
	sub shape { my $p=shift; my $marf=$p->{amain}; say "Shape ".substr($p->{uic},0,14)."... "; $p->prHdrs(); say "Rows: ".scalar(@$marf); say "Width: ".$p->{width}; }	
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
		$p->show();
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
		$p->show();
	}		
	sub togStrict { my $p=shift; $p->{bStrict}==0 ? $p->{bStrict}=1 : $p->{bStrict}=0; say $p->{uic}." strict mode = ". $p->{bStrict}; }
	sub isStrict { my $p=shift; return $p->{bStrict}==0 ? 0 : 1; }
	sub setWidth { my ($p,$arf)=@_; if(! $p->{length} || $p->{length}<=0){ $p->{width}= scalar(@$arf); } }
	sub setIsValid { my ($p,$val)=@_; $p->{bIsValidState}= $val; } 
	sub chkTypes { my ($p,$charf)=@_; my %dTypes=(i=>0,s=>0,o=>0); $p->msgWIP();  }	
	sub exportToFile {my $p=shift;  $p->msgWIP(); }
	sub mvColtoPos { my $p=shift; $p->msgWIP(); }
	sub mvRowtoPos { my $sdoc="Move row to new position"; 
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
	sub getRowSigs { my $sdoc="ToDo: document";
		my $p=shift; my $marf=$p->{amain};
		my %hRV=();  
		while ( my ($idxR,$arf)=each @$marf) {
			$hRV{$idxR}=::getSHA($idxR.join("",@$arf));
		}		
		return \%hRV; 
	}
	
	sub srtMtxByCol { my $sdoc="ToDo: document";
		my ($p,$colwant,$bSort)= @_; my $marf=$p->{amain}; 
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
		
		if($srtType==0) { @aNewRowSigOrd= map { $_ } sort { $dSigtoVal{$a}<=>$dSigtoVal{$b} } keys %dSigtoVal; }
		elsif($srtType==1) { @aNewRowSigOrd= map { $_ } sort { $dSigtoVal{$b}<=>$dSigtoVal{$a} } keys %dSigtoVal; }
		
		for my $RSIG (@aNewRowSigOrd){
			say substr($RSIG,0,7) ."... ($colwant) ". $dSigtoVal{$RSIG} ." , ". join(" _ ", @{$dSigtoRow{$RSIG}});
		}	
	}
	
	sub mulxVuntilXYcond { my $p=shift; my $sdoc="ToDo: document"; $p->msgWIP(); }		
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
	sub msgWIP { my $p=shift; say $p->{uic}." not yet implemented."; }	
	sub prHdrs { my $p=shift; if($p->{width}<=0){ return; } my @ah=(); my $hdarf=$p->{ahdrs}; if(scalar(@$hdarf)==0){ @ah=@$hdarf;  } else { @ah=map{ $_ } 1..($p->{width}); say join( " _ ", @ah);}  }	
	sub show { my $p=shift; my $marf=$p->{amain}; say '='x13; $p->prHdrs(); for my $arf (@$marf) { say join( " _ ", @$arf);  } $p->shape(); say '='x13; }

	sub importFileData { my $sdoc="data = rows of space-separated values";
		say $sdoc;  
		my ($p,$fname)=@_; 
		if ( ! -e $fname ) { say "$fname not found."; return; }
		my $marf=$p->{amain};
		open(my $fh, '<', $fname);
		my @aFL=<$fh>;
		chomp(@aFL);
		my %dStats=(); 
		while ( my ($idx,$L)=each @aFL) { 
			my @aPcs=split(/ +/,$L); $dStats{$idx}=\@aPcs; 
			if( $p->{width} <1 ){ $p->setWidth(\@aPcs);   } 
			elsif( $p->{width}!= scalar(@aPcs) ){ say "import warning, row $idx"; }		
			push @$marf,\@aPcs; 
		}
		say "Import statistics"; 
		for my $k (sort { $a<=>$b} keys %dStats){ 
			say "Length $k=".scalar( @{$dStats{$k}} ); 
		}
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
	my $var=shift; 
	if(ref($var)) { say "ref $var of type ". ref($var);  }
	elsif(looks_like_number($var)) { say "$var of type number";  }
	else { say Dumper ($var); } 
}	
sub dec2hex { my $d=shift; return sprintf( "%x" , $d ); }
sub padint { my $i=shift; if ($i<10){ return "  ".$i;} elsif ( $i < 100) { return " ".$i} else {return $i;} }


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
 		my %dPCG=();
 		say "% values in place _ ". join(" ;; ", map { "$_ (". ($_/$sum)*100 .")"  } @$arfNums) ;
 		map { $dPCG{$_}=($_/$sum)*100 } @$arfNums ;
 		say "% values sorted _ ". join(" ;; ", map { "$_ (". $dPCG{$_} .")"  } sort {$dPCG{$b}<=>$dPCG{$a}} keys %dPCG );  

 		
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
	 say "Tip: next you might: for my \$L (\@\$arf) { say \$L; }";
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


