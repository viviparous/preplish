#! /usr/bin/env bash

#TODO:  
#highlight string in code
#create modes: mode1=coding; mode2=querying
#import lines (not whole file) from scratchfile or from cmdhistory
#append file , check after append
#before run, append $file as  __DATA__ 

#https://misc.flogisoft.com/bash/tip_colors_and_formatting

GLOBIGNORE="*"

dts=$(date +"%Y.%m.%d_%H%M")
fstem=_repl.pl
tmpfile=$dts$fstem
touch $tmpfile
scratchfile=_tmp001.txt
touch $scratchfile
#logfile=_tmplog.txt
#touch $logfile
datasetsffx=_data.txt
dataset=$tmpfile$datasetsffx
echo "__DATA__" > $dataset #contains one line; erased if there is no data appended
subrfilesffx=_subrfile.txt
subrfile=$tmpfile$subrfilesffx
touch $subrfile
chkpval=0
tc001=1 

declare -a aTmpFiles	#add files to remove
aTmpFiles+=($scratchfile)

 
declare -a aAppMsgs
bPerltidy=0
bPerldoc=0
if [ -x "$(command -v perldoc)" ];
then
    aAppMsgs+=("perldoc is installed")
	bPerldoc=1
else
 aAppMsgs+=("no perldoc found")
fi
if [ -x "$(command -v perltidy)" ];
then
    aAppMsgs+=("perltidy is installed")
	bPerltidy=1

else
 aAppMsgs+=("no perltidy found")
fi

if [ -x "$(command -v perl)" ];
then
    aAppMsgs+=("perl is installed")
    perlpath=$(which perl)
    aAppMsgs+=($perlpath)
	bPerl=1
else
	aAppMsgs+=("no perl found! end program")
	echo -e "\e[35m"
	for i in ${!aAppMsgs[@]}; do echo -e "$i /  ${aAppMsgs[$i]}" ; done
	echo -e "\e[m"
	exit 0
fi


declare -a cmdhistory

#cmd verbs
declare -A dcmdhelp

dcmdhelp[cmdhelp]=cmdhelp 				#show all REPL cmds
dcmdhelp[cmdhelpd]="cmdhelpd "			#show description for a cmdword
dcmdhelp[cmdexit]=cmdexit				#exit,quit
dcmdhelp[cmdquit]=cmdquit				#exit,quit
dcmdhelp[cmdlist]=cmdlist				#show input history
dcmdhelp[cmdlsdir]=cmdlsdir				#ls dir
dcmdhelp[cmdimport]="cmdimport "		#import a file
dcmdhelp[cmdrunfwargs]="cmdrunfwargs "		#run a specific function with arguments
dcmdhelp[cmdrwparms]="cmdrwparms "			#run existing code with @args 
dcmdhelp[cmdlsmods]=cmdlsmods			#cpan list installed
dcmdhelp[cmdlsmodsgrep]=cmdlsmodsgrep	#cpan list | grep str
dcmdhelp[cmdshowc]=cmdshowc				#list current code
dcmdhelp[cmdchkp]=cmdchkp				#save a copy of current code as a "checkpoint" file
dcmdhelp[cmdcatf]="cmdcatf "			#cat named file
dcmdhelp[cmdcatsub]="cmdcatsub "		#search subroutine names in a perl file
dcmdhelp[cmdcatpkg]="cmdcatpkg "		#search package names in a perl file 
dcmdhelp[cmdclear]=cmdclear				#clear all code
dcmdhelp[cmdclrlast]=cmdclrlast				#clear last line; code must be correct without the line
dcmdhelp[cmdpdocq]="cmdpdocq "			#perldoc query FAQs
dcmdhelp[cmdpdocf]="cmdpdocf "			#perldoc query functions
dcmdhelp[cmdtogrun]="cmdtogrun"			#toggle run code after each line is added; code check remains active
dcmdhelp[cmddataimp]="cmddataimp"			#append data to data file; if cmddatatog is TRUE, file is appended as __DATA__ section
dcmdhelp[cmddatatog]="cmddatatog"			#toggle inclusion of __DATA__ section
dcmdhelp[cmddataclear]="cmddataclear"			#clear __DATA__ section , but leave toggle in current state


#modes for input
declare -A dcntrlMode
dcntrlMode[cmSubrForL]=0
dcntrlMode[bIsSubNotForL]=1
dcntrlMode[cmPODmode]=0
dcntrlMode[cmTOGrun]=1				#default is true, run code after each line is added
dcntrlMode[bUseDataFile]=0			#toggle 

declare -a aSubrForL


function showhelp () {
 declare -a acmds

 for i in ${!dcmdhelp[@]}; do
  #echo -n " ${dcmdhelp[$i]} "
  acmds+=(${dcmdhelp[$i]})
 done

 teststr=$(echo ${acmds[@]} | sed 's/ /\n/g' | sort -h | awk '{for(i=1;i<=NF;i++){ printf "%s ",$i }}' )
 echo "// $teststr //"
 echo " "

}

function showhelpdataops () {
 msgincolour "After importing a data file as __DATA__ section, use cmddatatog to activate (toggle) the inclusion of the data."
 msgincolour "Use the subroutines listDATA and readDATA to work with the __DATA__ section."	
	
}

function showhistory () {

	for i in ${!cmdhistory[@]}; do
	  msglinesyntax "$i /  ${cmdhistory[$i]}" 
	done

}

function cleartmpfiles {

	msgincolour "Clear tmp files..."
	for i in ${!aTmpFiles[@]}; do
	 if [[ -e ${aTmpFiles[$i]} ]]; then 
	  rm  ${aTmpFiles[$i]} 
	  echo -n "." && sleep 1 && echo -n "." && sleep 1 && echo -n "."
	 fi
	done


}

function mkdts {

	dts=$(date +"%Y.%m.%d_%H%M")
	echo $dts

}

function parseArgLine {


	bUseComma=$1 	# 0 no , 1 yes
	
	shift			# now we process the remaining arguments

	bMkQQField=0
	declare -a aQQField
	declare -a aFINAL

	while [[ $# -gt 0 ]]; do
		arg="$1"

		#echo "$0 $LINENO arg: $arg"

		 if [[ $arg =~ ^\" && $arg =~ [^\"]$ ]]; then 	#start of "string with spaces"
		  bMkQQField=1;
		  aQQField+=($arg)
		 elif [[ $arg =~ \"$ && $arg =~ ^[^\"] ]]; then		#end of "string with spaces"
		  aQQField+=($arg)
		  bMkQQField=0
		#  echo "${aQQField[@]}"
		  aFINAL+=("${aQQField[@]}")
			if [[ $bUseComma -eq 1 ]]; then aFINAL+=(,); fi
		  unset aQQField
		 elif [[ $bMkQQField -eq 1 ]]; then			
		  aQQField+=("$arg")
		 else
		#  echo "23arg: $arg"			#take arg as is
			aFINAL+=($arg)
			if [[ $bUseComma -eq 1 ]]; then aFINAL+=(,); fi
		 fi

		
		# Shift to get the next arg
		shift
	done


	if [[ $bUseComma -eq 1 ]]; then	unset 'aFINAL[${#aFINAL[@]}-1]'; fi	#delete last comma
#	outstr=$(echo "${aFINAL[*]}")
	outstr=$(echo ${aFINAL[*]})

	echo $outstr

}


function coloursyntax {

 ofile=$1-bu.txt
 cat -n $1 > $ofile

 if [[ $bPerltidy -eq 1 ]]; 
  then 
  perltidy -st $1 | cat -n > $ofile
 fi

 cat $ofile | sed -e 's/[\%()~]\w*/\x1b[1;33;01m&\x1b[m/ig' -e 's/[\$\@()~]\w*/\x1b[1;36;01m&\x1b[m/ig' -e 's/[\/\\{}#=]/\x1b[1;31;01m&\x1b[m/ig' | perl -pe  's/(while |use |sub |if |else )/\e[1;34m\1\033[0m/g'
 rm $ofile
}

function msgincolour {

 echo -e "\e[100m"
 echo $1
 echo -e "\e[m"

}

function msglinesyntax {

echo $1 | sed -e 's/[\%()~]\w*/\x1b[1;33;01m&\x1b[m/ig' -e 's/[\$\@()~]\w*/\x1b[1;36;01m&\x1b[m/ig' -e 's/[\/\\{}#=]/\x1b[1;31;01m&\x1b[m/ig' | perl -pe  's/(while |use |sub |if |else )/\e[1;34m\1\033[0m/g'

}

function listCurrSubrForL () {
	if [[ -e $scratchfile ]]; then rm $scratchfile; fi
	touch $scratchfile
	
	for i in ${!aSubrForL[@]}; do
	  msglinesyntax "$i /  ${aSubrForL[$i]}" 
	  echo "${aSubrForL[$i]}" >> $scratchfile
	done

	#syntax helper
	synhelp=$(perl -pe 's/[{}()\[\],;"()\=\-]/ /g'  $scratchfile | grep -oP  "(?<=[\$\%\@])\S+\s" | awk '{n[$1]++;}END{for (a in n) { print a"="n[a]" "}}' | sort | awk '{printf $0; printf " ;; "}'	)
	msgincolour "$synhelp"
}

function mkcheckpoint () {
 lc=$(wc -l $tmpfile | awk '{print $1}')
 if [[ $lc -gt 0 ]]; 
 then
  chkpfstem="_chkp_"
  chkpext=".txt"
  chkpf="$tmpfile$chkpfstem$chkpval$chkpext"
  cp $tmpfile $chkpf
  
  if [[ ${dcntrlMode[bUseDataFile]} -eq 1 ]]
	then 
	cat $dataset >> $chkpf
  fi  
  
  chkpval=$(($chkpval+1))
  msgincolour "checkpoint saved"
 fi  
}


function appendSubToSubrFile () {

	ofile=$subrfile
	echo "init state... $ofile"
	cat -n $ofile
	
	dtscmt=$( mkdts )
	echo -e "\n### subroutine $dtscmt \n" >> $ofile 
	
	for i in "${aSubrForL[@]}"; do
	  echo "$i" >> $ofile
#	  printf '%s\n' "$i" >> $ofile	  
	done	
	
	echo "altered state... $ofile"
#	cat -n $ofile | $grepwsyntax
	coloursyntax $ofile
}

function appendSubToScratchFile () {

	ofile=$scratchfile
	echo "init state... $ofile"
	cat -n $ofile

	for i in "${aSubrForL[@]}"; do
	  echo "$i" >> $ofile
#	  printf '%s\n' "$i" >> $ofile	  
	done	
	
	echo "altered state... $ofile"
	cat -n $ofile
}

function bFileIsValid () {
	bRVcheck=0
	rv=$(perl -I . -c $1)
	if [ $? -eq 0 ]
	then
	 bRVcheck=1
	fi
	echo "$bRVcheck"

}



includefile="import.tmpl01.txt"
if [[ -e $includefile ]]; 
then 
 msgincolour "Found $includefile, importing..."
 cat $includefile
 cat $includefile >> $tmpfile
 rv=$(perl -I . -c $tmpfile)

	if [ $? -eq 0 ]
	 then
		cp $tmpfile $scratchfile
		msgincolour "Imported $includefile"

	else 
		msgincolour "Error. Did not import $includefile"
	fi
 
else
 msgincolour "No auto-import file $includefile found."
fi



# # # START MAIN


echo -e "\e[32m"
echo -e "For help, type ${dcmdhelp[cmdhelp]}\nFor cmd details, type ${dcmdhelp[cmdhelpd]}\$cmdname.\nTo exit, type ${dcmdhelp[cmdquit]} or ${dcmdhelp[cmdexit]}\n"
echo "Important: To type a backslash for an array ref or hash ref, type two backslashes to escape the second one."


echo -e "\e[35m"
for i in ${!aAppMsgs[@]}; do echo -e "$i /  ${aAppMsgs[$i]}" ; done
echo -e "\e[m"

history -r $0_cmds
set -o vi

while [ $tc001 ]; 
do

	read -ep '>>>: ' codeline
	history -s "$codeline"
	

	subregex="^[[:space:]]*sub "
	forregex="^[[:space:]]*for my "
	whlregex="^[[:space:]]*while \( [^[:space:]]+ "
	whleachregex="^[[:space:]]*while \( my \( [^[:space:]]+,[^[:space:]]+ )[[:space:]]*=[[:space:]]*each [^[:space:]]+ {"
	podopnregex="^=pod"
	podendregex="^=cut"


	### BEGIN POD MODE
	 if [[ $codeline =~ $podopnregex && ${dcntrlMode[cmPODmode]} -eq 0 ]];
	 then 
		
		msgincolour "Received pod cmd. Add a new line with only =cut to complete"
		dcntrlMode[cmPODmode]=1
		aSubrForL+=("$codeline")
		listCurrSubrForL
		continue

	 elif [[ $codeline =~ ^$podendregex ]];
	 then 
		msgincolour "Received end of pod marker $codeline"
		dcntrlMode[cmPODmode]=0
		aSubrForL+=("$codeline")
		listCurrSubrForL
		cp $tmpfile $scratchfile
		appendSubToScratchFile
		frv="$(bFileIsValid $scratchfile)"

		if [ "$frv" -eq 1 ]; then
		 cp $scratchfile $tmpfile
		 
		else
		 msgincolour "Invalid code, discarding..."
		 listCurrSubrForL
		 unset aSubrForL 
		fi
		continue
		
	 elif [[ ${dcntrlMode[cmPODmode]} -eq 1 ]];
	 then
		msgincolour "(Continue inside pod. Add a new line with only $podendregex to complete the scope.)"
		sleep 1
		aSubrForL+=(" $codeline")
		listCurrSubrForL
		
		continue
	 fi

	### END POD MODE

	### BEGIN SUBFORWHILE MODE
#	 if creating a subroutine or loop
	 if [[ ( $codeline =~ $subregex || $codeline =~ $forregex || $codeline =~ $whleachregex || $codeline =~ $whlregex ) && ! $codeline =~ }\ *$ && ${dcntrlMode[cmSubrForL]} -eq 0 ]];

	 then 
		if [[ $codeline =~ $subregex ]]; 
		then 
		 dcntrlMode[bIsSubNotForL]=1
		else
		 dcntrlMode[bIsSubNotForL]=0
		fi
		
		msgincolour "Received scope marker $codeline ,  add line with only }## to complete"
		dcntrlMode[cmSubrForL]=1
		aSubrForL+=("$codeline")
		listCurrSubrForL
		continue

#	 elif [[ $codeline =~ ^}$ || $codeline =~ ^}# ]];
	 elif [[ $codeline =~ ^}##$ ]];
	 then 
		msgincolour "Received end of multiline sub/loop marker $codeline"
		dcntrlMode[cmSubrForL]=0
		aSubrForL+=("$codeline")
		listCurrSubrForL
		cp $tmpfile $scratchfile
		appendSubToScratchFile
		frv="$(bFileIsValid $scratchfile)"

		if [ "$frv" -eq 1 ]; then
		 cp $scratchfile $tmpfile
		 if [[ dcntrlMode[bIsSubNotForL] -eq 1 ]]; then 
		  appendSubToSubrFile
		  unset aSubrForL
		 fi
		 
		else
		 msgincolour "Invalid code, discarding..."
		 listCurrSubrForL
		 unset aSubrForL 
		fi
		continue
		
	 elif [[ ${dcntrlMode[cmSubrForL]} -eq 1 ]];
	 then
		msgincolour "(Continue inside sub or for loop... No syntax-check until you complete the scope. Add line with only }## to complete the scope.)"
		sleep 1
		aSubrForL+=(" $codeline")
		listCurrSubrForL
		
		continue
	 fi
	### END SUBFORWHILE MODE

	### BEGIN CMD and CODE MODE
	 if [[ ${dcmdhelp[cmdquit]} == $codeline || ${dcmdhelp[cmdexit]} == $codeline ]];
	 then 
		echo "received ${dcmdhelp[cmdquit]}"
		tc001=0
		break
	 elif [[ ${dcmdhelp[cmdhelp]} == $codeline ]];
	 then
		showhelp
		continue
	elif [[ ${dcmdhelp[cmdlist]} == $codeline ]];
	 then
		showhistory
		continue
	elif [[ ${dcmdhelp[cmddatatog]} == $codeline ]];
	 then
		if [[ ${dcntrlMode[bUseDataFile]} -eq 1	]]; then dcntrlMode[bUseDataFile]=0 ; else  dcntrlMode[bUseDataFile]=1; fi
		msgincolour "Toggled ${dcmdhelp[bUseDataFile]}, value now ${dcntrlMode[bUseDataFile]}"		
		continue
	 elif [[ ${dcmdhelp[cmdshowc]} == $codeline ]];
	 then
#		cat -n $tmpfile | perltidy -st #$grepwsyntax
#		perltidy -st $tmpfile | cat -n | $grepwsyntax #use only if perltidy was found
		coloursyntax $tmpfile
#		cat -n $tmpfile | $grepwsyntax #use only if perltidy was found
		
		continue

	elif [[ $codeline =~ ${dcmdhelp[cmdcatf]} ]];
	 then
		echo "received catf cmd $codeline"
		
		fname=$(echo $codeline | awk '{print $2}')
		if [[ -e $fname ]]; 
		then 
		 echo "Found $fname"
		# use syntax colour for .pl files
			if [[ "$fname" =~ \.[Pp][Ll]$ ]] ; then coloursyntax $fname; 
			elif [[ "$fname" =~ \.[Tt][Xx][Tt]$ ]] ; then cat -n $fname | perl -pe  's/(\d+)/\e[1;34m\1\033[0m/g' ; 
			else cat -n $fname
			fi
		
		else
		 echo "No file $fname"
		fi
		
		continue
		
	elif [[ $codeline =~ ${dcmdhelp[cmdcatsub]} ]];
	 then
		echo "received catsub cmd $codeline"
		
		fname=$(echo $codeline | awk '{print $2}')
		if [[ -e $fname ]]; 
		then 
		 echo "Found $fname"
		 grep --colour -HinP "^\s*sub\s+\S+\s+{" $fname 

		else
		 echo "No file $fname"
		fi
		
		continue

	elif [[ $codeline =~ ${dcmdhelp[cmdcatpkg]} ]];
	 then
		echo "received catpkg cmd $codeline"
		
		fname=$(echo $codeline | awk '{print $2}')
		if [[ -e $fname ]]; 
		then 
		 echo "Found $fname"
		 grep --colour -HinP "^\s*package\s+\S+\s+{" $fname

		else
		 echo "No file $fname"
		fi
		
		continue

	elif [[ $codeline =~ ${dcmdhelp[cmdrunfwargs]} ]];
	 then
		cntParams=$(echo $codeline | awk '{print NF}')
		if [[ $cntParams -ge 2 ]]; 
		then
		 funcnym=$(echo $codeline | awk '{print $2}')
   		 echo "Received cmdrunfwargs cmd $funcnym $codeline"
		 #must handle args intelligently 
		 codelinemod=$(echo $codeline | awk '{for(i=3;i<=NF;i++){printf "%s ",$i}}')
		 echo "$0 $LINENO dbg: $codelinemod"
		 paramstr=$(parseArgLine 1 $codelinemod)
		 echo "$0 $LINENO subroutine to run: $funcnym($paramstr)"
		 tmprwargs=_tmp002.txt
		 aTmpFiles+=($tmprwargs)
		 cp $tmpfile $tmprwargs
		 echo "my \$func = \&$funcnym ;" >> $tmprwargs
		 echo "\$func->($paramstr);" >> $tmprwargs #add arguments
		 msgincolour "Temp file:"
		 cat $tmprwargs
		 msgincolour "Check file..."
		 rv=$(perl -I . -c $tmprwargs)

		 if [ $? -eq 0 ]
		 then
			perl -I . $tmprwargs 
			  
		 else
		  echo "There was an error." 
		 fi
		 
		 
		fi
		continue



	elif [[ $codeline =~ ${dcmdhelp[cmdpdocf]} || $codeline =~ ${dcmdhelp[cmdpdocq]} ]];
	 then
		cntParams=$(echo $codeline | awk '{print NF}')
		if [[ $bPerldoc -eq 1 && $cntParams -eq 2 ]]; 
		then
		 srchstr=$(echo $codeline | awk '{print $2}')
   		 echo "received perldoc cmd $codeline"

		 if [[ $codeline =~ ${dcmdhelp[cmdpdocf]} ]] ; 
		 then
			perldoc -Ti -f $srchstr
		 elif [[ $codeline =~ ${dcmdhelp[cmdpdocq]} ]] ;
		 then
			perldoc -Ti -q $srchstr
		 
		 fi
		fi
		continue

	elif [[ $codeline =~ ${dcmdhelp[cmdhelpd]} ]];
	 then
		cntParams=$(echo $codeline | awk '{print NF}')
		if [[ $cntParams -eq 2 ]]; 
		then
		 srchstr=$(echo $codeline | awk '{print $2}')
   		 echo "received cmdhelpcmd $codeline"

		 docu=$(head -n 100 $0 | grep "\[$srchstr\]" | awk -F'#' '{print $2}') 
		 echo "$srchstr -- $docu"
		else
		 echo "error in $codeline"
		 
		fi
		continue

	elif [[ ${dcmdhelp[cmdchkp]} == $codeline ]]; then
		mkcheckpoint
		continue	
		
	elif [[ ${dcmdhelp[cmdclear]} == $codeline ]];
	 then
		rm $tmpfile
		touch $tmpfile
		continue
		
	elif [[ ${dcmdhelp[cmdclrlast]} == $codeline ]];
	 then
		head -n -1 $tmpfile > $scratchfile
		#if it compiles, keep
		rv=$(perl -I . -c $scratchfile)
		if [ $? -eq 0 ]
		 then
		  cp $scratchfile $tmpfile
		  msgincolour "Cleared the last line"

		else 
		 msgincolour "Could not clear the last line"
		fi
		continue
		
		
	 elif [[ ${dcmdhelp[cmdlsdir]} == $codeline ]];
	 then
		ls -l 
		continue	
	elif [[ ${dcmdhelp[cmdlsmods]} == $codeline ]];
	 then
		cpan -l
		continue
	elif [[ $codeline =~ ${dcmdhelp[cmdlsmodsgrep]} ]];
	 then
		echo "received lsmodsgrep cmd $codeline"
		cntParams=$(echo $codeline | awk '{print NF}')
		if [[ $cntParams -eq 2 ]]; 
		then
			gstr=$(echo $codeline | awk '{print $2}')
			cpan -l | grep -i $gstr 
		fi
		continue		
		
	elif [[ $codeline =~ ${dcmdhelp[cmdimport]} ]];
	 then
		echo "received import cmd $codeline"
		fname=$(echo $codeline | awk '{print $2}')
		if [[ -e $fname ]]; 
		then 
		 echo "Found $fname"
		 rv=$(perl -I . -c $fname)

			if [ $? -eq 0 ]
			 then
				cp $tmpfile $scratchfile
				cat $fname >> $scratchfile
				rv=$(perl -I . -c $scratchfile)
				if [ $? -eq 0 ]
				 then
				  cp $scratchfile $tmpfile
				  echo "Imported $fname"

				else 
				 echo "Did not import $fname"
			    fi

			else 
				echo "Did not import $fname"
			fi
		 
		else
		 echo "No file $fname"
		fi
		
		continue

	elif [[ $codeline =~ ${dcmdhelp[cmddataimp]} ]];
	 then
		echo "received import data cmd $codeline"
		fname=$(echo $codeline | awk '{print $2}')
		if [[ -e $fname ]]; 
		then 
		 echo "Found $fname"

				cat $fname >> $dataset
				echo "Imported $fname"
				showhelpdataops

		else
		 echo "No file $fname"
		fi
		
		continue

	elif [[ ${dcmdhelp[cmddataclear]} == $codeline ]];
	 then
		echo "__DATA__" > $dataset
		continue

		
	elif [[ $codeline =~ ${dcmdhelp[cmdrwparms]} ]];
	 then
		echo "received rwparms cmd $codeline"		
		cntParams=$(echo $codeline | awk '{print NF}')
		if [[ $cntParams -gt 1 ]]; 
		then
		 #must handle args intelligently
		 codelinemod=$(echo $codeline | awk '{for(i=2;i<=NF;i++){printf "%s ",$i}}')
		 echo "$0 $LINENO dbg : $codelinemod"
		 paramstr=$(parseArgLine 0 $codelinemod)
		 echo "run existing code with parameters $paramstr"
		 perl -I . $tmpfile "$paramstr"
		 echo "Done!"
		else
		 echo "need parameters after cmdword"
		fi
		
		continue		
	elif [[ ${dcmdhelp[cmdtogrun]} == $codeline ]];
	 then
		if [[ ${dcntrlMode[cmTOGrun]} -eq 1	]]; then dcntrlMode[cmTOGrun] =0 ; else  dcntrlMode[cmTOGrun]=1; fi
		msgincolour "Toggled ${dcmdhelp[cmdtogrun]}, value now ${dcntrlMode[cmTOGrun]}"
		continue		

	 else
	  cmdhistory+=("$codeline")
	 fi
	 ### END CMD and CODE MODE


	### BEGIN COMPILE AND TEST MODE
	 echo "$codeline" >> $tmpfile
	 

	 
	 rv=$(perl -I . -c $tmpfile)

	 if [ $? -eq 0 ] #compile worked
	 then
		
		 #if last line contains a LH assignment, test the value
		 #capture the variable, insert "showtype($varname)" and run
		bEvalLast=0
		lside=-1
		lastline=$(tail -n 1 $tmpfile)
		if ! echo "$lastline" | grep -q "==" && ! echo "$lastline" |  grep -q "!=" && ! echo "$lastline" | grep -q ">=" && ! echo "$lastline" | grep -q "<=" && echo "$lastline" | grep -q "=" ; then
		 lside=$(echo $lastline | perl -lne 'my $v=$_; my $rv=0; my $xEQ=index($v, "="); my $s1=substr($v,0,$xEQ-1); if(  $s1 !~ /[{}()]/  && ! m/==/ && m/[^!><+-]=/ ){ m/(\S+)=/; $rv=$1; } print $rv; ' )
		 #echo "$LINENO dbg: $lside"
		 varlen=${#lside} 
		 if [[ $lside != "0" && $varlen -gt 1 ]]; then bEvalLast=1 ; fi
		 
		fi
		
		 if [[ ${dcntrlMode[bUseDataFile]} -eq 1 ]]
		 then 
			cat $tmpfile > $scratchfile
			cat $dataset >> $scratchfile
			if [[ ${dcntrlMode[cmTOGrun]} -eq 1 ]]; then perl -I . $scratchfile ; fi 

		 elif [[ ${dcntrlMode[cmTOGrun]} -eq 1 ]]; then 
		  cat $tmpfile > $scratchfile
		  if [[ $bEvalLast -eq 1 ]]; then 
		  
			echo "sub _gettypeinfo { my \$var=shift; if(ref(\$var)) { say \"ref \$var of type \". ref(\$var);  }" >> $scratchfile  
			echo "	elsif(looks_like_number(\$var)) { say \"\$var of type number\";  }" >> $scratchfile 
			echo "		else { say Dumper (\$var); } }" >> $scratchfile 
			echo "_gettypeinfo($lside);" >> $scratchfile 
		  fi
		  perl -I . $scratchfile
		  if [[ $bEvalLast -eq 1 ]]; then echo "assigned lvalue: $lside , length $varlen" ; fi		  
		 
		 elif [[ $bEvalLast -eq 1 ]]; then 
		  #copy main file to tmp, append perl evaluation statement; tail -n 1 the output		 
		  echo "created lvalue: $lside , name length $varlen"
		fi
		
	 else 			#compile failed
		head -n -1 $tmpfile > $scratchfile
		mv $scratchfile $tmpfile
	 	  
	 fi
	### END COMPILE and TEST MODE

done

subrforLC=$(wc -l $subrfile | awk '{print $1}' )
#echo "sz $subrfile $subrforLC"
if [[ $subrforLC -eq 0 ]]; then rm $subrfile; fi
dataLC=$(wc -l $dataset | awk '{print $1}' )
if [[ $dataLC -lt 2 ]]; then rm $dataset; fi
cleartmpfiles
history -w $0_cmds
#echo -e "\ncmd history:"
#showhistory
echo "Saved in file $tmpfile"
