# docker-video-encoding

Docker container for DASH video encoding using FFMPEG. 
The following parameters can be specified: 

* _crf_: value to specify target output quality 
* _mindur_: specify the minimum duration of a segment in seconds (relevant in case of variable segment duration encoding)
* _maxdur_: specify the maximum duration of a segment in seconds (relevant in case of variable segment duration encoding)
* _seglen_: specify the fix duration in seconds of all video segments (in case of variable set seglen="var")
* _encoder_: specify the encoder. supported: x264. planned to be supported: x265, vp9

If the source video shall be splitted into segments of fixed duration, set maxdur=0 and mindur=0; If the source video shall be splitted into segments of variable duration, please set seglen="var".

## QUICKSTART (encoding only)

First download an example video:

```
wget https://service.inet.tu-berlin.de/owncloud/index.php/s/8NA7IFNKN9TgXVA/download -O samples/videos/bigbuckbunny480p24x30s.y4m
```

Encode the example with fixed segment durations: 

```
sudo docker run --rm -v "$PWD"/samples/videos/:/videos \
                     -v "$PWD"/samples/results/:/results \
                     fginet/docker-video-encoding:latest bigbuckbunny480p24x30s.y4m 41 0 0 4 x264

```

The command line arguments are:

```
<video_id> <crf_value> <key_int_min> <key_int_max> <target_seg_length> <codec>
```

You can find the results in the *samples/results* folder.

## QUICKSTART (with worker and job queue)

**Important**: Make sure that docker is configured to work without root access.

First make sure you downloaded the video as described about (*bigbuckbunny480p24x30s.y4m*).
Afterwards make a copy of the job template:

```
cp samples/jobs/00_waiting/bigbuckbunny480p24x30s_job001.txt.tmpl samples/jobs/00_waiting/bigbuckbunny480p24x30s_job001.txt
```

Start the worker:

```
python3 worker.py --dry-run --one-job
```

The following options are used:

  * *--dry-run*: does not call the container, but prints the docker command.
  * *--one-job*: quit after processing one job.

### run_workers.sh Script

Use the *run_workers.sh* script to start a worker on each available core:

```
cp run_workers_template.sh run_workers.sh
```

Adapt the paths and parameters in the script and remove the *echo* from *echo screen* in the script to activate the workers when you execute the script.

You can stop all running workers after the current job with creating a *STOP_WORKERS* file in the working directory:

```
touch STOP_WORKERS
```

## Local Testing

First build the image:

	sudo docker build -t fginet/docker-video-encoding:latest .

You can start and enter the build image with:

```
sudo docker run --rm -it --entrypoint=bash fginet/docker-video-encoding:latest
```

If you want to test encoding, also add the videos/ and results/ volumes:

```
sudo docker run --rm -v "$PWD"/samples/videos/:/videos \
                     -v "$PWD"/samples/results/:/results \
                     -it --entrypoint=bash fginet/docker-video-encoding:latest
```

