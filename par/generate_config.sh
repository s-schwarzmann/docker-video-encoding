#!/bin/bash

mkdir jobs_1


#list of videos
declare -a ids=("bigbuckbunny480p24" "bigbuckbunny720p24" "tos4k")


#list all crf values
declare -a crfs=(16 \
22 \
28 \
34)

declare -a max_durs=(4 \
6 \
8 \
10)

for i in "${ids[@]}"
do
	for c in "${crfs[@]}"
	do
		for md in "${max_durs[@]}"
		do
			encoder="x264"
			file_id="$i"_"$c"-"$md"-"$encoder"-"var"
			printf "{\"video\": \"$i\", \n \"crf\": $c, \n \"min_length\": 0, \n \"max_length\": $md, \n \"target_seg_length\": \"var\", \n \"encoder\": \"$encoder\"}"> jobs_1/"$file_id".txt 

			encoder="x265"
			file_id="$i"_"$c"-"$md"-"$encoder"-"var"
			printf "{\"video\": \"$i\", \n \"crf\": $c, \n \"min_length\": 0, \n \"max_length\": $md, \n \"target_seg_length\": \"var\", \n \"encoder\": \"$encoder\"}"> jobs_1/"$file_id".txt 			
		
		done
	done
done

