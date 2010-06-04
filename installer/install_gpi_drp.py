#!/usr/bin/env python
import os, sys
from Tkinter import *
import Tkinter
#import ttk
import Tkinter as ttk
import ScrolledText
import tkSimpleDialog
import tkFileDialog, tkMessageBox
import urllib,urllib2
import re
import tempfile
import subprocess

import logging

import zipfile


# The following MUST be consistent with the Knowledge Tree
version = '0.61'
filenames=['gpitv_'+version+'.zip', 
            'dst_'+version+'.zip', 
            'pipeline_'+version+'.zip', 
            'documentation_'+version+'.zip', 
            'dst_psfs.zip', 
            'dst_zemax.zip', 
            'dst_detectordata.zip']

IDs= ['19170', '12182', '19168', '19375', '12183', '11315', '19374' ]


#filenames=['pipeline_'+version+'.zip']

#IDs= ['19170', '19168', '??', '??', '??', '??', "??"]


# Helpful flag:
DEBUG=False
#if DEBUG:
    #filenames=['pipeline_'+version+'.zip'] 

class GPI_installer:
    def __init__(self):

        self.DEBUG=DEBUG
        self.installed_ok = False # not done yet

        self.file_logger=None

        self.root = Tk()
        self.root.title("GPI IFS Software Installer")
        self.root.geometry('+50+50')
        formatting = {"background": "#CCCCCC"}
        formatting={}
        frame = ttk.Frame(self.root, padx=10, pady=10) #padding=(10,10,10,10)) #, padx=10, pady=10)

        r=0
        ttk.Label(frame, text="GPI IFS Software Installer", font="Helvetica 20 bold italic",  **formatting).grid(row=r, columnspan=4)

        r=r+1
        ttk.Label(frame, justify=LEFT, text="""
        This script will install the GPI IFS software tree, including
        - DST       Data Simulation Tool
        - DRP       Data Reduction Pipeline
        - GUIs      DRF parsing & editing GUIs
        - GPItv     GPI interactive data viewer

        Requirements:
        - A working copy of IDL, version >= 6.0
        - The Goddard IDL astronomy library in your $IDL_PATH
        - about 1 GB of disk space 
          (and many GB for simulated & reduced data)


        Questions, comments, and bug reports for this installer should
        be sent to Marshall Perrin <mperrin@ucla.edu>
        Questions, comments, and bug reports for the pipeline software
        itself should also be copied to Jerome Maire <maire@astro.umontreal.ca>
        """,  **formatting).grid(row=r, columnspan=3, stick=N+E+S+W)
        r=r+1

        #----
        lf = ttk.LabelFrame(frame, text="Install Location:", padx=3, pady=6, **formatting)# padding=(3,3,6,6))#, padx=3, pady=6, **formatting)
        ttk.Label(lf, justify=LEFT, text="""Please enter the directory path in which the software should be installed. 
    This directory will be created if necessary.
    """, **formatting).grid(row=0,column=1,columnspan=3, sticky=N+E+S+W)

        self.label_path = ttk.Label(lf,text="Installation Path:",  **formatting)
        self.label_path.grid(row=3,column=1,stick=N+E+S+W)
        self.entry_path = ttk.Entry(lf, )
        self.entry_path.grid(row=3,column=2,stick=N+E+S+W)
        self.entry_path.insert(0,'~/GPI/')
        ttk.Button(lf, text="Browse...", command=self.pick_dir, **formatting).grid(row=3,column=3)

        ttk.Label(lf,text=" ", **formatting).grid(row=4,column=1)
        lf.grid(row=r,column=0,columnspan=3)
        r=r+1

        #----
        lf = ttk.LabelFrame(frame, text="Knowledge Tree:",padx=3, pady=6, **formatting)# padding=(3,3,6,6))#, padx=3, pady=6, **formatting)
        rr=0
        ttk.Label(lf, justify=LEFT,  text="""Please enter your Knowledge Tree username & password so
the software can be downloaded from the KT.
(not needed if zipfiles are already downloaded)
        
        """, **formatting).grid(row=rr, columnspan=3, stick=N+E+S+W)

        self.label_username = ttk.Label(lf,text="KT Username:", justify=LEFT, **formatting)
        self.label_username.grid(row=rr+1,column=1,stick=N+E+S+W)
        self.entry_username = ttk.Entry(lf)
        self.entry_username.grid(row=rr+1,column=2,stick=N+E+S+W)

        self.label_password = ttk.Label(lf,text="KT Password:", **formatting)
        self.label_password.grid(row=rr+2,column=1,stick=N+E+S+W)
        self.entry_password = ttk.Entry(lf, show="*")
        self.entry_password.grid(row=rr+2,column=2,stick=N+E+S+W)

        if self.DEBUG:
            self.entry_username.insert(0,'mperrin')
            self.entry_path.insert(5,'_test')


        ttk.Label(lf,text=" ", **formatting).grid(row=r+3,column=1)

        lf.grid(row=4,column=0,columnspan=3, sticky=N+E+S+W)

        #----
        lf = ttk.LabelFrame(frame, text="Install Type:",padx=3, pady=6, **formatting)# padding=(3,3,6,6))#, padx=3, pady=6, **formatting)
        rr=0
        #ttk.Label(lf, justify=LEFT,  text="""Please enter your Knowledge Tree username & password so
        #""", **formatting).grid(row=rr, columnspan=3, stick=N+E+S+W)

        self.install_type = ttk.StringVar(value='Full')
        self.check_type = ttk.Checkbutton(lf,text="Just update existing install?", justify=LEFT, onvalue='Update', offvalue='Full', variable=self.install_type, **formatting  )
        self.check_type.grid(row=rr, column=1, stick=N+E+S+W)
        ttk.Label(lf,text="If checked, the large (800 MB) data files will not be re-downloaded.", **formatting).grid(row=rr+1,column=1)


        lf.grid(row=5, column=0, columnspan=3, sticky=N+E+S+W)
 
        #----
        buttonbar = ttk.Frame(frame, **formatting)
        buttonbar.grid(row=8,column=0, columnspan=3)
        ttk.Button(buttonbar, text="Install", command=self.go_install, **formatting).grid(row=0,column=0)
        ttk.Label(buttonbar,text=" ", **formatting).grid(row=0,column=1)
        ttk.Button(buttonbar, text="Quit", command=self.quit, **formatting).grid(row=0,column=2)

        frame.grid(row=0) #, padding=(2,2,2,2))#, padx=2, pady=2, sticky=(N, S, E, W))
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)

        self.root.update()

        

    def mainloop(self):
        self.root.mainloop()
        #d = MyDialog(root)

        #print d.result
    
    def quit(self):
        if self.installed_ok:
            sys.exit()
        else:
            ans = tkMessageBox.askokcancel(title="Confirm Quit",message="Are you sure you want to quit the installer without finishing the install?", icon='question')
            if ans:
                sys.exit()
    def runcmd(self,cmdstring, **kwargs):
        self.log("    " +cmdstring)
        sys.stdout.flush()   #make sure to flush output before starting subproc.
        subprocess.call(cmdstring, shell=True, **kwargs)


    def go_install(self):


        self.log("Go button pressed!")

        self.log("Install type is "+self.install_type.get())


        if not self.validate_fields():
            return

        self.install_path = self.entry_path.get()
        self.install_path = os.path.normpath(os.path.expanduser(self.install_path))
        if not self.install_path.endswith(os.sep):
            self.install_path+= os.sep


        # Create install dir if required
        if not os.path.exists(self.install_path):
            ans = tkMessageBox.askyesno("Confirm mkdir","The directory %s needs to be created. Is it OK to create it now?" % self.install_path)
            if ans:
                os.makedirs(self.install_path)
            else:
                self.log("User cancelled")
                return



        # open a file logger
        self.file_logger=logging.getLogger('GPI DRP Installer')
        hdlr = logging.FileHandler(self.install_path+"install_log.txt")
        formatter=logging.Formatter('%(asctime)s %(levelname)s %(message)s')
        hdlr.setFormatter(formatter)
        self.file_logger.addHandler(hdlr)
        self.file_logger.setLevel(logging.INFO)

        self.log("   ***   Installation Start   ***   ")
        self.log("path: "+self.entry_path.get())
        self.log("user: "+self.entry_username.get())

        self.log("  logging actions to file "+self.install_path+"install_log.txt")

        # Get the input ZIP files

        status_ok, files = self.getfiles(self.entry_username.get(), self.entry_password.get(), directory=self.install_path)

        if status_ok:

            # do the actual installation

            self.unzipall(files)
            self.finish_install()


            self.verify_install()
        else:
            self.log(" Could not obtain required files successfully - installation terminated. ", log_level=logging.ERROR)

    def log(self, message, log_level=logging.INFO):
        # write to file
        if self.file_logger is not None:
            self.file_logger.log(log_level, message)
        # and to screen
        self.logger.addText(message)
        self.root.update_idletasks() # process events!

         


    def unzip_file_into_dir(self, file, dir):
        if not os.path.isdir(dir):
            os.mkdir(dir, 0777)
        zfobj = zipfile.ZipFile(file)
        for name in zfobj.namelist():
            self.log('Unzipping '+name)
            if name.endswith('/'):
                if not os.path.isdir(os.path.join(dir, name)):
                    os.mkdir(os.path.join(dir, name))
            else:
                outfile = open(os.path.join(dir, name), 'wb')
                outfile.write(zfobj.read(name))
                outfile.close()

    def unzipall(self, files):
        for f in files:
            #self.runcmd('unzip -o %s' % os.path.basename(f), cwd=self.install_path)
            self.unzip_file_into_dir(f, self.install_path)

    def finish_install(self):
        d = self.install_path

        # move scripts to top-level path
        if not os.path.islink( "%sscripts" % d):
            self.runcmd("ln -s %spipeline/scripts %s" % (d,d))
        # set file permissions for scripts
        # (not preserved by ZIP files)

        self.runcmd("chmod 755 %s/scripts/gpi-pipeline" % d)

        self.set_ifsdir_variable()


        
        if not os.path.exists(os.path.expanduser("~/.Xdefaults")):
            ans = tkMessageBox.askyesno(title="Create .Xdefaults file?",message="""The installer would like to create/update a .Xdefaults file in your home directory, in order to adjust the screen appearance of the IFS software (font and colors). 
            
 This is the only way to adjust widget colors in IDL. It will almost certainly have no effect whatsoever on any other application on your computer. 

Saying Yes here will let the installer update this config file. If you say no here, all the IFS software will work just fine, but will have all-grey IDL default widgets. This is a purely cosmetic user interface question!""", icon='question')
            if ans:
                xd = open(os.path.expanduser("~/.Xdefaults"), "w")
                XDEFTEXT = """
!---- Customization of Xdefaults values for GPI widgets 
!  Purely cosmetic, no functional changes at all!
!  Feel free to tweak and adjust as desired.
!  developed by Marshall Perrin 
Idl*GPI_DRP*background: #E9E9F5
Idl*GPI_DRP*fontList: *helvetica-bold-r-*--11*
Idl*GPI_DRP*Table*fontList: *helvetica-medium-r-*--10*
Idl*GPI_DRP*XmPushButton*background: lightblue
Idl*GPI_DRP*red_button*background: pink
Idl*GPI_DRP*Status*red_button*background: pink
Idl*GPI_DRP*Status*XmText*fontList: *helvetica-medium-r-*--10*

Idl*GPI_DRP_DST*background: #DAE3D0
Idl*GPI_DRP_DST*XmText*background: white
Idl*GPI_DRP_DST*SimButton*background: #AAE3A0

Idl*GPI_DRP_DRFGUI*fontList:  *helvetica-bold-r-*--11*
Idl*GPI_DRP_DRFGUI*background: #E7E7D0
Idl*GPI_DRP_DRFGUI*red_button*background: pink
Idl*GPI_DRP_DRFGUI*XmPushButton*background: #CBE0DF
Idl*GPI_DRP_DRFGUI*XmCascadeButton*background: lightblue
Idl*GPI_DRP_DRFGUI*XmText*background: #F7F7F0

Idl*GPI_DRP_Parser*fontList:  *helvetica-bold-r-*--11*
Idl*GPI_DRP_Parser*background: #F1E9C8
Idl*GPI_DRP_Parser*red_button*background: pink
Idl*GPI_DRP_Parser*XmPushButton*background: #CBE0DF
Idl*GPI_DRP_Parser*XmCascadeButton*background: lightblue
Idl*GPI_DRP_Parser*XmText*background: #F7F7F0
"""
                xd.writelines(XDEFTEXT)
                xd.close()
                self.log("Updated ~/.Xdefaults file")
            else:
                self.log("no update done to ~/.Xdefaults")
	else:
	    self.log("An existing ~/.Xdefaults file was detected - no modifications are being made to this. ")
	    self.log("However, if you would like to customize the appearance of your GPI GUI programs, please see the file sample_Xdefaults in the pipeline/scripts directory")


                


        outmessage = """ *** Congratulations ***


The GPI IFS Data Pipeline software has now been installed in: \n%s

To run it, you need to set various environment variables.  Please source one of the following files in your shell startup script:
    
    %sscripts/setenv_GPI.bash
    %sscripts/setenv_GPI.csh

You may need to verify in those setenv_GPI files that the GPI_IFS_DIR variable has been set properly. Once that is done, you can start the pipeline itself via
    %sscripts/gpi-pipeline
which you may wish to add to your $PATH.


See the documentation files in %sdocumentation for usage instructions and more!


""" % (d, d, d, d, d)
        self.log(outmessage)

        self.log("""
------
Unfinished/TODO: Clean up ZIP files after extraction
------
You may now press 'Quit' to exit the installer.
""")
        ans = tkMessageBox.showinfo("Install OK",outmessage)

        self.installed_ok = True
        #exit()


    def verify_install(self):
        self.log("Verification of install NOT YET IMPLEMENTED")


    def set_ifsdir_variable(self):
        # Update the environment variabiles in the setenvs files.

        # The directory variable there should NOT end with a trailing slash.
        # so take one out here if necessary
        d = self.install_path
        if d.endswith(os.sep):
            d = d.rstrip(os.sep)
        default_dir = r'~/GPI'
        files = [d+os.sep+'scripts/setenv_GPI.csh', d+os.sep+'scripts/setenv_GPI.bash']
        for filename in files:
            self.log('Updating '+filename)
            if not os.path.exists(filename):
                self.log("Could not find file %s - cannot update! Your environment variables will probably not be set right.", log_level=logging.ERROR)
                continue
            f = open(filename)
            textfile = f.readlines()
            f.close()
            f = open(filename,'w')
            #print default_dir, d
            f.writelines( [t.replace(default_dir,d) for t in textfile] )
            f.close()
            #for line in textfile:
                #print line
                #if line.find(default_dir) > -1:
                    #self.log("Updating default dir %s to %s " % (default_dir, d))

                #f.write(line.replace(default_dir,d))
            #f.close()






    def validate_fields(self,which='path'):
        if which == 'path':
            fields = [self.entry_path]
            names = ['Installation Path']
        else:
            fields = [self.entry_username, self.entry_password]
            names = ['KT Username', 'KT Password']
        for f,n in zip(fields,names):
            if f.get() == "":
                self.log("ERROR: Blank value for field "+n+"! Please enter a value there.", log_level=logging.ERROR)
                return False
        return True


    def pick_dir(self):
        defaultdir = self.entry_path.get()
        if ~os.path.isdir(defaultdir):
            defaultdir='~'
        defaultdir = os.path.expanduser(defaultdir)
        dirname = tkFileDialog.askdirectory(parent=self.root,initialdir=defaultdir,title='Please select a directory...')
        if len(dirname ) > 0:
            self.log("You chose %s" % dirname )
            self.entry_path.delete(0,len(self.entry_path.get())+3)
            self.entry_path.insert(0,dirname)
        else:
            self.log("You cancelled.")


    def login_opener( self, username="Test", password="None"):

        if not self.validate_fields(which='login'):
            return None
        # see URLLIB2 cookbook at http://personalpages.tds.net/~kent37/kk/00010.html

        KT_login = 'http://dms.hia.nrc.ca/login.php'

        # Create a form-based password-authentication object and log in to KT
        opener = urllib2.build_opener(urllib2.HTTPCookieProcessor())
        urllib2.install_opener(opener)
        params = urllib.urlencode(dict(username=username, password=password, action='login', cookieverify='',redirect=''))
        self.log("Logging in to Knowledge Tree to download files")
        f = opener.open(KT_login, params)
        data = f.read()
        f.close()
        info = f.info()
        #self.log("URL: %s" % f.geturl()
        #self.log("INFO:"+ str(f.info()))
 
        return opener
       # TODO - verify login OK by examining output data
 
    def getfiles(self, username="Test", password="None", directory=None):
        """ Filenames and URLs should be set to values consistent with the KT 
        """


        KT_download = 'http://dms.hia.nrc.ca/action.php?kt_path_info=ktcore.actions.document.view&fDocumentId='
        directory = os.path.expanduser(directory)

        if directory is None: 
            directory = tempfile.gettempdir()
            self.log("Storing temporary files in %s." % directory)

        outfiles = []
        opener = None

        cwd = os.path.dirname(os.path.abspath(__file__))
        cwd2 = os.path.abspath(cwd+"/../")
        if cwd.endswith("MacOS"): # if we're in an app bundle
            self.log("detected running from a Mac OS .app bundle; adjusting paths accordingly")
            cwd2 = os.path.abspath(cwd+"/../../../")
            cwd = os.path.abspath(cwd+"/../../")

        self.log("Checking for already available files in "+directory)
        self.log("Checking for already available files in "+cwd)
        self.log("Checking for already available files in "+cwd2)
    
        # which filenames do we want?
        if self.install_type.get()=='Full':
            filenames2=filenames
        else:
            filenames2=filenames[0:-3]


        # now download the files
        for f,u in zip(filenames2,IDs):
            outname = directory+os.sep+f
            inname2 =cwd+os.sep+f
            if os.path.exists(outname):
                self.log("File already exists: %s" % outname)
                outfiles.append(outname)
            elif os.path.exists(cwd+os.sep+f):
                self.log("Found file %s" % cwd+os.sep+f)
                outfiles.append(cwd+os.sep+f)
            elif os.path.exists(cwd2+os.sep+f):
                self.log("Found file %s" % cwd2+os.sep+f)
                outfiles.append(cwd2+os.sep+f)
            else:
                self.log("Could not find file %s; retreiving from KT." % f )
                if opener is None:
                    self.log("Opening new connection to KT - this may take some time....")
                    opener = self.login_opener(username=username,password=password)
                    if opener is None: 
                        self.log("Could not open connection to KT. Exiting. ", log_level=logging.ERROR)
                        return (False, outfiles)
                u2 = KT_download+u
                self.log("Now retrieving file %s.\n Source URL= %s" % (f,u2))
                conn = opener.open(u2)
                data = conn.read()
                conn.close()
                info = conn.info()
                #self.log("URL: %s" % f.geturl()
                #self.log("INFO:"+ str(f.info()))
                if 'Content-Disposition' in info:
                    fn = re.match('.*filename="([^"]*)"', info['Content-Disposition']).group(1)
                    self.log("Output Filename: %s" % fn)
                    outname=fn
                    #self.log("Disposition: ", info['Content-Disposition']
                    out = open(outname, "w")
                    out.write(data)
                    out.close()
                    self.log("  Data output to file %s" % outname)
                    outfiles.append(outname)
                else:
                    errmessage = "Could not retrieve file %s from KT! Check URL: \n%s\n " % (f, u2)
                    self.log(errmessage, log_level=logging.ERROR)
                    ans = tkMessageBox.showerror(title="Download Error",  message="ERROR: "+errmessage, icon='error'  )

                    return (False,outfiles) # no sense in continuing further...

        self.log("All requested files have now been downloaded")

        return (True,outfiles)
           
class ViewLog(tkSimpleDialog.Dialog):
  """ Display log messages of a program """

  def __init__(self, parent, geometry='+650+50',timestep=100):
    """ Create and display window. Log is CumulativeLogger. """
    self.root = Tk()
    self.root.geometry(geometry)
    self.root.title("Installer Log")
    frame = ttk.Frame(self.root)#, padding=(10,10,10,10))

    master=frame

    master.pack_configure(fill=Tkinter.BOTH, expand=1)
    self.t = ScrolledText.ScrolledText(master, width=60, height=45) #, sticky=(Tkinter.N,Tkinter.S,Tkinter.E,Tkinter.W))
    self.t.insert(Tkinter.END, "")
    self.t.configure(state=Tkinter.DISABLED)
    self.t.see(Tkinter.END)
    self.t.pack(fill=Tkinter.BOTH)

    self.currtext=""

    self.root.update()

    self.timestep=timestep
    #self.aw_alarm = self.root.after(self.timestep,self.checkLog)

  def addText(self,newtext):
        self.t.configure(state=Tkinter.NORMAL)
        self.t.insert(Tkinter.END, newtext+"\n")
        self.t.configure(state=Tkinter.DISABLED)
        self.t.see(Tkinter.END)



if __name__ == "__main__":

    #logging.basicConfig()
    #l = logging.getLogger()
    #l.setLevel(logging.INFO)
    #cl = CumulativeLogger.CumulativeLogger()

    g = GPI_installer()
    v = ViewLog(g.root, geometry='550x600+570+50',timestep=10)
    g.logger = v
    g.log('Starting the GPI IFS Software Installer.')
    g.log('Informative log messages will appear in this window')
    g.log('as the installer proceeds.')
    g.log(' ')
    g.log('Enter options in the window at left and press "Install" to proceed. ')
    g.log(' ')



    g.mainloop()

    
