#!/usr/bin/env python
import os, sys, fnmatch
import glob
import subprocess
import fileinput

# A script to package GPI IFS DRP code into Zip files for easy distribution.
# By Marshall

# EDIT THE NEXT LINE TO SET THE RELEASE VERSION
release_version = '0.61'


# Set the next variable to True if you want to skip making the really large
# tar files that don't change often (the detector data and Zemax files)
# Set it to False to re-create those zip files too.
skipLarge=False
skipLarge=True

def runcmd(cmdstring, **kwargs):
    print "    " +cmdstring
    sys.stdout.flush()   #make sure to flush output before starting subproc.
    subprocess.call(cmdstring, shell=True, **kwargs)
#


def locate(pattern, root=os.curdir):
    '''Locate all files matching supplied filename pattern in and below
    supplied root directory.'''
    for path, dirs, files in os.walk(os.path.abspath(root)):
        for filename in fnmatch.filter(files, pattern):
            yield os.path.join(path, filename)

def cleanup():
    # put things back as they were at first
    runcmd('mv tmp/dst_zem/* dst')
    runcmd('mv tmp/dst/PSFs dst')
    runcmd('mv tmp/detector_data/* dst/detector_data/')
    runcmd('rmdir tmp/dst_zem/')
    runcmd('rmdir tmp/dst')
    runcmd('rmdir tmp/detector_data')
    runcmd('rmdir tmp')

def update_textfile_version(filename, version=release_version):
    for line in fileinput.FileInput(filename, inplace=1):
        if line.startswith('version = '): 
            line = "version = '%s'" % release_version




if __name__ == "__main__":

    print """

    Now building zip files for GPI software. 

    This may take some time (particularly if skipLarge is not set)


    """

    update_textfile_version('pipeline/drp_code/gpi_pipeline_version.pro')
    update_textfile_version('pipeline/installer/install_gpi_drp.py')

    if skipLarge:
        print "Creating Zip files (except the really large Zemax and Detector ones)"
        print ""

    cd=os.curdir

    zip_args = '-x CVS */CVS' # exclude CVS files.

    # deal with the files which should go in a different zip file
    # -- Zemax Files --
    #runcmd('\\rm -r tmp') # clear out any previous invocation.
    if not os.path.isdir('tmp/dst'): 
        os.makedirs('tmp/dst')
 
    #runcmd('mkdir tmp/dst')
    runcmd('mv dst/*zemdisp* tmp/dst')
    runcmd('mv dst/ifu_microlens* tmp/dst')
    if not skipLarge:
        runcmd('zip -r dst_zemax.zip dst %s' % zip_args, cwd='tmp')
    runcmd('mv tmp/dst tmp/dst_zem')
    runcmd('mv tmp/dst_zemax.zip .')

    # -- Input PSFs --
    if not os.path.isdir('tmp/dst'): 
        os.makedirs('tmp/dst')
    runcmd('mv dst/PSFs tmp/dst')
    if not skipLarge:
        runcmd('zip -r dst_psfs.zip dst %s' % zip_args, cwd='tmp')
        runcmd('mv tmp/dst_psfs.zip .', cwd=cd)

    # -- Detector data --
    if not skipLarge:
        runcmd('zip -r dst_detectordata.zip dst/detector_data')
    runcmd('mv dst/detector_data tmp') # always mv this out of the dst code dir in any case.

    #make some directories just in case
    runcmd('mkdir pipeline/queue')
    runcmd('mkdir data')
    runcmd('mkdir logs')
    runcmd('mkdir data/raw')
    runcmd('mkdir data/reduced')

    directories = ['gpitv', 'dst', 'pipeline', 'documentation']
    for d in directories:
	if d == "pipeline":  #special hack: include blank top-level data directories inside the pipeline zipfile
		dirs = 'pipeline data logs -x pipeline/installer'
	else:
		dirs=d
        runcmd('zip -r %s_%s.zip %s %s' % (d, release_version, dirs, zip_args))
    


    cleanup()    
        


    # move the created zip files to the release directory
    runcmd('mv *.zip ../Release_GPI/')
    runcmd('cp pipeline/installer/install_gpi_drp.py ../Release_GPI/install.sh')
    runcmd('chmod 755 ../Release_GPI/install.sh')


    # create a double-clickable installer
    if not os.path.isdir('../Release_GPI/InstallGPIDRP.app/Contents/MacOS'):
        os.makedirs('../Release_GPI/InstallGPIDRP.app/Contents/MacOS')
    runcmd('cp ../Release_GPI/install.sh ../Release_GPI/InstallGPIDRP.app/Contents/MacOS/InstallGPIDRP')
    runcmd('tar cvzf  installer.tar.gz install.sh InstallGPIDRP.app', cwd='../Release_GPI/')


    print """

    GPI software now packaged. 

    Examine the Zip files in ../Release_GPI/

    """

