import os
import sys
import shutil
import logging
import random
import json
import time
import subprocess
import re
from os.path import join as pjoin

log = logging.getLogger(__name__)

def get_and_lock_job(jobdir, vdir, wid, dryrun=False):
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

	if len(rel_jobs) == 0:
		log.info("No relevant jobs available for me!")
		return None

	job = random.choice(rel_jobs)

	log.debug("Selected job: %s" % job) 

	wjob = "%s.%s" % (wid, job)

	src = pjoin(jobdir, "00_waiting", job)
	dst = pjoin(jobdir, "01_running", wjob)

	log.debug("MOVING: %s to %s" % (src, dst))

	shutil.move(src, dst)

	log.debug("Waiting if someone else wants this job..")

	if not dryrun:
		time.sleep(40)

	job_workers = [j.split(".")[0] for j in os.listdir(pjoin(jobdir, "01_running")) if job in j]

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


def process_job(jobdir, tmpdir, viddir, resultdir, container, job, wid, dryrun=False):
	"""
	Processes a job with the docker container.

	@param jobdir: Job directory
	@param tmpdir: Temporary directory of the host to use
	@param viddir: Directory with the videos
	@param resultdir: Directory to put the results to
	@param container: Container to use for encoding
	@param job: The filename of the job to execute
	@param wid: The ID of the worker
	"""

	ts = int(time.time())

	abs_job = pjoin(jobdir, "01_running", job)

	log.info("Processing %s" % abs_job)

	with open(abs_job) as f:
		j = json.load(f)

	log.debug("Job: %s" % j)

	rdir = pjoin(resultdir, "%s.%d" % (os.path.splitext(job)[0], ts))
	tdir = pjoin(tmpdir, "%s.%d" % (os.path.splitext(job)[0], ts))

	os.makedirs(rdir, exist_ok=True)
	os.makedirs(tdir, exist_ok=True)

	ret = _docker_run(tdir, viddir, rdir, container,
	                  j["video_id"], j["crf_value"], j["key_int_min"], j["key_int_max"], j["target_seq_length"],
			  dryrun=dryrun)

	if ret:
		dst = pjoin(jobdir, "02_done", job.split(".", 1)[1])

		log.debug("Moving %s to %s." % (abs_job, dst))

		shutil.move(abs_job, dst)
	else:
		log.error("Encoding job failed !!")

		dst = pjoin(jobdir, "99_failed", "%s.%d" % (job, ts))

		log.debug("Moving %s to %s." % (abs_job, dst))

		shutil.move(abs_job, dst)

	return ret

def _docker_run(tmpdir, viddir, resultdir, container, video_id, crf_value, key_int_min, key_int_max, target_seq_length, dryrun=False):

	t = time.perf_counter()

	cmd = ["docker", "run", "--rm", 
	       "--user" , "1000:1000",
               "-v", "\"%s:/videos\"" % os.path.abspath(viddir), 
	       "-v", "\"%s:/tmpdir\"" % os.path.abspath(tmpdir), 
	       "-v", "\"%s:/results\"" % os.path.abspath(resultdir), 
               container,
               video_id, str(crf_value), str(key_int_min), str(key_int_max), str(target_seq_length)]

	log.debug("RUN: %s" % " ".join(cmd))

	if not dryrun:

		try:
			with open(pjoin(resultdir, "docker_run_stdout.log"), "wt") as fout, \
		             open(pjoin(resultdir, "docker_run_stderr.log"), "wt") as ferr:

				ret = subprocess.check_call(cmd, stderr=ferr, stdout=fout)

				print(ret)

		except subprocess.CalledProcessError:
			log.error("Docker run failed !!")
			log.error("Check the logs in the resultdir for details.")
			return False

	else:
		log.warning("Dryrun selected. Not starting docker container!")
		
	log.debug("RUN: %s" % " ".join(cmd))

	dur = time.perf_counter() - t

	log.info("Encoding duration: %.1fs" % dur)

	stats = {'encoding_duration': dur,
		 'docker_cmd': " ".join(cmd)}

	with open(pjoin(resultdir, "stats.json"), "w") as f:
		json.dump(stats, f, indent=4, sort_keys=True)

	return True


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
	parser.add_argument('-o', '--one-job', help="Run only one job and quit.", action="store", default=False)
	parser.add_argument('-d', '--dry-run', help="Dry-run. Do not run docker.", action="store", default=True)
	parser.add_argument('-i', '--id', help="Worker identifier.", default="w1")

	args = parser.parse_args()

	log.info("Starting worker.")

	# Sanity check for video filename
	if any(["_" in v for v in os.listdir(args.viddir)]):
		log.error("Sanity check failed: A video contains '_' in the filename! This is not allowed!")
		sys.exit(-1)

	# Sanity check for worker ID
	if not re.match('^[a-zA-Z0-9]+$', args.id):
		log.error("Worker ID is only allowed to contain numbers and letters.") 
		sys.exit(-1)

	# Make sure the directories exist
	for d in [args.tmpdir, args.viddir, args.resultdir]:
		os.makedirs(d, exist_ok=True)

	# Make sure job directories exist.
	for d in ["00_waiting", "01_running", "02_done", "99_failed"]:
		os.makedirs(pjoin(args.jobdir, d), exist_ok=True)

	if args.dry_run:
		log.warning("This is a DRY-RUN. I am not running docker.")

	running = True

	while running:
		
		try:
			if not args.dry_run:
				time.sleep(random.randint(3, 12))

			job = get_and_lock_job(args.jobdir, args.viddir, args.id, 
                                               dryrun=args.dry_run)
	
			if job:
				process_job(args.jobdir, args.tmpdir, args.viddir, 
                                            args.resultdir, args.container, job, 
                                            args.id, dryrun=args.dry_run)

		except KeyboardInterrupt:

			log.warning("Received keyboard interrupt. Quitting after current job.")
			running = False

		if args.one_job or args.dry_run:
			log.warning("One job only option is set. Exiting loop.")
			running = False

	log.info("Quitting worker %s." % args.id)

