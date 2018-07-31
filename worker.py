import os
import sys
import shutil
import logging
import random
import json
import time
import subprocess
from os.path import join as pjoin

log = logging.getLogger(__name__)

def get_and_lock_job(jobdir, vdir, wid):
	"""
	Get the next job to process and locks it for the worker.

	Only get's jobs where we have the video available locally.

	@param jobdir: Directory with jobs
	@param vdir: Directory with the videos
	@param wid: Worker ID
	"""

	log.debug("get_job(%s, %s, %s)" % (jobdir, vdir, wid))

	jobs = [j for j in os.listdir(pjoin(jobdir, "00_waiting")) if j.endswith(".txt")]

	videos = [os.path.splitext(v)[0] for v in os.listdir(vdir)]

	# Sanity check for video filename

	log.debug("videos: %s" % videos)
	log.debug("jobs: %s" % jobs)

	# Relevant jobs, jobs where we have the video locally
	rel_jobs = [j for j in jobs if j.split('_')[0] in videos]

	log.debug("Relevant jobs: %s" % rel_jobs)

	job = random.choice(rel_jobs)

	log.debug("Selected job: %s" % job) 

	wjob = "%s.%s" % (wid, job)

	src = pjoin(jobdir, job)
	dst = pjoin(jobdir, "01_running", wjob)

	log.debug("MOVING: %s to %s" % (src, dst))

	# shutil.move(src, dst)

	log.debug("Waiting if someone else wants this job..")

	# time.sleep(1)

	job_workers = [j.split(".")[0] for j in os.listdir(pjoin(jobdir, "01_running")) if job in j]

	print(job_workers)

	assert(len(job_workers) > 0 and (wid in job_workers))

	if len(job_workers) == 1:
		return wjob
	else:

		log.warning("Conflicting workers for job %s! Workers: %s " % (job, job_workers))

		me_idx = sorted(job_workers).index(wid)

		if me_idx == 0:
			log.info("I am index %d, taking the job!" % me_idx)

			return wjob
		else:
			log.info("I am index %d, giving up on the job" % me_idx)

			log.debug("Removing %s again." % dst)
			os.remove(dst)

			return None


def process_job(jobdir, tmpdir, viddir, resultdir, container, job, wid):
	"""
	Processes a job with the docker container.

	"""

	abs_job = pjoin(jobdir, "01_running", job)

	log.info("Processing %s" % abs_job)

	with open(abs_job) as f:
		j = json.load(f)

	log.debug("Job: %s" % j)

	rdir = pjoin(resultdir, os.path.splitext(job)[0])
	tdir = pjoin(tmpdir, os.path.splitext(job)[0])

	os.makedirs(rdir, exist_ok=True)
	os.makedirs(tdir, exist_ok=True)

	_docker_run(tdir, viddir, rdir, container,
		    j["video_id"], j["crf_value"], j["key_int_min"], j["key_int_max"], j["target_seq_length"])

def _docker_run(tmpdir, viddir, resultdir, container, video_id, crf_value, key_int_min, key_int_max, target_seq_length):

	log.info("... docker run ...")

	cmd = ["docker", "run", "--rm", 
               "-v", "\"%s:/videos\"" % os.path.abspath(viddir), 
	       "-v", "\"%s:/tmpdir\"" % os.path.abspath(tmpdir), 
	       "-v", "\"%s:/results\"" % os.path.abspath(resultdir), 
               container, 
               video_id, str(crf_value), str(key_int_min), str(key_int_max), str(target_seq_length)]

	log.debug("RUN: %s" % " ".join(cmd))


if __name__ == "__main__":

	logconf = {'format': '[%(asctime)s.%(msecs)-3d: %(name)-16s - %(levelname)-5s] %(message)s', 'datefmt': "%H:%M:%S"}
	logging.basicConfig(level=logging.DEBUG, **logconf)

	import argparse
	parser = argparse.ArgumentParser(description="Encoding worker.")
	parser.add_argument('-j', '--jobdir', help="Jobs folder.", default="samples/jobs/")
	parser.add_argument('-v', '--viddir', help="Video folder.", default="samples/videos")
	parser.add_argument('-t', '--tmpdir', help="Temporary folder.", default="samples/tmpdir")
	parser.add_argument('-r', '--resultdir', help="Results folder.", default="samples/results")
	parser.add_argument('-c', '--container', help="Container to use.", default="csieber/encoding:latest")
	parser.add_argument('-i', '--id', help="Worker identifier.", default="w1")

	args = parser.parse_args()

	log.info("Starting worker.")

	# Sanity check for video filename
	if any(["_" in v for v in os.listdir(args.viddir)]):
		log.error("Sanity check failed: A video contains '_' in the filename! This is not allowed!")
		sys.exit(-1)

	job = get_and_lock_job(args.jobdir, args.viddir, args.id)

	if job:
		process_job(args.jobdir, args.tmpdir, args.viddir, args.resultdir, args.container, job, args.id)


