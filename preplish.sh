#! /usr/bin/bash

dts=$(date +"%Y.%m.%d_%H%M")
fstem=_tmp.pl
tmpfile=$dts$fstem
touch $tmpfile
scratchfile=_tmp001.txt
logfile=_tmplog.txt
tc001=1 


cmdquit=cmdquit
cmdlist=cmdlist
cmdclear=cmdclear

declare -a cmdhistory


function showhistory () {

	for i in ${!cmdhistory[@]}; do
	  echo "$i /  ${cmdhistory[$i]}"
	done

#for value in "${cmdhistory[@]}"
#do
#     echo $value
#done
	
}



echo "To exit, type $cmdquit"

while [ $tc001 ]; 
do

	 read -p '>>>: ' codeline
	 if [[ $cmdquit == $codeline ]];
	 then 
		echo "received $cmdquit"
		tc001=0
		break
	 elif [[ $cmdlist == $codeline ]];
	 then
		showhistory
		continue
	 elif [[ $cmdclear == $codeline ]];
	 then
		rm $tmpfile
		continue		
	 else
	  cmdhistory+=("$codeline")
	 fi
	 
	 
	 echo "$codeline" >> $tmpfile
	 rv=$(perl -c $tmpfile)
#	 perl -c $tmpfile > $logfile
	 

	 if [ $? -eq 0 ]
	 then
		perl $tmpfile 
	 else 
		#if exists perltidy, could run here; 
		head -n -1 $tmpfile > $scratchfile
		mv $scratchfile $tmpfile
	 	  
	 fi

done

showhistory

