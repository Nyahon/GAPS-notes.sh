#!/bin/bash -       
#title           : GAPS-notes.sh
#description     : This script will fetch your current note report from GAPS
#					and print a formatted version to stdout.
#author		 : Yohann Meyer
#date            : 20190129
#version         : 1.0
#usage		 : bash GAPS-notes.sh
#notes           : Install w3m, xmllint and curl to use this script.
#bash_version    : 4.4.19(1)-release
#==============================================================================
username=""
password=""
year=""
studentID=""

setUser=false;
setPass=false;
setYear=false;

usage() { echo "Usage: "
		  echo "      $0 [-y <year>] [-u <username>] [-p <password>]" 1>&2; 
		  echo ;
		  echo "Dependencies :";
		  echo "      curl xmllint w3m ";
		  echo "   [debian]: ";
		  echo "   sudo apt install curl libxml2-utils w3m"
		  exit 1; }

username_prompt(){	
	echo "Enter GAPS login [name.surname] : "
	read username
}
year_prompt(){
	echo "Enter chosen year [201X] :"
	read year 
}
pass_prompt(){
	echo "Enter password for user ${username} :"
	read -s password
}

getStudentID(){
	echo "Asking the gods for your student ID..."
	curl https://gaps.heig-vd.ch/consultation/etudiant/index.php --data "login=${username}&password=${password}&submit=Entrer" 1&>/dev/null

	studentID="$(curl https://gaps.heig-vd.ch/consultation/controlescontinus/consultation.php \
	-u ${username}:${password} 2>&1 | \
	grep 'show_CCs(' | grep -Eo '[0-9]{5}'| uniq
	)"
	echo "your student GAPS ID seems to be ${studentID}"
}
fetchNotes(){

	echo "Fetching notes..."
	raw="$(curl -H "Content-Type: application/x-www-form-urlencoded; charset=utf-8" -s 'https://gaps.heig-vd.ch/consultation/controlescontinus/consultation.php' \
	--data "rs=getStudentCCs&rsargs=%5B${studentID}%2C${year}%2Cnull%5D&" -u${username}:${password} 2>>./.log)"
	endString=$((${#raw} - 3 - 1));
	raw=${raw:3:endString}
	echo $raw | sed 's/\\//g' | sed 's/<table /<table border="1"/g' > tmp.html
}
prettify(){
	echo "";	
	#hack, for now. To do better with decoding unicode
	#sed -i.bak 's/u00e9/é/g' tmp.html
	xmllint --html "tmp.html" 2>./.log > notes.html
	rm tmp.html
	
}
printNotes(){
	w3m -dump notes.html
}
#******************************MAIN****************************#
while getopts ":u:p:y:" o; do
    case "${o}" in
        u)
            username=${OPTARG};
            setUser=true;
			;;
        p)
            password=${OPTARG}
            setPass=true;
			echo "Using password on the command line is not recommended."
			;;
        y)
			year=${OPTARG};
			setYear=true;
			;;
		
		*)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if ! $setUser
then
	username_prompt	
fi
if ! $setPass
then
	pass_prompt	
fi
if ! $setYear
then
	year_prompt	
fi


getStudentID
fetchNotes
prettify
printNotes
