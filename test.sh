#/bin/bash


a="08"
if [[ $a =~ ^[0][0-9]$ ]];then
	echo "$a"
	a=$(echo "$a" | sed 's/\([0]\)\(.*\)/\2/')
	echo "$a"
fi

