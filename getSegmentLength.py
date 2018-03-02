import commands, os, sys, re, time
import subprocess
import pandas as pd
import time

input_file=str(sys.argv[1])
file_name=str(sys.argv[2])


f = open(input_file, 'r')

output_file=open("segment_length_"+file_name+".txt","w");

for line in f:
        if line.startswith('#EXTINF'):
		splitted_str=line.split(':');
		seg_length=splitted_str[1].strip();
		seg_length=seg_length[:-1]
		output_file.writelines(str(seg_length)+'\n');
		output_file.flush();

time.sleep(0.5)
f=open("segment_length_"+file_name+".txt","r");
data = pd.read_csv(f, sep=" ", header=None)
data2 = data.drop(data.index[len(data)-1])
print(str(data.mean()))
print(str(data.std()))		
print(str(data.min()))
print(str(data.max()))

print(str(data2.mean()))
print(str(data2.std()))		
print(str(data2.min()))
print(str(data2.max()))
