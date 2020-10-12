#!/bin/sh
# Any copyright is dedicated to the Public Domain.
# https://creativecommons.org/publicdomain/zero/1.0/

# Initial function (Main), will check URLs and format them if necessary
initialize() {
	local URL=""
	for i in ${target_url}; do
		if [[ ${URL} ]]; then
			URL=""
		fi
		case $i in
			"http://"*"http://"* | "https://"*"https://"* | \
			"www."*".com"*"www."*".com"* | *".com"*".com"* )
				echo -ne "[${YC}WARNING${NC}]: URL's must be separated by spaces.${NC}\n"
				return 1
			;;
			"http://"* | "https://"* )
				URL+="$i"
				get "$URL"
			;;
			"www."*".com"* | *".com"* )
				URL+="http://"
				URL+="$i"
				get "$URL"
			;;
		esac
	done
	return 0
}

# Function that obtains data with youtube-dl and saves it to ~/Videos
get() {
	# Get directories (aka. dir)
	local current_dir=$(pwd)
	local target_dir=$(echo -n ~/Videos)
	
	# Get video title, used for the download messages
	local title=$(/usr/bin/env youtube-dl -s -e $1)
	
	# Change directory to the target directory (~/Videos)
	cd $target_dir
	
	# Check verbose flag state value and define youtube-dl arguments
	if [ "${verbose}" -eq 2 ]; then
		local cmd_argv="-c --recode-video mp4 -o %(title)s.%(ext)s"
	else
		local cmd_argv="-q -c --recode-video mp4 -o %(title)s.%(ext)s"
	fi
	
	# Send download default messages:
	echo -e "${GRC}▶ ${NC}Get: ${CBC}${title}${NC}"
	echo -e "${GRC}▶ ${NC}Save to: ${CC}${target_dir}${NC}"
	
	# Check verbose flag are different then 0 (default)
	# and show full youtube-dl command as message
	if [ "${verbose}" -eq 2 -o "${verbose}" -eq 1 ]; then
		echo "/usr/bin/env youtube-dl ${cmd_argv} \"$1\""
	fi

	# Execute youtube-dl with defined arguments
	/usr/bin/env youtube-dl ${cmd_argv} "$1"
	
	# Check youtube-dl return code
	if [ $? -eq 0 ]; then
		count_c=$((count_c+1)) # Success
	else
		count_f=$((count_f+1)) # Fail
	fi
	
	# Change the directory to the original directory (Formerly current)
	cd $current_dir
}

# Print help message function
help_msg() {
	echo "Usage: $0 [OPTIONS] [URL/LINK]"
	echo -e "\nExemple:\n"
	echo "   $0 \"link\""
	echo "   $0 \"link1\" \"link2\" \"link3\""
	echo -e "\nOptions:"
	echo "   -v,-vv,--verbose  Verbose mode."
	echo "   --version  Show current version."
	echo "   -h, --help  Show help page."
}

# Counter for download attempts:
count_c=0 # Count downloads completed (Success attempt)
count_f=0 # Count downloads failed (Fail attempt)

# Script info:
readonly EXEC_NAME=$0 # Script filename
readonly RELEASE="1.0.0"

# Message colors:
readonly BC="$(printf '\033[0;34m')" # Blue color
readonly BBC="$(printf '\033[1;34m')" # Blue color bold
readonly NC="$(printf '\033[0m')" # No color
readonly GRC="$(printf '\033[1;32m')" # Green color bold
readonly CC="$(printf '\033[0;36m')" # Cyan color
readonly CBC="$(printf '\033[1;36m')" # Cyan color bold
readonly WC="$(printf '\033[1;37m')" # White color bold
readonly YC="$(printf '\033[1;33m')" # Yellow color bold
readonly GC="$(printf '\033[0;37m')" # Gray color
readonly RC="$(printf '\033[1;31m')" # Red color

# Define verbose flag (Default state)
verbose=0

# Define the target URL value to empty
target_url=""

# Initializes a loop for check each argument if any
while [[ $# > 0 ]]; do
	case "$1" in
		-h | --help ) # Help options
			help_msg
			exit 0
		;;
		
		-V | --version ) # Version options
			echo "Version $RELEASE"
			exit 0
		;;
		
		-v | --verbose ) # Verbose options
			if [ $verbose -eq 0 ]; then
				verbose=1
			fi
			shift
		;;
		
		-vv ) # Verbose options (More information)
			if [ $verbose -eq 0 ]; then
				verbose=2
			fi
			shift
		;;
		
		## Match URL/LINK parsed as command line argument ##
		"http://"* | "https://"* | "www."*".com"* | *".com"* )
			target_url+=" $1"
			shift
		;;
		
		*) # Case an unknow option is parsed
			echo "Unknow option '$1' parsed, return error"
			exit 1
		;;
	esac
done

# Checks if the script is running as root (Administrator account or equivalent)
if [[ $(id -u) -eq 0 ]]; then
	echo -ne "[${RC}ERROR${NC}]: Running script as root.${NC}\n"
	echo "For your data security, do not run this script as root."
	exit 2	
fi	

echo -e "\n ╼ ╼ ╼ ╼ ╼ ╼ ╼ ╼ [ STARTING ] ╾ ╾ ╾ ╾ ╾ ╾ ╾ ╾\n"

if [[ ${target_url} ]]; then
	## Initialize with URL's parsed as command line argument
	initialize
else
	## User input menu:
	while
	echo -ne "${WC}▼ ${BC}Enter URL's or just press ENTER to exit ${WC}▼\n${BBC}∷ ${GC}" && \
	read k && \
	echo -ne "${NC}"; do
		case "$k" in
			"http://"* | "https://"* | "www."*".com"* | *".com"* )
				if [[ ${target_url} ]]; then
					target_url=""
				fi
				target_url+=" $k"
				initialize
			;;
			''|' ') break;;
		esac
	done
fi

echo -e "\n ╼ ╼ ╼ ╼ ╼ ╼ ╼ ╼ [ FINAL INFO ] ╾ ╾ ╾ ╾ ╾ ╾ ╾ ╾ "
echo -e " — Attempets success: ${GRC}${count_c}${NC}"
echo -e " — Attempets fails: ${GRC}${count_f}${NC}"

exit 0
