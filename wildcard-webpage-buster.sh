#!/bin/bash

###Color Codes###
RESET='\033[0m'
RED='\033[0;31m'
RED_B='\033[1;31m'
GREEN='\033[0;32m'
GREEN_B='\033[1;32m'
YELLOW='\033[0;33m'
YELLOW_B='\033[1;33m'
BLUE='\033[0;34m'
BLUE_B='\033[1;34m'
PURPLE='\033[0;35m'
PURPLE_B='\033[1;35m'
CYAN='\033[0;36m'
CYAN_B='\033[1;36m'
WHITE='\033[0;37m'
WHITE_B='\033[1;37m'


###Parsing User-Defined Options###
while [[ $# -gt 0 ]]; do
	key="$1"
	case $key in
	-h|--help) ###Help Page
		echo -e "\n ${WHITE_B}-h|--help :${RESET} Display this help page."
		echo -e "\n ${WHITE_B}-o|--output :${RESET} Specify a file for wildcard-webpage-evade to log what pages it was able to access. If none is specified, it will default to using ./wildcard-webpage-evade.log."
		echo -e "\n ${WHITE_B}-q|--quiet :${RESET} Makes wildcard-webpage-evade only output found pages. By default, wildcard-webpage-evade will output every attempt. Use the quiet option to make the output cleaner."
		echo -e "\n ${WHITE_B}-s|--string :${RESET} The wildcard method usually either redirects you to the default web page, or outputs a random string of letters and numbers. In order for the tool to determine what page is the default page, you must specify a string that is unique to the page the default page it redirects you to. Make sure this argument is put in quotes. ${RED_B}(REQUIRED)${RESET}"
		echo -e "\n ${WHITE_B}-t|--target :${RESET} Specifies the target you are trying to enumerate. ${RED_B}(REQUIRED)${RESET}"
		echo -e "\n ${WHITE_B}-w|--wordlist :${RESET} Specifies the wordlist to be used to try and brute force directory names. If one is not specified, the wildcard-webpage-evade will default to the popular /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt wordlist. Note that if you are on a machine that does not not have this wordlist, or the wordlist's default location is moved, the script will error out if no wordlist is specified."
		echo -e "\n ${WHITE_B}-x|--extensions :${RESET} Specifies if any extensions should be appended to the brute force. Much like dirbuster, by default wildcard-webpage-evade will only attempt to access pages with no extensions. This can omit potentially important files, such as php, aspx, etc. This option takes a comma separated list of extensions. Example: -x php,aspx,txt."
		echo -e "\n${WHITE_B}Example Usage :${RESET}"
		echo "./wildcard-webpage-evade.sh -w ./directory_list.txt -t 10.10.10.10 -x php,aspx,txt -s \"Welcome to the\""
		echo "./wildcard-webpage-evade.sh -s \"a series of numbers\"  -q -t 10.10.10.10"
		echo "./wildcard-webpage-evade.sh -t 10.10.10.10 -s \"Password:\" -x php -o results.log"
		echo "./wildcard-webpage-evade.sh -s \"Click here to Register\" -t 10.10.10.10"
		echo " "
		exit
		shift
		shift
		;;
	-w|--wordlist)
		WORDLIST="$2"
		shift
		shift
		;;
	-s|--string)
		REDIRECTSTRING="$2"
		shift
		shift
		;;
	-x|--extensions)
		EXTENSIONS="$2"
		shift
		shift
		;;
	-t|--target)
		TARGET="$2"
		shift
		shift
		;;	
	-o|--output)
		OUTPUTFILE="$2"
		shift
		shift
		;;
	-q|--quiet)
		QUIET="yes"
		shift
		;;
	*)
		echo "Invalid Option(s) Set. Please use -h for help."
		shift
		shift
		;;
	esac
done

###Verification of Valid Options###
if [ -z $WORDLIST ]; then
	WORDLIST="/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt"
fi
if [ ! -r $WORDLIST ]; then
	echo "The file $WORDLIST cannot be found. Please specify a valid wordlist."
	exit
fi

if [ -z $TARGET ]; then
	echo "No target has been set. A target must be specified for wildcard-webpage-evade to run."
	exit
fi

if [ -z "$REDIRECTSTRING" ]; then
	echo "No Redirect String (-s) was specified. A Redirect String must be specified for wildcard-webpage-evade to run."
	exit
fi

if [ -z $OUTPUTFILE ]; then
	OUTPUTFILE="./wildcard-webpage-evade.output"
fi

###Brute Forcing Pages###
EXTENSION_LIST=("")
if [ -n $EXTENSIONS ]; then
	for extension in $(echo $EXTENSIONS | tr "," "\n"); do
		EXTENSION_LIST=("${EXTENSION_LIST[@]}" ".$extension")
	done
fi
echo -e "----------------------------------------------\n"
echo -e "${WHITE_B}Target:${RESET} $TARGET"
echo -e "${WHITE_B}Wordlist:${RESET} $WORDLIST"
echo -e "${WHITE_B}Extensions:${RESET} $EXTENSIONS"
echo -e "${WHITE_B}Output File:${RESET} $OUTPUTFILE"
echo -e "${WHITE_B}String:${RESET} $REDIRECTSTRING"
echo -e "\n----------------------------------------------"
if [ "$QUIET" = "yes" ]; then
	echo -e "\nThe Quiet (-q) Option has been specified. There will only be output when a valid page is found."
fi
echo " "
for word in $(cat $WORDLIST); do
	for extension in "${EXTENSION_LIST[@]}"; do
		response=$(curl -k -s $TARGET/$word$extension)
		if [ $(echo $response | grep -c "$REDIRECTSTRING") -eq 1 ]; then
			if [ -z $QUIET ]; then
				echo -e "${RED}Page $TARGET/${RED_B}$word$extension ${RED}not found.${RESET}"
			fi
		elif [ $(echo $response | egrep -c "<|>|;|:|/") -eq 0 ]; then
			if [ -z $QUIET ]; then
				echo -e "${RED}Page $TARGET/${RED_B}$word$extension ${RED}not found.${RESET}"
			fi
		else
			echo -e "${GREEN}Page $TARGET/${GREEN_B}$word$extension ${GREEN}FOUND!${RESET}"
			echo "$(date) : $TARGET/$word$extension FOUND." >> $OUTPUTFILE
	fi
	done
done


