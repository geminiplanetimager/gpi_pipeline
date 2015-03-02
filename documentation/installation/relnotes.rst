
.. _release-notes:

Release Notes
###################

You may wish to skip ahead to  :ref:`configuring`.  

The next release of the GPI pipeline will probably be sometime September-ish after the final commissioning run, for use in 2014B. 

Version 1.3
=========================================
Released 2015 March, for Gemini 2015A


.. note:: 

    Prior versions of the pipeline have been subject to some biases in parallactic angle calculation 
    for targets that transit very close to zenith, for whcih the field rotation rate gets up to several degrees per exposure. 
    This version of the pipeline more carefully compensates for the time offset between FITS header writing 
    and the midpoint of the frame exposure time, and as a result yields more accurate astrometry for exposures very close to zenith. 
    We recommend reprocessing earlier data with this current version of the pipeline if your target passes within 5-10 deg of zenith. 


.. note::

    The Calibration Database now indexes some additional fields, in particular telescope elevation which is now used when matching
    wavelength calibration files. As a result, after upgrading to version 1.3 of the pipeline you **must** rescan 
    the calibration database to reindex the database, or the pipeline will not operate properly. 
    Just press the "Rescan Calibration Database" button in the Status Console after you have updated and restarted pipeline. 

 
* Enhancements/Additions to primitives and recipes:

  * Remove Persistence primitive algorithm improvements to better handle UTR mode and coadds.  (Ingraham)
  * Remove Persistence primitive gains keyword parameter to manually override the end time of the previous exposure, if necessary. (Ingraham)
  * updated contrasts in GPITV and the Measure Contrast to use precisely the same algorithm for individual slices. Also modified the plotting 
    colors and labels for clarity. Also updated default slice in Measure Contrast changed plot legend to make it easier to read. (Ingraham)
  * New primitive "Save Accumulated Stack" to save all images at once in a batch, for instance after PSF subtraction. (Millar-Blanchaer)
  * Updates to high pass filtering in quicklook spectral recipe (Ingraham)
  * Bug fix to "Interpolate Bad Pixels in 2D frames" to avoid dividing by zero causing NANs in final image products under some circumstances (Wolff).
  * Improved algorithm for "Correct Distortion" primitive that conserves flux when resampling (Fitzgerald, Konopacky). 
  * For "Quick Wavelength Solution", better constrained the allowed x/y shifts in the initial cross correlation of old and new wavecals. (Wolff)
  * Added error checking for suitable input files to "Flexure Cross Correlation with Polcal" (Millar-Blanchaer)
  * Updated "Contrast Measurement" recipe template to measure contrast from all wavelengths (Follette)
  * Algorithm improvement to "Combine 2D Dark Images" for better read noise estimation on coadded images (Follette)
  * Added keywords to "Subtract Mean Stellar Polarization" to allow fine-tuning the region used for estimating stellar polarization. (Hung)
  * Updated parallelization options to "Filter Datacube Spatially" (Ingraham)
  * New recipe to make low-frequency filtered flat fields in polarization mode. (Millar-Blanchaer)



* Enhancements to instrument characterization

  * Improved algorithms for calculating time-averaged parallactic angles very near zenith, where fields are very rapidly rotating. 
    Provides improved astrometric precision for exposures on objects transiting near zenith as noted above. (Nielsen)
  * Rotation matrices for World Coordinate System headers and other uses are now all derived from 
    AVPARANG (the time-averaged parallactic angle over the course of the exposure computed by this pipeline)
    instead of PAR_ANG (the instantaneous parallactic angle at the time when the Gemini Data System saved state 
    for the FITS header, several seconds before the exposure actually started). (Nielsen)


* GPItv enhancements and bug fixes:

  * New "Create SNR Map" option added to cube display drop-down menu. This normalizes the displayed image by the measured contrast curve, with the goal of making point sources equally visually apparent on a single image stretch regardless of separation from the central star. Note this is a quick convenience mode only, and is not intended as a publication-quality assessment of the significance of any particular detection!  (Ingraham)
  * Low pass filter option added to enable smoothing of background noise. Select "Low Pass Filter" option from the cube display drop-down menu. Right now the low pass filter size is hard-coded to use the typical GPI PSF FWHM for each of the filters. (Ingraham)
  * Avoid displaying unnecessary flexure plot when overplotting wavecals in GPItv (Ingraham)
  * Updated the gpitv contrast plot to display the wavelength of the slice when only one slice's contrast is plotted. (Wolff)
  * New display mode for Q and U Stokes parameters normalized by total intensity (Millar-Blanchaer)
  * For at Gemini South, fix Browse Files window's buttons for "Today's Raw Data" and "Today's Reduced Data" (Ingraham)
  * For at Gemini South, fix GPItv file dialogs to avoid trying to list the tens of thousands of files in the /dhs/perm directory. 

* Recipe Editor, Data Parser, Autoreducer GUIs: 

  * Data Parser code split in two (parsergui for the widget user interface, parsercore for the actual recipe generation logic), to better enable the
    data parsing algorithms to be called as a subroutine from other codes. See example code in parsercore__define for usage. Added infrastructure 
    classes for file sets and added functionality to Recipe/DRF class to support this. (Perrin)
  * Data Parser now also outputs Low Frequency Flat Field recipe for polarization flats (Millar-Blanchaer)
  * Bug fix for an unusual edge-case issue with FITS keywords when loading reduced files from the Calibrations directory directly into the Recipe Editor (Ingraham)
  * Autoreducer options for manually adjusting wavecal position now can also be used to adjust polcals (Millar-Blanchaer)
  * Improvements to Recipe Editor GUI to better display template names when opening existing recipes, and generally improve the user interface for selecting a new recipe template (Savransky)

* Infrastructure improvements

  * Improved calibration database algorithm for selection of wavecal to choose wavecals that are closest in both
    time and telescope elevation, preferring the quick wavecals taken just before each science sequence (Wolff). 
  * Added detector linearization calibration file type to Calibraton DB

* Improved documentation and tutorials

  * Additions to FAQ: Answer question about pipeline log problems due to IDL license server issues (Perrin)
  * Added documentation for new Save Accumulated Stack primitive (Millar-Blanchaer)
  * Updated recipe editor docs to reflect UI changes (Savransky)

* Miscellaneous bug fixes and minor tasks:

  * GPITV's Browse Files window does better at ignoring non-GPI files (Ingraham) but will still open GPI pupil viewer files that lack INSTRUME keyword anyway (Perrin)
  * Better error checking for update_prev_saved_fits_header functionality in Measure Sat Spots Location, Flux, and Contrast primitives (Perrin)
  * Typo bug fix in gpi_extract_1d_spectrum (Ingraham)
  * Minor fixes to Wavelength Solution code output error messages and warnings. Improved error handling in wavecal algorithm utility functions. (Wolff)
  * Now correctly computes average parallactic angle in the rare case that UT midnight occurs during the exposure, as well as the even-rarer 
    case where UT midnight occurs in the 3 seconds after the FITS header is written but before the exposure starts. (Nielsen)
  * Bug fix for use of shared memory in Parallelized Polarization Spot Calibration (Millar-Blanchaer)
  * Deprecated the gpi_assemble_datacube wrapper primitive; use Assemble Spectral Datacube or Assemble Polarization Datacube instead. 
  * Removed old deprecated test* primitives, left over from pre-first-light pipeline development. Removed old deprecated primitives with 
    alternate algorithms (not recommended, from pre-first-light) for telluric calibration, photometric calibration. (Ingraham, Maire)
  * Fix spelling mistakes in a few primitives (Ingraham)
  * Added parallelized version of high pass filter algorithm, which can save a few seconds in some circumstances for GPItv or 
    Filter Datacube Spatially primitive (Perrin). But also avoid trying the parallelized version at the Gemini South summit since the IDL license
    server there is very slow to start parallel sessions so it's actually slower  (Perrin). 

* Other

  * GPItv gained a GPIES-campaign specific tool for marking file status (good/bad) and adding comments to the GPIES campaign database (ImageInfo menu, "Mark File Status"). This option will do nothing and be quietly ignored for users who do not have GPIES-campaign Dropbox access.  (Savransky)



Version 1.2.1
=========================================
Released 2014 December 2. 

This is a minor bugfix release for v1.2.0 based on testing from Kathleen Labrie at Gemini and input from the Gemini community. 

* Improved the installation scripts (Perrin)
* Updated data reduction Tutorials (Millar-Blanchaer, Wolff, Ingraham)
* Added error handling in primitives to ensure no parallelization is invoked when using the runtime (Perrin, Ingraham, Millar-Blanchaer, Wolff)
* More robust polarization spot calibration code in the presence of uncorrected hot pixels (Millar-Blanchaer)
* Improved boundary checking in gpi_destripe_science_image primitive (Ingraham)
* Added a missing utility (gpi_lsqr_mlens_extract_dep.pro)


Version 1.2.0
=========================================
Released 2014 October 31. 

This release incorporates updates and enhancements for 2014B. Thanks to the users in 2014A and members of the GPI and Gemini team who contributed improvements.

.. note:: 

      The World Coordinate System calibration for GPI was updated in accordance
      with the results of Konopacky et al. (2014). This changes the pixel scale
      and orientation of north that are written into datacube FITS headers. Datacubes
      reduced with the current version of the pipeline should have more
      accurate orientations than prior versions. However, please bear in mind
      that if you compare datacubes reduced with older versions of the pipeline
      to datacubes reduced with the new one, you may find a spurious offset in position angle 
      or separation.  Users should take care and perform their own calibrations when
      doing high precision astrometry. 



* Enhancements/Additions to primitives and recipes:	
  
  * New primitive: "Correct ADR Shift" applies a software correction for atmospheric differential refraction (ADR).
  * New primitive: "Filter Datacube Spatially" applies high pass filter to datacubes, similar to the GPItv display option.
  * New primitive: "Flexure 2D x correlation with polcal" uses cross correlation to automatically derive flexure corrections for polarimetry mode.

  * Destriping for Darks primitive now preserves the mean bias level of reduced dark files, to better subtract that bias from science images. Dark generation and hot pixel identification primitives updated for compatibility. (Perrin)
  * Distortion correction primitive can now work either before Accumulate Images (undistorts one image at a time) or after it (undistorts all previously accumulated images) (Perrin)
  * Update Spot Shifts for Flexure gains a new mode, "bandshift", which takes into account the known offsets between spectral bands to calculate a flexure-corrected wavelength solution for any filter based on H band argon lamp images. (Wolff)
  * Update Spot Shifts for Flexure also now can apply spatially-variable offsets across the field of view, to account for the second order flexure correction.
  * Improvements in wavecal solution code to accomodate microlens PSF option as well as Gaussian PSFs. Improvements to smooth and filter the derived wavelength solutions to improve S/N and better handle lenslets at edge of FOV. (Wolff)
  * Improvements to Sat Spot measurements in polarization mode (Wang, Millar-Blanchaer)
  * Subtract Stellar Polarization primitive uses star position from sat spots. Can also be applied to a single polarization datacube (podc file) instead of Stokes datacube (stokesdc file).  (Millar-Blanchaer). 
  * Significant improvements to detector persistence model and persistence correction (Ingraham).
  * Improved polarization datacube extraction using empirical Gaussian model lenslet PSFs for weighted extraction (Millar-Blanchaer, Fitzgerald)
  * Algorithm improvements to photometric calibration calculation. (Ingraham)
  * Measure Satellite Spot Locations now writes PSFC_x header values to the SCI header for *each slice* where sat spots were found (Savransky)

* Enhancements to instrument characterization

  * Updated zero point fluxes in pipeline_constants to values calculated using the instrument response curves and not the filter profiles - differences are very minor (Ingraham).
  * Updated plate scale and rotation angle in accordance with the measurements of Konopacky et al. (2014, Proc. SPIE).

* GPItv enhancements and bug fixes:

  * Minor bug fix to histogram window (Perrin)
  * GPItv display of wavelength solution has gained a mouse mode enabling dragging the solution around interactively. This updates the dx and dy parameters displayed in gpitv, which can then be copied into the autoreducer or recipe editor for use when creating datacubes. (Wolff)
  * For polarimetry files, GPItv can now compute and display radial stokes vectors, and also a normalized differences display (Millar-Blanchaer).
  * GPItv contrast plot display bug fix for cases with small Y axis range (Nielsen)

* Recipe Editor, Data Parser, Autoreducer GUIs: 

  * Data parser ignores aborted files (Perrin)
  * Substantial speedup to data code parser code. Also bug fix to avoid major slowdown when working on fits.gz files.  (Perrin)
  * Data parser now lets you select, queue, or delete multiple recipes at once. (Perrin)
  * Autoreducer GUI now displays options for the improved flexure correction in Update Spot Shifts.  (Wolff)
  * Autoreducer no longer makes unnecessary datacubes for darks, or for persistence cleanup frames after calibration lamps. (Perrin)
  * More informative error messages in Recipe Editor (Wolff)

* Improved documentation and tutorials

  * Clarified and simplified installation instructions (Wang, Long, Ingraham, Perrin)
  * Improved tutorials for spectral and polarization reductions (Wolff, Millar-Blanchaer, Long, Savransky, Nielsen)
  * New tutorial on reducing your own GPI data (Perrin, Hibon, Wolff)
  * New tutorial on spectrophotometric calibration and companion spectral extraction (Ingraham)
  * Documentation links to papers by the GPI team presented at the SPIE meeting (team)
  * Added helpful error messages and a line in the pipeline settings documentation about how to work around a rare bug with semaphore locking (Wang)
  * Updated documentation for several of the new features listed above (team)

* Installation and infrastructure improvements

  * Backend process improvements for building compiled versions (Wang, Perrin)
  * IDL7 compatibility bug fix in contrast measurement code (Maire)
  * Improved Windows installation script and instructions (Wang)

* Miscellaneous bug fixes and minor tasks:

  * Precision improvement bug fix in calc_avparang. (Maire)
  * Minor bug fixes to wavelength solution code. (Wolff)
  * Minor bug fix to Data Parser's Gemini data label parsing code. (Perrin)
  * Autoreducer no longer automatically starts at Gemini (Perrin, Hibon)
  * Bug fixes for startup directory for gpitv and other GUIs.  (Wang, Perrin)
  * Improvements in 2D detector + photon noise model code for estimating per-pixel S/N. (Fitzgerald)
  * Clean up some obsolete templates (Perrin)
  * Minor bug fix in combine_3d_datacubes primitive and calibrate_photometric_flux (Ingraham)
  * Added NaN support for mean combine images (Wang)
  * Some recipe templates updates to reflect changes in the primitives (Wang)
  * Improve robustness of CalDB (Wang)
  * Improve plotting tools in extract_one_spectrum (Wolff) 
  * Minor bug fixes in get_spectral_response (Ingraham)
  * Minor bug fixes in handling of files taken with the GPI IFS in its unsupported engineering-only subarray mode (Perrin)
  * Minor bug fix to PNG plotting in contrast measurement tool (Wolff)
  * Datacube assembly code made more robust against unexpected input values (Wolff)
  * Rotate Cube North now updates satellite spot positions correctly (Ingraham)


* Other

  * Continued development of next-generation datacube reconstruction algorithms (Ingraham, Maire, Draper, Wolff). These are not yet ready for production use and are not yet included in this release; however substantial progress is being made. Stay tuned for future pipeline releases. 

Version 1.1.1
=========================================
Released 2014 May 7. 

This is a minor bugfix release for v1.1. 

* Fix typo in gpi_destripe_science_images that was causing recipes to fail. 
* Also some other minor changes: 
  
  * URL and zip file updates for tutorial dataset files (Millar-Blanchaer, Marchis, Perrin). 
  * Add 'None' mouse mode option to gpitv (Fitzgerald).  
  * Remove obsolete persistence model file (Ingraham) 
  * Compiler should not output nonfunctional Mac OS .app bundles (Draper)
  * Improved installation documentation and gpi-pipeline script for compiled version (Perrin)



Version 1.1.0
=========================================
Released 2014 May 1. 

This version was released in support of the GPI Early Science shared-risk observing programs by the community in 2014A. It includes a range
of enhancements and fixes made during the ongoing commissioning observing runs, including in particular substantial updates to polarimetry mode support. 

.. comment:
    The following should summarize everything significant in commits from 2564 (release 1.0) through to current


* Updates for polarimetry mode:

  * Polarization waveplate angles offsets, coordinate system signs, and Stokes vector position angles all straightened out. Polarization reductions 
    now yield position angles in output files which are oriented in the usual astronomical convention of starting with 
    Stokes +Q = north. (Millar-Blanchaer)
  * Added new primitive "Clean Polarization Pairs via Double Difference" to debias polarization pairs by subtracting the median single difference bias between pairs. (Perrin)
  * Added new primitive "Subtract Mean Stellar Polarization". (Perrin)
  * Added new primitive "KLIP ADI for Pol Mode" to create total intensity disk images from polarimetry data. (Millar-Blanchaer)
  * Improvements to satellite spot handling and star position measurements for polarimetry mode. Improved stability of locating star center by setting a lower threshold in pixel value. (Wang)
  * Improved polarization mode recipe templates (Millar-Blanchaer, Perrin)
  * Lenslet coordinates in polarimetry mode match spectral mode. (Millar-Blanchaer)
  * Update "Update spot shifts for flexure" to work in polarimetry mode (Millar-Blanchaer)
  * Many bug fixes and minor updates to polarimetry primitives. (Millar-Blanchaer)
  * Improved GPItv polarimetry display; see notes in GPItv section below. 

* Enhancements/Additions to primitives and recipes:	
  
  * Added new primitive "Smooth a 3D Cube". (Millar-Blanchaer)
  * Improvements to "Calibrate Photometric Flux" primitive. (Ingraham)
  * Improved background subtraction in "Extract 1D Spectrum" (Ingraham)
  * Update to "Destripe Science Image" (Ingraham)
  * Update "wavelength solution 2D" primitive for parallelization, and for use of microlens PSFs; see note below. (Wolff) 
  * "Subtract Dark" can interpolate between dark frames taken before and after an observation. (Perrin)
  * "Destripe for Darks Only" algorithm improvements to preserve overall detector bias levels in darks, so they subtract better in science images. (Perrin)
  * Contrast profiles can be written to TXT files and FITS tables. (Savransky)
  * "Rotate North" primitive can be applied either before or after Accumulate Images. (Perrin)
  * Improved performance of locating satellite spots in spectral mode. Now can add satellite spots separation constraint. (Ingraham, Savransky)
  * Updates to inserting fake planets into cubes. (Ingraham)
  * "Rotate North" has a new option to pivot around the star location or not. Also now saves rotation angle in extension header (Millar-Blanchaer)
  * Parameter updates to default recipes. (Millar-Blanchaer, Savransky)


* Pipeline infrastructure

  * Added infrastructure code to allow primitives to modify images that have been stored by Accumulate Images. 
    This allows some primitives that work on individual images to work either before or after Accumulate Images. If before, 
    the primitive will act on each image one at a time. If after, the primitive will loop over all
    accumulated images in a row. (Perrin) 
  * Minor reordering of default order of primitives. (Perrin)
  * Fixed bug in Windows when encountering symlinks. (Maire)
  * Install script will warn but allow aliased IDL commands. (Wang)
  * Added new utility function, `get_spectral_response` to return measured spectral throughput in both direct and coronagraphic modes. (Maire)


* Recipe Editor, Data Parser, Autoreducer GUIs: 

  * Autoreducer should ignore non-GPI FITS files (Perrin)
  * Autoreducer should recognize arc lamps and run Quick Wavecal recipe template.  (Perrin)
  * Autoreducer should recognize and ignore "cleanup frames", which are throwaway frames taken 
    to allow for persistence decay between different lamps. (Wolff, Rantakyro, Perrin)
  * At Gemini, Autoreducer should now automatically change directories for different dates. (Perrin)
  * Data Parser should also ignore cleanup frames (Wolff, Perrin)
  * Data Parser and Recipe Editor get improved filenames for saving recipe files. (Perrin, Wolff)
  * Better handling of errors to mitigate GUI crashes and other unresponsive behavior. (Wang)
  * Added 'File | New' menu option in Recipe Editor to make new blank recipes. (Savransky)
  * GPI Launcher will bring to the front any existing window if you click the corresponding button. (Perrin)

* GPItv enhancements and bug fixes:

  * Overhaul of polarization vector plotting. Improved display options, more intuitive vector 
    behavior on image zooms, can display either polarized intensity or polarization fraction. (Perrin)
  * Improved UI for selecting wavecal/polcal files. (Perrin)
  * Added behavior to discard current polcal/wavecal when switching to a new file. (Perrin)
  * Fixed bugs that prevented viewing of temporary data and headers in certain cases. (Wang)
  * SDI settings for spectral cube collapsed display are now a menu item under Options, for consistency with other GPItv settings. (Savransky)
  * Better FITS metadata display for lamp cleanup frames, which are flagged using the ND4 filter.

* Documentation 

  * Improved installation documentation (Wang, Perrin)
  * Updated Tutorial documentation. (Ingraham)
  * Added polarization data reduction tutorial. (Millar-Blanchaer)
  * Updated Step-by-step data reduction pages (Wolff, Ingraham, Wang, Perrin)
  * FAQ updates (Perrin)

* Miscellaneous bug fixes and minor tasks:

  * Many minor bug fixes. (Ingraham, Maire, Millar-Blanchaer, Perrin, Savransky, Wang, Wolff)
  * Some refactoring and reorganizing routines. (Perrin, Wolff)
  * Fix nonfunctional 'Remove File' button in Recipe Editor and Data Parser GUIs. (Rajan, Perrin)
  * "Measure Distortion" primitive was disabled since distortion correction is a lab calibration rather than routine on-sky task. (Maire)
  * Better error handling in gpitv if flexure shifts lookup file not present (Ingraham)
  * Better edge case handling in gpitv if sat spot positions are recorded in the 
    FITS header but fluxes are not (Wang)
  * Minor fixes to 'Destripe Science Image' primitive. (Ingraham)
  * In /nogui mode, Rescan CalDB shouldn't try to update nonexistent Status Console window (Perrin)
  * Fixed bug for output directory path for saved contrast profiles. (Savransky)
  * Fix logging bug if running the pipeline in single-recipe mode (Ingraham)
  * Improved code clarity and variable names in wavelength solution primitive, remove redundant double save of the output file. (Wolff)
  * Fix datestring bug for engineering mode ("E" filename) FITS files (Savransky)
  * Path cleanup for install: remove hard coded filter paths, add trailing slashes unformly for consistency across unix systems (Ingraham, Wang)
  * Minor debugging: remove some debug print statements, code cleanup, etc. (team)
  * Updated pipeline constants. (Perrin, Ingraham) 
  * Better filename handling, parsing, and creation. (Millar-Blanchaer, Perrin, Wang, Wolff)
 

.. admonition:: Advertisement: SPIE talks on GPI Data Pipeline 

 Want to learn more details on how to calibrate and reduce GPI data? The GPI data pipeline, its algorithms, and 
 calibrations for the instrument will be discussed in detail in 13 presentations at the SPIE meeting this summer. 

 In addition to the changes listed above, many code commits were made relevant
 to new primitives for the creation and use of high-resolution subpixel sampled
 microlens PSF models. These algorithms are not quite ready for prime time
 yet and are not included in the public release. Stay tuned for 1.2 this fall, and/or see the
 presentations by Ingraham,  Draper, and Wolff at the SPIE this summer. 


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


