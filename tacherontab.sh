#commande « tacherontab » permet la
#programmation du service « tacheron ». La
#syntaxe de cette commande est la suivante :
#tacherontab [-u user] {-l | -r | -e} 

#/bin/bash
#champ of user
user=


#system date
date=$(date '+%Y-%m-%d %H:%M:%S')

#file which contains list of allowed users
file=/etc
file_allow=$file/allow

#tacherontab [-u user] {-l | -r | -e} 
#-u aaa -l
regx=(
'^-u[ ][^ ]*[ ]-[lre]' 
#user name
'[^ ]*'
)

#parameter username
#return etat
function check_user(){
	etat=0	
	for i in $(cat $file_allow); do	
		if [[ $i == $1 ]];then
			etat=1			
			return $etat				
		fi
	done
	if [[ $etat == 0 ]];then
		return $etat
	fi

}

#parameter $1 $2 $3
#return etat
function assinged(){
	if [[ $1 == '-u' ]];then
		if [[ $2 =~ ${regx[1]} ]];then
			if [[ $3 == '-l' || $3 == '-r' || $3 == '-e' ]];then
				check_user $2				
				if [[ $? == 1 ]];then 				
					user=$2	
					case $3 in
					  '-l')return 1;;
					  '-r')return 2;;
					  '-e')return 3;;
					esac		
				else
					echo "no this user"	  				
				fi
			fi		
		fi		
	
	fi
}
#tacherontab –u toto -l affiche le fichier tacherontab de l'utilisateur toto #situé dans le répertoire /#etc/tacheron/
function mode_l(){
	init="tacherontab"	
	name_folder=$init$user	
	cat /home/damien/l014/projet/tacheron/$name_folder
}
#tacherontab –u toto -r efface le fichier tacherontab de l'utilisateur toto 
function mode_r(){
	init="tacherontab"	
	name_fichier=$init$user	
	fichier_user=/home/damien/l014/projet/tacheron/$name_fichier
	
	echo "" > $fichier_user
}
#tacherontab –u toto -e crée ou édite (pour
#modification) un fichier temporaire dans /tmp ouvert
#dans vi. Lors de la sauvegarde, le fichier est écrit
#dans /etc/tacheron/tacherontabtoto. 
function mode_e(){
	init="tacherontab"	
	name_fichier=$init$user	
	fichier_user=$fichier/$name_fichier	
	vi $fichier_user

}
#main

assinged $1 $2 $3
etat=$?
case $etat in
	1) mode_l ;;
	2) mode_r ;;
	3) mode_e ;;
esac





