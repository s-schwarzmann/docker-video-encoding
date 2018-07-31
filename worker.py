import os
import sys
import shutil
import logging
import random
from os.path import join as pjoin

log = logging.getLogger(__name__)

def get_job(jobdir, rundir, vdir, wid):
	"""
	Get the next job to process and locks it for the worker.

	Only get's jobs where we have the video available locally.

	@param jobdir: Directory with jobs
	@param rundir: Directory with running jobs
	@param vdir: Directory with the videos
	@param wid: Worker ID
	"""

	log.debug("get_job(%s, %s, %s, %s)" % (jobdir, rundir, vdir, wid))

	jobs = os.listdir(jobdir)

	videos = [os.path.splitext(v)[0] for v in os.listdir(vdir)]

	# Sanity check for video filename

	log.debug("videos: %s" % videos)
	log.debug("jobs: %s" % jobs)

	# Relevant jobs, jobs where we have the video locally
	rel_jobs = [j for j in jobs if j.split('_')[0] in videos]

	log.debug("Relevant jobs: %s" % rel_jobs)

	job = random.choice(rel_jobs)

	log.debug("Selected job: %s" % job) 

	src = pjoin(jobdir, job)
	dst = pjoin(rundir, "%s.%s" % (wid, job))

	log.debug("MOVING: %s to %s" % (src, dst))

	# shutil.move(src, dst)

	

if __name__ == "__main__":

	logconf = {'format': '[%(asctime)s.%(msecs)-3d: %(name)-16s - %(levelname)-5s] %(message)s', 'datefmt': "%H:%M:%S"}
	logging.basicConfig(level=logging.DEBUG, **logconf)

	import argparse
	parser = argparse.ArgumentParser(description="Encoding worker.")
	parser.add_argument('-j', '--jobdir', help="Jobs folder.", default="samples/jobs/")
	parser.add_argument('-r', '--rundir', help="Running jobs folder.", default="samples/jobs_running/")
	parser.add_argument('-d', '--donedir', help="Finished jobs folder.", default="samples/jobs_done/")
	parser.add_argument('-v', '--viddir', help="Video folder.", default="samples/videos")
	parser.add_argument('-i', '--id', help="Worker identifier.", default="w1")

	args = parser.parse_args()

	log.info("Starting worker.")

	# Sanity check for video filename
	if any(["_" in v for v in os.listdir(args.viddir)]):
		log.error("Sanity check failed: A video contains '_' in the filename! This is not allowed!")
		sys.exit(-1)

	job = get_job(args.jobdir, args.rundir, args.viddir, args.id)

