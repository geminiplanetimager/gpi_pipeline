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

    exptimes = [2,60,60,60,60,600,600,600]
    modes =    [2,2, 3,  3, 3,  3,  3,  3]
    reads =    [2, 2, 4, 8, 16, 4, 16, 64]
    nexp  =    [10,10,10,10,10, 5,  5,  5]


    counter=100
    for (e,m,r,n) in zip(exptimes, modes, reads, nexp):
        print (e, m, r)
        IFSCont.configureDetector(e,m,r)
        for i in range(n):
            counter += 1
            IFSCont.takeExposure( "darktests2_%04d" % (counter,) )



