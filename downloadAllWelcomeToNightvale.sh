#!/bin/bash
newone="false"
newdur=""
declare -A CurrentITEM
cd "/home/will/Music/Podcasts/Welcome_To_Nightvale"

function doWorkOnEpisode () {
	#1:title,2:number,3:date,4:duration,5:url
	title="$1"
	number="$2"
	date="$3"
	duration="$4"
	url="$5"
#Check that the episode number is a number, if it isn't, it's bonus junk to be skipped
	case $number in
		''|*[!0-9]*) echo "Skipping Non-Nightvale content" ;;
		*)
			if ! [[ -f "$title.mp3" ]]; then
				echo "Episode $number does not exist. Downloading"
				wget $url -O "$title.mp3"
				newone="true"
				newdur=$4
			else
				echo "Episode $number already exists."
			fi
			#echo "----"
			#echo "Episode $number"
			#echo "Title: $title"
			#echo "Duration: $duration"
			#echo "Published: $date"
			#echo "----"
		;;
	esac
}
function extractEpisodeData() {
	str="$1"
	printIfString "$str" "title"
	num=$(echo ${CurrentITEM["title"]} | cut -d "-" -f 1)
	CurrentITEM["num"]="$num"
	printIfString "$str" "pubDate"
	printIfString "$str" "enclosure" "true"
	url=$(echo ${CurrentITEM["enclosure"]} | grep -o url=\".*\")
	url=${url/url=/""}
	url=${url//'"'/""}
	CurrentITEM["url"]="$url"
	printIfString "$str" "itunes:duration"
	dur=${CurrentITEM["itunes:duration"]}
	if [[ "$dur" != "" ]]; then
		#Duration is the last one in the item, so if it's not blank, we've got all the data
		doWorkOnEpisode "${CurrentITEM["title"]}" "${CurrentITEM["num"]}" "${CurrentITEM["pubDate"]}" "${CurrentITEM["itunes:duration"]}" "${CurrentITEM["url"]}"
		CurrentITEM["title"]=""
		CurrentITEM["num"]=""
		CurrentITEM["pubDate"]=""
		CurrentITEM["itunes:duration"]=""
		CurrentITEM["url"]=""
	fi
}
function printIfString() {
	#1=data, 2=tag, 3=isSelfClosingTagType
	data="$1"
	tag="$2"
	len=${#tag}
	if [[ "$3" == "true" ]]; then
		let len=len+1
		if [[ "${data:0:$len}" == "<$tag" ]]; then
			data=${data/<$tag/""}
			data=${data/\/>/""}
			if [[ "$data" != "" ]]; then
				CurrentITEM["$tag"]="$data"
			#	echo "CurrentITEM[$tag]=$data"
			fi
		fi
	else
		let len=len+2
		if [[ "${data:0:$len}" == "<$tag>" ]]; then
			data=${data/<$tag>/""}
			data=${data/<\/$tag>/""}
			if [[ "$data" != "" ]]; then
				CurrentITEM["$tag"]="$data"
			#	echo "CurrentITEM[$tag]=$data"
			fi
		fi
	fi
}

#showID="536258179"
showID="rss"
sourceURL="http://nightvale.libsyn.com/rss"
if [[ -f "$showID" ]]; then
	rm $showID
fi
wget $sourceURL
source=$(cat $showID)

echo "Starting Scan"
OLDIFS=$IFS
IFS=$(echo -e "\n")
while read -r line; do
	line=$(echo $line | tr -d '[:space:]')
	if [[ "$line" == "<item>" ]]; then
		#echo "--------Start of ITEM"
		pendown="true"
	elif [[ "$line" == "</item>" ]]; then
		pendown="false"
		#echo "--------End of ITEM"
		echo ""
	fi
	if [[ "$pendown" == "true" ]]; then
		IFS=$OLDIFS
		extractEpisodeData "$line"
		IFS=$(echo -e "\n")
	fi
done <<<$source
IFS=$OLDIFS

rm $showID
if [[ "$newone" == "true" ]]; then
	notify-send "New Podcast" "Welcome to Nightvale - $newdur"
fi
echo "Done"

