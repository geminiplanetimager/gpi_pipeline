
.. _release-notes:

Release Notes
###################

You may wish to skip ahead to  :ref:`configuring`.


Version 1.1
=========================================
Released TBD May 1 ish. 

This version was released in support of the GPI Early Science shared-risk observing programs by the community. It includes a range
of enhancements and fixes made during the ongoing commissioning observing runs, including in particular substantial updates to polarimetry mode support. 

.. comment:
    Everything significatn in commits from 2564 (release 1.0) through to current

* Enhancements/Additions to primitives and recipes:

* Pipeline infrastructure

* Recipe Editor, Data Parser, Autoreducer GUIs: 

* GPItv enhancements and bug fixes:

* Documentation 


* Miscellaneous bug fixes and minor tasks:

 


Version 1.0.0
=========================================
Released 2014 Feb 14

Version  1.0.0 of the GPI dat pipeline was released together with the full GPI first light data release.  
This version includes a variety of enhancements and bugfixes specifically targeted at the first light data.
  
* Enhancements/Additions to primitives and recipes: 
  
  * Added ability to locate the central star in polarimetry mode. (Wang)
  * Improved handling of missing keywords and associated logging. (Ingraham)
  * Added 2MASS filter corrections to photometric calibration and flux calculation. (Ingraham)
  * Bug fixes and improvements in spectral extraction primitive. (Ingraham)
  * Updated the 2d wavelength solution primitive to accept a user defined reference wavecal file. Improved efficiency of 2D wavelength solution code. (Wolff)
  * Added star color magnitude correction to photometric calibration. (Ingraham)
  * Bug fixes in thermal background subtraction for K band. (Ingraham)
  * Numerous bug fixes in polarization mode primitives. (Millar-Blanchaer)
  * Updates to LOCI ADI. (Ingraham, Marois)
  * Updated the quick wavelength solution primitive to accept estimated offsets in both the x and y directions and to shift the lenslet boxes via cross correlation to account for large flexure shifts. (Wolff)
  * Added the Quality Check Wavelength Calibration primitive to the 2D wavelength solution and wuick wavelength solution recipes. (Wolff, Perrin)


* Pipeline infrastructure:

  * Added Vega spectral data. (Ingraham)
  * Updated apodizer transmissions. (Wang)
  * Created a gpi-pipeline launcher for Windows to be consistent with Mac/Unix systems. (Wang)
  * Automated installation scripts for all operating systems. (Wang)
  * Added throughputs (including telluric transmission) from first light data. (Maire)
  * Added utility functions for atmospheric differential refraction. (Perrin)
  * Fixed handling of non-GPI environment variables. (Savransky)


* Recipe Editor, Data Parser, Autoreducer GUIs: 

  * Updated gpicaldatabase to ensure that thermal cubes are not mistaken for thermal 2d images. (Ingraham)
  * Improved Data Parser handling of wavelength calibration data. (Wolff)
  * Improved logic for selecting appropriate Dark files. (Perrin)
  * Loaded recipes now automatically set the filename in the Recipe Editor. (Savransky)
  * Removed maximum number of primitives limit in Recipe Editor. (Savransky)
  * Improved working directory handling. (Wolff)


* GPItv enhancements and bug fixes:

  * Added gpitv_startup_dir as user configurable setting. (Savransky)
  * Bug fixes in GPItv autoscaling. (Ingraham)
  * Fixed rotation of polarization vectors. (Millar-Blanchaer, Wang)
  * Added high-pass filter for polarization mode. (Wang)
  * Added 'Total Intensity' cube collapse option for polarization pair files. (Perrin)
  * Fixed rotation of pointing data along with image. (Wang)
  * Fixed toggling between contrast and native units. (Maire)
    
* Documentation 

  * Added the AA_README file that gives the pickles indices. (Ingraham)
  * Added documentation for automated install scripts. (Wang)
  * Added Known Issues page, more screen shots, general documentation tuneup for V1.0. (Perrin)
  * Added summary of software licenses. (Perrin)

* Miscellaneous bug fixes and minor tasks:

  * Many minor bugs fixes. (Ingraham, Maire, Millar-Blanchaer, Perrin, Savransky, Wang, Wolff)
  * Cleanup and re-organization of pipeline dependencies. (Perrin, Ingraham, Marie, Savransky)
  * Cleanup of headers in utils and pipeline_deps. (Maire, Perrin, Savransky, Ingraham). 





Version 0.9.4
=========================================
Released 2014 Jan 7

This version was released at the January 2014 AAS meeting. This was the
first version of the pipeline advertised to the wider community.  

This version includes extensive enhancements and lessons learned during and after GPI first light in November 2013. 

* New Primitives:

  * KLIP ADI with Forced Center - workaround for cases of low S/N satellite spots not being properly detected (Savransky)
  * Quality Check Wavecal - check for various potential defects based on spatial derivatives of wavecal (Perrin)
  * Interpolate Bad Pixels in Cube - heuristic/statistical outlier detection and interpolation. 
  * New primitives for background subtraction in cube space. (Ingraham)
  * New primitives for correction of lenslet throughput variations (Perrin)

* Enhancements to existing primitives and recipes: 
  
  * Much improved satellite spot location for on-sky data (Savransky)
  * Merged the single-threaded and parallelized versions of "2D Wavecal Solution" into a 
    single primitive with optional parallelization (Wolff, Perrin)
  * 2D Wavecal peak fitting algorithm and line lists updated to improve performance on Argon lamps; 2D Wavecal output and saving of model image reimplemented (Perrin)
  * Further wavecal routine improvements (Wolff, Ingraham)
  * Updated some recipes and default arguments (Ingraham)
  * Improved destriping for science images (Ingraham)
  * Updated algorithm for gravity-induced flexure lookup table (Maire)
  * Added adjustible thresholds for hot and cold bad pixel detection primitives.  (Perrin)
  * "Add missing keyword" primitive now lets you set the keyword's variable type.
  * Polarimetry mode primitives updated (Millar-Blanchaer, Perrin)
  * Fix for incorrect sign in waveplate rotation Mueller matrix calculation (Millar-Blanchaer)
  * New polarimetry mode box extraction algorithm (Perrin)
  * Implement Sigma Clipping algorithm for 2D image combination for darks, science data, flats, etc. (Perrin)
  * LOCI primitive updates (Maire)

* Pipeline infrastructure:

  * Improved parallelization utility routines (Perrin, Ingraham)
  * Improved propagation of DQ and/or VAR extensions through the pipeline (Perrin)
  * Datacube min/max extracted wavelengths updated to filter 10% transmission wavelengths (Maire)
  * Several new wavecal-related utilty routines; utility routine for manual pixel editing of bad pixel files (Perrin)

* Recipe Editor, Data Parser, Autoreducer GUIS: 

  * Continued improvements to Recipe Editor following the major overhaul in 0.9.3. Improvements in user interface, 
    file handling, ability to manually select calibration files, autogenerated recipe paths and filenames, 
    several small fixes, and more. (Perrin, Savransky, Ingraham, Wolff)
  * Autoreducer auto starts, configures, and updated  files wildcards properly if at_gemini==1. (Perrin)
  * Bug fix Data Parser confusion arising from mixed Engineering and Science mode FITS files. (Perrin)
  * Improved FITS keyword display for FITS files listed in Recipe Editor or Data Parser GUIs. (Perrin)

* GPItv enhancements and bug fixes:

  * Major overhaul of image rotation and inversion code. (Perrin)
  * Improvements/fixes to "retain current view" option to properly handle flipped and rotated images, and to accomodate changing between images of different sizes, and more. (Savransky, Perrin)
  * Try to retain image display units if retaining image stretch. (Perrin)
  * Interative shift adjustment added to wavecal overplot dialog, and wavecal overplot shows full spectral ranges (Perrin)
  * Better display of GCAL-specific header info such as lamp names and ND filters. (Perrin)
  * GPItv contrast plot also estimates stellar magnitude (Sadakuni, Ingraham)
  * Better updates and raising of child plot windows, either when explicitly reinvoked or when new image loaded (Savransky)
  * Browse Files GUI cleanup and removal of deprecated code (Perrin) and various minor improvements to Browse Files display of images and cubes (Ingraham, Perrin)

    
* Documentation 

  * Updated tutorial to use on-sky data (Ingraham). 
  * More answers for FAQs (Ingraham, Perrin)
  * Updated/clarified installation instructions (Ingraham, Perrin)
  * Extensive improvements to Developer Documentation (Perrin)

* Source code housekeeping:

  * Removed various deprecated or unused routines.  (Ingraham, Perrin, Maire)
  * IDL 7 compatibility fixes (Ingraham)
  * Replace Keck jargon 'DRF' with Gemini jargon 'Recipe' in GUIs and some code internals.

* Miscellaneous bug fixes and minor tasks:

  * Many minor bugs fixed and algorithms tweaked during first light. (Savransky, Ingraham, Maire, Wolff, Perrin)
  * Updated defaults for some pipeline settings
  * More careful handling of the Gemini YYYYMMDD date string rollover at 2 pm Chilean local time. (Savransky, Perrin)
  * Updated the included Pickles spectral library files to the STScI updated normalized files. (Ingraham)
  * Support HL coronagraph in config files, and update code to allow NRM mode as well. 
  * Misc logging and error reporting enhancements. 

 





Version 0.9.3
=========================================
Released 2013 Nov 12

This version was released for GPI first light at Gemini South. This includes
updates and enhancements based on testing at Gemini in September and October 2013.


* New Primitives:

  * New and improved "2D Wavelength Solution" (a.k.a. "Wavecal 2.0") algorithm,
    which works by fitting a forward model to the lenslet spectra pixels
    directly in 2D, rather than measuring each peak sequentially then fitting a
    line in 1D.  This algorithm is demonstrably more robust, more precise, and
    better able to handle overlapping adjacent spectra and various noise
    sources than the original algorithm.  A prior wavecal from the Calibration
    Database is used as a starting guess for each fit rather than starting from
    zero a priori knowledge each time, Further improving robustness.  Extensive
    testing has shown this new algorithm is strictly better than the old
    algorithm (which is retained in the pipeline still as an option in any
    case) in every respect except for being slower. Two versions of this
    algorithm are provided, one which is single threaded and a parallelized
    implementation for use on multi-core machnes. (Wolff)
  * Derived primitive "Quick Wavelength Solution Update" based on the above, which only fits
    every ~400th lenslet (adjustible) and then applies an appropriate average
    bulk shift to the best available prior wavecal from CalDB. This provides an ability to 
    generate "Quicklook" quality wavecals in very short run time (Perrin & Wolff).
  * New ADI KLIP primitive, "KLIP algorithm Angular Differential Imaging". (Savransky)
  * New primitive "Flag as Quicklook" that sets a QUIKLOOK=True FITS header
    keyword in output files. (Perrin)
  * New primitive "Create Symbolic Links" for those times when you really want to make
    it looks like one file is being written to two different places.  Only works on
    POSIX compliant operating systems, e.g. Mac OS and Linux. 
  


* Pipeline infrastructure and enhancements to existing primitives: 

  * SDI KLIP algorithm performance dramatically sped up by about 3-4x.  Updates to accumulate_images framework
    to allow retrieving images slice by slice. 
  * Now will detect if the pipeline is about to overwrite an existing output file, and
    (depending on the value of a new file_overwrite_handling setting) either prompt the user what should be done, 
    overwrite it, write the new file to a different output name, or don't write anything at all but raise an error. (Perrin)
  * Adds DATALAB keyword support and swap to underscores for suffixes. Closes issue 311
  * Implement scaling for dark subtractions with non-identical exposure times of science images and the reference darks;
    closes action 173 from Pre-Ship Review Report.
  * New utility function gpi_sanity_check_wavecal provides quality checks on
    derived wavelength calibrations. 
  * Polarization spot position measurement primitive parallelized for much improved speed.
  * Improved update_wcs_basic command that does precise calculations of AVPARANG and MJD-AVG
  * Define a new pipeline setting "at_gemini", which enables several small adjustments
    in file paths and wildcards suitable for the case of the pipeline running integrated into the
    Gemini network on Cerro Pachon. If you're not one of the observatory computers on the summit, this is not expected to be of use to you. (Perrin)
  * New utility function gpi_get_ifs_lenslet_scale for consistent calculations everywhere (Savransky)
  * Updated accumulate_getimage to optionally return single slices (Savransky)
  * Improvements to the Recipe class (DRF) internal implementation. (Perrin)
  * Infrastructure and tools in preparation for eventual next-generation data cube extraction algorithm (Ingraham)
  * Updated handling of sat spot locations in header.
  * Updated WCS handling with proper coordinate rotation as determined prior to being on sky. (Perrin, Thomas, Chilcote, Savransky)

* Recipe Editor, Data Parser, Autoreducer GUIS: 

  * Major revision/refactoring of Recipe Editor code. Now uses Recipe class internally for improved abstraction and better overall
    code clarity and ease of long term maintenance.  While the GUI has not changed substantially, this was a
    major overhaul to the internals of this tool. (Perrin)
  * 

* GPItv enhancements and bug fixes:

  * Add display of the mean stellar position across all wavelengths to the Star Position plot. (Perrin)
  * Bug fix sign error for Rotate North Up; add WCS existence check for auto-handedness function
    
* Improved documentation and installation guide (Ingraham, Perrin). 

  * New FAQ section in the docs (Ingraham)

* Source code housekeeping:

  * Subversion repository reorganized to use standard "trunk", "tags", "branches" directories. (Perrin)

* Miscellaneous bug fixes and minor tasks:

  * 2D plotting should reuse an existing IDL graphics window by default if possible.
  * Remove obsolete user-changable suffixes feature.  (Perrin)
  * improved handling for absolute path specs in the middle of a filename string
  * Improved logging in several places. (Perrin)
  * Clean up of deprecated code (Ingraham)
  * Better error message text for read only versus missing output directories (Perrin, Ingraham?
  * Removed all direct use of CDELT1 & CDELT2 keywords - everything is now handled through extast and getrot. Addressed bug 325. (Savransky)
  * Various minor bug fixes, typo corrections, and other small stuff.  (Perrin, Ingraham, Savransky)






Version: 0.9.2 
=========================================
Released 2013 Sept 5

This version was  
released for the start of GPI integration at Gemini South. It 
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


