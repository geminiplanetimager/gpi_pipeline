.. _calibdb:

The Calibration Database
##############################

The calibration database consists of a directory containing all reduced calibration 
files needed by the GPI DRP, and associated software for indexing and accessing
the calibration files.  The location of the calibration data directory is :ref:`configured
upon system installation <config-envvars>`. 

As new calibration data are reduced, they are automatically saved into the
calibration DB. As other data are reduced, by default the pipeline queries the calibration
data to find the most appropriate calibration information for each task. (Users may explicitly select calibration files if desired, using the Recipe Editor tool).

The index of available calibrations is maintained in a FITS bintable file called ``GPI_Calibs_DB.fits`` located in the calibrations directory. 
(For convenience, a human-readable copy of this file is also saved, in plain text format. This can be used to quickly examine by eye its contents) 
The index table contains a list of various keyword values
of the reduced calibration data that can be used by the calibration DB software to
assign appropriate calibration 


The fields which are tracked are:

1. Directory path (Currently all files are stored in the same calibrations directory,
   but we save the path explicitly to support potential future upgrades to this
   directory layout).
2. Filename of the reduced calibration data
3. Data type (e.g. Dark, wavelength calibration, flat field, etc) 
4. Prism (to differentiate between spectral and polarimetric mode)
5. Filter 
6. Apodizer 
7. Lyot
8. Port of the Gemini Instrument Support Structure (side, bottom). This is relevant for instrumental polarization calibration.
9. Exposure time
10. date of acquisition of the raw file (in JD), or the most recent if the calibration is a combined product from several raw files 


How the Calibration Database Selects Which File to Return
-----------------------------------------------------------

Below is a list of the Criteria used to select the correct recipe to reduce a given type of calibration file. The values for the Type, Exposure Time, Data, Filter, and Prism are pulled from the image headers of the raw files. 

============================    ===========================
Calibration File                Criteria
============================    ===========================
Dark                            Type, Exposure time, date
Wavelength solution             Type, Filter, Prism, Date
Polarimetry spots cal           Type, Filter, Prism, Date
Master flat                     Type, Filter, Prism
Bad pixel map                   Type, Date
Plate scale & orientation       Type, Date
Spot locations                  Type, Filter, Prism, Date
Grid ratio                      Type, Filter, Prism, Date
Distortion                      Type, Date
Flux conversion                 Type, Filter, Prism, Date
Telluric transmission           Type, Filter, Prism, Date
Instrumental polarization       Type, Filter, Prism, Date
============================    ===========================


The **rules for matching files** are detailed :ref:`here <caldb-devel>`.


Maintaining the Calibration Database
----------------------------------------------

For the most part, the calibration database software takes care of maintaining
itself in a fairly automatic manner.  As new calibration files are reduced, the
DRP software updates in real-time the calibration database. 

The calibration file index can be
re-created at any time if needed by pressing the 'Rescan Calib. DB' button in the 
pipeline :ref:`status_console`. For instance, if you want to copy or move calibration 
files from one computer to another, on the destination computer you should 
rescan the database and it will pick up any new files that were added. 

