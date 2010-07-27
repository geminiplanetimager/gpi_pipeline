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

    exptimes = [600,600,600]
    modes =    [  3,  3,  3]
    reads =    [  4, 16, 64]
    nexp  =    [  3,  3,  3]


    counter=100
    for (e,m,r,n) in zip(exptimes, modes, reads, nexp):
        print (e, m, r)
        IFSCont.configureDetector(e,m,r)
        for i in range(n):
            counter += 1
            IFSCont.takeExposure( "darktests3_%04d" % (counter,) )



