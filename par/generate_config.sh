#!/bin/bash

mkdir jobs_1
encoder="x264"

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
			file_id="$i"_"$c"-"$md"-"$encoder"
			echo $file_id
			#touch jobs_1/"$file_id"
			printf "{\"video\": \"$i\", \n \"crf\": $c, \n \"min_length\": 0, \n \"max_length\": $md, \n \"target_seg_length\": \"var\", \n \"encoder\": \"$encoder\"}"> jobs_1/"$file_id".txt 
		
		done
	done
done

