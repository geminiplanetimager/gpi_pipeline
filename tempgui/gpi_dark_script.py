#!/usr/bin/env python

import os,sys
import re
import subprocess
import glob
import datetime
import time


def runcmd(cmdstring, **kwargs):
    print(">    " +cmdstring)
#    return
    sys.stdout.flush()   #make sure to flush output before starting subproc.
    p = subprocess.Popen(cmdstring, shell=True, stdout=subprocess.PIPE)
    stdout, stderr = p.communicate()
    print stdout



def checkGMB_camReady():
    """ Check the GMB and return the ifs.observation.cameraReady flag.
    Returns 1 if ready, 0 if not. 
    """

    cmd = '$TLC_ROOT/bin/linux64/gpUtGmbReadVal -sim -connectAs IFS -name ifs.observation.exposureInProgress'

    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = p.communicate()
    r = re.search(' = <([0-1])>',stdout)
    if r is not None:
        return 1-int(r.group(1))
    else:
        return  0 

def configureDetector( time, mode, nreads):
    runcmd('gpIfDetector_tester localhost configureExposure 0 %d %d %d 1' % (time*1000000., mode, nreads))

def takeExposure(counter=0):
    today = datetime.date.today()
    datestr = "%02d%02d%02d" % (today.year%100, today.month,today.day)

    outpath = "Y:\\\\%s\\darktests_%04d.fits" % (datestr, counter)

    while not checkGMB_camReady():
        print "waiting for camera to be ready"
        time.sleep(1)

    runcmd('gpIfDetector_tester localhost startExposure "%s" 0' % outpath)

    while not checkGMB_camReady():
        print "waiting for camera to finish exposing"
        time.sleep(5)

    print "waiting 30 s for FITS writing to finish"
    time.sleep(30)

if __name__ == "__main__":

    exptimes = [2,60,60,60,60,600,600,600]
    modes =    [2,2, 3,  3, 3,  3,  3,  3]
    reads =    [2, 2, 4, 8, 16, 4, 16, 64]
    nexp  =    [10,10,10,10,10, 5,  5,  5]



    counter=100
    for (e,m,r,n) in zip(exptimes, modes, reads, nexp):
        print (e, m, r)
        configureDetector(e,m,r)
        for i in range(n):
            counter += 1
            takeExposure( counter)
    



