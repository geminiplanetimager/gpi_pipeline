#!/usr/bin/env python

import os,sys
import subprocess
import datetime
import time
import re




class IFSController(object):
    """ A class to implement an interface to the IFS, with appropriate checking and waiting etc. 
    
Public commands:
    initialize()            initializes the detector server & hardware
    configureDetector(time_in_s, mode, nreads, ncoadds)
    takeExposure(filename)  
    moveMotor(axis, position)
    abortExposure()         aborts
    is_exposing()           returns True or False, as appropriate
    
    """
    def __init__(self, parent=None):
        self.parent=parent 

        self.testMode = False  # should we just print commands without actually executing them?
        self.writeall = True # are we writing ALL reads to disk? (does extra waiting if true)

        self.datestr=None
        self._check_datedir()


    #--- class internal private commands follow ----

    def _check_datedir(self):
        """ Check the current YYMMDD output directory. Create it if necessary."""
        today = datetime.date.today()
        datestr = "%02d%02d%02d" % (today.year%100, today.month,today.day)
        if datestr != self.datestr:
            self._log("New date - Updating date directory")
            self.datestr = datestr
            self.datadir = '/net/hydrogen/data/projects/gpi/Detector/TestData'+os.sep+datestr
            if not os.path.isdir(self.datadir):
                self._log("Creating directory "+self.datadir)
                try:
                    os.mkdir(self.datadir)
                    os.chmod(self.datadir, 0755)
                except:
                    self._log("Could not create directory "+self.datadir)

    def _log(self,message,nonewline=False):
        """ Log a string, either by printing or by calling a higher level log function """
        if self.parent is not None:
            self.parent.log(message,nonewline=nonewline)
        else:
            print(message)

    def _dot(self):
        """ print a dot."""
        if self.parent is not None:
            self.parent.log(".",nonewline=True)
        else:
            print ".",




    def _runcmd(self, cmdstring):
        """ Execute a command. Log the command and its returned results. """
        self._log(">    " +cmdstring)
        if self.testMode: return  # don't actually do anything

        sys.stdout.flush()   #make sure to flush output before starting subproc.
        p = subprocess.Popen(cmdstring, shell=True, stdout=subprocess.PIPE)
        stdout, stderr = p.communicate()
        self._log(stdout)

    def _checkGMB(self, var='ifs.observation.exposureInProgress'):
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

    def _checkGMB_camReady(self):
        return self._checkGMB('ifs.observation.cameraReady')

    def _checkGMB_expInProgress(self):
        return self._checkGMB('ifs.observation.exposureInProgress')

    def _wait(self, sleeptime=1):
        """ wait, while keeping the parent GUI alive if necessary """
        for i in range(sleeptime*1):
            time.sleep(1)
            if self.parent is not None:
                self.parent.root.update_idletasks()
    #--- public interface commands follow ----

    def is_exposing(self):
        return self._checkGMB_expInProgress()

    def configureDetector(self, time, mode, nreads, coadds=1):
        self._log( "Configuring for %d %d %d %d" % (int(time*1000000.), mode, nreads, coadds)) 
        self._runcmd('gpIfDetector_tester localhost configureExposure 0 %d %d %d %d' % (int(time*1000000.), mode, nreads, coadds))

    def takeExposure(self, filename='test0001'):
        self._check_datedir()

        outpath = "Y:\\\\%s\\%s.fits" % (self.datestr, filename)

        if self._checkGMB_expInProgress():
            self._log("waiting for camera to be ready",nonewline=True)
            while self._checkGMB_expInProgress():
                self._wait(1)
                self._dot()
            self._log("") # add newline after dots.

        self._runcmd('gpIfDetector_tester localhost startExposure "%s" 0' % outpath)
        self._wait(1)# wait for exposure to start before checking

        if self._checkGMB_expInProgress():
            self._log("waiting for camera to finish exposing")
            while self._checkGMB_expInProgress():
                self._wait(1)
                self._dot()
            self._log("") # add newline after dots.

        if self.writeall:
            self._log("waiting 30 s for FITS writing to finish",nonewline=True)
            for i in range(30):
                self._wait(1)
                self._dot()

#            self._wait(10)
#            self._log("waiting 20 s for FITS writing to finish")
#            self._wait(10)
#            self._log("waiting 10 s for FITS writing to finish")
#            self._wait(10)

        self._log("Exposure complete!")

    def abortExposure(self):
        self._runcmd('gpIfDetector_tester localhost abortExposure 0' % outpath)

    def initialize(self):
        #self._runcmd('startDetectorServerWindow &') # no, don't do this one
        self._runcmd('gpIfDetector_tester localhost initializeServer $IFS_ROOT/config/gpIFDetector_cooldown08.cfg')
        self._runcmd('gpIfDetector_tester localhost initializeHardware')
        self._log("Waiting 15 s for hardware to initialize")
        self._wait(15)
        self._log("Initialization complete.")

    def moveMotor(self,axis,position):
        self._runcmd('$TLC_ROOT/scripts/gpMcdMove.csh 1 $MACHINE_NAME %d %d' % (int(axis), int(position)) ) 
