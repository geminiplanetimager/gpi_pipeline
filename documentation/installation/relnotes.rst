
.. _release-notes:

Release Notes
###################

You may wish to skip ahead to  :ref:`configuring`.

Version: 0.9.2 
=========================================
Released 2013 Sept 5

The current stable version of the pipeline is 0.9.2, 
released for the start of GPI integration at Gemini South. This version
includes updates and enhancements from during the GPI pre-ship acceptance review and following weeks.


* Greatly improved persistence correction algorithm (Ingraham)
* Improved WCS header output (Perrin), and WCS assembly offloaded to helper function for consistency between spectral and polarization modes (Savransky)
* Calculation of time-averaged parallactic angle added to cube assembly primitives (Savransky, Marois)
* New Primitives:

  * New SDI KLIP primitive and templates (Savransky, Tyler Barker)
  * New primitive Check Coronagraph Status added; quicklook recipes updated to check if occulted data and if so, calculate the contrast (Savransky, Rantakyro)
  * Initial implementation of high-resolution subpixel microlens PSF code--still experimental! Ongoing testing and improvements. (Ruffio, Ingraham)
  * New primitive "Insert Planet Into Cube", with associated atmosphere models (Ingraham)

* Pipeline infrastructure enhancements

  * Template cleanup and reorganization, addition of templates starting of previously processed data cubes (Ingraham)
  * Implement subdirectory scanning support for calibrations directory (Perrin)
  * Rescanning config or CalDB now animates the Status Console progress bar (Perrin)
  * Added capability for long-running primitives to update Status Console progress bar (Savransky). Several primitives updated to do so.
  * Improvements to release and compiler scripts: Improved output filenames; includes HTML docs in compiled code; also generates source code zip file too. (Perrin)
  * New code to launch HTML documentation directly from pipeline GUIs (Perrin)
  * Added new file for pipeline_constants, added accessor function, moved variables from settings to constants file as appropriate (Savransky). Vega fluxes moved into new pipeline constants file and values updated (Ingraham)

* Recipe Editor and Parser GUIs:

  * Parameter allowed ranges now displayed in Recipe Editor (Savransky, Labrie)
  * Improved output filenames: output recipe filenames now first and last fits file used in the recipe and a short name now defined for each recipe template (Wolff)
  * Double clicking a filename in the file lists in either Recipe Editor or Data Parser will now open that file in gpitv (Perrin)
  * Recipe Editor GUI layout cleanup (Ingraham)

* GPItv enhancements and bug fixes:

  * Major cleanup of gpitv image loading procedure and associated documentation.  also fixed initial directory setting bug in the directory viewer.  removed unnecessary print output in ifs_cube_movie and changed klip backend to re-NaN bad pixels after processing (Savransky)
  * KLIP mode implemented in GPItv (Savransky, Tyler Barker)
  * fixed bug in KLIP associated with empty annuli (Savransky, Marois)
  * removed collapse by diff from gpitv and fixed gpitv sdi to use stored sat spots (Savransky)
  * fixed passing headers to gpitv when file is not being saved by pipeline.  fixed imname display issues in gpitv. (Savransky)
  * Bug fixes for image rotation and inversion with complex display modes like KLIP or align speckles (Perrin), fixed satspot handling in presence of rotations and inversion in gpitv (Savransky)
  * Implemented 'Auto Handedness' mode to flip images if necessary to get East counterclockwise of North (Perrin)

* Source code housekeeping:

  * Removal of deprecated function source code files, removal of some deprecated variables and other code, general codebase cleanup (Perrin, Ingraham, Savransky, Labrie)
  * Comprehensive renaming of primitive routine source code files such that filenames and primitive names are now consistent (Perrin, Ingraham)
  * Relocated gpitv source to a subdirectory of pipeline (Perrin)
  * Added compile_opt defint32, strictarr, logical_predicate to __start_primitive and updated all primitives with incompatible v4 syntax (Savransky)

* Miscellaneous bug fixes:

  * Minor bug fixes to various primitives (Ingraham)
  * Improved error handling for nonexistent FITS files when reading recipe XML files (Perrin)
  * Added username_in_log_filename setting to enable functional logging on multiuser machines
  * removed some unnecessary warning/info statements that were just cluttering up the display
  * switch several 'if not' statements to 'if ~' for logical rather than bitwise negation.
  * Recipe Editor now honors the 'organize_reduced_data_by_dates' option for setting output directories.
  * Windows OS compatibility bug fixes (Maire)
  * svn:keywords property set on all primitve source files to enable version id updating in FITS headers (was only working for some primitives before). (Perrin)

Version: 0.9.1 
=========================================
Released 2013 June 18.

Version 0.9.1 was 
released at the end of GPI acceptance testing at UCSC. This version
incorporates many enhancements and lessons learned based on GPI pre-ship acceptance testing.



* Initial implementation of IFS flexure spectral shift handling. (Maire, Perrin, Ingraham)
 
    * New primitives to measure spectral shifts based on test data, populate a
      lookup table of spectral displacements on the H2RG as a function of
      instrument elevation angle, and apply corrective shifts to wavelength
      solution data prior to datacube extraction
    * Applied shifts tracked in FITS header keywords SPOT_DX, SPOT_DY in reduced data products. 
    * Autoreducer GUI enhanced with options to control the above. 

* Destriping algorithms for darks and science enhanced to remove microphonics noise via Fourier filtering.  (Perrin, Ingraham, Ruffio)

* New primitive for persistence correction (Ingraham)

* Algorithm improvements and updated primitive for distortion correction (Maire, Konopacky)

* More robust polarization mode spot location calibration algorithm (Millar-Blanchaer)

* New primitive and recipe for generating cold bad pixel map from multi filter flats. (Perrin, Marois)

* Data parser now generates recipes for cold and hot and combined bad pixels
  maps if given suitable input data.  (Perrin)

    * Hot pixel maps generated from the longest available dark sequence,
      provided it has ITIME > 60 s and there are at least 10 dark files in the
      set. 

    * Cold bad pixel maps generated from all available flat files, provided
      there are at least 3 distinct filters. (TBD if 3 is sufficient. More is
      better for this purpose.)

    * Combined bad pixel maps generated if either of the above is invoked.

* New algorithm for low spatial frequency flat field generation (Ruffio)

* New recipe template for LOCI reductions (Maire)

* Off-by-one rounding bug fix in data cube extraction (Ruffio)

* Use identical SDI function in pipeline primitive and GPItv (Marois)

* Multiple input directory support added to recipe editor (Savransky)

* Updates to speckle alignment backend (Savransky)

* Pickles library of stellar spectra now included in config data directory, for use in photometric calibration routines (Perrin)

* Updated wavecal routine to only allow reasonable lamp/filter combinations (Maire, Ingraham)

* Various minor bug fixes, aesthetic cleanup of FITS keywords, improved logging, and other minor miscellany (Ingraham, Ruffio, Savransky, Millar-Blanchaer, Maire, Perrin)



Version 0.9.0
=========================================
Released 2013 February 8

Version 0.9.0 was used for GPI acceptance testing at UCSC.

* Adds destriping algorithms to mitigate IFS detector electronic noise pickup. (Ingraham, Perrin)


* The calibration database is now aware of IFS cooldowns and warm ups, and will
  by default refuse to use calibration files from a different cooldown.
  (Because hot pixels, darks, etc, change so much between detector thermal
  cycles, this is the right default). If you want to temporarily disable this
  at the start of a run so you can e.g. use existing wavelength solutions
  before you have had time to take new better ones, this can be done easily
  just by changing a flag in the pipeline config file.  (Perrin)

* Other Calibration Database various improvements.

*   The "automatic reducer" pipeline window now has a new option, which
    lets you select a specific reduction recipe template to apply to each new IFS
    data file as it is taken. The default remains the same, a basic datacube recipe
    without much calibration, but this lets you override that default with a
    different recipe if you so desire (for instance, Dmitry wants a recipe to
    produce speckle-aligned data cubes when he's doing a speckle nulling
    experiment.)  (Perrin)

*   Error checking in gpitv has been enhanced so that, if/when it encounters an
    error, it will just print the error message on screen and then return to normal
    execution, rather than stopping in the debugger and freezing the IDL widget
    program event loop. This should prevent any viewer program errors from pausing
    execution of the automatic reducer. (Savransky, Perrin)

*   New graphical tool 'gpicaldbview'. This displays a nice tabular interface
    to view/search the current contents of the calibration database. (Probably of
    interest primarily to pipeline developers; for normal users it remains the case
    that the CalibDB will always automatically provide the best available
    calibrations during data reduction.)   (Perrin)



Past Versions
===============

0.8.1
-------
Released 2012 August 8

* Improved command line functionality for pipeline testing
* Improved auto-reducer tool and quicklook recipes
* GPItv speckle alignment mode added



0.8
---------
Released 2012 February 2. 

Initial version for IFS integrated with rest of GPI at UCSC.

Improved MEF file support, Gemini style keywords, 
major code reorganization and cleanup

0.7
---------
Released 2011 August 1. 

Most significant change is adoption of Multi-Extension FITS ("MEF") data file formats,
in accordance with Gemini standard. 

0.6
----------
Released 2010 May 26. 


0.5
---------

Release June 2008 for GPI Critial Design Review

Proceed now to :ref:`configuring`.


