.. _calibrations_howto:

A very basic guide to creating Calibration Files for your GPI data
######################################################################

.. warning::
     This document is not intended as a complete guide to achieving science-grade calibrations
     of your GPI science data! Not yet anyway. For now this is just a first draft discussion of
     what the different calibration files are, and how you might go about generating them. 


In many cases, the Data Parser will automatically generate a good set of recipes for reducing some/all of your calibration files.
This page takes the alternate approach, of describing what you need to know in order to perform the process yourself, understand how it all works, etc. 
More detailed
docs yet to come!


Darks
=======

**Calibration DB File Type:** Dark

**File Suffix:** dark

**Generate with Recipe:** "Dark"

**Discussion:** Dark files operate in the typical manner for IR detectors with GPI. Because of the possible presence of various nonlinear detector effects 
("reset anomaly", etc), it is generally considered safest to take specific individual dark frames for *each* integration time you use, rather than
taking just one integration time and rescaling it. The pipeline does not implement rescaling darks for different exposure times, so you *must* take distinct dark sequences for each exposure time. 

To create dark calibrations, take a set of many dark files (with the Lyot to Blank). Ideally one would
want > 100 images to ensure that noise in the reduced darks is a order of magnitude less than noise in the
science frames, but that will not always be feasible.  Coadds increase efficiency for short integration times. 10 coadds * 10 exposures is a recommended approach.  Process them using the create dark file recipe. 

Repeat the above process for all exposure times of interest. 

The Data Parser will generate suitable recipes when provided with one or more sequences of dark files. 

Periodic dark observations taken during GPI I&T at UCSC show that the detector's complement of 
hot pixels evolves slightly but noticeably on two week timescales. Using darks more than a week or two different in
time from your science data results in visibly higher residual hot pixels in the final datacubes. (The dark current for the large
majority of normal pixels is in comparison very stable, as are indeed most of the hot pixels - it's just some outliers that evolve.)

.. note::

  Currently the GPI pipeline adopts a very conservative approach of only using
  dark frames taken with exactly the same integration time as a given science
  frame. This allows direct subtraction without rescaling for any nonlinear
  behavior of pixels, such as can sometimes be seen for some hot pixels. 

  However, tests have shown that for the vast majority of pixels, scaling darks
  from different exposure times by the ratio of the integration times and then
  subtracting those, pretty much works fine. The conservative "library of darks
  at all distinct integration times" approach has been retained, in part simply
  because it's simple and low cost to take darks often when the instrument is
  not in use. 


Thermal and/or Sky Background Emission
=========================================


**Calibration DB File Type:** Thermal/Sky Background

**File Suffix:** background

**Generate with Recipe:**  'Combine Thermal/Sky Background Images'

Thermal emission (from sky or telescope) becomes an important background source at around 2 microns. 
It thus can be necessary to subtract backgrounds, particularly when reducing calibration lamp spectra. 

It does not matter significantly for the `Y`, `J`, or `H` filters; there is no
significant emission at those wavelengths for our purposes. 


To generate, obtain some number of images of the relevant background (e.g sky
frames, or images of the dome interior with calibration lamps turned off), with
as similar as possible instrument settings to your science data. Reduce these
frames with the above recipe.  As usual, take enough frames to ensure a good S/N measurement. 

Unlike darks, the pipeline is set up to scale thermal emission to different exposure
times. Thus, one set of relatively deep background observations will suffice to
correct observations in the same mode but with different integration times.  

*The Data Parser does not currently automatically generate recipes for this - please do so manually for now*


Bad Pixel Maps
===================

**Calibration DB File Type:**  Bad pixel maps

**File Suffix:** coldbadpix, hotpix, nonlinearbadpix, badpix

**Generate with Recipe:**  Several. Generate Hot Bad Pixel Map from Darks, Generate Cold Bad Pixel Map from Flats, Combine Bad Pixel Maps


You'll see there are 4 different types of files related to tracking bad pixels:

 * coldbadpix: Cold Bad Pixel Map
 * hotpix: Hot Pixel Map
 * nonlinearbadpix : Nonlinear Bad Pixel Map
 * badpix: Bad Pixel Map

The ones that are named "badpix" are the final output bad pixel maps. These 
are generated from the union of one each Cold, Hot, and Nonlinear bad pixel maps. Thus, 
to generate a bad pixel map you must first generate the 
3 different individual maps, and then combine them. 


**Step 1: Hot Bad Pixels**

Maps of hot (high dark current) pixels files can be generated in the pipeline using the "Generate Hot Bad Pixel Map
from Darks" recipe. The input files should be a set of >= 10 dark exposures with identical ITIME, 
preferably ITIME > 100 s. (The longer the better...)  

The algorithm works by measuring the read noise from the standard deviation between frames, and then
locating pixels that are very significantly above this level. Specifically, the criteria for being considered a hot pixel are > 1 dark count e- per second, measured with > 5 sigma confidence.  For comparison, typical pixels have dark counts < 0.01 e-/sec for our detector. 

The Data Parser, if ran on suitable dark files, will 
automatically generate one recipe using the longest available dark sequence with >= 10 files. (If the only darks available are < 60 s in integration time, the Data Parser will not try to produce a hot pixel map.)


**Step 2: Cold Bad Pixels**

Maps of cold (non-photo-sensitive) pixels are generated using the recipe
"Generate Cold Bad Pixel Map from Flats" recipe. Finding such pixels for GPI is
more complicated than for typical instruments. Because of the lenslet array,
it's not possible to illuminate the detector with any kind of truly flat
illumination pattern. You'll always have the pattern of tens of thousands of
lenslets imprinted, with little to no illumination between them.  However, by
adding together many flat field exposures *taken using several different
filters* we can at least get illumination onto all of the pixels of the
detector.  (Though that illumination pattern is very structured rather than
flat.) We call this a "multi-filter pseudoflat".  We then take advantage of 
the translational symmetries inherent in the
lenslet array to build up a reference image that retains the spectral structure from the illumination pattern but
is smoothed over several detector pixels. By comparing individual pixels to this reference image, we can identify those that lack sensitivity. 


The "cold pixel" selection criterion is  "any pixel with < 15% normalized response measured from the summed multi-filter pseudoflat." 

The Data Parser will produce a recipe for this if given flat images in at least three different filters. (More is better)

**Step 3: Nonlinear Bad Pixels**

Every pixel shows some nonlinearity as it approaches saturation; that doesn't count as bad. 
But some pixels show *no* linear behavior at any exposure level (without being strictly hot or cold). 
It's those pixels we want to identify and exclude. 

nonlinearbadpix are an *optional* calibration. The pipeline will work fine without them. 
The required calibration file can only be generated outside of the pipeline right now, by a Python script by Marshall that
relies on looking at a flat image taken in UTR save-all-frames mode. 

*Because of this, right now the pipeline ignores the "only use calibrations from the same cooldown"
restriction for nonlinear bad pixel files - that one existing nonlinear bad pixel map can automatically be
used regardless of date.*

**Step 4: Combining the above**

This part's easy. Just run the 'Combine Bad Pixel Maps' recipe. Feed it as
input data *any* raw GPI file. The contents of that file don't actually matter, all that's used is the date. 
Based on that date, the data pipeline will 
automatically retrieve the best available (closest in time) hot, cold, and (optionally) nonlinear bad pixel
maps from the calibration database, and produce a combined file that will be
saved into the calibration directory. 

The Data Parser will produce a recipe for this if either the Hot Pixel or Cold Pixel recipes mentioned above are produced. 


Wavelength Solutions
========================

**Calibration DB File Type:** Wavelength Solution Cal File

**File Suffix:** wavecal

**Generate with Recipe:** "Wavelength Solution"

Take a series of arc lamp exposures (multiple exposures to increase S/N). Reduce these using the 'Wavelength Solution' recipe. This will create a references datacube that provides the starting x and y positions, the wavelength at those positions, the wavelength dispersion, and the tilt angle for each lenslet spectrum. This data cube may then be used to extract full spectral data cubes from science data.

Due to numerous close emission lines in Argon lamp data that are blended at GPI’s resolution and therefore cannot be identified and discriminated, the Xenon lamp is recommended for all GPI wavelength calibrations. The Argon lamp can optionally be used in Y band for acceptable solutions, but is not recommended in other filters.

.. note::
        This recipe is somewhat computationally intensive, and will take 10-20 minutes to run on typical machines. 



Polarimetry Spot Locations
============================

**Calibration DB File Type:** Polarimetry Spots Cal File

**File Suffix:** polcal

**Generate with Recipe:** 'Calibrate Polarization Spots Locations'


Take a set of flat field observations in polarimetry mode in the filter of interest.  Reduce these
using the 'Calibrate Polarization Spots Locations' recipe and you should be ready to go. 

Typically the same exact set of input data are used for 'Calibrate Polarization Spots Locations' and 
'Create Polarized Flat-field', but two distinct output files are produced from the two recipes. 

.. note::
        This recipe is somewhat computationally intensive, and will take 10-20 minutes to run on typical machines. 

Instrumental Polarization
============================

**Calibration DB File Type:** Instrumental Polarization

**File Suffix:** instpol

**Generate with Recipe:**

This is not generated using a pipeline recipe - it's a complicated one-time calibration performed during
integration and test at UCSC. Contact Max or Sloane for more information. 


Flat Fields
==============

**Calibration DB File Type:** Flat Field

**File Suffix:** flat

**Generate with Recipe:** 'Flat-field Extraction' (spectral mode), 'Create Polarized Flat-field' (polarimetry mode)


Take a set of flat field observations in desired mode and filter. Reduce with the appropriate recipe. 


