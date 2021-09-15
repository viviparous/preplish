#! /usr/bin/env bash


 
declare -a aAppMsgs
bPerltidy=0

if [ -x "$(command -v perltidy)" ];
then
    aAppMsgs+=("perltidy is installed")
	bPerltidy=1

else
 aAppMsgs+=("no perltidy found")
fi



function coloursyntax {

 ofile=$1-bu.txt
 cat -n $1 > $ofile

 if [[ $bPerltidy -eq 1 ]]; 
  then 
  perltidy -st $1 | cat -n > $ofile
 fi

 cat $ofile | sed -e 's/[\%()~]\w*/\x1b[1;33;01m&\x1b[m/ig' -e 's/[\$\@()~]\w*/\x1b[1;36;01m&\x1b[m/ig' -e 's/[\/\\{}#=]/\x1b[1;31;01m&\x1b[m/ig' | perl -pe  's/(while |use |sub |if |else |my |for )/\e[1;34m\1\033[0m/g'
 rm $ofile
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


for i in ${!aAppMsgs[@]}; do echo "$i /  ${aAppMsgs[$i]}" ; done
		
fname=$1
if [[ -e $fname ]]; 
		then 
		 echo "Found $fname"
		# cat -n $fname | $grepwsyntax
		
		
		frv="$(bFileIsValid $fname)"

		if [ "$frv" -eq 1 ]; then
		 echo "Code is valid..."
		 coloursyntax $fname		 
		else
		 echo "Invalid code..."
		fi		
		
		

else
		 echo "No file $fname"
fi
		
