import commands, os, sys, re, time
import pandas as pd
import time

sub_dir=str(sys.argv[1])
output_name=str(sys.argv[2])
segment_num=int(round(float(sys.argv[3])))

f = open('filesize_'+str(output_name)+'.txt', 'w')
for i in range (0,segment_num):
	file_name = str(i)
	while len(file_name)<3:
		file_name="0"+file_name
	command_string = "du -h -B1 "+str(sub_dir)+"/out_"+file_name+".ts | awk '{ print $1; }'"
	command=commands.getoutput(command_string)
	command=command[:-1]
	f.write(command+"\n")


time.sleep(0.5)
f = open('filesize_'+str(output_name)+'.txt', 'r')
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

print(str(data.sum()))		

