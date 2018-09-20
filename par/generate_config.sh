#!/bin/bash

#mkdir jobs_2


#list of videos
declare -a id1="Meridian3840x2160,.mkv"
declare -a id2="Meridian3840x2160,"


#list all crf values
declare -a crfs=(16 \
22 \
28 \
34)

declare -a max_durs=(4 \
6 \
8 \
10)



for c in "${crfs[@]}"
do
	for md in "${max_durs[@]}"
	do
			encoder="x264"
			file_id="$id2"_"$c"-"$md"-"$encoder"-"var"
			printf "{\"video\": \"$id1\", \n \"crf\": $c, \n \"min_length\": 0, \n \"max_length\": $md, \n \"target_seg_length\": \"var\", \n \"encoder\": \"$encoder\"}"> jobs_2/"$file_id".txt 

			encoder="x265"
			file_id="$id2"_"$c"-"$md"-"$encoder"-"var"
			printf "{\"video\": \"$id1\", \n \"crf\": $c, \n \"min_length\": 0, \n \"max_length\": $md, \n \"target_seg_length\": \"var\", \n \"encoder\": \"$encoder\"}"> jobs_2/"$file_id".txt 			
		
	done
done

