import os
import sys
import logging
import random
import json
import time
import subprocess
import re
import traceback
import shutil
from functools import partial
from os.path import join as pjoin
from dirjobs import DirJobs

log = logging.getLogger(__name__)


def process_job(job, wargs, dryrun=False):
    """
    Processes a job with the docker container.

    @param job: The job to process
    @param wargs: Arguments for the worker (container)
    """

    ts = int(time.time())

    stats = {'ts': ts,
             'job': job.name(),
             'job.path': job.path()}

    stats.update(wargs)

    log.info("Processing %s" % job)

    try:
        with open(job.path()) as f:
            j = json.load(f)

        stats['job_dict'] = j

        log.debug("Job: %s" % j)

        d = "%d.%s.%s" % (ts, wargs['id'], job.name_woext())
        rdir = pjoin(wargs['resultdir'], d)
        tdir = pjoin(wargs['tmpdir'], d)

        os.makedirs(rdir, exist_ok=True)
        os.makedirs(tdir, exist_ok=True)

        t = time.perf_counter()

        ret = _docker_run(stats, tdir, wargs['viddir'], rdir, wargs['container'],
                          j["video"], j["crf"], j["min_length"],
                          j["max_length"], j["target_seg_length"],
                          j["encoder"],
                  dryrun=dryrun, processor=wargs['processor'])

        dur = time.perf_counter() - t
        stats['encoding_duration'] = dur

        log.info("Encoding duration: %.1fs" % dur)

    except:
        print(traceback.format_exc())
        log.critical("Failed to process job!")
        return False

    with open(pjoin(rdir, "stats.json"), "w") as f:
        json.dump(stats, f, indent=4, sort_keys=True)

    log.debug("Deleting %s" % tdir)
    shutil.rmtree(tdir)

    return ret


def _docker_run(stats, tmpdir, viddir, resultdir, container,
                video_id, crf_value, key_int_min, key_int_max, target_seg_length, encoder,
                dryrun=False, processor=None):

    docker_opts = ["--rm",
                   "--user" , "%d:%d" % (os.geteuid(), os.getegid()),
                   "-v", "%s:/videos" % os.path.abspath(viddir),
                   "-v", "%s:/tmpdir" % os.path.abspath(tmpdir),
                   "-v", "%s:/results" % os.path.abspath(resultdir)]

    if processor:
        docker_opts += ["--cpuset-cpus=%s" % processor]

    docker_opts += [container]

    cmd = ["docker", "run"] + docker_opts + \
          [video_id, str(crf_value), str(key_int_min), str(key_int_max), str(target_seg_length), encoder]

    log.debug("RUN: %s" % " ".join(cmd))

    if not dryrun:

        try:
            with open(pjoin(resultdir, "docker_run_stdout.txt"), "wt") as fout, \
                 open(pjoin(resultdir, "docker_run_stderr.txt"), "wt") as ferr:

                ret = subprocess.check_call(cmd, stderr=ferr, stdout=fout)

                print(ret)

        except subprocess.CalledProcessError:
            log.error("Docker run failed !!")
            log.error("Check the logs in %s for details." % resultdir)
            return False

    else:
        log.warning("Dryrun selected. Not starting docker container!")

    stats['docker_cmd'] = " ".join(cmd)

    return True

def worker_loop(args):

    videos = [os.path.splitext(v)[0] for v in os.listdir(args.viddir)]

    log.info("Available videos: %s" % videos)

    # Select only jobs where we have the video locally available
    def video_filter(videos, path, name):
        return name.split('_')[0] in videos

    dj = DirJobs(args.jobdir,
                 wid=args.id,
                 worker_sync=not args.dry_run,
                 sync_time=70,
                 job_filter=partial(video_filter, videos))

    running = True

    # Worker arguments
    fields = ['tmpdir', 'viddir', 'resultdir', 'container', 'id', 'processor']
    wargs =  {k: getattr(args, k) for k in fields}

    while running:

        try:
            job = dj.next_and_lock()

            if job:
                ret = process_job(job, wargs, dryrun=args.dry_run)

                if ret:
                    job.done()
                else:
                    log.error("Encoding job failed !!")
                    job.failed()
            else:
                pt = random.randint(30, 90)
                log.debug("No job found. Pausing for %d seconds." % pt)
                time.sleep(pt)

        except KeyboardInterrupt:

            log.warning("Received keyboard interrupt. Quitting after current job.")
            running = False

        if args.one_job or args.dry_run:
            log.warning("One job only option is set. Exiting loop.")
            running = False


if __name__ == "__main__":

    logconf = {'format': '[%(asctime)s.%(msecs)-3d: %(name)-16s - %(levelname)-5s] %(message)s', 'datefmt': "%H:%M:%S"}
    logging.basicConfig(level=logging.DEBUG, **logconf)

    import argparse
    parser = argparse.ArgumentParser(description="Encoding worker.")
    parser.add_argument('-j', '--jobdir', help="Jobs folder.", default="samples/jobs/")
    parser.add_argument('-v', '--viddir', help="Video folder.", default="samples/videos")
    parser.add_argument('-t', '--tmpdir', help="Temporary folder.", default="samples/tmpdir")
    parser.add_argument('-r', '--resultdir', help="Results folder.", default="samples/results")
    parser.add_argument('-c', '--container', help="Container to use.", default="fginet/encoding:latest")
    parser.add_argument('--one-job', help="Run only one job and quit.", action="store_true")
    parser.add_argument('--dry-run', help="Dry-run. Do not run docker.", action="store_true")
    parser.add_argument('-i', '--id', help="Worker identifier.", default="w1")
    parser.add_argument('-p', '--processor', help="Which CPU to use.", default=None)

    args = parser.parse_args()

    log.info("Starting worker %s." % args.id)

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

    jpath = pjoin(args.jobdir, "00_waiting")
    if not os.path.exists(jpath):
        log.critical("Path with the waiting jobs %s has to exist!" % jpath)
        sys.exit(-1)

    if args.dry_run:
        log.warning("This is a DRY-RUN. I am not running docker.")

    worker_loop(args)

    log.info("Quitting worker %s." % args.id)

