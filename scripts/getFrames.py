import commands, os, sys, re, time
import subprocess

input_file=str(sys.argv[1])
file_name=str(sys.argv[2])


command_string = "ffprobe -show_frames "+input_file
#command=commands.getoutput(command_string)
output = subprocess.Popen(command_string, stdout=subprocess.PIPE, shell=True)

output_file=open("frames_"+file_name+".txt","w");
output_file.write("#counter;key_frame;size;duration;coded_picture_number\n")

counter=1
for line in output.stdout.readlines():
	if line.startswith('key_frame=0'):
		key_frame=0
	if line.startswith('key_frame=1'):
		key_frame=1
	if line.startswith('pict_type'):
		splitted_str=line.split('=')
		pict_type=(splitted_str[1]).strip();
	if line.startswith('pkt_duration_time'):
		splitted_str=line.split('=')
		duration=(splitted_str[1]).strip();
	if line.startswith('pkt_size'):
		splitted_str=line.split('=')
		size=(splitted_str[1]).strip();
	if line.startswith('coded_picture_number'):
		splitted_str=line.split('=')
		coded_picture_number=splitted_str[1].strip()
	if line.startswith('best_effort_timestamp_time'):
		splitted_str=line.split('=')
		be_ts=(splitted_str[1]).strip()
	if line.startswith('[/FRAME]'):	
		output_file.writelines(str(pict_type)+";"+str(key_frame)+";"+str(size)+";"+str(duration)+";"+str(coded_picture_number)+";"+str(be_ts)+"\n");
		output_file.flush()	
		counter=counter+1

