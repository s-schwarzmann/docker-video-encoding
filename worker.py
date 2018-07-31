import os
import sys
import shutil
import logging
import random
import time
from os.path import join as pjoin

log = logging.getLogger(__name__)

def get_and_lock_job(jobdir, rundir, vdir, wid):
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

	wjob = "%s.%s" % (wid, job)

	src = pjoin(jobdir, job)
	dst = pjoin(rundir, wjob)

	log.debug("MOVING: %s to %s" % (src, dst))

	# shutil.move(src, dst)

	log.debug("Waiting if someone else wants this job..")

	time.sleep(1)

	job_workers = [j.split(".")[0] for j in os.listdir(rundir) if job in j]

	log.warning("Conflicting workers for job %s! Workers: %s " % (job, job_workers))

	me_idx = sorted(job_workers).index(wid)

	if me_idx == 0:
		log.info("I am index %d, taking the job!" % me_idx)

		return wjob
	else:
		log.info("I am index %d, giving up on the job" % me_idx)

		log.debug("Removing %s again." % dst)
		os.remove(jf)

		return None


def process_job(rundir, donedir, viddir, job, wid):
	"""
	Processes a job with the docker container.

	"""

	abs_job = pjoin(rundir, job)

	log.info("Processing %s" % abs_job) 

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

	job = get_and_lock_job(args.jobdir, args.rundir, args.viddir, args.id)

	if job:
		process_job(args.rundir, args.donedir, args.viddir, job, args.id)


