#!/bin/bash

#list all ids
#declare -a ids=("9o9qSGZwMKE" \
#"9wLV4cl7hCE" \
#"big_buck_bunny_1080p24" \
#"BreatheOut-StealingHeather-ForResearchOnly-420" \
#"_bw06BVC3FM" \
#"elephants_dream_720p24" \
#"fuMtNy_iBiY" \
#"IRfqvsgWBMw" \
#"sintel" \
#"sita_sings_the_blues_1080p24" \
#"th1NTVIhUQU" \
#"TXxFR6-L_Zk" \
#"vkmpwS1aCc8" \
#"vulcfGo_mw4" \
#"AeLyrPgV0-Q" \
#"P6kDZhLIkqw" \
#"PoEIW1mjxFE" \
#)

declare -a ids=("9o9qSGZwMKE" "sintel" "9wLV4cl7hCE" "AeLyrPgV0-Q" "big_buck_bunny_1080p24")
#declare -a ids=("9o9qSGZwMKE" "sintel")
#list all crf values
declare -a crfs=(17 \
20 \
23 \
26 \
29 \
32 \
35 \
41)

#min max combinations
declare -a min_max=("0 15 var" \
"0 100 var" \
"0 10 var" \
"0 5 var" \
"1 15 var" \
"1 10 var" \
"1 5 var" \
##tommy
"2 5 var" \
"2 6 var" \
"2 7 var" \
"2 8 var" \
"2 9 var" \
"2 10 var" \
"3 5 var" \
"3 6 var" \
"3 7 var" \
"3 8 var" \
"3 9 var" \
"3 10 var" \
"4 5 var" \
"4 6 var" \
"4 7 var" \
"4 8 var" \
"4 9 var" \
"4 10 var" \
"5 6 var" \
"5 7 var" \
"5 8 var" \
"5 9 var" \
"5 10 var" \
)

for i in "${ids[@]}"
do
	for c in "${crfs[@]}"
	do
		#fixed length
		for target_lens in `seq 0.5 0.5 15.0`;
		do
			echo $i $c 0 0  "$target_lens"  | sed s/\,/./g
		done
		#variable length 0 15
		for mm in "${min_max[@]}"
		do
			echo $i $c "$mm" 
		done
	done
done
