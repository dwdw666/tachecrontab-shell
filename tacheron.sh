#La commande lit régulièrement les fichiers
#présents dans le répertoire /etc/tacheron/ et le
#fichier /etc/tacherontab pour voir si des tâches
#doivent être exécutées. 
#author: Wang Taojun ,Ding Liang

#!/bin/bash

#where 
fichier=
file=/etc
file_allow=$file/allow
file_tacheron=$file/tacheron
file_tacherontab=$file/tacherontab
#date of system
#10 43 04 06 01 2021
#seconde month hour day month year 
sys_date=$(date '+%S %M %H %d %m %Y')
sys_sec=$(date '+%S')
sys_min=$(date '+%M')
sys_hour=$(date '+%H')
sys_day=$(date '+%d')
sys_mon=$(date '+%m')
sys_year=$(date '+%Y')
#array of system date 
date=(
$sys_sec
$sys_min
$sys_hour
$sys_day
$sys_mon
$sys_year
)

#command champ
command=

#this array stores regex to help with the validation of different input types
#e.g. 01, */5, 07-10,  02,03
regex=(
'[a-z]' # a
'[A-Z]' # A
'^[0-9][0-9]*$' #12
'^[*]/[0-9][0-9]*$' # */5
'^[0-9][0-9]*-[0-9][0-9]*/[0-9][0-9]*' #0-23/5
'^[1-9][0-9]*-[1-9][0-9]*([~][0-9][0-9]*)*$' #5-8~6~7
'^(([0-9][0-9]*)[,])+([0-9][0-9]*)$' #0,1,2
'^[*]$' #*
)

#Global return value for returning strings from functions
#(because bash can only return integers with $?)
retval=""
declare -a global_ret_array
declare -a array
global_command_value=""
etat=0
etat_check_date=1

#parameter username
#return etat
function check_user(){
	etat_check_user=0	
	for i in $(cat $file_allow); do	
		if [[ $i == $1 ]];then
			etat_check_user=1			
			return $etat_check_user				
		fi
	done
	if [[ $etat_check_user == 0 ]];then
		return $etat_check_user
	fi

}

#check if date == date of system
#parameter: date
#return: boolean
#function check_date(){
	
#}
#parametre file
function read_file(){
	while read line;do
   	echo $line
	done < /home/damien/l014/projet/tacheron/tacherontabtoto


}

#parameter $1
#return etat
function check_format_seperate(){
	lable_check_format_seperate=0
	for (( i=0;i<${#regex[@]};i++ ));do	
		if [[ $1 =~ ${regex[$i]} ]];then			
			lable_check_format_seperate=1
			etat=1
			return $i
		fi
	done;
	if [ $lable_check_format_seperate -eq 1 ];then
		return 250	
	fi
}


#Parameters (chaine of string)
#return int
function split_line(){
	line_contents=`sed -n "$1p" < $fichier`	
	#Breaks down the full string into individual components - 		   #minute,hour,month etc.
	#into and array called "time"
	#Delimiter is the space
	IFS=' ' read -ra array <<< "$line_contents"
	#command string could have spaces in between, so the command is the tail
	#of the array from index 5	
	for (( y=0; y<=5; y++ )); do
		global_ret_array[$y]=${array[$y]}
	done	
	global_command_value="${array[6]}"
	for (( y=7; y<${#array[@]}; y++ )); do
		global_command_value+=" ${array[$y]}"
	done	
	#echo "a=${global_ret_array[*]}"
	
}

#check_date par ligne
function check_date(){
	split_line $1
	etat_check_date=1
	sec_real=
	echo "global_ret_array=${global_ret_array[*]}"
	for (( 	j=0;j<${#global_ret_array[@]};j++ ));do	
#		echo "global_ret_array[$j]=${global_ret_array[$j]}"
		check_format_seperate "${global_ret_array[$j]}"
		nb_type=$?
#		echo "j=$j"
#		echo "nb_type=$nb_type"
#		echo "date=${date[$j]}"
		case $nb_type in
			#e.g 12			
			2) 
			if [ $j -eq 0 ];then #if the unit is sec we have to transfer to sec*15
			     sec_real=$(( ${global_ret_array[$j]}*15 ))
			     if [ ${date[$j]} -ne $sec_real ];then
				        etat_check_date=0
					return $etat_check_date
			     fi
			else
			     if [ ${date[$j]} -ne ${global_ret_array[$j]} ];then
				        etat_check_date=0
					return $etat_check_date
			     fi
			fi
		        ;;
			#e.g */5			
			3) 
			split_values=( $(echo "$global_ret_array[$j]" | grep -o '[0-9]*') )
			
			if [ $j -eq 0 ];then #if the unit is sec we have to transfer to sec*15
			     sec_real=$(( $split_values*15 ))
			     remainder=$(( ${date[$j]}%$sec_real ))
			     if [ $remainder -ne 0 ];then
			 	etat_check_date=0
				return $etat_check_date
			     fi
			else
			    remainder=$(( ${date[$j]}%$split_values ))
		       	    if [ $remainder -ne 0 ];then
			 	etat_check_date=0
				return $etat_check_date
			    fi
			fi
			;; 
			#e.g 0-23/5
			4)
			split_values=( $(echo "$global_ret_array[$j]" | grep -o '[0-9]*') )
			#initial the split_values for sec
			split_values_sec=() 
			for (( k=0;k<${#split_values[@]};k++));do
				split_values_sec[$k]=$(( ${split_values[$k]}*15 ))
			done
			remainder=$(( ${date[$j]}%${split_values[2]} ))
			remainder_sec=$(( ${date[$j]}%${split_values_sec[2]} ))
                        remainder_use=
			split_values_use=()
#			echo "remainder_sec=$remainder_sec"
#		        echo "remainder=$remainder"
			#choose the value use
			if [ $j -eq 0 ];then
				remainder_use=$remainder_sec
				split_values_use=("${split_values_sec[@]}")
				#echo "split_values_use=${split_values_use[1]}"
			else
			  	remiander_use=remainder
				split_values_use=("${split_values[@]}")
	
			fi

			if [ $remainder_use -ne 0  ];then			
				etat_check_date=0
				return $etat_check_date
			   fi
			   if [ ${date[$j]} -lt ${split_values_use[0]} ];then
			        etat_check_date=0
				return $etat_check_date
			   fi
			   if [ ${date[$j]} -gt ${split_values_use[1]} ];then
			         etat_check_date=0
				return $etat_check_date
			   fi
			;;
			#e.g 5-8~6~7
			5)
			split_values=( $(echo "$global_ret_array[$j]" | grep -o '[0-9]*') )
			split_values_sec=()
			for (( k=0;k<${#split_values[@]};k++));do
				split_values_sec[$k]=$(( ${split_values[$k]}*15 ))
			done
			
			nb_rest=$(( ${#split_values[@]}-2 ))
			lable=0
			
			for (( k=${split_values[0]};k<=${split_values[1]};k++));do
				for (( l=2;l<=$nb_rest;l++ ));do
					if [ $k -ne ${split_values[$l]} ];then
					        if [ $j -eq 0 ];then
							k_use=$(( $k*15 ))
						else
						    	k_use=$k
	
						fi
						if [ ${date[$j]} -eq $k_use ];then
				        		lable=1
					     	fi
					fi
				done
			done
			if [ $lable -ne 1 ];then
				#echo "aa"				
				etat_check_date=0
				return $etat_check_date
			fi

			
			;;
			#e.g 3,4,5
			6)
			split_values=( $(echo "$global_ret_array[$j]" | grep -o '[0-9]*') )
			split_values_sec=()
			for (( k=0;k<${#split_values[@]};k++));do
				split_values_sec[$k]=$(( ${split_values[$k]}*15 ))
			done
			#echo ${#split_values[@]}
			lable=0
			if [ $j -eq 0 ];then
				split_values_use=(${split_values_sec[@]})
				#echo "kk=${split_values_use[*]}"
			else
				split_values_use=(${split_values[@]})
	
			fi
			for (( m=0;m<${#split_values[@]};m++ ));do
				if [ ${split_values_use[$m]} -eq ${date[$j]} ];then
				lable=1
				fi
			done
			if [ $lable -eq 0 ];then
				etat_check_date=0
				return $etat_check_date
			fi
			;;
			#e.g *
			7)
			if [ $j -eq 0 ];then
				remainder=$(( ${date[$j]}%15 ))
				if [ $remainder -ne 0 ];then
					etat_check_date=0
					return $etat_check_date
				fi
			fi
			;;
			*)
				etat_check_date=0
				return $etat_check_date			
			;;
		esac
	done
	#echo "final j==$j" 
	if [ $etat_check_date -eq 1 ];then
		echo "run command=$global_command_value"
		$global_command_value		
		sudo echo "run command=$global_command_value   date=${date[*]}" >> /var/log/tacheron
		
	fi
	
	return $etat_check_date
}
#check_date par file

function check_file(){		 
	FN=$(wc -l < $1)	
	for (( r=1;r<=$FN;r++ ));do
		
		echo "ligne=$r of $1"		
		check_date $r
	done
}
#test 
#check_format_seperate "01-02"
#echo $?
#split_line 2
#check_date 1
#echo $?

#check_format_seperate "*"
#echo $?
#echo "${global_ret_array[0]}"
#cat $fichier2
#fichier=$fichier2
#check_file $fichier2

#main

cc=$(id |cut -d"=" -f 2 |cut -d "(" -f 1)
if [ $cc -eq 0 ];then
	while true;do
                #seconde month hour day month year 
                sys_date=$(date '+%S %M %H %d %m %Y')
                sys_sec=$(date '+%S')
                sys_min=$(date '+%M')
                sys_hour=$(date '+%H')
                sys_day=$(date '+%d')
                sys_mon=$(date '+%m')
                sys_year=$(date '+%Y')
                #array of system date 
                date=(
                $sys_sec
                $sys_min
                $sys_hour
                $sys_day
                $sys_mon
                $sys_year
                )
                for (( p=0;p<${#date[@]};p++ ));do
                      date[$p]=$(echo "${date[$p]}" | sed 's/^\([0]\)\(.*\)$/\2/')
                      
                done		
                echo ${date[*]}
	 	for t in $file_tacheron/*;do
			if [[ $t =~ ^.*[^~]$ ]];then
				fichier=$t		
				check_file $t	
			fi
		done
               sleep 1
	done
else
	echo "you are not root user"
fi




