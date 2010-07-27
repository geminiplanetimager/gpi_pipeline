#!/usr/bin/env python

import os,sys
import subprocess
import datetime
import time
import re
import pyfits
import numpy
import glob

import pylab as p
from idlcompat import idllib


TESTMODE = True

def smooth(x,window_len=11,window='hanning'):
    """smooth the data using a window with requested size.
    (from http://www.scipy.org/Cookbook/SignalSmooth )
    
    This method is based on the convolution of a scaled window with the signal.
    The signal is prepared by introducing reflected copies of the signal 
    (with the window size) in both ends so that transient parts are minimized
    in the begining and end part of the output signal.
    
    input:
        x: the input signal 
        window_len: the dimension of the smoothing window; should be an odd integer
        window: the type of window from 'flat', 'hanning', 'hamming', 'bartlett', 'blackman'
            flat window will produce a moving average smoothing.

    output:
        the smoothed signal
        
    example:

    t=linspace(-2,2,0.1)
    x=sin(t)+randn(len(t))*0.1
    y=smooth(x)
    
    see also: 
    
    numpy.hanning, numpy.hamming, numpy.bartlett, numpy.blackman, numpy.convolve
    scipy.signal.lfilter
 
    TODO: the window parameter could be the window itself if an array instead of a string   
    """

    if x.ndim != 1:
        raise ValueError, "smooth only accepts 1 dimension arrays."

    if x.size < window_len:
        raise ValueError, "Input vector needs to be bigger than window size."


    if window_len<3:
        return x


    if not window in ['flat', 'hanning', 'hamming', 'bartlett', 'blackman']:
        raise ValueError, "Window is on of 'flat', 'hanning', 'hamming', 'bartlett', 'blackman'"


    s=numpy.r_[2*x[0]-x[window_len:1:-1],x,2*x[-1]-x[-1:-window_len:-1]]
    #print(len(s))
    if window == 'flat': #moving average
        w=ones(window_len,'d')
    else:
        w=eval('numpy.'+window+'(window_len)')

    y=numpy.convolve(w/w.sum(),s,mode='same')
    return y[window_len-1:-window_len+1]


def rebin( a, newshape ):
        '''Rebin an array to a new shape.
        (from http://www.scipy.org/Cookbook/Rebinning )
        '''
        assert len(a.shape) == len(newshape)
        slices = [ slice(0,old, float(old)/new) for old,new in zip(a.shape,newshape) ]
        coordinates = numpy.mgrid[slices]
        indices = coordinates.astype('i')   #choose the biggest smaller integer index
        return a[tuple(indices)]


def refBiasSub(filename, slope=False):
    """ 
    Apply bias subtraction based on reference pixels for a H2RG

    Args:
       filename (str): the filename to process

    Kwargs:
       slope (bool):   allow the column fits to vary between top and bottom?
    """
    fits = pyfits.open(filename)
    if 'BIASSUB' not in fits[0].header.keys():

        #TODO check for subarray images, and if so, give up on ref pixel sub.

        fits[0].header.update('BIASSUB','Yes', 'Reference Pixel Subtraction Done')
        fits[0].header.add_history('Reference pixel bias values subtracted by gpiifs.py')

        top = fits[0].data[-4:, :].mean(0)
        bot = fits[0].data[0:4, :].mean(0)
        top.shape = (32, 64) 
        bot.shape = (32, 64) 
        mt = top.mean(1)
        mb = bot.mean(1)
        if slope:
            print "Slope mode not yet implemented!"
        else:
            chanmeans = (mt+mb)/2
            chanmeans.shape = (32,1)
            chanmeans2 = rebin(chanmeans, (32,64))
            chanmeans2.shape = (1,2048)


        left = fits[0].data[:, 0:4].mean(1)
        right= fits[0].data[:, -4:].mean(1)
        rowmeans = (left+right)/2
        rowmeans2 = smooth(rowmeans, window_len=7)
        rowmeans2.shape = (2048,1)


        z = numpy.zeros_like(fits[0].data)
        z += chanmeans2
        fn = filename[0:-5]+"_chans.fits"
        pyfits.HDUList(pyfits.PrimaryHDU(z)).writeto(fn, clobber=True)
        z = numpy.zeros_like(fits[0].data)
        #z -= chanmeans2
        z += rowmeans2
        fn = filename[0:-5]+"_rows.fits"
        pyfits.HDUList(pyfits.PrimaryHDU(z)).writeto(fn, clobber=True)
        z += chanmeans2

        return fits[0].data, z


def testRefSub(filename):
    data, bias = refBiasSub(filename)

    p.subplot(131)
    p.imshow( idllib.alogscale(data, 0, 2000) )
    p.title(filename)
    p.subplot(132)
    p.imshow( idllib.alogscale(bias, 0, 2000) )
    p.title("Bias")
    p.subplot(133)
    p.imshow( idllib.alogscale(data-bias, 0, 2000) )
    p.title("Subtracted")

    fn = filename[0:-5]+"_bs.fits"

    pyfits.HDUList(pyfits.PrimaryHDU(data-bias)).writeto(fn, clobber=True)




class IFSHeaderFixer(object):
    def __init__(self, parent=None):
        self.keywords=[]
        self.values={}
        self.comments={}

        self.parent = parent

    def _log(self,message,nonewline=False):
        """ Log a string, either by printing or by calling a higher level log function """
        if self.parent is not None:
            self.parent._log(message,nonewline=nonewline)
        else:
            print(message)

    def updateKeyword(self, keyword, value, comment=None):

        self.values[keyword] = value
        self.comments[keyword] = comment

        # keep track of order so they get added in order
        if not keyword in self.keywords:
            self.keywords.append(keyword)

    def updateHeader(self, fitsfile):
#       # need to watch out for network latency/long compute times meaning that
#       # the files are not fully written yet. In that case, wait for the write to finish.
        size = os.path.getsize(filename)
        while ((size != 8392320 ) & (size != 16784640)):
            self.log('file %s not fully written to disk yet - waiting.' % filename)
            return False

        try:
            f= pyfits.open(fitsfile, mode='update')
            if 'TARGET' not in f[0].header.keys():  # check if it's already been updated
                for k in self.keywords:
                    f[0].header.update(k, self.values[k], self.comments[k])
                f[0].header.add_history(' Header keywords updated by gpiifs.py')
            f.close()
        except:
            return False

    def watchDirectory(self, directory):
        self.directory = directory
        self._log("Now watching directory %s for new FITS files." % (self.directory))
        curfitsset = set(glob.glob(self.directory+os.sep+"*.fits"))
        self.oldfitsset = curfitsset
        self._log("\tIgnoring %d already present FITS files." % len(curfitsset))

    def checkNewFiles(self):
        curfitsset = set(glob.glob(self.directory+os.sep+"*.fits"))
        newfiles = curfitsset - self.oldfitsset
        if len(newfiles) > 0:
            self._log("New FITS files!: "+ ' '.join(newfiles))
            for fn in newfiles: 
                if self.updateHeader(fn):
                    self.oldfitsset.add(fn)

def getDataDir():
    """ for use in GUI startup only"""
    if TESTMODE:
        basedir = '/Users/mperrin/data/GPI/'
    else:
        basedir = '/net/hydrogen/data/projects/gpi/'
    today = datetime.date.today()
    datestr = "%02d%02d%02d" % (today.year%100, today.month,today.day)
    datadir = basedir + 'Detector/TestData'+os.sep+datestr
    return datadir



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

        if TESTMODE:
            self.basedir = '/Users/mperrin/data/GPI/'
        else:
            self.basedir = '/net/hydrogen/data/projects/gpi/'

        self.HeaderFixer = IFSHeaderFixer(parent=self)
        self.PupilFixer = IFSHeaderFixer(parent=self)
        self.fixers = [self.HeaderFixer, self.PupilFixer]

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
            self.datadir = self.basedir + 'Detector/TestData'+os.sep+datestr
            self._makedir(self.datadir)
            self.pupildir = self.basedir + 'Pupil/TestData'+os.sep+datestr
            self._makedir(self.pupildir)
            self.HeaderFixer.watchDirectory(self.datadir)
            self.PupilFixer.watchDirectory(self.pupildir)

    def _makedir(self,dirname):
        if not os.path.isdir(dirname):
            self._log("Creating directory "+dirname)
            try:
                os.mkdir(dirname)
                os.chmod(dirname, 0755)
            except:
                self._log("Could not create directory "+dirname)

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

        cmd = '$TLC_ROOT/bin/linux64/gpUtGmbReadVal -sim -connectAs IFS -name '+var

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
        for f in self.fixers:
            f.updateKeyword("MOTOR%d" % int(axis), int(position), "Commanded position of motor %d" % int(axis))

    def updateKeyword(self, keyword, value, comment=None):
        if TESTMODE:
            print (keyword, value, comment)

        for f in self.fixers:
            f.updateKeyword(keyword,value,comment)

    def _checkGMB_PupilexpInProgress(self):
        return self._checkGMB('ifs.pupilviewing.exposureInProgress')

    def pupilExposure(self,filename='test0001',time=1,coadds=1):
        self._check_datedir()

        outpath = self.pupildir+os.sep+filename+".fits"

        self._runcmd('gpIfPupil_tester localhost startExposure "%s" "%s" "%s"' % (outpath,int(time*1000.),int(coadds)) )
        self._wait(1)# wait for exposure to start before checking

        while self._checkGMB_PupilexpInProgress():
            self._log("waiting for camera to finish exposing")
            self._wait(5)
 
        self._log("Pupil exposure complete!")

    def checkNewFiles(self):
        for f in self.fixers:
            f.checkNewFiles()


if __name__ == "__main__":
    os.chdir('/Users/mperrin/data/GPI/TestData/100722')
    testRefSub('darktests2_0114.fits')

