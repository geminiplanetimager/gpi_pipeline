Calibration Database
########################

.. _caldb-devel:

Rules for Matching Files
=============================

When you request a calibration file, the first step is to select all
calibration files of a given type (for instance, all darks, or all wavelength
calibrations). Once it has that list, it has to restrict to a subset of
applicable calibration files. This happens based on FITS keywords, as follows:

*	Darks match on ITIME and IFS Readoutmode
*	Wavecals, flats, polcals, instrumental polarizations, telluric transmissions all match on IFSFILT and DISPERSR
*	Spot location and grid ratio match on Filter only. 
*	Bad pixel maps, pixel scale, distortion measurements all match only on calibration type. 

That selection yields a set of calibration files of the appropriate type (for
instance, all H-band spectral wavelength calibrations). 

Because the instrument configuration or detector properties can change
significantly whenever you warm up the IFS, by default we then restrict our
consideration to only calibration files taken from the same cooldown run as the
science data. That is, any calibration files from before the start of that
cooldown or after the start of the next cooldown will not be considered. The
list of cooldowns is maintained in a file in the pipeline configuration
directory. 

Then from the subset of available files, you have to select the best one. The logic for that is as follows:

1.	Find the closest-in-time calibration to the science data. Once you know the filename and date of that calibration file, check to see if there are any other calibration files in the selected subset with times within ±12 hours of that closest file.  

        a.	If there is only one such file, return it as the best calibration.
        b.	If there are several such files, proceed to step 2.

2.	From all the selected files within that date range, find the one that has the maximum integration time. 

        a.	If there is only one such file, return it as the best calibraiton
        b.	If there are several files with identical exposure times, proceed to step 3.

3.	From all the selected files in that date range with the max exposure time, return the single file which is closest in time. 


This is kind of convoluted but in practice should do a fairly robust job of
automatically identifying the most appropriate calibration file in almost all
circumstances. And remember, users can always manually select calibration files
as well. 
