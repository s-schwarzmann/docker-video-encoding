# docker-video-encoding

Docker container for DASH video encoding using FFMPEG. 
The following parameters can be specified in a config file: 

* _crf_: value to specify target output quality 
* _mindur_: specify the minimum duration of a segment in seconds (relevant in case of variable segment duration encoding)
* _maxdur_: specify the maximum duration of a segment in seconds (relevant in case of variable segment duration encoding)
* _seglen_: specify the fix duration in seconds of all video segments (relevant in cas of fixed segment duration encoding)

If the source video shall be splitted in segments of fixed duration, set maxdur=0 and mindur=0; 
