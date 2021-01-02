#! /usr/bin/bash

#TODO:  multiline subroutine 


dts=$(date +"%Y.%m.%d_%H%M")
fstem=_tmp.pl
tmpfile=$dts$fstem
touch $tmpfile
scratchfile=_tmp001.txt
logfile=_tmplog.txt
tc001=1 

bPerldoc=0
if [ -x "$(command -v perldoc)" ];
then
    echo "perldoc is installed"
	bPerldoc=1
else
 echo "no perldoc found"
fi



declare -a cmdhistory

#cmd verbs
declare -A dcmdhelp

dcmdhelp[cmdhelp]=cmdhelp 				#show all REPL cmds
dcmdhelp[cmdexit]=cmdexit				#exit,quit
dcmdhelp[cmdquit]=cmdquit				#exit,quit
dcmdhelp[cmdlist]=cmdlist				#show input history
dcmdhelp[cmdlsdir]=cmdlsdir				#ls dir
dcmdhelp[cmdimport]="cmdimport "		#import a file
dcmdhelp[cmdlsmods]=cmdlsmods			#cpan list installed
dcmdhelp[cmdlsmodsgrep]=cmdlsmodsgrep	#cpan list | grep str
dcmdhelp[cmdshowc]=cmdshowc				#list current code
dcmdhelp[cmdcatf]="cmdcatf "			#cat named file
dcmdhelp[cmdcatsub]="cmdcatsub "		#search subroutine names in a perl file
dcmdhelp[cmdcatpkg]="cmdcatpkg "		#search package names in a perl file 
dcmdhelp[cmdclear]=cmdclear				#clear all code
dcmdhelp[cmdpdocq]="cmdpdocq "			#perldoc query FAQs
dcmdhelp[cmdpdocf]="cmdpdocf "			#perldoc query functions

#modes for input
declare -A dcntrlMode



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
	  echo "$i /  ${cmdhistory[$i]}"
	done

#for value in "${cmdhistory[@]}"
#do
#     echo $value
#done
	
}



echo "To exit, type ${dcmdhelp[cmdquit]} or ${dcmdhelp[cmdexit]} "

while [ $tc001 ]; 
do

	 read -p '>>>: ' codeline
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
		cat -n $tmpfile
		continue

	elif [[ $codeline =~ ${dcmdhelp[cmdcatf]} ]];
	 then
		echo "received catf cmd $codeline"
		
		fname=$(echo $codeline | awk '{print $2}')
		if [[ -e $fname ]]; 
		then 
		 echo "Found $fname"
		 cat -n $fname
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
		
		
	elif [[ ${dcmdhelp[cmdclear]} == $codeline ]];
	 then
		rm $tmpfile
		touch $tmpfile
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
		
		
		

	 else
	  cmdhistory+=("$codeline")
	 fi
	 
	 
	 echo "$codeline" >> $tmpfile
	 rv=$(perl -I . -c $tmpfile)

	 

	 if [ $? -eq 0 ]
	 then
		perl -I . $tmpfile 
	 else 
		head -n -1 $tmpfile > $scratchfile
		mv $scratchfile $tmpfile
	 	  
	 fi

done

showhistory
echo "Saved in file $tmpfile"
