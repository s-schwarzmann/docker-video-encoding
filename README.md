# docker-video-encoding

Docker container for DASH video encoding using FFMPEG. 
The following parameters can be specified: 

* _crf_: value to specify target output quality 
* _mindur_: specify the minimum duration of a segment in seconds (relevant in case of variable segment duration encoding)
* _maxdur_: specify the maximum duration of a segment in seconds (relevant in case of variable segment duration encoding)
* _seglen_: specify the fix duration in seconds of all video segments (in case of variable set seglen="var")
* _encoder_: specify the encoder. supported: x264. planned to be supported: x265, vp9

If the source video shall be splitted into segments of fixed duration, set maxdur=0 and mindur=0; If the source video shall be splitted into segments of variable duration, please set seglen="var".

## QUICKSTART

Example for fixed segment durations: 

```
sudo docker run --rm -v "$PWD"/samples/videos/:/videos \
                     -v "$PWD"/samples/results/:/results \
                     ls3info/encoding:latest big_buck_bunny_360p24_30s 41 0 0 4 x264

```

## Local Testing

First build the image:

	sudo docker build -t ls3info/encoding:latest .

You can start and enter the build image with:

```
sudo docker run --rm -it --entrypoint=bash ls3info/encoding:latest
```

If you want to test encoding, also add the videos/ and results/ volumes:

```
sudo docker run --rm -v "$PWD"/samples/videos/:/videos \
                     -v "$PWD"/samples/results/:/results \ 
                     -it --entrypoint=bash ls3info/encoding:latest
```

