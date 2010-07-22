#!/usr/bin/env python

import os,sys
import subprocess
import datetime
import time
import re




class IFSController(object):
    """ A class to implement an interface to the IFS, with appropriate checking and waiting etc. """
    def __init__(self, parent=None):
        self.parent=parent 


        self.datestr=None
        self._check_datedir()


    def _check_datedir(self):
        """ Check the current YYMMDD output directory. Create it if necessary."""
        today = datetime.date.today()
        datestr = "%02d%02d%02d" % (today.year%100, today.month,today.day)
        if datestr != self.datestr:
            self.log("New date - Updating date directory")
            self.datestr = datestr
            self.datadir = '/net/hydrogen/data/projects/gpi/Detector/TestData'+os.sep+datestr
            if not os.path.isdir(self.datadir):
                self.log("Creating directory "+self.datadir)
                try:
                    os.mkdir(self.datadir)
                    os.chmod(self.datadir, 0755)
                except:
                    self.log("Could not create directory "+self.datadir)

    def log(self,message):
        """ Log a string, either by printing or by calling a higher level log function """
        if self.parent is not None:
            self.parent.log(message)
        else:
            print(message)

    def runcmd(self, cmdstring):
        """ Execute a command. Log the command and its returned results. """
        self.log(">    " +cmdstring)
        sys.stdout.flush()   #make sure to flush output before starting subproc.
        p = subprocess.Popen(cmdstring, shell=True, stdout=subprocess.PIPE)
        stdout, stderr = p.communicate()
        self.log(stdout)

    def configureDetector(self, time, mode, nreads, coadds=1):
        self.log( "Configuring for %d %d %d %d" % (int(time*1000000.), mode, nreads, coadds)) 
        self.runcmd('gpIfDetector_tester localhost configureExposure 0 %d %d %d %d' % (int(time*1000000.), mode, nreads, coadds))


    def checkGMB(self, var='ifs.observation.exposureInProgress'):
        """ Check the GMB and return the ifs.observation.cameraReady flag.
        Returns 1 if ready, 0 if not. 
        """

        cmd = '$TLC_ROOT/bin/linux64/gpUtGmbReadVal -sim -connectAs IFS -name ifs.observation.exposureInProgress'

        p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = p.communicate()
        r = re.search(' = <([0-1])>',stdout)
        if r is not None:
            return int(r.group(1))
        else:
            return  0

    def checkGMB_camReady(self):
        return self.checkGMB('ifs.observation.cameraReady')

    def checkGMB_expInProgress(self):
        return self.checkGMB('ifs.observation.exposureInProgress')

    def is_exposing(self):
        return self.checkGMB_expInProgress()

    def takeExposure(self, filename='test0001'):
        self._check_datedir()

        outpath = "Y:\\\\%s\\%s.fits" % (self.datestr, filename)

        while self.checkGMB_expInProgress():
            self.log("waiting for camera to be ready")
            time.sleep(1)

        self.runcmd('gpIfDetector_tester localhost startExposure "%s" 0' % outpath)
        time.sleep(1) # wait for exposure to start before checking

        while self.checkGMB_expInProgress():
            self.log("waiting for camera to finish exposing")
            time.sleep(5)

        self.log("waiting 30 s for FITS writing to finish")
        if parent is None:
            time.sleep(30)
        else: # keep the GUI alive while waiting
            for i in range(300):
                time.sleep(0.1)
                parent.root.update_idletasks()

    def abort(self):
        self.log("Abort is not implemented yet!")

    def initialize(self):
        #self.runcmd('startDetectorServerWindow &') # no, don't do this one
        self.runcmd('gpIfDetector_tester localhost initializeServer $IFS_ROOT/config/gpIFDetector_cooldown08.cfg')
        self.runcmd('gpIfDetector_tester localhost initializeHardware')

    def moveMotor(self,axis,position):
        self.runcmd('$TLC_ROOT/scripts/gpMcdMove.csh 1 $MACHINE_NAME %d %d' % (int(axis), int(position)) 
