import os
import logging

log = logging.getLogger(__name__)

def get_job(jobdir, vdir, wid):
	"""
	Get the next job to process.

	Only get's jobs where we have the video available locally.

	@param jobdir: Directory with jobs
	@param vdir: Directory with the videos
	@param wid: Worker ID
	"""

	log.debug("get_job(%s, %s, %s)" % (jobdir, vdir, wid))

	jobs = os.listdir(jobdir)

	videos = os.listdir(vdir)

	print(jobs)	
	

if __name__ == "__main__":

	logconf = {'format': '[%(asctime)s.%(msecs)-3d: %(name)-16s - %(levelname)-5s] %(message)s', 'datefmt': "%H:%M:%S"}
	logging.basicConfig(level=logging.DEBUG, **logconf)

	import argparse
	parser = argparse.ArgumentParser(description="Encoding worker.")
	parser.add_argument('-j', '--jobdir', help="Job folder.", default="webdav/jobs/")
	parser.add_argument('-v', '--viddir', help="Video folder.", default="webdav/videos")
	parser.add_argument('-i', '--id', help="Worker identifier.", default="w1")

	args = parser.parse_args()

	log.info("Starting worker.")

	job = get_job(args.jobdir, args.viddir, args.id)

