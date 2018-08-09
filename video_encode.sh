#!/usr/bin/env bash

err_trap() {
    echo "Error happened!. Quitting."
    exit -1
}

trap 'err_trap' ERR

if [ "$#" -ne 6 ]; then
    echo "Usage: video_encode.sh <video_id> <crf_value> <key_int_min> <key_int_max> <target_seg_length> <codec>"
    exit -1
fi

steady_id=$1
vid_id=/videos/$1.y4m
crf_val=$2
min_dur=$3
max_dur=$4 
target_seg_length=$5
codec=$6

if [ ! -f "$vid_id" ]; then
    echo "Video file $vid_id not found!"
    exit -1
fi

TS=$(date +%s)

encoding_id=$steady_id\_$codec\_$crf_val\_$min_dur\_$max_dur\_$target_seg_length

# Store the segments in the temporary folder

RESULTS="/results"
TMP="/tmpdir"

echo $vid_id

SINCE=$(( $(date +%s) - $TS ))
echo "### Collecting metrics (${SINCE}s since start) ###"

#collect some video metrics which do not differ for the encodings
#duration of complete video sequence
dur=$(ffprobe -i $vid_id -show_entries format=duration -v quiet | grep duration | awk '{ print $1} ' | tr -d duration=)
#frames per second
fps=$(ffmpeg -i $vid_id 2>&1 | sed -n "s/.*, \(.*\) fp.*/\1/p")
fps=$(python -c "from math import ceil; print ceil($fps)")
resolution=$(ffmpeg -i $vid_id 2>&1 | grep -oP 'Stream .*, \K[0-9]+x[0-9]+')
#bitrate of raw video
tmp_bitrate=$(ffmpeg -i $vid_id 2>&1 | grep bitrate | sed 's/.*bitrate=\([0-9]\+\).*/\1/g')
bitrate=$(echo $tmp_bitrate | awk {' print $6 '})

#Segment size in frames (depends on duration and fps)
key_int_max=$(echo $fps*$max_dur | bc)
key_int_min=$(echo $fps*$min_dur | bc)


SINCE=$(( $(date +%s) - $TS ))
echo "### Encoding video (${SINCE}s since start) ###"

#variable encoding
#threads -1 makes the whole thing deterministic (each encoding with this parameters will result in the same encoded resulting video)
#crf: constant rate factor, i.e. quality 
#pass: denotes first and second pass
#keyint: maximum gop size 
#min-keyint: minimum gop size
if [[ $target_seg_length == "var" ]]; then

	#encode the video in case of variable
	ffmpeg -nostats -threads 1 -i $vid_id -crf $crf_val -vcodec lib"$codec" -"$codec"-params keyint="$key_int_max":min-keyint="$key_int_min" -f stream_segment -segment_list $TMP/out.m3u8  $TMP/out_%03d.ts -pass 2
	

else
	min_dur=$target_seg_length
	max_dur=$target_seg_length
	#encode the video in case of fixed length
	ffmpeg -nostats -threads 1 -i $vid_id -crf $crf_val -vcodec lib"$codec" -f stream_segment -segment_time $target_seg_length -force_key_frames "expr:gte(t,n_forced*$target_seg_length)" -segment_list $TMP/out.m3u8  $TMP/out_%03d.ts -pass 2
	

fi

SINCE=$(( $(date +%s) - $TS ))
echo "### Analyzing encoded video (${SINCE}s since start) ###"

num_segs="$(ls $TMP/ | wc -l)" 
num_segs=$(($num_segs-1))

temp_br=$(python scripts/getBitrates.py $TMP $encoding_id $num_segs)
avg_br=$(echo $temp_br | sed -n 1p | awk {' print $2 '})
std_br=$(echo $temp_br | sed -n 1p | awk {' print $6 '})
min_br=$(echo $temp_br | sed -n 1p | awk {' print $10 '})
max_br=$(echo $temp_br | sed -n 1p | awk {' print $14 '})
avg_br_clean=$(echo $temp_br | sed -n 1p | awk {' print $18 '})
std_br_clean=$(echo $temp_br | sed -n 1p | awk {' print $22 '})
min_br_clean=$(echo $temp_br | sed -n 1p | awk {' print $26 '})
max_br_clean=$(echo $temp_br | sed -n 1p | awk {' print $30 '})


SINCE=$(( $(date +%s) - $TS ))
echo "### Computing quality metrics (${SINCE}s since start) ###"

#compute SSIM, m_ssim, psnr, vmaf
ffmpeg -nostats -i $TMP/out.m3u8 -i $vid_id -lavfi libvmaf="log_path=quality_metrics.txt:psnr=1:ssim=1:ms_ssim=1" -f null -



#ff_output=$(ffmpeg -i $sub_dir/out.m3u8 -i $vid_id  -filter_complex "ssim" -f null - 2>&1 > /dev/null)

#ffmpeg -i $sub_dir/out.m3u8 -i $vid_id -lavfi "ssim=ssim.log;[0:v][1:v]psnr=psnr.log;[0:v][1:v]libvmaf=libvmaf.log" -f null –
#ffmpeg -i $sub_dir/out.m3u8 -i $vid_id -lavfi "libvmaf=libvmaf.log" -f null -
#ffmpeg -i subdir/out.m3u8 -i bbb_first_min.y4m -lavfi libvmaf -f null -

#all_val=$(echo $ff_output | awk '{print $((NF-1))}')
#pref="All:"
#avg_ssim=${all_val#$pref}

#all_val_psnr=$(echo $$ff_output | awk '{print $((NF-1))}')
#pref="average:"
#avg_psnr=${all_val_psnr$pref}


SINCE=$(( $(date +%s) - $TS ))
echo "### Getting segment length, file sizes, etc. (${SINCE}s since start) ###"

tmp_seglength=$(python scripts/getSegmentLength.py $TMP/out.m3u8 $encoding_id)
avg_seglength=$(echo $tmp_seglength | sed -n 1p | awk {' print $2 '})
std_seglength=$(echo $tmp_seglength | sed -n 1p | awk {' print $6 '})
min_seglength=$(echo $tmp_seglength | sed -n 1p | awk {' print $10 '})
max_seglength=$(echo $tmp_seglength | sed -n 1p | awk {' print $14 '})
avg_seglength_clean=$(echo $tmp_seglength | sed -n 1p | awk {' print $18 '})
std_seglength_clean=$(echo $tmp_seglength | sed -n 1p | awk {' print $22 '})
min_seglength_clean=$(echo $tmp_seglength | sed -n 1p | awk {' print $26 '})
max_seglength_clean=$(echo $tmp_seglength | sed -n 1p | awk {' print $30 '})


tmp_filesize=$(python scripts/getFileSize.py $TMP $encoding_id $num_segs)
avg_segsize=$(echo $tmp_filesize | sed -n 1p | awk {' print $2 '})
std_segsize=$(echo $tmp_filesize | sed -n 1p | awk {' print $6 '})
min_segsize=$(echo $tmp_filesize | sed -n 1p | awk {' print $10 '})
max_segsize=$(echo $tmp_filesize | sed -n 1p | awk {' print $14 '})
avg_segsize_clean=$(echo $tmp_filesize | sed -n 1p | awk {' print $18 '})
std_segsize_clean=$(echo $tmp_filesize | sed -n 1p | awk {' print $22 '})
min_segsize_clean=$(echo $tmp_filesize | sed -n 1p | awk {' print $26 '})
max_segsize_clean=$(echo $tmp_filesize | sed -n 1p | awk {' print $30 '})


total_segsize=$(echo $tmp_filesize | sed -n 1p | awk {' print $34 '})

python scripts/getFrames.py $TMP/out.m3u8 $encoding_id > /dev/null 2> /dev/null

SINCE=$(( $(date +%s) - $TS ))
echo "### Finishing up (${SINCE}s since start) ###"

mkdir -p /$RESULTS/$encoding_id 2>/dev/null
mv *.txt /$RESULTS/$encoding_id 2>/dev/null

echo "$steady_id;$codec;$dur;$fps;$resolution;$bitrate;$crf_val;$target_seg_length;$min_dur;$max_dur;$num_segs;$avg_seglength;$std_seglength;$min_seglength;$max_seglength;$avg_seglength_clean;$std_seglength_clean;$min_seglength_clean;$max_seglength_clean;$total_segsize;$avg_segsize;$std_segsize;$min_segsize;$max_segsize;$avg_segsize_clean;$std_segsize_clean;$min_segsize_clean;$max_segsize_clean;$avg_br;$std_br;$min_br;$max_br;$avg_br_clean;$std_br_clean;$min_br_clean;$max_br_clean" > /$RESULTS/$encoding_id/summary.txt
