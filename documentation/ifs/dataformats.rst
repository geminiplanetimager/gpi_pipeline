GPI Data Formats
===================


Multi-Extension FITS format
----------------------------

GPI raw and reduced files are Gemini-style Multi Extension FITS
("MEF") files. The primary HDU contains only a header; image data is always
stored in a first image extension named "SCI". Optional extensions for
uncertainty estimates ("ERR") and data quality flags ("DQ") may be present. 

* The data quality extension "DQ" is present on all raw files since July 2012.

* The uncertainty image extension remains turned off at this time. In practice,
  for high contrast imaging, reliable sensitivity estimates should be computed
  by inserting mock point sources into data, not relying on error propagation
  using an ERR extension.

FITS keywords are split between the primary header (for keywords about overall instrument state) and the image extension header (for keywords about the IFS detector readout and image data contents), again in keeping with Gemini standards.


Main Image Extension "SCI"
------------------------------

This is where your science data is. For a raw frame, it's a 2048x2048 float
array. For most reduced data products, it will be some other format, typically a
datacube. Units of raw data are by default *total counts per coadd for that exposure time*, not
counts/second. Units will always be identified in the BUNIT keyword.

Data quality flags extension "DQ"
------------------------------------

This extension will contain a 8-bit integer flag for each pixel in the
main image array. Their meanings are as follows for 2D detector images. Bits
0-4 are written by the IFS detector readout software. Bit 5 may be written by the data
pipeline, which can also modify bit 0.


* bit 0: bad pixel, do not use if set. Values initially marked by bad pixel
  mask in detector server 
* bit 1: raw pixel (read from detector) exceeds
  saturation value (specified in configuration file)
* bit 2: pixel value difference between consecutive reads exceeds saturation
  value 
* bit 3: maximum delta for pixel removed during UTR calculation 
* bit 4: minimum delta for pixel removed during UTR calculation 
* bit 5: [work in progress] flagged as bad pixel by data pipeline using 
  time-dependent bad pixel map from calibration database.

Bits 3 and 4 are a bit complicated, but have to do with calculating up-the-ramp (UTR) slopes. In
order to remove glitches like cosmic ray hits, if the difference between UTR
samples for a pixel exceeds a specified amount, the difference is removed from
the UTR calculation. Only the largest jump in either direction is removed. Bits
3 and 4 indicate if this has happened. This only can occur if there are more
then 3 UTR samples (groups).

Pixel which have bit 5 set to 1, but bit 0 set to 0 (indicating "usable pixel"
but also "flagged as bad pixel by pipeline") indicated the common case of bad
pixels being detected and then repaired by interpolation based on neighboring
pixel values.



Types of GPI IFS Files
--------------------------

There are many different types of GPI data files. The type of a given file may
be indicated by the FILETYPE keyword.

.. note::
        Insert here table of possible file types and FILETYPE keyword values, and typical filename extensions





FITS Keywords
-----------------

See documentation in Fredrik's official document SCI-OCS-GPI-SRD.doc, or
(perhaps more conveniently) in the copy maintained in the GPI FITS Keywords
spreadsheet in the data team shared folder.

For reduced data cubes, the wavelength solution is given by the 3rd WCS axis:
CTYPE3, CUNIT3, CCRPIX3, CRVAL3, CDELT3, in compliance with the FITS standard,
specifically Calabretta et al. 2002 "Representation of Spectral Coordinates in
FITS", available from http://fits.gsfc.nasa.gov/fits_wcs.html .

It's actually just the same equation as for RA or Dec in the simplest case:

wavelength = CRVALx + CDELTx*(pixel coordinate ? CRPIXx)

For polarimetry datacubes, the FITS convention for polarimetry is given in
Griesen et al. 2002, "Representation of World Coordinates in FITS". GPI files
comply with that standard.


Time Formats in FITS Headers
------------------------------

The header in the primary extension of GPI FITS files contains four keywords that determine the time of the observation:

=========================       ================         ===============================================================================
Keyword                         Format                   Description 
=========================       ================         ===============================================================================
DATE-OBS                        YYYY-MM-DD               UT date at start of exposure
UTSTART                         HH:MM:SS.SSS             UT time at start of exposure
UTEND                           HH:MM:SS.SSS             UT time at end of exposure (after last read)
MJD-OBS                         DOUBLE                   Modified Julian Date of observation start (equivalent to DATE-OBS + UTSTART)
=========================       ================         ===============================================================================

Due to overheads for resetting the array before the readout stars, the actual period of photointegration will not begin until on average 1.5 read times after UTSTART. 
Users who care about exposure time accuracy at the 1-second level should consult the GPI instrument team (particularly Chilcote & Savransky). 

.. note::
    Because DATE-OBS is always the date of the observation start, observations that cross the UT dateline will have a UTSTART time corresponding to the DATE-OBS value, but a UTEND time corresponding to the following day.  When trying to reconstruct the exact timestamp for the end time of these observations it is necessary to increment the date by one day before adding UTEND. 


