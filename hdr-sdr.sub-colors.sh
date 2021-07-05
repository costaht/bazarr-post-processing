#!/bin/bash
# Credit to https://github.com/brianspilner01/media-server-scripts/blob/master/sub-clean.sh which this script is heavily modified from
# Created by Discord user kal-el#4076

	# This script changes subtitle color for SDR & HDR video files respectively. 
	# Requires color code a specific to be present in .srt file and file names to have HDR, DV etc in them.
	# If there is no HDR tag in filename the script will guess HDR for _Movies_ that have "Bluray" & "UHD" in them.
	# The script will default to SDR color if it cant see or guess HDR!
	# For best results follow scene naming.
	
	# How to use manually:
	# Run this script across your whole media library:
	# find /path/to/library -name '*.srt' -exec /path/to/sub-color.sh "{}" \;
	# SETTINGS BELOW IS STILL NEEDED IN MANUAL MODE
	
	# How to use with Bazarr:
	# Add the line below to Bazarr (Settings > Subtitles > Use Custom Post-Processing > Post-processing command):
	# /path/to/sub-color.sh "{{subtitles}}" 

	# Enabe Bazarr to add color to your subtitle (important), Settings->Subtitles->Color->Drop down menu
	# Download a subtitle using Bazarr and open the .srt file, copy the color code in the file (#xxxxxx format) to bazarr_color setting below. Important!
	# Find color codes wanted for SDR & HDR content and put them in hdr_color and sdr_color settings below, also #xxxxxx format.
	# A good place get color hex-codes: https://www.color-hex.com/color-names.html
	
	# Add tv and movie root folders in dir_tv & dir_movie settings below. 
	# This is needed so script can see if it is a movie or tv show and guess HDR.


	## !!!! PLEX INTEGRATION IS NOT TESTED BUT SHOULD WORK !!!! ##
	# Add to Sub-Zero (in Plex > Settings > under Manage > Plugins > Sub-Zero Subtitles > Call this executable upon successful subtitle download (near the bottom):
	# /path/to/sub-color.sh %(subtitle_path)s


#User settings needed:
bazarr_color="" 					#Color used in bazarr. #000000 is black 
hdr_color="" 						#Color wanted for HDR subtitles, #xxxxxx format
sdr_color=""						#Color wanted for SDR subtitles, #xxxxxx format
dir_tv=""							#Root folder for tv-shows e.g.: /media/tv/
dir_movie=""						#Root folder for movies e.g.: /media/movies/



# ------------ No further user action needed  ------------ #


#Import filepath {{subtitles}} from Bazarr Custom Processing Command.
SUB_FILEPATH="$1"
SUB_FILENAME=`echo $(basename "${SUB_FILEPATH%.*}")`


# Check if filename contains HDR 
if grep -oiEq 'HLG|HDR|HDR10|HDR10+|HDR10Plus|DoVi|DV|Dolby.Vision' <<< "$SUB_FILENAME"; then sub_hdr=true && echo "Found HDR tag." ; fi

# Check if filename contains SDR
if grep -oiEq 'SDR' <<< "$SUB_FILENAME"; then sub_sdr=true && echo "Found SDR tag."; fi

# Check if it is a Bluray rip
if grep -oiEq 'Bluray|Blu-ray|BRRip|BDRip' <<< "$SUB_FILENAME"; then sub_blu=true ; fi

# Check if filename is 4K
if grep -oiEq '2160p|UHD' <<< "$SUB_FILENAME"; then sub_4k=true ; fi

# Check if it is a movie or tv-show
if grep -oiEq "$dir_tv" <<< "$SUB_FILEPATH"; then sub_tv=true && echo "This is a TV-show." ; else sub_movie=true && echo "This is a movie." ; fi



#If sub_hdr or sub_sdr aldeady true exit and continue with setting color 
if [ "$sub_hdr" = true ] || [ "$sub_sdr" = true ]; then
    :
elif [ "$sub_movie" = true ] && [ "$sub_4k" = true ] && [ "$sub_blu" = true ]; then
    sub_hdr=true && echo "Guessing this is HDR."
else
    sub_sdr=true && echo "Guessing this is SDR."
fi


# Check that file exists
[ ! -f "$SUB_FILEPATH" ] && { echo "usage: sub-color.sh [FILE]" ; echo "Warning: subtitle file does not exist" ; exit 1 ; }

# Check for bazarr_color code in file
case `grep -q "$bazarr_color" "$SUB_FILEPATH" >/dev/null; echo $?` in
  0)
	echo "Found bazarr color code $bazarr_color in file. Starting color change."
   # code if found
       	if [[ "$SUB_FILEPATH" =~ \.srt$ ]] # only operate on srt files
		then
			# convert any DOS formatted files to UNIX (remove carriage return line endings)
			   sed -i 's/\r$//g' "$SUB_FILEPATH"

			if [ "$sub_hdr" = true ]; then
			    sed -i -e 's,'"$bazarr_color"','"$hdr_color"',gI' "$SUB_FILEPATH"
			    echo "HDR color $hdr_color applied."
			else
			    sed -i -e 's,'"$bazarr_color"','"$sdr_color"',gI' "$SUB_FILEPATH"
			    echo "SDR color $sdr_color applied."
			fi

		else
			echo "Provided file must be .srt"
			exit 1
		fi
	;;
  1)
    echo "Sub has not been color coded $bazarr_color by Bazarr, nothing to replace. Exiting."
	exit 1
	# code if not found
	;;
  *)
    echo "Unexpected error, exiting."
	exit 2
	# code if an error occurred
	;;
esac
