#!/usr/bin/env python
import os, sys
import Tkinter
import Tkinter as ttk
from Tkinter import N,E,S,W
import ScrolledText
import tkSimpleDialog
import tkFileDialog, tkMessageBox
import re
import subprocess
import glob
import pyfits
import datetime
import time

import logging


import gpiifs


#from IPython.Debugger import Tracer; stop = Tracer()



####################################



class GPIMechanism(object):
    """ a wrapper class for a mechanism. Called to create each mech part of the GUI """
    def __init__(self, root, parent, name, positions, axis=0, keyword="KEYWORD",**formatting):
        self.name = name
        self.axis=axis
        self.keyword=keyword

        self.frame = ttk.Frame(root, padx=2, pady=2) #padding=(10,10,10,10)) #, padx=10, pady=10)
        ttk.Label(self.frame,text=" "+self.name+": ", **formatting).grid(row=0,column=0)

        self.value=' -Unknown- '
        if positions is None:
            self.type='Continuous'
            self.entry = ttk.Entry(self.frame, width=8 , **formatting)
            self.entry.insert(0,'0')
            self.entry.grid(row=0,column=1)

        else:  # wheel or stage
            self.type='Discrete'
            self.positions = positions # this should be a hash of values
            self.pos_names = self.positions.keys()

            self.list=Tkinter.Listbox(self.frame, height=len(self.pos_names), **formatting)
            for s in self.pos_names:
                self.list.insert(Tkinter.END, s)
            self.list.grid(row=0,column=1)

        ttk.Button(self.frame, text="Move", command=self.move, **formatting).grid(row=0,column=2)
        ttk.Button(self.frame, text="Datum", command=self.datum, **formatting).grid(row=0,column=3)
        #ttk.Button(self.frame, text="Stop", command=self.stop, **formatting).grid(row=0,column=4)
        self.pos=ttk.Label(self.frame,text=self.value, **formatting)
        self.pos.grid(row=0,column=4)


        self.frame.grid_columnconfigure(0, minsize=100)
        self.frame.grid_columnconfigure(1, minsize=180)
 
        self.parent=parent

    def move(self):
        if self.type == 'Discrete':
            sel = self.list.curselection()
            if len(sel) == 0:
                self.parent.log( "Nothing selected!")
                return
            else:
                val = self.pos_names[int(self.list.curselection()[0])]

                pos = self.positions[val]
                self.parent.log( "MOVE! motor: %s \t position %d \titem: %s " % (self.name,pos, val))
                self.value=val
                self.pos.config(text="%10s" % (val))
        else:
            pos = int(self.entry.get())
            self.value = '%d' % pos
            self.pos.config(text="%10d" % (pos))
            self.parent.log("MOVE! motor: %s \tposition %d" % (self.name, pos))

        #self.parent.IFSController.runcmd('$TLC_ROOT/scripts/gpMcdMove.csh 1 $MACHINE_NAME %d %d' % (self.axis, pos) )
        self.parent.IFSController.moveMotor(self.axis, pos) 

    def datum(self):
        self.parent.IFSController.datumMotor(self.axis)

    def stop(self):
        self.parent.IFSController.abortMotor(self.axis)

    def init(self):
        self.parent.IFSController.initMotor(self.axis)

    def printkey(self):
        self.parent.log("%08s = '%s'" % (self.keyword, self.value))

    def updatekey(self):
        return (self.keyword, self.value)

####################################

class GPI_TempGUI(object):
    def __init__(self, logger=None):

        self.logger = None # needed so attribute is defined before creating IFSController

        self._make_widgets()
        self.last_image_fn=""
        self.last_pupil_fn=""

        self.oldfitsset=set([])


        self.datadir = gpiifs.getDataDir() 
        #self.datadir = self.IFSController.datadir 
        if not os.path.isdir(self.datadir):
            os.makedirs(self.datadir)
        os.chdir(self.datadir)

        self.file_logger=None
        self.logger = ViewLog(self.root, geometry='550x600+650+50',logpath=self.datadir)


        self.log('Starting the GPI IFS Temporary GUI')
        self.log('Informative log messages will appear in this window.')
        self.log("    Log written to file "+self.logger.filename)
        self.log(' ')


        self.IFSController = gpiifs.IFSController(parent=self)

        self._set_initial_filename()
        self._set_initial_pupil_filename()
        self.watchid=None
        self.watchDir(init=True)

        self.root.protocol("WM_DELETE_WINDOW", self.quit)
        self.root.update()

    def _initall(self):
        for m in self.motors:
            m.init()
    def _stopall(self):
        for m in self.motors:
            m.stop()


    def _make_widgets(self):
        self.root = Tkinter.Tk()
        self.root.title("GPITempGUI")
        self.root.geometry('+100+50')
        formatting = {"background": "#CCCCCC"}
        formatting={}
        frame = ttk.Frame(self.root, padx=10, pady=10) #padding=(10,10,10,10)) #, padx=10, pady=10)

        r=0
        ttk.Label(frame, text="GPI IFS Temporary GUI", font="Helvetica 20 bold italic",  **formatting).grid(row=r, columnspan=4)
        r=r+1

        #----
        mframe = ttk.LabelFrame(frame, text="Motors:", padx=2, pady=2, bd=2, relief=Tkinter.GROOVE) #padding=(10,10,10,10)) #, padx=10, pady=10)

        ttk.Label(mframe, justify=Tkinter.LEFT, text=" Click on desired position, then press MOVE. ", 
              **formatting).grid(row=0, columnspan=2, stick=W+E)
        ttk.Button(mframe,  text="Init All", command=self._initall, **formatting).grid(row=0,column=3)
        ttk.Button(mframe,  text="Stop All", command=self._stopall, **formatting).grid(row=0,column=4)

        self.motors=[]
        
        positions = {"Y": 800, "J":400, "H": 00, "K1":1200, "K2":1600}
        self.motors.append( GPIMechanism(mframe, self, "   Filter", positions, axis=3, keyword='FILTER', **formatting) )

        positions = {"Spectral": 9200, "Wollaston":00, "None": 4600}
        self.motors.append( GPIMechanism(mframe, self, "    Prism", positions, axis=4, keyword='PRISM', **formatting) )
        
        positions = {"Inserted": -300, "Removed":3400}
        self.motors.append(  GPIMechanism(mframe, self, "PupilCam", positions, axis=2, keyword='PUPILMIR', **formatting) )

        positions = {"L1": 00, "Dark":200}
        self.motors.append(  GPIMechanism(mframe, self, "%15s" % ("Lyot"), positions, axis=1, keyword='LYOT', **formatting) )

        self.motors.append(  GPIMechanism(mframe, self, "%15s" % ("Focus"), None, axis=5, keyword='FOCUS', **formatting) )
        
        for i in range(len(self.motors)):
            self.motors[i].frame.grid(row=i+1, columnspan=5, stick=W)

        mframe.grid(row=r,stick=E+W)
        r=r+1
        #----
        mframe = ttk.LabelFrame(frame, text="Header Keywords:", padx=2, pady=2, bd=2, relief=Tkinter.GROOVE) 

        mr=0
        ttk.Label(mframe,text="TARGET:",  **formatting).grid(row=mr,column=0, stick=W)
        self.entry_target = ttk.Entry(mframe, )
        self.entry_target.grid(row=mr,column=1,stick=N+E+S+W)
        mr=mr+1

        ttk.Label(mframe,text="COMMENTS:",  **formatting).grid(row=mr,column=0, stick=W)
        self.entry_comment = ttk.Entry(mframe, )
        self.entry_comment.grid(row=mr,column=1,stick=N+E+S+W)
        mr=mr+1

        ttk.Label(mframe,text="OBSERVER:",  **formatting).grid(row=mr,column=0, stick=W)
        self.entry_obs= ttk.Entry(mframe, )
        self.entry_obs.grid(row=mr,column=1,stick=N+E+S+W)
        ttk.Label(mframe,text="     ",  **formatting).grid(row=mr,column=2, stick=N+E+S+W)
        mr=mr+1

        mframe.grid_columnconfigure(0, minsize=150)
        mframe.grid_columnconfigure(1, minsize=150)
        mframe.grid(row=r,stick=E+W) 
        r=r+1
        #----

        mframe = ttk.LabelFrame(frame, text="Hawaii 2RG:", padx=2, pady=2, bd=2, relief=Tkinter.GROOVE) #padding=(10,10,10,10)) #, padx=10, pady=10)

        mr=0
        ttk.Label(mframe, justify=Tkinter.LEFT, text=" Modes: 1=single, 2=CDS, 3=MCDS, 4=UTR ", 
              **formatting).grid(row=mr, columnspan=3, stick=W+E)
        mr=mr+1

        ttk.Label(mframe,text="Mode nreads ncoadds:",  **formatting).grid(row=mr,column=0, stick=W)
        self.entry_mode = ttk.Entry(mframe,  width=10, )
        self.entry_mode.grid(row=mr,column=1,stick=N+E+S+W)
        self.entry_mode.insert(0,"2 2 1")
        mr=mr+1

        ttk.Label(mframe,text="ITIME: ",  **formatting).grid(row=mr,column=0, stick=W)
        self.entry_itime = ttk.Entry(mframe,  width=10, )
        self.entry_itime.grid(row=mr,column=1,stick=N+E+S+W)
        self.entry_itime.insert(0,"1.5")
        ttk.Label(mframe,text="s",  **formatting).grid(row=mr,column=2, stick=N+E+S+W)
        mr=mr+1

        ttk.Label(mframe,text="Next Filename:",  **formatting).grid(row=mr,column=0, stick=W)
        self.entry_fn = ttk.Entry(mframe,  width=10, )
        self.entry_fn.grid(row=mr,column=1,stick=N+E+S+W)
        self.entry_fn.insert(0,'test0001')
        ttk.Label(mframe,text=".fits",  **formatting).grid(row=mr,column=2, stick=N+E+S+W)
        mr=mr+1
 
        buttonbar = ttk.Frame(mframe, **formatting)
        buttonbar.grid(row=mr,column=0, columnspan=3)
        ttk.Button(buttonbar, text="Initialize", command=self.startSW, **formatting).grid(row=0,column=0)
        ttk.Button(buttonbar, text="Configure", command=self.configDet, **formatting).grid(row=0,column=1)
        ttk.Button(buttonbar, text="Take Image", command=self.takeImage, **formatting).grid(row=0,column=2)
        #ttk.Button(buttonbar, text="Print Keywords", command=self.printKeywords, **formatting).grid(row=0,column=3)
        ttk.Button(buttonbar, text="Abort", command=self.doAbort, **formatting).grid(row=0,column=4)
        ttk.Button(buttonbar, text="ds9", command=self.ds9, **formatting).grid(row=0,column=5)
        #ttk.Button(buttonbar, text="Quit", command=self.quit, **formatting).grid(row=0,column=5)


        mframe.grid_columnconfigure(0, minsize=150)
        mframe.grid_columnconfigure(1, minsize=150)
        mframe.grid(row=r,stick=E+W) 
        r=r+1

        #----
        mframe = ttk.LabelFrame(frame, text="PupilCam:", padx=2, pady=2, bd=2, relief=Tkinter.GROOVE) #padding=(10,10,10,10)) #, padx=10, pady=10)

        mr=0
        ttk.Label(mframe,text="ITIME:",  **formatting).grid(row=mr,column=0, stick=W)
        self.entry_pupilitime = ttk.Entry(mframe,  width=10, )
        self.entry_pupilitime.grid(row=mr,column=1,stick=N+E+S+W)
        self.entry_pupilitime.insert(0,"1.0")
        ttk.Label(mframe,text="s",  **formatting).grid(row=mr,column=2, stick=N+E+S+W)
        mr=mr+1

        ttk.Label(mframe,text="Next Filename:",  **formatting).grid(row=mr,column=0, stick=W)
        self.entry_pupilfn = ttk.Entry(mframe,  width=10, )
        self.entry_pupilfn.grid(row=mr,column=1,stick=N+E+S+W)
        self.entry_pupilfn.insert(0,'pupil0001')
        ttk.Label(mframe,text=".fits",  **formatting).grid(row=mr,column=2, stick=N+E+S+W)
        mr=mr+1
 
        buttonbar = ttk.Frame(mframe, **formatting)
        buttonbar.grid(row=mr,column=0, columnspan=3)
        #ttk.Button(buttonbar, text="Initialize", command=self.startSW, **formatting).grid(row=0,column=0)
        ttk.Button(buttonbar, text="Configure", command=self.configPupil, **formatting).grid(row=0,column=1)
        ttk.Button(buttonbar, text="Take Image", command=self.takePupil, **formatting).grid(row=0,column=2)
        ttk.Button(buttonbar, text="ds9", command=self.ds9pupil, **formatting).grid(row=0,column=3)

        mframe.grid_columnconfigure(0, minsize=150)
        mframe.grid_columnconfigure(1, minsize=150)
        mframe.grid(row=r,stick=E+W) 
        r=r+1

 
        #----

        frame.grid(row=0) 
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)

    def mainloop(self):
        self.root.mainloop()

    def quit(self):
        if  tkMessageBox.askokcancel(title="Confirm Quit",message="Are you sure you want to quit?"):
            self.log(' User quit GPITempGUI.py ')
            self.log(' ' )

            if self.watchid is not None:
                self.root.after_cancel(self.watchid)
            del self.logger
            self.root.destroy()

    def startSW(self):
        if  tkMessageBox.askokcancel(title="Confirm Start & Init",message="Are you sure you want to start the servers and initialize the hardware?"):
            self.IFSController.initialize()

    def doAbort(self):
        if  tkMessageBox.askokcancel(title="Confirm Abort",message="Are you sure you want to abort?"):
            self.IFSController.abortExposure()

    def configDet(self):
        parts = self.entry_mode.get().split()
        self.IFSController.configureDetector( float(self.entry_itime.get()), int(parts[0]), int(parts[1]), int(parts[2]) )

    def configPupil(self):
        self.pupil_exptime = float(self.entry_pupilitime.get())
        self.log("Pupil exposure time set to %d s" % self.pupil_exptime)

    def _incr_filename(self, widget, pupil=False):
        #increment the filename:
        m =  re.search('(.*?)([0-9]+)',widget.get())
        if m is not None:
            formatstr = "%0"+str(len(m.group(2)))+"d"
            newfn = m.group(1) + formatstr % ( int(m.group(2))+1)
            widget.delete(0,Tkinter.END)
            widget.insert(0,newfn)

    def _store_keywords(self):
        """ Store keyword values to controller object """
        keywords = ['TARGET','COMMENTS','OBSERVER', 'REQ_DET', 'REQ_PUP']
        entries = [self.entry_target, self.entry_comment, self.entry_obs, self.entry_mode, self.entry_pupilitime]
        comm = ['What are we looking at?', 'Misc comments', 'Who?', 'Requested detector config in gpitempgui', 'Requested pupil config in gpitempgui']
        for k, e, c in zip(keywords, entries, comm):
            self.IFSController.updateKeyword(k, e.get(), c)
        for m in self.motors:
            res = m.updatekey()
            self.IFSController.updateKeyword(res[0], res[1] , "Commanded motor position")
            #f[0].header.update(*m.updatekey() )
 

    def takePupil(self):
        if not hasattr(self, "pupil_exptime"):
            self.configPupil()
        self._store_keywords()
        self.IFSController.pupilExposure(self.entry_pupilfn.get(), time=self.pupil_exptime )
	self.last_pupil_fn = self.entry_pupilfn.get()
        self._incr_filename(self.entry_pupilfn)

    def takeImage(self):
        self._store_keywords()
        self.IFSController.takeExposure(self.entry_fn.get() )
	self.last_image_fn = self.entry_pupilfn.get()
        self._incr_filename(self.entry_fn)

    def ds9(self):
        self.runcmd("ds9 %s%s.fits &" % (self.IFSController.datadir+os.sep, self.last_image_fn))
    def ds9pupil(self):
        self.runcmd("ds9 %s%s.fits &" % (self.IFSController.pupildir+os.sep,self.last_pupil_fn))


    #def checkGMB(self):
        #val = self.IFSController.checkGMB_camReady()
        #self.log("    VALUE = %s" % string(val)) 

    #def printKeywords(self):
        #keywords = ['TARGET','COMMENTS','OBSERVER']
        #entries = [self.entry_target, self.entry_comment, self.entry_obs]
        #self.log('-- keywords --')
        #for k, e in zip(keywords, entries):
            #self.log("%8s = '%s'" % (k, e.get()))
        #for m in self.motors:
            #m.printkey()
        #self.log(' ')

    def runcmd(self,cmdstring, **kwargs):
        self.log(">    " +cmdstring)
        sys.stdout.flush()   #make sure to flush output before starting subproc.
        result = subprocess.call(cmdstring, shell=True, **kwargs)
        self.log("     return code= %d " %result)

    def watchDir(self,init=False):
        self.watchid = self.root.after(1000,self.watchDir)

        if self.IFSController.is_exposing(): 
            self.log(' still exposing - waiting.')
            return
        #self.log('watching')
        self.IFSController.checkNewFiles()

#        directory = os.curdir
#        curfitsset = set(glob.glob(directory+os.sep+"*.fits"))
#        if init:
#            self.log("Now watching directory %s for new FITS files." % (self.datadir))
#            self.oldfitsset = curfitsset
#            #self.log("Ignoring already present FITS files" +' '.join(curfitsset))
#            self.log("Ignoring %d already present FITS files." % len(curfitsset))
#            return
#
#
#        newfiles = curfitsset - self.oldfitsset
#        if len(newfiles) > 0:
#            self.log("New FITS files!: "+ ' '.join(newfiles))
#            for fn in newfiles: 
#                if self.updateKeywords(fn):
#                    self.oldfitsset.add(fn)
#
#        #self.oldfitsset=curfitsset
#
#    def updateKeywords(self, filename):
#        try:
#        #if 1:
#            # need to watch out for network latency/long compute times meaning that
#            # the files are not fully written yet. In that case, wait for the write to finish.
#            # FIXME - this code could be more robust, to avoid infinite loop potential etc
#            size = os.path.getsize(filename)
#            while ((size != 8392320 ) & (size != 16784640)):
#                self.log('file %s not fully written to disk yet - waiting.' % filename)
#                return False
#                #for i in range(5):
#                    #self.root.update_idletasks() # process events!
#                    #time.sleep(0.1)
#                #size = os.path.getsize(filename)
#
#            f = pyfits.open(filename,mode='update')
#            if 'TARGET' not in f[0].header.keys():  # check if it's already been updated
#                keywords = ['TARGET','COMMENTS','OBSERVER']
#                entries = [self.entry_target, self.entry_comment, self.entry_obs]
#                f[0].header.add_history(' Header keywords updated by GPITempGUI.py')
#                for k, e in zip(keywords, entries):
#                    f[0].header.update(k,e.get())
#                
#                for m in self.motors:
#                    f[0].header.update(*m.updatekey() )
#                self.log("Updated FITS keywords in %s" % filename) 
#            f.close()
#            return True # either we updated it or it was already updated
#     
#
#        except:
#            self.log("ERROR: could not update FITS keywords in %s" % filename)
#            return False

    def _set_initial_filename(self):
        i=1
        fn = "test%04d" % i
        while (os.path.exists(self.datadir+os.sep+fn+".fits")):
            i+=1
            fn = "test%04d" % i
        self.entry_fn.delete(0,Tkinter.END)
        self.entry_fn.insert(0,fn)
        self.log("Next filename set to %s.fits"% fn)

    def _set_initial_pupil_filename(self):
        i=1
        fn = "pupil%04d" % i
        while (os.path.exists(self.IFSController.pupildir+os.sep+fn+".fits")):
            i+=1
            fn = "pupil%04d" % i
        self.entry_pupilfn.delete(0,Tkinter.END)
        self.entry_pupilfn.insert(0,fn)
        self.log("Next pupilcam filename set to %s.fits"% fn)


    def log(self, message, **kwargs):
        if self.logger is not None:
            self.logger.log(message, **kwargs)



#######################################################################     

class ViewLog(tkSimpleDialog.Dialog):
    """ Display log messages of a program """

    def __init__(self, parent, geometry='+950+50',timestep=100, logpath=None):
        """ Create and display window. Log is CumulativeLogger. """

        # open a file logger
        if logpath is None:
            logpath = os.curdir
        today = datetime.date.today()
        log_fn = logpath+os.sep+ "ifslog_%02d%02d%02d.txt" % (today.year%100, today.month,today.day)

        self.file_logger=logging.getLogger('GPITempGUI Log')
        hdlr = logging.FileHandler(log_fn)
        formatter=logging.Formatter('%(asctime)s %(levelname)s\t%(message)s')
        hdlr.setFormatter(formatter)
        self.file_logger.addHandler(hdlr)
        self.file_logger.setLevel(logging.INFO)
        self.file_logger.log(logging.INFO,'----------------------------------------------------------')


        self.hdlr = hdlr # save for deleting later? 

        # create window  for log
        self.root = Tkinter.Tk()
        self.root.geometry(geometry)
        self.root.title("GPITempGUI Log")

        frame = ttk.Frame(self.root)#, padding=(10,10,10,10))
        frame.pack_configure(fill=Tkinter.BOTH, expand=1)
        self.t = ScrolledText.ScrolledText(frame, width=60, height=45) 
        self.t.insert(Tkinter.END, "")
        self.t.configure(state=Tkinter.DISABLED)
        self.t.see(Tkinter.END)
        self.t.pack(fill=Tkinter.BOTH)

        self.currtext=""

        self.root.update()


        self.filename = log_fn  

        #self.timestep=timestep
        #self.aw_alarm = self.root.after(self.timestep,self.checkLog)

        #self.dontclose=True
        #self.root.protocol("WM_DELETE_WINDOW", self.close)

    def close(self):
        if self.dontclose:
            pass
        else:
            self.root.destroy()

    def __del__(self):
        try:
            logging.shutdown()
            self.hdlr.flush()
            self.hdlr.close()
            self.file_logger.removeHandler(self.hdlr)
        except:
            print "problem closing log?"
        #self.dontclose=False
        self.root.destroy()
        print "logger closed"


    def log(self, message, log_level=logging.INFO,nonewline=False):
        # write to file
        if self.file_logger is not None:
            self.file_logger.log(log_level, message)
        # and to screen
        self.addText(message,nonewline=nonewline)


    def addText(self,newtext, nonewline=False):
        self.t.configure(state=Tkinter.NORMAL)
        if nonewline:
            self.t.insert(Tkinter.END, newtext)
        else:
            self.t.insert(Tkinter.END, newtext+"\n")
        self.t.configure(state=Tkinter.DISABLED)
        self.t.see(Tkinter.END)

#######################################################################     

if __name__ == "__main__":

    g = GPI_TempGUI()
    g.mainloop()

