#!/usr/bin/env python

import os,sys
import re
import subprocess
import glob
import datetime
import time

import gpiifs


if __name__ == "__main__":

    IFSCont = gpiifs.IFSController()

    exptimes = 1
#    modes =    [2,2, 3,  3, 3,  3,  3,  3]
#    reads =    [2, 2, 4, 8, 16, 4, 16, 64]
#    nexp  =    [10,10,10,10,10, 5,  5,  5]
    lyot     = []
    mirror   = []
#    filter   =
#    prism    =

    counter=0
    for l in lyot:
        print (l)
#        IFSCont.configureDetector(e,m,r)
#        for i in range(n):
#            counter += 1
#            IFSCont.takeExposure( "darktests2_%04d" % (counter,) )
        IFSCont.moveMotor(1,l)
        IFSCont.moveMotor(1,0)
        IFSCont.moveMotor(2,-300)
        counter += 1
        IFSCont.pupilExposure("Pupil_repeatability_lyot_%04d" %(counter),exptime)
        IFSCont._wait(30)
    for i in range(10):
        print (i)
        IFSCont.moveMotor(1,0)
        IFSCont.moveMotor(2,3400)
        counter +=1
        IFSCont.pupilExposure("Pupil_repeatability_mirror_%04d" %(counter),exptime)
        IFSCont._wait(30)
    
