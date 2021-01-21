#! /usr/bin/bash

#TODO:  
#use bash to manage args
#remove temp files and dump non-zero length files to a "dump"
#create modes: mode1=coding; mode2=querying
#kvpargs ;; dynamic object, add methods
#import lines (not whole file) from scratchfile or from cmdhistory
#if subrfile is empty, rm 

#https://misc.flogisoft.com/bash/tip_colors_and_formatting


dts=$(date +"%Y.%m.%d_%H%M")
fstem=_repl.pl
tmpfile=$dts$fstem
touch $tmpfile
scratchfile=_tmp001.txt
touch $scratchfile
#logfile=_tmplog.txt
#touch $logfile
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



declare -a cmdhistory

#cmd verbs
declare -A dcmdhelp

dcmdhelp[cmdhelp]=cmdhelp 				#show all REPL cmds
dcmdhelp[cmdhelpcmd]="cmdhelpcmd "			#show description for a cmdword
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


#modes for input
declare -A dcntrlMode
dcntrlMode[cmSubrForL]=0
dcntrlMode[bIsSubNotForL]=1
dcntrlMode[cmPODmode]=0

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


function showhistory () {

	for i in ${!cmdhistory[@]}; do
	  msglinesyntax "$i /  ${cmdhistory[$i]}" 
	done

#for value in "${cmdhistory[@]}"
#do
#     echo $value
#done
	
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

	for i in ${!aSubrForL[@]}; do
	  msglinesyntax "$i /  ${aSubrForL[$i]}" 
	done
	
}

function mkcheckpoint () {
 lc=$(wc -l $tmpfile | awk '{print $1}')
 if [[ $lc -gt 0 ]]; 
 then
  chkpfstem="_chkp_"
  chkpext=".txt"
  cp $tmpfile $tmpfile$chkpfstem$chkpval$chkpext
  chkpval=$(($chkpval+1))
  msgincolour "checkpoint saved"
 fi  
}


function appendSubToSubrFile () {

	ofile=$subrfile
	echo "init state... $ofile"
	cat -n $ofile

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

echo -e "\e[32m"
echo -e "For help, type ${dcmdhelp[cmdhelp]}\nFor cmd details, type ${dcmdhelp[cmdhelpcmd]}\$cmdname.\nTo exit, type ${dcmdhelp[cmdquit]} or ${dcmdhelp[cmdexit]}\n"
echo "Reminder: To type a backslash for an array ref or hash ref, type two backslashes to escape the second one."


echo -e "\e[35m"
for i in ${!aAppMsgs[@]}; do echo -e "$i /  ${aAppMsgs[$i]}" ; done
echo -e "\e[m"

history -r cmdhistory
set -o vi

while [ $tc001 ]; 
do

	read -ep '>>>: ' codeline
	history -s "$codeline"
	
	subregex="sub [a-zA-Z0-9]+\ *{\ *$"
	forregex="for my [^[:space:]]+\ *(\ *[^[:space:]]+\ *)\ *{\ *$"
	whlregex="while\ *(\ *[^[:space:]]+\ *)\ *{\ *$"
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
	 if [[ ( $codeline =~ $subregex || $codeline =~ $forregex || $codeline =~ $whlregex) && ${dcntrlMode[cmSubrForL]} -eq 0 ]];

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
		 if [[ dcntrlMode[bIsSubNotForL] -eq 1 ]]; then appendSubToSubrFile ; fi
		 
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
		# cat -n $fname | $grepwsyntax
		 coloursyntax $fname
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
		 grep -HinP "^\s*sub\s+\S+\s+{" $fname 

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
		 grep -HinP "^\s*package\s+\S+\s+{" $fname

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
		 paramstr=$(echo $codeline | awk -F'"| ' '{for(i=3;i<=NF;i++){printf "%s ",$i; if(i!=NF){ printf ", "}}}')
		 echo "subroutine to run: $funcnym($paramstr)"
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

	elif [[ $codeline =~ ${dcmdhelp[cmdhelpcmd]} ]];
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
		
	elif [[ $codeline =~ ${dcmdhelp[cmdrwparms]} ]];
	 then
		echo "received rwparms cmd $codeline"		
		cntParams=$(echo $codeline | awk '{print NF}')
		if [[ $cntParams -gt 1 ]]; 
		then
		 #must handle args intelligently
		 paramstr=$(echo $codeline | awk '{for(i=2;i<=NF;i++){printf "%s ",$i}}')
		 echo "run existing code with parameters $parmstr"
		 perl -I . $tmpfile $paramstr
		 echo "Done!"
		else
		 echo "need parameters after cmdword"
		fi
		
		continue		
		

	 else
	  cmdhistory+=("$codeline")
	 fi
	 ### END CMD and CODE MODE


	### BEGIN COMPILE AND TEST MODE
	 echo "$codeline" >> $tmpfile
	 rv=$(perl -I . -c $tmpfile)

	 if [ $? -eq 0 ]
	 then
		perl -I . $tmpfile 
	 else 
		head -n -1 $tmpfile > $scratchfile
		mv $scratchfile $tmpfile
	 	  
	 fi
	### END COMPILE and TEST MODE

done

subrforLC=$(wc -l $subrfile | awk '{print $1}' )
if [[ $subforLC -eq 0 ]]; then rm $subrfile; fi
cleartmpfiles
history -w cmdhistory
echo "cmd history:"
showhistory
echo "Saved in file $tmpfile"
